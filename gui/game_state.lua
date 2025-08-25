local RhythmBridge = require("engine_bridge")
local Player = require("ui.player")
local Controls = require("ui.controls")
local Visualizer = require("ui.visualizer")
local GameState = {}

GameState.initialized = false
GameState.window_width = 800
GameState.window_height = 600
GameState.engine = nil
GameState.last_status = nil

GameState.theme = {

    bg_primary = {0.08, 0.08, 0.12, 1.0},    
    bg_secondary = {0.12, 0.12, 0.18, 1.0},  
    bg_elevated = {0.15, 0.15, 0.22, 1.0},   
    bg_surface = {0.18, 0.18, 0.25, 1.0},    

    text_primary = {0.95, 0.95, 0.98, 1.0},  
    text_secondary = {0.70, 0.70, 0.80, 1.0}, 
    text_muted = {0.50, 0.50, 0.60, 1.0},    
    text_disabled = {0.35, 0.35, 0.45, 1.0}, 

    accent_pink = {0.95, 0.35, 0.65, 1.0},   
    accent_purple = {0.65, 0.35, 0.95, 1.0}, 
    accent_blue = {0.35, 0.65, 0.95, 1.0},   
    accent_cyan = {0.35, 0.95, 0.85, 1.0},   
    accent_orange = {0.95, 0.65, 0.35, 1.0}, 

    progress_bg = {0.25, 0.25, 0.35, 1.0},   
    progress_fill = {0.95, 0.35, 0.65, 1.0}, 

    button_normal = {0.20, 0.20, 0.28, 1.0},
    button_hover = {0.25, 0.25, 0.35, 1.0},
    button_active = {0.30, 0.30, 0.40, 1.0},
    button_primary = {0.95, 0.35, 0.65, 1.0},

    glass = {0.15, 0.15, 0.22, 0.90},
    glass_border = {0.35, 0.35, 0.45, 0.30},

    shadow = {0.0, 0.0, 0.0, 0.40},
    shadow_strong = {0.0, 0.0, 0.0, 0.60},

    gradient_main = {
        {0.95, 0.35, 0.65, 1.0}, 
        {0.65, 0.35, 0.95, 1.0}  
    },
    gradient_wave = {
        {0.95, 0.65, 0.35, 1.0}, 
        {0.95, 0.35, 0.65, 1.0}, 
        {0.65, 0.35, 0.95, 1.0}, 
        {0.35, 0.65, 0.95, 1.0}, 
        {0.35, 0.95, 0.85, 1.0}  
    }
}

GameState.layout = {
    padding = 20,
    margin = 10,
    button_height = 40,
    progress_bar_height = 20,
    header_height = 60,
    footer_height = 80
}

GameState.app_state = {
    current_screen = "player", 
    is_playing = false,
    is_paused = false,
    volume = 0.8,
    current_song = "No song loaded",
    current_time = 0,
    total_time = 0,
    progress = 0.0,
    current_track = 0,
    total_tracks = 0,
    previous_state = "stopped", 
    was_playing_before_end = false, 
    just_auto_advanced = false, 
    user_seeking = false, 
    last_seek_time = 0, 

    shuffle_enabled = false,
    repeat_mode = "off", 
    original_track_order = {}, 
    shuffled_track_order = {} 
}

GameState.player_component = nil
GameState.controls_component = nil
GameState.visualizer_component = nil

GameState.galactic_journey = {
    warp_stars = {},
    galaxy_spiral = {},
    quantum_particles = {},

    time = 0,
    initialized = false
}

function GameState:init()
    if self.initialized then
        return
    end

    self.window_width, self.window_height = love.graphics.getDimensions()

    self.floating_image = love.graphics.newImage("assets/png/pngwing.com.png")
    self.floating_animation = {
        time = 0,
        float_offset = 0,
        rotation = 0,
        scale = 1.0,
        glow_intensity = 0.5
    }

    self.fonts = {
        default = love.graphics.getFont(),
        large = love.graphics.newFont(18),
        small = love.graphics.newFont(12)
    }

    local success, engine = pcall(RhythmBridge.new, RhythmBridge)
    if success then
        self.engine = engine
        print("Engine bridge initialized successfully")

        local possible_paths = {"./mp3-files/", "../mp3-files/", "mp3-files/"}
        local loaded = false

        for _, path in ipairs(possible_paths) do
            local ok, err = self.engine:load_directory(path)
            if ok then
                print("Loaded music directory:", path)
                loaded = true
                break
            end
        end

        if not loaded then
            print("Could not find music directory. Tried: ./mp3-files/, ../mp3-files/, mp3-files/")
            print("GUI will run without music files loaded")
        end
    else
        print("Warning: Could not initialize engine bridge:", engine)
        print("GUI will run in demo mode without audio functionality")
    end

    self.player_component = Player:new(self)
    self.controls_component = Controls:new(self)
    self.visualizer_component = Visualizer:new(self)

    self.initialized = true
    print("GameState initialized")
end

