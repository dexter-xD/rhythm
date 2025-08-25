local Controls = {}
Controls.__index = Controls

function Controls:new(game_state)
    local controls = {
        game_state = game_state,
        layout = {
            padding = 15,
            margin = 10,
            button_width = 70,
            button_height = 35,
            button_spacing = 12,
            volume_slider_width = 120,
            volume_slider_height = 20,
            volume_handle_size = 16,
            font_size = 12
        },
        fonts = {},
        colors = {},
        buttons = {},
        icons = {},
        volume_slider = {
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            is_dragging = false,
            handle_x = 0
        },

        button_states = {
            play_pause = { pressed = false, hover = false },
            stop = { pressed = false, hover = false },
            previous = { pressed = false, hover = false },
            next = { pressed = false, hover = false },
            shuffle = { pressed = false, hover = false },
            repeat_btn = { pressed = false, hover = false }
        },

        shuffle_enabled = false,
        repeat_mode = "off"  
    }

    setmetatable(controls, self)
    controls:_loadIcons()
    controls:_initializeFonts()
    controls:_initializeColors()
    controls:_setupButtons()

    return controls
end

function Controls:_loadIcons()
    self.icons = {
        play = love.graphics.newImage("assets/png/play.png"),
        pause = love.graphics.newImage("assets/png/pause.png"),
        stop = love.graphics.newImage("assets/png/stop-button.png"),
        next = love.graphics.newImage("assets/png/next-button.png"),
        previous = nil, 
        sound = love.graphics.newImage("assets/png/sound.png"),
        shuffle = love.graphics.newImage("assets/png/shuffle.png"),
        replay = love.graphics.newImage("assets/png/replay.png")
    }

    local next_img = self.icons.next
    local canvas = love.graphics.newCanvas(next_img:getWidth(), next_img:getHeight())
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.push()
    love.graphics.scale(-1, 1) 
    love.graphics.translate(-next_img:getWidth(), 0)
    love.graphics.draw(next_img, 0, 0)
    love.graphics.pop()
    love.graphics.setCanvas()

    self.icons.previous = love.graphics.newImage(canvas:newImageData())
end

function Controls:_initializeFonts()
    self.fonts = {
        button = love.graphics.newFont(self.layout.font_size),
        volume = love.graphics.newFont(self.layout.font_size - 2),
        default = love.graphics.getFont()
    }
end

function Controls:_initializeColors()
    local theme = self.game_state.theme
    self.colors = {
        background = theme.glass,
        surface = theme.bg_elevated,
        button_normal = theme.button_normal,
        button_hover = theme.button_hover,
        button_pressed = theme.button_active,
        button_primary = theme.button_primary,
        text = theme.text_primary,
        text_disabled = theme.text_disabled,
        border = theme.glass_border,
        shadow = theme.shadow
    }
end

function Controls:_setupButtons()
    self.buttons = {
        {
            id = "shuffle",
            text = "⤮",
            tooltip = "Shuffle",
            action = function() print("Shuffle toggled") end
        },
        {
            id = "repeat",
            text = "↻",
            tooltip = "Repeat",
            action = function() print("Repeat toggled") end
        },
        {
            id = "previous",
            text = "◀",
            tooltip = "Previous Track (Left Arrow)",
            action = function() self:_previousTrack() end
        },
        {
            id = "play_pause",
            text = "▶",
            tooltip = "Play/Pause (Space)",
            action = function() self:_togglePlayback() end
        },
        {
            id = "next",
            text = "▶",
            tooltip = "Next Track (Right Arrow)",
            action = function() self:_nextTrack() end
        },
        {
            id = "random",
            text = "⚡",
            tooltip = "Random",
            action = function() print("Random toggled") end
        },
        {
            id = "equalizer",
            text = "⫸",
            tooltip = "Equalizer",
            action = function() print("Equalizer opened") end
        }
    }
end

