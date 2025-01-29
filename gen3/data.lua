-- https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_structure_(Generation_III)
-- https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_species_data_structure_(Generation_III)
-- https://bulbapedia.bulbagarden.net/wiki/Move_data_structure_(Generation_III)
-- pretty much all offsets and logic from link above and the pret decomps. god fuck what am i doing with my life

if _DATA_RUN then
    return
end
_DATA_RUN = true        -- my C header macro lol

function print(thing)
    if thing == nil then
        thing = ""
    end
    console:log(tostring(thing))
end
print("-----------------------")

local game = emu:getGameCode()
if game == "AGB-AXVE" then
    print("Ruby detected!")
    FRONT = 0x03004360          -- front of party
    WILD = 0x030045C0           -- wild pokemon, or if against a trainer, front of their party (https://github.com/pret/pokeemerald/blob/50d325f081a161f4a223d999497d7a65bd896194/src/pokemon.c#L75)
    PARTY_COUNT = 0x3004350     -- 1 byte, number of pokemon in party (looking at emerald decomp, should be 2 bytes before FRONT of party)
    SPECIES = 0x081FEC34 - 28   -- species data structure of pokemon 0 (https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_species_data_structure_(Generation_III))
    PARTY_IND = 0x02024A6A      -- tracks which pokemon in party is out in battle
    OPP_IND = 0x02024A6C        -- 1 byte, tracks which pokemon opposing trainer has out (0 if lead, 2 if third, etc.)
    MOVE_LOC = 0x081FB12C       -- location in memory of start of move data structures (https://bulbapedia.bulbagarden.net/wiki/Move_data_structure_(Generation_III))
elseif game == "AGB-AXPE" then
    print("Sapphire detected!")
    FRONT = 0x03004360
    WILD = 0x030045C0
    PARTY_COUNT = 0x3004350
    SPECIES = 	0x081FEBC4 - 28
    PARTY_IND = 0x02024A6A
    OPP_IND = PARTY_IND + 2
    MOVE_LOC = 0x081FB0BC
    TRAINER_ID = 0x02024EAE     -- Location in memory of 4-byte trainer id (low 16 is visible id, high 16 is secret)
elseif game == "AGB-BPEE" then
    print("Emerald detected!")
    FRONT = 0x020244EC
    WILD = 0x02024744
    PARTY_COUNT = 0x20244E9
    SPECIES = 0x083203E8 - 28
    PARTY_IND = 0x0202406E
    OPP_IND = PARTY_IND + 2
    MOVE_LOC = 0x0831C898
elseif game == "AGB-BPRE" then
    print("FireRed detected!")
    FRONT = 0x02024284
    WILD = 0x0202402C
    PARTY_COUNT = 0x02024029
    SPECIES = 0x082547A0 - 28
    PARTY_IND = 0x02023BCE
    OPP_IND = 0x02023BD0
    MOVE_LOC = 0x08250C04
    WEATHER = 0x02023F1C        -- 1 byte I think it's gBattleWeather, tracks most recent weather condition. Each weather type takes up 1 bit (https://github.com/pret/pokeemerald/blob/50d325f081a161f4a223d999497d7a65bd896194/include/constants/battle.h#L226)
elseif game == "AGB-BPGE" then
    print("LeafGreen detected!")
    FRONT = 0x02024284
    WILD = 0x0202402C
    PARTY_COUNT = 0x2024029
    SPECIES = 0x0825477C - 28
    MOVE_LOC = 0x08250BE0
else
    print("Couldn't recognize game code:\t" .. game)
    os.exit(1)
end

-- https://github.com/pret/pokeemerald/blob/50d325f081a161f4a223d999497d7a65bd896194/include/constants/battle.h#L218
WEATHER_RAIN_TEMPORARY      = (1 << 0)
WEATHER_RAIN_DOWNPOUR       = (1 << 1)  -- unused
WEATHER_RAIN_PERMANENT      = (1 << 2)
WEATHER_RAIN                = (WEATHER_RAIN_TEMPORARY | WEATHER_RAIN_DOWNPOUR | WEATHER_RAIN_PERMANENT)
WEATHER_SANDSTORM_TEMPORARY = (1 << 3)
WEATHER_SANDSTORM_PERMANENT = (1 << 4)
WEATHER_SANDSTORM           = (WEATHER_SANDSTORM_TEMPORARY | WEATHER_SANDSTORM_PERMANENT)
WEATHER_SUN_TEMPORARY       = (1 << 5)
WEATHER_SUN_PERMANENT       = (1 << 6)
WEATHER_SUN                 = (WEATHER_SUN_TEMPORARY | WEATHER_SUN_PERMANENT)
WEATHER_HAIL_TEMPORARY      = (1 << 7)
WEATHER_HAIL                = (WEATHER_HAIL_TEMPORARY)
WEATHER_ANY                 = (WEATHER_RAIN | WEATHER_SANDSTORM | WEATHER_SUN | WEATHER_HAIL)

-- gotta love modular/permutation groups
local CHUNK_MAP = {
    [0] = {0, 1, 2, 3},
    [1] = {0, 1, 3, 2},
    [2] = {0, 2, 1, 3},
    [3] = {0, 3, 1, 2},
    [4] = {0, 2, 3, 1},
    [5] = {0, 3, 2, 1},
    [6] = {1, 0, 2, 3},
    [7] = {1, 0, 3, 2},
    [8] = {2, 0, 1, 3},
    [9] = {3, 0, 1, 2},
    [10] = {2, 0, 3, 1},
    [11] = {3, 0, 2, 1},
    [12] = {1, 2, 0, 3},
    [13] = {1, 3, 0, 2},
    [14] = {2, 1, 0, 3},
    [15] = {3, 1, 0, 2},
    [16] = {2, 3, 0, 1},
    [17] = {3, 2, 0, 1},
    [18] = {1, 2, 3, 0},
    [19] = {1, 3, 2, 0},
    [20] = {2, 1, 3, 0},
    [21] = {3, 1, 2, 0},
    [22] = {2, 3, 1, 0},
    [23] = {3, 2, 1, 0}
}

-- https://bulbapedia.bulbagarden.net/wiki/Nature#List_of_Natures
NATURE = {
    [0] = "Hardy",
    [1] = "Lonely",
    [2] = "Brave",
    [3] = "Adamant",
    [4] = "Naughty",
    [5] = "Bold",
    [6] = "Docile",
    [7] = "Relaxed",
    [8] = "Impish",
    [9] = "Lax",
    [10] = "Timid",
    [11] = "Hasty",
    [12] = "Serious",
    [13] = "Jolly",
    [14] = "Naive",
    [15] = "Modest",
    [16] = "Mild",
    [17] = "Quiet",
    [18] = "Bashful",
    [19] = "Rash",
    [20] = "Calm",
    [21] = "Gentle",
    [22] = "Sassy",
    [23] = "Careful",
    [24] = "Quirky"
}

-- https://bulbapedia.bulbagarden.net/wiki/List_of_items_by_index_number_in_Generation_III#List
ITEM = {
    [000] = "Nothing",
    [001] = "Master Ball",
    [002] = "Ultra Ball",
    [003] = "Great Ball",
    [004] = "Poké Ball",
    [005] = "Safari Ball",
    [006] = "Net Ball",
    [007] = "Dive Ball",
    [008] = "Nest Ball",
    [009] = "Repeat Ball",
    [010] = "Timer Ball",
    [011] = "Luxury Ball",
    [012] = "Premier Ball",
    [013] = "Potion",
    [014] = "Antidote",
    [015] = "Burn Heal",
    [016] = "Ice Heal",
    [017] = "Awakening",
    [018] = "Parlyz Heal",
    [019] = "Full Restore",
    [020] = "Max Potion",
    [021] = "Hyper Potion",
    [022] = "Super Potion",
    [023] = "Full Heal",
    [024] = "Revive",
    [025] = "Max Revive",
    [026] = "Fresh Water",
    [027] = "Soda Pop",
    [028] = "Lemonade",
    [029] = "Moomoo Milk",
    [030] = "EnergyPowder",
    [031] = "Energy Root",
    [032] = "Heal Powder",
    [033] = "Revival Herb",
    [034] = "Ether",
    [035] = "Max Ether",
    [036] = "Elixir",
    [037] = "Max Elixir",
    [038] = "Lava Cookie",
    [039] = "Blue Flute",
    [040] = "Yellow Flute",
    [041] = "Red Flute",
    [042] = "Black Flute",
    [043] = "White Flute",
    [044] = "Berry Juice",
    [045] = "Sacred Ash",
    [046] = "Shoal Salt",
    [047] = "Shoal Shell",
    [048] = "Red Shard",
    [049] = "Blue Shard",
    [050] = "Yellow Shard",
    [051] = "Green Shard",
    [052] = "unknown",
    [053] = "unknown",
    [054] = "unknown",
    [055] = "unknown",
    [056] = "unknown",
    [057] = "unknown",
    [058] = "unknown",
    [059] = "unknown",
    [060] = "unknown",
    [061] = "unknown",
    [062] = "unknown",
    [063] = "HP Up",
    [064] = "Protein",
    [065] = "Iron",
    [066] = "Carbos",
    [067] = "Calcium",
    [068] = "Rare Candy",
    [069] = "PP Up",
    [070] = "Zinc",
    [071] = "PP Max",
    [072] = "unknown",
    [073] = "Guard Spec.",
    [074] = "Dire Hit",
    [075] = "X Attack",
    [076] = "X Defend",
    [077] = "X Speed",
    [078] = "X Accuracy",
    [079] = "X Special",
    [080] = "Poké Doll",
    [081] = "Fluffy Tail",
    [082] = "unknown",
    [083] = "Super Repel",
    [084] = "Max Repel",
    [085] = "Escape Rope",
    [086] = "Repel",
    [087] = "unknown",
    [088] = "unknown",
    [089] = "unknown",
    [090] = "unknown",
    [091] = "unknown",
    [092] = "unknown",
    [093] = "Sun Stone",
    [094] = "Moon Stone",
    [095] = "Fire Stone",
    [096] = "Thunderstone",
    [097] = "Water Stone",
    [098] = "Leaf Stone",
    [099] = "unknown",
    [100] = "unknown",
    [101] = "unknown",
    [102] = "unknown",
    [103] = "TinyMushroom",
    [104] = "Big Mushroom",
    [105] = "unknown",
    [106] = "Pearl",
    [107] = "Big Pearl",
    [108] = "Stardust",
    [109] = "Star Piece",
    [110] = "Nugget",
    [111] = "Heart Scale",
    [112] = "unknown",
    [113] = "unknown",
    [114] = "unknown",
    [115] = "unknown",
    [116] = "unknown",
    [117] = "unknown",
    [118] = "unknown",
    [119] = "unknown",
    [120] = "unknown",
    [121] = "Orange Mail",
    [122] = "Harbor Mail",
    [123] = "Glitter Mail",
    [124] = "Mech Mail",
    [125] = "Wood Mail",
    [126] = "Wave Mail",
    [127] = "Bead Mail",
    [128] = "Shadow Mail",
    [129] = "Tropic Mail",
    [130] = "Dream Mail",
    [131] = "Fab Mail",
    [132] = "Retro Mail",
    [133] = "Cheri Berry",
    [134] = "Chesto Berry",
    [135] = "Pecha Berry",
    [136] = "Rawst Berry",
    [137] = "Aspear Berry",
    [138] = "Leppa Berry",
    [139] = "Oran Berry",
    [140] = "Persim Berry",
    [141] = "Lum Berry",
    [142] = "Sitrus Berry",
    [143] = "Figy Berry",
    [144] = "Wiki Berry",
    [145] = "Mago Berry",
    [146] = "Aguav Berry",
    [147] = "Iapapa Berry",
    [148] = "Razz Berry",
    [149] = "Bluk Berry",
    [150] = "Nanab Berry",
    [151] = "Wepear Berry",
    [152] = "Pinap Berry",
    [153] = "Pomeg Berry",
    [154] = "Kelpsy Berry",
    [155] = "Qualot Berry",
    [156] = "Hondew Berry",
    [157] = "Grepa Berry",
    [158] = "Tamato Berry",
    [159] = "Cornn Berry",
    [160] = "Magost Berry",
    [161] = "Rabuta Berry",
    [162] = "Nomel Berry",
    [163] = "Spelon Berry",
    [164] = "Pamtre Berry",
    [165] = "Watmel Berry",
    [166] = "Durin Berry",
    [167] = "Belue Berry",
    [168] = "Liechi Berry",
    [169] = "Ganlon Berry",
    [170] = "Salac Berry",
    [171] = "Petaya Berry",
    [172] = "Apicot Berry",
    [173] = "Lansat Berry",
    [174] = "Starf Berry",
    [175] = "Enigma Berry",
    [176] = "unknown",
    [177] = "unknown",
    [178] = "unknown",
    [179] = "BrightPowder",
    [180] = "White Herb",
    [181] = "Macho Brace",
    [182] = "Exp. Share",
    [183] = "Quick Claw",
    [184] = "Soothe Bell",
    [185] = "Mental Herb",
    [186] = "Choice Band",
    [187] = "King's Rock",
    [188] = "SilverPowder",
    [189] = "Amulet Coin",
    [190] = "Cleanse Tag",
    [191] = "Soul Dew",
    [192] = "DeepSeaTooth",
    [193] = "DeepSeaScale",
    [194] = "Smoke Ball",
    [195] = "Everstone",
    [196] = "Focus Band",
    [197] = "Lucky Egg",
    [198] = "Scope Lens",
    [199] = "Metal Coat",
    [200] = "Leftovers",
    [201] = "Dragon Scale",
    [202] = "Light Ball",
    [203] = "Soft Sand",
    [204] = "Hard Stone",
    [205] = "Miracle Seed",
    [206] = "BlackGlasses",
    [207] = "Black Belt",
    [208] = "Magnet",
    [209] = "Mystic Water",
    [210] = "Sharp Beak",
    [211] = "Poison Barb",
    [212] = "NeverMeltIce",
    [213] = "Spell Tag",
    [214] = "TwistedSpoon",
    [215] = "Charcoal",
    [216] = "Dragon Fang",
    [217] = "Silk Scarf",
    [218] = "Up-Grade",
    [219] = "Shell Bell",
    [220] = "Sea Incense",
    [221] = "Lax Incense",
    [222] = "Lucky Punch",
    [223] = "Metal Powder",
    [224] = "Thick Club",
    [225] = "Stick",
    [226] = "unknown",
    [227] = "unknown",
    [228] = "unknown",
    [229] = "unknown",
    [230] = "unknown",
    [231] = "unknown",
    [232] = "unknown",
    [233] = "unknown",
    [234] = "unknown",
    [235] = "unknown",
    [236] = "unknown",
    [237] = "unknown",
    [238] = "unknown",
    [239] = "unknown",
    [240] = "unknown",
    [241] = "unknown",
    [242] = "unknown",
    [243] = "unknown",
    [244] = "unknown",
    [245] = "unknown",
    [246] = "unknown",
    [247] = "unknown",
    [248] = "unknown",
    [249] = "unknown",
    [250] = "unknown",
    [251] = "unknown",
    [252] = "unknown",
    [253] = "unknown",
    [254] = "Red Scarf",
    [255] = "Blue Scarf",
    [256] = "Pink Scarf",
    [257] = "Green Scarf",
    [258] = "Yellow Scarf",
    [259] = "Mach Bike",
    [260] = "Coin Case",
    [261] = "Itemfinder",
    [262] = "Old Rod",
    [263] = "Good Rod",
    [264] = "Super Rod",
    [265] = "S.S. Ticket",
    [266] = "Contest Pass",
    [267] = "unknown",
    [268] = "Wailmer Pail",
    [269] = "Devon Goods",
    [270] = "Soot Sack",
    [271] = "Basement Key",
    [272] = "Acro Bike",
    [273] = "Pokéblock Case",
    [274] = "Letter",
    [275] = "Eon Ticket",
    [276] = "Red Orb",
    [277] = "Blue Orb",
    [278] = "Scanner",
    [279] = "Go-Goggles",
    [280] = "Meteorite",
    [281] = "Rm. 1 Key",
    [282] = "Rm. 2 Key",
    [283] = "Rm. 4 Key",
    [284] = "Rm. 6 Key",
    [285] = "Storage Key",
    [286] = "Root Fossil",
    [287] = "Claw Fossil",
    [288] = "Devon Scope",
    [289] = "TM01",
    [290] = "TM02",
    [291] = "TM03",
    [292] = "TM04",
    [293] = "TM05",
    [294] = "TM06",
    [295] = "TM07",
    [296] = "TM08",
    [297] = "TM09",
    [298] = "TM10",
    [299] = "TM11",
    [300] = "TM12",
    [301] = "TM13",
    [302] = "TM14",
    [303] = "TM15",
    [304] = "TM16",
    [305] = "TM17",
    [306] = "TM18",
    [307] = "TM19",
    [308] = "TM20",
    [309] = "TM21",
    [310] = "TM22",
    [311] = "TM23",
    [312] = "TM24",
    [313] = "TM25",
    [314] = "TM26",
    [315] = "TM27",
    [316] = "TM28",
    [317] = "TM29",
    [318] = "TM30",
    [319] = "TM31",
    [320] = "TM32",
    [321] = "TM33",
    [322] = "TM34",
    [323] = "TM35",
    [324] = "TM36",
    [325] = "TM37",
    [326] = "TM38",
    [327] = "TM39",
    [328] = "TM40",
    [329] = "TM41",
    [330] = "TM42",
    [331] = "TM43",
    [332] = "TM44",
    [333] = "TM45",
    [334] = "TM46",
    [335] = "TM47",
    [336] = "TM48",
    [337] = "TM49",
    [338] = "TM50",
    [339] = "HM01",
    [340] = "HM02",
    [341] = "HM03",
    [342] = "HM04",
    [343] = "HM05",
    [344] = "HM06",
    [345] = "HM07",
    [346] = "HM08",
    [347] = "unknown",
    [348] = "unknown",
    [349] = "Oak's Parcel*",
    [350] = "Poké Flute*",
    [351] = "Secret Key*",
    [352] = "Bike Voucher*",
    [353] = "Gold Teeth*",
    [354] = "Old Amber*",
    [355] = "Card Key*",
    [356] = "Lift Key*",
    [357] = "Helix Fossil*",
    [358] = "Dome Fossil*",
    [359] = "Silph Scope*",
    [360] = "Bicycle*",
    [361] = "Town Map*",
    [362] = "VS Seeker*",
    [363] = "Fame Checker*",
    [364] = "TM Case*",
    [365] = "Berry Pouch*",
    [366] = "Teachy TV*",
    [367] = "Tri-Pass*",
    [368] = "Rainbow Pass*",
    [369] = "Tea*",
    [370] = "MysticTicket*",
    [371] = "AuroraTicket*",
    [372] = "Powder Jar*",
    [373] = "Ruby*",
    [374] = "Sapphire*",
    [375] = "Magma Emblem*",
    [376] = "Old Sea Map*",
}

-- https://bulbapedia.bulbagarden.net/wiki/List_of_Pok%C3%A9mon_by_index_number_in_Generation_III#List_of_Pok%C3%A9mon_by_index_number
POKEDEX = {
    [000] = "??????????",
    [001] = "Bulbasaur",
    [002] = "Ivysaur",
    [003] = "Venusaur",
    [004] = "Charmander",
    [005] = "Charmeleon",
    [006] = "Charizard",
    [007] = "Squirtle",
    [008] = "Wartortle",
    [009] = "Blastoise",
    [010] = "Caterpie",
    [011] = "Metapod",
    [012] = "Butterfree",
    [013] = "Weedle",
    [014] = "Kakuna",
    [015] = "Beedrill",
    [016] = "Pidgey",
    [017] = "Pidgeotto",
    [018] = "Pidgeot",
    [019] = "Rattata",
    [020] = "Raticate",
    [021] = "Spearow",
    [022] = "Fearow",
    [023] = "Ekans",
    [024] = "Arbok",
    [025] = "Pikachu",
    [026] = "Raichu",
    [027] = "Sandshrew",
    [028] = "Sandslash",
    [029] = "Nidoran♀",
    [030] = "Nidorina",
    [031] = "Nidoqueen",
    [032] = "Nidoran♂",
    [033] = "Nidorino",
    [034] = "Nidoking",
    [035] = "Clefairy",
    [036] = "Clefable",
    [037] = "Vulpix",
    [038] = "Ninetales",
    [039] = "Jigglypuff",
    [040] = "Wigglytuff",
    [041] = "Zubat",
    [042] = "Golbat",
    [043] = "Oddish",
    [044] = "Gloom",
    [045] = "Vileplume",
    [046] = "Paras",
    [047] = "Parasect",
    [048] = "Venonat",
    [049] = "Venomoth",
    [050] = "Diglett",
    [051] = "Dugtrio",
    [052] = "Meowth",
    [053] = "Persian",
    [054] = "Psyduck",
    [055] = "Golduck",
    [056] = "Mankey",
    [057] = "Primeape",
    [058] = "Growlithe",
    [059] = "Arcanine",
    [060] = "Poliwag",
    [061] = "Poliwhirl",
    [062] = "Poliwrath",
    [063] = "Abra",
    [064] = "Kadabra",
    [065] = "Alakazam",
    [066] = "Machop",
    [067] = "Machoke",
    [068] = "Machamp",
    [069] = "Bellsprout",
    [070] = "Weepinbell",
    [071] = "Victreebel",
    [072] = "Tentacool",
    [073] = "Tentacruel",
    [074] = "Geodude",
    [075] = "Graveler",
    [076] = "Golem",
    [077] = "Ponyta",
    [078] = "Rapidash",
    [079] = "Slowpoke",
    [080] = "Slowbro",
    [081] = "Magnemite",
    [082] = "Magneton",
    [083] = "Farfetch'd",
    [084] = "Doduo",
    [085] = "Dodrio",
    [086] = "Seel",
    [087] = "Dewgong",
    [088] = "Grimer",
    [089] = "Muk",
    [090] = "Shellder",
    [091] = "Cloyster",
    [092] = "Gastly",
    [093] = "Haunter",
    [094] = "Gengar",
    [095] = "Onix",
    [096] = "Drowzee",
    [097] = "Hypno",
    [098] = "Krabby",
    [099] = "Kingler",
    [100] = "Voltorb",
    [101] = "Electrode",
    [102] = "Exeggcute",
    [103] = "Exeggutor",
    [104] = "Cubone",
    [105] = "Marowak",
    [106] = "Hitmonlee",
    [107] = "Hitmonchan",
    [108] = "Lickitung",
    [109] = "Koffing",
    [110] = "Weezing",
    [111] = "Rhyhorn",
    [112] = "Rhydon",
    [113] = "Chansey",
    [114] = "Tangela",
    [115] = "Kangaskhan",
    [116] = "Horsea",
    [117] = "Seadra",
    [118] = "Goldeen",
    [119] = "Seaking",
    [120] = "Staryu",
    [121] = "Starmie",
    [122] = "Mr. Mime",
    [123] = "Scyther",
    [124] = "Jynx",
    [125] = "Electabuzz",
    [126] = "Magmar",
    [127] = "Pinsir",
    [128] = "Tauros",
    [129] = "Magikarp",
    [130] = "Gyarados",
    [131] = "Lapras",
    [132] = "Ditto",
    [133] = "Eevee",
    [134] = "Vaporeon",
    [135] = "Jolteon",
    [136] = "Flareon",
    [137] = "Porygon",
    [138] = "Omanyte",
    [139] = "Omastar",
    [140] = "Kabuto",
    [141] = "Kabutops",
    [142] = "Aerodactyl",
    [143] = "Snorlax",
    [144] = "Articuno",
    [145] = "Zapdos",
    [146] = "Moltres",
    [147] = "Dratini",
    [148] = "Dragonair",
    [149] = "Dragonite",
    [150] = "Mewtwo",
    [151] = "Mew",
    [152] = "Chikorita",
    [153] = "Bayleef",
    [154] = "Meganium",
    [155] = "Cyndaquil",
    [156] = "Quilava",
    [157] = "Typhlosion",
    [158] = "Totodile",
    [159] = "Croconaw",
    [160] = "Feraligatr",
    [161] = "Sentret",
    [162] = "Furret",
    [163] = "Hoothoot",
    [164] = "Noctowl",
    [165] = "Ledyba",
    [166] = "Ledian",
    [167] = "Spinarak",
    [168] = "Ariados",
    [169] = "Crobat",
    [170] = "Chinchou",
    [171] = "Lanturn",
    [172] = "Pichu",
    [173] = "Cleffa",
    [174] = "Igglybuff",
    [175] = "Togepi",
    [176] = "Togetic",
    [177] = "Natu",
    [178] = "Xatu",
    [179] = "Mareep",
    [180] = "Flaaffy",
    [181] = "Ampharos",
    [182] = "Bellossom",
    [183] = "Marill",
    [184] = "Azumarill",
    [185] = "Sudowoodo",
    [186] = "Politoed",
    [187] = "Hoppip",
    [188] = "Skiploom",
    [189] = "Jumpluff",
    [190] = "Aipom",
    [191] = "Sunkern",
    [192] = "Sunflora",
    [193] = "Yanma",
    [194] = "Wooper",
    [195] = "Quagsire",
    [196] = "Espeon",
    [197] = "Umbreon",
    [198] = "Murkrow",
    [199] = "Slowking",
    [200] = "Misdreavus",
    [201] = "Unown",
    [202] = "Wobbuffet",
    [203] = "Girafarig",
    [204] = "Pineco",
    [205] = "Forretress",
    [206] = "Dunsparce",
    [207] = "Gligar",
    [208] = "Steelix",
    [209] = "Snubbull",
    [210] = "Granbull",
    [211] = "Qwilfish",
    [212] = "Scizor",
    [213] = "Shuckle",
    [214] = "Heracross",
    [215] = "Sneasel",
    [216] = "Teddiursa",
    [217] = "Ursaring",
    [218] = "Slugma",
    [219] = "Magcargo",
    [220] = "Swinub",
    [221] = "Piloswine",
    [222] = "Corsola",
    [223] = "Remoraid",
    [224] = "Octillery",
    [225] = "Delibird",
    [226] = "Mantine",
    [227] = "Skarmory",
    [228] = "Houndour",
    [229] = "Houndoom",
    [230] = "Kingdra",
    [231] = "Phanpy",
    [232] = "Donphan",
    [233] = "Porygon2",
    [234] = "Stantler",
    [235] = "Smeargle",
    [236] = "Tyrogue",
    [237] = "Hitmontop",
    [238] = "Smoochum",
    [239] = "Elekid",
    [240] = "Magby",
    [241] = "Miltank",
    [242] = "Blissey",
    [243] = "Raikou",
    [244] = "Entei",
    [245] = "Suicune",
    [246] = "Larvitar",
    [247] = "Pupitar",
    [248] = "Tyranitar",
    [249] = "Lugia",
    [250] = "Ho-Oh",
    [251] = "Celebi",
    [252] = "?",
    [253] = "?",
    [254] = "?",
    [255] = "?",
    [256] = "?",
    [257] = "?",
    [258] = "?",
    [259] = "?",
    [260] = "?",
    [261] = "?",
    [262] = "?",
    [263] = "?",
    [264] = "?",
    [265] = "?",
    [266] = "?",
    [267] = "?",
    [268] = "?",
    [269] = "?",
    [270] = "?",
    [271] = "?",
    [272] = "?",
    [273] = "?",
    [274] = "?",
    [275] = "?",
    [276] = "?",
    [277] = "Treecko",
    [278] = "Grovyle",
    [279] = "Sceptile",
    [280] = "Torchic",
    [281] = "Combusken",
    [282] = "Blaziken",
    [283] = "Mudkip",
    [284] = "Marshtomp",
    [285] = "Swampert",
    [286] = "Poochyena",
    [287] = "Mightyena",
    [288] = "Zigzagoon",
    [289] = "Linoone",
    [290] = "Wurmple",
    [291] = "Silcoon",
    [292] = "Beautifly",
    [293] = "Cascoon",
    [294] = "Dustox",
    [295] = "Lotad",
    [296] = "Lombre",
    [297] = "Ludicolo",
    [298] = "Seedot",
    [299] = "Nuzleaf",
    [300] = "Shiftry",
    [301] = "Nincada",
    [302] = "Ninjask",
    [303] = "Shedinja",
    [304] = "Taillow",
    [305] = "Swellow",
    [306] = "Shroomish",
    [307] = "Breloom",
    [308] = "Spinda",
    [309] = "Wingull",
    [310] = "Pelipper",
    [311] = "Surskit",
    [312] = "Masquerain",
    [313] = "Wailmer",
    [314] = "Wailord",
    [315] = "Skitty",
    [316] = "Delcatty",
    [317] = "Kecleon",
    [318] = "Baltoy",
    [319] = "Claydol",
    [320] = "Nosepass",
    [321] = "Torkoal",
    [322] = "Sableye",
    [323] = "Barboach",
    [324] = "Whiscash",
    [325] = "Luvdisc",
    [326] = "Corphish",
    [327] = "Crawdaunt",
    [328] = "Feebas",
    [329] = "Milotic",
    [330] = "Carvanha",
    [331] = "Sharpedo",
    [332] = "Trapinch",
    [333] = "Vibrava",
    [334] = "Flygon",
    [335] = "Makuhita",
    [336] = "Hariyama",
    [337] = "Electrike",
    [338] = "Manectric",
    [339] = "Numel",
    [340] = "Camerupt",
    [341] = "Spheal",
    [342] = "Sealeo",
    [343] = "Walrein",
    [344] = "Cacnea",
    [345] = "Cacturne",
    [346] = "Snorunt",
    [347] = "Glalie",
    [348] = "Lunatone",
    [349] = "Solrock",
    [350] = "Azurill",
    [351] = "Spoink",
    [352] = "Grumpig",
    [353] = "Plusle",
    [354] = "Minun",
    [355] = "Mawile",
    [356] = "Meditite",
    [357] = "Medicham",
    [358] = "Swablu",
    [359] = "Altaria",
    [360] = "Wynaut",
    [361] = "Duskull",
    [362] = "Dusclops",
    [363] = "Roselia",
    [364] = "Slakoth",
    [365] = "Vigoroth",
    [366] = "Slaking",
    [367] = "Gulpin",
    [368] = "Swalot",
    [369] = "Tropius",
    [370] = "Whismur",
    [371] = "Loudred",
    [372] = "Exploud",
    [373] = "Clamperl",
    [374] = "Huntail",
    [375] = "Gorebyss",
    [376] = "Absol",
    [377] = "Shuppet",
    [378] = "Banette",
    [379] = "Seviper",
    [380] = "Zangoose",
    [381] = "Relicanth",
    [382] = "Aron",
    [383] = "Lairon",
    [384] = "Aggron",
    [385] = "Castform",
    [386] = "Volbeat",
    [387] = "Illumise",
    [388] = "Lileep",
    [389] = "Cradily",
    [390] = "Anorith",
    [391] = "Armaldo",
    [392] = "Ralts",
    [393] = "Kirlia",
    [394] = "Gardevoir",
    [395] = "Bagon",
    [396] = "Shelgon",
    [397] = "Salamence",
    [398] = "Beldum",
    [399] = "Metang",
    [400] = "Metagross",
    [401] = "Regirock",
    [402] = "Regice",
    [403] = "Registeel",
    [404] = "Kyogre",
    [405] = "Groudon",
    [406] = "Rayquaza",
    [407] = "Latias",
    [408] = "Latios",
    [409] = "Jirachi",
    [410] = "Deoxys",
    [411] = "Chimecho",
    [412] = "Pokémon Egg",
    [413] = "Unown",
    [414] = "Unown",
    [415] = "Unown",
    [416] = "Unown",
    [417] = "Unown",
    [418] = "Unown",
    [419] = "Unown",
    [420] = "Unown",
    [421] = "Unown",
    [422] = "Unown",
    [423] = "Unown",
    [424] = "Unown",
    [425] = "Unown",
    [426] = "Unown",
    [427] = "Unown",
    [428] = "Unown",
    [429] = "Unown",
    [430] = "Unown",
    [431] = "Unown",
    [432] = "Unown",
    [433] = "Unown",
    [434] = "Unown",
    [435] = "Unown",
    [436] = "Unown",
    [437] = "Unown",
    [438] = "Unown",
    [439] = "Unown",
}

-- https://bulbapedia.bulbagarden.net/wiki/List_of_moves
MOVES = {
    [0] = "?????",
    [1] = "Pound",
    [2] = "Karate Chop",
    [3] = "Double Slap",
    [4] = "Comet Punch",
    [5] = "Mega Punch",
    [6] = "Pay Day",
    [7] = "Fire Punch",
    [8] = "Ice Punch",
    [9] = "Thunder Punch",
    [10] = "Scratch",
    [11] = "Vise Grip",
    [12] = "Guillotine",
    [13] = "Razor Wind",
    [14] = "Swords Dance",
    [15] = "Cut",
    [16] = "Gust",
    [17] = "Wing Attack",
    [18] = "Whirlwind",
    [19] = "Fly",
    [20] = "Bind",
    [21] = "Slam",
    [22] = "Vine Whip",
    [23] = "Stomp",
    [24] = "Double Kick",
    [25] = "Mega Kick",
    [26] = "Jump Kick",
    [27] = "Rolling Kick",
    [28] = "Sand Attack",
    [29] = "Headbutt",
    [30] = "Horn Attack",
    [31] = "Fury Attack",
    [32] = "Horn Drill",
    [33] = "Tackle",
    [34] = "Body Slam",
    [35] = "Wrap",
    [36] = "Take Down",
    [37] = "Thrash",
    [38] = "Double-Edge",
    [39] = "Tail Whip",
    [40] = "Poison Sting",
    [41] = "Twineedle",
    [42] = "Pin Missile",
    [43] = "Leer",
    [44] = "Bite",
    [45] = "Growl",
    [46] = "Roar",
    [47] = "Sing",
    [48] = "Supersonic",
    [49] = "Sonic Boom",
    [50] = "Disable",
    [51] = "Acid",
    [52] = "Ember",
    [53] = "Flamethrower",
    [54] = "Mist",
    [55] = "Water Gun",
    [56] = "Hydro Pump",
    [57] = "Surf",
    [58] = "Ice Beam",
    [59] = "Blizzard",
    [60] = "Psybeam",
    [61] = "Bubble Beam",
    [62] = "Aurora Beam",
    [63] = "Hyper Beam",
    [64] = "Peck",
    [65] = "Drill Peck",
    [66] = "Submission",
    [67] = "Low Kick",
    [68] = "Counter",
    [69] = "Seismic Toss",
    [70] = "Strength",
    [71] = "Absorb",
    [72] = "Mega Drain",
    [73] = "Leech Seed",
    [74] = "Growth",
    [75] = "Razor Leaf",
    [76] = "Solar Beam",
    [77] = "Poison Powder",
    [78] = "Stun Spore",
    [79] = "Sleep Powder",
    [80] = "Petal Dance",
    [81] = "String Shot",
    [82] = "Dragon Rage",
    [83] = "Fire Spin",
    [84] = "Thunder Shock",
    [85] = "Thunderbolt",
    [86] = "Thunder Wave",
    [87] = "Thunder",
    [88] = "Rock Throw",
    [89] = "Earthquake",
    [90] = "Fissure",
    [91] = "Dig",
    [92] = "Toxic",
    [93] = "Confusion",
    [94] = "Psychic",
    [95] = "Hypnosis",
    [96] = "Meditate",
    [97] = "Agility",
    [98] = "Quick Attack",
    [99] = "Rage",
    [100] = "Teleport",
    [101] = "Night Shade",
    [102] = "Mimic",
    [103] = "Screech",
    [104] = "Double Team",
    [105] = "Recover",
    [106] = "Harden",
    [107] = "Minimize",
    [108] = "Smokescreen",
    [109] = "Confuse Ray",
    [110] = "Withdraw",
    [111] = "Defense Curl",
    [112] = "Barrier",
    [113] = "Light Screen",
    [114] = "Haze",
    [115] = "Reflect",
    [116] = "Focus Energy",
    [117] = "Bide",
    [118] = "Metronome",
    [119] = "Mirror Move",
    [120] = "Self-Destruct",
    [121] = "Egg Bomb",
    [122] = "Lick",
    [123] = "Smog",
    [124] = "Sludge",
    [125] = "Bone Club",
    [126] = "Fire Blast",
    [127] = "Waterfall",
    [128] = "Clamp",
    [129] = "Swift",
    [130] = "Skull Bash",
    [131] = "Spike Cannon",
    [132] = "Constrict",
    [133] = "Amnesia",
    [134] = "Kinesis",
    [135] = "Soft-Boiled",
    [136] = "High Jump Kick",
    [137] = "Glare",
    [138] = "Dream Eater",
    [139] = "Poison Gas",
    [140] = "Barrage",
    [141] = "Leech Life",
    [142] = "Lovely Kiss",
    [143] = "Sky Attack",
    [144] = "Transform",
    [145] = "Bubble",
    [146] = "Dizzy Punch",
    [147] = "Spore",
    [148] = "Flash",
    [149] = "Psywave",
    [150] = "Splash",
    [151] = "Acid Armor",
    [152] = "Crabhammer",
    [153] = "Explosion",
    [154] = "Fury Swipes",
    [155] = "Bonemerang",
    [156] = "Rest",
    [157] = "Rock Slide",
    [158] = "Hyper Fang",
    [159] = "Sharpen",
    [160] = "Conversion",
    [161] = "Tri Attack",
    [162] = "Super Fang",
    [163] = "Slash",
    [164] = "Substitute",
    [165] = "Struggle",
    [166] = "Sketch",
    [167] = "Triple Kick",
    [168] = "Thief",
    [169] = "Spider Web",
    [170] = "Mind Reader",
    [171] = "Nightmare",
    [172] = "Flame Wheel",
    [173] = "Snore",
    [174] = "Curse",
    [175] = "Flail",
    [176] = "Conversion 2",
    [177] = "Aeroblast",
    [178] = "Cotton Spore",
    [179] = "Reversal",
    [180] = "Spite",
    [181] = "Powder Snow",
    [182] = "Protect",
    [183] = "Mach Punch",
    [184] = "Scary Face",
    [185] = "Feint Attack",
    [186] = "Sweet Kiss",
    [187] = "Belly Drum",
    [188] = "Sludge Bomb",
    [189] = "Mud-Slap",
    [190] = "Octazooka",
    [191] = "Spikes",
    [192] = "Zap Cannon",
    [193] = "Foresight",
    [194] = "Destiny Bond",
    [195] = "Perish Song",
    [196] = "Icy Wind",
    [197] = "Detect",
    [198] = "Bone Rush",
    [199] = "Lock-On",
    [200] = "Outrage",
    [201] = "Sandstorm",
    [202] = "Giga Drain",
    [203] = "Endure",
    [204] = "Charm",
    [205] = "Rollout",
    [206] = "False Swipe",
    [207] = "Swagger",
    [208] = "Milk Drink",
    [209] = "Spark",
    [210] = "Fury Cutter",
    [211] = "Steel Wing",
    [212] = "Mean Look",
    [213] = "Attract",
    [214] = "Sleep Talk",
    [215] = "Heal Bell",
    [216] = "Return",
    [217] = "Present",
    [218] = "Frustration",
    [219] = "Safeguard",
    [220] = "Pain Split",
    [221] = "Sacred Fire",
    [222] = "Magnitude",
    [223] = "Dynamic Punch",
    [224] = "Megahorn",
    [225] = "Dragon Breath",
    [226] = "Baton Pass",
    [227] = "Encore",
    [228] = "Pursuit",
    [229] = "Rapid Spin",
    [230] = "Sweet Scent",
    [231] = "Iron Tail",
    [232] = "Metal Claw",
    [233] = "Vital Throw",
    [234] = "Morning Sun",
    [235] = "Synthesis",
    [236] = "Moonlight",
    [237] = "Hidden Power",
    [238] = "Cross Chop",
    [239] = "Twister",
    [240] = "Rain Dance",
    [241] = "Sunny Day",
    [242] = "Crunch",
    [243] = "Mirror Coat",
    [244] = "Psych Up",
    [245] = "Extreme Speed",
    [246] = "Ancient Power",
    [247] = "Shadow Ball",
    [248] = "Future Sight",
    [249] = "Rock Smash",
    [250] = "Whirlpool",
    [251] = "Beat Up",
    [252] = "Fake Out",
    [253] = "Uproar",
    [254] = "Stockpile",
    [255] = "Spit Up",
    [256] = "Swallow",
    [257] = "Heat Wave",
    [258] = "Hail",
    [259] = "Torment",
    [260] = "Flatter",
    [261] = "Will-O-Wisp",
    [262] = "Memento",
    [263] = "Facade",
    [264] = "Focus Punch",
    [265] = "Smelling Salts",
    [266] = "Follow Me",
    [267] = "Nature Power",
    [268] = "Charge",
    [269] = "Taunt",
    [270] = "Helping Hand",
    [271] = "Trick",
    [272] = "Role Play",
    [273] = "Wish",
    [274] = "Assist",
    [275] = "Ingrain",
    [276] = "Superpower",
    [277] = "Magic Coat",
    [278] = "Recycle",
    [279] = "Revenge",
    [280] = "Brick Break",
    [281] = "Yawn",
    [282] = "Knock Off",
    [283] = "Endeavor",
    [284] = "Eruption",
    [285] = "Skill Swap",
    [286] = "Imprison",
    [287] = "Refresh",
    [288] = "Grudge",
    [289] = "Snatch",
    [290] = "Secret Power",
    [291] = "Dive",
    [292] = "Arm Thrust",
    [293] = "Camouflage",
    [294] = "Tail Glow",
    [295] = "Luster Purge",
    [296] = "Mist Ball",
    [297] = "Feather Dance",
    [298] = "Teeter Dance",
    [299] = "Blaze Kick",
    [300] = "Mud Sport",
    [301] = "Ice Ball",
    [302] = "Needle Arm",
    [303] = "Slack Off",
    [304] = "Hyper Voice",
    [305] = "Poison Fang",
    [306] = "Crush Claw",
    [307] = "Blast Burn",
    [308] = "Hydro Cannon",
    [309] = "Meteor Mash",
    [310] = "Astonish",
    [311] = "Weather Ball",
    [312] = "Aromatherapy",
    [313] = "Fake Tears",
    [314] = "Air Cutter",
    [315] = "Overheat",
    [316] = "Odor Sleuth",
    [317] = "Rock Tomb",
    [318] = "Silver Wind",
    [319] = "Metal Sound",
    [320] = "Grass Whistle",
    [321] = "Tickle",
    [322] = "Cosmic Power",
    [323] = "Water Spout",
    [324] = "Signal Beam",
    [325] = "Shadow Punch",
    [326] = "Extrasensory",
    [327] = "Sky Uppercut",
    [328] = "Sand Tomb",
    [329] = "Sheer Cold",
    [330] = "Muddy Water",
    [331] = "Bullet Seed",
    [332] = "Aerial Ace",
    [333] = "Icicle Spear",
    [334] = "Iron Defense",
    [335] = "Block",
    [336] = "Howl",
    [337] = "Dragon Claw",
    [338] = "Frenzy Plant",
    [339] = "Bulk Up",
    [340] = "Bounce",
    [341] = "Mud Shot",
    [342] = "Poison Tail",
    [343] = "Covet",
    [344] = "Volt Tackle",
    [345] = "Magical Leaf",
    [346] = "Water Sport",
    [347] = "Calm Mind",
    [348] = "Leaf Blade",
    [349] = "Dragon Dance",
    [350] = "Rock Blast",
    [351] = "Shock Wave",
    [352] = "Water Pulse",
    [353] = "Doom Desire",
    [354] = "Psycho Boost",
}
TYPES = {
    [0] = "Normal",
    [1] = "Fighting",
    [2] = "Flying",
    [3] = "Poison",
    [4] = "Ground",
    [5] = "Rock",
    [6] = "Bug",
    [7] = "Ghost",
    [8] = "Steel",
    [9] = "???",
    [10] = "Fire",
    [11] = "Water",
    [12] = "Grass",
    [13] = "Electric",
    [14] = "Psychic",
    [15] = "Ice",
    [16] = "Dragon",
    [17] = "Dark"
}

TYPE_PROPERTY = {
    [0] = {
        ["weak"] = {5, 8},
        ["strong"] = {},
        ["ineff"] = {7},
    },
    [1] = {
        ["weak"] = {2, 3, 6, 14},
        ["strong"] = {0, 5, 8, 15, 17},
        ["ineff"] = {7},
    },
    [2] = {
        ["weak"] = {5, 8, 13},
        ["strong"] = {1, 6, 12},
        ["ineff"] = {},
    },
    [3] = {
        ["weak"] = {3, 4, 5, 7},
        ["strong"] = {12},
        ["ineff"] = {8},
    },
    [4] = {
        ["weak"] = {6, 12},
        ["strong"] = {3, 5, 8, 10, 13},
        ["ineff"] = {2},
    },
    [5] = {
        ["weak"] = {1, 4, 8},
        ["strong"] = {2, 6, 10, 15},
        ["ineff"] = {},
    },
    [6] = {
        ["weak"] = {1, 2, 3, 7, 8, 10},
        ["strong"] = {12, 14, 17},
        ["ineff"] = {},
    },
    [7] = {
        ["weak"] = {8, 17},
        ["strong"] = {7, 14},
        ["ineff"] = {0},
    },
    [8] = {
        ["weak"] = {8, 10, 11, 13},
        ["strong"] = {5, 15},
        ["ineff"] = {},
    },
    [10] = {
        ["weak"] = {5, 10, 11, 16},
        ["strong"] = {6, 8, 12, 15},
        ["ineff"] = {},
    },
    [11] = {
        ["weak"] = {11, 12, 16},
        ["strong"] = {4, 5, 10},
        ["ineff"] = {},
    },
    [12] = {
        ["weak"] = {2, 3, 6, 8, 10, 12, 16},
        ["strong"] = {4, 5, 11},
        ["ineff"] = {},
    },
    [13] = {
        ["weak"] = {12, 13, 16},
        ["strong"] = {2, 11},
        ["ineff"] = {4},
    },
    [14] = {
        ["weak"] = {8, 14},
        ["strong"] = {1, 3},
        ["ineff"] = {17},
    },
    [15] = {
        ["weak"] = {8, 10, 11, 15},
        ["strong"] = {2, 4, 12, 16},
        ["ineff"] = {},
    },
    [16] = {
        ["weak"] = {8},
        ["strong"] = {16},
        ["ineff"] = {},
    },
    [17] = {
        ["weak"] = {1, 8, 17},
        ["strong"] = {7, 14},
        ["ineff"] = {},
    },
}

TYPE_ENHANCE_ITEM = {     -- like soft sand, charcoal, etc.
    [0] = 217,
    [1] = 207,
    [2] = 210,
    [3] = 211,
    [4] = 203,
    [5] = 204,
    [6] = 188,
    [7] = 213,
    [8] = 199,
    [10] = 215,
    [11] = 209,
    [12] = 205,
    [13] = 208,
    [14] = 214,
    [15] = 212,
    [16] = 216,
    [17] = 206
}

ABILITY = {
    [1] = "Stench",
    [2] = "Drizzle",
    [3] = "Speed Boost",
    [4] = "Battle Armor",
    [5] = "Sturdy",
    [6] = "Damp",
    [7] = "Limber",
    [8] = "Sand Veil",
    [9] = "Static",
    [10] = "Volt Absorb",
    [11] = "Water Absorb",
    [12] = "Oblivious",
    [13] = "Cloud Nine",
    [14] = "Compound Eyes",
    [15] = "Insomnia",
    [16] = "Color Change",
    [17] = "Immunity",
    [18] = "Flash Fire",
    [19] = "Shield Dust",
    [20] = "Own Tempo",
    [21] = "Suction Cups",
    [22] = "Intimidate",
    [23] = "Shadow Tag",
    [24] = "Rough Skin",
    [25] = "Wonder Guard",
    [26] = "Levitate",
    [27] = "Effect Spore",
    [28] = "Synchronize",
    [29] = "Clear Body",
    [30] = "Natural Cure",
    [31] = "Lightning Rod",
    [32] = "Serene Grace",
    [33] = "Swift Swim",
    [34] = "Chlorophyll",
    [35] = "Illuminate",
    [36] = "Trace",
    [37] = "Huge Power",
    [38] = "Poison Point",
    [39] = "Inner Focus",
    [40] = "Magma Armor",
    [41] = "Water Veil",
    [42] = "Magnet Pull",
    [43] = "Soundproof",
    [44] = "Rain Dish",
    [45] = "Sand Stream",
    [46] = "Pressure",
    [47] = "Thick Fat",
    [48] = "Early Bird",
    [49] = "Flame Body",
    [50] = "Run Away",
    [51] = "Keen Eye",
    [52] = "Hyper Cutter",
    [53] = "Pickup",
    [54] = "Truant",
    [55] = "Hustle",
    [56] = "Cute Charm",
    [57] = "Plus",
    [58] = "Minus",
    [59] = "Forecast",
    [60] = "Sticky Hold",
    [61] = "Shed Skin",
    [62] = "Guts",
    [63] = "Marvel Scale",
    [64] = "Liquid Ooze",
    [65] = "Overgrow",
    [66] = "Blaze",
    [67] = "Torrent",
    [68] = "Swarm",
    [69] = "Rock Head",
    [70] = "Drought",
    [71] = "Arena Trap",
    [72] = "Vital Spirit",
    [73] = "White Smoke",
    [74] = "Pure Power",
    [75] = "Shell Armor",
    [76] = "Air Lock",
}

EXP_GROUP_NAME = {
    [0] = "Medium Fast",
    "Erratic",
    "Fluctuating",
    "Medium Slow",
    "Fast",
    "Slow"
}

-- table where *EXP_GROUP[level][group]* gives how much exp is required for a pokemon in *group* to get to *level*.
EXP_GROUP = {
    {[0] = 0, 0, 0, 0, 0, 0},
    {[0] = 8, 15, 4, 9, 6, 10},
    {[0] = 27, 52, 13, 57, 21, 33},
    {[0] = 64, 122, 32, 96, 51, 80},
    {[0] = 125, 237, 65, 135, 100, 156},
    {[0] = 216, 406, 112, 179, 172, 270},
    {[0] = 343, 637, 178, 236, 274, 428},
    {[0] = 512, 942, 276, 314, 409, 640},
    {[0] = 729, 1326, 393, 419, 583, 911},
    {[0] = 1000, 1800, 540, 560, 800, 1250},
    {[0] = 1331, 2369, 745, 742, 1064, 1663},
    {[0] = 1728, 3041, 967, 973, 1382, 2160},
    {[0] = 2197, 3822, 1230, 1261, 1757, 2746},
    {[0] = 2744, 4719, 1591, 1612, 2195, 3430},
    {[0] = 3375, 5737, 1957, 2035, 2700, 4218},
    {[0] = 4096, 6881, 2457, 2535, 3276, 5120},
    {[0] = 4913, 8155, 3046, 3120, 3930, 6141},
    {[0] = 5832, 9564, 3732, 3798, 4665, 7290},
    {[0] = 6859, 11111, 4526, 4575, 5487, 8573},
    {[0] = 8000, 12800, 5440, 5460, 6400, 10000},
    {[0] = 9261, 14632, 6482, 6458, 7408, 11576},
    {[0] = 10648, 16610, 7666, 7577, 8518, 13310},
    {[0] = 12167, 18737, 9003, 8825, 9733, 15208},
    {[0] = 13824, 21012, 10506, 10208, 11059, 17280},
    {[0] = 15625, 23437, 12187, 11735, 12500, 19531},
    {[0] = 17576, 26012, 14060, 13411, 14060, 21970},
    {[0] = 19683, 28737, 16140, 15244, 15746, 24603},
    {[0] = 21952, 31610, 18439, 17242, 17561, 27440},
    {[0] = 24389, 34632, 20974, 19411, 19511, 30486},
    {[0] = 27000, 37800, 23760, 21760, 21600, 33750},
    {[0] = 29791, 41111, 26811, 24294, 23832, 37238},
    {[0] = 32768, 44564, 30146, 27021, 26214, 40960},
    {[0] = 35937, 48155, 33780, 29949, 28749, 44921},
    {[0] = 39304, 51881, 37731, 33084, 31443, 49130},
    {[0] = 42875, 55737, 42017, 36435, 34300, 53593},
    {[0] = 46656, 59719, 46656, 40007, 37324, 58320},
    {[0] = 50653, 63822, 50653, 43808, 40522, 63316},
    {[0] = 54872, 68041, 55969, 47846, 43897, 68590},
    {[0] = 59319, 72369, 60505, 52127, 47455, 74148},
    {[0] = 64000, 76800, 66560, 56660, 51200, 80000},
    {[0] = 68921, 81326, 71677, 61450, 55136, 86151},
    {[0] = 74088, 85942, 78533, 66505, 59270, 92610},
    {[0] = 79507, 90637, 84277, 71833, 63605, 99383},
    {[0] = 85184, 95406, 91998, 77440, 68147, 106480},
    {[0] = 91125, 100237, 98415, 83335, 72900, 113906},
    {[0] = 97336, 105122, 107069, 89523, 77868, 121670},
    {[0] = 103823, 110052, 114205, 96012, 83058, 129778},
    {[0] = 110592, 115015, 123863, 102810, 88473, 138240},
    {[0] = 117649, 120001, 131766, 109923, 94119, 147061},
    {[0] = 125000, 125000, 142500, 117360, 100000, 156250},
    {[0] = 132651, 131324, 151222, 125126, 106120, 165813},
    {[0] = 140608, 137795, 163105, 133229, 112486, 175760},
    {[0] = 148877, 144410, 172697, 141677, 119101, 186096},
    {[0] = 157464, 151165, 185807, 150476, 125971, 196830},
    {[0] = 166375, 158056, 196322, 159635, 133100, 207968},
    {[0] = 175616, 165079, 210739, 169159, 140492, 219520},
    {[0] = 185193, 172229, 222231, 179056, 148154, 231491},
    {[0] = 195112, 179503, 238036, 189334, 156089, 243890},
    {[0] = 205379, 186894, 250562, 199999, 164303, 256723},
    {[0] = 216000, 194400, 267840, 211060, 172800, 270000},
    {[0] = 226981, 202013, 281456, 222522, 181584, 283726},
    {[0] = 238328, 209728, 300293, 234393, 190662, 297910},
    {[0] = 250047, 217540, 315059, 246681, 200037, 312558},
    {[0] = 262144, 225443, 335544, 259392, 209715, 327680},
    {[0] = 274625, 233431, 351520, 272535, 219700, 343281},
    {[0] = 287496, 241496, 373744, 286115, 229996, 359370},
    {[0] = 300763, 249633, 390991, 300140, 240610, 375953},
    {[0] = 314432, 257834, 415050, 314618, 251545, 393040},
    {[0] = 328509, 267406, 433631, 329555, 262807, 410636},
    {[0] = 343000, 276458, 459620, 344960, 274400, 428750},
    {[0] = 357911, 286328, 479600, 360838, 286328, 447388},
    {[0] = 373248, 296358, 507617, 377197, 298598, 466560},
    {[0] = 389017, 305767, 529063, 394045, 311213, 486271},
    {[0] = 405224, 316074, 559209, 411388, 324179, 506530},
    {[0] = 421875, 326531, 582187, 429235, 337500, 527343},
    {[0] = 438976, 336255, 614566, 447591, 351180, 548720},
    {[0] = 456533, 346965, 639146, 466464, 365226, 570666},
    {[0] = 474552, 357812, 673863, 485862, 379641, 593190},
    {[0] = 493039, 367807, 700115, 505791, 394431, 616298},
    {[0] = 512000, 378880, 737280, 526260, 409600, 640000},
    {[0] = 531441, 390077, 765275, 547274, 425152, 664301},
    {[0] = 551368, 400293, 804997, 568841, 441094, 689210},
    {[0] = 571787, 411686, 834809, 590969, 457429, 714733},
    {[0] = 592704, 423190, 877201, 613664, 474163, 740880},
    {[0] = 614125, 433572, 908905, 636935, 491300, 767656},
    {[0] = 636056, 445239, 954084, 660787, 508844, 795070},
    {[0] = 658503, 457001, 987754, 685228, 526802, 823128},
    {[0] = 681472, 467489, 1035837, 710266, 545177, 851840},
    {[0] = 704969, 479378, 1071552, 735907, 563975, 881211},
    {[0] = 729000, 491346, 1122660, 762160, 583200, 911250},
    {[0] = 753571, 501878, 1160499, 789030, 602856, 941963},
    {[0] = 778688, 513934, 1214753, 816525, 622950, 973360},
    {[0] = 804357, 526049, 1254796, 844653, 643485, 1005446},
    {[0] = 830584, 536557, 1312322, 873420, 664467, 1038230},
    {[0] = 857375, 548720, 1354652, 902835, 685900, 1071718},
    {[0] = 884736, 560922, 1415577, 932903, 707788, 1105920},
    {[0] = 912673, 571333, 1460276, 963632, 730138, 1140841},
    {[0] = 941192, 583539, 1524731, 995030, 752953, 1176490},
    {[0] = 970299, 591882, 1571884, 1027103, 776239, 1212873},
    {[0] = 1000000, 600000, 1640000, 1059860, 800000, 1250000},
}



-- Returns true if the given type is physical (or ???), false if special.
---@param type integer
local function isPhysical(type)
    return (type <= 9)
end

---@class pokemon
---@field personality     integer
---@field nature          string
---@field otid            integer
---@field language        string
---@field checksum        integer
---@field level           integer
---@field stat            table<string, integer>
---@field species_ind     integer                   index of species
---@field species         string
---@field type1           integer                   index of first type
---@field type2           integer                   index of second type. if monotyped, type2 will coincide with type1
---@field item_ind        integer
---@field item            string
---@field exp             integer
---@field exp_group       integer                   index of exp group, or level-up type, from species struct.
---@field base_exp_yield  integer
---@field moves           table<integer, integer>   array of moves
---@field ev              table<string, integer>
---@field beauty          integer
---@field gender          string                    "f" or "m" (currently isn't working)
---@field iv              table<string, integer>
---@field egg             boolean
---@field friendship      integer                   if it's an egg, this counts number of remaining egg cycles
---@field ability         integer                   index of ability (https://bulbapedia.bulbagarden.net/wiki/Ability#List_of_Abilities)
---@field ev_yield        table<string, integer>
---@field status          integer                   https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_structure_(Generation_III)#Status_condition
local pokemon = {}
pokemon.__index = pokemon
local pokemon_fields = {"personality", "nature", "otid", "language", "checksum", "species",
                         "item", "ev", "iv", "ability", "ev_yield", "stat", "moves", "type1",
                         "type2", "exp", "exp_group", "base_exp_yield", "friendship", "egg",
                         "gender", }

-- Returns the locations of the data substructures corresponding to the pokemon at *poke_loc*. Return looks like
---@return integer growth, integer attacks, integer ev_condition, integer misc
---```lua
---    return growth, attacks, ev_condition, misc
---```
local function getSubstructureLocations(poke_loc)
    local personality = emu:read32(poke_loc)
    local data = poke_loc + 32
    local order = personality % 24
    local function align(chunk_order)
        local res = {}
        for i, value in ipairs(chunk_order) do
            res[i] = (value * 12) + data
        end
        return res
    end
    local locs = align(CHUNK_MAP[order])
    return locs[1], locs[2], locs[3], locs[4]
end

---@param loc? integer location in memory of desired pokemon (defaults to front of party)
---@return pokemon # Pokemon structure that contains whatever I feel like honestly (at least IVs and EVs and ability)
function readPoke(loc)
    loc = loc or FRONT
    local poke = {}
    setmetatable(poke, pokemon)

    poke.personality = emu:read32(loc)
    poke.nature = NATURE[poke.personality % 25]
    poke.otid = emu:read32(loc + 4)
    poke.language = emu:read8(loc + 18)
    poke.checksum = emu:read16(loc + 28)
    poke.level = emu:read8(loc + 84)
    poke.stat = {}
    poke.stat.curr_hp = emu:read16(loc + 86)
    poke.stat.tot_hp = emu:read16(loc + 88)
    poke.stat.atk = emu:read16(loc + 90)
    poke.stat.def = emu:read16(loc + 92)
    poke.stat.spe = emu:read16(loc + 94)
    poke.stat.spa = emu:read16(loc + 96)
    poke.stat.spd = emu:read16(loc + 98)

    local key = poke.personality ~ poke.otid
    local growth, attacks, ev_condition, misc = getSubstructureLocations(loc)

    local bits = emu:read32(growth) ~ key
    poke.species_ind = (bits >> 0) & 0xFFFF
    poke.species = POKEDEX[poke.species_ind]
    poke.item_ind = (bits >> 16) & 0xFFFF
    poke.item = ITEM[poke.item_ind]
    poke.exp = emu:read32(growth + 4) ~ key
    bits = emu:read32(growth + 8) ~ key
    poke.friendship = (bits >> 8) & 0xFF

    bits = emu:read32(attacks) ~ key
    poke.moves = {}
    table.insert(poke.moves, (bits >> 0) & 0xFFFF)
    table.insert(poke.moves, (bits >> 16) & 0xFFFF)
    bits = emu:read32(attacks + 4) ~ key
    table.insert(poke.moves, (bits >> 0) & 0xFFFF)
    table.insert(poke.moves, (bits >> 16) & 0xFFFF)

    bits = emu:read32(ev_condition) ~ key
    poke.ev = {}
    poke.ev.hp = (bits >> 0) & 0xFF
    poke.ev.atk = (bits >> 8) & 0xFF
    poke.ev.def = (bits >> 16) & 0xFF
    poke.ev.spe = (bits >> 24) & 0xFF
    bits = emu:read32(ev_condition + 4) ~ key
    poke.ev.spa = (bits >> 0) & 0xFF
    poke.ev.spd = (bits >> 8) & 0xFF
    poke.beauty = (bits >> 24) & 0xFF

    bits = emu:read32(misc) ~ key
    if (bits >> 31) & 0x1 == 1 then
        poke.gender = "f"
    else
        poke.gender = "m"
    end
    bits = emu:read32(misc + 4) ~ key
    poke.iv = {}
    poke.iv.hp = (bits >> 0) & 0x1F
    poke.iv.atk = (bits >> 5) & 0x1F
    poke.iv.def = (bits >> 10) & 0x1F
    poke.iv.spe = (bits >> 15) & 0x1F
    poke.iv.spa = (bits >> 20) & 0x1F
    poke.iv.spd = (bits >> 25) & 0x1F
    poke.egg = ((bits >> 30) & 0x1) == 1
    local ability = bits >> 31          -- 0 if first ability, 1 if second

    poke.status = emu:read32(loc + 80)

    poke.type1 = emu:read8(SPECIES + (poke.species_ind * 28) + 6)
    poke.type2 = emu:read8(SPECIES + (poke.species_ind * 28) + 7)
    poke.base_exp_yield = emu:read8(SPECIES + (poke.species_ind * 28) + 9)
    poke.exp_group = emu:read8(SPECIES + (poke.species_ind * 28) + 19)

    bits = emu:read16(SPECIES + (poke.species_ind * 28) + 10)
    poke.ev_yield = {}
    poke.ev_yield.hp = (bits >> 0) & 0x3
    poke.ev_yield.atk = (bits >> 2) & 0x3
    poke.ev_yield.def = (bits >> 4) & 0x3
    poke.ev_yield.spe = (bits >> 6) & 0x3
    poke.ev_yield.spa = (bits >> 8) & 0x3
    poke.ev_yield.spd = (bits >> 10) & 0x3

    poke.ability = emu:read8(SPECIES + (poke.species_ind * 28) + 22 + ability)

    return poke
end

-- returns pokemon object for front of party in current battle (or last battle if not in one)
function readFront()
    local off = FRONT
    if PARTY_IND then
        off = off + (emu:read8(PARTY_IND) * 100)
    end
    return readPoke(off)
end

-- returns pokemon object for current opposing pokemon
function readOpponent()
    local off = WILD
    if OPP_IND then
        off = off + (emu:read8(OPP_IND) * 100)
    end
    return readPoke(off)
end

-- Returns true if any field of *self* is nil, false otherwise
---@return boolean
function pokemon:checkFields()
    for _, value in ipairs(pokemon_fields) do
        if self[value] == nil then
            return true
        end
    end
    return false
end

-- Returns true if *self* is shiny, false otherwise
---@return boolean
function pokemon:isShiny()
    local id = self.otid & 0xFFFF
    local sid = self.otid >> 16
    local p1 = self.personality & 0xFFFF
    local p2 = self.personality >> 16
    return (id ~ sid ~ p1 ~ p2) < 8
end

function pokemon:printEVs()
    local ev = self.ev
    print("EVs:")
    print("HP:\t\t" .. tostring(ev.hp))
    print("Attack:\t\t" .. tostring(ev.atk))
    print("Defense:\t\t" .. tostring(ev.def))
    print("Sp. Attack:\t" .. tostring(ev.spa))
    print("Sp. Defense:\t" .. tostring(ev.spd))
    print("Speed:\t\t" .. tostring(ev.spe))
    local sum = 0
    for _, value in pairs(ev) do
        sum = sum + value
    end
    print("Total:\t\t" .. tostring(sum))
end

function pokemon:printIVs()
    local iv = self.iv
    print("IVs:")
    print("HP:\t\t" .. tostring(iv.hp))
    print("Attack:\t\t" .. tostring(iv.atk))
    print("Defense:\t\t" .. tostring(iv.def))
    print("Sp. Attack:\t" .. tostring(iv.spa))
    print("Sp. Defense:\t" .. tostring(iv.spd))
    print("Speed:\t\t" .. tostring(iv.spe))
end

function pokemon:printMoves()
    for i = 1, 4 do
        print("Move " .. tostring(i) .. ":\t" .. MOVES[self.moves[i]])
    end
end

function pokemon:print()
    if self:checkFields() then
        print()
        return
    end
    print("\t" .. self.species)
    print("Nature:\t\t" .. self.nature)
    print("Ability:\t\t" .. self.ability)
    print("Item:\t\t" .. self.item)
    print()
    self:printEVs()
    self:printIVs()
end

function pokemon:sumEV()
    local sum = 0
    for _, ev in pairs(self.ev) do
        sum = sum + ev
    end
    return sum
end

-- Prints opponent's trainers pokemons (pokemen?)
function printOpponent()
    if not opponentBuffer then
        opponentBuffer = console:createBuffer("Enemy Trainer")
    end
    local function send(str)
        opponentBuffer:print(str .. "\n")
    end

    opponentBuffer:clear()
    for i = 0, 500, 100 do
        local poke = readPoke(WILD + i)
        if poke.species == POKEDEX[0] then
            goto continue
        end
        send(poke.species .. "  lvl " .. tostring(poke.level))
        ::continue::
    end
end

-- returns entire trainer id, secret (high 16) and visible (low 16). Returns -1 if TRAINER_ID is undefined.
local function getTrainerId()
    if not TRAINER_ID then
        return -1
    end
    local visible = emu:read16(TRAINER_ID)
    local secret = emu:read16(TRAINER_ID + 2)
    return (secret << 16) + visible
end

local function fixChecksum(poke_loc)
    local data_loc = poke_loc + 32
    local poke = readPoke(poke_loc)
    local key = poke.personality ~ poke.otid
    local check = 0
    for i = 0, 47, 4 do
        local bits = emu:read32(data_loc + i) ~ key
        check = check + (bits & 0xFFFF) + ((bits >> 16) & 0xFFFF)
    end
    check = check & 0xFFFF
    emu:write16(FRONT + 28, check)
end

-- my motivation for writing this function was that I wanted
-- a Tyranitar with ancient power and dragon dance, but after completing
-- the Hoenn dex to get the totodile for ancient power I realized they
-- are not both possible in the vanilla game. This function is my retaliation.
---@param poke_loc integer Location in memory of desired pokemon to modify
---@param move_ind integer Which move to modify (move 1, 2, 3, or 4)
---@param new_move_ind integer Index of new move (see bulbapedia list of moves for names or MOVES in data.lua)
local function changeMove(poke_loc, move_ind, new_move_ind)
    assert(move_ind == 1 or move_ind == 2 or move_ind == 3 or move_ind == 4, "move_ind must be 1, 2, 3, or 4.")

    local poke = readPoke(poke_loc)
    print(string.format("Changing move %d of %s to %s", move_ind, poke.species, MOVES[new_move_ind]))
    
    local key = poke.personality ~ poke.otid
    local _, attacks, _, _ = getSubstructureLocations(poke_loc)

    local pp = 0
    if MOVE_LOC then
        pp = emu:read8(MOVE_LOC + (new_move_ind * 12) + 4)
    end

    local mask
    local exponent
    if (move_ind % 2) == 0 then
        mask = 0x0000FFFF
        exponent = 16
    else
        mask = 0xFFFF0000
        exponent = 0
    end

    local offset = 0
    if move_ind > 2 then
        offset = 4
    end

    local bits = emu:read32(attacks + offset) ~ key
    bits = (bits & mask) + (new_move_ind << exponent)
    emu:write32(attacks + offset, bits ~ key)

    bits = emu:read32(attacks + 8) ~ key
    local move_off = move_ind - 1
    exponent = move_off * 8
    mask = 0xFFFFFFFF - (0xFF << exponent)
    bits = (bits & mask) + (pp << exponent)
    emu:write32(attacks + 8, bits ~ key)

    fixChecksum(poke_loc)
end

-- Changes front pokemon's *move_ind* move to *new_move*
---@param move_ind integer 1, 2, 3, or 4
---@param new_move string name of new move (case and whitespace insensitive ["ancientpower" will work for "Ancient Power"])
function changeFrontMove(move_ind, new_move)
    new_move_test = new_move:gsub("%s", ""):lower()

    local new_move_ind = -1
    for key, value in pairs(MOVES) do
        if new_move_test == value:gsub("%s", ""):lower() then
            new_move_ind = key
            break
        end
    end

    if new_move_ind == -1 then
        print(string.format("Could not locate move \"%s\"", new_move))
        return
    end

    changeMove(FRONT, move_ind, new_move_ind)
end

-- Adds max pp boosts to all moves of the pokemon at *poke_loc*
local function maxPP(poke_loc)
    local poke = readPoke(poke_loc)
    print(string.format("Adding pp boosts to %s", poke.species))
    
    local key = poke.personality ~ poke.otid
    local growth, _, _, _ = getSubstructureLocations(poke_loc)

    local bits = emu:read32(growth + 8) ~ key
    bits = (bits & 0xFFFFFF00) + 0xFF
    emu:write32(growth + 8, bits ~ key)

    fixChecksum(poke_loc)
end

-- Maxes pp boosts for current pokemon at front of party
function maxFrontPP()
    maxPP(FRONT)
end

-- Maxes all IVs to 31 of the pokemon at *poke_loc* in memory
local function maxIVs(poke_loc)
    local poke = readPoke(poke_loc)
    print(string.format("Maxing %s's IVs", poke.species))
    local key = poke.personality ~ poke.otid
    local _, _, _, misc = getSubstructureLocations(poke_loc)

    local bits = emu:read32(misc + 4) ~ key
    bits = bits | 0x3FFFFFFF        -- set last 30 bits (iv bits) to 1, don't touch highest 2
    emu:write32(misc + 4, bits ~ key)

    fixChecksum(poke_loc)
end

-- Maxes all IVs of pokemon at front of party
function maxFrontIVs()
    maxIVs(FRONT)
end

-- https://bulbapedia.bulbagarden.net/wiki/Experience#Gain_formula
-- Returns exp gain if {wild, trainer}, should be about 1.5x difference (I'm not sure how to determine whether it's wild or a trainer battle).
function expCalc()
    local good = readFront()
    local bad = readOpponent()

    local b = bad.base_exp_yield
    local L = bad.level
    local s = 1
    local e = 1
    if good.item_ind == 197 then    -- lucky egg
        e = 1.5
    end
    local a = 1
    local t = 1
    if TRAINER_ID then
        local curr_tid = getTrainerId()
        if good.otid ~= curr_tid then
            t = 1.5
        end
    end

    local exp_wild = ((b * L) / 7) * (1 / s) * e * a * t
    local exp_trainer = exp_wild * 1.5
    return {math.floor(exp_wild), math.floor(exp_trainer)}
end

local function contains(t, value)
    for _, check in pairs(t) do
        if value == check then
            return true
        end
    end
    return false
end

-- https://github.com/pret/pokeemerald/blob/50d325f081a161f4a223d999497d7a65bd896194/include/pokemon.h#L260
-- battle pokemon struct definition
-- https://github.com/pret/pokeemerald/blob/50d325f081a161f4a223d999497d7a65bd896194/src/battle_main.c#L164
-- battle pokemon struct declaration in ewram
-- u8 gBattlerAttacker gives which BattlePokemon struct is battling, which has stat changes under s8 statChanges[8] (6 stats + accuracy/evasion)
-- uses APPLY_STAT_MOD macro to do this, with these ratios https://github.com/pret/pokeemerald/blob/50d325f081a161f4a223d999497d7a65bd896194/src/pokemon.c#L1868

-- Calculate how much damage *user* will do to *against* with move *move* on a high roll (https://bulbapedia.bulbagarden.net/wiki/Damage#Generation_III).  
-- Currently doesn't check weather or boujee move effects like Facade or Earthquake/Surf. Or stat changes like from calm mind. It is dumb. I am lazy.    
-- Checks: {Base stats, physical/special, level, burn phys debuff, STAB, type chart (fighting 2x against normal etc.), moves like dragon rage / psywave etc., type-enhancing item like softsand etc.}
---@param user pokemon
---@param against pokemon
---@param move integer
---@return integer
function damageCalc(user, against, move)
    if (user:checkFields()) or (against:checkFields()) or (not MOVE_LOC) or (move == 117) or (move == 68) or (move == 283) or (move == 243) then       -- bide, counter, endeavor, mirror coat
        return -1
    elseif (move == 82) then    -- dragon rage
        return 40
    elseif (move == 149) then   -- psywave
        return user.level * 1.5
    elseif (move == 69) then    -- seismic toss
        if (against.type1 == 7) or (against.type2 == 7) then
            return 0
        else
            return user.level
        end
    elseif (move == 49) then    -- sonic boom
        if (against.type1 == 7) or (against.type2 == 7) then
            return 0
        else
            return 20
        end
    elseif (move == 162) then   --super fang
        return against.stat.curr_hp // 2
    end

    local level = user.level
    local move_off = MOVE_LOC + (move * 12)
    local power = emu:read8(move_off + 1)     -- + 1 gives offset inside move struc for power
    local move_type = emu:read8(move_off + 2)
    if (move_type == 9) or (move_type > 17) then
        return 0
    end
    if TYPE_ENHANCE_ITEM[move_type] == user.item_ind then
        power = power * 1.1
    end
    local A = 69
    local D = 69
    local physical = isPhysical(move_type)
    if physical then
        A = user.stat.atk
        D = against.stat.def
    else
        A = user.stat.spa
        D = against.stat.spd
    end
    local burn = 1
    if physical and (((user.status >> 4) & 0x1) == 1) and not (user.ability == 62) then      -- https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_structure_(Generation_III)#Status_condition
        burn = 0.5
    end
    local screen = 1        -- battle.h (gSideStatuses)
    local targets = 1       -- double battles
    local weather = 1       -- battle.h (gBattleWeather)
    local ff = 1            -- battle.h (gBattleResources)
    local stockpile = 1
    local critical = 1
    local double_dmg = 1
    local charge = 1
    local hh = 1
    local stab = 1
    if (move_type == user.type1) or (move_type == user.type2) then
        stab = 1.5
    end
    local opp_type1 = against.type1
    local opp_type2 = against.type2
    local type1 = 1
    local type2 = 1
    if contains(TYPE_PROPERTY[move_type]["strong"], opp_type1) then
        type1 = 2.0
    elseif contains(TYPE_PROPERTY[move_type]["weak"], opp_type1) then
        type1 = 0.5
    elseif contains(TYPE_PROPERTY[move_type]["ineff"], opp_type1) then
        type1 = 0
    end
    if contains(TYPE_PROPERTY[move_type]["strong"], opp_type2) then
        type2 = 2.0
    elseif contains(TYPE_PROPERTY[move_type]["weak"], opp_type2) then
        type2 = 0.5
    elseif contains(TYPE_PROPERTY[move_type]["ineff"], opp_type2) then
        type2 = 0
    end

    local dmg = ((((((2 * level)/5) + 2) * power * (A/D)) / 50) * burn * screen * targets * weather * ff + 2) * stockpile * critical * double_dmg * charge * hh * stab * type1 * type2
    return dmg
end
