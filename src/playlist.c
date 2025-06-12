#include "playlist.h"
#include <strings.h>

#define INITIAL_CAPACITY 16

Playlist *playlist_create(void) {
  Playlist *playlist = malloc(sizeof(Playlist));
  if (!playlist)
    return NULL;

  playlist->files = malloc(sizeof(char *) * INITIAL_CAPACITY);
  if (!playlist->files) {
    free(playlist);
    return NULL;
  }

  playlist->count = 0;
  playlist->current_index = 0;
  playlist->capacity = INITIAL_CAPACITY;

  return playlist;
}

void playlist_destroy(Playlist *playlist) {
  if (!playlist)
    return;

  for (int i = 0; i < playlist->count; i++) {
    free(playlist->files[i]);
  }
  free(playlist->files);
  free(playlist);
}

int is_mp3_file(const char *filename) {
  const char *ext = strrchr(filename, '.');
  if (!ext)
    return 0;

  return (strcasecmp(ext, ".mp3") == 0);
}

static int expand_playlist(Playlist *playlist) {
  int new_capacity = playlist->capacity * 2;
  char **new_files = realloc(playlist->files, sizeof(char *) * new_capacity);
  if (!new_files)
    return -1;

  playlist->files = new_files;
  playlist->capacity = new_capacity;
  return 0;
}

int playlist_add_file(Playlist *playlist, const char *filename) {
  if (!playlist || !filename)
    return -1;

  if (playlist->count >= playlist->capacity) {
    if (expand_playlist(playlist) != 0)
      return -1;
  }

  playlist->files[playlist->count] = strdup(filename);
  if (!playlist->files[playlist->count])
    return -1;

  playlist->count++;
  return 0;
}

int playlist_add_directory(Playlist *playlist, const char *directory) {
  if (!playlist || !directory)
    return -1;

  DIR *dir = opendir(directory);
  if (!dir)
    return -1;

  struct dirent *entry;
  char filepath[1024];
  int added = 0;

  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
      continue;
    }

    if (is_mp3_file(entry->d_name)) {
      snprintf(filepath, sizeof(filepath), "%s/%s", directory, entry->d_name);

      struct stat st;
      if (stat(filepath, &st) == 0 && S_ISREG(st.st_mode)) {
        if (playlist_add_file(playlist, filepath) == 0) {
          added++;
        }
      }
    }
  }

  closedir(dir);
  return added;
}

const char *playlist_get_current(Playlist *playlist) {
  if (!playlist || playlist->count == 0)
    return NULL;
  if (playlist->current_index < 0 || playlist->current_index >= playlist->count)
    return NULL;

  return playlist->files[playlist->current_index];
}

int playlist_next(Playlist *playlist) {
  if (!playlist || playlist->count == 0)
    return -1;

  playlist->current_index++;
  if (playlist->current_index >= playlist->count) {
    playlist->current_index = 0;
  }

  return playlist->current_index;
}

int playlist_previous(Playlist *playlist) {
  if (!playlist || playlist->count == 0)
    return -1;

  playlist->current_index--;
  if (playlist->current_index < 0) {
    playlist->current_index = playlist->count - 1;
  }

  return playlist->current_index;
}

void playlist_get_info(Playlist *playlist, int *current, int *total) {
  if (!playlist) {
    if (current)
      *current = 0;
    if (total)
      *total = 0;
    return;
  }

  if (current)
    *current = playlist->current_index + 1;
  if (total)
    *total = playlist->count;
}