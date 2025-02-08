if not _DATA_RUN then
    local script_dir = io.popen"cd .. && cd":read'*l'
    local data_path = script_dir .. "\\gen4\\data.lua"
    dofile(data_path)
end

local function checkShiny()
    local poke = readEnemy()
    return poke:isShiny()
end

local function press(...)
    local frames = 4
    local buttons = {...}
    local set_table = {}
    for key, value in pairs(buttons) do
        set_table[value] = "True"
    end
    for i = 1, frames do
        joypad.set(set_table)
        emu.frameadvance()
    end
end

local function wait(sec)
    for i = 1, sec * 60, 1 do
        emu.frameadvance()
    end
end

local function softReset()
    press("Select", "Start", "L", "R")

    -- Menuing
    wait(9)
    press("A")
    wait(1.7)
    press("A")
    wait(3.3)
    press("A")
    wait(3.5)

    -- Encounter
    press("A")
    wait(3)
    press("A")
    wait(1.8)
    press("A")
    wait(3.7)
    press("A")
    wait(0.8)
    press("A")
    wait(10)
    press("A")
    wait(4)
end

local function main()
    console.clear()

    press("A")
    reset_count = 0
    while not checkShiny() do
        reset_count = reset_count + 1
        if reset_count % 10 == 0 then
            console.clear()
        end
        print("Reset count: " .. reset_count)
        softReset()
    end
    print("Shiny found after " .. reset_count .. " resets")
end

main()
-- console.clear()
-- softReset()