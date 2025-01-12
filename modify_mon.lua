if not _DATA_RUN then
    local script_path = debug.getinfo(1, "S").source:sub(2)
    local script_dir = script_path:match("(.*/)")
    local data_path = script_dir .. "data.lua"
    dofile(data_path)
end

-- moves
-- my motivation for including this functionality was that I wanted
-- a Tyranitar with ancient power and dragon dance, but after completing
-- the Hoenn dex to get the totodile for ancient power I realized they
-- are not possible in the vanilla game. This function is my retaliation.
changeFrontMove(2, "ancientpower")      -- example
maxFrontPP()

-- IVs
maxFrontIVs()