local game = {}
local wave_spawn_timer = 0
local level_timer = 0
local boss_explosion_timer = 0
local level_duration = 15
local explosions = {}
local waiting_for_menu = false
local boss_spawned = false


function game.load()
    music = love.audio.newSource("sound/music.mp3", "static")
    melenchon = love.audio.newSource("sound/mel.mp3", "static")
    explode = love.audio.newSource("sound/explode.mp3", "static")
    explosion_image = love.graphics.newImage("images/explosion.png")
    hit = love.audio.newSource("sound/hit.mp3", "static")
    music:setLooping(true)
    music:play()
    bullets = {}
    bonuses = {}
    level_timer = 0
    wave_spawn_timer = 0
    level = 1
    player = {
        x = 0,
        y = love.graphics.getHeight() / 2,
        speed = 200,
        image = main_ship,
        up = false,
        down = false,
        left = false,
        right = false,
        score = 0,
        shooting = false,
        weapons = {
            { name = "Laser", damage = 1, speed = 500, fire_rate = 0.2, ammo = 0, max_ammo = -1, last_shot = nil, level = 1 },
            { name = "Missile", damage = 5, speed = 300, fire_rate = 1, ammo = 0, max_ammo = 10, last_shot = nil }
        },
        current_weapon = 1
    }
    enemies = {}
    stars = {}
    planets = {}
    game_over = false
    waiting_for_menu = false
    for i = 1, 100 do
        table.insert(stars, {
            x = love.math.random(love.graphics.getWidth()),
            y = love.math.random(love.graphics.getHeight()),
            speed = love.math.random(50, 200)
        })
    end

    function createSimpleWave(startY)
        return {
            enemies = {
                { type = "enemy", x = love.graphics.getWidth(), y = startY, speed = 180, image = enemy2, life = 3, animation = newAnimation(enemy2, 100, 107, 1) },
                { type = "enemy", x = love.graphics.getWidth() + 100, y = startY, speed = 180, image = enemy2, life = 3, animation = newAnimation(enemy2, 100, 107, 1) },
                { type = "enemy", x = love.graphics.getWidth() + 200, y = startY, speed = 180, image = enemy2, life = 3, animation = newAnimation(enemy2, 100, 107, 1) },
                { type = "enemy", x = love.graphics.getWidth() + 300, y = startY, speed = 180, image = enemy2, life = 3, animation = newAnimation(enemy2, 100, 107, 1) },
                { type = "enemy", x = love.graphics.getWidth() + 400, y = startY, speed = 180, image = enemy2, life = 3, animation = newAnimation(enemy2, 100, 107, 1) },
            }
        }
    end

    function createBossWave(sprite, startY)
        return {
            enemies = {
                { type = "enemy", x = love.graphics.getWidth() - 350, y = startY, speed = 0, image = sprite, life = 100, animation = newAnimation(sprite, 400, 459, 1) }
            }
        }
    end

    function createWeaponBonusWave()
        return {
            enemies = {
                { type = "bonus", x = love.graphics.getWidth(), y = love.math.random(love.graphics.getHeight()), speed = 180, image = bonus1 },
            }
        }
    end

    function createMissileBonusWave()
        return {
            enemies = {
                { type = "bonus", x = love.graphics.getWidth(), y = love.math.random(love.graphics.getHeight()), speed = 180, image = bonus2 }
            }
        }
    end

    levels = {
        [1] = {
            wave_interval = 5,
            wave_number = 4,
            current_wave = 1,
            create_wave = function()
                local spawnY = love.math.random(80, love.graphics.getHeight() - 80)
                return createSimpleWave(spawnY)
            end
        },
        [2] = {
            wave_interval = 1,
            wave_number = 2,
            current_wave = 1,
            create_wave = function()
                local spawnY = love.math.random(80, love.graphics.getHeight() - 80)
                return createWeaponBonusWave(spawnY)
            end
        },
        [3] = {
            wave_interval = 3,
            wave_number = 4,
            current_wave = 1,
            create_wave = function()
                local spawnY = love.math.random(80, love.graphics.getHeight() - 80)
                return createSimpleWave(spawnY)
            end
        },
        [4] = {
            wave_interval = 1,
            wave_number = 2,
            current_wave = 1,
            create_wave = function()
                local spawnY = love.math.random(80, love.graphics.getHeight() - 80)
                return createMissileBonusWave(spawnY)
            end
        },
        [5] = {
            wave_interval = 1,
            wave_number = 2,
            current_wave = 1,
            create_wave = function()
                local spawnY = (love.graphics.getHeight() - enemy4:getHeight()) / 2
                return createBossWave(enemy4, spawnY)
            end
        }
    }
