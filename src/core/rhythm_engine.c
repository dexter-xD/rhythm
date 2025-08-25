#include "core/rhythm_engine.h"
#include <sys/stat.h>
#include <libgen.h>

struct RhythmEngine {
    AudioPlayer* audio_player;
    Playlist* playlist;
    RhythmStatus current_status;
    RhythmError last_error;
    bool status_dirty;  
};

static bool is_directory(const char* path) {
    struct stat st;
    return (stat(path, &st) == 0 && S_ISDIR(st.st_mode));
}

static int get_file_duration(AudioPlayer* player) {
    return audio_player_get_total_time(player);
}

static int get_current_position(AudioPlayer* player) {
    return audio_player_get_current_time(player);
}

static float calculate_progress(int current_time, int total_time) {
    if (total_time <= 0) return 0.0f;
    float progress = (float)current_time / (float)total_time;
    return (progress > 1.0f) ? 1.0f : progress;
}

static void update_status(RhythmEngine* engine) {
    if (!engine) return;

    RhythmStatus* status = &engine->current_status;

    if (status->current_file) {
        free(status->current_file);
        status->current_file = NULL;
    }

    if (engine->playlist && engine->playlist->count > 0) {
        playlist_get_info(engine->playlist, &status->current_track, &status->total_tracks);
        const char* current_file = playlist_get_current(engine->playlist);
        if (current_file) {
            status->current_file = strdup(basename((char*)current_file));
        }
    } else {
        status->current_track = 0;
        status->total_tracks = 0;
    }

    if (engine->audio_player) {
        status->state = audio_player_get_state(engine->audio_player);
        status->volume = audio_player_get_volume(engine->audio_player);

        audio_player_get_vis_data(engine->audio_player, status->vis_bands, 32);

        status->total_time = get_file_duration(engine->audio_player);
        status->current_time = get_current_position(engine->audio_player);
        status->progress = audio_player_get_progress(engine->audio_player);
    } else {
        status->state = PLAYER_STATE_STOPPED;
        status->volume = 0.0f;
        status->total_time = 0;
        status->current_time = 0;
        status->progress = 0.0f;
        memset(status->vis_bands, 0, sizeof(status->vis_bands));
    }

    engine->status_dirty = false;
}

RhythmEngine* rhythm_engine_create(void) {
    RhythmEngine* engine = malloc(sizeof(RhythmEngine));
    if (!engine) {
        return NULL;
    }

    memset(engine, 0, sizeof(RhythmEngine));
    engine->last_error = RHYTHM_OK;
    engine->status_dirty = true;

    engine->audio_player = audio_player_init();
    if (!engine->audio_player) {
        engine->last_error = RHYTHM_ERROR_AUDIO_DEVICE;
        free(engine);
        return NULL;
    }

    engine->playlist = playlist_create();
    if (!engine->playlist) {
        engine->last_error = RHYTHM_ERROR_MEMORY;
        audio_player_cleanup(engine->audio_player);
        free(engine);
        return NULL;
    }

    update_status(engine);

    return engine;
}

void rhythm_engine_destroy(RhythmEngine* engine) {
    if (!engine) return;

    rhythm_engine_stop(engine);

    if (engine->audio_player) {
        audio_player_cleanup(engine->audio_player);
    }

    if (engine->playlist) {
        playlist_destroy(engine->playlist);
    }

    if (engine->current_status.current_file) {
        free(engine->current_status.current_file);
    }

    free(engine);
}

RhythmError rhythm_engine_load_file(RhythmEngine* engine, const char* filename) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    if (!filename) return RHYTHM_ERROR_NULL_POINTER;

    struct stat st;
    if (stat(filename, &st) != 0) {
        engine->last_error = RHYTHM_ERROR_FILE_NOT_FOUND;
        return RHYTHM_ERROR_FILE_NOT_FOUND;
    }

    rhythm_engine_stop(engine);

    if (engine->playlist) {
        playlist_clear(engine->playlist);
    } else {
        engine->playlist = playlist_create();
        if (!engine->playlist) {
            engine->last_error = RHYTHM_ERROR_MEMORY;
            return RHYTHM_ERROR_MEMORY;
        }
    }

    if (playlist_add_file(engine->playlist, filename) != 0) {
        engine->last_error = RHYTHM_ERROR_INVALID_FORMAT;
        return RHYTHM_ERROR_INVALID_FORMAT;
    }

    engine->status_dirty = true;
    engine->last_error = RHYTHM_OK;
    return RHYTHM_OK;
}

RhythmError rhythm_engine_load_directory(RhythmEngine* engine, const char* directory) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    if (!directory) return RHYTHM_ERROR_NULL_POINTER;

    if (!is_directory(directory)) {
        engine->last_error = RHYTHM_ERROR_FILE_NOT_FOUND;
        return RHYTHM_ERROR_FILE_NOT_FOUND;
    }

    rhythm_engine_stop(engine);

    if (engine->playlist) {
        playlist_clear(engine->playlist);
    } else {
        engine->playlist = playlist_create();
        if (!engine->playlist) {
            engine->last_error = RHYTHM_ERROR_MEMORY;
            return RHYTHM_ERROR_MEMORY;
        }
    }

    int added = playlist_add_directory(engine->playlist, directory);
    if (added <= 0) {
        engine->last_error = RHYTHM_ERROR_INVALID_FORMAT;
        return RHYTHM_ERROR_INVALID_FORMAT;
    }

    engine->status_dirty = true;
    engine->last_error = RHYTHM_OK;
    return RHYTHM_OK;
}

