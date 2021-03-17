/**
 * MicroTF2 - System.sp
 * 
 * Implements the coordinator that orchestrates the gameplay
 */

#define TOTAL_GAMEMODES 100
#define TOTAL_SYSMUSIC 6
#define TOTAL_SYSOVERLAYS 10

#define SYSMUSIC_PREMINIGAME 0
#define SYSMUSIC_BOSSTIME 1
#define SYSMUSIC_SPEEDUP 2
#define SYSMUSIC_GAMEOVER 3
#define SYSMUSIC_FAILURE 4
#define SYSMUSIC_WINNER 5

#define SYSMUSIC_MAXFILES 32
#define SYSMUSIC_MAXSTRINGLENGTH 192

#define OVERLAY_BLANK ""
#define OVERLAY_MINIGAMEBLANK "gemidyne/warioware/overlays/minigame_blank"
#define OVERLAY_WON "gemidyne/warioware/overlays/minigame_success"
#define OVERLAY_FAIL "gemidyne/warioware/overlays/minigame_failure"
#define OVERLAY_SPEEDUP "gemidyne/warioware/overlays/system_speedup"
#define OVERLAY_SPEEDDN "gemidyne/warioware/overlays/system_speeddown"
#define OVERLAY_BOSS "gemidyne/warioware/overlays/system_bossevent"
#define OVERLAY_GAMEOVER "gemidyne/warioware/overlays/system_gameover"
#define OVERLAY_WELCOME "gemidyne/warioware/overlays/system_waitingforplayers"
#define OVERLAY_SPECIALROUND "gemidyne/warioware/overlays/system_specialround"

char SystemNames[TOTAL_GAMEMODES+1][32];
char SystemMusic[TOTAL_GAMEMODES+1][TOTAL_SYSMUSIC+1][SYSMUSIC_MAXFILES][SYSMUSIC_MAXSTRINGLENGTH];
int SystemMusicCount[TOTAL_GAMEMODES+1][TOTAL_SYSMUSIC+1];
float SystemMusicLength[TOTAL_GAMEMODES+1][TOTAL_SYSMUSIC+1][SYSMUSIC_MAXFILES];

int GamemodeID = 0;
int MaxGamemodesSelectable = 0;


stock void InitializeSystem()
{
	char gameFolder[32];
	GetGameFolderName(gameFolder, sizeof(gameFolder));

	if (!StrEqual(gameFolder, "tf"))
	{
		SetFailState("WarioWare can only be run on Team Fortress 2.");
	}

	if (GetExtensionFileStatus("sdkhooks.ext") < 1) 
	{
		SetFailState("The SDKHooks Extension is not loaded.");
	}

	if (GetExtensionFileStatus("tf2items.ext") < 1)
	{
		SetFailState("The TF2Items Extension is not loaded.");
	}

	if (GetExtensionFileStatus("steamtools.ext") < 1)
	{
		SetFailState("The SteamTools Extension is not loaded.");
	}

	LoadTranslations("microtf2.phrases.txt");

	#if defined LOGGING_STARTUP
	LogMessage("Initializing System...");
	#endif
	
	HookEvents();
	InitializeForwards();
	InitializePluginForwards();
	InitialiseHud();
	LoadOffsets();
	InitializeConVars();
	InitializeCommands();
	InitializeSpecialRounds();
	InitialiseSounds();
	LoadGamemodeInfo();
	InitialiseVoices();

	AddToForward(g_pfOnMapStart, INVALID_HANDLE, System_OnMapStart);
	InitializeMinigames();
	InitialiseWeapons();
}

public void System_OnMapStart()
{
	if (FileExists("bin/server.dll") && FindConVar("sm_timescale_win_fix__version") == INVALID_HANDLE)
	{
		SetFailState("Bakugo's host_timescale fix is required to run this plugin on Windows based servers. Download and install from: https://forums.alliedmods.net/showthread.php?t=324264");
	}

	char gameDescription[32];
	Format(gameDescription, sizeof(gameDescription), "WarioWare (v%s)", PLUGIN_VERSION);
	Steam_SetGameDescription(gameDescription);

	MinigameID = 0;
	BossgameID = 0;
	PreviousMinigameID = 0;
	PreviousBossgameID = 0;
	g_iSpecialRoundId = 0;
	g_iWinnerScorePointsAmount = 1;
	MinigamesPlayed = 0;
	g_iNextMinigamePlayedSpeedTestThreshold = 0;
	BossGameThreshold = 20;
	MaxRounds = g_hConVarPluginMaxRounds.IntValue;
	RoundsPlayed = 0;
	g_fActiveGameSpeed = 1.0;

	IsMinigameActive = false;
	g_bIsMinigameEnding = false;
	g_bIsMapEnding = false;
	g_bIsGameOver = false;
	g_bIsBlockingTaunts = true;
	g_bIsBlockingKillCommands = true;
	g_eDamageBlockMode = EDamageBlockMode_All;

	for (int g = 0; g < TOTAL_GAMEMODES; g++)
	{
		for (int i = 0; i < TOTAL_SYSMUSIC; i++)
		{
			for (int k = 0; k < SystemMusicCount[g][i]; k++)
			{
				// Preload (Precache and Add To Downloads Table) all Sounds needed for every gamemode
				char buffer[SYSMUSIC_MAXSTRINGLENGTH];

				strcopy(buffer, sizeof(buffer), SystemMusic[g][i][k]);

				if (strlen(buffer) > 0)
				{
					PreloadSound(buffer);
				}
			}
		}
	}

	PrecacheMaterial(OVERLAY_MINIGAMEBLANK);
	PrecacheMaterial(OVERLAY_WON);
	PrecacheMaterial(OVERLAY_FAIL);
	PrecacheMaterial(OVERLAY_SPEEDUP);
	PrecacheMaterial(OVERLAY_SPEEDDN);
	PrecacheMaterial(OVERLAY_BOSS);
	PrecacheMaterial(OVERLAY_GAMEOVER);
	PrecacheMaterial(OVERLAY_WELCOME);
	PrecacheMaterial(OVERLAY_SPECIALROUND);
}

