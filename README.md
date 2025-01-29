## Introduction
These are scripts for Gen III/IV Pokémon games (EN-US versions).

This is designed for use with the [mGBA emulator](https://mgba.io/) ([GitHub](https://github.com/mgba-emu/mgba)) v0.10 for Gen III, and [BizHawk](https://tasvideos.org/Bizhawk) ([GitHub](https://github.com/TASEmulators/BizHawk)) for the DS games (Gen IV only right now).

After writing the EV/IV display script for Gen III (using the [Bulbapedia page](https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_data_structure_(Generation_III))), I found a [very similar script](https://github.com/mgba-emu/mgba/blob/master/res/scripts/pokemon.lua) on the mGBA GitHub page by [endrift](https://github.com/endrift), which I've copied here because I am a bamf. After nearly deleting my work and throwing my laptop at the wall, I had a change of heart, since that script didn't actually display the EVs nor the IVs, which I find most a most helpful inclusion.

## How to use
*stat_display.lua* has updating EV/IV displays for both party and opponent/wild Pokémon.

*daycare.lua* will automatically run the daycare paths (long horizontal right under the daycare in RSE, vertical underground tunnel in FRLG).

*modify_mon.lua* shows some uses of functions to change Pokémon moves and IVs. It directly modifies data and is definitely cheating so be careful.

*search_mem.lua* is in Gen IV for searching the RAM because when I tried to using the tool in EmuHawk, the option for the proper RAM is greyed out.

*shiny_scripts* contains scripts for auto shiny hunting. In Emerald this is nontrivial because of the goofy way it handles rng, so that's mainly my interest.

## Future
If I really no-life it I would like to add a comparable Gen V script.

Maybe also look into DeSmuME/other emulators, as the only change should be the functions for reading the RAM.