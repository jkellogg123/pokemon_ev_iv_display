if not _DATA_RUN then
    local script_path = debug.getinfo(1, "S").source:sub(2)
    local script_dir = script_path:match("(.*/)")
    local data_path = script_dir .. "data.lua"
    dofile(data_path)
end


-- Scans and outputs party data
---@param skip_frames? integer If passed, will only scan every *skip_frames* frames
function scanParty(skip_frames)
    if (skip_frames ~= nil) and (emu:currentFrame() % skip_frames ~= 0) then
        return
    end

    if not partyEVBuffer then
        partyEVBuffer = console:createBuffer("Party EVs")
    end
    if not partyIVBuffer then
        partyIVBuffer = console:createBuffer("Party IVs")
    end

    local function sendEV(str)
        str = str or ""
        partyEVBuffer:print(str .. "\n")
    end
    local function sendIV(str)
        str = str or ""
        partyIVBuffer:print(str .. "\n")
    end
    local function send(str)
        sendEV(str)
        sendIV(str)
    end
    local count = emu:read8(PARTY_COUNT)
    partyEVBuffer:clear()
    partyIVBuffer:clear()
    for i = 0, (count - 1) * 100, 100 do
        local poke = readPoke(FRONT + i)
        if poke.species == POKEDEX[0] then
            goto continue
        end
        local ev = poke.ev
        local iv = poke.iv
        local name = poke.species
        name = name or ""
        if poke:isShiny() then
            name = name .. " **"
        end
        if poke.egg then
            name = name .. string.format(" %s (%d egg cycles)", poke.gender, poke.friendship)
        elseif poke.species_ind == 328 then     -- feebas
            name = name .. "(" .. tostring(poke.beauty) .. " beauty)"
        end

        send(string.format("%-16s @%s", name, poke.item))       -- turns out longest pokemon name in gen 3 is 12 characters (Pokémon Egg), followed by Masquerain (10 char)
        sendEV(string.format("HP %3d Atk %3d Def %3d Sp.A %3d Sp.D %3d Spe %3d Total %d",
                            ev.hp, ev.atk, ev.def, ev.spa, ev.spd, ev.spe, poke:sumEV()))
        sendIV(string.format("HP %2d Atk %2d Def %2d Sp.A %2d Sp.D %2d Spe %2d",
                            iv.hp, iv.atk, iv.def, iv.spa, iv.spd, iv.spe))
        send()
        ::continue::
    end
end


-- Scans and outputs the most recently encountered enemy pokemon (wild or trainer)
---@param skip_frames? integer If passed, will only scan every *skip_frames* frames
function scanEnemy(skip_frames)
    if (skip_frames ~= nil) and (emu:currentFrame() % skip_frames ~= 0) then
        return
    end

    if not enemyBuffer then
        enemyBuffer = console:createBuffer("Enemy")
    end

    local poke = readOpponent()
    if poke:checkFields() then
        return
    end
    
    local ev = poke.ev
    local iv = poke.iv
    local stat = poke.stat
    enemyBuffer:clear()
    local function send(str)
        str = str or ""
        enemyBuffer:print(str .. "\n")
    end
    send(string.format("%-13s @%s  %s", poke.species, poke.item, ABILITY[poke.ability]))
    send("\t\tIV\tEV\tStat")
    send("HP:\t\t" .. tostring(iv.hp) .. "\t" .. tostring(ev.hp) .. "\t" .. tostring(stat.curr_hp) .. "/" .. tostring(stat.tot_hp))
    send("Attack:\t\t" .. tostring(iv.atk) .. "\t" .. tostring(ev.atk) .. "\t" .. tostring(stat.atk))
    send("Defense:\t\t" .. tostring(iv.def) .. "\t" .. tostring(ev.def) .. "\t" .. tostring(stat.def))
    send("Sp. Attack:\t" .. tostring(iv.spa) .. "\t" .. tostring(ev.spa) .. "\t" .. tostring(stat.spa))
    send("Sp. Defense:\t" .. tostring(iv.spd) .. "\t" .. tostring(ev.spd) .. "\t" .. tostring(stat.spd))
    send("Speed:\t\t" .. tostring(iv.spe) .. "\t" .. tostring(ev.spe) .. "\t" .. tostring(stat.spe))
    send("Nature:\t" .. poke.nature)

    local shiny
    if poke:isShiny() then
        shiny = "*Yes!*"
    else
        shiny = "No"
    end
    send("Shiny:\t" .. shiny)

    local ev_yield_str = ""
    for ev, yield in pairs(poke.ev_yield) do
        if yield > 0 then
            ev_yield_str = ev_yield_str .. tostring(yield) .. " " .. ev .. "  "
        end
    end
    local exp_wild, exp_trainer = table.unpack(expCalc())
    ev_yield_str = ev_yield_str .. string.format("  %d/%dexp (wild/trainer)", exp_wild, exp_trainer)
    send("Yields:\t" .. ev_yield_str)
    send()

    scanDamage()
end

-- Scans and outputs damage calculations for current pokemon (I've updated it to add experience info as well)
---@param skip_frames? integer If passed, will only scan every *skip_frames* frames
function scanDamage(skip_frames)
    if (skip_frames ~= nil) and (emu:currentFrame() % skip_frames ~= 0) then
        return
    end

    if not enemyBuffer then
        enemyBuffer = console:createBuffer("Enemy")
    end
    local function send(str)
        str = str or ""
        enemyBuffer:print(str .. "\n")
    end

    local good = readFront()
    local bad = readOpponent()
    if (good:checkFields()) or (bad:checkFields()) then
        return
    end
    if (good.level > 0) and (good.level < 100) then
        local next_exp = EXP_GROUP[good.level + 1][good.exp_group]
        local exp_needed = next_exp - good.exp
        send(string.format("%s lvl.%d  (%d exp to next) %s", good.species, good.level, exp_needed, EXP_GROUP_NAME[good.exp_group]))
    else
        send(string.format("%s, lvl.%d", good.species, good.level))
    end
    send(string.format("%s  --->  %s (%d/%d hp)", good.species, bad.species, bad.stat.curr_hp, bad.stat.tot_hp))
    send(string.format("%-16sDeals (dmg in hp)", ""))
    for i = 1, 4 do
        local dmg_high = damageCalc(good, bad, good.moves[i])
        local dmg_low = dmg_high * 0.85
        send(string.format("%-18s%.1f - %.1f", MOVES[good.moves[i]], dmg_low, dmg_high))
        send()
    end
end




local skip = 30    -- skip every *skip* frames
if not PARTY_IND then
    print("No data found for memory location of current party pokemon in battle.")
end
if not OPP_IND then
    print("No data found for memory location of opponent party index (should be 2 after player party index).")
end
if not MOVE_LOC then
    print("No data found for memory location of move data structures.")
end
if not TRAINER_ID then
    print("No data found for memory location of trainer ID (needed for exp calc).")
end

callbacks:add("frame", function() scanParty(skip) end)
callbacks:add("frame", function() scanEnemy(skip) end)