function Controls:draw(x, y, width, height)

    self.last_draw_params = {x = x, y = y, width = width, height = height}

    local prev_font = love.graphics.getFont()
    local prev_color = {love.graphics.getColor()}

    self:_drawModernBottomControlBar(x, y, width, height)

    love.graphics.setFont(prev_font)
    love.graphics.setColor(prev_color)
end

function Controls:_getLastDrawParams()
    if self.last_draw_params then
        return self.last_draw_params.x, self.last_draw_params.y, self.last_draw_params.width, self.last_draw_params.height
    end
    return nil
end

function Controls:_drawModernBottomControlBar(x, y, width, height)
    local status = self.game_state.last_status
    local progress = status and status.progress or 0.0
    local current_time = status and status.current_time or 0
    local total_time = status and status.total_time or 0

    love.graphics.setColor(self.game_state.theme.bg_elevated[1], self.game_state.theme.bg_elevated[2], self.game_state.theme.bg_elevated[3], 0.8)
    love.graphics.rectangle("fill", x, y, width, height)

    local song_title = "No song loaded"
    if status and status.current_file then

        song_title = status.current_file:match("([^/\\]+)$") or status.current_file
        song_title = song_title:match("(.+)%..+$") or song_title
    end

    local title_font = love.graphics.newFont(16)
    love.graphics.setFont(title_font)
    love.graphics.setColor(self.game_state.theme.text_primary)
    local title_width = title_font:getWidth(song_title)
    local title_x = x + width / 2 - title_width / 2
    local title_y = y + 8  
    love.graphics.print(song_title, title_x, title_y)

    local button_size = 40
    local button_spacing = 15
    local progress_height = 8  

    local button_offset = 52  
    local progress_offset = 52  
    local control_y = y + button_offset - button_size / 2  
    local progress_y = y + progress_offset - progress_height / 2  

    local controls_start_x = x + 12
    local prev_x = controls_start_x
    local play_x = prev_x + button_size + button_spacing
    local next_x = play_x + button_size + button_spacing

    local time_font = love.graphics.newFont(11)
    local time_width = math.max(time_font:getWidth("00:00"), time_font:getWidth("99:99")) + 10

    local progress_start_x = next_x + button_size + button_spacing + time_width

    local repeat_button_x = x + width - button_size - 20  
    local shuffle_button_x = repeat_button_x - button_size - button_spacing  
    local volume_button_x = shuffle_button_x - button_size - button_spacing  

    local progress_width = volume_button_x - progress_start_x - button_spacing - time_width

    self:_drawModernProgressBar(progress_start_x, progress_y, progress_width, progress_height, progress, current_time, total_time)

    self:_drawModernControlButton(prev_x, control_y, button_size, "previous", "previous")
    self:_drawModernControlButton(play_x, control_y, button_size, "play_pause", self:_getPlayPauseIcon())
    self:_drawModernControlButton(next_x, control_y, button_size, "next", "next")

    self:_drawModernVolumeButton(volume_button_x, control_y, button_size)

    self:_drawShuffleButton(shuffle_button_x, control_y, button_size)
    self:_drawRepeatButton(repeat_button_x, control_y, button_size)
end

function Controls:_getPlayPauseIcon()
    local status = self.game_state.last_status
    local is_playing = status and status.state == "playing"
    return is_playing and "pause" or "play"
end

