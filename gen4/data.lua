if _DATA_RUN then
    return
end
_DATA_RUN = true        -- my C header macro lol

read8 = memory.readbyte
read16 = memory.read_u16_le
read32 = memory.read_u32_le

write8 = memory.writebyte
write16 = memory.write_u16_le
write32 = memory.write_u32_le

local game_8 = read8(0x02FFFE08)
local game_16 = read16(0x02FFFE08)
if game_16 == 0x4C50 then  -- Check game version
    game = "Platinum"
    BASE_PTR = 0x02101D2C
    FRONT_OFF = 0xD094
    PARTY_TRACK = 0x539F4 -- tracks which index player poke is in battle currently (0 for front, 1 for second, etc.)
    ENEMY_OFF = 0x58E3C  -- From searching
    -- ENEMY_TRACK = 0xA3D14   -- from searching
    -- ENEMY_TRACK = 0xA3A2C   -- from searching
    -- ENEMY_TRACK = 0xA39B4   -- from searching
    -- ENEMY_TRACK = 0xA393C   -- from searching
    -- ENEMY_TRACK = 0xA3834   -- from searching
    -- ENEMY_TRACK = 0xA2844   -- from searching
    SPECIES_ROM = 0x03704E08 - 44
elseif game_8 == 0x44 then
    game = "Diamond"
elseif game_8 == 0x50 then
    game = "Pearl"
elseif game_16 == 0x4748 then
    game = "HeartGold"
    BASE_PTR = 0x0211186C
    FRONT_OFF = 0xD088
    ENEMY_OFF = 0x3A3EC
    SPECIES_ROM = 0x06FCF208 - 44
elseif game_16 == 0x5353 then
    game = "SoulSilver"
    BASE_PTR = 0x0211186C
    FRONT_OFF = 0xD088
    ENEMY_OFF = 0x3A3EC
    -- ENEMY_OFF = 0x3CEC8
    -- ENEMY_OFF = 0x52218
    -- ENEMY_OFF = 0x56F1C
    -- ENEMY_OFF = 0x5C048
    -- ENEMY_OFF = 0x43A3EC
    -- ENEMY_OFF = 0x43CEC8
    -- ENEMY_OFF = 0x452218
    -- ENEMY_OFF = 0x456F1C
    -- ENEMY_OFF = 0x45C048
    -- ENEMY_OFF = 0x83A3EC
    -- ENEMY_OFF = 0x83CEC8
    -- ENEMY_OFF = 0x852218
    -- ENEMY_OFF = 0x856F1C
    -- ENEMY_OFF = 0x85C048
    -- ENEMY_OFF = 0xC3A3EC
    -- ENEMY_OFF = 0xC3CEC8
    -- ENEMY_OFF = 0xC52218
    -- ENEMY_OFF = 0xC56F1C
    -- ENEMY_OFF = 0xC5C048
    SPECIES_ROM = 0x06FCF208 - 44
else
    console.log("Non Gen IV game detected.")
    game = "idk"
end

local lang = read8(0x02FFFE0F)
if lang ~= 0x45 then
    console.log("Non USA version detected. Not supported.")
end

POKE_SIZE = 236

