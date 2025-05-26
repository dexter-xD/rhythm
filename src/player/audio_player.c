#include "audio_player.h"


#define BUFFER_SIZE 16384
#define DEFAULT_VOLUME 2.0f 

static int pa_callback(const void *inputBuffer, void *outputBuffer,
                      unsigned long framesPerBuffer,
                      const PaStreamCallbackTimeInfo *timeInfo,
                      PaStreamCallbackFlags statusFlags,
                      void *userData) {
    AudioPlayer *player = (AudioPlayer *)userData;
    float *out = (float *)outputBuffer;
    int out_samples = framesPerBuffer;
    int out_channels = CHANNELS;
    int out_total = out_samples * out_channels;

    if (player->state != PLAYER_STATE_PLAYING) {
        memset(out, 0, out_total * sizeof(float));
        return paContinue;
    }

    int in_channels, encoding;
    long in_rate;
    mpg123_getformat(player->mh, &in_rate, &in_channels, &encoding);

    int in_samples_needed = (int)((float)out_samples * ((float)in_rate / (float)SAMPLE_RATE)) + 4;
    int in_total = in_samples_needed * in_channels;

    float *in_buffer = (float *)malloc(in_total * sizeof(float));
    if (!in_buffer) {
        fprintf(stderr, "Failed to allocate input buffer\n");
        memset(out, 0, out_total * sizeof(float));
        return paAbort;
    }

    size_t bytes_read = 0;
    int samples_read = 0;
    int max_attempts = 10;
    int attempts = 0;
    while (samples_read < in_total && attempts < max_attempts) {
        size_t got = 0;
        int err = mpg123_read(player->mh, (unsigned char *)(in_buffer + samples_read), (in_total - samples_read) * sizeof(float), &got);
        if (err == MPG123_DONE) {
            player->state = PLAYER_STATE_STOPPED;
            memset(out, 0, out_total * sizeof(float));
            free(in_buffer);
            return paComplete;
        } else if (err != MPG123_OK) {
            fprintf(stderr, "Error reading audio data: %s\n", mpg123_strerror(player->mh));
            memset(out, 0, out_total * sizeof(float));
            free(in_buffer);
            return paAbort;
        }
        samples_read += got / sizeof(float);
        attempts++;
    }

    float *ch_buffer = NULL;
    if (in_channels != out_channels) {
        ch_buffer = (float *)malloc(in_samples_needed * out_channels * sizeof(float));
        if (!ch_buffer) {
            free(in_buffer);
            memset(out, 0, out_total * sizeof(float));
            return paAbort;
        }
        convert_audio_format(in_buffer, ch_buffer, in_samples_needed, in_channels, out_channels);
    } else {
        ch_buffer = in_buffer;
    }

    if (in_rate != SAMPLE_RATE) {
        resample_audio(ch_buffer, out, in_samples_needed, out_samples, out_channels);
    } else {
        memcpy(out, ch_buffer, out_total * sizeof(float));
    }

    for (int i = 0; i < out_total; i++) {
        float sample = out[i] * player->volume;
        if (sample > 1.0f) sample = 1.0f;
        if (sample < -1.0f) sample = -1.0f;
        out[i] = sample;
    }

    int bands = 32;
    int samples_per_band = out_total / bands;
    for (int b = 0; b < bands; b++) {
        float sum = 0.0f;
        int start = b * samples_per_band;
        int end = (b == bands - 1) ? out_total : (b + 1) * samples_per_band;
        for (int i = start; i < end; i++) {
            sum += out[i] * out[i];
        }
        int count = end - start;
        player->vis_bands[b] = count > 0 ? sqrtf(sum / count) : 0.0f;
    }

    if (ch_buffer != in_buffer) free(ch_buffer);
    free(in_buffer);
    return paContinue;
}

static void list_audio_devices(void) {
    int numDevices = Pa_GetDeviceCount();
    if (numDevices < 0) {
        fprintf(stderr, "Error getting device count: %s\n", Pa_GetErrorText(numDevices));
        return;
    }

    fprintf(stderr, "Available audio devices:\n");
    for (int i = 0; i < numDevices; i++) {
        const PaDeviceInfo *deviceInfo = Pa_GetDeviceInfo(i);
        if (deviceInfo) {
            fprintf(stderr, "Device %d: %s (in: %d, out: %d)\n",
                    i, deviceInfo->name,
                    deviceInfo->maxInputChannels,
                    deviceInfo->maxOutputChannels);
        }
    }
}

static PaDeviceIndex find_output_device(void) {
    int numDevices = Pa_GetDeviceCount();
    if (numDevices < 0) {
        fprintf(stderr, "Error getting device count: %s\n", Pa_GetErrorText(numDevices));
        return paNoDevice;
    }

    PaDeviceIndex defaultOutput = Pa_GetDefaultOutputDevice();
    if (defaultOutput != paNoDevice) {
        const PaDeviceInfo *deviceInfo = Pa_GetDeviceInfo(defaultOutput);
        if (deviceInfo && deviceInfo->maxOutputChannels > 0) {
            return defaultOutput;
        }
    }

    for (int i = 0; i < numDevices; i++) {
        const PaDeviceInfo *deviceInfo = Pa_GetDeviceInfo(i);
        if (deviceInfo && deviceInfo->maxOutputChannels > 0) {
            return i;
        }
    }

    return paNoDevice;
}

