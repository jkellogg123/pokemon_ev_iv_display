local function print(thing)
    if thing == nil then
        thing = ""
    end
    console:log(tostring(thing))
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

OPPOSITE = {[LEFT] = RIGHT,
            [RIGHT] = LEFT,
            [UP] = DOWN,
            [DOWN] = UP}

local function spam(key, times)
    for i = 1, times, 1 do
        emu:addKey(key)
        for j = 1, 3, 1 do
            emu:runFrame()
        end
        emu:clearKey(key)
        emu:runFrame()
    end
end

local function cycleThread()
    frames_done = frames_done + 1

    if frames_done % 4 == 0 then
        emu:clearKey(B)
    else
        emu:addKey(B)
    end

    if frames_done == frames_1way then
        emu:clearKey(direction)
        emu:addKey(OPPOSITE[direction])
    end

    if frames_done == frames_1way * 2 then
        emu:clearKey(OPPOSITE[direction])
        cycles_done = cycles_done + 1
        if cycles_done == cycles then
            callbacks:remove(id)
            print("Done!")
            print("XX")
            return
        end
        if cycles_done % 10 == 0 then
            print(tostring(cycles_done) .. "/" .. tostring(cycles) .. " completed")
        end
        emu:addKey(direction)
        frames_done = 0
    end
end

local function cycle()
    emu:addKey(direction)

    local init_frames = 8 + 12 + 4      -- 8 frames to turn character, 12 + 4 to startup on the bike
    -- for i = 1, init_frames, 1 do
    --     emu:runFrame()
    -- end
    frames_1way = math.ceil((steps+2) * 4.05) + init_frames     -- mach bike takes 4 frames per tile (for me it was inconsistent so I settled for this, banging the head against the wall tile)
    frames_done = 0
    cycles_done = 0
    id = callbacks:add("frame", cycleThread)
end

local function main()
    print("------------")
    local game = emu:getGameCode()
    if (game == "AGB-AXVE") or (game == "AGB-AXPE") or (game == "AGB-BPEE") then        -- rse
        steps = 134
        direction = LEFT
    elseif (game == "AGB-BPRE") or (game == "AGB-BPGE") then        -- frlg
        steps = 59
        direction = DOWN
    end
    local exp = steps * 40
    cycles = exp // (steps * 2)

    cycle()
end

main()