local POKEDEX = {
    [000] = "-----",       [001] = "Bulbasaur",   [002] = "Ivysaur",     [003] = "Venusaur",    [004] = "Charmander",  
    [005] = "Charmeleon",  [006] = "Charizard",   [007] = "Squirtle",    [008] = "Wartortle",   [009] = "Blastoise",   
    [010] = "Caterpie",    [011] = "Metapod",     [012] = "Butterfree",  [013] = "Weedle",      [014] = "Kakuna",      
    [015] = "Beedrill",    [016] = "Pidgey",      [017] = "Pidgeotto",   [018] = "Pidgeot",     [019] = "Rattata",     
    [020] = "Raticate",    [021] = "Spearow",     [022] = "Fearow",      [023] = "Ekans",       [024] = "Arbok",       
    [025] = "Pikachu",     [026] = "Raichu",      [027] = "Sandshrew",   [028] = "Sandslash",   [029] = "Nidoran♀",    
    [030] = "Nidorina",    [031] = "Nidoqueen",   [032] = "Nidoran♂",    [033] = "Nidorino",    [034] = "Nidoking",    
    [035] = "Clefairy",    [036] = "Clefable",    [037] = "Vulpix",      [038] = "Ninetales",   [039] = "Jigglypuff",  
    [040] = "Wigglytuff",  [041] = "Zubat",       [042] = "Golbat",      [043] = "Oddish",      [044] = "Gloom",       
    [045] = "Vileplume",   [046] = "Paras",       [047] = "Parasect",    [048] = "Venonat",     [049] = "Venomoth",    
    [050] = "Diglett",     [051] = "Dugtrio",     [052] = "Meowth",      [053] = "Persian",     [054] = "Psyduck",     
    [055] = "Golduck",     [056] = "Mankey",      [057] = "Primeape",    [058] = "Growlithe",   [059] = "Arcanine",    
    [060] = "Poliwag",     [061] = "Poliwhirl",   [062] = "Poliwrath",   [063] = "Abra",        [064] = "Kadabra",     
    [065] = "Alakazam",    [066] = "Machop",      [067] = "Machoke",     [068] = "Machamp",     [069] = "Bellsprout",  
    [070] = "Weepinbell",  [071] = "Victreebel",  [072] = "Tentacool",   [073] = "Tentacruel",  [074] = "Geodude",     
    [075] = "Graveler",    [076] = "Golem",       [077] = "Ponyta",      [078] = "Rapidash",    [079] = "Slowpoke",    
    [080] = "Slowbro",     [081] = "Magnemite",   [082] = "Magneton",    [083] = "Farfetch'd",  [084] = "Doduo",       
    [085] = "Dodrio",      [086] = "Seel",        [087] = "Dewgong",     [088] = "Grimer",      [089] = "Muk",         
    [090] = "Shellder",    [091] = "Cloyster",    [092] = "Gastly",      [093] = "Haunter",     [094] = "Gengar",      
    [095] = "Onix",        [096] = "Drowzee",     [097] = "Hypno",       [098] = "Krabby",      [099] = "Kingler",     
    [100] = "Voltorb",     [101] = "Electrode",   [102] = "Exeggcute",   [103] = "Exeggutor",   [104] = "Cubone",      
    [105] = "Marowak",     [106] = "Hitmonlee",   [107] = "Hitmonchan",  [108] = "Lickitung",   [109] = "Koffing",     
    [110] = "Weezing",     [111] = "Rhyhorn",     [112] = "Rhydon",      [113] = "Chansey",     [114] = "Tangela",     
    [115] = "Kangaskhan",  [116] = "Horsea",      [117] = "Seadra",      [118] = "Goldeen",     [119] = "Seaking",     
    [120] = "Staryu",      [121] = "Starmie",     [122] = "Mr. Mime",    [123] = "Scyther",     [124] = "Jynx",        
    [125] = "Electabuzz",  [126] = "Magmar",      [127] = "Pinsir",      [128] = "Tauros",      [129] = "Magikarp",    
    [130] = "Gyarados",    [131] = "Lapras",      [132] = "Ditto",       [133] = "Eevee",       [134] = "Vaporeon",    
    [135] = "Jolteon",     [136] = "Flareon",     [137] = "Porygon",     [138] = "Omanyte",     [139] = "Omastar",     
    [140] = "Kabuto",      [141] = "Kabutops",    [142] = "Aerodactyl",  [143] = "Snorlax",     [144] = "Articuno",    
    [145] = "Zapdos",      [146] = "Moltres",     [147] = "Dratini",     [148] = "Dragonair",   [149] = "Dragonite",   
    [150] = "Mewtwo",      [151] = "Mew",         [152] = "Chikorita",   [153] = "Bayleef",     [154] = "Meganium",    
    [155] = "Cyndaquil",   [156] = "Quilava",     [157] = "Typhlosion",  [158] = "Totodile",    [159] = "Croconaw",    
    [160] = "Feraligatr",  [161] = "Sentret",     [162] = "Furret",      [163] = "Hoothoot",    [164] = "Noctowl",     
    [165] = "Ledyba",      [166] = "Ledian",      [167] = "Spinarak",    [168] = "Ariados",     [169] = "Crobat",      
    [170] = "Chinchou",    [171] = "Lanturn",     [172] = "Pichu",       [173] = "Cleffa",      [174] = "Igglybuff",   
    [175] = "Togepi",      [176] = "Togetic",     [177] = "Natu",        [178] = "Xatu",        [179] = "Mareep",      
    [180] = "Flaaffy",     [181] = "Ampharos",    [182] = "Bellossom",   [183] = "Marill",      [184] = "Azumarill",   
    [185] = "Sudowoodo",   [186] = "Politoed",    [187] = "Hoppip",      [188] = "Skiploom",    [189] = "Jumpluff",    
    [190] = "Aipom",       [191] = "Sunkern",     [192] = "Sunflora",    [193] = "Yanma",       [194] = "Wooper",      
    [195] = "Quagsire",    [196] = "Espeon",      [197] = "Umbreon",     [198] = "Murkrow",     [199] = "Slowking",    
    [200] = "Misdreavus",  [201] = "Unown",       [202] = "Wobbuffet",   [203] = "Girafarig",   [204] = "Pineco",      
    [205] = "Forretress",  [206] = "Dunsparce",   [207] = "Gligar",      [208] = "Steelix",     [209] = "Snubbull",    
    [210] = "Granbull",    [211] = "Qwilfish",    [212] = "Scizor",      [213] = "Shuckle",     [214] = "Heracross",   
    [215] = "Sneasel",     [216] = "Teddiursa",   [217] = "Ursaring",    [218] = "Slugma",      [219] = "Magcargo",    
    [220] = "Swinub",      [221] = "Piloswine",   [222] = "Corsola",     [223] = "Remoraid",    [224] = "Octillery",   
    [225] = "Delibird",    [226] = "Mantine",     [227] = "Skarmory",    [228] = "Houndour",    [229] = "Houndoom",    
    [230] = "Kingdra",     [231] = "Phanpy",      [232] = "Donphan",     [233] = "Porygon2",    [234] = "Stantler",    
    [235] = "Smeargle",    [236] = "Tyrogue",     [237] = "Hitmontop",   [238] = "Smoochum",    [239] = "Elekid",      
    [240] = "Magby",       [241] = "Miltank",     [242] = "Blissey",     [243] = "Raikou",      [244] = "Entei",       
    [245] = "Suicune",     [246] = "Larvitar",    [247] = "Pupitar",     [248] = "Tyranitar",   [249] = "Lugia",       
    [250] = "Ho-Oh",       [251] = "Celebi",      [252] = "Treecko",     [253] = "Grovyle",     [254] = "Sceptile",    
    [255] = "Torchic",     [256] = "Combusken",   [257] = "Blaziken",    [258] = "Mudkip",      [259] = "Marshtomp",   
    [260] = "Swampert",    [261] = "Poochyena",   [262] = "Mightyena",   [263] = "Zigzagoon",   [264] = "Linoone",     
    [265] = "Wurmple",     [266] = "Silcoon",     [267] = "Beautifly",   [268] = "Cascoon",     [269] = "Dustox",      
    [270] = "Lotad",       [271] = "Lombre",      [272] = "Ludicolo",    [273] = "Seedot",      [274] = "Nuzleaf",     
    [275] = "Shiftry",     [276] = "Taillow",     [277] = "Swellow",     [278] = "Wingull",     [279] = "Pelipper",    
    [280] = "Ralts",       [281] = "Kirlia",      [282] = "Gardevoir",   [283] = "Surskit",     [284] = "Masquerain",  
    [285] = "Shroomish",   [286] = "Breloom",     [287] = "Slakoth",     [288] = "Vigoroth",    [289] = "Slaking",     
    [290] = "Nincada",     [291] = "Ninjask",     [292] = "Shedinja",    [293] = "Whismur",     [294] = "Loudred",     
    [295] = "Exploud",     [296] = "Makuhita",    [297] = "Hariyama",    [298] = "Azurill",     [299] = "Nosepass",    
    [300] = "Skitty",      [301] = "Delcatty",    [302] = "Sableye",     [303] = "Mawile",      [304] = "Aron",        
    [305] = "Lairon",      [306] = "Aggron",      [307] = "Meditite",    [308] = "Medicham",    [309] = "Electrike",   
    [310] = "Manectric",   [311] = "Plusle",      [312] = "Minun",       [313] = "Volbeat",     [314] = "Illumise",    
    [315] = "Roselia",     [316] = "Gulpin",      [317] = "Swalot",      [318] = "Carvanha",    [319] = "Sharpedo",    
    [320] = "Wailmer",     [321] = "Wailord",     [322] = "Numel",       [323] = "Camerupt",    [324] = "Torkoal",     
    [325] = "Spoink",      [326] = "Grumpig",     [327] = "Spinda",      [328] = "Trapinch",    [329] = "Vibrava",     
    [330] = "Flygon",      [331] = "Cacnea",      [332] = "Cacturne",    [333] = "Swablu",      [334] = "Altaria",     
    [335] = "Zangoose",    [336] = "Seviper",     [337] = "Lunatone",    [338] = "Solrock",     [339] = "Barboach",    
    [340] = "Whiscash",    [341] = "Corphish",    [342] = "Crawdaunt",   [343] = "Baltoy",      [344] = "Claydol",     
    [345] = "Lileep",      [346] = "Cradily",     [347] = "Anorith",     [348] = "Armaldo",     [349] = "Feebas",      
    [350] = "Milotic",     [351] = "Castform",    [352] = "Kecleon",     [353] = "Shuppet",     [354] = "Banette",     
    [355] = "Duskull",     [356] = "Dusclops",    [357] = "Tropius",     [358] = "Chimecho",    [359] = "Absol",       
    [360] = "Wynaut",      [361] = "Snorunt",     [362] = "Glalie",      [363] = "Spheal",      [364] = "Sealeo",      
    [365] = "Walrein",     [366] = "Clamperl",    [367] = "Huntail",     [368] = "Gorebyss",    [369] = "Relicanth",   
    [370] = "Luvdisc",     [371] = "Bagon",       [372] = "Shelgon",     [373] = "Salamence",   [374] = "Beldum",      
    [375] = "Metang",      [376] = "Metagross",   [377] = "Regirock",    [378] = "Regice",      [379] = "Registeel",   
    [380] = "Latias",      [381] = "Latios",      [382] = "Kyogre",      [383] = "Groudon",     [384] = "Rayquaza",    
    [385] = "Jirachi",     [386] = "Deoxys",      [387] = "Turtwig",     [388] = "Grotle",      [389] = "Torterra",    
    [390] = "Chimchar",    [391] = "Monferno",    [392] = "Infernape",   [393] = "Piplup",      [394] = "Prinplup",    
    [395] = "Empoleon",    [396] = "Starly",      [397] = "Staravia",    [398] = "Staraptor",   [399] = "Bidoof",      
    [400] = "Bibarel",     [401] = "Kricketot",   [402] = "Kricketune",  [403] = "Shinx",       [404] = "Luxio",       
    [405] = "Luxray",      [406] = "Budew",       [407] = "Roserade",    [408] = "Cranidos",    [409] = "Rampardos",   
    [410] = "Shieldon",    [411] = "Bastiodon",   [412] = "Burmy",       [413] = "Wormadam",    [414] = "Mothim",      
    [415] = "Combee",      [416] = "Vespiquen",   [417] = "Pachirisu",   [418] = "Buizel",      [419] = "Floatzel",    
    [420] = "Cherubi",     [421] = "Cherrim",     [422] = "Shellos",     [423] = "Gastrodon",   [424] = "Ambipom",     
    [425] = "Drifloon",    [426] = "Drifblim",    [427] = "Buneary",     [428] = "Lopunny",     [429] = "Mismagius",   
    [430] = "Honchkrow",   [431] = "Glameow",     [432] = "Purugly",     [433] = "Chingling",   [434] = "Stunky",      
    [435] = "Skuntank",    [436] = "Bronzor",     [437] = "Bronzong",    [438] = "Bonsly",      [439] = "Mime Jr.",    
    [440] = "Happiny",     [441] = "Chatot",      [442] = "Spiritomb",   [443] = "Gible",       [444] = "Gabite",      
    [445] = "Garchomp",    [446] = "Munchlax",    [447] = "Riolu",       [448] = "Lucario",     [449] = "Hippopotas",  
    [450] = "Hippowdon",   [451] = "Skorupi",     [452] = "Drapion",     [453] = "Croagunk",    [454] = "Toxicroak",   
    [455] = "Carnivine",   [456] = "Finneon",     [457] = "Lumineon",    [458] = "Mantyke",     [459] = "Snover",      
    [460] = "Abomasnow",   [461] = "Weavile",     [462] = "Magnezone",   [463] = "Lickilicky",  [464] = "Rhyperior",   
    [465] = "Tangrowth",   [466] = "Electivire",  [467] = "Magmortar",   [468] = "Togekiss",    [469] = "Yanmega",     
    [470] = "Leafeon",     [471] = "Glaceon",     [472] = "Gliscor",     [473] = "Mamoswine",   [474] = "Porygon-Z",   
    [475] = "Gallade",     [476] = "Probopass",   [477] = "Dusknoir",    [478] = "Froslass",    [479] = "Rotom",       
    [480] = "Uxie",        [481] = "Mesprit",     [482] = "Azelf",       [483] = "Dialga",      [484] = "Palkia",      
    [485] = "Heatran",     [486] = "Regigigas",   [487] = "Giratina",    [488] = "Cresselia",   [489] = "Phione",      
    [490] = "Manaphy",     [491] = "Darkrai",     [492] = "Shaymin",     [493] = "Arceus",      [494] = "Pokémon Egg", 
    [495] = "Manaphy Egg", [496] = "Deoxys",      [497] = "Deoxys",      [498] = "Deoxys",      [499] = "Wormadam",    
    [500] = "Wormadam",    [501] = "Giratina",    [502] = "Shaymin",     [503] = "Rotom",       [504] = "Rotom",       
    [505] = "Rotom",       [506] = "Rotom",       [507] = "Rotom",       }

