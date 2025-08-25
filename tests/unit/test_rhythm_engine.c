#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
#include "core/rhythm_engine.h"

#define TEST_ASSERT(condition, message) \
    do { \
        if (!(condition)) { \
            fprintf(stderr, "FAIL: %s - %s\n", __func__, message); \
            return 0; \
        } \
    } while(0)

#define TEST_PASS() \
    do { \
        printf("PASS: %s\n", __func__); \
        return 1; \
    } while(0)

static void create_test_file(const char* filename) {
    FILE* f = fopen(filename, "w");
    if (f) {
        fprintf(f, "test content");
        fclose(f);
    }
}

static void create_test_directory(const char* dirname) {
    mkdir(dirname, 0755);

    char filepath[256];
    snprintf(filepath, sizeof(filepath), "%s/test1.mp3", dirname);
    create_test_file(filepath);

    snprintf(filepath, sizeof(filepath), "%s/test2.mp3", dirname);
    create_test_file(filepath);

    snprintf(filepath, sizeof(filepath), "%s/not_audio.txt", dirname);
    create_test_file(filepath);
}

static void cleanup_test_files(void) {
    unlink("test_file.mp3");
    unlink("test_dir/test1.mp3");
    unlink("test_dir/test2.mp3");
    unlink("test_dir/not_audio.txt");
    rmdir("test_dir");
}

static int test_engine_create_destroy(void) {
    RhythmEngine* engine = rhythm_engine_create();
    TEST_ASSERT(engine != NULL, "Engine creation should succeed");

    RhythmStatus status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.state == PLAYER_STATE_STOPPED, "Initial state should be stopped");
    TEST_ASSERT(status.current_track == 0, "Initial track should be 0");
    TEST_ASSERT(status.total_tracks == 0, "Initial total tracks should be 0");
    TEST_ASSERT(status.current_file == NULL, "Initial current file should be NULL");

    rhythm_engine_destroy(engine);
    TEST_PASS();
}

static int test_null_pointer_handling(void) {

    TEST_ASSERT(rhythm_engine_load_file(NULL, "test.mp3") == RHYTHM_ERROR_NULL_POINTER, 
                "Should return NULL pointer error");
    TEST_ASSERT(rhythm_engine_play(NULL) == RHYTHM_ERROR_NULL_POINTER, 
                "Should return NULL pointer error");
    TEST_ASSERT(rhythm_engine_pause(NULL) == RHYTHM_ERROR_NULL_POINTER, 
                "Should return NULL pointer error");
    TEST_ASSERT(rhythm_engine_stop(NULL) == RHYTHM_ERROR_NULL_POINTER, 
                "Should return NULL pointer error");

    RhythmEngine* engine = rhythm_engine_create();
    TEST_ASSERT(engine != NULL, "Engine creation should succeed");

    TEST_ASSERT(rhythm_engine_load_file(engine, NULL) == RHYTHM_ERROR_NULL_POINTER, 
                "Should return NULL pointer error for NULL filename");
    TEST_ASSERT(rhythm_engine_load_directory(engine, NULL) == RHYTHM_ERROR_NULL_POINTER, 
                "Should return NULL pointer error for NULL directory");

    rhythm_engine_destroy(engine);
    TEST_PASS();
}

static int test_file_loading(void) {
    RhythmEngine* engine = rhythm_engine_create();
    TEST_ASSERT(engine != NULL, "Engine creation should succeed");

    RhythmError result = rhythm_engine_load_file(engine, "nonexistent.mp3");
    TEST_ASSERT(result == RHYTHM_ERROR_FILE_NOT_FOUND, "Should return file not found error");
    TEST_ASSERT(rhythm_engine_get_last_error(engine) == RHYTHM_ERROR_FILE_NOT_FOUND, 
                "Last error should be file not found");

    create_test_file("test_file.mp3");
    result = rhythm_engine_load_file(engine, "test_file.mp3");
    TEST_ASSERT(result == RHYTHM_OK, "Should successfully load existing file");

    RhythmStatus status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.total_tracks == 1, "Should have 1 track after loading file");
    TEST_ASSERT(status.current_track == 1, "Current track should be 1");

    rhythm_engine_destroy(engine);
    cleanup_test_files();
    TEST_PASS();
}

