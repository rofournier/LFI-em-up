function love.conf(t)
    -- Configuration settings
end

local current_scene

local scenes

function love.load()
    love.window.setFullscreen(true, "exclusive")
    main_ship = love.graphics.newImage("images/player.png")
    enemy1 = love.graphics.newImage("images/enemy1.png")
    explosion_image = love.graphics.newImage("images/explosion.png")
    enemy2 = love.graphics.newImage("images/enemy2.png")
    enemy3 = love.graphics.newImage("images/enemy3.png")
    enemy4 = love.graphics.newImage("images/enemy4.png")
    bonus1 = love.graphics.newImage("images/bonus1.png")
    bonus2 = love.graphics.newImage("images/bonus2.png")
    bomb = love.graphics.newImage("images/bomb.png")
    laser = love.graphics.newImage("images/laser.png")

    -- Load scenes
    scenes = {
        game = require("scenes.game"),
        menu = require("scenes.menu")
    }

    -- Set initial scene
    switch_scene("menu")
end

function love.update(dt)
    if current_scene and current_scene.update then
        current_scene.update(dt)
    end
end

function love.draw()
    if current_scene and current_scene.draw then
        current_scene.draw()
    end
end

function love.keypressed(key)
    if current_scene and current_scene.keypressed then
        current_scene.keypressed(key)
    end
end

function love.keyreleased(key)
    if current_scene and current_scene.keyreleased then
        current_scene.keyreleased(key)
    end
end

function switch_scene(scene_name)
    current_scene = scenes[scene_name]
    if current_scene and current_scene.load then
        current_scene.load()
    end
end