local ITEM = {
    [000] = "None",          [001] = "Master Ball",   [002] = "Ultra Ball",    [003] = "Great Ball",    [004] = "Poké Ball",     
    [005] = "Safari Ball",   [006] = "Net Ball",      [007] = "Dive Ball",     [008] = "Nest Ball",     [009] = "Repeat Ball",   
    [010] = "Timer Ball",    [011] = "Luxury Ball",   [012] = "Premier Ball",  [013] = "Dusk Ball",     [014] = "Heal Ball",     
    [015] = "Quick Ball",    [016] = "Cherish Ball",  [017] = "Potion",        [018] = "Antidote",      [019] = "Burn Heal",     
    [020] = "Ice Heal",      [021] = "Awakening",     [022] = "Parlyz Heal",   [023] = "Full Restore",  [024] = "Max Potion",    
    [025] = "Hyper Potion",  [026] = "Super Potion",  [027] = "Full Heal",     [028] = "Revive",        [029] = "Max Revive",    
    [030] = "Fresh Water",   [031] = "Soda Pop",      [032] = "Lemonade",      [033] = "Moomoo Milk",   [034] = "EnergyPowder",  
    [035] = "Energy Root",   [036] = "Heal Powder",   [037] = "Revival Herb",  [038] = "Ether",         [039] = "Max Ether",     
    [040] = "Elixir",        [041] = "Max Elixir",    [042] = "Lava Cookie",   [043] = "Berry Juice",   [044] = "Sacred Ash",    
    [045] = "HP Up",         [046] = "Protein",       [047] = "Iron",          [048] = "Carbos",        [049] = "Calcium",       
    [050] = "Rare Candy",    [051] = "PP Up",         [052] = "Zinc",          [053] = "PP Max",        [054] = "Old Gateau",    
    [055] = "Guard Spec.",   [056] = "Dire Hit",      [057] = "X Attack",      [058] = "X Defense",     [059] = "X Speed",       
    [060] = "X Accuracy",    [061] = "X Special",     [062] = "X Sp. Def",     [063] = "Poké Doll",     [064] = "Fluffy Tail",   
    [065] = "Blue Flute",    [066] = "Yellow Flute",  [067] = "Red Flute",     [068] = "Black Flute",   [069] = "White Flute",   
    [070] = "Shoal Salt",    [071] = "Shoal Shell",   [072] = "Red Shard",     [073] = "Blue Shard",    [074] = "Yellow Shard",  
    [075] = "Green Shard",   [076] = "Super Repel",   [077] = "Max Repel",     [078] = "Escape Rope",   [079] = "Repel",         
    [080] = "Sun Stone",     [081] = "Moon Stone",    [082] = "Fire Stone",    [083] = "Thunderstone",  [084] = "Water Stone",   
    [085] = "Leaf Stone",    [086] = "TinyMushroom",  [087] = "Big Mushroom",  [088] = "Pearl",         [089] = "Big Pearl",     
    [090] = "Stardust",      [091] = "Star Piece",    [092] = "Nugget",        [093] = "Heart Scale",   [094] = "Honey",         
    [095] = "Growth Mulch",  [096] = "Damp Mulch",    [097] = "Stable Mulch",  [098] = "Gooey Mulch",   [099] = "Root Fossil",   
    [100] = "Claw Fossil",   [101] = "Helix Fossil",  [102] = "Dome Fossil",   [103] = "Old Amber",     [104] = "Armor Fossil",  
    [105] = "Skull Fossil",  [106] = "Rare Bone",     [107] = "Shiny Stone",   [108] = "Dusk Stone",    [109] = "Dawn Stone",    
    [110] = "Oval Stone",    [111] = "Odd Keystone",  [112] = "Griseous Orb*", [113] = "unknown",       [114] = "unknown",       
    [115] = "unknown",       [116] = "unknown",       [117] = "unknown",       [118] = "unknown",       [119] = "unknown",       
    [120] = "unknown",       [121] = "unknown",       [122] = "unknown",       [123] = "unknown",       [124] = "unknown",       
    [125] = "unknown",       [126] = "unknown",       [127] = "unknown",       [128] = "unknown",       [129] = "unknown",       
    [130] = "unknown",       [131] = "unknown",       [132] = "unknown",       [133] = "unknown",       [134] = "unknown",       
    [135] = "Adamant Orb",   [136] = "Lustrous Orb",  [137] = "Grass Mail",    [138] = "Flame Mail",    [139] = "Bubble Mail",   
    [140] = "Bloom Mail",    [141] = "Tunnel Mail",   [142] = "Steel Mail",    [143] = "Heart Mail",    [144] = "Snow Mail",     
    [145] = "Space Mail",    [146] = "Air Mail",      [147] = "Mosaic Mail",   [148] = "Brick Mail",    [149] = "Cheri Berry",   
    [150] = "Chesto Berry",  [151] = "Pecha Berry",   [152] = "Rawst Berry",   [153] = "Aspear Berry",  [154] = "Leppa Berry",   
    [155] = "Oran Berry",    [156] = "Persim Berry",  [157] = "Lum Berry",     [158] = "Sitrus Berry",  [159] = "Figy Berry",    
    [160] = "Wiki Berry",    [161] = "Mago Berry",    [162] = "Aguav Berry",   [163] = "Iapapa Berry",  [164] = "Razz Berry",    
    [165] = "Bluk Berry",    [166] = "Nanab Berry",   [167] = "Wepear Berry",  [168] = "Pinap Berry",   [169] = "Pomeg Berry",   
    [170] = "Kelpsy Berry",  [171] = "Qualot Berry",  [172] = "Hondew Berry",  [173] = "Grepa Berry",   [174] = "Tamato Berry",  
    [175] = "Cornn Berry",   [176] = "Magost Berry",  [177] = "Rabuta Berry",  [178] = "Nomel Berry",   [179] = "Spelon Berry",  
    [180] = "Pamtre Berry",  [181] = "Watmel Berry",  [182] = "Durin Berry",   [183] = "Belue Berry",   [184] = "Occa Berry",    
    [185] = "Passho Berry",  [186] = "Wacan Berry",   [187] = "Rindo Berry",   [188] = "Yache Berry",   [189] = "Chople Berry",  
    [190] = "Kebia Berry",   [191] = "Shuca Berry",   [192] = "Coba Berry",    [193] = "Payapa Berry",  [194] = "Tanga Berry",   
    [195] = "Charti Berry",  [196] = "Kasib Berry",   [197] = "Haban Berry",   [198] = "Colbur Berry",  [199] = "Babiri Berry",  
    [200] = "Chilan Berry",  [201] = "Liechi Berry",  [202] = "Ganlon Berry",  [203] = "Salac Berry",   [204] = "Petaya Berry",  
    [205] = "Apicot Berry",  [206] = "Lansat Berry",  [207] = "Starf Berry",   [208] = "Enigma Berry",  [209] = "Micle Berry",   
    [210] = "Custap Berry",  [211] = "Jaboca Berry",  [212] = "Rowap Berry",   [213] = "BrightPowder",  [214] = "White Herb",    
    [215] = "Macho Brace",   [216] = "Exp. Share",    [217] = "Quick Claw",    [218] = "Soothe Bell",   [219] = "Mental Herb",   
    [220] = "Choice Band",   [221] = "King's Rock",   [222] = "SilverPowder",  [223] = "Amulet Coin",   [224] = "Cleanse Tag",   
    [225] = "Soul Dew",      [226] = "DeepSeaTooth",  [227] = "DeepSeaScale",  [228] = "Smoke Ball",    [229] = "Everstone",     
    [230] = "Focus Band",    [231] = "Lucky Egg",     [232] = "Scope Lens",    [233] = "Metal Coat",    [234] = "Leftovers",     
    [235] = "Dragon Scale",  [236] = "Light Ball",    [237] = "Soft Sand",     [238] = "Hard Stone",    [239] = "Miracle Seed",  
    [240] = "BlackGlasses",  [241] = "Black Belt",    [242] = "Magnet",        [243] = "Mystic Water",  [244] = "Sharp Beak",    
    [245] = "Poison Barb",   [246] = "NeverMeltIce",  [247] = "Spell Tag",     [248] = "TwistedSpoon",  [249] = "Charcoal",      
    [250] = "Dragon Fang",   [251] = "Silk Scarf",    [252] = "Up-Grade",      [253] = "Shell Bell",    [254] = "Sea Incense",   
    [255] = "Lax Incense",   [256] = "Lucky Punch",   [257] = "Metal Powder",  [258] = "Thick Club",    [259] = "Stick",         
    [260] = "Red Scarf",     [261] = "Blue Scarf",    [262] = "Pink Scarf",    [263] = "Green Scarf",   [264] = "Yellow Scarf",  
    [265] = "Wide Lens",     [266] = "Muscle Band",   [267] = "Wise Glasses",  [268] = "Expert Belt",   [269] = "Light Clay",    
    [270] = "Life Orb",      [271] = "Power Herb",    [272] = "Toxic Orb",     [273] = "Flame Orb",     [274] = "Quick Powder",  
    [275] = "Focus Sash",    [276] = "Zoom Lens",     [277] = "Metronome",     [278] = "Iron Ball",     [279] = "Lagging Tail",  
    [280] = "Destiny Knot",  [281] = "Black Sludge",  [282] = "Icy Rock",      [283] = "Smooth Rock",   [284] = "Heat Rock",     
    [285] = "Damp Rock",     [286] = "Grip Claw",     [287] = "Choice Scarf",  [288] = "Sticky Barb",   [289] = "Power Bracer",  
    [290] = "Power Belt",    [291] = "Power Lens",    [292] = "Power Band",    [293] = "Power Anklet",  [294] = "Power Weight",  
    [295] = "Shed Shell",    [296] = "Big Root",      [297] = "Choice Specs",  [298] = "Flame Plate",   [299] = "Splash Plate",  
    [300] = "Zap Plate",     [301] = "Meadow Plate",  [302] = "Icicle Plate",  [303] = "Fist Plate",    [304] = "Toxic Plate",   
    [305] = "Earth Plate",   [306] = "Sky Plate",     [307] = "Mind Plate",    [308] = "Insect Plate",  [309] = "Stone Plate",   
    [310] = "Spooky Plate",  [311] = "Draco Plate",   [312] = "Dread Plate",   [313] = "Iron Plate",    [314] = "Odd Incense",   
    [315] = "Rock Incense",  [316] = "Full Incense",  [317] = "Wave Incense",  [318] = "Rose Incense",  [319] = "Luck Incense",  
    [320] = "Pure Incense",  [321] = "Protector",     [322] = "Electirizer",   [323] = "Magmarizer",    [324] = "Dubious Disc",  
    [325] = "Reaper Cloth",  [326] = "Razor Claw",    [327] = "Razor Fang",    [328] = "TM01",          [329] = "TM02",          
    [330] = "TM03",          [331] = "TM04",          [332] = "TM05",          [333] = "TM06",          [334] = "TM07",          
    [335] = "TM08",          [336] = "TM09",          [337] = "TM10",          [338] = "TM11",          [339] = "TM12",          
    [340] = "TM13",          [341] = "TM14",          [342] = "TM15",          [343] = "TM16",          [344] = "TM17",          
    [345] = "TM18",          [346] = "TM19",          [347] = "TM20",          [348] = "TM21",          [349] = "TM22",          
    [350] = "TM23",          [351] = "TM24",          [352] = "TM25",          [353] = "TM26",          [354] = "TM27",          
    [355] = "TM28",          [356] = "TM29",          [357] = "TM30",          [358] = "TM31",          [359] = "TM32",          
    [360] = "TM33",          [361] = "TM34",          [362] = "TM35",          [363] = "TM36",          [364] = "TM37",          
    [365] = "TM38",          [366] = "TM39",          [367] = "TM40",          [368] = "TM41",          [369] = "TM42",          
    [370] = "TM43",          [371] = "TM44",          [372] = "TM45",          [373] = "TM46",          [374] = "TM47",          
    [375] = "TM48",          [376] = "TM49",          [377] = "TM50",          [378] = "TM51",          [379] = "TM52",          
    [380] = "TM53",          [381] = "TM54",          [382] = "TM55",          [383] = "TM56",          [384] = "TM57",          
    [385] = "TM58",          [386] = "TM59",          [387] = "TM60",          [388] = "TM61",          [389] = "TM62",          
    [390] = "TM63",          [391] = "TM64",          [392] = "TM65",          [393] = "TM66",          [394] = "TM67",          
    [395] = "TM68",          [396] = "TM69",          [397] = "TM70",          [398] = "TM71",          [399] = "TM72",          
    [400] = "TM73",          [401] = "TM74",          [402] = "TM75",          [403] = "TM76",          [404] = "TM77",          
    [405] = "TM78",          [406] = "TM79",          [407] = "TM80",          [408] = "TM81",          [409] = "TM82",          
    [410] = "TM83",          [411] = "TM84",          [412] = "TM85",          [413] = "TM86",          [414] = "TM87",          
    [415] = "TM88",          [416] = "TM89",          [417] = "TM90",          [418] = "TM91",          [419] = "TM92",          
    [420] = "HM01",          [421] = "HM02",          [422] = "HM03",          [423] = "HM04",          [424] = "HM05",          
    [425] = "HM06",          [426] = "HM07",          [427] = "HM08",          [428] = "Explorer Kit*", [429] = "Loot Sack",     
    [430] = "Rule Book",     [431] = "Poké Radar",    [432] = "Point Card",    [433] = "Journal",       [434] = "Seal Case",     
    [435] = "Fashion Case",  [436] = "Seal Bag",      [437] = "Pal Pad",       [438] = "Works Key",     [439] = "Old Charm",     
    [440] = "Galactic Key",  [441] = "Red Chain",     [442] = "Town Map",      [443] = "Vs. Seeker",    [444] = "Coin Case",     
    [445] = "Old Rod",       [446] = "Good Rod",      [447] = "Super Rod",     [448] = "Sprayduck",     [449] = "Poffin Case",   
    [450] = "Bicycle",       [451] = "Suite Key",     [452] = "Oak's Letter",  [453] = "Lunar Wing",    [454] = "Member Card",   
    [455] = "Azure Flute",   [456] = "S.S. Ticket",   [457] = "Contest Pass",  [458] = "Magma Stone",   [459] = "Parcel",        
    [460] = "Coupon 1",      [461] = "Coupon 2",      [462] = "Coupon 3",      [463] = "Storage Key",   [464] = "SecretPotion",  
    [465] = "Vs. Recorder*", [466] = "Gracidea*",     [467] = "Secret Key*",   [468] = "Apricorn Box*", [469] = "Unown Report*", 
    [470] = "Berry Pots*",   [471] = "Dowsing MCHN*", [472] = "Blue Card*",    [473] = "SlowpokeTail*", [474] = "Clear Bell*",   
    [475] = "Card Key*",     [476] = "Basement Key*", [477] = "SquirtBottle*", [478] = "Red Scale*",    [479] = "Lost Item*",    
    [480] = "Pass*",         [481] = "Machine Part*", [482] = "Silver Wing*",  [483] = "Rainbow Wing*", [484] = "Mystery Egg*",  
    [485] = "Red Apricorn*", [486] = "Ylw Apricorn*", [487] = "Blu Apricorn*", [488] = "Grn Apricorn*", [489] = "Pnk Apricorn*", 
    [490] = "Wht Apricorn*", [491] = "Blk Apricorn*", [492] = "Fast Ball*",    [493] = "Level Ball*",   [494] = "Lure Ball*",    
    [495] = "Heavy Ball*",   [496] = "Love Ball*",    [497] = "Friend Ball*",  [498] = "Moon Ball*",    [499] = "Sport Ball*",   
    [500] = "Park Ball*",    [501] = "Photo Album*",  [502] = "GB Sounds*",    [503] = "Tidal Bell*",   [504] = "RageCandyBar*", 
    [505] = "Data Card 01*", [506] = "Data Card 02*", [507] = "Data Card 03*", [508] = "Data Card 04*", [509] = "Data Card 05*", 
    [510] = "Data Card 06*", [511] = "Data Card 07*", [512] = "Data Card 08*", [513] = "Data Card 09*", [514] = "Data Card 10*", 
    [515] = "Data Card 11*", [516] = "Data Card 12*", [517] = "Data Card 13*", [518] = "Data Card 14*", [519] = "Data Card 15*", 
    [520] = "Data Card 16*", [521] = "Data Card 17*", [522] = "Data Card 18*", [523] = "Data Card 19*", [524] = "Data Card 20*", 
    [525] = "Data Card 21*", [526] = "Data Card 22*", [527] = "Data Card 23*", [528] = "Data Card 24*", [529] = "Data Card 25*", 
    [530] = "Data Card 26*", [531] = "Data Card 27*", [532] = "Jade Orb*",     [533] = "Lock Capsule*", [534] = "Red Orb*",      
    [535] = "Blue Orb*",     [536] = "Enigma Stone*", }


