local Visualizer = {}
Visualizer.__index = Visualizer

function Visualizer:new(game_state)
    local visualizer = {
        game_state = game_state,
        layout = {
            padding = 10,
            margin = 5,
            bar_spacing = 2,
            min_bar_height = 2,
            max_bar_height = 100,
            bar_width = 0, 
            num_bands = 32 
        },
        colors = {},
        animation = {

            current_bands = {},

            target_bands = {},

            smoothing_factor = 0.18, 
            decay_factor = 0.97, 
            peak_hold_time = 0.5, 
            peak_decay_rate = 0.8, 

            peak_values = {},
            peak_hold_timers = {},

            beat_energy_history = {},
            beat_threshold = 1.5,
            last_beat_time = 0,
            beat_intensity = 0,
            beat_decay = 0.95
        },
        rainbow_colors = {},
        last_update_time = 0,
        target_fps = 60, 
        frame_time_threshold = 1.0 / 60.0 
    }

    setmetatable(visualizer, self)
    visualizer:_initializeColors()
    visualizer:_initializeAnimation()
    visualizer:_generateRainbowColors()

    return visualizer
end

function Visualizer:_initializeColors()
    local theme = self.game_state.theme
    self.colors = {
        background = theme.glass,
        surface = theme.surface_elevated,
        bar_outline = theme.glass_border,
        peak_indicator = theme.accent,
        text = theme.text,
        text_secondary = theme.text_secondary,
        grid_lines = theme.bg3,
        glow = theme.primary,
        shadow = {0.0, 0.0, 0.0, 0.4}
    }
end

function Visualizer:_initializeAnimation()
    for i = 1, self.layout.num_bands do
        self.animation.current_bands[i] = 0.0
        self.animation.target_bands[i] = 0.0
        self.animation.peak_values[i] = 0.0
        self.animation.peak_hold_timers[i] = 0.0
    end
end

