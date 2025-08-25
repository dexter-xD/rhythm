#ifndef PLAYLIST_H
#define PLAYLIST_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <stdbool.h>

typedef struct {
    char **files;
    int count;
    int current_index;
    int capacity;
} Playlist;

Playlist* playlist_create(void);
void playlist_destroy(Playlist *playlist);
void playlist_clear(Playlist *playlist);

int playlist_add_file(Playlist *playlist, const char *filename);
int playlist_add_directory(Playlist *playlist, const char *directory);
int is_mp3_file(const char *filename);

const char* playlist_get_current(Playlist *playlist);
int playlist_next(Playlist *playlist);
int playlist_previous(Playlist *playlist);
int playlist_set_current(Playlist *playlist, int index);

void playlist_get_info(Playlist *playlist, int *current, int *total);
int playlist_get_count(Playlist *playlist);
int playlist_get_current_index(Playlist *playlist);
const char* playlist_get_file_at(Playlist *playlist, int index);
bool playlist_is_empty(Playlist *playlist);

#endif 