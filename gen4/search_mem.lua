if not _DATA_RUN then
    local script_dir = io.popen"cd":read'*l'
    local data_path = script_dir .. "\\data.lua"
    dofile(data_path)
end

local function searchRam(value, size, advance)
    assert(size == 1 or size == 2 or size == 4, "Search must be 1, 2, or 4 bytes long.")
    advance = advance or false

    if size == 4 then
        read = memory.read_u32_le
    elseif size == 2 then
        read = memory.read_u16_le
    else
        read = memory.readbyte
    end

    local matches = {}
    for i = 0x02000000, 0x03000000 - size, size do
        if advance and (i % 0x10000 == 0) then
            emu.frameadvance()
        end
        local check = read(i)
        if check == value then
            table.insert(matches, i)
        end
    end

    return matches
end

local function findOffsets(target, size, advance)
    console.clear()
    local matches = searchRam(target, size, advance)
    print(#matches .. " matches found")
    
    local base = read32(BASE_PTR)
    local good_offs = {}
    for key, value in pairs(matches) do
        local offset = value - base
        table.insert(good_offs, offset)
    end
    for key, value in pairs(good_offs) do
        print(string.format("0x%X", value))
    end

    return good_offs
end

local value = 3450285741
findOffsets(value, 4, true)