function GameState:update(dt)

    self.floating_animation.time = self.floating_animation.time + dt

    local audio_energy = 0
    local bass_energy = 0
    local mid_energy = 0
    local high_energy = 0

    if self.visualizer_component and self.visualizer_component.animation then

        for i = 1, 8 do 
            bass_energy = bass_energy + (self.visualizer_component.animation.current_bands[i] or 0)
        end
        for i = 9, 20 do 
            mid_energy = mid_energy + (self.visualizer_component.animation.current_bands[i] or 0)
        end
        for i = 21, 32 do 
            high_energy = high_energy + (self.visualizer_component.animation.current_bands[i] or 0)
        end

        bass_energy = math.min(1.0, bass_energy / 4.0)
        mid_energy = math.min(1.0, mid_energy / 6.0)
        high_energy = math.min(1.0, high_energy / 6.0)
        audio_energy = (bass_energy + mid_energy + high_energy) / 3.0
    end

    local status = self.last_status
    local is_playing = status and status.state == "playing"

    local base_glow = 0.6 + 0.15 * math.sin(self.floating_animation.time * 1.1)
    local bass_glow = is_playing and (bass_energy * 0.4) or 0
    local high_glow = is_playing and (high_energy * 0.2) or 0
    self.floating_animation.glow_intensity = base_glow + bass_glow + high_glow

    local gentle_float = math.sin(self.floating_animation.time * 0.7) * 1.5
    local bass_float = is_playing and (bass_energy * 6) or 0
    local mid_float = is_playing and (mid_energy * math.sin(self.floating_animation.time * 2.3) * 2) or 0
    self.floating_animation.float_offset = gentle_float + bass_float + mid_float

    local rotation_speed = is_playing and (high_energy * 0.3 + mid_energy * 0.1) or 0
    self.floating_animation.rotation = self.floating_animation.rotation + dt * rotation_speed

    local base_scale = 1.0 + math.sin(self.floating_animation.time * 0.8) * 0.025
    local bass_scale = is_playing and (bass_energy * 0.15) or 0
    local mid_scale = is_playing and (mid_energy * 0.08) or 0
    local high_scale = is_playing and (high_energy * 0.04) or 0
    self.floating_animation.scale = base_scale + bass_scale + mid_scale + high_scale

    local color_cycle = self.floating_animation.time * 0.3
    local bass_color_mod = bass_energy * math.sin(self.floating_animation.time * 1.7) * 0.3
    local mid_color_mod = mid_energy * math.sin(self.floating_animation.time * 2.1) * 0.2
    local high_color_mod = high_energy * math.sin(self.floating_animation.time * 3.3) * 0.15

    self.floating_animation.glow_color_shift = {
        r = 0.95 + 0.05 * math.sin(color_cycle + bass_energy * 2) + bass_color_mod,
        g = 0.35 + 0.15 * math.sin(color_cycle + mid_energy * 3) + mid_color_mod,
        b = 0.65 + 0.25 * math.sin(color_cycle + high_energy * 4) + high_color_mod
    }

    local beat_threshold = 0.6
    local strong_beat_threshold = 0.8
    local current_bass = bass_energy
    local previous_bass = self.floating_animation.previous_bass or 0
    local beat_detected = is_playing and current_bass > beat_threshold and previous_bass < beat_threshold
    local strong_beat_detected = is_playing and current_bass > strong_beat_threshold and previous_bass < strong_beat_threshold

    if strong_beat_detected then
        self.floating_animation.beat_pulse = 1.5  
        self.floating_animation.beat_time = self.floating_animation.time
        self.floating_animation.strong_beat = true
    elseif beat_detected then
        self.floating_animation.beat_pulse = 1.0
        self.floating_animation.beat_time = self.floating_animation.time
        self.floating_animation.strong_beat = false
    end

    if self.floating_animation.beat_pulse then
        local pulse_age = self.floating_animation.time - (self.floating_animation.beat_time or 0)
        local decay_rate = self.floating_animation.strong_beat and 2.5 or 3.0
        self.floating_animation.beat_pulse = math.max(0, self.floating_animation.beat_pulse - pulse_age * decay_rate)
    end

    self.floating_animation.particle_triggers = {
        bass_trigger = bass_energy > 0.7,
        mid_trigger = mid_energy > 0.6,
        high_trigger = high_energy > 0.5,
        combined_trigger = audio_energy > 0.8
    }

    local harmonic_phase = self.floating_animation.time * 0.5
    self.floating_animation.harmonic_resonance = {
        fundamental = bass_energy * math.sin(harmonic_phase),
        second = mid_energy * math.sin(harmonic_phase * 2),
        third = high_energy * math.sin(harmonic_phase * 3),
        combined = (bass_energy + mid_energy + high_energy) / 3 * math.sin(harmonic_phase * 1.618) 
    }

    self.floating_animation.previous_bass = current_bass

    local spectral_centroid = 0
    local spectral_rolloff = 0
    local spectral_flux = 0

    if self.visualizer_component and self.visualizer_component.animation then

        local weighted_sum = 0
        local magnitude_sum = 0
        for i = 1, 32 do
            local magnitude = self.visualizer_component.animation.current_bands[i] or 0
            weighted_sum = weighted_sum + (i * magnitude)
            magnitude_sum = magnitude_sum + magnitude
        end
        spectral_centroid = magnitude_sum > 0 and (weighted_sum / magnitude_sum / 32) or 0

        local energy_threshold = magnitude_sum * 0.85
        local cumulative_energy = 0
        for i = 1, 32 do
            cumulative_energy = cumulative_energy + (self.visualizer_component.animation.current_bands[i] or 0)
            if cumulative_energy >= energy_threshold then
                spectral_rolloff = i / 32
                break
            end
        end

        local current_spectrum_sum = 0
        local previous_spectrum_sum = self.floating_animation.previous_spectrum_sum or 0
        for i = 1, 32 do
            current_spectrum_sum = current_spectrum_sum + (self.visualizer_component.animation.current_bands[i] or 0)
        end
        spectral_flux = math.abs(current_spectrum_sum - previous_spectrum_sum)
        self.floating_animation.previous_spectrum_sum = current_spectrum_sum
    end

    self.floating_animation.spectral_features = {
        centroid = spectral_centroid,
        rolloff = spectral_rolloff,
        flux = spectral_flux,
        brightness = spectral_centroid * audio_energy,
        warmth = (1 - spectral_centroid) * bass_energy,
        dynamics = spectral_flux * 0.1
    }

    if beat_detected then
        local current_time = self.floating_animation.time
        local last_beat_time = self.floating_animation.last_beat_time or current_time
        local beat_interval = current_time - last_beat_time

        if beat_interval > 0.3 and beat_interval < 2.0 then 
            local estimated_bpm = 60 / beat_interval
            self.floating_animation.estimated_bpm = estimated_bpm
            self.floating_animation.beat_phase = 0 
        end

        self.floating_animation.last_beat_time = current_time
    end

    if self.floating_animation.estimated_bpm then
        local beat_duration = 60 / self.floating_animation.estimated_bpm
        self.floating_animation.beat_phase = (self.floating_animation.beat_phase or 0) + dt / beat_duration
        if self.floating_animation.beat_phase > 1 then
            self.floating_animation.beat_phase = self.floating_animation.beat_phase - 1
        end
    end

    self.floating_animation.audio_energy = audio_energy
    self.floating_animation.bass_energy = bass_energy
    self.floating_animation.mid_energy = mid_energy
    self.floating_animation.high_energy = high_energy
    self.floating_animation.is_playing = is_playing

    if self.engine and self.engine:is_valid() then
        self.engine:update()
        local status = self.engine:get_status()

        if status then
            local previous_state = self.app_state.previous_state
            local current_state = status.state

            self.last_status = status
            self.app_state.current_song = status.current_file or "No song loaded"
            self.app_state.current_time = status.current_time
            self.app_state.total_time = status.total_time
            self.app_state.progress = status.progress
            self.app_state.current_track = status.current_track
            self.app_state.total_tracks = status.total_tracks
            self.app_state.volume = status.volume

            if previous_state ~= current_state then
                print(string.format("State change: %s -> %s (track %d/%d, progress %.2f)", 
                      previous_state, current_state, status.current_track, status.total_tracks, status.progress))

                if current_state == "playing" then
                    self.app_state.just_auto_advanced = false
                end
            end

            if self.app_state.just_auto_advanced and previous_state == "playing" and current_state == "stopped" and 
               status.progress < 0.1 and status.current_track < status.total_tracks then
                print("Track failed to play after auto-advance, trying next track...")
                self.app_state.just_auto_advanced = false

                local ok, err = self.engine:next_track()
                if ok then
                    love.timer.sleep(0.1)
                    local play_ok, play_err = self.engine:play()
                    if play_ok then
                        print("Successfully skipped to next working track")
                    else
                        print("Failed to play next track:", play_err)
                    end
                else
                    print("Failed to skip to next track:", err)
                end
            end

            if previous_state == "playing" and current_state == "stopped" and 
               status.total_tracks >= 1 and status.progress >= 0.99 and 
               not self.app_state.user_seeking and
               (status.current_time >= status.total_time - 2) then

                local next_track = self:getNextTrack()

                if next_track then
                    print(string.format("Song ended (%.1f%% complete), auto-advancing with mode: shuffle=%s, repeat=%s", 
                          status.progress * 100, 
                          self.app_state.shuffle_enabled and "on" or "off",
                          self.app_state.repeat_mode))

                    love.timer.sleep(0.1)

                    local ok, err = self:_navigateToTrack(next_track)
                    if ok then

                        love.timer.sleep(0.1)

                        local play_ok, play_err = self.engine:play()
                        if play_ok then
                            print("Auto-advance successful, playing track", next_track)

                            self.app_state.just_auto_advanced = true
                        else
                            print("Auto-advance failed to start playback:", play_err)
                        end
                    else
                        print("Auto-advance failed to navigate to track:", err)
                    end
                else

                    print("End of playlist reached, no repeat enabled")
                end
            elseif previous_state == "playing" and current_state == "stopped" and status.progress < 0.95 then

                print(string.format("Song stopped unexpectedly at %.1f%% - this might be a seeking issue", status.progress * 100))
            end

            if status.state == "playing" then
                self.app_state.is_playing = true
                self.app_state.is_paused = false
            elseif status.state == "paused" then
                self.app_state.is_playing = false
                self.app_state.is_paused = true
            else 
                self.app_state.is_playing = false
                self.app_state.is_paused = false
            end

            self.app_state.previous_state = current_state

            if self.app_state.user_seeking and 
               love.timer.getTime() - self.app_state.last_seek_time > 2.0 then
                self.app_state.user_seeking = false
            end
        end
    end

    if self.player_component then
        self.player_component:update(dt)
    end
    if self.controls_component then
        self.controls_component:update(dt)
    end
    if self.visualizer_component then
        self.visualizer_component:update(dt)
    end