static int test_directory_loading(void) {
    RhythmEngine* engine = rhythm_engine_create();
    TEST_ASSERT(engine != NULL, "Engine creation should succeed");

    RhythmError result = rhythm_engine_load_directory(engine, "nonexistent_dir");
    TEST_ASSERT(result == RHYTHM_ERROR_FILE_NOT_FOUND, "Should return file not found error");

    create_test_directory("test_dir");
    result = rhythm_engine_load_directory(engine, "test_dir");
    TEST_ASSERT(result == RHYTHM_OK, "Should successfully load directory");

    RhythmStatus status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.total_tracks == 2, "Should have 2 MP3 tracks (ignoring .txt file)");
    TEST_ASSERT(status.current_track == 1, "Current track should be 1");

    rhythm_engine_destroy(engine);
    cleanup_test_files();
    TEST_PASS();
}

static int test_playback_states(void) {
    RhythmEngine* engine = rhythm_engine_create();
    TEST_ASSERT(engine != NULL, "Engine creation should succeed");

    RhythmError result = rhythm_engine_play(engine);
    TEST_ASSERT(result == RHYTHM_ERROR_INVALID_STATE, "Should return invalid state error");

    create_test_file("test_file.mp3");
    rhythm_engine_load_file(engine, "test_file.mp3");

    RhythmStatus status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.state == PLAYER_STATE_STOPPED, "Initial state should be stopped");

    result = rhythm_engine_pause(engine);
    TEST_ASSERT(result == RHYTHM_OK, "Pause should succeed even when stopped");

    result = rhythm_engine_stop(engine);
    TEST_ASSERT(result == RHYTHM_OK, "Stop should succeed even when stopped");

    rhythm_engine_destroy(engine);
    cleanup_test_files();
    TEST_PASS();
}

static int test_volume_control(void) {
    RhythmEngine* engine = rhythm_engine_create();
    TEST_ASSERT(engine != NULL, "Engine creation should succeed");

    RhythmError result = rhythm_engine_set_volume(engine, 1.5f);
    TEST_ASSERT(result == RHYTHM_OK, "Volume setting should succeed");

    RhythmStatus status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.volume == 1.5f, "Volume should be set to 1.5");

    rhythm_engine_set_volume(engine, -1.0f);
    status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.volume >= 0.0f, "Volume should not be negative");

    rhythm_engine_set_volume(engine, 5.0f);
    status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.volume <= 2.0f, "Volume should be clamped to maximum");

    rhythm_engine_destroy(engine);
    TEST_PASS();
}

static int test_playlist_navigation(void) {
    RhythmEngine* engine = rhythm_engine_create();
    TEST_ASSERT(engine != NULL, "Engine creation should succeed");

    RhythmError result = rhythm_engine_next_track(engine);
    TEST_ASSERT(result == RHYTHM_ERROR_INVALID_STATE, "Should return invalid state error");

    result = rhythm_engine_previous_track(engine);
    TEST_ASSERT(result == RHYTHM_ERROR_INVALID_STATE, "Should return invalid state error");

    create_test_directory("test_dir");
    rhythm_engine_load_directory(engine, "test_dir");

    RhythmStatus status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.current_track == 1, "Should start at track 1");
    TEST_ASSERT(status.total_tracks == 2, "Should have 2 tracks");

    result = rhythm_engine_next_track(engine);
    TEST_ASSERT(result == RHYTHM_OK, "Next track should succeed");

    status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.current_track == 2, "Should be at track 2");

    result = rhythm_engine_previous_track(engine);
    TEST_ASSERT(result == RHYTHM_OK, "Previous track should succeed");

    status = rhythm_engine_get_status(engine);
    TEST_ASSERT(status.current_track == 1, "Should be back at track 1");

    rhythm_engine_destroy(engine);
    cleanup_test_files();
    TEST_PASS();
}

