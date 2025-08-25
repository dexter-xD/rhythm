#ifndef AUDIO_PLAYER_H
#define AUDIO_PLAYER_H

#include "shared/common.h"
#include "core/audio_converter.h"
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
    int current_position_seconds;  
    int total_duration_seconds;   
} AudioPlayer;

AudioPlayer* audio_player_init(void);
void audio_player_cleanup(AudioPlayer *player);

int audio_player_play(AudioPlayer *player, const char *filename);
void audio_player_pause(AudioPlayer *player);
void audio_player_resume(AudioPlayer *player);
void audio_player_stop(AudioPlayer *player);

void audio_player_set_volume(AudioPlayer *player, float volume);
int audio_player_seek(AudioPlayer *player, float position);

PlayerState audio_player_get_state(AudioPlayer *player);
float audio_player_get_volume(AudioPlayer *player);
int audio_player_get_current_time(AudioPlayer *player);
int audio_player_get_total_time(AudioPlayer *player);
float audio_player_get_progress(AudioPlayer *player);
void audio_player_get_vis_data(AudioPlayer *player, float *vis_bands, int num_bands);

#endif 