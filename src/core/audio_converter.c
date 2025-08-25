#include "core/audio_converter.h"


// low-pass filter
// static void apply_lowpass_filter(float *samples, int num_samples, int channels) {
//     float alpha = 0.1f; // Filter coefficient
//     float prev[2] = {0.0f, 0.0f}; // Previous samples for each channel
//     for (int i = 0; i < num_samples * channels; i += channels) {
//         for (int ch = 0; ch < channels; ch++) {
//             float current = samples[i + ch];
//             samples[i + ch] = prev[ch] + alpha * (current - prev[ch]);
//             prev[ch] = samples[i + ch];
//         }
//     }
// }

// normalization 
// static void normalize_volume(float *samples, int num_samples, int channels) {
//     float max_amplitude = 0.0f;
//     for (int i = 0; i < num_samples * channels; i++) {
//         float abs_val = fabsf(samples[i]);
//         if (abs_val > max_amplitude) {
//             max_amplitude = abs_val;
//         }
//     }
//     if (max_amplitude > 0.0f && max_amplitude < 0.9f) {
//         float scale = 0.9f / max_amplitude;
//         for (int i = 0; i < num_samples * channels; i++) {
//             samples[i] *= scale;
//         }
//     }
// }

void convert_audio_format(float *input, float *output, int num_samples, int input_channels, int output_channels) {
    if (input_channels == output_channels) {
        memcpy(output, input, num_samples * input_channels * sizeof(float));
    } else {
        if (input_channels == 1 && output_channels == 2) {
            for (int i = 0; i < num_samples; i++) {
                float sample = input[i];
                output[i * 2] = sample;
                output[i * 2 + 1] = sample;
            }
        } else if (input_channels == 2 && output_channels == 1) {
            for (int i = 0; i < num_samples; i++) {
                float left = input[i * 2];
                float right = input[i * 2 + 1];
                output[i] = (left + right) * 0.5f;
            }
        }
    }
}

void resample_audio(float *input, float *output, int input_samples, int output_samples, int channels) {
    if (input_samples == output_samples) {
        memcpy(output, input, input_samples * channels * sizeof(float));
        return;
    }
    float ratio = (float)input_samples / output_samples;
    for (int i = 0; i < output_samples; i++) {
        float pos = i * ratio;
        int pos0 = (int)pos;
        float frac = pos - pos0;
        for (int ch = 0; ch < channels; ch++) {
            if (pos0 + 1 >= input_samples) {
                output[i * channels + ch] = input[pos0 * channels + ch];
            } else {
                float sample0 = input[pos0 * channels + ch];
                float sample1 = input[(pos0 + 1) * channels + ch];
                output[i * channels + ch] = sample0 + (sample1 - sample0) * frac;
            }
        }
    }
} 