local MOVE = {
    [0] = "????",
    [1] = "Pound",            [2] = "Karate Chop",      [3] = "Double Slap",      [4] = "Comet Punch",      [5] = "Mega Punch",       
    [6] = "Pay Day",          [7] = "Fire Punch",       [8] = "Ice Punch",        [9] = "Thunder Punch",    [10] = "Scratch",         
    [11] = "Vise Grip",       [12] = "Guillotine",      [13] = "Razor Wind",      [14] = "Swords Dance",    [15] = "Cut",             
    [16] = "Gust",            [17] = "Wing Attack",     [18] = "Whirlwind",       [19] = "Fly",             [20] = "Bind",            
    [21] = "Slam",            [22] = "Vine Whip",       [23] = "Stomp",           [24] = "Double Kick",     [25] = "Mega Kick",       
    [26] = "Jump Kick",       [27] = "Rolling Kick",    [28] = "Sand Attack",     [29] = "Headbutt",        [30] = "Horn Attack",     
    [31] = "Fury Attack",     [32] = "Horn Drill",      [33] = "Tackle",          [34] = "Body Slam",       [35] = "Wrap",            
    [36] = "Take Down",       [37] = "Thrash",          [38] = "Double-Edge",     [39] = "Tail Whip",       [40] = "Poison Sting",    
    [41] = "Twineedle",       [42] = "Pin Missile",     [43] = "Leer",            [44] = "Bite",            [45] = "Growl",           
    [46] = "Roar",            [47] = "Sing",            [48] = "Supersonic",      [49] = "Sonic Boom",      [50] = "Disable",         
    [51] = "Acid",            [52] = "Ember",           [53] = "Flamethrower",    [54] = "Mist",            [55] = "Water Gun",       
    [56] = "Hydro Pump",      [57] = "Surf",            [58] = "Ice Beam",        [59] = "Blizzard",        [60] = "Psybeam",         
    [61] = "Bubble Beam",     [62] = "Aurora Beam",     [63] = "Hyper Beam",      [64] = "Peck",            [65] = "Drill Peck",      
    [66] = "Submission",      [67] = "Low Kick",        [68] = "Counter",         [69] = "Seismic Toss",    [70] = "Strength",        
    [71] = "Absorb",          [72] = "Mega Drain",      [73] = "Leech Seed",      [74] = "Growth",          [75] = "Razor Leaf",      
    [76] = "Solar Beam",      [77] = "Poison Powder",   [78] = "Stun Spore",      [79] = "Sleep Powder",    [80] = "Petal Dance",     
    [81] = "String Shot",     [82] = "Dragon Rage",     [83] = "Fire Spin",       [84] = "Thunder Shock",   [85] = "Thunderbolt",     
    [86] = "Thunder Wave",    [87] = "Thunder",         [88] = "Rock Throw",      [89] = "Earthquake",      [90] = "Fissure",         
    [91] = "Dig",             [92] = "Toxic",           [93] = "Confusion",       [94] = "Psychic",         [95] = "Hypnosis",        
    [96] = "Meditate",        [97] = "Agility",         [98] = "Quick Attack",    [99] = "Rage",            [100] = "Teleport",       
    [101] = "Night Shade",    [102] = "Mimic",          [103] = "Screech",        [104] = "Double Team",    [105] = "Recover",        
    [106] = "Harden",         [107] = "Minimize",       [108] = "Smokescreen",    [109] = "Confuse Ray",    [110] = "Withdraw",       
    [111] = "Defense Curl",   [112] = "Barrier",        [113] = "Light Screen",   [114] = "Haze",           [115] = "Reflect",        
    [116] = "Focus Energy",   [117] = "Bide",           [118] = "Metronome",      [119] = "Mirror Move",    [120] = "Self-Destruct",  
    [121] = "Egg Bomb",       [122] = "Lick",           [123] = "Smog",           [124] = "Sludge",         [125] = "Bone Club",      
    [126] = "Fire Blast",     [127] = "Waterfall",      [128] = "Clamp",          [129] = "Swift",          [130] = "Skull Bash",     
    [131] = "Spike Cannon",   [132] = "Constrict",      [133] = "Amnesia",        [134] = "Kinesis",        [135] = "Soft-Boiled",    
    [136] = "High Jump Kick", [137] = "Glare",          [138] = "Dream Eater",    [139] = "Poison Gas",     [140] = "Barrage",        
    [141] = "Leech Life",     [142] = "Lovely Kiss",    [143] = "Sky Attack",     [144] = "Transform",      [145] = "Bubble",         
    [146] = "Dizzy Punch",    [147] = "Spore",          [148] = "Flash",          [149] = "Psywave",        [150] = "Splash",         
    [151] = "Acid Armor",     [152] = "Crabhammer",     [153] = "Explosion",      [154] = "Fury Swipes",    [155] = "Bonemerang",     
    [156] = "Rest",           [157] = "Rock Slide",     [158] = "Hyper Fang",     [159] = "Sharpen",        [160] = "Conversion",     
    [161] = "Tri Attack",     [162] = "Super Fang",     [163] = "Slash",          [164] = "Substitute",     [165] = "Struggle",       
    [166] = "Sketch",         [167] = "Triple Kick",    [168] = "Thief",          [169] = "Spider Web",     [170] = "Mind Reader",    
    [171] = "Nightmare",      [172] = "Flame Wheel",    [173] = "Snore",          [174] = "Curse",          [175] = "Flail",          
    [176] = "Conversion 2",   [177] = "Aeroblast",      [178] = "Cotton Spore",   [179] = "Reversal",       [180] = "Spite",          
    [181] = "Powder Snow",    [182] = "Protect",        [183] = "Mach Punch",     [184] = "Scary Face",     [185] = "Feint Attack",   
    [186] = "Sweet Kiss",     [187] = "Belly Drum",     [188] = "Sludge Bomb",    [189] = "Mud-Slap",       [190] = "Octazooka",      
    [191] = "Spikes",         [192] = "Zap Cannon",     [193] = "Foresight",      [194] = "Destiny Bond",   [195] = "Perish Song",    
    [196] = "Icy Wind",       [197] = "Detect",         [198] = "Bone Rush",      [199] = "Lock-On",        [200] = "Outrage",        
    [201] = "Sandstorm",      [202] = "Giga Drain",     [203] = "Endure",         [204] = "Charm",          [205] = "Rollout",        
    [206] = "False Swipe",    [207] = "Swagger",        [208] = "Milk Drink",     [209] = "Spark",          [210] = "Fury Cutter",    
    [211] = "Steel Wing",     [212] = "Mean Look",      [213] = "Attract",        [214] = "Sleep Talk",     [215] = "Heal Bell",      
    [216] = "Return",         [217] = "Present",        [218] = "Frustration",    [219] = "Safeguard",      [220] = "Pain Split",     
    [221] = "Sacred Fire",    [222] = "Magnitude",      [223] = "Dynamic Punch",  [224] = "Megahorn",       [225] = "Dragon Breath",  
    [226] = "Baton Pass",     [227] = "Encore",         [228] = "Pursuit",        [229] = "Rapid Spin",     [230] = "Sweet Scent",    
    [231] = "Iron Tail",      [232] = "Metal Claw",     [233] = "Vital Throw",    [234] = "Morning Sun",    [235] = "Synthesis",      
    [236] = "Moonlight",      [237] = "Hidden Power",   [238] = "Cross Chop",     [239] = "Twister",        [240] = "Rain Dance",     
    [241] = "Sunny Day",      [242] = "Crunch",         [243] = "Mirror Coat",    [244] = "Psych Up",       [245] = "Extreme Speed",  
    [246] = "Ancient Power",  [247] = "Shadow Ball",    [248] = "Future Sight",   [249] = "Rock Smash",     [250] = "Whirlpool",      
    [251] = "Beat Up",        [252] = "Fake Out",       [253] = "Uproar",         [254] = "Stockpile",      [255] = "Spit Up",        
    [256] = "Swallow",        [257] = "Heat Wave",      [258] = "Hail",           [259] = "Torment",        [260] = "Flatter",        
    [261] = "Will-O-Wisp",    [262] = "Memento",        [263] = "Facade",         [264] = "Focus Punch",    [265] = "Smelling Salts", 
    [266] = "Follow Me",      [267] = "Nature Power",   [268] = "Charge",         [269] = "Taunt",          [270] = "Helping Hand",   
    [271] = "Trick",          [272] = "Role Play",      [273] = "Wish",           [274] = "Assist",         [275] = "Ingrain",        
    [276] = "Superpower",     [277] = "Magic Coat",     [278] = "Recycle",        [279] = "Revenge",        [280] = "Brick Break",    
    [281] = "Yawn",           [282] = "Knock Off",      [283] = "Endeavor",       [284] = "Eruption",       [285] = "Skill Swap",     
    [286] = "Imprison",       [287] = "Refresh",        [288] = "Grudge",         [289] = "Snatch",         [290] = "Secret Power",   
    [291] = "Dive",           [292] = "Arm Thrust",     [293] = "Camouflage",     [294] = "Tail Glow",      [295] = "Luster Purge",   
    [296] = "Mist Ball",      [297] = "Feather Dance",  [298] = "Teeter Dance",   [299] = "Blaze Kick",     [300] = "Mud Sport",      
    [301] = "Ice Ball",       [302] = "Needle Arm",     [303] = "Slack Off",      [304] = "Hyper Voice",    [305] = "Poison Fang",    
    [306] = "Crush Claw",     [307] = "Blast Burn",     [308] = "Hydro Cannon",   [309] = "Meteor Mash",    [310] = "Astonish",       
    [311] = "Weather Ball",   [312] = "Aromatherapy",   [313] = "Fake Tears",     [314] = "Air Cutter",     [315] = "Overheat",       
    [316] = "Odor Sleuth",    [317] = "Rock Tomb",      [318] = "Silver Wind",    [319] = "Metal Sound",    [320] = "Grass Whistle",  
    [321] = "Tickle",         [322] = "Cosmic Power",   [323] = "Water Spout",    [324] = "Signal Beam",    [325] = "Shadow Punch",   
    [326] = "Extrasensory",   [327] = "Sky Uppercut",   [328] = "Sand Tomb",      [329] = "Sheer Cold",     [330] = "Muddy Water",    
    [331] = "Bullet Seed",    [332] = "Aerial Ace",     [333] = "Icicle Spear",   [334] = "Iron Defense",   [335] = "Block",          
    [336] = "Howl",           [337] = "Dragon Claw",    [338] = "Frenzy Plant",   [339] = "Bulk Up",        [340] = "Bounce",         
    [341] = "Mud Shot",       [342] = "Poison Tail",    [343] = "Covet",          [344] = "Volt Tackle",    [345] = "Magical Leaf",   
    [346] = "Water Sport",    [347] = "Calm Mind",      [348] = "Leaf Blade",     [349] = "Dragon Dance",   [350] = "Rock Blast",     
    [351] = "Shock Wave",     [352] = "Water Pulse",    [353] = "Doom Desire",    [354] = "Psycho Boost",   [355] = "Roost",          
    [356] = "Gravity",        [357] = "Miracle Eye",    [358] = "Wake-Up Slap",   [359] = "Hammer Arm",     [360] = "Gyro Ball",      
    [361] = "Healing Wish",   [362] = "Brine",          [363] = "Natural Gift",   [364] = "Feint",          [365] = "Pluck",          
    [366] = "Tailwind",       [367] = "Acupressure",    [368] = "Metal Burst",    [369] = "U-turn",         [370] = "Close Combat",   
    [371] = "Payback",        [372] = "Assurance",      [373] = "Embargo",        [374] = "Fling",          [375] = "Psycho Shift",   
    [376] = "Trump Card",     [377] = "Heal Block",     [378] = "Wring Out",      [379] = "Power Trick",    [380] = "Gastro Acid",    
    [381] = "Lucky Chant",    [382] = "Me First",       [383] = "Copycat",        [384] = "Power Swap",     [385] = "Guard Swap",     
    [386] = "Punishment",     [387] = "Last Resort",    [388] = "Worry Seed",     [389] = "Sucker Punch",   [390] = "Toxic Spikes",   
    [391] = "Heart Swap",     [392] = "Aqua Ring",      [393] = "Magnet Rise",    [394] = "Flare Blitz",    [395] = "Force Palm",     
    [396] = "Aura Sphere",    [397] = "Rock Polish",    [398] = "Poison Jab",     [399] = "Dark Pulse",     [400] = "Night Slash",    
    [401] = "Aqua Tail",      [402] = "Seed Bomb",      [403] = "Air Slash",      [404] = "X-Scissor",      [405] = "Bug Buzz",       
    [406] = "Dragon Pulse",   [407] = "Dragon Rush",    [408] = "Power Gem",      [409] = "Drain Punch",    [410] = "Vacuum Wave",    
    [411] = "Focus Blast",    [412] = "Energy Ball",    [413] = "Brave Bird",     [414] = "Earth Power",    [415] = "Switcheroo",     
    [416] = "Giga Impact",    [417] = "Nasty Plot",     [418] = "Bullet Punch",   [419] = "Avalanche",      [420] = "Ice Shard",      
    [421] = "Shadow Claw",    [422] = "Thunder Fang",   [423] = "Ice Fang",       [424] = "Fire Fang",      [425] = "Shadow Sneak",   
    [426] = "Mud Bomb",       [427] = "Psycho Cut",     [428] = "Zen Headbutt",   [429] = "Mirror Shot",    [430] = "Flash Cannon",   
    [431] = "Rock Climb",     [432] = "Defog",          [433] = "Trick Room",     [434] = "Draco Meteor",   [435] = "Discharge",      
    [436] = "Lava Plume",     [437] = "Leaf Storm",     [438] = "Power Whip",     [439] = "Rock Wrecker",   [440] = "Cross Poison",   
    [441] = "Gunk Shot",      [442] = "Iron Head",      [443] = "Magnet Bomb",    [444] = "Stone Edge",     [445] = "Captivate",      
    [446] = "Stealth Rock",   [447] = "Grass Knot",     [448] = "Chatter",        [449] = "Judgment",       [450] = "Bug Bite",       
    [451] = "Charge Beam",    [452] = "Wood Hammer",    [453] = "Aqua Jet",       [454] = "Attack Order",   [455] = "Defend Order",   
    [456] = "Heal Order",     [457] = "Head Smash",     [458] = "Double Hit",     [459] = "Roar of Time",   [460] = "Spacial Rend",   
    [461] = "Lunar Dance",    [462] = "Crush Grip",     [463] = "Magma Storm",    [464] = "Dark Void",      [465] = "Seed Flare",     
    [466] = "Ominous Wind",   [467] = "Shadow Force",   }