end

function GameState:draw()

    self:_drawBackgroundGradient()

    love.graphics.setColor(self.theme.text_primary)

    self:drawMainContent()
end

function GameState:_initGalacticJourney()
    if self.galactic_journey.initialized then return end

    for i = 1, 100 do
        table.insert(self.galactic_journey.warp_stars, {
            x = math.random() * self.window_width,
            y = math.random() * self.window_height,
            z = math.random() * 1000 + 100, 
            speed = math.random() * 200 + 50,
            brightness = math.random() * 0.8 + 0.2,
            trail_length = 0
        })
    end

    local center_x = self.window_width / 2
    local center_y = self.window_height / 2

    self.galactic_journey.galaxy_spiral = {
        center_x = center_x,
        center_y = center_y,
        rotation = 0,
        arms = {},
        core_size = 80
    }

    for arm = 1, 4 do
        local arm_data = {
            angle_offset = (arm / 4) * math.pi * 2,
            points = {}
        }

        for i = 1, 50 do
            local distance = i * 8
            local angle = arm_data.angle_offset + distance * 0.02
            local x = center_x + math.cos(angle) * distance
            local y = center_y + math.sin(angle) * distance * 0.7 

            if x >= -100 and x <= self.window_width + 100 and 
               y >= -100 and y <= self.window_height + 100 then
                table.insert(arm_data.points, {
                    x = x, y = y, 
                    brightness = math.random() * 0.6 + 0.2,
                    size = math.random() * 2 + 1
                })
            end
        end

        table.insert(self.galactic_journey.galaxy_spiral.arms, arm_data)
    end

    for i = 1, 80 do
        table.insert(self.galactic_journey.quantum_particles, {
            x = math.random() * self.window_width,
            y = math.random() * self.window_height,
            vx = (math.random() - 0.5) * 30,
            vy = (math.random() - 0.5) * 30,
            size = math.random() * 3 + 1,
            energy = math.random(),
            color = {
                math.random() * 0.5 + 0.5,
                math.random() * 0.3 + 0.4,
                math.random() * 0.8 + 0.2
            },
            trail = {}
        })
    end

    self.galactic_journey.initialized = true
end

function GameState:_drawBackgroundGradient()
    self:_initGalacticJourney()

    self.galactic_journey.time = self.galactic_journey.time + love.timer.getDelta()
    local dt = love.timer.getDelta()

    local status = self.last_status
    local audio_intensity = 0
    local bass_level = 0
    local mid_level = 0
    local high_level = 0

    if status and status.vis_bands then
        for i = 1, 8 do
            bass_level = bass_level + (status.vis_bands[i] or 0)
        end
        for i = 9, 16 do
            mid_level = mid_level + (status.vis_bands[i] or 0)
        end
        for i = 17, 32 do
            high_level = high_level + (status.vis_bands[i] or 0)
        end

        bass_level = bass_level / 8
        mid_level = mid_level / 8
        high_level = high_level / 16
        audio_intensity = (bass_level + mid_level + high_level) / 3
    end

    local segments = 30
    for i = 0, segments - 1 do
        local segment_height = self.window_height / segments
        local segment_y = i * segment_height
        local blend = i / (segments - 1)

        local r = 0.005 + blend * 0.02 + math.sin(self.galactic_journey.time + blend * 3) * 0.01
        local g = 0.008 + blend * 0.03 + math.sin(self.galactic_journey.time * 1.3 + blend * 2) * 0.015
        local b = 0.04 + blend * 0.06 + math.sin(self.galactic_journey.time * 0.8 + blend * 4) * 0.02

        r = r + bass_level * 0.06 + audio_intensity * 0.04
        g = g + mid_level * 0.05 + audio_intensity * 0.03
        b = b + high_level * 0.08 + audio_intensity * 0.05

        love.graphics.setColor(r, g, b, 1.0)
        love.graphics.rectangle("fill", 0, segment_y, self.window_width, segment_height + 1)
    end

    local warp_speed = 1 + high_level * 3 + audio_intensity * 2

    for _, star in ipairs(self.galactic_journey.warp_stars) do

        star.z = star.z - star.speed * warp_speed * dt

        if star.z <= 1 then
            star.z = 1000 + math.random() * 500
            star.x = math.random() * self.window_width
            star.y = math.random() * self.window_height
        end

        local scale = 500 / star.z
        local screen_x = self.window_width/2 + (star.x - self.window_width/2) * scale
        local screen_y = self.window_height/2 + (star.y - self.window_height/2) * scale

        star.trail_length = warp_speed * 20

        if warp_speed > 1.5 then
            local trail_end_x = screen_x - (screen_x - self.window_width/2) * 0.1
            local trail_end_y = screen_y - (screen_y - self.window_height/2) * 0.1

            love.graphics.setColor(0.9, 0.9, 1.0, star.brightness * 0.6)
            love.graphics.setLineWidth(scale * 2)
            love.graphics.line(screen_x, screen_y, trail_end_x, trail_end_y)
        end

        love.graphics.setColor(1, 1, 1, star.brightness)
        love.graphics.circle("fill", screen_x, screen_y, math.max(scale * 2, 1))
    end

    for _, particle in ipairs(self.galactic_journey.quantum_particles) do

        local energy_boost = 1 + mid_level * 2
        particle.vx = particle.vx + (math.random() - 0.5) * energy_boost * dt * 10
        particle.vy = particle.vy + (math.random() - 0.5) * energy_boost * dt * 10

        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt

        if particle.x < 0 then particle.x = self.window_width end
        if particle.x > self.window_width then particle.x = 0 end
        if particle.y < 0 then particle.y = self.window_height end
        if particle.y > self.window_height then particle.y = 0 end

        table.insert(particle.trail, 1, {x = particle.x, y = particle.y})
        if #particle.trail > 8 then
            table.remove(particle.trail)
        end

        for i, trail_point in ipairs(particle.trail) do
            local trail_alpha = (1 - i / #particle.trail) * 0.5 * energy_boost
            local trail_size = particle.size * (1 - i / #particle.trail) * energy_boost

            love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], trail_alpha)
            love.graphics.circle("fill", trail_point.x, trail_point.y, trail_size)
        end

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], 0.9 * energy_boost)
        love.graphics.circle("fill", particle.x, particle.y, particle.size * energy_boost)
    end 

