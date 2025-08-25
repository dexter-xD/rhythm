#!/usr/bin/env luajit

package.path = package.path .. ";./?.lua"

local RhythmBridge = require("engine_bridge")

print("Testing Rhythm Engine Bridge...")
print("==============================")

print("\n1. Testing engine creation...")
local success, bridge = pcall(RhythmBridge.new, RhythmBridge)

if not success then
    print("FAILED: Could not create engine bridge: " .. tostring(bridge))
    print("Make sure the shared library is built and accessible")
    os.exit(1)
end

print("SUCCESS: Engine bridge created")

print("\n2. Testing engine validity...")
if bridge:is_valid() then
    print("SUCCESS: Engine is valid")
else
    print("FAILED: Engine is not valid")
    os.exit(1)
end

print("\n3. Testing status retrieval...")
local status = bridge:get_status()
print("SUCCESS: Got status")
print("  State: " .. tostring(status.state))
print("  Current track: " .. tostring(status.current_track))
print("  Total tracks: " .. tostring(status.total_tracks))
print("  Volume: " .. tostring(status.volume))
print("  Current file: " .. tostring(status.current_file))

print("\n4. Testing error handling...")
local ok, err = bridge:load_file("/nonexistent/file.mp3")
if not ok then
    print("SUCCESS: Error handling works - " .. tostring(err))
else
    print("UNEXPECTED: Should have failed to load nonexistent file")
end

print("\n5. Testing parameter validation...")
local ok, err = bridge:set_volume("invalid")
if not ok then
    print("SUCCESS: Parameter validation works - " .. tostring(err))
else
    print("FAILED: Should have rejected invalid volume parameter")
end

print("\n6. Testing volume control...")
local ok, err = bridge:set_volume(0.5)
if ok then
    print("SUCCESS: Volume set to 0.5")
    local status = bridge:get_status()
    print("  Confirmed volume: " .. tostring(status.volume))
else
    print("FAILED: Could not set volume - " .. tostring(err))
end

print("\n7. Testing seek parameter validation...")
local ok, err = bridge:seek(1.5)  
if not ok then
    print("SUCCESS: Seek validation works - " .. tostring(err))
else
    print("FAILED: Should have rejected seek position > 1.0")
end

print("\n8. Testing utility functions...")
print("  Time formatting: " .. bridge:format_time(125) .. " (should be 02:05)")
print("  State name: " .. bridge:get_state_name(0) .. " (should be 'stopped')")

print("\n9. Testing cleanup...")
bridge:destroy()
print("SUCCESS: Engine destroyed")

print("\n10. Testing post-cleanup error handling...")
local ok, err = pcall(function() bridge:get_status() end)
if not ok then
    print("SUCCESS: Post-cleanup access properly blocked")
else
    print("FAILED: Should have blocked access after cleanup")
end

print("\n==============================")
print("All tests completed!")
print("Bridge implementation appears to be working correctly.")