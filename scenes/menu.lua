local menu = {}
menu.items = {"New Game", "Options", "Credits", "Exit"}
menu.selectedIndex = 1

function menu.load()
    love.graphics.setFont(love.graphics.newFont(20))
    menu.titleImage = love.graphics.newImage("images/title.png")
    menu.bg = love.audio.newSource("sound/menu.mp3", "static")
    menu.select_sound = love.audio.newSource("sound/menuselect.mp3", "static")
    menu.bg:play()
end

function menu.update(dt)
    -- body
end

function menu.keypressed(key)
    if key == "up" then
        menu.select_sound:play()
        menu.selectedIndex = menu.selectedIndex - 1
        if menu.selectedIndex < 1 then
            menu.selectedIndex = #menu.items
        end
    elseif key == "down" then
        menu.select_sound:play()
        menu.selectedIndex = menu.selectedIndex + 1
        if menu.selectedIndex > #menu.items then
            menu.selectedIndex = 1
        end
    elseif key == "return" then
        if menu.items[menu.selectedIndex] == "New Game" then
            menu.bg:stop()
            switch_scene("game")
        elseif menu.items[menu.selectedIndex] == "Exit" then
            love.event.quit()
        end
    end
end

function menu.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw title image
    local titleX = (screenWidth - menu.titleImage:getWidth()) / 2
    love.graphics.setColor(1, 1, 1) -- Reset color to white for the image
    love.graphics.draw(menu.titleImage, titleX, 50)

    -- Draw menu items
    for i, item in ipairs(menu.items) do
        local itemY = love.graphics.getHeight() / 2 + 50 + (i - 1) * 30
        if i == menu.selectedIndex then
            love.graphics.setColor(0.5, 0.5, 0.5) -- Gray background for selected item
            love.graphics.rectangle("fill", 0, itemY, screenWidth, 30)
            love.graphics.setColor(1, 1, 1) -- White color for text
        else
            love.graphics.setColor(1, 1, 1) -- White color for non-selected items
        end
        love.graphics.printf(item, 0, itemY, screenWidth, "center")
    end
end

function menu.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        for i, item in ipairs(menu.items) do
            local itemY = 200 + (i - 1) * 30
            if y >= itemY and y <= itemY + 20 then
                menu.selectedIndex = i
                if item == "New Game" then
                    -- Start new game
                end
            end
        end
    end
end

return menu