end

function GameState:drawMainContent()
    local center_x = self.window_width / 2
    local center_y = self.window_height / 2

    local circle_radius = 120
    local circle_y = center_y - 90  
    self:_drawCircularArea(center_x, circle_y, circle_radius)

    if self.visualizer_component then

        local is_likely_fullscreen = self.window_width > 1400 or (self.window_width / self.window_height) > 1.6

        local wave_y
        if is_likely_fullscreen then
            wave_y = center_y + 300  
        else
            wave_y = center_y + 110  
        end

        local wave_width = self.window_width  
        local wave_height = 80
        self.visualizer_component:draw(0, wave_y, wave_width, wave_height)  
    end

    if self.controls_component then
        local controls_height = 70  
        local controls_y = self.window_height - controls_height  
        local controls_width = self.window_width  
        local controls_x = 0  
        self.controls_component:draw(controls_x, controls_y, controls_width, controls_height)
    end
end

function GameState:_drawCircularArea(center_x, center_y, radius)

    if self.floating_image then
        love.graphics.push()

        local harmonic = self.floating_animation.harmonic_resonance or {}
        local resonance_offset = (harmonic.combined or 0) * 3

        love.graphics.translate(center_x, center_y + self.floating_animation.float_offset + resonance_offset)
        love.graphics.rotate(self.floating_animation.rotation)
        love.graphics.scale(self.floating_animation.scale)

        local img_width = self.floating_image:getWidth()
        local img_height = self.floating_image:getHeight()

        local desired_size = radius * 1.2
        local scale_factor = desired_size / math.max(img_width, img_height)

        local draw_x = -(img_width * scale_factor) / 2
        local draw_y = -(img_height * scale_factor) / 2

        local glow_alpha = self.floating_animation.glow_intensity or 0.5
        local audio_energy = self.floating_animation.audio_energy or 0
        local bass_energy = self.floating_animation.bass_energy or 0
        local is_playing = self.floating_animation.is_playing or false
        local beat_pulse = self.floating_animation.beat_pulse or 0
        local glow_color = self.floating_animation.glow_color_shift or {r = 0.95, g = 0.35, b = 0.65}
        local triggers = self.floating_animation.particle_triggers or {}

        if beat_pulse > 0 then
            local pulse_intensity = self.floating_animation.strong_beat and 1.5 or 1.0
            local pulse_scale = 1.0 + beat_pulse * 0.4 * pulse_intensity
            local pulse_alpha = beat_pulse * 0.5

            love.graphics.setColor(glow_color.r, 0.2, 0.2, pulse_alpha * 0.7)
            love.graphics.draw(self.floating_image, draw_x - 12, draw_y - 12, 0, scale_factor * pulse_scale * 1.05, scale_factor * pulse_scale * 1.05)

            love.graphics.setColor(0.2, glow_color.g, 0.2, pulse_alpha * 0.7)
            love.graphics.draw(self.floating_image, draw_x - 10, draw_y - 10, 0, scale_factor * pulse_scale, scale_factor * pulse_scale)

            love.graphics.setColor(0.2, 0.2, glow_color.b, pulse_alpha * 0.7)
            love.graphics.draw(self.floating_image, draw_x - 8, draw_y - 8, 0, scale_factor * pulse_scale * 0.95, scale_factor * pulse_scale * 0.95)

            love.graphics.setColor(glow_color.r, glow_color.g, glow_color.b, pulse_alpha)
            love.graphics.draw(self.floating_image, draw_x - 6, draw_y - 6, 0, scale_factor * pulse_scale, scale_factor * pulse_scale)
        end

        local bass_glow_alpha = glow_alpha * 0.4 + (harmonic.fundamental or 0) * 0.3
        if is_playing and bass_energy > 0.1 then
            love.graphics.setColor(glow_color.r * 1.2, glow_color.g * 0.6, glow_color.b * 0.8, bass_glow_alpha)
            love.graphics.draw(self.floating_image, draw_x - 5, draw_y - 5, 0, scale_factor * 1.15, scale_factor * 1.15)
        end

        local mid_glow_alpha = glow_alpha * 0.3 + (harmonic.second or 0) * 0.25
        if is_playing and audio_energy > 0.2 then
            love.graphics.setColor(glow_color.r * 0.8, glow_color.g * 1.2, glow_color.b * 1.0, mid_glow_alpha)
            love.graphics.draw(self.floating_image, draw_x - 3, draw_y - 3, 0, scale_factor * 1.08, scale_factor * 1.08)
        end

        local high_glow_alpha = glow_alpha * 0.2 + (harmonic.third or 0) * 0.2
        if is_playing and audio_energy > 0.15 then
            love.graphics.setColor(glow_color.r * 0.6, glow_color.g * 0.8, glow_color.b * 1.3, high_glow_alpha)
            love.graphics.draw(self.floating_image, draw_x - 1, draw_y - 1, 0, scale_factor * 1.03, scale_factor * 1.03)
        end

        if triggers.bass_trigger then
            self:_drawBassParticles(0, 0, radius, glow_color)
        end

        if triggers.mid_trigger then
            self:_drawMidFrequencyRings(0, 0, radius * 0.6, glow_color)
        end

        if triggers.high_trigger then
            self:_drawHighFrequencySparkles(0, 0, radius, glow_color, audio_energy)
        end

        if triggers.combined_trigger then
            self:_drawCombinedEnergyBurst(0, 0, radius, glow_color, audio_energy)
        end

        local spectral = self.floating_animation.spectral_features or {}

        if is_playing and spectral.brightness and spectral.brightness > 0.3 then
            self:_drawSpectralBrightness(0, 0, radius, spectral.brightness, glow_color)
        end

        if is_playing and spectral.warmth and spectral.warmth > 0.4 then
            self:_drawSpectralWarmth(0, 0, radius, spectral.warmth, glow_color)
        end

        if is_playing and spectral.dynamics and spectral.dynamics > 0.2 then
            self:_drawSpectralDynamics(0, 0, radius, spectral.dynamics, glow_color)
        end

        if self.floating_animation.beat_phase and is_playing then
            self:_drawTempoSyncedGeometry(0, 0, radius, self.floating_animation.beat_phase, glow_color)
        end

        local spectral = self.floating_animation.spectral_features or {}
        local morph_intensity = is_playing and audio_energy * 0.3 or 0

        if morph_intensity > 0.1 then

            local vertical_stretch = 1.0 + (spectral.centroid or 0) * morph_intensity * 0.2
            local horizontal_stretch = 1.0 + (1 - (spectral.centroid or 0)) * morph_intensity * 0.15

            love.graphics.setColor(glow_color.r * 0.8, glow_color.g * 0.8, glow_color.b * 0.8, morph_intensity * 0.3)
            love.graphics.draw(self.floating_image, draw_x, draw_y, 0, 
                scale_factor * horizontal_stretch, scale_factor * vertical_stretch)

            local flux_rotation = (spectral.flux or 0) * morph_intensity * 0.1
            if math.abs(flux_rotation) > 0.01 then
                love.graphics.setColor(glow_color.r, glow_color.g * 0.6, glow_color.b * 1.2, morph_intensity * 0.2)
                love.graphics.draw(self.floating_image, draw_x, draw_y, flux_rotation, scale_factor, scale_factor)
            end
        end

        local main_brightness = 0.95 + audio_energy * 0.05
        local color_shift_intensity = is_playing and audio_energy * 0.1 or 0

        local warmth_factor = spectral.warmth or 0
        local brightness_factor = spectral.brightness or 0

        love.graphics.setColor(
            1.0 + glow_color.r * color_shift_intensity + warmth_factor * 0.1,
            1.0 + glow_color.g * color_shift_intensity - warmth_factor * 0.05 + brightness_factor * 0.05,
            1.0 + glow_color.b * color_shift_intensity - warmth_factor * 0.1 + brightness_factor * 0.1,
            main_brightness
        )
        love.graphics.draw(self.floating_image, draw_x, draw_y, 0, scale_factor, scale_factor)

        if is_playing and audio_energy > 0.25 then

            love.graphics.setColor(1, 1, 1, audio_energy * 0.3)
            love.graphics.setLineWidth(1)
            love.graphics.draw(self.floating_image, draw_x - 0.5, draw_y - 0.5, 0, scale_factor * 1.005, scale_factor * 1.005)

            if bass_energy > 0.4 then
                love.graphics.setColor(glow_color.r, glow_color.g * 0.5, glow_color.b * 0.5, bass_energy * 0.2)
                love.graphics.setLineWidth(2)
                love.graphics.draw(self.floating_image, draw_x - 1, draw_y - 1, 0, scale_factor * 1.01, scale_factor * 1.01)
            end
        end

        love.graphics.pop()
    end
