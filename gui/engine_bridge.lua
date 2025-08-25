local ffi = require("ffi")

ffi.cdef[[
    // Forward declarations
    typedef struct RhythmEngine RhythmEngine;

    // Error codes
    typedef enum {
        RHYTHM_OK = 0,
        RHYTHM_ERROR_INIT = -1,
        RHYTHM_ERROR_FILE_NOT_FOUND = -2,
        RHYTHM_ERROR_INVALID_FORMAT = -3,
        RHYTHM_ERROR_AUDIO_DEVICE = -4,
        RHYTHM_ERROR_MEMORY = -5,
        RHYTHM_ERROR_NULL_POINTER = -6,
        RHYTHM_ERROR_INVALID_STATE = -7
    } RhythmError;

    // Player state enum
    typedef enum {
        PLAYER_STATE_STOPPED = 0,
        PLAYER_STATE_PLAYING = 1,
        PLAYER_STATE_PAUSED = 2
    } PlayerState;

    // Status structure
    typedef struct {
        char* current_file;
        int current_track;
        int total_tracks;
        float progress;
        int current_time;
        int total_time;
        PlayerState state;
        float volume;
        float vis_bands[32];
    } RhythmStatus;

    // Engine lifecycle management
    RhythmEngine* rhythm_engine_create(void);
    void rhythm_engine_destroy(RhythmEngine* engine);

    // File and playlist management
    RhythmError rhythm_engine_load_file(RhythmEngine* engine, const char* filename);
    RhythmError rhythm_engine_load_directory(RhythmEngine* engine, const char* directory);

    // Playback control
    RhythmError rhythm_engine_play(RhythmEngine* engine);
    RhythmError rhythm_engine_pause(RhythmEngine* engine);
    RhythmError rhythm_engine_stop(RhythmEngine* engine);
    RhythmError rhythm_engine_next_track(RhythmEngine* engine);
    RhythmError rhythm_engine_previous_track(RhythmEngine* engine);
    RhythmError rhythm_engine_seek(RhythmEngine* engine, float position);
    RhythmError rhythm_engine_set_volume(RhythmEngine* engine, float volume);

    // Status queries and updates
    RhythmStatus rhythm_engine_get_status(RhythmEngine* engine);
    void rhythm_engine_update(RhythmEngine* engine);
    RhythmError rhythm_engine_get_last_error(RhythmEngine* engine);
    const char* rhythm_engine_error_string(RhythmError error);

    // Memory management
    void free(void* ptr);
]]

local ERROR_MESSAGES = {
    [0] = "OK",
    [-1] = "Initialization error",
    [-2] = "File not found",
    [-3] = "Invalid format",
    [-4] = "Audio device error",
    [-5] = "Memory error",
    [-6] = "Null pointer error",
    [-7] = "Invalid state error"
}

local PLAYER_STATES = {
    [0] = "stopped",
    [1] = "playing", 
    [2] = "paused"
}

local RhythmBridge = {}
RhythmBridge.__index = RhythmBridge

function RhythmBridge:new()
    local bridge = {
        engine = nil,
        engine_lib = nil,
        last_error = 0,
        is_initialized = false
    }
    setmetatable(bridge, self)

    local success, lib = pcall(function()

        local possible_paths = {
            "./librhythm_engine.so",
            "../build/librhythm_engine.so", 
            "librhythm_engine.so",
            "./build/librhythm_engine.so"
        }

        for _, path in ipairs(possible_paths) do
            local ok, result = pcall(ffi.load, path)
            if ok then
                return result
            end
        end

        return ffi.load("rhythm_engine")
    end)

    if not success then
        error("Failed to load rhythm engine library: " .. tostring(lib))
    end

    bridge.engine_lib = lib

    bridge.engine = bridge.engine_lib.rhythm_engine_create()
    if bridge.engine == nil then
        error("Failed to create rhythm engine instance")
    end

    bridge.is_initialized = true
    return bridge
end

function RhythmBridge:destroy()
    if self.is_initialized and self.engine ~= nil then
        self.engine_lib.rhythm_engine_destroy(self.engine)
        self.engine = nil
        self.is_initialized = false
    end
end

