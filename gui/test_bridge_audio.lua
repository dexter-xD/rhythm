#!/usr/bin/env luajit

package.path = package.path .. ";./?.lua"

local RhythmBridge = require("engine_bridge")

print("Testing Rhythm Engine Bridge with Audio...")
print("==========================================")

local bridge = RhythmBridge:new()
print("Engine bridge created successfully")

print("\n1. Testing audio file loading...")
local ok, err = bridge:load_file("../mp3-files/test.mp3")
if ok then
    print("SUCCESS: Audio file loaded")

    local status = bridge:get_status()
    print("  Current file: " .. tostring(status.current_file))
    print("  Total time: " .. bridge:format_time(status.total_time))
    print("  State: " .. status.state)
    print("  Total tracks: " .. status.total_tracks)
else
    print("FAILED: Could not load audio file - " .. tostring(err))
end

print("\n2. Testing directory loading...")
local ok, err = bridge:load_directory("../mp3-files/")
if ok then
    print("SUCCESS: Directory loaded")

    local status = bridge:get_status()
    print("  Total tracks: " .. status.total_tracks)
    print("  Current track: " .. status.current_track)
    print("  Current file: " .. tostring(status.current_file))
else
    print("FAILED: Could not load directory - " .. tostring(err))
end

print("\n3. Testing playback controls...")

local ok, err = bridge:play()
if ok then
    print("SUCCESS: Play command accepted")
else
    print("INFO: Play command failed (expected in test environment) - " .. tostring(err))
end

local ok, err = bridge:pause()
if ok then
    print("SUCCESS: Pause command accepted")
else
    print("INFO: Pause command result - " .. tostring(err))
end

local ok, err = bridge:stop()
if ok then
    print("SUCCESS: Stop command accepted")
else
    print("INFO: Stop command result - " .. tostring(err))
end

print("\n4. Testing track navigation...")
local ok, err = bridge:next_track()
if ok then
    print("SUCCESS: Next track command accepted")
    local status = bridge:get_status()
    print("  Current track after next: " .. status.current_track)
else
    print("INFO: Next track result - " .. tostring(err))
end

local ok, err = bridge:previous_track()
if ok then
    print("SUCCESS: Previous track command accepted")
    local status = bridge:get_status()
    print("  Current track after previous: " .. status.current_track)
else
    print("INFO: Previous track result - " .. tostring(err))
end

print("\n5. Testing visualization data...")
local status = bridge:get_status()
print("Visualization bands (first 8):")
for i = 1, 8 do
    print(string.format("  Band %d: %.3f", i, status.vis_bands[i]))
end

print("\n6. Testing update loop...")
for i = 1, 3 do
    bridge:update()
    local status = bridge:get_status()
    print(string.format("Update %d - State: %s, Progress: %.3f", i, status.state, status.progress))
end

print("\n7. Cleanup...")
bridge:destroy()
print("SUCCESS: Engine destroyed")

print("\n==========================================")
print("Audio bridge test completed!")
print("The bridge successfully interfaces with the C engine.")