function Controls:_drawModernProgressBar(x, y, width, height, progress, current_time, total_time)
    local radius = height / 2

    self.progress_bar = self.progress_bar or {}
    self.progress_bar.x = x
    self.progress_bar.y = y
    self.progress_bar.width = width
    self.progress_bar.height = height

    love.graphics.setColor(self.game_state.theme.progress_bg[1], self.game_state.theme.progress_bg[2], self.game_state.theme.progress_bg[3], 0.6)
    self:_drawRoundedRect(x, y, width, height, radius)

    local fill_width = width * math.min(1.0, math.max(0.0, progress))
    if fill_width > 0 then

        local segments = 3
        local segment_width = fill_width / segments

        for i = 0, segments - 1 do
            local segment_x = x + i * segment_width
            local blend = i / (segments - 1)

            local theme = self.game_state.theme
            local r = theme.gradient_main[1][1] * (1 - blend) + theme.gradient_main[2][1] * blend
            local g = theme.gradient_main[1][2] * (1 - blend) + theme.gradient_main[2][2] * blend
            local b = theme.gradient_main[1][3] * (1 - blend) + theme.gradient_main[2][3] * blend

            love.graphics.setColor(r, g, b, 1.0)

            love.graphics.rectangle("fill", segment_x, y, segment_width + 1, height)
        end

        love.graphics.setColor(self.game_state.theme.gradient_main[1])
        love.graphics.circle("fill", x + radius, y + radius, radius)

        if fill_width >= width - radius then
            love.graphics.setColor(self.game_state.theme.gradient_main[2])
            love.graphics.circle("fill", x + fill_width - radius, y + radius, radius)
        end

        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.rectangle("fill", x, y, fill_width, height/2)
    end

    local time_font = love.graphics.newFont(11)
    love.graphics.setFont(time_font)

    local current_str = self:_formatTime(current_time)
    local total_str = self:_formatTime(total_time)

    love.graphics.setColor(self.game_state.theme.text_secondary)
    local time_y = y + height / 2 - time_font:getHeight() / 2  
    love.graphics.print(current_str, x - time_font:getWidth(current_str) - 10, time_y)

    love.graphics.setColor(self.game_state.theme.text_secondary)
    love.graphics.print(total_str, x + width + 10, time_y)
end

function Controls:_drawModernControlButton(x, y, size, button_id, icon_name)
    local radius = size / 2
    local center_x = x + radius
    local center_y = y + radius

    if not self.modern_buttons then self.modern_buttons = {} end
    self.modern_buttons[button_id] = {
        x = x, y = y, width = size, height = size,
        center_x = center_x, center_y = center_y, radius = radius
    }

    local icon_image = self.icons[icon_name]
    if icon_image then
        love.graphics.setColor(self.game_state.theme.text_secondary)
        local icon_size = size * 0.5
        local scale = icon_size / math.max(icon_image:getWidth(), icon_image:getHeight())
        local icon_x = center_x - (icon_image:getWidth() * scale) / 2
        local icon_y = center_y - (icon_image:getHeight() * scale) / 2
        love.graphics.draw(icon_image, icon_x, icon_y, 0, scale, scale)
    end
end

function Controls:_drawModernVolumeButton(x, y, size)
    local radius = size / 2
    local center_x = x + radius
    local center_y = y + radius

    if not self.modern_buttons then self.modern_buttons = {} end
    self.modern_buttons.volume = {
        x = x, y = y, width = size, height = size,
        center_x = center_x, center_y = center_y, radius = radius,
        is_volume_popup_open = false
    }

    love.graphics.setColor(self.game_state.theme.button_normal)
    love.graphics.circle("fill", center_x, center_y, radius)

    if self.icons.sound then
        love.graphics.setColor(self.game_state.theme.text_secondary)
        local icon_size = size * 0.5
        local scale = icon_size / math.max(self.icons.sound:getWidth(), self.icons.sound:getHeight())
        local icon_x = center_x - (self.icons.sound:getWidth() * scale) / 2
        local icon_y = center_y - (self.icons.sound:getHeight() * scale) / 2
        love.graphics.draw(self.icons.sound, icon_x, icon_y, 0, scale, scale)
    end
end