RhythmError rhythm_engine_play(RhythmEngine* engine) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    if (!engine->audio_player) return RHYTHM_ERROR_INVALID_STATE;
    if (!engine->playlist) return RHYTHM_ERROR_INVALID_STATE;

    const char* current_file = playlist_get_current(engine->playlist);
    if (!current_file) {
        engine->last_error = RHYTHM_ERROR_INVALID_STATE;
        return RHYTHM_ERROR_INVALID_STATE;
    }

    if (engine->audio_player->state == PLAYER_STATE_PAUSED) {
        audio_player_resume(engine->audio_player);
    } else {

        if (audio_player_play(engine->audio_player, current_file) != 0) {
            engine->last_error = RHYTHM_ERROR_INVALID_FORMAT;
            return RHYTHM_ERROR_INVALID_FORMAT;
        }
    }

    engine->status_dirty = true;
    engine->last_error = RHYTHM_OK;
    return RHYTHM_OK;
}

RhythmError rhythm_engine_pause(RhythmEngine* engine) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    if (!engine->audio_player) return RHYTHM_ERROR_INVALID_STATE;

    audio_player_pause(engine->audio_player);
    engine->status_dirty = true;
    engine->last_error = RHYTHM_OK;
    return RHYTHM_OK;
}

RhythmError rhythm_engine_stop(RhythmEngine* engine) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    if (!engine->audio_player) return RHYTHM_ERROR_INVALID_STATE;

    audio_player_stop(engine->audio_player);
    engine->status_dirty = true;
    engine->last_error = RHYTHM_OK;
    return RHYTHM_OK;
}

RhythmError rhythm_engine_next_track(RhythmEngine* engine) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    if (!engine->playlist) return RHYTHM_ERROR_INVALID_STATE;

    if (playlist_next(engine->playlist) < 0) {
        engine->last_error = RHYTHM_ERROR_INVALID_STATE;
        return RHYTHM_ERROR_INVALID_STATE;
    }

    if (engine->audio_player && engine->audio_player->state == PLAYER_STATE_PLAYING) {
        return rhythm_engine_play(engine);
    }

    engine->status_dirty = true;
    engine->last_error = RHYTHM_OK;
    return RHYTHM_OK;
}

RhythmError rhythm_engine_previous_track(RhythmEngine* engine) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    if (!engine->playlist) return RHYTHM_ERROR_INVALID_STATE;

    if (playlist_previous(engine->playlist) < 0) {
        engine->last_error = RHYTHM_ERROR_INVALID_STATE;
        return RHYTHM_ERROR_INVALID_STATE;
    }

    if (engine->audio_player && engine->audio_player->state == PLAYER_STATE_PLAYING) {
        return rhythm_engine_play(engine);
    }

    engine->status_dirty = true;
    engine->last_error = RHYTHM_OK;
    return RHYTHM_OK;
}

RhythmError rhythm_engine_seek(RhythmEngine* engine, float position) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    if (!engine->audio_player) return RHYTHM_ERROR_INVALID_STATE;

    if (position < 0.0f || position > 1.0f) {
        engine->last_error = RHYTHM_ERROR_INVALID_STATE;
        return RHYTHM_ERROR_INVALID_STATE;
    }

    if (!engine->audio_player->current_file) {
        engine->status_dirty = true;
        engine->last_error = RHYTHM_OK;
        return RHYTHM_OK;
    }

    if (audio_player_seek(engine->audio_player, position) != 0) {
        engine->last_error = RHYTHM_ERROR_INVALID_STATE;
        return RHYTHM_ERROR_INVALID_STATE;
    }

    engine->status_dirty = true;
    engine->last_error = RHYTHM_OK;
    return RHYTHM_OK;
}

RhythmError rhythm_engine_set_volume(RhythmEngine* engine, float volume) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    if (!engine->audio_player) return RHYTHM_ERROR_INVALID_STATE;

    audio_player_set_volume(engine->audio_player, volume);
    engine->status_dirty = true;
    engine->last_error = RHYTHM_OK;
    return RHYTHM_OK;
}

RhythmStatus rhythm_engine_get_status(RhythmEngine* engine) {
    RhythmStatus empty_status = {0};

    if (!engine) {
        return empty_status;
    }

    if (engine->status_dirty) {
        update_status(engine);
    }

    return engine->current_status;
}

void rhythm_engine_update(RhythmEngine* engine) {
    if (!engine) return;

    engine->status_dirty = true;
}

RhythmError rhythm_engine_get_last_error(RhythmEngine* engine) {
    if (!engine) return RHYTHM_ERROR_NULL_POINTER;
    return engine->last_error;
}

const char* rhythm_engine_error_string(RhythmError error) {
    switch (error) {
        case RHYTHM_OK:
            return "No error";
        case RHYTHM_ERROR_INIT:
            return "Initialization error";
        case RHYTHM_ERROR_FILE_NOT_FOUND:
            return "File not found";
        case RHYTHM_ERROR_INVALID_FORMAT:
            return "Invalid audio format";
        case RHYTHM_ERROR_AUDIO_DEVICE:
            return "Audio device error";
        case RHYTHM_ERROR_MEMORY:
            return "Memory allocation error";
        case RHYTHM_ERROR_NULL_POINTER:
            return "Null pointer error";
        case RHYTHM_ERROR_INVALID_STATE:
            return "Invalid engine state";
        default:
            return "Unknown error";
    }
}