end


function game.update(dt)
    if not game_over then
        game.handle_movement(dt)
        game.handle_shooting(dt)
        game.handle_enemy_spawning(dt)
        game.handle_shoot_collisions(dt)
        game.handle_player_enemy_collisions()
        game.update_enemy_animations(dt)
    end
    game.update_explosions(dt)
end


function game.update_enemy_animations(dt)
    for i = #enemies, 1, -1 do
        enemy = enemies[i]
        if enemy.animation then
            enemy.animation.currentTime = enemy.animation.currentTime + dt
            if enemy.animation.currentTime >= enemy.animation.duration then
                enemy.animation.currentTime = enemy.animation.currentTime - enemy.animation.duration
            end
        end
        enemy.x = enemy.x - enemy.speed * dt
        if enemy.x < -enemy.image:getWidth() then
            table.remove(enemies, i)
        else
            if enemy.type == "bonus" then
                enemy.y = enemy.y + enemy.speed * dt * (enemy.direction or 1)
                if enemy.y < 0 then
                    enemy.y = 0
                    enemy.direction = 1
                elseif enemy.y > love.graphics.getHeight() - enemy.image:getHeight() then
                    enemy.y = love.graphics.getHeight() - enemy.image:getHeight()
                    enemy.direction = -1
                end
            end
        end
    end
end