static int test_seek_functionality(void) {
    RhythmEngine* engine = rhythm_engine_create();
    TEST_ASSERT(engine != NULL, "Engine creation should succeed");

    RhythmError result = rhythm_engine_seek(engine, 0.5f);
    TEST_ASSERT(result == RHYTHM_OK, "Seek to 50% should succeed");

    result = rhythm_engine_seek(engine, 0.0f);
    TEST_ASSERT(result == RHYTHM_OK, "Seek to start should succeed");

    result = rhythm_engine_seek(engine, 1.0f);
    TEST_ASSERT(result == RHYTHM_OK, "Seek to end should succeed");

    result = rhythm_engine_seek(engine, -0.1f);
    TEST_ASSERT(result == RHYTHM_ERROR_INVALID_STATE, "Seek to negative position should fail");

    result = rhythm_engine_seek(engine, 1.1f);
    TEST_ASSERT(result == RHYTHM_ERROR_INVALID_STATE, "Seek beyond end should fail");

    rhythm_engine_destroy(engine);
    TEST_PASS();
}

static int test_status_updates(void) {
    RhythmEngine* engine = rhythm_engine_create();
    TEST_ASSERT(engine != NULL, "Engine creation should succeed");

    RhythmStatus status1 = rhythm_engine_get_status(engine);
    TEST_ASSERT(status1.state == PLAYER_STATE_STOPPED, "Initial state should be stopped");
    TEST_ASSERT(status1.progress == 0.0f, "Initial progress should be 0");
    TEST_ASSERT(status1.current_time == 0, "Initial current time should be 0");
    TEST_ASSERT(status1.total_time == 0, "Initial total time should be 0");

    create_test_file("test_file.mp3");
    rhythm_engine_load_file(engine, "test_file.mp3");

    RhythmStatus status2 = rhythm_engine_get_status(engine);
    TEST_ASSERT(status2.total_tracks == 1, "Should have 1 track");
    TEST_ASSERT(status2.current_track == 1, "Should be at track 1");

    rhythm_engine_update(engine);
    RhythmStatus status3 = rhythm_engine_get_status(engine);

    TEST_ASSERT(status3.total_tracks == status2.total_tracks, "Track count should be consistent");

    rhythm_engine_destroy(engine);
    cleanup_test_files();
    TEST_PASS();
}

static int test_error_strings(void) {
    const char* error_str;

    error_str = rhythm_engine_error_string(RHYTHM_OK);
    TEST_ASSERT(strcmp(error_str, "No error") == 0, "Should return correct error string");

    error_str = rhythm_engine_error_string(RHYTHM_ERROR_FILE_NOT_FOUND);
    TEST_ASSERT(strcmp(error_str, "File not found") == 0, "Should return correct error string");

    error_str = rhythm_engine_error_string(RHYTHM_ERROR_MEMORY);
    TEST_ASSERT(strcmp(error_str, "Memory allocation error") == 0, "Should return correct error string");

    error_str = rhythm_engine_error_string((RhythmError)999);
    TEST_ASSERT(strcmp(error_str, "Unknown error") == 0, "Should return unknown error for invalid code");

    TEST_PASS();
}

int main(void) {
    printf("Running Rhythm Engine Unit Tests\n");
    printf("================================\n");

    int passed = 0;
    int total = 0;

    total++; if (test_engine_create_destroy()) passed++;
    total++; if (test_null_pointer_handling()) passed++;
    total++; if (test_file_loading()) passed++;
    total++; if (test_directory_loading()) passed++;
    total++; if (test_playback_states()) passed++;
    total++; if (test_volume_control()) passed++;
    total++; if (test_playlist_navigation()) passed++;
    total++; if (test_seek_functionality()) passed++;
    total++; if (test_status_updates()) passed++;
    total++; if (test_error_strings()) passed++;

    printf("\n================================\n");
    printf("Test Results: %d/%d passed\n", passed, total);

    if (passed == total) {
        printf("All tests passed!\n");
        return 0;
    } else {
        printf("Some tests failed!\n");
        return 1;
    }
}