#ifndef CLI_H
#define CLI_H

#include "core/rhythm_engine.h"
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
void cli_display_status(const RhythmStatus *status);
int cli_handle_input(RhythmEngine *engine);

#endif 