function game.draw()
    game.draw_explosions()
    game.draw_hud()
    game.draw_bg_stars()
    game.draw_bg_planets()
    if game_over then
        local gameOverText = "Game Over"
        local returnText = "Press any key to return to menu"
        local gameOverX = (love.graphics.getWidth() - love.graphics.getFont():getWidth(gameOverText)) / 2
        local returnX = (love.graphics.getWidth() - love.graphics.getFont():getWidth(returnText)) / 2
        love.graphics.print(gameOverText, gameOverX, love.graphics.getHeight() / 2)
        love.graphics.print(returnText, returnX, love.graphics.getHeight() / 2 + 20)
    else
        love.graphics.draw(player.image, player.x, player.y)
        for _, bullet in ipairs(bullets) do
            love.graphics.draw(bullet.image, bullet.x, bullet.y)
        end
        for _, enemy in ipairs(enemies) do
            if enemy.animation then
                local spriteNum = math.floor(enemy.animation.currentTime / enemy.animation.duration * #enemy.animation.quads) + 1
                love.graphics.draw(enemy.animation.spriteSheet, enemy.animation.quads[spriteNum], enemy.x, enemy.y)
            else
                if enemy.image == enemy3 then
                    love.graphics.draw(enemy.image, enemy.x, enemy.y, enemy.rotation, 1, 1, enemy.image:getWidth() / 2, enemy.image:getHeight() / 2)
                else
                    love.graphics.draw(enemy.image, enemy.x, enemy.y)
                end
            end
        end
    end
end




function game.lose_game(i, enemy)
    music:stop()
    explode:play()
    game.create_explosion(enemy.x, enemy.y)
    game_over = true
    waiting_for_menu = true
end

function game.handle_shoot_collisions(dt)
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            if game.check_collision(bullet, enemy) and enemy.type == "enemy" then
                enemy.life = enemy.life - bullet.damage
                if enemy.life <= 0 then
                    table.remove(enemies, j)
                    player.score = player.score + 10
                    game.create_explosion(enemy.x, enemy.y)
                    if enemy.image == enemy4 then
                        for i = 1, 6 do
                            for j = 1, 10 do
                                game.create_explosion(enemy.x + (i - 3) * 80, enemy.y + (j - 3) * 80)
                            end
                        end
                    end
                end
                table.remove(bullets, i)
                hit:play()
                break
            end
        end
    end
end

function game.handle_player_enemy_collisions()
    for i, enemy in ipairs(enemies) do
        if game.check_collision(player, enemy) then
            if enemy.type == "bonus" then
                if enemy.image == bonus1 then
                    table.remove(enemies, i)
                    player.score = player.score + 50
                    player.weapons[player.current_weapon].level = player.weapons[player.current_weapon].level + 1
                elseif enemy.image == bonus2 then
                    table.remove(enemies, i)
                    melenchon:play()
                    player.score = player.score + 50
                    player.weapons[2].ammo = player.weapons[2].ammo + 5
                end
            else
                game.lose_game(i, enemy)
            end
        end
    end
end

function game.check_collision(obj1, obj2)
    return obj1.x and obj1.y and obj2.x and obj2.y and obj1.image and obj2.image and
           obj1.x < obj2.x + obj2.image:getWidth() and
           obj2.x < obj1.x + obj1.image:getWidth() and
           obj1.y < obj2.y + obj2.image:getHeight() and
           obj2.y < obj1.y + obj1.image:getHeight()
end



function game.keypressed(key)
    if game_over and waiting_for_menu then
        waiting_for_menu = false
        switch_scene("menu")
    else
        game.handle_movement_input(key)
        if key == "space" then
            player.shooting = true
        end
        if key == "a" then
            dropBomb()
        end
    end
end

function game.keyreleased(key)
    game.handle_movement_input_released(key)
    if key == "space" then
        player.shooting = false
    end
end

function game.draw_hud()
    dt = love.timer.getDelta()
    local padding = 10
    local rectWidth = love.graphics.getWidth()
    local rectHeight = 50
    local scoreText = "Score: " .. player.score
    local levelText = "Level: " .. level
    local bombsText = "Bombs: " .. player.weapons[2].ammo
    local text = scoreText .. "  " .. levelText .. "  " .. bombsText
    local textWidth = love.graphics.getFont():getWidth(text)
    local textHeight = love.graphics.getFont():getHeight()
    local timeText = level_timer

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 10, rectWidth, rectHeight)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, 10, 10 + (rectHeight - textHeight) / 2)
    local timeText = string.format("Time: %.2f", level_timer)
    love.graphics.print(timeText, rectWidth - love.graphics.getFont():getWidth(timeText) - padding, 10 + (rectHeight - textHeight) / 2)
    love.graphics.setColor(1, 1, 1) -- Reset color to white for other drawings
end

function game.draw_bg_stars()
    for _, star in ipairs(stars) do
        star.x = star.x - star.speed * love.timer.getDelta()
        if star.x < 0 then
            star.x = love.graphics.getWidth()
            star.y = love.math.random(love.graphics.getHeight())
            star.speed = love.math.random(50, 200)
        end
        love.graphics.points(star.x, star.y)
    end
end

function game.draw_bg_planets()
    if #planets < 1 then    
        local i = love.math.random(4)
        local planet_image = love.graphics.newImage("images/bg_planet" .. i .. ".png")
        table.insert(planets, {
            image = planet_image,
            x = love.graphics.getWidth() + (i - 1) * 200,
            y = love.math.random(love.graphics.getHeight()),
            speed = love.math.random(20, 100)
        })
    end
    
    for _, planet in ipairs(planets) do
        planet.x = planet.x - planet.speed * love.timer.getDelta()
        if planet.x < -planet.image:getWidth() then
            planet.x = love.graphics.getWidth()
            planet.y = love.math.random(love.graphics.getHeight())
            planet.speed = love.math.random(20, 100)
        end
        love.graphics.draw(planet.image, planet.x, planet.y)
        if planet.x < 0 then
            table.remove(planets, _)
        end
    end
end

function game.handle_movement(dt)
    if player.up and player.y > 0 then
        player.y = player.y - player.speed * dt
    elseif player.down and player.y < love.graphics.getHeight() - player.image:getHeight() then
        player.y = player.y + player.speed * dt
    end

    if player.left and player.x > 0 then
        player.x = player.x - player.speed * dt
    elseif player.right and player.x < love.graphics.getWidth() - player.image:getWidth() then
        player.x = player.x + player.speed * dt
    end
