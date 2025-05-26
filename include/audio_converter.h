#ifndef AUDIO_CONVERTER_H
#define AUDIO_CONVERTER_H

#include "common.h"
#include <math.h>

void convert_audio_format(float *input, float *output, int num_samples, int input_channels, int output_channels);
void resample_audio(float *input, float *output, int input_samples, int output_samples, int channels);

#endif