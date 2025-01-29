if not _DATA_RUN then
    local script_dir = io.popen"cd":read'*l'
    local data_path = script_dir .. "\\data.lua"
    dofile(data_path)
end

-- Shows the expertly crafted display. Meant to be set on frame callback.
function display(skip_frames)
    if emu.framecount() % skip_frames == 0 then
        return
    end
    
    local front = readFront()
    local display_str = ""
    local function add(str)
        str = str or ""
        display_str = display_str .. str .. "\n"
    end

    add(string.format("%s @%s  %d/%d hp  |  %s", front.species, front.item, front.stat.curr_hp, front.stat.hp, front.ability))

    add(string.format("\t HP Atk Def SpA SpD Spe"))
    local iv = front.iv
    local ev = front.ev
    local stat = front.stat
    add(string.format("IVs:\t%3d %3d %3d %3d %3d %3d",
    iv.hp, iv.atk, iv.def, iv.spa, iv.spd, iv.spe))
    add(string.format("EVs:\t%3d %3d %3d %3d %3d %3d | Total %d",
    ev.hp, ev.atk, ev.def, ev.spa, ev.spd, ev.spe, front:sumEV()))
    add()
    add(string.format("Stats:\t%3d %3d %3d %3d %3d %3d",
    stat.hp, stat.atk, stat.def, stat.spa, stat.spd, stat.spe))

    add("\n")
    local enemy = readEnemy()
    if enemy == nil or enemy:checkFields({"species", "item", "ability", "ev_yield", "stat"}) then
        add("No enemy")
    else
        add(string.format("%s @%s  %d/%d hp  |  %s", enemy.species, enemy.item, enemy.stat.curr_hp, enemy.stat.hp, enemy.ability))
        if enemy:isShiny() then
            add("**Shiny**")
        end
        local ev_yield_str = ""
        for ev, yield in pairs(enemy.ev_yield) do
            if yield > 0 then
                ev_yield_str = ev_yield_str .. tostring(yield) .. " " .. ev .. "  "
            end
        end
        add(string.format("\t HP Atk Def SpA SpD Spe"))
        stat = enemy.stat
        add(string.format("Stats:\t%3d %3d %3d %3d %3d %3d",
        stat.hp, stat.atk, stat.def, stat.spa, stat.spd, stat.spe))
        if front.stat.spe > enemy.stat.spe then
            add("Your " .. front.species .. " outspeeds")
        elseif front.stat.spe == enemy.stat.spe then
            add("Speed tie")
        else
            add("Their " .. enemy.species .. " outspeeds")
        end

        add("Yields:   " .. ev_yield_str)
    end

    if display_str == prev_display_str then
        return
    end
    console.clear()
    console.log(display_str)
    prev_display_str = display_str
end



local skip_frames = 128
prev_display_str = "" -- global variable, only re-renders if the display string changes

event.onframeend(function () display(skip_frames) end)
function stop()
    event.unregisterbyname("display")
    console.clear()
    console.log("Display stopped!")
end
function redo()
    console.log("Refreshing display script...")
    stop()
    prev_display_str = ""
    event.onframeend(function () display(skip_frames) end)
end
