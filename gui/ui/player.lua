local Player = {}
Player.__index = Player

function Player:new(game_state)
    local player = {
        game_state = game_state,
        layout = {
            padding = 20,
            margin = 10,
            progress_bar_height = 25,
            info_section_height = 120,
            time_font_size = 14,
            title_font_size = 18,
            info_font_size = 12
        },
        fonts = {},
        colors = {},
        progress_bar = {
            x = 0,
            y = 0,
            width = 0,
            height = 0,
            is_dragging = false,
            last_seek_time = 0,
            seek_throttle = 0.1, 
            pending_seek_position = nil
        }
    }

    setmetatable(player, self)
    player:_initializeFonts()
    player:_initializeColors()

    return player
end

function Player:_initializeFonts()
    self.fonts = {
        title = love.graphics.newFont(self.layout.title_font_size),
        time = love.graphics.newFont(self.layout.time_font_size),
        info = love.graphics.newFont(self.layout.info_font_size),
        default = love.graphics.getFont()
    }
end

function Player:_initializeColors()
    local theme = self.game_state.theme
    self.colors = {
        background = theme.glass,
        surface = theme.bg_elevated,
        text_primary = theme.text_primary,
        text_secondary = theme.text_secondary,
        text_muted = theme.text_muted,
        progress_bg = theme.progress_bg,
        progress_fill = theme.progress_fill,
        progress_handle = theme.accent_pink,
        track_info_bg = theme.glass,
        accent = theme.accent_pink,
        glow = theme.accent_pink,
        shadow = {0.0, 0.0, 0.0, 0.3}
    }
end

function Player:draw(x, y, width, height)

    local prev_font = love.graphics.getFont()
    local prev_color = {love.graphics.getColor()}

    self:_drawCleanSongInfo(x, y, width, height)

    love.graphics.setFont(prev_font)
    love.graphics.setColor(prev_color)
end

function Player:_drawCleanSongInfo(x, y, width, height)
    local status = self.game_state.last_status
    local song_title = "No song loaded"

    if status and status.current_file then

        song_title = status.current_file:match("([^/\\]+)$") or status.current_file
        song_title = song_title:match("(.+)%..+$") or song_title
    end

    local center_x = x + width / 2

    local title_font = love.graphics.newFont(28)
    love.graphics.setFont(title_font)
    love.graphics.setColor(self.game_state.theme.text_primary)

    local title_width = title_font:getWidth(song_title)
    love.graphics.print(song_title, center_x - title_width/2, y + height/2 - title_font:getHeight()/2)
end

function Player:_drawRoundedRect(x, y, width, height, radius, mode)
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

function Player:_drawRoundedRect(x, y, width, height, radius, mode)
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

function Player:_formatTime(seconds)
    if not seconds or seconds < 0 then
        return "00:00"
    end

    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

function Player:mousepressed(x, y, button)
    if button == 1 then 

        if self:_isPointInProgressBar(x, y) then
            self.progress_bar.is_dragging = true

            self:_handleProgressBarClick(x, y, true)
            return true
        end
    end
    return false
end

function Player:mousereleased(x, y, button)
    if button == 1 and self.progress_bar.is_dragging then
        self.progress_bar.is_dragging = false

        if self.progress_bar.pending_seek_position then
            self:_performSeek(self.progress_bar.pending_seek_position)
            self.progress_bar.pending_seek_position = nil
        end
        return true
    end
    return false
end

function Player:mousemoved(x, y, dx, dy)
    if self.progress_bar.is_dragging then

        self:_handleProgressBarClick(x, y, false)
        return true
    end
    return false
end

function Player:_isPointInProgressBar(x, y)
    return x >= self.progress_bar.x and 
           x <= self.progress_bar.x + self.progress_bar.width and
           y >= self.progress_bar.y and 
           y <= self.progress_bar.y + self.progress_bar.height
end

function Player:_handleProgressBarClick(x, y, immediate)
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        return
    end

    local relative_x = x - self.progress_bar.x
    local seek_position = math.max(0.0, math.min(1.0, relative_x / self.progress_bar.width))

    if immediate then

        self:_performSeek(seek_position)
    else

        local current_time = love.timer.getTime()
        if current_time - self.progress_bar.last_seek_time >= self.progress_bar.seek_throttle then
            self:_performSeek(seek_position)
            self.progress_bar.last_seek_time = current_time
            self.progress_bar.pending_seek_position = nil
        else

            self.progress_bar.pending_seek_position = seek_position
        end
    end
end

function Player:_performSeek(seek_position)
    if not self.game_state.engine or not self.game_state.engine:is_valid() then
        return
    end

    seek_position = math.max(0.0, math.min(1.0, seek_position))

    local status = self.game_state.engine:get_status()
    if not status or not status.current_file or status.total_time <= 0 then
        return
    end

    if status.total_time > 0 then
        local safety_margin = math.max(3.0, status.total_time * 0.05) 
        local max_seek_position = math.max(0.0, (status.total_time - safety_margin) / status.total_time)
        
        if seek_position > max_seek_position then
            seek_position = max_seek_position
            print(string.format("Limiting seek to %.1f%% (%.1fs from end) to avoid MPEG decode errors", 
                  seek_position * 100, safety_margin))
        end
        
        if status.progress > 0.95 and seek_position > status.progress then
            print("Blocking seek - already near end of track to prevent decode errors")
            return
        end
    end

    self.game_state.app_state.user_seeking = true
    self.game_state.app_state.last_seek_time = love.timer.getTime()

    local ok, err = self.game_state.engine:seek(seek_position)
    if not ok then
        print("Failed to seek:", err)
    end
end

function Player:update(dt)

    if self.progress_bar.pending_seek_position and not self.progress_bar.is_dragging then
        local current_time = love.timer.getTime()
        if current_time - self.progress_bar.last_seek_time >= self.progress_bar.seek_throttle then
            self:_performSeek(self.progress_bar.pending_seek_position)
            self.progress_bar.pending_seek_position = nil
            self.progress_bar.last_seek_time = current_time
        end
    end
end

function Player:getPreferredHeight()
    return self.layout.info_section_height + 
           self.layout.progress_bar_height + 
           (self.layout.margin * 3) + 
           (self.layout.padding * 2) + 
           30 
end

return Player