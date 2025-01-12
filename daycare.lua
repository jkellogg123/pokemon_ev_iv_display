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
            local time_m = (os.time() - start) / 60
            print(string.format("Done!  Took:  %.1fm", time_m))
            print("XXX")
            return
        end
        if cycles_done % 10 == 0 then
            local now = os.time()
            local time_per_cycle = (now - cycle_start) / cycles_done
            local time_total  = (cycles * time_per_cycle) + (cycle_start - start)
            local time_left = time_total - (now - start)
            print(string.format("%d/%d \t~%.1fm remain  (%.1fm total)", cycles_done, cycles, time_left/60, time_total/60))
        end
        emu:addKey(direction)
        frames_done = 0
    end
end

local function cycle()
    emu:addKey(direction)

    local init_frames = 8 + 12 + 4      -- 8 frames to turn character, 12 + 4 to startup on the bike
    frames_1way = math.ceil((steps+2) * 4.05) + init_frames     -- mach bike takes 4 frames per tile (for me it was inconsistent so I settled for this, banging the head against the wall tile)
    frames_done = 0
    cycles_done = 0
    cycle_start = os.time()
    id = callbacks:add("frame", cycleThread)
end

local function main()
    print("------------")
    start = os.time()
    local game = emu:getGameCode()
    if (game == "AGB-AXVE") or (game == "AGB-AXPE") or (game == "AGB-BPEE") then        -- rse
        steps = 134
        direction = LEFT
    elseif (game == "AGB-BPRE") or (game == "AGB-BPGE") then        -- frlg
        steps = 59
        direction = DOWN
    end

    local exp = 40000
    cycles = exp // (steps * 2)

    print(string.format("Starting Daycare loop for %dexp, which will take roughly %d cycles there and back.", exp, cycles))
    cycle()
end

main()