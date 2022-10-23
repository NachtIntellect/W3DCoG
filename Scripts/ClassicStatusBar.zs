class ClassicStatusBar : BaseStatusBar
{
	HUDFont ClassicFont, BigFont;
	TextureID mugshot;

	int mugshottimer, idleframe;
	Vector3 playerpos[MAXPLAYERS];

	TextureID pixel;
	int fizzleindex;
	Vector2 fizzlepoints[64000];

	bool fizzleeffect;
	Color fizzlecolor;

	play int staticmugshot;
	play int staticmugshottimer;

	override void Init()
	{
		Super.Init();
		SetSize(42, 320, 200);
		CompleteBorder = False;

		ClassicFont = HUDFont.Create("WOLFNUM", 0);
		BigFont = HUDFont.Create("BIGFONT", 0);

		pixel = TexMan.CheckForTexture("Floor", TexMan.Type_Any);

		fizzleindex = 0;
		SetFizzleFadeSteps();

		fizzleeffect = false;
	}

	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);

		if (pixel && fizzleeffect)
		{
			for (int f = 0; f <= fizzleindex; f++)
			{
				Vector2 fizzle = fizzlepoints[f];

				screen.DrawTexture(pixel, false, fizzle.x, fizzle.y, DTA_320x200, true, DTA_DestWidth, 1, DTA_DestHeight, 1, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_FillColor, fizzlecolor);
				screen.DrawTexture(pixel, false, fizzle.x > 160 ? fizzle.x - 320 : fizzle.x + 320, fizzle.y, DTA_320x200, true, DTA_DestWidth, 1, DTA_DestHeight, 1, DTA_TopOffset, 0, DTA_LeftOffset, 0, DTA_FillColor, fizzlecolor);
			}

			fizzleindex += 1920; // Draw a chunk of pixels at a time...

			if (fizzleindex >= fizzlepoints.Size()) { fizzleindex = fizzlepoints.Size() - 1; }
		}

		if (state == HUD_StatusBar)
		{
			BeginStatusBar(screenblocks < 11);
			DrawClassicBar();
		}
		else if (state == HUD_Fullscreen)
		{
			DrawHUD();
		}
	}

	static void DoFizzle(Actor caller, color clr = 0xFF0000, bool Off = false)
	{
		if (ClassicStatusBar(StatusBar).CPlayer.mo != caller) { return; }

		ClassicStatusBar(StatusBar).fizzleeffect = !Off;
		ClassicStatusBar(StatusBar).fizzlecolor = clr;
	}

	static void ClearFizzle(Actor caller)
	{
		DoFizzle(caller, 0, true);
	}

	play static void DoGrin(Actor caller)
	{
		if (players[consoleplayer].mo != caller) { return; }

		ClassicStatusBar(StatusBar).staticmugshot = 1;
		ClassicStatusBar(StatusBar).staticmugshottimer = gametic + 80; // 80 tics is roughly the duration of the chaingun pickup sound
	}

	play void DoIdleFace(Actor caller)
	{
		if (players[consoleplayer].mo != caller) { return; }

		ClassicStatusBar(StatusBar).staticmugshot = 2;
		ClassicStatusBar(StatusBar).staticmugshottimer = gametic + 35;
	}

	play static void DoScream(Actor caller)
	{
		if (players[consoleplayer].mo != caller) { return; }

		ClassicStatusBar(StatusBar).staticmugshot = 3;
		ClassicStatusBar(StatusBar).staticmugshottimer = gametic + 30;
	}

	void DrawClassicBar(bool drawborder = true, int points = -1, int lives = -1)
	{
		if (drawborder)
		{
			Vector2 window, windowsize, screensize, viewportsize, viewport;

			screensize = (Screen.GetWidth(), Screen.GetHeight());

			int blocks = automapactive ? 10 : clamp(screenblocks, 3, 10);

			double yoffset = (200 - RelTop);

			CVar borderstylevar = CVar.GetCVar("g_borderstyle", CPlayer);
			int borderstyle = borderstylevar ? borderstylevar.GetInt() : 0;

			if (borderstyle > 0)
			{
				double width = 200 * screensize.x / screensize.y;
				viewportsize.x = (blocks * (width - 16)) / 8.35;
			}
			else
			{
				viewportsize.x = (blocks * (320 - 16)) / 10;
			}

			viewportsize.y = (blocks * yoffset) / 10 - 2;

			viewport.x = (320 - viewportsize.x) / 2;
			viewport.y = (yoffset - viewportsize.y) / 2;

			[window, windowsize] = DrawToHud.TranslatetoHUDCoordinates(viewport, viewportsize, checkfullscreen:true);

			if (screenblocks < 11 && !automapactive && (borderstyle != 2 || screenblocks < 10))
			{
				// Fill outside of boundaries with green
				Screen.Dim(0x004040, 1.0, 0, 0, int(window.x - 1), int(screensize.y));
				Screen.Dim(0x004040, 1.0, int(window.x + windowsize.x), 0, int(screensize.x - window.x - windowsize.x), int(screensize.y));
				Screen.Dim(0x004040, 1.0, int(window.x - 1), 0, int(windowsize.x + 2), int(window.y));
				Screen.Dim(0x004040, 1.0, int(window.x - 1), int(window.y + windowsize.y), int(windowsize.x + 2), int(screensize.y - window.y - windowsize.y));

				// Draw border
				DrawImage("WBRD_T", (viewport.x, viewport.y - 1), DI_ITEM_LEFT_TOP, scale:(viewportsize.x / 8, 1.0));
				DrawImage("WBRD_B", (viewport.x, viewport.y + viewportsize.y - 1), DI_ITEM_LEFT_TOP, scale:(viewportsize.x / 8, 1.0));
				DrawImage("WBRD_L", (viewport.x - 3, viewport.y), DI_ITEM_LEFT_TOP, scale:(1.0, viewportsize.y / 8));
				DrawImage("WBRD_R", (viewport.x + viewportsize.x, viewport.y), DI_ITEM_LEFT_TOP, scale:(1.0, viewportsize.y / 8));

				DrawImage("WBRD_TL", (viewport.x - 3, viewport.y - 1), DI_ITEM_LEFT_TOP);
				DrawImage("WBRD_TR", (viewport.x + viewportsize.x, viewport.y - 1), DI_ITEM_LEFT_TOP);
				DrawImage("WBRD_BL", (viewport.x - 3, viewport.y + viewportsize.y - 1), DI_ITEM_LEFT_TOP);
				DrawImage("WBRD_BR", (viewport.x + viewportsize.x, viewport.y + viewportsize.y - 1), DI_ITEM_LEFT_TOP);
			}
			else if (automapactive || (screenblocks == 10 && borderstyle == 2))
			{
				Vector2 coords, size;
				[coords, size] = DrawToHud.TranslatetoHUDCoordinates((0, 200 - RelTop), (320, RelTop), checkfullscreen:true);

				Screen.Dim(0x004040, 1.0, 0, int(coords.y), int(screensize.x), int(size.y));
				DrawImage("WBRD_B", (160, 200 - RelTop), DI_ITEM_TOP | DI_ITEM_HCENTER, scale:(windowsize.x / 4, 1.0));
			}
		}

		DrawImage("BAR", (160, 198), DI_SCREEN_CENTER_BOTTOM);

		//Lives
		if (lives < 0) { lives = LifeHandler.GetLives(CPlayer.mo); }
		DrawString(ClassicFont, FormatNumber(max(lives, 0)), (116, 176), DI_TEXT_ALIGN_CENTER | DI_SCREEN_CENTER_BOTTOM);

		//Level
		String levelnum = String.Format("%i", level.levelnum);
		if (level.levelnum > 100)
		{
			levelnum = String.Format("%i", level.levelnum % 100);
			if (levelnum == "0") { levelnum = "10"; }
		}

		if (levelnum == "0") { levelnum = "?"; }

		DrawString(ClassicFont, (Game.IsSoD() && levelnum == "21" ? "18" : levelnum), (32, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);

		//Score
		if (points < 0) { points = GetAmount("Score"); }
		DrawString(ClassicFont, FormatNumber(points % 1000000), (95, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);

		//Health
		DrawString(ClassicFont, FormatNumber(CPlayer.health), (191, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);

		DrawMugShot(136, 164);

		//Keys
		if (GetAmount("YellowKey") || GetAmount("YellowKeyLost")) { DrawImage("YKEY", (244, 172), DI_ITEM_CENTER | DI_SCREEN_CENTER_BOTTOM); }
		if (GetAmount("BlueKey") || GetAmount("BlueKeyLost")) { DrawImage("BKEY", (244, 188), DI_ITEM_CENTER | DI_SCREEN_CENTER_BOTTOM); }

		//Weapon
		TextureID icontex;
		String icon = "";
		double scale = 1.0;
		let weapon = CPlayer.ReadyWeapon;

		if (weapon)
		{
			String classname = weapon.GetClassName();

			icontex = GetInventoryIcon(weapon, 0);

			if (!icontex && weapon.SpawnState) { icontex = weapon.SpawnState.GetSpriteTexture(0); }
		}
		else
		{
			icontex = TexMan.CheckForTexture("LUGER", TexMan.Type_Any);
		}

		if (icontex)
		{
			Vector2 size = TexMan.GetScaledSize(icontex);
			Vector2 scalexy = (1.0, 1.0);

			if (size.x > 48) { scalexy.x = 48. / size.x; }
			if (size.y > 24) { scalexy.y = 24. / size.y; }

			scale = min(scalexy.x, scalexy.y);

			DrawToHUD.DrawTexture(icontex, (280, 179), 1.0, scale, (!weapon || weapon is "ClassicWeapon") ? -1 : 0x000000, DrawToHUD.center, DrawToHUD.bottom, true);
		}


		//Ammo
		Ammo ammo1, ammo2;
		int ammocount = 0, ammocount1, ammocount2;
		[ammo1, ammo2, ammocount1, ammocount2] = GetClassicDisplayAmmo(CPlayer);
		if (ammo2) { ammocount += ammocount2; }
		if (ammo1) { ammocount += ammocount1; } 
		DrawString(ClassicFont, FormatNumber(ammocount), (231, 176), DI_TEXT_ALIGN_RIGHT | DI_SCREEN_CENTER_BOTTOM);
	}

	void DrawMugShot(int x, int y, int size = 32)
	{
		if (staticmugshot && staticmugshottimer >= gametic)
		{
			mugshot = GetMugShot(5, type:staticmugshot);
			mugshottimer = 0;
		}
		else if (!mugshot || mugshottimer > min(35, Random[mugshot](0, 255)))
		{
			mugshot = GetMugShot(5);
			mugshottimer = 0;
			idleframe = Random(1, 2);
		}

		Vector2 texsize = TexMan.GetScaledSize(mugshot);
		if (texsize.x > size || texsize.y > size)
		{
			if (texsize.y > texsize.x)
			{
				texsize.y = size * 1.0 / texsize.y;
				texsize.x = texsize.y;
			}
			else
			{
				texsize.x = size * 1.0 / texsize.x;
				texsize.y = texsize.x;
			}
		}
		else { texsize = (1.0, 1.0); }

		DrawTexture(mugshot, (x, y), DI_ITEM_OFFSETS, scale:texsize);
	}

	TextureID GetMugShot(int accuracy = 5, String face = "", int type = 0)
	{
		String mugshot;

		if (face == "") { face = CPlayer.mo.face; }

		if (CPlayer.health > 0)
		{
			int hlevel = 0;

			int maxhealth = CPlayer.mo.mugshotmaxhealth > 0 ? CPlayer.mo.mugshotmaxhealth : CPlayer.mo.maxhealth;
			if (maxhealth <= 0) { maxhealth = 100; }

			while (CPlayer.health < (accuracy - 1 - hlevel) * (maxhealth / accuracy)) { hlevel++; }

			int index = (gamestate == GS_CUTSCENE || level.time < 5) ? 0 : Random[mugshot](0, 255) >> 6;
			if (index == 3) { index = 1; }

			// SoD-specific god face
			if (Game.IsSod() || level.levelnum < 101)
			{
				if (players[consoleplayer].cheats & (CF_GODMODE | CF_GODMODE2))
				{
					mugshot = face .. "GOD" .. index;
				}
			}
	
			if (!mugshot.length())
			{
				switch (type)
				{
					default:
						mugshot = face .. "ST" .. hlevel .. index;
						break;
					case 1: // Grin
						mugshot = face .. "EVL";
						break;
					case 2: // Idle
						mugshot = face .. "STT" .. idleframe;
						break;
					case 3: // Scream
						mugshot = face .. "SCRM";
						break;

				}
			}
		}
		else
		{
			if (CPlayer.mo is "WolfPlayer" && WolfPlayer(CPlayer.mo).mutated)
			{
				mugshot = face .. "MUT";
			}
			else
			{
				mugshot = face .. "DEAD0";
			}
		}

		return TexMan.CheckForTexture(mugshot, TexMan.Type_Any); 
	}

	protected void DrawHUD()
	{
		fullscreenOffsets = true;

		int baseline = -14;

		//Score
		DrawString(BigFont, FormatNumber(GetAmount("Score")), (-2, baseline - 16), DI_TEXT_ALIGN_RIGHT, Font.FindFontColor("TrueWhite"));

		//Lives
		TextureID life = TexMan.CheckForTexture("I_LIFE", TexMan.Type_Any);
		if (life) { DrawTexture(life, (19, -26), DI_ITEM_CENTER); }
		DrawString(BigFont, FormatNumber(max(LifeHandler.GetLives(CPlayer.mo), 0)), (35, baseline), 0, Font.FindFontColor("TrueWhite"));

		//Keys
		if (GetAmount("YellowKey") || GetAmount("YellowKeyLost")) { DrawImage("I_YKEY_T", (-8, 0), DI_ITEM_LEFT_TOP); }
		if (GetAmount("BlueKey") || GetAmount("BlueKeyLost")) { DrawImage("I_BKEY_T", (-8, 14), DI_ITEM_LEFT_TOP); }

		//Ammo
		Ammo ammo1, ammo2;
		int ammocount = 0, ammocount1, ammocount2;
		[ammo1, ammo2, ammocount1, ammocount2] = GetClassicDisplayAmmo(CPlayer);

		TextureID ammoicon;
		if (ammo2) { ammocount += ammocount2; ammoicon = ammo2.Icon; }
		if (ammo1) { ammocount += ammocount1; ammoicon = ammo1.Icon; }

		if (ammoicon) { DrawTexture(ammoicon, (-110, -1), DI_ITEM_CENTER_BOTTOM ); }
		DrawString(BigFont, FormatNumber(ammocount), (-95, baseline), 0, Font.FindFontColor("TrueWhite"));

		//Health
		bool haveBerserk = hud_berserk_health && CPlayer.mo.FindInventory('PowerStrength');
		TextureID health = TexMan.CheckForTexture(haveBerserk ? "I_BERSERK" : "I_HEALTH", TexMan.Type_Any);
		if (health) { DrawTexture(health, (-50, -1), DI_ITEM_CENTER_BOTTOM); }
		DrawString(BigFont, FormatNumber(CPlayer.health), (-2, baseline), DI_TEXT_ALIGN_RIGHT, Font.FindFontColor("TrueWhite"));
	}

	Ammo, Ammo, int, int GetClassicDisplayAmmo(PlayerInfo CPlayer)
	{
		Ammo ammo1, ammo2;

		if (CPlayer.ReadyWeapon)
		{
			ammo1 = CPlayer.ReadyWeapon.Ammo1;
			ammo2 = CPlayer.ReadyWeapon.Ammo2;
			if (!ammo1)
			{
				ammo1 = ammo2;
				ammo2 = null;
			}
		}
		else
		{
			ammo1 = ammo2 = null;
		}

		if (!ammo1 && !ammo2)
		{
			ammo2 = Ammo(CPlayer.mo.FindInventory("WolfClip"));
		}

		let ammocount1 = ammo1 ? ammo1.Amount : 0;
		let ammocount2 = ammo2 ? ammo2.Amount : 0;

		return ammo1, ammo2, ammocount1, ammocount2;
	}

	override int GetProtrusion(double scaleratio) const
	{
		return int(24 * scaleratio);
	}

	override void Tick()
	{
		mugshottimer++;

		Super.Tick();
	}

	// Adapted from here: http://fabiensanglard.net/fizzlefade/index.php
	void SetFizzleFadeSteps()
	{
		int x, y;

		int fizzleval = 1;

		do
		{
			y = fizzleval & 0x000FF;		// Y = low 8 bits
			x = (fizzleval & 0x1FF00) >> 8;		// X = High 9 bits

			uint lsb = fizzleval & 1;		// Get the output bit.
			fizzleval >>= 1;			// Shift register

			if (lsb)				// If the output is 0, the xor can be skipped.
			{
				fizzleval ^= 0x00012000;
			}

			if (x < 320 && y < 200)
			{
				fizzlepoints[fizzleindex] = (x, y);
				fizzleindex++;
			}
		} while (fizzleval != 1)

		fizzleindex = 0;
	}

	// From v_draw.cpp
	static int GetUIScale(int altval = 0)
	{
		int scaleval;

		if (altval > 0) { scaleval = altval; }
		else if (uiscale == 0)
		{
			// Default should try to scale to 640x400
			int vscale = screen.GetHeight() / 400;
			int hscale = screen.GetWidth() / 640;
			scaleval = clamp(vscale, 1, hscale);
		}
		else { scaleval = uiscale; }

		// block scales that result in something larger than the current screen.
		int vmax = screen.GetHeight() / 200;
		int hmax = screen.GetWidth() / 320;
		int max = MAX(vmax, hmax);
		return MAX(1,MIN(scaleval, max));
	}

	// Original code from shared_sbar.cpp
	override void DrawAutomapHUD(double ticFrac)
	{
		int crdefault = Font.CR_GRAY;
		int highlight = Font.FindFontColor("WolfMenuYellowBright");

		let scale = GetUIScale(hud_scale);
		let titlefont = Font.FindFont("BigFont");
		let font = generic_ui ? NewSmallFont : SmallFont;
		let font2 = font;
		let vwidth = screen.GetWidth() / scale;
		let vheight = screen.GetHeight() / scale;
		let fheight = font.GetHeight();
		String textbuffer;
		int sec;
		int textdist = 4;
		int zerowidth = font.GetCharWidth("0");

		int y = textdist;

		// Don't prepend the map name...  Just use the level's title.
		textbuffer = level.LevelName;
		if (idmypos) { textbuffer = textbuffer .. " (" .. level.mapname.MakeUpper() .. ")"; }

		if (!generic_ui)
		{
			if (!font.CanPrint(textbuffer)) font = OriginalSmallFont;
		}

		let lines = font.BreakLines(textbuffer, vwidth - 32);
		let numlines = lines.Count();
		let finalwidth = lines.StringWidth(numlines - 1);

		// Draw the text
		for (int i = 0; i < numlines; i++)
		{
			screen.DrawText(titlefont, highlight, textdist, y, lines.StringAt(i), DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);
			y += titlefont.GetHeight();
		}

		y+= int(fheight / 2);

		String time;

		if (am_showtime) { time = level.TimeFormatted(); }

		if (am_showtotaltime)
		{
			if (am_showtime) { time = time .. " / " .. level.TimeFormatted(true); }
			else { time = level.TimeFormatted(true); }
		}

		if (am_showtime || am_showtotaltime)
		{
			screen.DrawText(font, crdefault, textdist, y, time, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight, DTA_Monospace, 2, DTA_Spacing, zerowidth, DTA_KeepRatio, true);
			y += int(fheight * 3 / 2);
		}

		String monsters = StringTable.Localize("AM_MONSTERS", false);
		String secrets = StringTable.Localize("AM_SECRETS", false);
		String items = StringTable.Localize("AM_ITEMS", false);

		double labelwidth = 0;

		for (int i = 0; i < 3; i++)
		{
			String label;
			int size;

			Switch (i)
			{
				case 0:
					label = monsters;
					break;
				case 1:
					label = secrets;
					break;
				case 2:
					label = items;
					break;
			}

			size = font2.StringWidth(label .. "   ");

			if (size > labelwidth) { labelwidth = size; }
		}

		if (!generic_ui)
		{
			// If the original font does not have accents this will strip them - but a fallback to the VGA font is not desirable here for such cases.
			if (!font.CanPrint(monsters) || !font.CanPrint(secrets) || !font.CanPrint(items)) { font2 = OriginalSmallFont; }
		}

		if (!deathmatch)
		{
			if (am_showmonsters && level.total_monsters > 0)
			{
				screen.DrawText(font2, crdefault, textdist, y, monsters, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				textbuffer = textbuffer.Format("%d/%d", level.killed_monsters, level.total_monsters);
				screen.DrawText(font2, Font.CR_RED, textdist + labelwidth, y, textbuffer, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				y += fheight;
			}

			if (am_showsecrets && level.total_secrets > 0)
			{
				screen.DrawText(font2, crdefault, textdist, y, secrets, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				textbuffer = textbuffer.Format("%d/%d", level.found_secrets, level.total_secrets);
				screen.DrawText(font2, Font.CR_SAPPHIRE, textdist + labelwidth, y, textbuffer, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				y += fheight;
			}

			// Draw item count
			if (am_showitems && level.total_items > 0)
			{
				screen.DrawText(font2, crdefault, textdist, y, items, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				textbuffer = textbuffer.Format("%d/%d", level.found_items, level.total_items);
				screen.DrawText(font2, Font.CR_GOLD, textdist + labelwidth, y, textbuffer, DTA_KeepRatio, true, DTA_VirtualWidth, vwidth, DTA_VirtualHeight, vheight);

				y += fheight;
			}
		}
	}

	override bool DrawPaused(int player)
	{
		TextureID pause = TexMan.CheckForTexture("W_PAUSE"); // gameinfo.PauseSign is not exposed to ZScript
		Vector2 size = TexMan.GetScaledSize(pause);

		double x = Screen.GetWidth() / 2;
		double y = Screen.GetHeight() / 2;

		Screen.DrawTexture(pause, true, x, y, DTA_CleanNoMove, true, DTA_CenterOffset, true);

		if (paused && multiplayer)
		{
			String pstring = StringTable.Localize("$TXT_PAUSEDBY");
			pstring.Substitute("%s", players[paused - 1].GetUserName());
			Screen.DrawText(SmallFont, Font.CR_WHITE, x - SmallFont.StringWidth(pstring) * CleanXfac_1 / 2, y + size.y * CleanYfac_1, pstring, DTA_CleanNoMove_1, true);
		}

		return true;
	}
}

class JaguarHUD : AltHUD
{
	override void Init()
	{
		Super.Init();

		HudFont = Font.FindFont("JAGFONT");
		if (HudFont == NULL) { HudFont = SmallFont; }
	}

	override void DrawHealth(PlayerInfo CPlayer, int x, int y)
	{
		int health = CPlayer.health;

		DrawImageToBox(StatusBar.GetMugShot(7, MugShot.ANIMATEDGODMODE | MugShot.DISABLERAMPAGE | MugShot.DISABLEOUCH | MugShot.CUSTOM, "WLJ"), x, y - 9, 32, 32, 1.0);
		DrawHudNumber(HudFont, -1, health, x + 84 - HudFont.StringWidth(String.Format("%i", health)), y + 17);
	}

	override int DrawAmmo(PlayerInfo CPlayer, int x, int y)
	{
		//Ammo
		Ammo ammo1, ammo2;
		int ammocount = 0, ammocount1, ammocount2;
		[ammo1, ammo2, ammocount1, ammocount2] = ClassicStatusBar(StatusBar).GetClassicDisplayAmmo(CPlayer);

		TextureID ammoicon;
		if (ammo2) { ammocount += ammocount2; ammoicon = ammo2.AltHudIcon; }
		if (ammo1) { ammocount += ammocount1; ammoicon = ammo1.AltHudIcon; }

		DrawHUDNumber(HudFont, -1, ammocount, x - HudFont.StringWidth(String.Format("%i", ammocount)), y + HudFont.GetHeight(), 1.0);
		if (ammoicon) { DrawImageToBox(ammoicon, x, y - 9, 32, 32, 1.0); }

		return 0;
	}

	override void DrawInGame(PlayerInfo CPlayer)
	{
		if (gamestate == GS_TITLELEVEL || !CPlayer) return;

		DrawHealth(CPlayer, 6, hudheight - 32);
		DrawAmmo(CPlayer, hudwidth - 42, hudheight - 32);

		int c = 0;

		Inventory bkey = CPlayer.mo.FindInventory("BlueKey");
		if (!bkey) { bkey = CPlayer.mo.FindInventory("BlueKeyLost"); }
		if (bkey)
		{
			DrawImageToBox(bkey.AltHudIcon, 86, hudheight - 39, 24, 24, 1.0);
		}

		Inventory ykey = CPlayer.mo.FindInventory("YellowKey");
		if (!ykey) { ykey = CPlayer.mo.FindInventory("YellowKeyLost"); }
		if (ykey)
		{
			DrawImageToBox(ykey.AltHudIcon, hudwidth - 108, hudheight - 39, 24, 24, 1.0);
		}
	}

	override void DrawAutomap(PlayerInfo CPlayer)
	{
		if (gamestate == GS_TITLELEVEL || !CPlayer) return;

		// Use the game's standard automap overlay
		StatusBar.DrawAutomapHUD(0);
	}
}