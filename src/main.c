#include "common.h"
#include "audio_player.h"
#include "cli.h"
#include "playlist.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <sys/stat.h>

static AudioPlayer *player = NULL;
static Playlist *playlist = NULL;

void cleanup(int signum) {
    (void)signum;
    if (player) {
        audio_player_cleanup(player);
    }
    if (playlist) {
        playlist_destroy(playlist);
    }
    cli_cleanup();
    exit(0);
}

int is_directory(const char *path) {
    struct stat st;
    return (stat(path, &st) == 0 && S_ISDIR(st.st_mode));
}

int play_current_track(AudioPlayer *player, Playlist *playlist) {
    const char *current_file = playlist_get_current(playlist);
    if (!current_file) return -1;
    
    audio_player_stop(player);
    return audio_player_play(player, current_file);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <mp3_file_or_directory>\n", argv[0]);
        return 1;
    }

    atexit(cli_cleanup);

    signal(SIGINT, cleanup);
    signal(SIGTERM, cleanup);

    playlist = playlist_create();
    if (!playlist) {
        fprintf(stderr, "Failed to create playlist\n");
        return 1;
    }

    if (is_directory(argv[1])) {
        int added = playlist_add_directory(playlist, argv[1]);
        if (added <= 0) {
            fprintf(stderr, "No MP3 files found in directory: %s\n", argv[1]);
            playlist_destroy(playlist);
            return 1;
        }
        printf("Found %d MP3 files in directory\n", added);
        sleep(1);
    } else {
        if (!is_mp3_file(argv[1])) {
            fprintf(stderr, "File is not an MP3: %s\n", argv[1]);
            playlist_destroy(playlist);
            return 1;
        }
        if (playlist_add_file(playlist, argv[1]) != 0) {
            fprintf(stderr, "Failed to add file to playlist: %s\n", argv[1]);
            playlist_destroy(playlist);
            return 1;
        }
    }

    player = audio_player_init();
    if (!player) {
        fprintf(stderr, "Failed to initialize audio player\n");
        playlist_destroy(playlist);
        return 1;
    }

    cli_init();

    if (play_current_track(player, playlist) != 0) {
        fprintf(stderr, "Failed to play first track\n");
        audio_player_cleanup(player);
        playlist_destroy(playlist);
        return 1;
    }

    while (1) {
        cli_display_status(player, playlist);
        int input_result = cli_handle_input(player, playlist);
        
        if (input_result == 2) {
            break;
        } else if (input_result == 1) {
            playlist_next(playlist);
            if (play_current_track(player, playlist) != 0) {
                fprintf(stderr, "Failed to play next track\n");
            }
        } else if (input_result == -1) {
            playlist_previous(playlist);
            if (play_current_track(player, playlist) != 0) {
                fprintf(stderr, "Failed to play previous track\n");
            }
        }
        
        if (player->state == PLAYER_STATE_PLAYING) {
            off_t position = mpg123_tell(player->mh);
            off_t length = mpg123_length(player->mh);
            if (length > 0 && position >= length - 1000) {
                int current, total;
                playlist_get_info(playlist, &current, &total);
                if (total > 1) {
                    playlist_next(playlist);
                    if (play_current_track(player, playlist) != 0) {
                        fprintf(stderr, "Failed to auto-advance to next track\n");
                    }
                }
            }
        }
        
        usleep(100000);
    }

    if (player) {
        audio_player_cleanup(player);
    }
    if (playlist) {
        playlist_destroy(playlist);
    }

    return 0;
} 