local RhythmBridge = require("engine_bridge")

print("Testing visualizer spectrum data...")

local engine = RhythmBridge:new()

local ok, err = engine:load_directory("../mp3-files/")
if not ok then
    print("Failed to load music:", err)
    return
end

local play_ok, play_err = engine:play()
if not play_ok then
    print("Failed to start playback:", play_err)
    return
end

print("Playback started, monitoring spectrum data for 10 seconds...")

local start_time = os.time()
local sample_count = 0
local max_values = {}

for i = 1, 32 do
    max_values[i] = 0
end

while os.time() - start_time < 10 do
    engine:update()
    local status = engine:get_status()

    if status and status.vis_bands then
        sample_count = sample_count + 1

        for i = 1, 32 do
            local value = status.vis_bands[i] or 0
            if value > max_values[i] then
                max_values[i] = value
            end
        end

        if sample_count % 100 == 0 then
            local active_bands = 0
            local total_energy = 0

            for i = 1, 32 do
                local value = status.vis_bands[i] or 0
                if value > 0.01 then
                    active_bands = active_bands + 1
                end
                total_energy = total_energy + value
            end

            print(string.format("Sample %d: %d active bands, total energy: %.3f", 
                  sample_count, active_bands, total_energy))
        end
    end

    os.execute("sleep 0.01")
end

print("\nSpectrum data summary:")
print("Total samples:", sample_count)

local active_bands = 0
for i = 1, 32 do
    if max_values[i] > 0.01 then
        active_bands = active_bands + 1
    end
end

print("Bands with activity:", active_bands, "out of 32")

if active_bands > 0 then
    print("Visualizer should work correctly!")

    print("\nExample maximum values per band:")
    for i = 1, math.min(10, 32) do
        print(string.format("Band %2d: %.3f", i, max_values[i]))
    end
else
    print("Warning: No spectrum data detected. Check audio engine implementation.")
end

engine:stop()
engine:destroy()
print("Test completed.")