function Controls:_drawModernVolumeButton(x, y, size)
    local radius = size / 2
    local center_x = x + radius
    local center_y = y + radius

    if not self.modern_buttons then self.modern_buttons = {} end
    self.modern_buttons.volume = {
        x = x, y = y, width = size, height = size,
        center_x = center_x, center_y = center_y, radius = radius
    }

    if not self.volume_popup then
        self.volume_popup = {
            is_open = false,
            x = 0, y = 0, width = 30, height = 120
        }
    end

    if self.icons.sound then
        love.graphics.setColor(self.game_state.theme.text_secondary)
        local icon_size = size * 0.5
        local scale = icon_size / math.max(self.icons.sound:getWidth(), self.icons.sound:getHeight())
        local icon_x = center_x - (self.icons.sound:getWidth() * scale) / 2
        local icon_y = center_y - (self.icons.sound:getHeight() * scale) / 2
        love.graphics.draw(self.icons.sound, icon_x, icon_y, 0, scale, scale)
    end

    if self.volume_popup.is_open then
        self:_drawVolumePopup(center_x, center_y - size/2 - 10)
    end
end

function Controls:_drawVolumePopup(x, y)
    local status = self.game_state.last_status
    local volume = status and status.volume or 0.8

    local popup_width = 30
    local popup_height = 120
    local popup_x = x - popup_width / 2
    local popup_y = y - popup_height

    self.volume_popup.x = popup_x
    self.volume_popup.y = popup_y
    self.volume_popup.width = popup_width
    self.volume_popup.height = popup_height

    love.graphics.setColor(self.game_state.theme.bg_elevated[1], self.game_state.theme.bg_elevated[2], self.game_state.theme.bg_elevated[3], 0.95)
    self:_drawRoundedRect(popup_x - 5, popup_y - 5, popup_width + 10, popup_height + 10, 8)

    local track_x = popup_x + popup_width / 2 - 2
    local track_width = 4
    love.graphics.setColor(self.game_state.theme.progress_bg)
    self:_drawRoundedRect(track_x, popup_y + 10, track_width, popup_height - 20, track_width / 2)

    local fill_height = (popup_height - 20) * math.min(1.0, math.max(0.0, volume / 2.0))
    local fill_y = popup_y + popup_height - 10 - fill_height

    if fill_height > 0 then
        love.graphics.setColor(self.game_state.theme.accent_blue)
        self:_drawRoundedRect(track_x, fill_y, track_width, fill_height, track_width / 2)

        local handle_y = fill_y
        local handle_radius = 8

        love.graphics.setColor(self.game_state.theme.accent_blue)
        love.graphics.circle("fill", track_x + track_width / 2, handle_y, handle_radius)

        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", track_x + track_width / 2 - 1, handle_y - 1, handle_radius / 2)
    end

    local volume_font = love.graphics.newFont(10)
    love.graphics.setFont(volume_font)
    love.graphics.setColor(self.game_state.theme.text_primary)
    local volume_text = string.format("%d%%", math.floor(volume * 100))
    local text_width = volume_font:getWidth(volume_text)
    love.graphics.print(volume_text, popup_x + popup_width / 2 - text_width / 2, popup_y + popup_height + 5)
end

function Controls:_formatTime(seconds)
    if not seconds or seconds < 0 then
        return "00:00"
    end

    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

function Controls:_drawRoundedRect(x, y, width, height, radius, mode)
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

