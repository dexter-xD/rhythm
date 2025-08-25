#include "cli/cli.h"

#define RESET     "\x1B[0m"
#define DIM       "\x1B[2m"
#define BOLD      "\x1B[1m"
#define WHITE     "\x1B[97m"
#define GRAY      "\x1B[90m"
#define BLUE      "\x1B[94m"
#define GREEN     "\x1B[92m"
#define YELLOW    "\x1B[93m"
#define RED       "\x1B[91m"

static void clear_input_buffer(void) {
    int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);

    char c;
    while (read(STDIN_FILENO, &c, 1) > 0) {

    }

    fcntl(STDIN_FILENO, F_SETFL, flags);
}

static int get_terminal_width(void) {
    struct winsize w;
    ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
    return w.ws_col;
}

static void format_time(int seconds, char *buffer) {
    int minutes = seconds / 60;
    seconds %= 60;
    sprintf(buffer, "%02d:%02d", minutes, seconds);
}

static void draw_progress_bar(float progress, int width) {
    int filled = (int)(progress * width);
    for (int i = 0; i < width; i++) {
        if (i < filled) {
            printf("%s▓%s", BLUE, RESET);
        } else {
            printf("%s░%s", DIM, RESET);
        }
    }
}

static void set_vis_color(int band, int total_bands, float intensity) {
    float hue = 360.0f * band / (float)(total_bands - 1);
    float s = 0.8f, v = intensity;
    float c = v * s;
    float x = c * (1 - fabsf(fmodf(hue / 60.0f, 2) - 1));
    float m = v - c;
    float r, g, b;

    if (hue < 60)      { r = c; g = x; b = 0; }
    else if (hue < 120){ r = x; g = c; b = 0; }
    else if (hue < 180){ r = 0; g = c; b = x; }
    else if (hue < 240){ r = 0; g = x; b = c; }
    else if (hue < 300){ r = x; g = 0; b = c; }
    else              { r = c; g = 0; b = x; }

    int ir = (int)((r + m) * 255);
    int ig = (int)((g + m) * 255);
    int ib = (int)((b + m) * 255);

    printf("\033[38;2;%d;%d;%dm", ir, ig, ib);
}

void cli_init(void) {
    printf("\033[?25l");
    printf("\033[2J\033[H");
}

void cli_cleanup(void) {
    printf("\033[?25h");
    printf("\033[2J\033[H");
    printf(RESET);
    fflush(stdout);
}

void cli_display_status(const RhythmStatus *status) {
    printf("\033[H\033[2J");
    clear_input_buffer(); 

    if (!status->current_file) return;

    const char *filename = strrchr(status->current_file, '/');
    filename = filename ? filename + 1 : status->current_file;

    char clean_name[256];
    strncpy(clean_name, filename, sizeof(clean_name) - 1);
    clean_name[sizeof(clean_name) - 1] = '\0';
    char *ext = strrchr(clean_name, '.');
    if (ext && strcmp(ext, ".mp3") == 0) *ext = '\0';

    char current_time[10], total_time[10];
    format_time(status->current_time, current_time);
    format_time(status->total_time, total_time);

    int term_width = get_terminal_width();
    int content_width = term_width > 80 ? 80 : term_width - 4;

    printf("\n");

    printf("  %s%s%s", BOLD WHITE, clean_name, RESET);
    if (status->total_tracks > 1) {
        printf("  %s(%d/%d)%s", GRAY, status->current_track, status->total_tracks, RESET);
    }
    printf("\n");
    printf("  %s%s / %s%s\n\n", GRAY, current_time, total_time, RESET);

    printf("  ");
    draw_progress_bar(status->progress, content_width - 4);
    printf("  %s%.0f%%%s\n\n", GRAY, status->progress * 100, RESET);

    int vis_bands = 24;
    int vis_height = 6;
    float max_val = 0.0f;

    for (int i = 0; i < vis_bands && i < 32; i++) {
        if (status->vis_bands[i] > max_val) max_val = status->vis_bands[i];
    }
    if (max_val < 0.01f) max_val = 0.01f;

    for (int row = vis_height; row > 0; row--) {
        printf("  ");
        for (int b = 0; b < vis_bands; b++) {
            float norm = status->vis_bands[b] / max_val;
            int bar_level = (int)(norm * vis_height + 0.5f);

            if (bar_level >= row) {
                set_vis_color(b, vis_bands, 0.8f + 0.2f * norm);
                printf("▊");
            } else {
                printf(" ");
            }
        }
        printf("%s\n", RESET);
    }

    printf("\n");

    printf("  %s", GRAY);
    if (status->state == PLAYER_STATE_PLAYING) {
        printf("▶ Playing");
    } else if (status->state == PLAYER_STATE_PAUSED) {
        printf("⏸ Paused");
    } else {
        printf("⏹ Stopped");
    }

    printf("    Volume: %s%.0f%%%s", WHITE, status->volume * 100, GRAY);
    printf("    [space] pause  [q] quit  [+/-] volume  [←/→] seek");
    if (status->total_tracks > 1) {
        printf("  [n] next  [p] prev");
    }
    printf("%s\n", RESET);

    printf("\n");
}

int cli_handle_input(RhythmEngine *engine) {
    struct termios oldt, newt;
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);

    int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);

    char c;
    int result = 0;

    if (read(STDIN_FILENO, &c, 1) > 0) {
        RhythmStatus status = rhythm_engine_get_status(engine);

        switch (c) {
            case ' ':
                if (status.state == PLAYER_STATE_PLAYING) {
                    rhythm_engine_pause(engine);
                } else if (status.state == PLAYER_STATE_PAUSED) {
                    rhythm_engine_play(engine);
                }
                break;
            case 'q':
            case 'Q':
                rhythm_engine_stop(engine);
                cli_cleanup();
                result = 2;
                break;
            case 'n':
            case 'N':
                result = 1;
                break;
            case 'p':
            case 'P':
                result = -1;
                break;
            case '+':
                rhythm_engine_set_volume(engine, status.volume + 0.1f);
                break;
            case '-':
                rhythm_engine_set_volume(engine, status.volume - 0.1f);
                break;
            case '\033':
                if (read(STDIN_FILENO, &c, 1) == 1 && c == '[') {
                    if (read(STDIN_FILENO, &c, 1) == 1) {
                        float seek_offset = 0.05f; 

                        switch (c) {
                            case 'C': 
                                rhythm_engine_seek(engine, status.progress + seek_offset);
                                break;
                            case 'D': 
                                rhythm_engine_seek(engine, status.progress - seek_offset);
                                break;
                        }
                    }
                }
                while (read(STDIN_FILENO, &c, 1) > 0) {
                }
                break;
            default:
                break;
        }
    }

    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    fcntl(STDIN_FILENO, F_SETFL, flags);

    clear_input_buffer();

    return result;
}