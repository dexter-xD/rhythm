#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <signal.h>
#include <errno.h>
#include "core/rhythm_engine.h"
#include "shared/common.h"

static RhythmEngine* global_engine = NULL;
static pid_t love2d_pid = -1;

static void cleanup_handler(int sig) {
    printf("\nShutting down GUI...\n");

    if (love2d_pid > 0) {
        kill(love2d_pid, SIGTERM);
        waitpid(love2d_pid, NULL, 0);
    }

    if (global_engine) {
        rhythm_engine_destroy(global_engine);
        global_engine = NULL;
    }

    exit(0);
}

static void print_usage(const char* program_name) {
    printf("Usage: %s [OPTIONS] [file_or_directory]\n", program_name);
    printf("\nOptions:\n");
    printf("  -h, --help     Show this help message\n");
    printf("  -v, --version  Show version information\n");
    printf("\nArguments:\n");
    printf("  file_or_directory  Optional MP3 file or directory containing MP3 files\n");
    printf("                     If not provided, GUI will launch with drag-and-drop support\n");
    printf("\nExamples:\n");
    printf("  %s                    # Launch with drag-and-drop support\n", program_name);
    printf("  %s song.mp3           # Launch with specific file\n", program_name);
    printf("  %s /path/to/music/    # Launch with directory\n", program_name);
}

static bool file_exists(const char* path) {
    return access(path, R_OK) == 0;
}

static bool is_directory(const char* path) {
    struct stat st;
    return stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}

static int launch_love2d(const char* music_path) {
    char gui_path[1024];
    char engine_lib_path[1024];
    char music_arg[1024];

    char exe_path[1024];
    ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
    if (len == -1) {
        fprintf(stderr, "Error: Could not determine executable path\n");
        return -1;
    }
    exe_path[len] = '\0';

    char* last_slash = strrchr(exe_path, '/');
    if (last_slash) {
        *last_slash = '\0';
    }

    snprintf(gui_path, sizeof(gui_path), "%s/../gui", exe_path);
    snprintf(engine_lib_path, sizeof(engine_lib_path), "%s/librhythm_engine.so", exe_path);

    if (music_path) {
        snprintf(music_arg, sizeof(music_arg), "RHYTHM_MUSIC_PATH=%s", music_path);
    }

    if (!file_exists(gui_path)) {
        fprintf(stderr, "Error: GUI directory not found at %s\n", gui_path);
        return -1;
    }

    love2d_pid = fork();

    if (love2d_pid == -1) {
        perror("Error: Failed to fork Love2D process");
        return -1;
    }

    if (love2d_pid == 0) {

        if (music_path && putenv(music_arg) != 0) {
            perror("Error: Failed to set environment variable");
            exit(1);
        }

        char ld_path[2048];
        const char* current_ld_path = getenv("LD_LIBRARY_PATH");
        if (current_ld_path) {
            snprintf(ld_path, sizeof(ld_path), "LD_LIBRARY_PATH=%s:%s", exe_path, current_ld_path);
        } else {
            snprintf(ld_path, sizeof(ld_path), "LD_LIBRARY_PATH=%s", exe_path);
        }

        if (putenv(ld_path) != 0) {
            perror("Error: Failed to set LD_LIBRARY_PATH");
            exit(1);
        }

        execl("/usr/bin/love", "love", gui_path, (char*)NULL);

        perror("Error: Failed to execute Love2D");
        exit(1);
    }

    int status;
    if (waitpid(love2d_pid, &status, 0) == -1) {
        perror("Error: Failed to wait for Love2D process");
        return -1;
    }

    love2d_pid = -1;

    if (WIFEXITED(status)) {
        return WEXITSTATUS(status);
    } else if (WIFSIGNALED(status)) {
        printf("Love2D terminated by signal %d\n", WTERMSIG(status));
        return -1;
    }

    return 0;
}

int main(int argc, char* argv[]) {
    const char* music_path = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        } else if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--version") == 0) {
            printf("Rhythm GUI v1.0.0\n");
            return 0;
        } else if (argv[i][0] == '-') {
            fprintf(stderr, "Error: Unknown option '%s'\n", argv[i]);
            print_usage(argv[0]);
            return 1;
        } else {

            if (music_path == NULL) {
                music_path = argv[i];
            } else {
                fprintf(stderr, "Error: Multiple file arguments provided\n");
                print_usage(argv[0]);
                return 1;
            }
        }
    }

    if (music_path && !file_exists(music_path)) {
        fprintf(stderr, "Error: File or directory '%s' does not exist or is not readable\n", music_path);
        return 1;
    }

    signal(SIGINT, cleanup_handler);
    signal(SIGTERM, cleanup_handler);

    printf("Initializing Rhythm Engine...\n");
    global_engine = rhythm_engine_create();
    if (!global_engine) {
        fprintf(stderr, "Error: Failed to initialize rhythm engine\n");
        return 1;
    }

    if (music_path) {
        RhythmError error;
        if (is_directory(music_path)) {
            printf("Loading directory: %s\n", music_path);
            error = rhythm_engine_load_directory(global_engine, music_path);
        } else {
            printf("Loading file: %s\n", music_path);
            error = rhythm_engine_load_file(global_engine, music_path);
        }

        if (error != RHYTHM_OK) {
            fprintf(stderr, "Error: Failed to load music: %s\n", 
                    rhythm_engine_error_string(error));
            rhythm_engine_destroy(global_engine);
            return 1;
        }
    } else {
        printf("Starting GUI with drag-and-drop support...\n");
    }

    printf("Launching GUI...\n");
    int result = launch_love2d(music_path);

    printf("Cleaning up...\n");
    if (global_engine) {
        rhythm_engine_destroy(global_engine);
        global_engine = NULL;
    }

    return result;
}