class GameHandler : StaticEventHandler
{
	Array<String> gamefiles;

	override void OnRegister()
	{
		// Check to see if a Wolf3D data file is present
		GameHandler.CheckGameFile("GAMEMAPS.WL3", gamefiles);
		GameHandler.CheckGameFile("GAMEMAPS.WL6", gamefiles);
		GameHandler.CheckGameFile("GAMEMAPS.SOD", gamefiles);
		GameHandler.CheckGameFile("GAMEMAPS.SD2", gamefiles);
		GameHandler.CheckGameFile("GAMEMAPS.SD3", gamefiles);
	}

	ui static bool GameFilePresent(String extension, bool allowdemos = true)
	{
		GameHandler this = GameHandler(StaticEventHandler.Find("GameHandler"));
		if (this)
		{
			if (this.gamefiles.Find(extension) < this.gamefiles.Size()) { return true; }
			if (extension ~== "WL3" && this.gamefiles.Find("WL6") < this.gamefiles.Size()) { return true; }
			if (allowdemos && extension ~== "SOD") { return true; }
		}

		return false;
	}

	private static void CheckGameFile(String filename, out Array<String> gamefiles, bool verbose = false)
	{
		if (!g_placeholders) { gamefiles.Push(filename.Mid(filename.length() - 3)); return; }

		// Check to see if a Wolf3D GAMEMAPS data file is present
		int g =	Wads.CheckNumForFullName(filename);
		String message = StringTable.Localize("$TXT_FOUNDFILE");

		if (g > -1)
		{
			String hash = MD5.hash(Wads.ReadLump(g));
/*
			if (
				hash == "" // I can't find the md5 of GAMEMAPS.WL3 anywhere, and don't own it, so...  unsupported.
			)
			{
				gamefiles.Push("WL3");
				message.Replace("%s", "Wolfenstein 3D (Episodes 1-3)");
			}
			else 
*/
			if (
				hash == "a4e73706e100dc0cadfb02d23de46481" || // v1.4 / GoG / Steam
				hash == "a15b04941937b7e136419a1e74e57e2f" // v1.1
			)
			{
				gamefiles.Push("WL6");
				message.Replace("%s", "Wolfenstein 3D");
			}
			else if (hash == "4eb2f538aab6e4061dadbc3b73837762")
			{
				gamefiles.Push("SDM");
				message.Replace("%s", "Spear of Destiny Demo");
			}
			else if (hash == "04f16534235b4b57fc379d5709f88f4a")
			{
				gamefiles.Push("SOD");
				message.Replace("%s", "Spear of Destiny");
			}
			else if (hash == "fa5752c5b1e25ee5c4a9ec0e9d4013a9")
			{
				gamefiles.Push("SD2");
				message.Replace("%s", "Return to Danger");
			}
			else if (
				hash == "4219d83568d770b1c6ac9c2d4d1dfb9e" ||
				hash == "29860b87c31348e163e10f8aa6f19295"
			)
			{
				gamefiles.Push("SD3");
				message.Replace("%s", "The Ultimate Challenge");
			}
		}

		if (verbose && !(message == StringTable.Localize("$TXT_FOUNDFILE")))
		{
			console.printf(message);
		}
	}