function RhythmBridge:_handle_error(error_code, operation)

    local error_num = tonumber(error_code)
    self.last_error = error_num
    if error_num ~= 0 then
        local error_msg = ERROR_MESSAGES[error_num] or ("Unknown error: " .. tostring(error_num))
        local full_msg = string.format("Engine error during %s: %s", operation, error_msg)
        print("Warning: " .. full_msg)
        return false, full_msg
    end
    return true, nil
end

function RhythmBridge:_check_engine()
    if not self.is_initialized or self.engine == nil then
        error("Engine not initialized or already destroyed")
    end
end

function RhythmBridge:load_file(filename)
    self:_check_engine()
    if type(filename) ~= "string" then
        return false, "Filename must be a string"
    end

    local result = self.engine_lib.rhythm_engine_load_file(self.engine, filename)
    return self:_handle_error(result, "load_file")
end

function RhythmBridge:load_directory(directory)
    self:_check_engine()
    if type(directory) ~= "string" then
        return false, "Directory must be a string"
    end

    local result = self.engine_lib.rhythm_engine_load_directory(self.engine, directory)
    return self:_handle_error(result, "load_directory")
end

function RhythmBridge:play()
    self:_check_engine()
    local result = self.engine_lib.rhythm_engine_play(self.engine)
    return self:_handle_error(result, "play")
end

function RhythmBridge:pause()
    self:_check_engine()
    local result = self.engine_lib.rhythm_engine_pause(self.engine)
    return self:_handle_error(result, "pause")
end

function RhythmBridge:stop()
    self:_check_engine()
    local result = self.engine_lib.rhythm_engine_stop(self.engine)
    return self:_handle_error(result, "stop")
end

function RhythmBridge:next_track()
    self:_check_engine()
    local result = self.engine_lib.rhythm_engine_next_track(self.engine)
    return self:_handle_error(result, "next_track")
end

function RhythmBridge:previous_track()
    self:_check_engine()
    local result = self.engine_lib.rhythm_engine_previous_track(self.engine)
    return self:_handle_error(result, "previous_track")
end

function RhythmBridge:seek(position)
    self:_check_engine()
    if type(position) ~= "number" then
        return false, "Position must be a number"
    end
    if position < 0.0 or position > 1.0 then
        return false, "Position must be between 0.0 and 1.0"
    end

    local result = self.engine_lib.rhythm_engine_seek(self.engine, position)
    return self:_handle_error(result, "seek")
end

function RhythmBridge:set_volume(volume)
    self:_check_engine()
    if type(volume) ~= "number" then
        return false, "Volume must be a number"
    end
    if volume < 0.0 or volume > 2.0 then
        return false, "Volume must be between 0.0 and 2.0"
    end

    local result = self.engine_lib.rhythm_engine_set_volume(self.engine, volume)
    return self:_handle_error(result, "set_volume")
end

function RhythmBridge:update()
    self:_check_engine()
    self.engine_lib.rhythm_engine_update(self.engine)
end

function RhythmBridge:get_status()
    self:_check_engine()
    local c_status = self.engine_lib.rhythm_engine_get_status(self.engine)

    local state_num = tonumber(c_status.state)
    local status = {
        current_file = nil,
        current_track = c_status.current_track,
        total_tracks = c_status.total_tracks,
        progress = c_status.progress,
        current_time = c_status.current_time,
        total_time = c_status.total_time,
        state = PLAYER_STATES[state_num] or "unknown",
        state_id = state_num,
        volume = c_status.volume,
        vis_bands = {}
    }

    if c_status.current_file ~= nil then
        status.current_file = ffi.string(c_status.current_file)
    end

    for i = 0, 31 do
        status.vis_bands[i + 1] = c_status.vis_bands[i]
    end

    return status
end

function RhythmBridge:get_last_error()
    self:_check_engine()
    local error_code = self.engine_lib.rhythm_engine_get_last_error(self.engine)
    return error_code, ERROR_MESSAGES[error_code] or ("Unknown error: " .. tostring(error_code))
end

function RhythmBridge:get_error_string(error_code)
    if not error_code then
        error_code = self.last_error
    end
    return ERROR_MESSAGES[error_code] or ("Unknown error: " .. tostring(error_code))
end

function RhythmBridge:is_valid()
    return self.is_initialized and self.engine ~= nil
end

function RhythmBridge:get_state_name(state_id)
    return PLAYER_STATES[state_id] or "unknown"
end

function RhythmBridge:format_time(seconds)
    if not seconds or seconds < 0 then
        return "00:00"
    end
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

return RhythmBridge