local ABILITY = {
    [0] = "????",
    [1] = "Stench",           [2] = "Drizzle",          [3] = "Speed Boost",      [4] = "Battle Armor",     [5] = "Sturdy",           
    [6] = "Damp",             [7] = "Limber",           [8] = "Sand Veil",        [9] = "Static",           [10] = "Volt Absorb",     
    [11] = "Water Absorb",    [12] = "Oblivious",       [13] = "Cloud Nine",      [14] = "Compound Eyes",   [15] = "Insomnia",        
    [16] = "Color Change",    [17] = "Immunity",        [18] = "Flash Fire",      [19] = "Shield Dust",     [20] = "Own Tempo",       
    [21] = "Suction Cups",    [22] = "Intimidate",      [23] = "Shadow Tag",      [24] = "Rough Skin",      [25] = "Wonder Guard",    
    [26] = "Levitate",        [27] = "Effect Spore",    [28] = "Synchronize",     [29] = "Clear Body",      [30] = "Natural Cure",    
    [31] = "Lightning Rod",   [32] = "Serene Grace",    [33] = "Swift Swim",      [34] = "Chlorophyll",     [35] = "Illuminate",      
    [36] = "Trace",           [37] = "Huge Power",      [38] = "Poison Point",    [39] = "Inner Focus",     [40] = "Magma Armor",     
    [41] = "Water Veil",      [42] = "Magnet Pull",     [43] = "Soundproof",      [44] = "Rain Dish",       [45] = "Sand Stream",     
    [46] = "Pressure",        [47] = "Thick Fat",       [48] = "Early Bird",      [49] = "Flame Body",      [50] = "Run Away",        
    [51] = "Keen Eye",        [52] = "Hyper Cutter",    [53] = "Pickup",          [54] = "Truant",          [55] = "Hustle",          
    [56] = "Cute Charm",      [57] = "Plus",            [58] = "Minus",           [59] = "Forecast",        [60] = "Sticky Hold",     
    [61] = "Shed Skin",       [62] = "Guts",            [63] = "Marvel Scale",    [64] = "Liquid Ooze",     [65] = "Overgrow",        
    [66] = "Blaze",           [67] = "Torrent",         [68] = "Swarm",           [69] = "Rock Head",       [70] = "Drought",         
    [71] = "Arena Trap",      [72] = "Vital Spirit",    [73] = "White Smoke",     [74] = "Pure Power",      [75] = "Shell Armor",     
    [76] = "Air Lock",        [77] = "Tangled Feet",    [78] = "Motor Drive",     [79] = "Rivalry",         [80] = "Steadfast",       
    [81] = "Snow Cloak",      [82] = "Gluttony",        [83] = "Anger Point",     [84] = "Unburden",        [85] = "Heatproof",       
    [86] = "Simple",          [87] = "Dry Skin",        [88] = "Download",        [89] = "Iron Fist",       [90] = "Poison Heal",     
    [91] = "Adaptability",    [92] = "Skill Link",      [93] = "Hydration",       [94] = "Solar Power",     [95] = "Quick Feet",      
    [96] = "Normalize",       [97] = "Sniper",          [98] = "Magic Guard",     [99] = "No Guard",        [100] = "Stall",          
    [101] = "Technician",     [102] = "Leaf Guard",     [103] = "Klutz",          [104] = "Mold Breaker",   [105] = "Super Luck",     
    [106] = "Aftermath",      [107] = "Anticipation",   [108] = "Forewarn",       [109] = "Unaware",        [110] = "Tinted Lens",    
    [111] = "Filter",         [112] = "Slow Start",     [113] = "Scrappy",        [114] = "Storm Drain",    [115] = "Ice Body",       
    [116] = "Solid Rock",     [117] = "Snow Warning",   [118] = "Honey Gather",   [119] = "Frisk",          [120] = "Reckless",       
    [121] = "Multitype",      [122] = "Flower Gift",    [123] = "Bad Dreams",     }        

