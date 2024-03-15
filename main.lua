
function love.load()
    gameFont = love.graphics.newFont("PressStart2P-Regular.ttf", 16)
    -- Load music and set it to loop
    music = love.audio.newSource("music.ogg", "stream")
    music:setLooping(false)
    music:play()

    -- Character setup
    character = {
        x = 100,
        y = love.graphics.getHeight() - 150, -- Adjust based on character size
        width = 50,
        height = 50,
        speed = 200, -- pixels per second
        velocityY = 0,
        isOnGround = true,
        alreadyJumped = false,
        canDoubleJump = function(self)
            doubleJumpCondition = not self.alreadyJumped and not self.isOnGround and self.velocityY < 100 and self.velocityY > -300
            return doubleJumpCondition
        end,
        isJumping = function(self)
            return self.velocityY < 0
        end,
    }

    -- Platform setup
    platforms = {
        -- Ground platform
        {
            x = 0,
            y = love.graphics.getHeight() - 50,
            width = love.graphics.getWidth(),
            height = 50,
            color = {1,1,1},
        }
    }
    platformTimer = 0
    platformInterval = 1 -- seconds between new platforms

    -- Music speed control
    musicSpeed = 1 -- Normal speed

    -- Gravity and jump setup
    gravity = 980
    jumpStrength = -450
    levelCompleted = false
    gameOver = false
    showDebugger = false

end

function love.update(dt)
    if not music:isPlaying() and not gameOver then
        -- Music has ended, trigger level end actions
        levelCompleted = true
        -- Here, you can trigger any actions that should occur when the level ends,
        -- such as displaying a message or loading a new level
    end
    local rightEdge = love.graphics.getWidth()
    -- Character movement and music speed adjustment
    if love.keyboard.isDown("right") then
        -- Adjust character speed when moving left
        -- Calculate the distance from the right edge
        local distanceToRightEdge = rightEdge - (character.x + character.width)

        -- Adjust speed based on distance to right edge
        local speedModifier = math.max(distanceToRightEdge / rightEdge, 0.1) -- Ensure there's always some movement
        character.x = character.x + (character.speed * speedModifier * dt)
        -- Increase music speed up to 2x
        musicSpeed = math.min(musicSpeed + dt * 0.5, 2)
    elseif love.keyboard.isDown("left") then
        character.x = character.x - character.speed * dt
        -- Decrease music speed down to 0.5x
        musicSpeed = math.max(musicSpeed - dt * 0.5, 0.5)
    else
        -- Gradually return to normal speed if no key is pressed
        musicSpeed = musicSpeed > 1 and math.max(musicSpeed - dt * 0.5, 1) or math.min(musicSpeed + dt * 0.5, 1)
    end
    -- Restart game logic
    if love.keyboard.isDown("r") and gameOver then
        gameOver = false
        character.x = 100
        character.y = love.graphics.getHeight() - 500
        character.velocityY = 0
        -- Reset any other necessary states or variables
        music:play() -- Optionally restart the music
    end
    -- Show showDebugger
    if love.keyboard.isDown("d") then
        if not showDebugger then
            showDebugger = true
        else
            showDebugger = false
        end
    end

    music:setPitch(musicSpeed) -- Adjust playback speed

    -- Platform generation
    platformTimer = platformTimer + dt
    if platformTimer >= platformInterval / musicSpeed then
        platformTimer = 0
        local newPlatform = {
            x = love.graphics.getWidth(),
            y = math.random(100, love.graphics.getHeight() - 50),
            width = 100,
            height = 20,
            color = {1, 1, 1},
        }
        table.insert(platforms, newPlatform)
    end

    -- Update platforms (simple movement to the left)
    for i, platform in ipairs(platforms) do
        platform.x = platform.x - 100 * dt * musicSpeed
        -- Remove platforms that move off-screen
        if platform.x < -platform.width then
            table.remove(platforms, i)
        end
    end

    -- Apply gravity to character
    character.velocityY = character.velocityY + gravity * dt
    character.y = character.y + character.velocityY * dt

    -- Jumping logic
    if love.keyboard.isDown("space") then
        if character.isOnGround then
            character.velocityY = jumpStrength
            character.isOnGround = false
        elseif character:canDoubleJump() then
            character.velocityY = jumpStrength
            character.alreadyJumped = true
        end
    end

    -- Platform collision detection
    for _, platform in ipairs(platforms) do
        if character.x < platform.x + platform.width and character.x + 50 > platform.x and
           character.y < platform.y + platform.height and character.y + 50 > platform.y then
            if character.velocityY > 0 then -- character is moving down
                character.y = platform.y - 50
                character.velocityY = 0
                character.isOnGround = true
                character.alreadyJumped = false
                platform.color = {1, 1, 0} -- RGB for yellow
            end
        end
    end

    -- Check if the character is out of screen
    if character.y > love.graphics.getHeight() or character.x < 0 or character.x > love.graphics.getWidth() then
        gameOver = true
        -- Optional: Stop the music or any ongoing game actions
        music:stop()
    end


end

function love.draw()
    love.graphics.setFont(gameFont) -- Set the 8-bit style font
    -- Draw the character
    love.graphics.rectangle("fill", character.x, character.y - 1, 50, 50) -- Simple square for the character

     if character:isJumping() then
        -- Make the rectangle taller and narrower to indicate jumping
        love.graphics.rectangle("fill", character.x, character.y - 10, character.width * 0.5, character.height + 20)
    else
        -- Normal drawing for the character
        love.graphics.rectangle("fill", character.x, character.y, character.width, character.height)
    end
    -- Draw platforms
    for _, platform in ipairs(platforms) do
        love.graphics.setColor(platform.color)
        love.graphics.rectangle("fill", platform.x, platform.y, platform.width, platform.height)
        love.graphics.setColor(1, 1, 1)
    end
    if levelCompleted then
        love.graphics.printf("Level Complete!", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
    end
    if gameOver then
        love.graphics.setColor(1, 0, 0) -- Set text color to red for visibility
        love.graphics.printf("Game Over", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
    end
    love.graphics.setColor(1, 1, 1) -- Reset color to white for other drawings
    if showDebugger then
        drawDebugger()
    end

end

function drawDebugger()
    local statsText = "Character Stats:\n"
    statsText = statsText .. "X: " .. tostring(character.x) .. "\n"
    statsText = statsText .. "Y: " .. tostring(character.y) .. "\n"
    statsText = statsText .. "Velocity Y: " .. tostring(character.velocityY) .. "\n"
    statsText = statsText .. "Is On Ground: " .. tostring(character.isOnGround) .. "\n"
    statsText = statsText .. "Can Double Jump: " .. tostring(character:canDoubleJump()) .. "\n"

    -- Set the position and size of the showDebugger box
    local boxX, boxY = 10, 10
    local boxWidth = 200 -- Adjust the width as needed
    local boxHeight = 100 -- Adjust the height based on the amount of text

    -- Set background color for the showDebugger box
    love.graphics.setColor(0, 0, 0, 0.75) -- Semi-transparent black
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)

    -- Set text color
    love.graphics.setColor(1, 1, 1) -- White
    love.graphics.printf(statsText, boxX + 5, boxY + 5, boxWidth - 10)

    -- Reset color to white for other drawings
    love.graphics.setColor(1, 1, 1)
end