end

function GameState:_drawBassParticles(center_x, center_y, radius, glow_color)
    local particle_count = 12
    local time = self.floating_animation.time
    local bass_energy = self.floating_animation.bass_energy or 0

    for i = 1, particle_count do
        local angle = (i / particle_count) * 2 * math.pi + time * 0.8
        local distance = radius * (0.8 + bass_energy * 0.4) + math.sin(time * 3 + i) * 20
        local particle_x = center_x + math.cos(angle) * distance
        local particle_y = center_y + math.sin(angle) * distance
        local particle_size = 2 + bass_energy * 4 + math.sin(time * 5 + i) * 2

        love.graphics.setColor(glow_color.r, glow_color.g * 0.6, glow_color.b * 0.4, 0.7 + bass_energy * 0.3)
        love.graphics.circle("fill", particle_x, particle_y, particle_size)

        love.graphics.setColor(glow_color.r, glow_color.g, glow_color.b, 0.3)
        love.graphics.circle("fill", particle_x, particle_y, particle_size * 2)

        local trail_length = 6
        for j = 1, trail_length do
            local trail_angle = angle - j * 0.1
            local trail_distance = distance - j * 5
            local trail_x = center_x + math.cos(trail_angle) * trail_distance
            local trail_y = center_y + math.sin(trail_angle) * trail_distance
            local trail_alpha = (1 - j / trail_length) * bass_energy * 0.4

            love.graphics.setColor(glow_color.r * 0.8, glow_color.g * 0.4, glow_color.b * 0.6, trail_alpha)
            love.graphics.circle("fill", trail_x, trail_y, particle_size * 0.6)
        end
    end
end

function GameState:_drawMidFrequencyRings(center_x, center_y, radius, glow_color)
    local ring_count = 3
    local time = self.floating_animation.time

    for i = 1, ring_count do
        local ring_radius = radius * (0.5 + i * 0.2) + math.sin(time * 3 + i) * 8
        local ring_alpha = 0.3 / i

        love.graphics.setColor(glow_color.r * 0.8, glow_color.g, glow_color.b * 0.9, ring_alpha)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", center_x, center_y, ring_radius)
    end
end

function GameState:_drawHighFrequencySparkles(center_x, center_y, radius, glow_color, energy)
    local sparkle_count = 16
    local time = self.floating_animation.time
    local high_energy = self.floating_animation.high_energy or 0

    for i = 1, sparkle_count do
        local angle = (i / sparkle_count) * 2 * math.pi + time * 5
        local distance = radius * (0.6 + math.sin(time * 8 + i) * 0.4) * (1 + high_energy * 0.3)
        local sparkle_x = center_x + math.cos(angle) * distance
        local sparkle_y = center_y + math.sin(angle) * distance
        local sparkle_size = 1 + energy * 3 + math.sin(time * 10 + i) * 1
        local sparkle_alpha = 0.5 + energy * 0.5

        love.graphics.setColor(1, 1, 1, sparkle_alpha)
        love.graphics.circle("fill", sparkle_x, sparkle_y, sparkle_size)

        love.graphics.setColor(glow_color.r, glow_color.g, glow_color.b, sparkle_alpha * 0.7)
        love.graphics.circle("fill", sparkle_x, sparkle_y, sparkle_size * 1.8)

        love.graphics.setColor(glow_color.r * 0.8, glow_color.g * 0.9, glow_color.b, sparkle_alpha * 0.4)
        love.graphics.circle("fill", sparkle_x, sparkle_y, sparkle_size * 2.5)

        local trail_length = 12
        for j = 1, trail_length do
            local trail_alpha = sparkle_alpha * (1 - j / trail_length) * 0.6
            local trail_distance = distance - j * 4
            local trail_angle = angle - j * 0.05
            local trail_x = center_x + math.cos(trail_angle) * trail_distance
            local trail_y = center_y + math.sin(trail_angle) * trail_distance

            love.graphics.setColor(glow_color.r, glow_color.g, glow_color.b, trail_alpha)
            love.graphics.circle("fill", trail_x, trail_y, sparkle_size * 0.4)

            if j % 3 == 0 then
                love.graphics.setColor(1, 1, 1, trail_alpha * 0.8)
                love.graphics.circle("fill", trail_x + math.random(-2, 2), trail_y + math.random(-2, 2), 0.5)
            end
        end
    end
