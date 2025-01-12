if not _DATA_RUN then
    local script_path = debug.getinfo(1, "S").source:sub(2)
    local script_dir = script_path:match("(.*/)"):sub(1, -2):match("(.*/)")
    local data_path = script_dir .. "data.lua"
    dofile(data_path)
end

A = 0
B = 1
SELECT = 2
START = 3
RIGHT = 4
LEFT = 5
UP = 6
DOWN = 7
R = 8
L = 9

resets = 0
local current_frame = 0
local cum       -- ulative
local return_flag

local function press(button)
    local length = 3        -- num of frames this will take
    -- window
    if current_frame >= cum + length then
        cum = cum + length
        return
    elseif current_frame < cum then
        return
    -- flag
    elseif return_flag then
        return
    end
    return_flag = true

    -- meat
    local gunk = current_frame - cum
    if gunk == 0 then
        -- print("Pressing " .. button)
        emu:addKey(button)
        return
    elseif gunk == 1 then
        return
    elseif gunk == 2 then
        -- print("releasing " .. button)
        emu:clearKey(button)
        return
    end

    -- never reach
    return
end

local function wait(sec)
    local length = math.floor(60 * sec)     -- num of frames this will take
    -- window
    if current_frame >= cum + length then
        cum = cum + length
        return
    elseif current_frame < cum then
        return
    -- flag
    elseif return_flag then
        return
    end
    return_flag = true

    -- meat (nothing since just waiting)
    return
end

local function run(direction, steps, redirect)
    redirect = redirect or false
    local length = steps * 8      -- num of frames this will take
    if redirect then
        length = length + 8
    end
    -- window
    if current_frame > cum + length then
        cum = cum + length
        return
    elseif current_frame < cum then
        return
    -- flag
    elseif return_flag then
        return
    end
    return_flag = true
    
    -- meat
    local gunk = current_frame - cum
    if gunk == 0 then
        -- print("Running...")
        emu:addKey(B)
        emu:addKey(direction)
    elseif gunk == length then
        emu:clearKey(B)
        emu:clearKey(direction)

        -- keeps running flow when switching direction
        cum = cum + length
        return_flag = false
        -- print("done running")
        return
    end

    return
end


local function thread()
    current_frame = current_frame + 1
    -- print("Frame " .. tostring(current_frame))
    cum = 1
    return_flag = false

    -- check shiny
    if current_frame == 1 then
        local kyogre = readOpponent()
        if kyogre:isShiny() then
            callbacks:remove(id)
            print("Found the motherlode after " .. tostring(resets) .. " resets")
            return
        else
            print(string.format("Not shiny, resetting (%d total)", resets))
        end
    end

    -- flee
    press(RIGHT)
    press(DOWN)
    press(A)
    wait(3.2)
    press(B)
    wait(3.7)
    press(B)

    -- --buffer
    -- wait(2 / 60)

    -- leave and come back
    local move = run

    move(DOWN, 1, true)
    move(RIGHT, 9)
    move(UP, 12)
    move(LEFT, 2)
    move(UP, 2)
    move(LEFT, 2)
    move(UP, 9)
    move(RIGHT, 6)
    move(DOWN, 1)

    -- phase in/out map tile
    local delay = 1.4
    wait(delay)
    move(UP, 1, true)
    wait(delay)

    move(LEFT, 6, true)
    move(DOWN, 9)
    move(RIGHT, 2)
    move(DOWN, 2)
    move(RIGHT, 2)
    move(DOWN, 12)
    move(LEFT, 9)
    move(UP, 1)

    --intro/abilities
    wait(15)
    press(B)
    wait(7)

    if not return_flag then
        resets = resets + 1
        current_frame = 0
    end
end

local function main()
    id = callbacks:add("frame", thread)
    print("You mustn't try to stop what you cannot understand...")
end

main()