AudioPlayer* audio_player_init(void) {
    AudioPlayer *player = (AudioPlayer *)malloc(sizeof(AudioPlayer));
    if (!player) {
        fprintf(stderr, "Failed to allocate player\n");
        return NULL;
    }

    PaError err = Pa_Initialize();
    if (err != paNoError) {
        fprintf(stderr, "Failed to initialize PortAudio: %s\n", Pa_GetErrorText(err));
        free(player);
        return NULL;
    }

    player->mh = mpg123_new(NULL, NULL);
    if (!player->mh) {
        fprintf(stderr, "Failed to create mpg123 handle\n");
        Pa_Terminate();
        free(player);
        return NULL;
    }

    mpg123_param(player->mh, MPG123_ADD_FLAGS, MPG123_FORCE_FLOAT, 0.0);
    mpg123_param(player->mh, MPG123_ADD_FLAGS, MPG123_FORCE_STEREO, 0.0);
    mpg123_param(player->mh, MPG123_ADD_FLAGS, MPG123_QUIET, 0.0);
    mpg123_param(player->mh, MPG123_ADD_FLAGS, MPG123_IGNORE_INFOFRAME, 0.0);

    PaDeviceIndex device = find_output_device();
    if (device == paNoDevice) {
        fprintf(stderr, "No suitable audio output device found\n");
        list_audio_devices();
        mpg123_delete(player->mh);
        Pa_Terminate();
        free(player);
        return NULL;
    }

    const PaDeviceInfo *deviceInfo = Pa_GetDeviceInfo(device);
    PaStreamParameters outputParameters = {
        .device = device,
        .channelCount = CHANNELS,
        .sampleFormat = paFloat32,
        .suggestedLatency = Pa_GetDeviceInfo(device)->defaultLowOutputLatency,
        .hostApiSpecificStreamInfo = NULL
    };

    err = Pa_OpenStream(&player->stream,
                       NULL,
                       &outputParameters,
                       SAMPLE_RATE,
                       FRAMES_PER_BUFFER,
                       paClipOff,
                       pa_callback,
                       player);
    
    if (err != paNoError) {
        fprintf(stderr, "Failed to open audio stream: %s\n", Pa_GetErrorText(err));
        fprintf(stderr, "Trying to list available devices...\n");
        list_audio_devices();
        mpg123_delete(player->mh);
        Pa_Terminate();
        free(player);
        return NULL;
    }

    player->state = PLAYER_STATE_STOPPED;
    player->volume = DEFAULT_VOLUME;
    player->current_file = NULL;
    player->vis_level = 0.0f;

    return player;
}

void audio_player_cleanup(AudioPlayer *player) {
    if (!player) return;

    if (player->stream) {
        Pa_StopStream(player->stream);
        Pa_CloseStream(player->stream);
    }
    if (player->mh) {
        mpg123_close(player->mh);
        mpg123_delete(player->mh);
    }
    if (player->current_file) {
        free(player->current_file);
    }
    free(player);
}

int audio_player_play(AudioPlayer *player, const char *filename) {
    if (!player || !filename) return -1;

    audio_player_stop(player);

    if (mpg123_open(player->mh, filename) != MPG123_OK) {
        fprintf(stderr, "Failed to open file: %s\n", mpg123_strerror(player->mh));
        return -1;
    }

    int channels, encoding;
    long rate;
    if (mpg123_getformat(player->mh, &rate, &channels, &encoding) != MPG123_OK) {
        fprintf(stderr, "Failed to get format: %s\n", mpg123_strerror(player->mh));
        mpg123_close(player->mh);
        return -1;
    }

    if (player->current_file) {
        free(player->current_file);
    }
    player->current_file = strdup(filename);

    PaError err = Pa_StartStream(player->stream);
    if (err != paNoError) {
        fprintf(stderr, "Failed to start stream: %s\n", Pa_GetErrorText(err));
        mpg123_close(player->mh);
        return -1;
    }

    player->state = PLAYER_STATE_PLAYING;
    return 0;
}

void audio_player_pause(AudioPlayer *player) {
    if (!player || player->state != PLAYER_STATE_PLAYING) return;

    PaError err = Pa_StopStream(player->stream);
    if (err == paNoError) {
        player->state = PLAYER_STATE_PAUSED;
    }
}

void audio_player_resume(AudioPlayer *player) {
    if (!player || player->state != PLAYER_STATE_PAUSED) return;

    PaError err = Pa_StartStream(player->stream);
    if (err == paNoError) {
        player->state = PLAYER_STATE_PLAYING;
    }
}

void audio_player_stop(AudioPlayer *player) {
    if (!player) return;

    if (player->stream) {
        Pa_StopStream(player->stream);
    }
    if (player->mh) {
        mpg123_close(player->mh);
    }
    player->state = PLAYER_STATE_STOPPED;
}

void audio_player_set_volume(AudioPlayer *player, float volume) {
    if (!player) return;
    if (volume < 0.0f) volume = 0.0f;
    if (volume > 2.0f) volume = 2.0f;
    player->volume = volume;
}

PlayerState audio_player_get_state(AudioPlayer *player) {
    return player ? player->state : PLAYER_STATE_STOPPED;
} 