local GameState = require("game_state")

function love.load()

    love.window.setTitle("Rhythm")
    love.window.setMode(800, 600, {
        resizable = true,
        minwidth = 600,
        minheight = 400,
        vsync = true
    })

    local success, iconData = pcall(love.image.newImageData, "assets/logo/logo.png")
    if success then
        love.window.setIcon(iconData)
        print("App icon set successfully")
    else
        print("Warning: Could not load app icon from assets/logo/logo.png:", iconData)
    end

    GameState:init()

    print("rhythm gui initialized")
end

function love.update(dt)

    GameState:update(dt)
end

function love.draw()

    love.graphics.clear(GameState.theme.background)

    GameState:draw()
end

function love.keypressed(key, scancode, isrepeat)

    GameState:keypressed(key, scancode, isrepeat)

    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button, istouch, presses)

    GameState:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)

    GameState:mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)

    GameState:mousemoved(x, y, dx, dy, istouch)
end

function love.resize(w, h)

    GameState:resize(w, h)
end

function love.filedropped(file)

    print("File dropped:", file:getFilename())
    GameState:handleDroppedFile(file)
end

function love.directorydropped(path)

    print("Directory dropped:", path)
    GameState:handleDroppedDirectory(path)
end

function love.quit()

    GameState:cleanup()
    print("rhythm gui shutting down")
end