#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <portaudio.h>
#include <mpg123.h>

#define CHECK_ERROR(condition, message) \
    do { \
        if (condition) { \
            fprintf(stderr, "Error: %s\n", message); \
            exit(EXIT_FAILURE); \
        } \
    } while(0)

typedef enum {
    PLAYER_STATE_STOPPED,
    PLAYER_STATE_PLAYING,
    PLAYER_STATE_PAUSED
} PlayerState;

#define SAMPLE_RATE 48000
#define CHANNELS 2
#define FRAMES_PER_BUFFER 1024

#endif 