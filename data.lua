-- https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_structure_(Generation_III)
-- pretty much all offsets and logic from link above. god fuck what am i doing with my life

function print(thing)
    if thing == nil then
        thing = ""
    end
    console:log(tostring(thing))
end

local game = emu:getGameCode()
if (game == "AGB-AXVE") or (game == "AGB-AXPE") then  -- ruby/sapphire
    print("Ruby/Sapphire detected!")
    FRONT = 0x03004360
    WILD = 0x030045C0
    PARTY_COUNT = 0x3004350
elseif game == "AGB-BPEE" then  -- emerald
    print("Emerald detected!")
    FRONT = 0x020244EC
    WILD = 0x02024744
    PARTY_COUNT = 0x20244e9
elseif (game == "AGB-BPRE") or (game == "AGB-BPGE") then    -- frlg
    print("FireRed/LeafGreen detected!")
    FRONT = 0x02024284
    WILD = 0x0202402C
    PARTY_COUNT = 0x2024029
else
    print("Couldn't recognize game code:\t" .. game)
    os.exit(1)
end

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
local NATURE = {
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
local ITEM = {
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
local POKEDEX = {
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

---@class pokemon
---@field package personality     integer
---@field package nature          string
---@field package otid            integer
---@field package language        string
---@field package checksum        integer
---@field package species         string
---@field package item            string
---@field package ev              table<string, integer>
---@field package iv              table<string, integer>
---@field package ability         integer       0 for first ability, 1 for second ability
local pokemon = {}
pokemon.__index = pokemon
local pokemon_fields = {"personality", "nature", "otid", "language", "checksum", "species", "item", "ev", "iv", "ability"}

-- TODO: maybe add checksum logic? why not
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

    local key = poke.personality ~ poke.otid
    local data = loc + 32
    local order = poke.personality % 24
    local function align(chunk_order)
        local res = {}
        for i, value in ipairs(chunk_order) do
            res[i] = (value * 12) + data
        end
        return res
    end
    local growth, attacks, ev_condition, misc = table.unpack(align(CHUNK_MAP[order]))

    local bits = emu:read32(growth) ~ key
    poke.species = POKEDEX[(bits >> 0) & 0xFFFF]
    poke.item = ITEM[(bits >> 16) & 0xFFFF]

    bits = emu:read32(ev_condition) ~ key
    poke.ev = {}
    poke.ev.hp = (bits >> 0) & 0xFF
    poke.ev.atk = (bits >> 8) & 0xFF
    poke.ev.def = (bits >> 16) & 0xFF
    poke.ev.spe = (bits >> 24) & 0xFF
    bits = emu:read32(ev_condition + 4) ~ key
    poke.ev.spa = (bits >> 0) & 0xFF
    poke.ev.spd = (bits >> 8) & 0xFF

    bits = emu:read32(misc + 4) ~ key
    poke.iv = {}
    poke.iv.hp = (bits >> 0) & 0x1F
    poke.iv.atk = (bits >> 5) & 0x1F
    poke.iv.def = (bits >> 10) & 0x1F
    poke.iv.spe = (bits >> 15) & 0x1F
    poke.iv.spa = (bits >> 20) & 0x1F
    poke.iv.spd = (bits >> 25) & 0x1F
    poke.ability = bits >> 31

    return poke
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

function pokemon:print()
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

local function printWild()
    local poke = readPoke(WILD)
    print("Wild Pokemon:")
    poke:print()
end

local function printFront()
    local poke = readPoke(FRONT)
    print("Front of party:")
    poke:print()
end

local function printParty()
    print("Party:")
    for i = 0, 500, 100 do
        local poke = readPoke(FRONT + i)
        poke:print()
        print()
    end
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

    local count = emu:read8(PARTY_COUNT)
    local function sendEV(str)
        partyEVBuffer:print(str .. "\n")
    end
    local function sendIV(str)
        partyIVBuffer:print(str .. "\n")
    end
    local function send(str)
        sendEV(str)
        sendIV(str)
    end
    partyEVBuffer:clear()
    partyIVBuffer:clear()
    for i = 0, (count - 1) * 100, 100 do
        local poke = readPoke(FRONT + i)
        if poke.species == POKEDEX[0] then
            goto continue
        end
        local ev = poke.ev
        local iv = poke.iv
        send(string.format("%-13s @%s", poke.species, poke.item))       -- turns out longest pokemon name in gen 3 is 12 characters (Pokémon Egg), followed by Masquerain (10 char)
        sendEV(string.format("HP %3d Atk %3d Def %3d Sp.A %3d Sp.D %3d Spe %3d Total %d",
                            ev.hp, ev.atk, ev.def, ev.spa, ev.spd, ev.spe, poke:sumEV()))
        sendIV(string.format("HP %2d Atk %2d Def %2d Sp.A %2d Sp.D %2d Spe %2d",
                            iv.hp, iv.atk, iv.def, iv.spa, iv.spd, iv.spe))
        ::continue::
    end
end

-- Scans and outputs the most recently encountered enemy pokemon (wild or trainer)
---@param skip_frames? integer If passed, will only scan every *skip_frames* frames
function scanWild(skip_frames)
    if (skip_frames ~= nil) and (emu:currentFrame() % skip_frames ~= 0) then
        return
    end

    if not wildBuffer then
        wildBuffer = console:createBuffer("Wild IVs")
    end

    local poke = readPoke(WILD)
    if poke:checkFields() then
        return
    end
    
    local iv = poke.iv
    wildBuffer:clear()
    local function send(str)
        wildBuffer:print(str .. "\n")
    end
    send(string.format("%-13s @%s", poke.species, poke.item))
    send("HP:\t\t" .. tostring(iv.hp))
    send("Attack:\t\t" .. tostring(iv.atk))
    send("Defense:\t\t" .. tostring(iv.def))
    send("Sp. Attack:\t" .. tostring(iv.spa))
    send("Sp. Defense:\t" .. tostring(iv.spd))
    send("Speed:\t\t" .. tostring(iv.spe))
    send("Nature:\t" .. poke.nature)
    local shiny
    if poke:isShiny() then
        shiny = "*Yes!*"
    else
        shiny = "No"
    end
    send("Shiny:\t" .. shiny)
end


local function main()
    print("\n-------------------")
    printFront()
    printWild()
    -- printParty()
end

-- main()
-- print(math.floor(((2 * 100 + getIVs().def + math.floor(getEVs().def / 4)) * getLevel()) / 100) + 5) -- blastoise defense calc