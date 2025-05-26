#ifndef PLAYLIST_H
#define PLAYLIST_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>

typedef struct {
    char **files;
    int count;
    int current_index;
    int capacity;
} Playlist;


Playlist* playlist_create(void);
void playlist_destroy(Playlist *playlist);
int playlist_add_file(Playlist *playlist, const char *filename);
int playlist_add_directory(Playlist *playlist, const char *directory);
const char* playlist_get_current(Playlist *playlist);
int playlist_next(Playlist *playlist);
int playlist_previous(Playlist *playlist);
void playlist_get_info(Playlist *playlist, int *current, int *total);
int is_mp3_file(const char *filename);

#endif 