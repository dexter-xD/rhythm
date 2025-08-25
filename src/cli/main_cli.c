#include "shared/common.h"
#include "core/rhythm_engine.h"
#include "cli/cli.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <sys/stat.h>

static RhythmEngine *engine = NULL;

void cleanup(int signum) {
    (void)signum;
    if (engine) {
        rhythm_engine_destroy(engine);
    }
    cli_cleanup();
    exit(0);
}

int is_directory(const char *path) {
    struct stat st;
    return (stat(path, &st) == 0 && S_ISDIR(st.st_mode));
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <mp3_file_or_directory>\n", argv[0]);
        return 1;
    }

    atexit(cli_cleanup);

    signal(SIGINT, cleanup);
    signal(SIGTERM, cleanup);

    engine = rhythm_engine_create();
    if (!engine) {
        fprintf(stderr, "Failed to create rhythm engine\n");
        return 1;
    }

    RhythmError result;
    if (is_directory(argv[1])) {
        result = rhythm_engine_load_directory(engine, argv[1]);
        if (result != RHYTHM_OK) {
            fprintf(stderr, "Failed to load directory: %s - %s\n", argv[1], rhythm_engine_error_string(result));
            rhythm_engine_destroy(engine);
            return 1;
        }

        RhythmStatus status = rhythm_engine_get_status(engine);
        if (status.total_tracks <= 0) {
            fprintf(stderr, "No MP3 files found in directory: %s\n", argv[1]);
            rhythm_engine_destroy(engine);
            return 1;
        }
        printf("Found %d MP3 files in directory\n", status.total_tracks);
        sleep(1);
    } else {
        if (!is_mp3_file(argv[1])) {
            fprintf(stderr, "File is not an MP3: %s\n", argv[1]);
            rhythm_engine_destroy(engine);
            return 1;
        }

        result = rhythm_engine_load_file(engine, argv[1]);
        if (result != RHYTHM_OK) {
            fprintf(stderr, "Failed to load file: %s - %s\n", argv[1], rhythm_engine_error_string(result));
            rhythm_engine_destroy(engine);
            return 1;
        }
    }

    cli_init();

    result = rhythm_engine_play(engine);
    if (result != RHYTHM_OK) {
        fprintf(stderr, "Failed to start playback: %s\n", rhythm_engine_error_string(result));
        rhythm_engine_destroy(engine);
        return 1;
    }

    while (1) {
        rhythm_engine_update(engine);
        RhythmStatus status = rhythm_engine_get_status(engine);

        cli_display_status(&status);
        int input_result = cli_handle_input(engine);

        if (input_result == 2) {

            break;
        } else if (input_result == 1) {

            rhythm_engine_next_track(engine);
        } else if (input_result == -1) {

            rhythm_engine_previous_track(engine);
        }

        if (status.state == PLAYER_STATE_PLAYING && status.progress >= 0.999f) {
            if (status.total_tracks > 1) {
                rhythm_engine_next_track(engine);
            }
        }

        usleep(100000);
    }

    rhythm_engine_destroy(engine);
    return 0;
}