function Controls:mousepressed(x, y, button)
    if button == 1 then 

        if self.modern_buttons then
            for button_id, btn_data in pairs(self.modern_buttons) do
                if self:_isPointInCircle(x, y, btn_data) then
                    if button_id == "previous" then
                        self:_previousTrack()
                    elseif button_id == "play_pause" then
                        self:_togglePlayback()
                    elseif button_id == "next" then
                        self:_nextTrack()
                    elseif button_id == "volume" then

                        if not self.volume_popup then
                            self.volume_popup = { is_open = false }
                        end
                        self.volume_popup.is_open = not self.volume_popup.is_open
                    end
                    return true
                end
            end
        end

        if self.shuffle_button and self:_isPointInRect(x, y, self.shuffle_button) then
            self:_toggleShuffle()
            return true
        end

        if self.repeat_button and self:_isPointInRect(x, y, self.repeat_button) then
            self:_toggleRepeat()
            return true
        end

        if self.progress_bar and self:_isPointInProgressBar(x, y) then
            self.progress_bar.is_dragging = true
            self:_handleProgressBarClick(x, y)
            return true
        end

        if self.volume_popup and self.volume_popup.is_open and self:_isPointInVolumePopup(x, y) then
            self.volume_popup.is_dragging = true
            self:_handleVolumePopupClick(x, y)
            return true
        end

        if self.volume_popup and self.volume_popup.is_open then
            self.volume_popup.is_open = false
        end

        if self.main_play_button and self:_isPointInCircle(x, y, self.main_play_button) then
            self:_togglePlayback()
            return true
        end

        if self:_checkCircularButtonClick(x, y) then
            return true
        end

        for _, btn in ipairs(self.buttons) do
            if btn.bounds and self:_isPointInRect(x, y, btn.bounds) then
                self.button_states[btn.id].pressed = true
                btn.action()
                return true
            end
        end
    end
    return false
end

function Controls:_isPointInCircle(x, y, circle)
    local dx = x - circle.center_x
    local dy = y - circle.center_y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance <= circle.radius
end

function Controls:_isPointInProgressBar(x, y)
    if not self.progress_bar then return false end
    return x >= self.progress_bar.x and 
           x <= self.progress_bar.x + self.progress_bar.width and
           y >= self.progress_bar.y and 
           y <= self.progress_bar.y + self.progress_bar.height
end

function Controls:_isPointInVolumePopup(x, y)
    if not self.volume_popup then return false end
    return x >= self.volume_popup.x and 
           x <= self.volume_popup.x + self.volume_popup.width and
           y >= self.volume_popup.y and 
           y <= self.volume_popup.y + self.volume_popup.height
end

function Controls:_handleVolumePopupClick(x, y)
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        return
    end

    local relative_y = y - self.volume_popup.y - 10 
    local usable_height = self.volume_popup.height - 20 
    local volume_position = 1.0 - math.max(0.0, math.min(1.0, relative_y / usable_height))
    local new_volume = volume_position * 2.0 

    local ok, err = self.game_state.engine:set_volume(new_volume)
    if not ok then
        print("Failed to set volume:", err)
    end
end

function Controls:_handleProgressBarClick(x, y)
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        return
    end

    local relative_x = x - self.progress_bar.x
    local seek_position = math.max(0.0, math.min(1.0, relative_x / self.progress_bar.width))

    local ok, err = self.game_state.engine:seek(seek_position)
    if ok then

        self.game_state.app_state.user_seeking = true
        self.game_state.app_state.last_seek_time = love.timer.getTime()
    else
        print("Seek failed:", err)
    end
end

function Controls:_checkCircularButtonClick(x, y)

    local draw_x, draw_y, draw_width, draw_height = self:_getLastDrawParams()
    if not draw_x then
        return false 
    end

    local center_x = draw_x + draw_width / 2
    local center_y = draw_y + draw_height / 2

    local main_button_size = 60
    local side_button_size = 45
    local small_button_size = 35
    local button_spacing = 70

    local circular_buttons = {
        {
            x = center_x - button_spacing * 2,
            y = center_y,
            radius = small_button_size / 2,
            action = function() 
                print("Stop button clicked")
                self:_stopPlayback() 
            end
        },
        {
            x = center_x - button_spacing,
            y = center_y,
            radius = side_button_size / 2,
            action = function() 
                print("Previous button clicked")
                self:_previousTrack() 
            end
        },
        {
            x = center_x + button_spacing,
            y = center_y,
            radius = side_button_size / 2,
            action = function() 
                print("Next button clicked")
                self:_nextTrack() 
            end
        },
        {
            x = center_x + button_spacing * 2,
            y = center_y,
            radius = small_button_size / 2,
            action = function() 
                print("Volume/Mute button clicked")
                self:_toggleMute() 
            end
        }
    }

    for _, btn in ipairs(circular_buttons) do
        local dx = x - btn.x
        local dy = y - btn.y
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance <= btn.radius then
            btn.action()
            return true
        end
    end

    return false
