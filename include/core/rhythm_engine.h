#ifndef RHYTHM_ENGINE_H
#define RHYTHM_ENGINE_H

#include "shared/common.h"
#include "core/audio_player.h"
#include "core/playlist.h"

typedef struct RhythmEngine RhythmEngine;

typedef enum {
    RHYTHM_OK = 0,
    RHYTHM_ERROR_INIT = -1,
    RHYTHM_ERROR_FILE_NOT_FOUND = -2,
    RHYTHM_ERROR_INVALID_FORMAT = -3,
    RHYTHM_ERROR_AUDIO_DEVICE = -4,
    RHYTHM_ERROR_MEMORY = -5,
    RHYTHM_ERROR_NULL_POINTER = -6,
    RHYTHM_ERROR_INVALID_STATE = -7
} RhythmError;

typedef struct {
    char* current_file;          
    int current_track;           
    int total_tracks;           
    float progress;              
    int current_time;           
    int total_time;             
    PlayerState state;           
    float volume;                
    float vis_bands[32];         
} RhythmStatus;

RhythmEngine* rhythm_engine_create(void);
void rhythm_engine_destroy(RhythmEngine* engine);

RhythmError rhythm_engine_load_file(RhythmEngine* engine, const char* filename);
RhythmError rhythm_engine_load_directory(RhythmEngine* engine, const char* directory);

RhythmError rhythm_engine_play(RhythmEngine* engine);
RhythmError rhythm_engine_pause(RhythmEngine* engine);
RhythmError rhythm_engine_stop(RhythmEngine* engine);
RhythmError rhythm_engine_next_track(RhythmEngine* engine);
RhythmError rhythm_engine_previous_track(RhythmEngine* engine);
RhythmError rhythm_engine_seek(RhythmEngine* engine, float position);
RhythmError rhythm_engine_set_volume(RhythmEngine* engine, float volume);

RhythmStatus rhythm_engine_get_status(RhythmEngine* engine);
void rhythm_engine_update(RhythmEngine* engine);
RhythmError rhythm_engine_get_last_error(RhythmEngine* engine);
const char* rhythm_engine_error_string(RhythmError error);

#endif 