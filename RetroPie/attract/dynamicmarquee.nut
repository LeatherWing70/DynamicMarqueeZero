local has_moved = false;
local load_timer_max = 20;
local load_timer = load_timer_max;
local marqDir = "";

fe.add_transition_callback( "dynamicmarquee" );
function dynamicmarquee( ttype, var, transition_time )
{
	switch ( ttype )
		{
			case Transition.EndNavigation:
				load_timer = load_timer_max;
				has_moved = true;
				break;
			case Transition.StartLayout:
				load_timer = load_timer_max;
				has_moved = true;
				break;			
			case Transition.EndLayout:
			case Transition.ToNewSelection:
			case Transition.FromOldSelection:
			case Transition.ToGame:
			case Transition.FromGame:
			case Transition.ToNewList:
			case Transition.ShowOverlay:
			case Transition.HideOverlay:
			case Transition.NewSelOverlay:
				break;
		}
   return false;
}

fe.add_ticks_callback( "updateTick" );
function updateTick( ttime )
{	
	load_timer = max(0, load_timer-1);

	//Update game media after delay
	if( has_moved && load_timer == 0)
	{
	switch ( fe.game_info(Info.Emulator) )
		{
			case "Panasonic 3DO":
			case "3DO Interactive Multiplayer":
				marqDir="3do";
				break;
			case "Amiga":
				marqDir="amiga";
				break;
			case "Amstrad CPC":
				marqDir="amstradcpc";
				break;
			case "Arcade":
				marqDir="arcade";
				break;
			case "Atari 2600":
				marqDir="atari2600";
				break;
			case "Atari 5200":
				marqDir="atari5200";
				break;
			case "Atari 7800 ProSystem":
				marqDir="atari7800";
				break;
			case "Atari 800":
				marqDir="atari800";
				break;
			case "Atari Jaguar":
				marqDir="atarijaguar";
				break;
			case "Atari Lynx":
				marqDir="atarilynx";
				break;
			case "Atari ST":
				marqDir="atarist";
				break;
			case "ColecoVision":
				marqDir="coleco";
				break;
			case "Commodore 64":
				marqDir="c64";
				break;
			case "Commodore Amiga":
				marqDir="amiga";
				break;
			case "Daphne":
				marqDir="daphne";
				break;
			case "Dragon 32":
				marqDir="dragon32";
				break;
			case "Dreamcast":
				marqDir="dreamcast";
				break;
			case "Fairchild ChannelF":
				marqDir="channelf";
				break;
			case "Famicom Disk System":
				marqDir="fds";
				break;
			case "Final Burn Alpha":
				marqDir="fba";
				break;
			case "Game Boy Advance":
				marqDir="gba";
				break;
			case "Game Boy":
				marqDir="gb";
				break;
			case "Game Boy Color":
				marqDir="gbc";
				break;
			case "Intellivision":
				marqDir="intellivision";
				break;
			case "Mame2010":
				marqDir="mame2010";
				break;
			case "Mega CD":
				marqDir="segacd";
				break;
			case "MSX":
				marqDir="msx";
				break;
			case "Multiple Arcade Machine Emulator":
				marqDir="arcade";
				break;
			case "Neo Geo":
				marqDir="neogeo";
				break;
			case "Neo Geo Pocket":
				marqDir="ngp";
				break;
			case "Neo Geo Pocket Color":
				marqDir="ngpc";
				break;
			case "Nintendo 64":
				marqDir="gc";
				break;
			case "Nintendo DS":
				marqDir="nds";
				break;
			case "Nintendo Entertainment System":
			case "Nintendo Entertainment System (NES)":
				marqDir="nes";
				break;
			case "Nintendo Gamecube":
				marqDir="gc";
				break;
			case "Nintendo Wii":
				marqDir="wii";
				break;
			case "Oric 1":
				marqDir="oric";
				break;
			case "PC":
				marqDir="pc";
				break;
			case "PC Engine":
				marqDir="pcengine";
				break;
			case "PlayStation":
				marqDir="psx";
				break;
			case "PlayStation Portable":
				marqDir="psp";
				break;
			case "Ports":
				marqDir="ports";
				break;
			case "Sega 32X":
				marqDir="sega32x";
				break;
			case "Sega CD":
				marqDir="segacd";
				break;
			case "Sega Gamegear":
				marqDir="gamegear";
				break;
			case "Sega Master System":
				marqDir="mastersystem";
				break;
			case "Sega Mega Drive":
				marqDir="megadrive";
				break;
			case "Sega Saturn":
				marqDir="saturn";
				break;
			case "Sega SG-1000":
				marqDir="sg-1000";
				break;
			case "Super Nintendo":
				marqDir="snes";
				break;
			case "Vectrex":
				marqDir="vectres";
				break;
			case "Videopac":
				marqDir="videopac";
				break;
			case "Virtual Boy":
				marqDir="vb";
				break;
			case "Z-machine":
				marqDir="zmachine";
				break;
			case "ZX Spectrum":
				marqDir="zxspectrum";
				break;
			case "TRS-80 Color Computer":
			case "RetroPie":
				break;
			default:
				marqDir="";
				break;			
		}
	
	//get ext of file
	local marqueepath=fe.get_art("marquee");
	local ext=marqueepath.slice(marqueepath.len().tointeger()-4);
	
	// if a file actually exists
	if (fe.path_test(marqueepath ,PathTest.IsFile)) {
		fe.plugin_command_bg( "ssh", "marquee@marquee.local \"/home/marquee/t.sh \\\""+marqDir+"/"+fe.game_info(Info.Name)+ext+"\\\" \\\""+fe.get_art("marquee")+"\\\" "+marqDir+"\"");
	}
	// else do default
	else
	{
		fe.plugin_command( "ssh", "marquee@marquee.local \"/home/marquee/t.sh retropie.png\"");
	}
	// reset
	has_moved = false;
		
	}
}

function max(a,b){
	if(a > b) return a;
	else return b;
}