end

function Controls:mousereleased(x, y, button)
    if button == 1 then

        for _, state in pairs(self.button_states) do
            state.pressed = false
        end

        if self.progress_bar and self.progress_bar.is_dragging then
            self.progress_bar.is_dragging = false
            return true
        end

        if self.volume_popup and self.volume_popup.is_dragging then
            self.volume_popup.is_dragging = false
            return true
        end

    end
    return false
end

function Controls:mousemoved(x, y, dx, dy)

    for _, btn in ipairs(self.buttons) do
        if btn.bounds then
            self.button_states[btn.id].hover = self:_isPointInRect(x, y, btn.bounds)
        end
    end

    if self.progress_bar and self.progress_bar.is_dragging then
        self:_handleProgressBarClick(x, y)
        return true
    end

    if self.volume_popup and self.volume_popup.is_dragging then
        self:_handleVolumePopupClick(x, y)
        return true
    end

    return false
end

function Controls:keypressed(key, scancode, isrepeat)

    if key == "space" then
        self:_togglePlayback()
        return true
    elseif key == "left" then
        self:_previousTrack()
        return true
    elseif key == "right" then
        self:_nextTrack()
        return true
    elseif key == "up" then
        self:_volumeUp()
        return true
    elseif key == "down" then
        self:_volumeDown()
        return true
    elseif key == "s" then
        self:_stopPlayback()
        return true
    elseif key == "m" then
        self:_toggleMute()
        return true
    end
    return false
end

function Controls:_isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.width and
           y >= rect.y and y <= rect.y + rect.height
end

function Controls:_togglePlayback()
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        print("Engine not available")
        return
    end

    local status = self.game_state.engine:get_status()
    if status.state == "playing" then
        local ok, err = self.game_state.engine:pause()
        if ok then
            print("Playback paused")
        else
            print("Failed to pause:", err)
        end
    else
        local ok, err = self.game_state.engine:play()
        if ok then
            print("Playback started")
        else
            print("Failed to play:", err)
        end
    end
end

function Controls:_stopPlayback()
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        print("Engine not available")
        return
    end

    local ok, err = self.game_state.engine:stop()
    if ok then
        print("Playback stopped")
    else
        print("Failed to stop:", err)
    end
end

function Controls:_previousTrack()
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        print("Engine not available")
        return
    end

    local prev_track = self.game_state:getPreviousTrack()
    if prev_track then
        local ok, err = self.game_state:_navigateToTrack(prev_track)
        if ok then
            print("Previous track (shuffle-aware):", prev_track)

            local status = self.game_state.last_status
            if status and status.state == "playing" then
                self.game_state.engine:play()
            end
        else
            print("Failed to go to previous track:", err)
        end
    else
        print("No previous track available")
    end
end

function Controls:_nextTrack()
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        print("Engine not available")
        return
    end

    local next_track = self.game_state:getNextTrack()
    if next_track then
        local ok, err = self.game_state:_navigateToTrack(next_track)
        if ok then
            print("Next track (shuffle-aware):", next_track)

            local status = self.game_state.last_status
            if status and status.state == "playing" then
                self.game_state.engine:play()
            end
        else
            print("Failed to go to next track:", err)
        end
    else
        print("No next track available")
    end
end

function Controls:_volumeUp()
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        return
    end

    local status = self.game_state.engine:get_status()
    local new_volume = math.min(2.0, status.volume + 0.1)
    local ok, err = self.game_state.engine:set_volume(new_volume)
    if ok then
        print("Volume:", math.floor(new_volume * 100) .. "%")
    else
        print("Failed to set volume:", err)
    end