end

function GameState:_drawCombinedEnergyBurst(center_x, center_y, radius, glow_color, energy)
    local burst_intensity = energy * 2.0
    local time = self.floating_animation.time

    local core_size = 8 + burst_intensity * 6
    local core_pulse = math.sin(time * 8) * 0.3 + 1

    love.graphics.setColor(1, 1, 1, burst_intensity * 0.9)
    love.graphics.circle("fill", center_x, center_y, core_size * core_pulse)

    love.graphics.setColor(glow_color.r, glow_color.g, glow_color.b, burst_intensity * 0.7)
    love.graphics.circle("fill", center_x, center_y, core_size * core_pulse * 1.5)

    love.graphics.setColor(glow_color.r * 0.8, glow_color.g * 0.6, glow_color.b, burst_intensity * 0.4)
    love.graphics.circle("fill", center_x, center_y, core_size * core_pulse * 2.2)
end

function GameState:_drawSpectralBrightness(center_x, center_y, radius, brightness, glow_color)
    local time = self.floating_animation.time
    local brightness_alpha = brightness * 0.6

    for i = 1, 5 do
        local corona_radius = radius * (0.3 + i * 0.1) + math.sin(time * 5 + i) * brightness * 5
        local corona_alpha = brightness_alpha / (i * 1.5)

        love.graphics.setColor(1, 1, 0.8, corona_alpha)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", center_x, center_y, corona_radius)
    end

    local particle_count = math.floor(brightness * 20)
    for i = 1, particle_count do
        local angle = (i / particle_count) * 2 * math.pi + time * 8
        local distance = radius * (0.4 + math.random() * 0.6)
        local particle_x = center_x + math.cos(angle) * distance
        local particle_y = center_y + math.sin(angle) * distance

        love.graphics.setColor(1, 1, 1, brightness * 0.8)
        love.graphics.circle("fill", particle_x, particle_y, 1 + brightness * 2)
    end
end

function GameState:_drawSpectralWarmth(center_x, center_y, radius, warmth, glow_color)
    local time = self.floating_animation.time
    local warmth_alpha = warmth * 0.5

    for i = 1, 4 do
        local glow_radius = radius * (0.2 + i * 0.15) + math.sin(time * 1.5 + i) * warmth * 8
        local glow_alpha = warmth_alpha / i

        love.graphics.setColor(1, 0.6, 0.2, glow_alpha)
        love.graphics.circle("fill", center_x, center_y, glow_radius)
    end

    local wave_count = 3
    for i = 1, wave_count do
        local wave_phase = (time * 2 + i * 0.5) % 1
        local wave_radius = radius * wave_phase * warmth
        local wave_alpha = (1 - wave_phase) * warmth * 0.4

        love.graphics.setColor(1, 0.4, 0.1, wave_alpha)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", center_x, center_y, wave_radius)
    end
end