local TYPE = {
    [0] = "Normal", [1] = "Fighting", [2] = "Flying", [3] = "Poison",    [4] = "Ground",   [5] = "Rock", [6] = "Bug",     [7] = "Ghost", [8] = "Steel",
    [9] = "???",
    [10] = "Fire",  [11] = "Water",   [12] = "Grass", [13] = "Electric", [14] = "Psychic", [15] = "Ice", [16] = "Dragon", [17] = "Dark"
}

---@class pokemon
---@field personality     integer
---@field nature          string
---@field otid            integer
---@field secret          integer                   secret id
---@field language        string
---@field checksum        integer
---@field level           integer
---@field stat            table<string, integer>
---@field species_ind     integer                   index of species
---@field species         string
---@field type1_ind       integer                   index of first type
---@field type2_ind       integer                   index of second type. if monotyped, type2 will coincide with type1
---@field type1           string
---@field type2           string
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
---@field ability_ind     integer                   index of ability (https://bulbapedia.bulbagarden.net/wiki/Ability#List_of_Abilities)
---@field ability         string
---@field ev_yield        table<string, integer>
---@field status          integer                   https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_structure_(Generation_III)#Status_condition
local pokemon = {}
pokemon.__index = pokemon
local pokemon_fields = {"personality", "nature", "otid", "language", "checksum", "species",
                         "item", "ev", "iv", "ability", "ev_yield", "stat", "moves", "type1",
                         "type2", "exp", "exp_group", "base_exp_yield", "friendship", "egg",
                         "gender", "secret", "beauty"}

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

local CHUNK_MAP_INV = {
    [0] = {0, 1, 2, 3},
    [1] = {0, 1, 3, 2},
    [2] = {0, 2, 1, 3},
    [3] = {0, 2, 3, 1},
    [4] = {0, 3, 1, 2},
    [5] = {0, 3, 2, 1},
    [6] = {1, 0, 2, 3},
    [7] = {1, 0, 3, 2},
    [8] = {1, 2, 0, 3},
    [9] = {1, 2, 3, 0},
    [10] = {1, 3, 0, 2},
    [11] = {1, 3, 2, 0},
    [12] = {2, 0, 1, 3},
    [13] = {2, 0, 3, 1},
    [14] = {2, 1, 0, 3},
    [15] = {2, 1, 3, 0},
    [16] = {2, 3, 0, 1},
    [17] = {2, 3, 1, 0},
    [18] = {3, 0, 1, 2},
    [19] = {3, 0, 2, 1},
    [20] = {3, 1, 0, 2},
    [21] = {3, 1, 2, 0},
    [22] = {3, 2, 0, 1},
    [23] = {3, 2, 1, 0}
}

---@return integer A, integer B, integer C, integer D
--- Returns the locations of the data substructures corresponding to the pokemon at *poke_loc*. Return looks like
---```lua
---    return A, B, C, D
---```
---see https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_structure_(Generation_IV)
local function getSubstructureLocations(poke_loc, inv)
    local chunk_map = CHUNK_MAP
    if inv then
        chunk_map = CHUNK_MAP_INV
    end
    local personality = read32(poke_loc)
    local order = ((personality & 0x3E000) >> 0xD) % 24
    local function align(chunk_order)
        local res = {}
        for i, value in ipairs(chunk_order) do
            res[i] = (value * 32)
        end
        return res
    end
    local locs = align(chunk_map[order])
    return locs[1], locs[2], locs[3], locs[4]
end

--- Returns 236 byte array of decrypted data (first 8 are unencrypted always)
local function decryptData(poke_loc)
    local data = {}
    for i = 0, 7, 1 do
        data[i] = read8(poke_loc + i)
    end
    local start = poke_loc + 8
    local X = {}
    local checksum = read16(poke_loc + 6)
    X[0] = checksum

    for i = 0, 63, 1 do
        X[i+1] = (0x41C64E6D * X[i] + 0x6073) & 0xFFFFFFFF
        local bits = read16(start + (2*i)) ~ (X[i+1] >> 16)
        data[8 + (2*i + 0)] = bits & 0xFF
        data[8 + (2*i + 1)] = (bits >> 8) & 0xFF
    end

    local A, B, C, D = getSubstructureLocations(poke_loc)
    local shuffle_data = {}
    for i = 0, 7, 1 do
        shuffle_data[i] = data[i]
    end
    for i = 8, 8 + 31, 1 do
        shuffle_data[i] = data[i + A]
    end
    for i = 8 + 32, 8 + 32 + 31, 1 do
        shuffle_data[i] = data[i + B - 32]
    end
    for i = 8 + 64, 8 + 64 + 31, 1 do
        shuffle_data[i] = data[i + C - 64]
    end
    for i = 8 + 96, 8 + 96 + 31, 1 do
        shuffle_data[i] = data[i + D - 96]
    end

    -- Battle stats
    X = {}
    local personality = read32(poke_loc)
    X[0] = personality
    start = poke_loc + 0x88
    for i = 0, 49, 1 do
        X[i+1] = (0x41C64E6D * X[i] + 0x6073) & 0xFFFFFFFF
        local bits = read16(start + (2*i)) ~ (X[i+1] >> 16)
        shuffle_data[0x88 + (2*i + 0)] = bits & 0xFF
        shuffle_data[0x88 + (2*i + 1)] = (bits >> 8) & 0xFF
    end

    return shuffle_data
end

-- For use with data object returned from decryptData.  
-- Interprets *data* as a lil endian byte array and reads *length* bytes starting from *offset* (max 4 bytes)
local function readData(data, offset, length)
    assert(length == 0 or length == 1 or length == 2 or length == 3 or length == 4, "Invalid length for data read: "..length)
    local res = 0
    for i = 0, length - 1, 1 do
        res = res + (data[offset + i] << (8*i))
    end
    return res
end

--- See https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_structure_(Generation_IV)
---@param loc? integer location in memory of desired pokemon (defaults to front of party)
---@return pokemon # Pokemon structure that contains whatever I feel like honestly (at least IVs and EVs and ability)
function readPoke(loc)
    loc = loc or read32(BASE_PTR) + FRONT_OFF
    local poke = {}
    setmetatable(poke, pokemon)

    local data = decryptData(loc)
    local grab8 = function(offset) return readData(data, offset, 1) end
    local grab16 = function(offset) return readData(data, offset, 2) end
    local grab32 = function(offset) return readData(data, offset, 4) end
        
    poke.personality = grab32(0x0)
    poke.checksum = grab16(0x6)

    -- Block A
    poke.species_ind = grab16(0x08)
    poke.species = POKEDEX[poke.species_ind]
    poke.item_ind = grab16(0x0A)
    poke.item = ITEM[poke.item_ind]
    poke.otid = grab16(0x0C)
    poke.secret = grab16(0x0E)
    poke.exp = grab32(0x10)
    poke.friendship = grab8(0x14)
    poke.ev = {}
    poke.ev.hp = grab8(0x18)
    poke.ev.atk = grab8(0x19)
    poke.ev.def = grab8(0x1A)
    poke.ev.spe = grab8(0x1B)
    poke.ev.spa = grab8(0x1C)
    poke.ev.spd = grab8(0x1D)
    poke.beauty = grab8(0x1F)

    -- Block B
    local iv_bits = grab32(0x38)
    poke.iv = {}
    poke.iv.hp = (iv_bits >> 0) & 0x1F
    poke.iv.atk = (iv_bits >> 5) & 0x1F
    poke.iv.def = (iv_bits >> 10) & 0x1F
    poke.iv.spe = (iv_bits >> 15) & 0x1F
    poke.iv.spa = (iv_bits >> 20) & 0x1F
    poke.iv.spd = (iv_bits >> 25) & 0x1F

    -- Battle stats
    poke.stat = {}
    poke.stat.curr_hp = grab16(0x8E)
    poke.stat.hp = grab16(0x90)
    poke.stat.atk = grab16(0x92)
    poke.stat.def = grab16(0x94)
    poke.stat.spe = grab16(0x96)
    poke.stat.spa = grab16(0x98)
    poke.stat.spd = grab16(0x9A)

    -- Species struct (https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_species_data_structure_(Generation_IV))
    local species = SPECIES_ROM + (poke.species_ind * 44)
    poke.type1_ind = read8(species + 6, "ROM")
    poke.type2_ind = read8(species + 7, "ROM")
    poke.type1 = TYPE[poke.type1_ind]
    poke.type2 = TYPE[poke.type2_ind]
    poke.base_exp_yield = read8(species + 9, "ROM")
    local ev_bits = read16(species + 10, "ROM")
    poke.ev_yield = {}
    poke.ev_yield.hp = (ev_bits >> 0) & 0x3
    poke.ev_yield.atk = (ev_bits >> 2) & 0x3
    poke.ev_yield.def = (ev_bits >> 4) & 0x3
    poke.ev_yield.spe = (ev_bits >> 6) & 0x3
    poke.ev_yield.spa = (ev_bits >> 8) & 0x3
    poke.ev_yield.spd = (ev_bits >> 10) & 0x3
    poke.exp_group = read8(species + 19, "ROM")
    local ability1 = read8(species + 22, "ROM")
    local ability2 = read8(species + 23, "ROM")
    if (ability2 == 0) or (poke.personality % 2 == 0) then
        poke.ability_ind = ability1
    else
        poke.ability_ind = ability2
    end
    poke.ability = ABILITY[poke.ability_ind]

    return poke
end

-- Returns true if any field of *self* is nil, false otherwise
---@return boolean
function pokemon:checkFields(fields)
    fields = fields or pokemon_fields
    for _, value in ipairs(fields) do
        if self[value] == nil then
            return true
        end
    end
    return false
end

function pokemon:sumEV()
    local sum = 0
    for _, ev in pairs(self.ev) do
        sum = sum + ev
    end
    return sum
end

function pokemon:isShiny()
    local id = self.otid & 0xFFFF
    local sid = self.secret
    local p1 = self.personality & 0xFFFF
    local p2 = self.personality >> 16
    return (id ~ sid ~ p1 ~ p2) < 8
end

-- data should 236 byte array, unencrypted, in ABCD order (as returned by decryptData). Will fix checksum.
local function writeNewPokeData(data, loc)

    local checksum = 0
    for i = 0x8, 0x86, 2 do
        checksum = checksum + readData(data, i, 2)
    end
    checksum = checksum & 0xFFFF
    data[6] = checksum & 0xFF
    data[7] = checksum >> 8
    for i = 0, 7, 1 do
        write8(loc + i, data[i])
    end

    local block1, block2, block3, block4 = getSubstructureLocations(loc, true)
    local X = {}
    table.insert(X, checksum)
    for i = 8, 8 + 30, 2 do
        X[#X+1] = (0x41C64E6D * X[#X] + 0x6073) & 0xFFFFFFFF
        local bits = readData(data, i + block1, 2) ~ (X[#X] >> 16)
        bits = bits & 0xFFFF
        write16(loc + i, bits)
    end
    for i = 8 + 32, 8 + 62, 2 do
        X[#X+1] = (0x41C64E6D * X[#X] + 0x6073) & 0xFFFFFFFF
        local bits = readData(data, i - 32 + block2, 2) ~ (X[#X] >> 16)
        bits = bits & 0xFFFF
        write16(loc + i, bits)
    end
    for i = 8 + 64, 8 + 94, 2 do
        X[#X+1] = (0x41C64E6D * X[#X] + 0x6073) & 0xFFFFFFFF
        local bits = readData(data, i - 64 + block3, 2) ~ (X[#X] >> 16)
        bits = bits & 0xFFFF
        write16(loc + i, bits)
    end
    for i = 8 + 96, 8 + 126, 2 do
        X[#X+1] = (0x41C64E6D * X[#X] + 0x6073) & 0xFFFFFFFF
        local bits = readData(data, i - 96 + block4, 2) ~ (X[#X] >> 16)
        bits = bits & 0xFFFF
        write16(loc + i, bits)
    end

    X = {}
    local personality = readData(data, 0, 4)
    table.insert(X, personality)
    for i = 0x88, 0x88 + 98, 2 do
        X[#X+1] = (0x41C64E6D * X[#X] + 0x6073) & 0xFFFFFFFF
        local bits = readData(data, i, 2) ~ (X[#X] >> 16)
        bits = bits & 0xFFFF
        write16(loc + i, bits)
    end

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
    assert(new_move_ind >= 0 and new_move_ind <= 467, "new_move_ind must be between 0 and 467.")

    local poke = readPoke(poke_loc)
    console.log(string.format("Changing move %d of %s to %s", move_ind, poke.species, MOVE[new_move_ind]))

    local data = decryptData(poke_loc)
    local off = 0x28 + (move_ind - 1) * 2
    data[off] = new_move_ind & 0xFF
    data[off + 1] = new_move_ind >> 8

    data[0x30 + (move_ind - 1)] = 0     -- set pp to 0

    writeNewPokeData(data, poke_loc)
end

-- Changes front pokemon's *move_ind* move to *new_move*
---@param move_ind integer 1, 2, 3, or 4
---@param new_move string name of new move (case and whitespace insensitive ["ancientpower" will work for "Ancient Power"])
function changeFrontMove(move_ind, new_move)
    new_move_test = new_move:gsub("%s", ""):lower()

    local new_move_ind = -1
    for key, value in pairs(MOVE) do
        if new_move_test == value:gsub("%s", ""):lower() then
            new_move_ind = key
            break
        end
    end

    if new_move_ind == -1 then
        console.log(string.format("Could not locate move \"%s\"", new_move))
        return
    end

    changeMove(read32(BASE_PTR) + FRONT_OFF, move_ind, new_move_ind)
end

-- Maxes all IVs to 31 of the pokemon at *poke_loc* in memory
local function maxIVs(poke_loc)
    local poke = readPoke(poke_loc)
    console.log(string.format("Maxing %s's IVs", poke.species))

    data = decryptData(poke_loc)
    data[0x38] = data[0x38] | 0x3FFFFFFF        -- set last 30 bits (iv bits) to 1, don't touch highest 2
    writeNewPokeData(data, poke_loc)
end

-- Maxes all IVs of pokemon at front of party
function maxFrontIVs()
    maxIVs(read32(BASE_PTR) + FRONT_OFF)
end

-- returns pokemon object for front of party
function readFront()
    local base = read32(BASE_PTR)
    local off = base + FRONT_OFF
    if PARTY_TRACK then
        local ind = read8(base + PARTY_TRACK)
        off = off + (POKE_SIZE * ind)
    end
    return readPoke(off)
end

function readEnemy()
    local base = read32(BASE_PTR)
    local off = base + ENEMY_OFF
    if ENEMY_TRACK then
        local ind = read8(base + ENEMY_TRACK)
        off = off + (POKE_SIZE * ind)
    end
    return readPoke(off)
end
