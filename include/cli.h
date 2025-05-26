#ifndef CLI_H
#define CLI_H

#include "audio_player.h"
#include "playlist.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <time.h>
#include <math.h>

void cli_init(void);
void cli_cleanup(void);
void cli_display_status(AudioPlayer *player, Playlist *playlist);
int cli_handle_input(AudioPlayer *player, Playlist *playlist);

#endif 