function Visualizer:_generateRainbowColors()
    self.rainbow_colors = {}
    local theme = self.game_state.theme

    local key_colors = theme.gradient_wave

    for i = 1, self.layout.num_bands do

        local position = (i - 1) / (self.layout.num_bands - 1) 
        local scaled_pos = position * (#key_colors - 1) + 1
        local color_index = math.floor(scaled_pos)
        local blend_factor = scaled_pos - color_index

        local color1 = key_colors[math.max(1, math.min(#key_colors, color_index))]
        local color2 = key_colors[math.max(1, math.min(#key_colors, color_index + 1))]

        local r = color1[1] * (1 - blend_factor) + color2[1] * blend_factor
        local g = color1[2] * (1 - blend_factor) + color2[2] * blend_factor
        local b = color1[3] * (1 - blend_factor) + color2[3] * blend_factor

        self.rainbow_colors[i] = {
            base = {r * 0.7, g * 0.7, b * 0.7, 0.85},
            bright = {r, g, b, 0.95},
            peak = {math.min(1.0, r * 1.2), math.min(1.0, g * 1.2), math.min(1.0, b * 1.2), 1.0},
            glow = {r, g, b, 0.3}, 
            shadow = {r * 0.3, g * 0.3, b * 0.3, 0.6} 
        }
    end
end

function Visualizer:draw(x, y, width, height)

    local prev_color = {love.graphics.getColor()}
    local prev_line_width = love.graphics.getLineWidth()

    self:_drawFlowingWaves(x, y, width, height)

    love.graphics.setColor(prev_color)
    love.graphics.setLineWidth(prev_line_width)
end

function Visualizer:_drawFlowingWaves(x, y, width, height)
    local center_y = y + height / 2
    local time = love.timer.getTime()

    local status = self.game_state.last_status
    local is_playing = status and status.state == "playing"

    local total_energy = 0
    local max_amplitude = 0
    for i = 1, self.layout.num_bands do
        local amplitude = self.animation.current_bands[i] or 0
        total_energy = total_energy + amplitude
        max_amplitude = math.max(max_amplitude, amplitude)
    end

    local energy_factor = math.min(1.0, total_energy / 8.0)
    local peak_factor = math.min(1.0, max_amplitude * 2.0)

    if not is_playing then

        local wave_layers = {
            {
                frequency_bands = {1, 8},
                amplitude_base = 5,  
                speed = 0.2,         
                color = {0.6, 0.3, 0.8, 1.0}, 
                thickness = 2
            }
        }

        for _, wave in ipairs(wave_layers) do
            self:_drawMinimalWaveLayer(x, center_y, width, wave, time)
        end
        return
    end

    if total_energy < 0.01 then

        love.graphics.setColor(0.6, 0.3, 0.8, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.line(x, center_y, x + width, center_y)
        return
    end

    local wave_layers = {
        {
            frequency_bands = {1, 4},     
            amplitude_base = 28,
            speed = 0.8,
            color = {0.8, 0.2, 0.9, 1.0}, 
            thickness = 5,
            phase_offset = 0,
            harmonics = 2 
        },
        {
            frequency_bands = {5, 12},    
            amplitude_base = 32,
            speed = 1.0,
            color = {0.2, 0.7, 1.0, 1.0}, 
            thickness = 6,
            phase_offset = math.pi / 3,
            harmonics = 3
        },
        {
            frequency_bands = {13, 20},   
            amplitude_base = 24,
            speed = 1.2,
            color = {0.9, 0.3, 0.8, 1.0}, 
            thickness = 4,
            phase_offset = math.pi / 2,
            harmonics = 2
        },
        {
            frequency_bands = {21, 28},   
            amplitude_base = 20,
            speed = 1.5,
            color = {0.1, 0.9, 0.9, 1.0}, 
            thickness = 3,
            phase_offset = math.pi,
            harmonics = 4
        },
        {
            frequency_bands = {29, 32},   
            amplitude_base = 16,
            speed = 1.8,
            color = {0.7, 1.0, 0.3, 1.0}, 
            thickness = 2,
            phase_offset = math.pi * 1.5,
            harmonics = 3
        }
    }

    for _, wave in ipairs(wave_layers) do
        self:_drawAudioReactiveWaveLayer(x, center_y, width, wave, time, energy_factor)
    end

    if energy_factor > 0.5 then
        self:_drawEnergyParticles(x, y, width, height, energy_factor, time)
    end
end

function Visualizer:_drawAudioReactiveWaveLayer(x, center_y, width, wave_config, time, energy_factor)
    local points = {}
    local segments = 150 

    local wave_amplitude = 0
    local band_count = 0
    local max_local_amplitude = 0
    for i = wave_config.frequency_bands[1], wave_config.frequency_bands[2] do
        if i <= self.layout.num_bands then
            local amp = self.animation.current_bands[i] or 0
            wave_amplitude = wave_amplitude + amp
            max_local_amplitude = math.max(max_local_amplitude, amp)
            band_count = band_count + 1
        end
    end
    wave_amplitude = band_count > 0 and (wave_amplitude / band_count) or 0

    wave_amplitude = wave_amplitude * 1.6
    local intensity_boost = 1.0 + max_local_amplitude * 1.0

    for i = 0, segments do
        local wave_x = x + (i / segments) * width
        local progress = i / segments

        local band_index = math.floor(progress * (wave_config.frequency_bands[2] - wave_config.frequency_bands[1])) + wave_config.frequency_bands[1]
        band_index = math.min(band_index, self.layout.num_bands)
        local local_amplitude = self.animation.current_bands[band_index] or 0

        local phase = (progress * 2.5 + time * wave_config.speed + wave_config.phase_offset) * math.pi
        local base_wave = math.sin(phase) * wave_config.amplitude_base * energy_factor

        local harmonic_wave = 0
        for h = 1, wave_config.harmonics do
            local harmonic_freq = h * 2
            local harmonic_amp = local_amplitude * (0.5 / h) 
            harmonic_wave = harmonic_wave + math.sin(phase * harmonic_freq) * harmonic_amp * 8
        end

        local audio_modulation = math.sin((progress * 5 + time * wave_config.speed * 1.3) * math.pi) * local_amplitude * 18 * intensity_boost

        local detail_freq = 8 + wave_config.frequency_bands[1] * 0.3 
        local fine_detail = math.sin((progress * detail_freq + time * wave_config.speed * 0.7) * math.pi) * wave_amplitude * 4

        local total_wave = (base_wave + harmonic_wave + audio_modulation + fine_detail) * (0.5 + energy_factor * 0.6)
        local wave_y = center_y + total_wave

        table.insert(points, wave_x)
        table.insert(points, wave_y)
    end

    if #points >= 4 then

        local cosmic_r = wave_config.color[1]
        local cosmic_g = wave_config.color[2] 
        local cosmic_b = wave_config.color[3]

        local alpha_base = 0.4 + energy_factor * 0.5
        local alpha_glow = 0.2 + energy_factor * 0.4

        love.graphics.setColor(cosmic_r, cosmic_g, cosmic_b, alpha_glow * 0.2)
        love.graphics.setLineWidth(wave_config.thickness + 12)
        love.graphics.line(points)

        love.graphics.setColor(cosmic_r, cosmic_g, cosmic_b, alpha_glow * 0.4)
        love.graphics.setLineWidth(wave_config.thickness + 8)
        love.graphics.line(points)

        love.graphics.setColor(cosmic_r, cosmic_g, cosmic_b, alpha_glow * 0.7)
        love.graphics.setLineWidth(wave_config.thickness + 4)
        love.graphics.line(points)

        love.graphics.setColor(cosmic_r, cosmic_g, cosmic_b, alpha_base)
        love.graphics.setLineWidth(wave_config.thickness)
        love.graphics.line(points)

        love.graphics.setColor(1, 1, 1, 0.15 + energy_factor * 0.25)
        love.graphics.setLineWidth(math.max(1, wave_config.thickness - 1))
        love.graphics.line(points)

        if energy_factor > 0.7 then
            love.graphics.setColor(1, 1, 1, (energy_factor - 0.7) * 0.8)
            love.graphics.setLineWidth(1)
            love.graphics.line(points)
        end
    end
end

function Visualizer:_drawEnergyParticles(x, y, width, height, energy_factor, time)
    local num_particles = math.floor(energy_factor * 20) 
    local center_y = y + height / 2

    for i = 1, num_particles do

        local seed = i * 123.456 + time * 0.5
        local particle_x = x + (math.sin(seed) * 0.5 + 0.5) * width
        local particle_y = center_y + math.cos(seed * 1.3) * height * 0.3 * energy_factor

        local movement_x = math.sin(time * 2 + i * 0.5) * energy_factor * 30
        local movement_y = math.cos(time * 1.5 + i * 0.7) * energy_factor * 20

        particle_x = particle_x + movement_x
        particle_y = particle_y + movement_y

        if particle_x >= x and particle_x <= x + width and particle_y >= y and particle_y <= y + height then

            local band_index = math.floor((particle_x - x) / width * self.layout.num_bands) + 1
            band_index = math.min(band_index, self.layout.num_bands)
            local color = self.rainbow_colors[band_index] or {1, 1, 1, 1}

            local distance_from_center = math.abs(particle_y - center_y) / (height * 0.5)
            local size = (1 - distance_from_center) * energy_factor * 4 + 1

            love.graphics.setColor(color.bright[1], color.bright[2], color.bright[3], energy_factor * 0.8)
            love.graphics.circle("fill", particle_x, particle_y, size)

            love.graphics.setColor(color.glow[1], color.glow[2], color.glow[3], energy_factor * 0.3)
            love.graphics.circle("fill", particle_x, particle_y, size * 2)
        end
    end
end

function Visualizer:_drawMinimalWaveLayer(x, center_y, width, wave_config, time)
    local points = {}
    local segments = 80

    for i = 0, segments do
        local wave_x = x + (i / segments) * width
        local progress = i / segments

        local wave_y = center_y + math.sin((progress * 2 + time * wave_config.speed) * math.pi) * wave_config.amplitude_base

        table.insert(points, wave_x)
        table.insert(points, wave_y)
    end

    if #points >= 4 then
        love.graphics.setColor(wave_config.color[1], wave_config.color[2], wave_config.color[3], 0.4)
        love.graphics.setLineWidth(wave_config.thickness)
        love.graphics.line(points)
    end
end

function Visualizer:_drawRoundedRect(x, y, width, height, radius, mode)
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

function Visualizer:_drawModernBar(x, y, width, height, color, radius)

    love.graphics.setColor(color.shadow)
    self:_drawRoundedRect(x + 1, y + 1, width, height, radius)

    self:_drawVerticalGradientBar(x, y, width, height, color.base, color.bright, radius)

    love.graphics.setColor(color.bright[1], color.bright[2], color.bright[3], 0.4)
    love.graphics.setLineWidth(1)
    self:_drawRoundedRect(x, y, width, height, radius, "line")
end

function Visualizer:_drawVerticalGradientBar(x, y, width, height, bottom_color, top_color, radius)
    local segments = math.max(8, math.min(32, height / 2))

    for i = 0, segments - 1 do
        local segment_height = height / segments
        local segment_y = y + i * segment_height
        local blend = i / (segments - 1)

        local r = bottom_color[1] * (1 - blend) + top_color[1] * blend
        local g = bottom_color[2] * (1 - blend) + top_color[2] * blend
        local b = bottom_color[3] * (1 - blend) + top_color[3] * blend
        local a = bottom_color[4] * (1 - blend) + top_color[4] * blend

        love.graphics.setColor(r, g, b, a)

        if i == 0 then

            self:_drawRoundedRect(x, segment_y, width, segment_height + 2, radius, "fill")
        elseif i == segments - 1 then

            love.graphics.rectangle("fill", x, segment_y - 1, width, segment_height + 1)
            self:_drawRoundedRect(x, segment_y - 1, width, segment_height + 1, radius, "fill")
        else

            love.graphics.rectangle("fill", x, segment_y, width, segment_height + 1)
        end
    end
end

function Visualizer:_drawBarReflection(x, y, width, height, radius)
    local reflection_height = math.min(height * 0.3, 20)

    local segments = 8
    for i = 0, segments - 1 do
        local segment_height = reflection_height / segments
        local segment_y = y + i * segment_height
        local alpha = (1 - i / segments) * 0.2

        love.graphics.setColor(1, 1, 1, alpha)
        if i == 0 then
            self:_drawRoundedRect(x + 1, segment_y + 1, width - 2, segment_height, radius/2)
        else
            love.graphics.rectangle("fill", x + 1, segment_y, width - 2, segment_height)
        end
    end
end

function Visualizer:_drawModernPeak(x, y, width, color, intensity)
    local peak_height = 3
    local glow_intensity = intensity * 0.8

    if glow_intensity > 0.1 then
        love.graphics.setColor(color.peak[1], color.peak[2], color.peak[3], glow_intensity * 0.3)
        love.graphics.rectangle("fill", x - 2, y - 2, width + 4, peak_height + 4)
    end

    love.graphics.setColor(color.peak)
    self:_drawRoundedRect(x, y, width, peak_height, 1.5)

    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.rectangle("fill", x + 1, y, width - 2, 1)
end

function Visualizer:_calculateModernBarHeight(amplitude, max_height)
    if amplitude <= 0 then
        return 0
    end

    local log_amplitude = math.log(1 + amplitude * 19) / math.log(20)

    local eased_amplitude = log_amplitude * log_amplitude * (3 - 2 * log_amplitude) 

    local height = eased_amplitude * (max_height - 10) + (amplitude > 0.01 and 2 or 0)

    return math.min(max_height, math.max(0, height))
end

function Visualizer:_calculateBarHeight(amplitude, max_height)
    if amplitude <= 0 then
        return 0
    end

    local log_amplitude = math.log(1 + amplitude * 9) / math.log(10) 

    local height = log_amplitude * max_height

    return math.min(max_height, math.max(0, height))
end

function Visualizer:_drawModernFrequencyLabels(x, y, width)
    local font = love.graphics.newFont(11)
    love.graphics.setFont(font)

    local labels = {
        {text = "BASS", pos = 0.08, color = self.game_state.theme.red_bright},
        {text = "LOW MID", pos = 0.25, color = self.game_state.theme.orange_bright},
        {text = "MID", pos = 0.5, color = self.game_state.theme.yellow_bright},
        {text = "HIGH MID", pos = 0.75, color = self.game_state.theme.aqua_bright},
        {text = "TREBLE", pos = 0.92, color = self.game_state.theme.purple_bright}
    }

    for _, label in ipairs(labels) do
        local label_x = x + (width * label.pos)
        local text_width = font:getWidth(label.text)

        love.graphics.setColor(self.colors.surface[1], self.colors.surface[2], self.colors.surface[3], 0.6)
        self:_drawRoundedRect(label_x - text_width/2 - 4, y - 2, text_width + 8, font:getHeight() + 4, 3)

        love.graphics.setColor(label.color[1], label.color[2], label.color[3], 0.8)
        love.graphics.print(label.text, label_x - text_width/2, y)
    end
end

function Visualizer:update(dt)
    local current_time = love.timer.getTime()

    if current_time - self.last_update_time < self.frame_time_threshold then
        return
    end

    self.last_update_time = current_time

    local status = self.game_state.last_status
    local is_playing = status and status.state == "playing"

    if is_playing and status and status.vis_bands then

        for i = 1, self.layout.num_bands do
            local engine_value = status.vis_bands[i] or 0.0

            self.animation.target_bands[i] = math.max(0.0, math.min(1.0, engine_value))
        end
    else

        for i = 1, self.layout.num_bands do
            if not is_playing then

                self.animation.target_bands[i] = 0.05 + (i % 3) * 0.02 
            else

                self.animation.target_bands[i] = 0.0
            end
        end
    end

    for i = 1, self.layout.num_bands do
        local current = self.animation.current_bands[i]
        local target = self.animation.target_bands[i]

        if target > current then

            self.animation.current_bands[i] = current + (target - current) * self.animation.smoothing_factor
        else

            self.animation.current_bands[i] = current * self.animation.decay_factor
        end

        local current_value = self.animation.current_bands[i]
        local current_peak = self.animation.peak_values[i]

        if current_value > current_peak then

            self.animation.peak_values[i] = current_value
            self.animation.peak_hold_timers[i] = self.animation.peak_hold_time
        else

            self.animation.peak_hold_timers[i] = self.animation.peak_hold_timers[i] - dt

            if self.animation.peak_hold_timers[i] <= 0 then

                self.animation.peak_values[i] = self.animation.peak_values[i] * self.animation.peak_decay_rate

                if self.animation.peak_values[i] < current_value then
                    self.animation.peak_values[i] = current_value
                end
            end
        end

        self.animation.current_bands[i] = math.max(0.0, math.min(1.0, self.animation.current_bands[i]))
        self.animation.peak_values[i] = math.max(0.0, math.min(1.0, self.animation.peak_values[i]))
    end
end

function Visualizer:getPreferredHeight()
    return self.layout.max_bar_height + (self.layout.padding * 2) + 20 
end

function Visualizer:setSmoothingFactor(factor)
    self.animation.smoothing_factor = math.max(0.01, math.min(1.0, factor))
end

function Visualizer:setDecayFactor(factor)
    self.animation.decay_factor = math.max(0.1, math.min(0.99, factor))
end

function Visualizer:setPeakHoldTime(time)
    self.animation.peak_hold_time = math.max(0.1, math.min(2.0, time))
end

function Visualizer:getDebugInfo()
    local max_current = 0
    local max_target = 0
    local active_bands = 0

    for i = 1, self.layout.num_bands do
        max_current = math.max(max_current, self.animation.current_bands[i])
        max_target = math.max(max_target, self.animation.target_bands[i])
        if self.animation.current_bands[i] > 0.01 then
            active_bands = active_bands + 1
        end
    end

    return {
        max_current = max_current,
        max_target = max_target,
        active_bands = active_bands,
        fps = 1.0 / self.frame_time_threshold
    }
end

function Visualizer:_drawBeatPulse(x, y, width, height, intensity)
    local time = love.timer.getTime()
    local pulse_alpha = intensity * 0.1

    local pulse_size = math.sin(time * 8) * 0.2 + 1
    love.graphics.setColor(0.3, 0.2, 0.5, pulse_alpha)
    love.graphics.rectangle("fill", x, y, width * pulse_size, height)
end

return Visualizer