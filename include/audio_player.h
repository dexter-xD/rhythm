#ifndef AUDIO_PLAYER_H
#define AUDIO_PLAYER_H

#include "common.h"
#include "audio_converter.h"
#include <unistd.h>
#include <math.h>

typedef struct {
    PaStream *stream;
    mpg123_handle *mh;
    PlayerState state;
    float volume;
    char *current_file;
    float vis_level;
    float vis_bands[32];
} AudioPlayer;

AudioPlayer* audio_player_init(void);

void audio_player_cleanup(AudioPlayer *player);
int audio_player_play(AudioPlayer *player, const char *filename);
void audio_player_pause(AudioPlayer *player);
void audio_player_resume(AudioPlayer *player);
void audio_player_stop(AudioPlayer *player);
void audio_player_set_volume(AudioPlayer *player, float volume);
PlayerState audio_player_get_state(AudioPlayer *player);

#endif 