end

function game.handle_movement_input(key)
    if key == "up" then
        player.up = true
    elseif key == "down" then
        player.down = true
    elseif key == "left" then
        player.left = true
    elseif key == "right" then
        player.right = true
    end
end

function game.handle_movement_input_released(key)
    if key == "up" then
        player.up = false
    elseif key == "down" then
        player.down = false
    elseif key == "left" then
        player.left = false
    elseif key == "right" then
        player.right = false
    end
end

function game.create_bullet(weapon, y_offset)
    local bullet = {
        x = player.x + player.image:getWidth(),
        y = player.y + player.image:getHeight() / 2 + (y_offset or 0),
        speed = weapon.speed,
        damage = weapon.damage,
        image = laser
    }
    table.insert(bullets, bullet)
end

function game.handle_shooting(dt)
    local weapon = player.weapons[player.current_weapon]
    if player.shooting and (weapon.last_shot == nil or love.timer.getTime() - weapon.last_shot >= weapon.fire_rate) then
        if weapon.level == 1 then
            game.create_bullet(weapon)
        elseif weapon.level == 2 then
            game.create_bullet(weapon, -10)
            game.create_bullet(weapon, 10)
        elseif weapon.level >= 3 then
            game.create_bullet(weapon, -10)
            game.create_bullet(weapon, 0)
            game.create_bullet(weapon, 10)
        end
        weapon.last_shot = love.timer.getTime()
    end

    for i, bullet in ipairs(bullets) do
        bullet.x = bullet.x + bullet.speed * dt
        if bullet.x > love.graphics.getWidth() then
            table.remove(bullets, i)
        end
    end
end


function game.handle_enemy_spawning(dt)
    level_timer = level_timer + dt
    wave_spawn_timer = wave_spawn_timer + dt

    local current_level = levels[level]

    if wave_spawn_timer >= current_level.wave_interval and current_level.current_wave ~= current_level.wave_number then
        local wave = current_level.create_wave()
        for _, enemy in ipairs(wave.enemies) do
            table.insert(enemies, enemy)
        end
        wave_spawn_timer = 0
        current_level.current_wave = current_level.current_wave + 1
    elseif current_level.current_wave == current_level.wave_number and #enemies == 0 then
        level = level + 1
        if level > #levels then
            game_over = true
            waiting_for_menu = true
            music:stop()
            return
        end
        current_level = levels[level]
        level_timer = 0
        wave_spawn_timer = 0
        current_level.current_wave = 1
    end

end


function newAnimation(image, width, height, duration)
    local animation = {}
    animation.spriteSheet = image;
    animation.quads = {};

    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end

    animation.duration = duration or 1
    animation.currentTime = 0

    return animation
end

function game.create_explosion(x, y)
    local new_explosion = {
        x = x,
        y = y,
        animation = newAnimation(explosion_image, 100, 100, 1)
    }
    new_explosion.animation.currentTime = 0
    table.insert(explosions, new_explosion)
end

function game.update_explosions(dt)
    for i, explosion in ipairs(explosions) do
        explosion.animation.currentTime = explosion.animation.currentTime + dt
        if explosion.animation.currentTime >= explosion.animation.duration then
            table.remove(explosions, i)
        end
    end
end

function game.draw_explosions()
    for _, explosion in ipairs(explosions) do
        local spriteNum = math.floor(explosion.animation.currentTime / explosion.animation.duration * #explosion.animation.quads) + 1
        love.graphics.draw(explosion.animation.spriteSheet, explosion.animation.quads[spriteNum], explosion.x, explosion.y)
    end
end

function dropBomb()
    if player.weapons[2].ammo > 0 then
        player.weapons[2].ammo = player.weapons[2].ammo - 1
        local bullet = {
            x = player.x + player.image:getWidth(),
            y = player.y + player.image:getHeight() / 2 + (y_offset or 0),
            speed = player.weapons[2].speed,
            damage = player.weapons[2].damage,
            image = bomb
        }
        table.insert(bullets, bullet)
    end
end

return game

