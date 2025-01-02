local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*/)")
local data_path = script_dir .. "data.lua"
dofile(data_path)

local skip = 30    -- skip every *skip* frames
callbacks:add("frame", function() scanEnemy(skip) end)
callbacks:add("frame", function() scanParty(skip) end)