public void LoadGamemodeInfo()
{
	char file[128];
	BuildPath(Path_SM, file, sizeof(file), "data/microtf2/Gamemodes.txt");

	KeyValues kv = new KeyValues("Gamemodes");

	if (!kv.ImportFromFile(file))
	{
		SetFailState("Unable to read Gamemodes.txt from data/microtf2/");
		kv.Close();
		return;
	}
 
	if (kv.GotoFirstSubKey())
	{
		do
		{
			int gamemodeId = GetIdFromSectionName(kv);

			// These 2 cannot have the different lengths; they're played at the same time
			kv.GetString("SysMusic_Failure", SystemMusic[gamemodeId][SYSMUSIC_FAILURE][0], SYSMUSIC_MAXSTRINGLENGTH);
			kv.GetFloat("SysMusic_Failure_Length", SystemMusicLength[gamemodeId][SYSMUSIC_FAILURE][0]);

			SystemMusicCount[gamemodeId][SYSMUSIC_FAILURE]++;

			kv.GetString("SysMusic_Winner", SystemMusic[gamemodeId][SYSMUSIC_WINNER][0], SYSMUSIC_MAXSTRINGLENGTH);
			kv.GetFloat("SysMusic_Winner_Length", SystemMusicLength[gamemodeId][SYSMUSIC_WINNER][0]);

			SystemMusicCount[gamemodeId][SYSMUSIC_WINNER]++;

			kv.GetString("FriendlyName", SystemNames[gamemodeId], 32);

			if (kv.GetNum("Selectable", 0) == 1)
			{
				// Selectable Gamemodes must be at the start of the Gamemodes.txt file
				MaxGamemodesSelectable++;
			}

			// Get sections
			LoadSysMusicSection(kv, gamemodeId);

			#if defined LOGGING_STARTUP
			LogMessage("Loaded gamemode %d - %s", gamemodeId, SystemNames[gamemodeId]);
			#endif
		}
		while (kv.GotoNextKey());
	}
 
	kv.Close();
}

stock int GetIdFromSectionName(KeyValues kv)
{
	char buffer[16];

	kv.GetSectionName(buffer, sizeof(buffer));

	return StringToInt(buffer);
}

stock void LoadSysMusicSection(KeyValues kv, int gamemodeId)
{
	if (!kv.GotoFirstSubKey())
	{
		return;
	}

	do
	{
		char section[32];
		kv.GetSectionName(section, sizeof(section));

		int bgmType = 0;

		if (StrEqual(section, "SysMusic_PreMinigame", false))
		{
			bgmType = SYSMUSIC_PREMINIGAME;
		}
		else if (StrEqual(section, "SysMusic_BossTime", false))
		{
			bgmType = SYSMUSIC_BOSSTIME;
		}
		else if (StrEqual(section, "SysMusic_SpeedUp", false))
		{
			bgmType = SYSMUSIC_SPEEDUP;
		}
		else if (StrEqual(section, "SysMusic_GameOver", false))
		{
			bgmType = SYSMUSIC_GAMEOVER;
		}

		if (kv.GotoFirstSubKey())
		{
			int idx = 0;

			do
			{
				kv.GetString("File", SystemMusic[gamemodeId][bgmType][idx], SYSMUSIC_MAXSTRINGLENGTH);

				SystemMusicLength[gamemodeId][bgmType][idx] = kv.GetFloat("Length");
				SystemMusicCount[gamemodeId][bgmType]++;
			}
			while (kv.GotoNextKey());

			kv.GoBack();
		}
	}
	while (kv.GotoNextKey());

	kv.GoBack();
}

stock void LoadOffsets()
{
	g_oCollisionGroup = TryFindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	g_oWeaponBaseClip1 = TryFindSendPropInfo("CTFWeaponBase", "m_iClip1");
	g_oPlayerActiveWeapon = TryFindSendPropInfo("CTFPlayer", "m_hActiveWeapon");
	g_oPlayerAmmo = TryFindSendPropInfo("CTFPlayer", "m_iAmmo");
}

stock void PrecacheMaterial(const char[] material)
{
	char path[128];

	Format(path, sizeof(path), "materials/%s", material);
	PrecacheGeneric(path, true);
}

stock int TryFindSendPropInfo(const char[] cls, const char[] prop)
{
	int offset = FindSendPropInfo(cls, prop);

	if (offset <= 0)
	{
		char message[64];

		Format(message, sizeof(message), "Unable to find %s prop on %s.", prop, cls);

		SetFailState(message);
	}

	return offset;
}