end

function Controls:_volumeDown()
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        return
    end

    local status = self.game_state.engine:get_status()
    local new_volume = math.max(0.0, status.volume - 0.1)
    local ok, err = self.game_state.engine:set_volume(new_volume)
    if ok then
        print("Volume:", math.floor(new_volume * 100) .. "%")
    else
        print("Failed to set volume:", err)
    end
end

function Controls:_toggleMute()
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        return
    end

    local status = self.game_state.engine:get_status()
    local new_volume = status.volume > 0.0 and 0.0 or 0.8 
    local ok, err = self.game_state.engine:set_volume(new_volume)
    if ok then
        print(new_volume > 0.0 and "Unmuted" or "Muted")
    else
        print("Failed to toggle mute:", err)
    end
end

function Controls:update(dt)

end

function Controls:_drawRoundedRect(x, y, width, height, radius, mode)
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

function Controls:_drawShuffleButton(x, y, size)
    local state = self.button_states.shuffle
    local radius = size / 2

    self.shuffle_button = {
        x = x,
        y = y,
        width = size,
        height = size,
        center_x = x + radius,
        center_y = y + radius
    }

    if self.icons.shuffle then

        local icon_color = self.shuffle_enabled and {1, 1, 1, 1} or {0.6, 0.6, 0.6, 0.8}
        love.graphics.setColor(icon_color)

        local icon_size = size * 0.6
        local center_x = x + size / 2
        local center_y = y + size / 2
        local scale = icon_size / math.max(self.icons.shuffle:getWidth(), self.icons.shuffle:getHeight())

        local scale_x = self.shuffle_enabled and -scale or scale
        local scale_y = scale

        love.graphics.draw(self.icons.shuffle, center_x, center_y, 0, scale_x, scale_y, 
                          self.icons.shuffle:getWidth()/2, self.icons.shuffle:getHeight()/2)
    end
end

function Controls:_drawRepeatButton(x, y, size)
    local state = self.button_states.repeat_btn
    local radius = size / 2

    self.repeat_button = {
        x = x,
        y = y,
        width = size,
        height = size,
        center_x = x + radius,
        center_y = y + radius
    }

    if self.icons.replay then

        local icon_color = (self.repeat_mode ~= "off") and {1, 1, 1, 1} or {0.6, 0.6, 0.6, 0.8}
        love.graphics.setColor(icon_color)

        local rotation = 0
        if self.repeat_mode == "all" then
            rotation = math.pi / 2  
        elseif self.repeat_mode == "one" then
            rotation = math.pi  
        end

        local icon_size = size * 0.6
        local center_x = x + size / 2
        local center_y = y + size / 2
        local scale = icon_size / math.max(self.icons.replay:getWidth(), self.icons.replay:getHeight())

        love.graphics.draw(self.icons.replay, center_x, center_y, rotation, scale, scale, 
                          self.icons.replay:getWidth()/2, self.icons.replay:getHeight()/2)
    end

    if self.repeat_mode == "one" then

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print("1", x + size - 15, y + 5)
    end
end

function Controls:_isPointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.width and
           y >= rect.y and y <= rect.y + rect.height
end

function Controls:_toggleShuffle()
    self.game_state:toggleShuffle()

    self.shuffle_enabled = self.game_state.app_state.shuffle_enabled
end

function Controls:_toggleRepeat()
    self.game_state:toggleRepeat()

    self.repeat_mode = self.game_state.app_state.repeat_mode
end

function Controls:update(dt)

    self.shuffle_enabled = self.game_state.app_state.shuffle_enabled
    self.repeat_mode = self.game_state.app_state.repeat_mode
end

function Controls:getPreferredHeight()
    return self.layout.button_height + (self.layout.padding * 2)
end

return Controls