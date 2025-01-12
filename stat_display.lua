if not _DATA_RUN then
    local script_path = debug.getinfo(1, "S").source:sub(2)
    local script_dir = script_path:match("(.*/)")
    local data_path = script_dir .. "data.lua"
    dofile(data_path)
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