function GameState:_drawSpectralDynamics(center_x, center_y, radius, dynamics, glow_color)
    local time = self.floating_animation.time
    local dynamics_intensity = math.min(1.0, dynamics * 5)

    local bolt_count = math.floor(dynamics_intensity * 8)
    for i = 1, bolt_count do
        local start_angle = (i / bolt_count) * 2 * math.pi
        local start_distance = radius * 0.2
        local start_x = center_x + math.cos(start_angle) * start_distance
        local start_y = center_y + math.sin(start_angle) * start_distance

        local segments = 5
        local current_x, current_y = start_x, start_y

        for j = 1, segments do
            local segment_angle = start_angle + (math.random() - 0.5) * 0.5
            local segment_distance = radius * (0.1 + j * 0.1) + math.random() * 10
            local next_x = center_x + math.cos(segment_angle) * segment_distance
            local next_y = center_y + math.sin(segment_angle) * segment_distance

            love.graphics.setColor(glow_color.r, glow_color.g, glow_color.b, dynamics_intensity * 0.7)
            love.graphics.setLineWidth(2)
            love.graphics.line(current_x, current_y, next_x, next_y)

            current_x, current_y = next_x, next_y
        end
    end

    local distortion_points = {}
    local point_count = 16
    for i = 1, point_count do
        local angle = (i / point_count) * 2 * math.pi
        local base_distance = radius * 0.5
        local distortion = math.sin(time * 10 + i) * dynamics_intensity * 15
        local point_distance = base_distance + distortion

        table.insert(distortion_points, center_x + math.cos(angle) * point_distance)
        table.insert(distortion_points, center_y + math.sin(angle) * point_distance)
    end

    if #distortion_points >= 6 then
        love.graphics.setColor(glow_color.r * 0.8, glow_color.g * 0.8, glow_color.b, dynamics_intensity * 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.line(distortion_points)
    end
end

function GameState:_drawTempoSyncedGeometry(center_x, center_y, radius, beat_phase, glow_color)
    local geometry_alpha = 0.4

    local triangle_count = 3
    for i = 1, triangle_count do
        local rotation_offset = (i - 1) * (2 * math.pi / triangle_count)
        local rotation = beat_phase * 2 * math.pi + rotation_offset
        local triangle_radius = radius * (0.3 + i * 0.1)

        local vertices = {}
        for j = 1, 3 do
            local vertex_angle = rotation + (j - 1) * (2 * math.pi / 3)
            local vertex_x = center_x + math.cos(vertex_angle) * triangle_radius
            local vertex_y = center_y + math.sin(vertex_angle) * triangle_radius
            table.insert(vertices, vertex_x)
            table.insert(vertices, vertex_y)
        end

        table.insert(vertices, vertices[1])
        table.insert(vertices, vertices[2])

        love.graphics.setColor(glow_color.r, glow_color.g, glow_color.b, geometry_alpha / i)
        love.graphics.setLineWidth(2)
        love.graphics.line(vertices)
    end
end

function GameState:_drawCircularProgress(center_x, center_y, radius)
    local status = self.last_status
    local progress = status and status.progress or 0.0
    local current_time = status and status.current_time or 0
    local total_time = status and status.total_time or 0

    self.progress_ring = {
        center_x = center_x,
        center_y = center_y,
        radius = radius,
        inner_radius = radius - 20,
        outer_radius = radius + 20
    }

    love.graphics.setColor(self.theme.progress_bg[1], self.theme.progress_bg[2], self.theme.progress_bg[3], 0.3)
    love.graphics.setLineWidth(12)
    love.graphics.circle("line", center_x, center_y, radius + 2)

    love.graphics.setColor(self.theme.progress_bg)
    love.graphics.setLineWidth(6)
    love.graphics.circle("line", center_x, center_y, radius)

    if progress > 0 then
        local start_angle = -math.pi / 2  
        local end_angle = start_angle + (progress * 2 * math.pi)

        local segments = 100
        for i = 0, segments - 1 do
            local segment_progress = i / segments
            if segment_progress <= progress then
                local angle = start_angle + (segment_progress * 2 * math.pi)
                local next_angle = start_angle + ((segment_progress + 1/segments) * 2 * math.pi)

                local color_blend = segment_progress
                local r = self.theme.gradient_main[1][1] * (1 - color_blend) + self.theme.gradient_main[2][1] * color_blend
                local g = self.theme.gradient_main[1][2] * (1 - color_blend) + self.theme.gradient_main[2][2] * color_blend
                local b = self.theme.gradient_main[1][3] * (1 - color_blend) + self.theme.gradient_main[2][3] * color_blend

                love.graphics.setColor(r, g, b, 0.4)
                love.graphics.setLineWidth(12)
                love.graphics.arc("line", center_x, center_y, radius + 2, angle, math.min(next_angle, end_angle))

                love.graphics.setColor(r, g, b, 1.0)
                love.graphics.setLineWidth(6)
                love.graphics.arc("line", center_x, center_y, radius, angle, math.min(next_angle, end_angle))
            end
        end

        local handle_angle = start_angle + (progress * 2 * math.pi)
        local handle_x = center_x + math.cos(handle_angle) * radius
        local handle_y = center_y + math.sin(handle_angle) * radius

        love.graphics.setColor(self.theme.progress_fill[1], self.theme.progress_fill[2], self.theme.progress_fill[3], 0.3)
        love.graphics.circle("fill", handle_x, handle_y, 16)

        love.graphics.setColor(self.theme.progress_fill)
        love.graphics.circle("fill", handle_x, handle_y, 10)

        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", handle_x - 2, handle_y - 2, 4)

        love.graphics.setColor(self.theme.bg_primary)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", handle_x, handle_y, 10)
    end

    love.graphics.setFont(self.fonts.default)
    love.graphics.setColor(self.theme.text_secondary)

    local current_str = self:_formatTime(current_time)
    local total_str = self:_formatTime(total_time)

    love.graphics.print(current_str, center_x - radius - 40, center_y + radius + 25)

    local total_width = self.fonts.default:getWidth(total_str)
    love.graphics.print(total_str, center_x + radius + 40 - total_width, center_y + radius + 25)
end

function GameState:_formatTime(seconds)
    if not seconds or seconds < 0 then
        return "0:00"
    end

    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", minutes, secs)
end

function GameState:_drawRoundedRect(x, y, width, height, radius, mode)
    mode = mode or "fill"
    local segments = 16

    if mode == "fill" then

        love.graphics.rectangle("fill", x + radius, y, width - 2*radius, height)
        love.graphics.rectangle("fill", x, y + radius, width, height - 2*radius)

        love.graphics.arc("fill", x + radius, y + radius, radius, math.pi, 3*math.pi/2, segments)
        love.graphics.arc("fill", x + width - radius, y + radius, radius, 3*math.pi/2, 2*math.pi, segments)
        love.graphics.arc("fill", x + radius, y + height - radius, radius, math.pi/2, math.pi, segments)
        love.graphics.arc("fill", x + width - radius, y + height - radius, radius, 0, math.pi/2, segments)
    else

        love.graphics.arc("line", x + radius, y + radius, radius, math.pi, 3*math.pi/2, segments)
        love.graphics.arc("line", x + width - radius, y + radius, radius, 3*math.pi/2, 2*math.pi, segments)
        love.graphics.arc("line", x + radius, y + height - radius, radius, math.pi/2, math.pi, segments)
        love.graphics.arc("line", x + width - radius, y + height - radius, radius, 0, math.pi/2, segments)
        love.graphics.line(x + radius, y, x + width - radius, y)
        love.graphics.line(x + radius, y + height, x + width - radius, y + height)
        love.graphics.line(x, y + radius, x, y + height - radius)
        love.graphics.line(x + width, y + radius, x + width, y + height - radius)
    end
end

function GameState:keypressed(key, scancode, isrepeat)

    if self.controls_component and self.controls_component:keypressed(key, scancode, isrepeat) then
        return 
    end

end

function GameState:mousepressed(x, y, button, istouch, presses)

    if button == 1 and self.progress_ring and self:_isPointInProgressRing(x, y) then
        self:_handleProgressRingClick(x, y)
        return
    end

    if self.player_component and self.player_component:mousepressed(x, y, button) then
        return 
    end

    if self.controls_component and self.controls_component:mousepressed(x, y, button) then
        return 
    end
end

function GameState:_isPointInProgressRing(x, y)
    if not self.progress_ring then return false end

    local dx = x - self.progress_ring.center_x
    local dy = y - self.progress_ring.center_y
    local distance = math.sqrt(dx * dx + dy * dy)

    return distance >= self.progress_ring.inner_radius and distance <= self.progress_ring.outer_radius
end

function GameState:_handleProgressRingClick(x, y)
    if not self.engine or not self.engine:is_valid() then
        return
    end

    local status = self.engine:get_status()
    if not status or not status.current_file or status.total_time <= 0 then
        return
    end

    local dx = x - self.progress_ring.center_x
    local dy = y - self.progress_ring.center_y
    local angle = math.atan2(dy, dx)

    local progress = (angle + math.pi/2) / (2 * math.pi)
    if progress < 0 then progress = progress + 1 end

    progress = math.max(0.0, math.min(1.0, progress))

    if status.total_time > 0 then
        local max_seek_position = math.max(0.0, (status.total_time - 2.0) / status.total_time)
        if progress > max_seek_position then
            progress = max_seek_position
        end
    end

    local ok, err = self.engine:seek(progress)
    if not ok then
        print("Failed to seek:", err)
    else
        print(string.format("Seeking to %.1f%%", progress * 100))
    end
end

function GameState:mousereleased(x, y, button, istouch, presses)

    if self.player_component then
        self.player_component:mousereleased(x, y, button)
    end

    if self.controls_component then
        self.controls_component:mousereleased(x, y, button)
    end
end

function GameState:mousemoved(x, y, dx, dy, istouch)

    if self.player_component then
        self.player_component:mousemoved(x, y, dx, dy)
    end

    if self.controls_component then
        self.controls_component:mousemoved(x, y, dx, dy)
    end
end

function GameState:resize(w, h)
    self.window_width = w
    self.window_height = h
    print(string.format("Window resized to %dx%d", w, h))
end

function GameState:handleDroppedFile(file)
    local filename = file:getFilename()
    print("Processing dropped file:", filename)

    local is_audio = filename:match("%.mp3$") or filename:match("%.wav$") or 
                    filename:match("%.ogg$") or filename:match("%.flac$") or
                    filename:match("%.m4a$") or filename:match("%.aac$")

    if is_audio then

        local file_path = filename

        if self.engine and self.engine:is_valid() then
            local ok, err = self.engine:load_file(file_path)
            if ok then
                print("Successfully loaded dropped file:", file_path)

                self.engine:play()
            else
                print("Failed to load dropped file:", err)

                self:_copyToMusicFolder(file, filename)
            end
        end
    else
        print("Dropped file is not a supported audio format")
    end
end

function GameState:handleDroppedDirectory(path)
    print("Processing dropped directory:", path)

    if self.engine and self.engine:is_valid() then
        local ok, err = self.engine:load_directory(path)
        if ok then
            print("Successfully loaded dropped directory:", path)

            self:_resetShuffle()
        else
            print("Failed to load dropped directory:", err)
        end
    end
end

function GameState:toggleShuffle()
    self.app_state.shuffle_enabled = not self.app_state.shuffle_enabled
    print("Shuffle " .. (self.app_state.shuffle_enabled and "enabled" or "disabled"))

    if self.app_state.shuffle_enabled then
        self:_enableShuffle()
    else
        self:_disableShuffle()
    end
end

function GameState:toggleRepeat()
    if self.app_state.repeat_mode == "off" then
        self.app_state.repeat_mode = "all"
        print("Repeat all enabled")
    elseif self.app_state.repeat_mode == "all" then
        self.app_state.repeat_mode = "one"
        print("Repeat one enabled")
    else
        self.app_state.repeat_mode = "off"
        print("Repeat disabled")
    end
end

function GameState:_enableShuffle()
    local status = self.last_status
    if not status or status.total_tracks <= 1 then
        return
    end

    self.app_state.original_track_order = {}
    for i = 1, status.total_tracks do
        self.app_state.original_track_order[i] = i
    end

    self.app_state.shuffled_track_order = {}
    for i = 1, status.total_tracks do
        self.app_state.shuffled_track_order[i] = i
    end

    for i = status.total_tracks, 2, -1 do
        local j = math.random(i)
        self.app_state.shuffled_track_order[i], self.app_state.shuffled_track_order[j] = 
            self.app_state.shuffled_track_order[j], self.app_state.shuffled_track_order[i]
    end

    print("Shuffle order created:", table.concat(self.app_state.shuffled_track_order, ", "))

    if status.state ~= "playing" then
        local first_shuffled_track = self.app_state.shuffled_track_order[1]
        if first_shuffled_track and self.engine and first_shuffled_track ~= status.current_track then
            local ok, err = self:_navigateToTrack(first_shuffled_track)
            if ok then
                print("Set current track to first in shuffle order:", first_shuffled_track)
            else
                print("Failed to navigate to first shuffled track:", err)
            end
        end
    end
end

function GameState:_disableShuffle()
    self.app_state.original_track_order = {}
    self.app_state.shuffled_track_order = {}
end

function GameState:_resetShuffle()
    if self.app_state.shuffle_enabled then
        self:_enableShuffle()
    end
end

function GameState:getNextTrack()
    local status = self.last_status
    if not status then
        return nil
    end

    if self.app_state.repeat_mode == "one" then
        return status.current_track
    end

    local next_track

    if self.app_state.shuffle_enabled and #self.app_state.shuffled_track_order > 0 then

        local current_pos = 1
        for i, track in ipairs(self.app_state.shuffled_track_order) do
            if track == status.current_track then
                current_pos = i
                break
            end
        end

        if current_pos < #self.app_state.shuffled_track_order then
            next_track = self.app_state.shuffled_track_order[current_pos + 1]
        else

            if self.app_state.repeat_mode == "all" then
                next_track = self.app_state.shuffled_track_order[1]  
            else
                next_track = nil  
            end
        end
    else

        if status.current_track < status.total_tracks then
            next_track = status.current_track + 1
        else

            if self.app_state.repeat_mode == "all" then
                next_track = 1  
            else
                next_track = nil  
            end
        end
    end

    return next_track
end

function GameState:getPreviousTrack()
    local status = self.last_status
    if not status then
        return nil
    end

    if self.app_state.repeat_mode == "one" then
        return status.current_track
    end

    local prev_track

    if self.app_state.shuffle_enabled and #self.app_state.shuffled_track_order > 0 then

        local current_pos = 1
        for i, track in ipairs(self.app_state.shuffled_track_order) do
            if track == status.current_track then
                current_pos = i
                break
            end
        end

        if current_pos > 1 then
            prev_track = self.app_state.shuffled_track_order[current_pos - 1]
        else

            if self.app_state.repeat_mode == "all" then
                prev_track = self.app_state.shuffled_track_order[#self.app_state.shuffled_track_order]  
            else
                prev_track = nil  
            end
        end
    else

        if status.current_track > 1 then
            prev_track = status.current_track - 1
        else

            if self.app_state.repeat_mode == "all" then
                prev_track = status.total_tracks  
            else
                prev_track = nil  
            end
        end
    end

    return prev_track
end

function GameState:_navigateToTrack(target_track)
    local status = self.last_status
    if not status or not self.engine or not self.engine:is_valid() then
        return false, "Engine not available"
    end

    local current_track = status.current_track

    if target_track == current_track then
        return true  
    end

    while current_track ~= target_track do
        local ok, err

        if target_track > current_track then

            ok, err = self.engine:next_track()
        else

            ok, err = self.engine:previous_track()
        end

        if not ok then
            return false, err
        end

        love.timer.sleep(0.05)
        self.engine:update()
        local new_status = self.engine:get_status()
        if new_status then
            current_track = new_status.current_track
        else
            return false, "Failed to get status"
        end

        if math.abs(target_track - current_track) > status.total_tracks then
            return false, "Navigation loop detected"
        end
    end

    return true
end

function GameState:_copyToMusicFolder(file, filename)
    print("Attempting to copy file to mp3-files folder...")

    local success = love.filesystem.createDirectory("mp3-files")
    if success then

        local data = file:read()
        if data then

            local basename = filename:match("([^/\\]+)$") or filename
            local target_path = "mp3-files/" .. basename

            local write_success = love.filesystem.write(target_path, data)
            if write_success then
                print("Successfully copied file to:", target_path)

                if self.engine and self.engine:is_valid() then
                    self.engine:load_directory("mp3-files/")
                end
            else
                print("Failed to copy file to mp3-files folder")
            end
        end
    else
        print("Failed to create mp3-files directory")
    end
end

function GameState:cleanup()

    if self.engine and self.engine:is_valid() then
        self.engine:destroy()
        print("Engine bridge cleaned up")
    end
    print("GameState cleanup")
end

return GameState