	// This is unreliable and causes crashes if it gets called before 
	// video initializes properly (e.g., with +map command line)
/*
	override void PlayerSpawned(PlayerEvent e)
	{
			if (g_nointro) { return; }
			if (g_sod && level.levelnum % 100 == 21) { return; }

			if (e.playernumber == consoleplayer) { Menu.SetMenu("GetPsyched", -1); }
	}

	override void PlayerRespawned(PlayerEvent e)
	{
			if (g_nointro) { return; }

			if (e.playernumber == consoleplayer) { Menu.SetMenu("GetPsyched", -1); }
	}
*/
	ui static bool CheckEpisode(String episode = "", bool allowunfiltered = true)
	{
		String extension = "";

		if (level.levelnum > 100 && episode == "") { episode = Level.GetEpisodeName(); }

		// Map lump name parsing because episode name checks are unreliable
		if (!episode.length())
		{
			String ext = level.mapname.Left(3);
			ext = ext.MakeUpper();

			if (ext ~== "SOD" || ext ~== "SD2" || ext ~== "SD3") { extension = ext; }
			else if (ext.left(1) ~== "E" && ext.mid(2) ~== "L")
			{
				int ep = ext.mid(1, 1).ToInt();

				if (ep == 1) { return true; }
				else if (ep <= 3) { extension = "WL3"; }
				else if (ep <= 6) { extension = "WL6"; }
			}

			episode = extension;
		}

		if (!episode.length()) { return true; }

		String temp;
		if (!extension.length())
		{
			temp = episode;
			int s, e;
			s = temp.IndexOf("[Optional");
			if (s > -1)
			{
				e = temp.IndexOf("]", s);
				extension = temp.Mid(e - 3, 3);
				extension = extension.MakeUpper();

				temp = temp.Mid(e + 1);
			}
		}

		// Treat episodes with no filter as if they were the shareware version
		if (!allowunfiltered && !extension.length()) { extension = "WL6"; }

		// If the replacement string wasn't there, then this one is good
		if (allowunfiltered && (temp == episode || !extension.length())) { return true; }

		GameHandler this = GameHandler(StaticEventHandler.Find("GameHandler"));
		if (this)
		{
			if (this.gamefiles.Find(extension) < this.gamefiles.Size()) { return true; }
			if (extension ~== "WL3" && this.gamefiles.Find("WL6") < this.gamefiles.Size()) { return true; }
			if (extension ~== "SOD" && level.levelnum % 100 < 3) { return true; }
		}

		return false;
	}
}

class Game
{
	static int, int IsSoD()
	{
		int ret = max(0, g_sod);

		if (level && level.levelnum > 700)
		{
			String ext = level.mapname.Left(3);
			if (ext ~== "SOD") { ret = 1; }
			else if (ext ~== "SD2") { ret = 2; }
			else if (ext ~== "SD3") { ret = 3; }
		}
		else
		{
			ret = 0;
		}

		if (g_sod != ret && gamestate == GS_LEVEL && level.time > 1) // Set the value if we are in a game and it hasn't been set already by the startup menu
		{
			CVar sodvar = CVar.FindCVar("g_sod");
			if (sodvar) { sodvar.SetInt(ret); }
		}

		return g_sod, ret;
	}

	static int WolfRandom()
	{
		static const int rnd_table[] = {
		  0,   8, 109, 220, 222, 241, 149, 107,  75, 248, 254, 140,  16,  66,
		 74,  21, 211,  47,  80, 242, 154,  27, 205, 128, 161,  89,  77,  36,
		 95, 110,  85,  48, 212, 140, 211, 249,  22,  79, 200,  50,  28, 188,
		 52, 140, 202, 120,  68, 145,  62,  70, 184, 190,  91, 197, 152, 224,
		149, 104,  25, 178, 252, 182, 202, 182, 141, 197,   4,  81, 181, 242,
		145,  42,  39, 227, 156, 198, 225, 193, 219,  93, 122, 175, 249,   0,
		175, 143,  70, 239,  46, 246, 163,  53, 163, 109, 168, 135,   2, 235,
		 25,  92,  20, 145, 138,  77,  69, 166,  78, 176, 173, 212, 166, 113,
		 94, 161,  41,  50, 239,  49, 111, 164,  70,  60,   2,  37, 171,  75,
		136, 156,  11,  56,  42, 146, 138, 229,  73, 146,  77,  61,  98, 196,
		135, 106,  63, 197, 195,  86,  96, 203, 113, 101, 170, 247, 181, 113,
		 80, 250, 108,   7, 255, 237, 129, 226,  79, 107, 112, 166, 103, 241,
		 24, 223, 239, 120, 198,  58,  60,  82, 128,   3, 184,  66, 143, 224,
		145, 224,  81, 206, 163,  45,  63,  90, 168, 114,  59,  33, 159,  95,
		 28, 139, 123,  98, 125, 196,  15,  70, 194, 253,  54,  14, 109, 226,
		 71,  17, 161,  93, 186,  87, 244, 138,  20,  52, 123, 251,  26,  36,
		 17,  46,  52, 231, 232,  76,  31, 221,  84,  37, 216, 165, 212, 106,
		197, 242,  98,  43,  39, 175, 254, 145, 190,  84, 118, 222, 187, 136,
		120, 163, 236, 249 };

		return rnd_table[Random(0, 255)];
	}
}