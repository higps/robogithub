#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <clientprefs>
#include <morecolors_newsyntax>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

//Define version number in a needlessly complex way
#define MAJOR	"2"
#define MINOR	"1"
#define PATCH	"2"
#define PLUGIN_VERSION	MAJOR..."."...MINOR..."."...PATCH

// Debug "Mode"
//#define DEBUG	//Uncomment for "debug" stuff. Just some 'PrintToChatAll's here and there.

/* Enum Strcuts */

enum struct ClientFlags
{
	int DisplayHUDText;
	int TimerCooldown;
	
	//HUD Text Editing
	
	int EditHUDTextMode_Movement;
	int EditHUDTextMode_Chat;
	int EHTMM_Cooldown;
	
	int ButtonPressed;
}

//Enums
enum PadHudTextFlags
{
	PHTF_NONE,
	PHTF_ShowText,
	PHTF_ShowText_MinMode,
	PHTF_MAX_FLAGS
}
enum PadCond (<<= 1)	//Custom Conditions - Use Pad_IsPlayerInCond() to see if a Custom Condition is active on a player.
{
	PadCond_None = 0,		// 0 << 0 = 0
	PadCond_Boost = 1,		// 1 << 0 = 1
	PadCond_NoFallDmg,		// 1 << 1 = 2
	PadCond_DelayResponse	// 1 << 2 = 4
}

enum //Custom ObjectType
{
	PadType_None = 0,
	PadType_Boost,
	PadType_Jump
}

enum //Teleporter states
{
	TELEPORTER_STATE_BUILDING = 0,				// Building, not active yet
	TELEPORTER_STATE_IDLE,						// Does not have a matching teleporter yet
	TELEPORTER_STATE_READY,						// Found match, charged and ready
	TELEPORTER_STATE_SENDING,					// Teleporting a player away
	TELEPORTER_STATE_RECEIVING,					
	TELEPORTER_STATE_RECEIVING_RELEASE,
	TELEPORTER_STATE_RECHARGING,				// Waiting for recharge
	TELEPORTER_STATE_UPGRADING					// Upgrading
}

enum //CvarName
{
	PadsEnabled,
	PadsAnnounce,
	PadSize,
	PadHealth,
	JumpSpeed,
	JumpHeight,
	JumpCrouchSpeedMult,
	JumpCrouchHeightMult,
	JumpBlockSnipers,
	JumpCooldown,
	BoostDuration,
	BoostSpeed,
	BoostDamage,
	BoostAirblast,
	BoostBlockAiming,
	BoostCooldown,
	BotsCanBuild,
	BlockEureka,
	DisguiseNeeded,
	VersionNumber
}

enum //Plugin Enabled states
{
	EngiPads_Disabled,
	EngiPads_Enabled,
	EngiPads_BoostOnly,
	EngiPads_JumpOnly
}
/* Global vars */

static int g_iPadType[2048];
static int g_iObjectParticle[2048];
static int g_iPlayerDamageTaken[MAXPLAYERS + 1];

static float g_flPlayerBoostEndTime[MAXPLAYERS + 1];

static PadCond g_fPadCondFlags[MAXPLAYERS + 1];

int g_cf_PadToggleDelay; // Bit Flag
//int g_iWeaponBuilders[MAXPLAYERS+1];

//Stores the x/y positions from the HUD Text cookie for use in editing positions
float g_flETHM_Pos[MAXPLAYERS+1][2];
float g_flETHM_Text_Movespeed[MAXPLAYERS+1];

//int g_iWeaponBuilders[MAXPLAYERS+1];

static char g_szOffsetStartProp[64];
static int g_iOffsetMatchingTeleporter = -1;

static Handle g_hPadCookie;
static Handle g_hPadTimerAnnounce;

//Handle g_hHUDSync;

Handle g_hGameConf;
Handle g_hWeaponBuilderDeploy;
Handle g_hWeaponBuilderHolster;
Handle g_hHUDSync;
Handle g_Cookie_PadHUDText;

Regex g_rMatchFloats;

Menu menu_PadHUDText;

//Enum structs
ClientFlags cf;
/* Convars */
ConVar cvarPads[VersionNumber + 1];


public Plugin myinfo =
{
	name 			= "[TF2] Engineer Pads",
	author 			= "Starblaster 64",
	description 	= "Custom Teleporter building replacements.",
	version 		= PLUGIN_VERSION,
	url 			= "https://forums.alliedmods.net/showthread.php?t=304025"
};

//Initialise gamedata to be used for getting/setting Teleporter pairs.
void InitGamedata()
{
	Handle hGameConf = LoadGameConfigFile("tf2.teleporters");
	if (hGameConf == INVALID_HANDLE)
	{
		SetFailState("[EngiPads] Unable to load gamedata file 'tf2.teleporters.txt'");
	}
	
	bool bFoundProp = GameConfGetKeyValue(hGameConf, "StartProp", g_szOffsetStartProp, sizeof(g_szOffsetStartProp));
	g_iOffsetMatchingTeleporter = GameConfGetOffset(hGameConf, "m_hMatchingTeleporter");
	
	if (!bFoundProp || g_iOffsetMatchingTeleporter < 0)
	{
		SetFailState("[EngiPads] Unable to get m_hMatchingTeleporter offset from 'tf2.teleporters.txt'. Check gamedata!");
	}
	
	CloseHandle(hGameConf);
}

public void OnPluginStart()
{	
	//GameConfig
	g_hGameConf = LoadGameConfigFile("bm_engipads_data");
	
	InitGamedata();
	
	RemovePadToggleFlag();
	
	menu_PadHUDText = new Menu(MenuHandler_PadEditHUDText, MENU_ACTIONS_ALL);
	
	//RegAdminCmd("sm_testdp", Command_TestDP, ADMFLAG_SLAY, "");
	
	RegConsoleCmd("sm_pad", TogglePadsMenuCmd);
	RegConsoleCmd("sm_pads", TogglePadsMenuCmd);
	RegConsoleCmd("sm_pad_help", ShowPadsInfoCmd);
	RegConsoleCmd("sm_padhelp", ShowPadsInfoCmd);
	
	AddCommandListener(Command_ReadChat, "say");
	AddCommandListener(Command_ReadChat, "say_team");
	
	AddCommandListener(EurekaTeleport, "eureka_teleport");
	
	cvarPads[VersionNumber] = CreateConVar("pads_version", PLUGIN_VERSION, "EngiPads version number. Don't touch this!", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT);
	cvarPads[PadsEnabled] = CreateConVar("pads_enabled", "1", "Enables/Disables the plugin. (2 - BoostPads only, 3 - JumpPads only)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	cvarPads[PadsAnnounce] = CreateConVar("pads_announce", "347.0", "Interval between chat announcements about the plugin. 0.0 to disable.", FCVAR_NOTIFY, true, 0.0);
	
	cvarPads[PadSize] = CreateConVar("pads_size", "0.7", "Pad size multiplier.", FCVAR_NOTIFY, true, 0.0, true, 5.0);
	cvarPads[PadHealth] = CreateConVar("pads_health", "100", "How much HP Pads will have.", FCVAR_NOTIFY, true, 1.0);
	cvarPads[JumpSpeed] = CreateConVar("pads_jump_speed", "700.0", "How fast players will be launched horizontally by Jump Pads.", FCVAR_NOTIFY, true, 0.0);
	cvarPads[JumpHeight] = CreateConVar("pads_jump_height", "700.0", "How fast players will be launched vertically by Jump Pads.", FCVAR_NOTIFY, true, 0.0);
	cvarPads[JumpCrouchSpeedMult] = CreateConVar("pads_jump_crouch_speed_mult", "1.0", "Multiply crouching players' speed by this much when using Jump Pads.", FCVAR_NOTIFY, true, 0.0);
	cvarPads[JumpCrouchHeightMult] = CreateConVar("pads_jump_crouch_height_mult", "1.0", "Multiply crouching players' height by this much when using Jump Pads.", FCVAR_NOTIFY, true, 0.0);
	cvarPads[JumpBlockSnipers] = CreateConVar("pads_jump_block_snipers", "1", "If enabled, prevents Snipers from scoping in while using Jump Pads.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarPads[JumpCooldown] = CreateConVar("pads_jump_cooldown", "3.0", "How long, in seconds, should Jump Pads take to recharge?", FCVAR_NOTIFY, true, 0.1);
	cvarPads[BoostDuration] = CreateConVar("pads_boost_duration", "5.0", "How long, in seconds, should Boost Pads boost players for?", FCVAR_NOTIFY, true, 0.0);
	cvarPads[BoostSpeed] = CreateConVar("pads_boost_speed", "520.0", "What minimum speed should players be boosted to when using Boost Pads?", FCVAR_NOTIFY, true, 0.0);
	cvarPads[BoostDamage] = CreateConVar("pads_boost_damage_threshold", "35", "How much damage can a boosted player take before losing their boost? 0 to disable.", FCVAR_NOTIFY, true, 0.0);
	cvarPads[BoostAirblast] = CreateConVar("pads_boost_airblast", "1", "Should boosted players lose their boost when airblasted?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarPads[BoostBlockAiming] = CreateConVar("pads_boost_block_aiming", "1", "Set to 1 to prevent scoped-in/revved up players from being speed boosted.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarPads[BoostCooldown] = CreateConVar("pads_boost_cooldown", "3.0", "How long in seconds should Boost Pads take to recharge?", FCVAR_NOTIFY, true, 0.1);
	cvarPads[BotsCanBuild] = CreateConVar("pads_bots_can_build", "0", "If enabled, Bots will build Boost Pads instead of Teleporters.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarPads[BlockEureka] = CreateConVar("pads_block_eureka", "1", "Toggle blocking Eureka Effect from teleporting to Pads that are Exits.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarPads[DisguiseNeeded] = CreateConVar("pads_need_disguise", "0", "Toggle if spies need a disguise to use pads.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "engipads");
	LoadTranslations("engipads.phrases");
	
	//Cookies
	g_hPadCookie = RegClientCookie("engipads_toggle", "Client's EngiPads toggle preference.", CookieAccess_Protected);
	
	//Hooks
	cvarPads[VersionNumber].AddChangeHook(CvarChange);
	cvarPads[PadsEnabled].AddChangeHook(CvarChange);
	cvarPads[PadsAnnounce].AddChangeHook(CvarChange);
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", OnLoadoutRefresh, EventHookMode_Pre);
	HookEvent("player_death", PlayerDeath, EventHookMode_Post);
	HookEvent("player_hurt", PlayerHurt, EventHookMode_Post);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	
	HookEvent("player_builtobject", ObjectBuilt, EventHookMode_Post);
	HookEvent("player_sapped_object", ObjectSapped, EventHookMode_Post);
	HookEvent("player_carryobject", ObjectDestroyed, EventHookMode_Post);
	
	HookEvent("object_destroyed", ObjectDestroyed, EventHookMode_Post);
	HookEvent("object_removed", ObjectDestroyed, EventHookMode_Post);
	
	HookEvent("object_deflected", ObjectDeflected, EventHookMode_Post);
	
	AddNormalSoundHook(HookSound);
	
	/* Hud Text Stuff*/
	
	/* Dhooks */
	
	//Holster
	g_hWeaponBuilderHolster = DHookCreate(0, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, OnWeaponBuilderHolster);
	if(g_hWeaponBuilderHolster == null) SetFailState("Failed to setup hook for CTFWeaponBuilder::Holster!"); 
	
	DHookAddParam(g_hWeaponBuilderHolster, HookParamType_CBaseEntity);
	
	if(!DHookSetFromConf(g_hWeaponBuilderHolster, g_hGameConf, SDKConf_Virtual, "CTFWeaponBuilder::Holster"))
	SetFailState("Failed to find CTFWeaponBuilder::Holster offset in the gamedata!");
	
	//Deploy
	g_hWeaponBuilderDeploy = DHookCreate(0, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, OnWeaponBuilderDeploy);
	if(g_hWeaponBuilderDeploy == null) SetFailState("Failed to setup hook for CTFWeaponBuilder::Deploy!"); 
	
	if(!DHookSetFromConf(g_hWeaponBuilderDeploy, g_hGameConf, SDKConf_Virtual, "CTFWeaponBuilder::Deploy"))
	SetFailState("Failed to find CTFWeaponBuilder::Deploy offset in the gamedata!");
	
	// Entity Listener
	DHookAddEntityListener(ListenType_Created, HookBuilders);
	
	//Hook existing builders if late loaded
	FindAndHookBuilders();
	
	/* Other */
	g_rMatchFloats = CompileRegex("(-?\\d{1,7}[.]-?\\d{1,7}) (-?\\d{1,7}[.]-?\\d{1,7}) (\\d{1,1})|(-?\\d{1,7}[.]-?\\d{1,7}) (-?\\d{1,7}[.]-?\\d{1,7})", PCRE_CASELESS);
	g_hHUDSync = CreateHudSynchronizer();
	g_Cookie_PadHUDText = RegClientCookie("Pad_HUD_Text_Pos", "Holds client specific HUD text position.", CookieAccess_Protected);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		OnClientPostAdminCheck(i);
	}
	
	delete g_hGameConf;
}
public void OnClientCookiesCached(int client)
{
	SetupHUDTextCookie2(client);
}
void FindAndHookBuilders()
{
	int iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_weapon_builder")) != -1)
	{
		DHookEntity(g_hWeaponBuilderDeploy, true, iEntity);
		DHookEntity(g_hWeaponBuilderHolster, true, iEntity);
	}
}
public void HookBuilders(int entity, const char[] classname)
{
	if(strcmp("tf_weapon_builder", classname) == 0)
	{		
		DHookEntity(g_hWeaponBuilderDeploy, true, entity);
		DHookEntity(g_hWeaponBuilderHolster, true, entity);
	}
}
public MRESReturn OnWeaponBuilderDeploy(int pThis, Handle hReturn, Handle hParams)
{
	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");
		
	DisplayPadBeingBuilt(client);
	
	#if defined DEBUG
	PrintToChatAll("Builder deployed, %N", client);
	#endif
	return MRES_Ignored;
}
public MRESReturn OnWeaponBuilderHolster(int pThis, Handle hReturn, Handle hParams)
{
	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");
	
	ClearPadHUDText(client);
	
	#if defined DEBUG
	PrintToChatAll("Builder holstered, %N", client);
	#endif
	
	return MRES_Ignored;
}
public void OnPluginEnd()
{
	ClearAllPadHudText();
	ConvertAllPadsToTeleporters(); //Convert all Pads back to teleporters if the plugin is unloaded.
}
public void OnConfigsExecuted()
{
	/* Version checker taken from VSH */
	static char szOldVersion[12];
	cvarPads[VersionNumber].GetString(szOldVersion, sizeof(szOldVersion));
	if (!StrEqual(szOldVersion, PLUGIN_VERSION))
		cvarPads[VersionNumber].SetString(PLUGIN_VERSION, false, true);
	
	if (cvarPads[PadsEnabled].IntValue > EngiPads_Disabled && cvarPads[PadsAnnounce].FloatValue > 0.0)
	{
		g_hPadTimerAnnounce = CreateTimer(cvarPads[PadsAnnounce].FloatValue, Timer_PadsAnnounce, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void CvarChange(ConVar cvar, const char[] szOldValue, const char[] szNewValue)
{
	if (cvar == cvarPads[VersionNumber])
	{
		if (!StrEqual(szNewValue, PLUGIN_VERSION))
			cvarPads[VersionNumber].SetString(PLUGIN_VERSION);	//If config version number does not match plugin, plugin will override it.
	}
	else if (cvar == cvarPads[PadsEnabled])
	{
		if (RoundToFloor(StringToFloat(szNewValue)) == EngiPads_Disabled && RoundToFloor(StringToFloat(szOldValue)) > EngiPads_Disabled)
		{
			ConvertAllPadsToTeleporters();
			ClearTimer(g_hPadTimerAnnounce);
		}
		else if (cvarPads[PadsAnnounce].FloatValue > 0.0 && RoundToFloor(StringToFloat(szOldValue)) == EngiPads_Disabled)
		{
			ClearTimer(g_hPadTimerAnnounce);
			g_hPadTimerAnnounce = CreateTimer(cvarPads[PadsAnnounce].FloatValue, Timer_PadsAnnounce, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if (cvar == cvarPads[PadsAnnounce])
	{
		if (StringToFloat(szNewValue) > 0.0 && cvarPads[PadsEnabled].IntValue > EngiPads_Disabled)
		{
			ClearTimer(g_hPadTimerAnnounce);
			g_hPadTimerAnnounce = CreateTimer(cvarPads[PadsAnnounce].FloatValue, Timer_PadsAnnounce, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (StringToFloat(szNewValue) <= 0.0)
		{
			ClearTimer(g_hPadTimerAnnounce);
		}
	}
}

public Action Timer_PadsAnnounce(Handle hTimer)
{
	if (cvarPads[PadsEnabled].IntValue == EngiPads_Disabled || cvarPads[PadsAnnounce].FloatValue <= 0.0)
	{
		g_hPadTimerAnnounce = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	int iAnnouncement = GetRandomInt(0, 5);
	
	switch (iAnnouncement)
	{
		case 0:
		{
			MC_PrintToChatAll("{orange}[EngiPads]{default} %t", "padphrase_announcement1", PLUGIN_VERSION);
		}
		default:
		{
			MC_PrintToChatAll("{orange}[EngiPads]{default} %t", "padphrase_announcement2");
		}
	}
	
	g_hPadTimerAnnounce = CreateTimer(cvarPads[PadsAnnounce].FloatValue, Timer_PadsAnnounce, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	RemovePadToggleFlag();
	ResetAllFlags();
	
	g_hPadTimerAnnounce = INVALID_HANDLE;
	
	/* Precache Sounds */
	PrecacheSound(")items/powerup_pickup_haste.wav", true);	//For some reason, using PrecacheScriptSound doesn't work for this sound.
	PrecacheScriptSound("Passtime.BallSmack");
	//The other gamesounds I emit should already be precached by the game
	
	/* Precache Particles */
	PrecacheParticleSystem("powerup_icon_haste_red");
	PrecacheParticleSystem("powerup_icon_haste_blue");
	
	PrecacheParticleSystem("powerup_icon_agility_red");
	PrecacheParticleSystem("powerup_icon_agility_blue");
}

public void OnMapEnd()
{
	ClearTimer(g_hPadTimerAnnounce);
}

public void OnClientPostAdminCheck(int client)
{
	//Reset players' global vars on connect/disconnect/death/pluginstart
	Pad_SetConds(client, PadCond_None);
	g_iPlayerDamageTaken[client] = 0;
	g_flPlayerBoostEndTime[client] = 0.0;
}
public void OnClientPutInServer(int client)
{
	SetupHUDTextCookie2(client);
}
public void OnClientDisconnect(int client)
{
	OnClientPostAdminCheck(client);
}
public Action OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(HasFlag(client, g_cf_PadToggleDelay))
	{
		g_cf_PadToggleDelay = RemoveFlag(client, g_cf_PadToggleDelay);
	}
	ClearPadHUDText(client);
	
	return Plugin_Continue;
}
public void PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsValidClient(client))
	OnClientPostAdminCheck(client);
	
	ClearPadHUDText(client);
}

public void PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarPads[BoostDamage].IntValue <= 0)
		return;
	
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iDamage = event.GetInt("damageamount");
	
	if (iAttacker != iVictim && Pad_IsPlayerInCond(iVictim, PadCond_Boost))	//Ignore self damage
	{
		g_iPlayerDamageTaken[iVictim] += iDamage;
		if (g_iPlayerDamageTaken[iVictim] >= cvarPads[BoostDamage].IntValue)
		{
			g_flPlayerBoostEndTime[iVictim] = 0.0;
		}
	}
}

public void ObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	if (!cvarPads[BoostAirblast].BoolValue)
		return;
	
	int iOwner = GetClientOfUserId(event.GetInt("ownerid"));
	int iWeapon = event.GetInt("weaponid");
	
	if (!iWeapon && IsValidClient(iOwner) && Pad_IsPlayerInCond(iOwner, PadCond_Boost))		//0 means ownerid was airblasted
	{
		g_flPlayerBoostEndTime[iOwner] = 0.0;
	}
}

public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)
		return;
	
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	
	if (!GetClientPadsEnabled(iBuilder) || cvarPads[PadsEnabled].IntValue == EngiPads_Disabled || !CheckCommandAccess(iBuilder, "sm_engipads_override", 0))
	{

		if (g_iPadType[iObj])
		{
				ConvertPadToTeleporter(iObj);
		}
		if (TF2_GetMatchingTeleporter(iObj) == iObj)
		{
			 TF2_SetMatchingTeleporter(iObj, -1);	//Reset m_hMatchingTeleporter if the buidling is no longer a Pad.
		}
		return;
	}

	ConvertTeleporterToPad(iObj, GetPadType(iObj), GetEntProp(iObj, Prop_Send, "m_bCarryDeploy") ? false : true);

					#if defined DEBUG
					PrintToChatAll("Converting to Pad %i", iObj);
					#endif

	
	PrintPadTypeNameToClient(g_iPadType[iObj], iBuilder);
}

public void ObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	//int client = GetClientOfUserId(event.GetInt("userid"));
	
	int iObj = event.GetInt("index");
	if ((view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter && view_as<TFObjectType>(event.GetInt("objecttype")) != TFObject_Teleporter) || !g_iPadType[iObj])
		return;
	
	int iObjParti = EntRefToEntIndex(g_iObjectParticle[iObj]);
	if (IsValidEntity(iObjParti))
		AcceptEntityInput(iObjParti, "Kill");
	g_iObjectParticle[iObj] = -1;
	
	#if defined DEBUG
	PrintToChatAll("%i Destroyed!", iObj);
	#endif
	
	if (!StrEqual(name, "player_carryobject"))
		g_iPadType[iObj] = PadType_None;
	
}

public void ObjectSapped(Event event, const char[] name, bool dontBroadcast)
{
	int iSapper = event.GetInt("sapperid");
	int iObj = GetEntPropEnt(iSapper, Prop_Send, "m_hBuiltOnEntity");
	
	if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter || !g_iPadType[iObj])
		return;
	
	SetVariantInt(GetEntProp(iSapper, Prop_Send, "m_iMaxHealth") * 2);
	AcceptEntityInput(iSapper, "SetHealth", iSapper); //Double Sapper HP. Since I set the Tele's matching Tele to itself, Sappers take 2 instances of damage per hit.
	
	SetEntPropFloat(iSapper, Prop_Send, "m_flModelScale", cvarPads[PadSize].FloatValue);	//Scale down Sapper to match Pad size.
}

public Action HookSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
		int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
		char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (IsValidEntity(entity))
	{
		char className[64];
		GetEntityClassname(entity, className, sizeof(className));
	
		if (StrEqual(className, "obj_attachment_sapper") && TF2_GetObjectType(entity) == TFObject_Sapper && channel == SNDCHAN_STATIC)
		{
			if (GetEntPropEnt(entity, Prop_Send, "m_hBuiltOnEntity") == -1)
			{
				if (StrEqual(sample, "weapons/sapper_timer.wav") || StrContains(sample, "spy_tape") != -1)
				{
					return Plugin_Handled;	//I need to block the duplicate sapping sound otherwise it'll loop forever.
				}
			}
		}
	}
		
	return Plugin_Continue;
}

public Action EurekaTeleport(int client, const char[] szCommand, int nArgs)
{
	if (cvarPads[PadsEnabled].IntValue == EngiPads_Disabled || !cvarPads[BlockEureka].BoolValue)
		return Plugin_Continue;
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		char arg[8]; GetCmdArg(1, arg, sizeof(arg));
		int iDest = StringToInt(arg);
		
		if (iDest != 1 || !GetCmdArgs())	//If teleport destination is not 1 or unspecified (Spawn)
			return Plugin_Continue;
		
		int i = -1;
		while ((i = FindEntityByClassname2(i, "obj_teleporter")) != -1)
		{
			if (IsValidEntity(i) && g_iPadType[i] && TF2_GetObjectMode(i) == TFObjectMode_Exit)
			{
				EmitGameSoundToClient(client, "Player.UseDeny", client);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public void OnGameFrame()
{
	if (cvarPads[PadsEnabled].IntValue == EngiPads_Disabled)
		return;
	
	int i = -1;
	while ((i = FindEntityByClassname2(i, "obj_teleporter")) != -1)
	{
		if (IsValidEntity(i))
		{
			if (g_iPadType[i])
			{
				OnPadThink(i);
			}
			else if (g_iPadType[i] == PadType_None && !GetEntProp(i, Prop_Send, "m_bWasMapPlaced"))
			{
				int iMatch = TF2_GetMatchingTeleporter(i);
				if (IsValidEntity(iMatch))
				{
					if ((g_iPadType[iMatch] || iMatch == i) && !GetEntProp(i, Prop_Send, "m_bDisabled"))
					{
						TF2_DisableObject(i);	//Disable Teleporters that are matched with Pads.
						if (iMatch != i)
							TF2_SetMatchingTeleporter(i, i);	//Unlink them so upgrades/sappers don't transfer over.
					}
				}
			}
		}
	}
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	/*
	int iOldButton = GetEntProp(client, Prop_Data, "m_nOldButtons");
	int iButton = GetEntProp(client, Prop_Data, "m_nButtons");
	int iButtonLast = GetEntProp(client, Prop_Data, "m_afButtonLast");
	int iButtonPressed = GetEntProp(client, Prop_Data, "m_afButtonPressed");
	int iButtonReleased = GetEntProp(client, Prop_Data, "m_afButtonReleased");
	int iButtonDisabled = GetEntProp(client, Prop_Data, "m_afButtonDisabled");
	int iButtonForced = GetEntProp(client, Prop_Data, "m_afButtonForced");
	//if(buttons)
	PrintToChatAll("iButtons - OB: %i B: %i L: %i P: %i R: %i D: %i F: %i", iOldButton, iButton, iButtonLast, iButtonPressed, iButtonReleased, iButtonDisabled, iButtonForced);
	*/
	
	if(buttons & IN_ATTACK3 && IsButtonPressed(client, IN_ATTACK3))
	{
		if(TF2_GetPlayerClass(client) == TFClass_Engineer 
		&& !HasFlag(client, g_cf_PadToggleDelay))
		{
			g_cf_PadToggleDelay = AddFlag(client, g_cf_PadToggleDelay);
			CreateTimer(0.375, Timer_PadToggleDelay, client);
			
			if(GetClientPadsEnabled(client))
			{
				SetClientPadsEnabled(client, false);
				
				ClientCommand(client, "playgamesound replay/deleted_take.wav");
				MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_disabled");
				//PrintToConsole(client, "[EngiPads] %t", "padphrase_disabled");
				DisplayPadBeingBuilt(client);
			}
			else
			{
				SetClientPadsEnabled(client, true);
				
				ClientCommand(client, "playgamesound replay/downloadcomplete.wav");
				MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_enabled");
				//PrintToConsole(client, "[EngiPads] %t", "padphrase_enabled");
				DisplayPadBeingBuilt(client);
			}
		}
	}
	if(buttons & IN_ATTACK2 && IsButtonPressed(client, IN_ATTACK2))
	{
		DisplayPadBeingBuilt(client);
	}
	if(HasFlag(client, cf.EditHUDTextMode_Movement) && buttons)
	{
		EditPadHUDText(client, buttons);
	}
}
Action Timer_PadToggleDelay(Handle timer, int client)
{
	RemovePadToggleFlag(client);
}

void RemovePadToggleFlag(int client = -1)
{
	if(client == -1)
	{
		g_cf_PadToggleDelay = 0;
	}
	else if(IsValidClient(client))
	{
		g_cf_PadToggleDelay = RemoveFlag(client, g_cf_PadToggleDelay);
	}
}
stock bool IsButtonHeld(int client, int buttons)
{
	int iButtonLast = GetEntProp(client, Prop_Data, "m_afButtonLast");
	
	if(iButtonLast & buttons)
	{
		return true;
	}
	return false;
}
stock bool IsButtonPressed(int client, int buttons)
{
	int iButtonPressed = GetEntProp(client, Prop_Data, "m_afButtonPressed");
	
	if(iButtonPressed & buttons)
	{
		//PrintToChatAll("Button pressed %i", buttons);
		return true;
	}
	return false;
}
stock bool IsButtonReleased(int client, int buttons)
{
	int iButtonReleased = GetEntProp(client, Prop_Data, "m_afButtonReleased");
	
	if(iButtonReleased & buttons)
	{
		return true;
	}
	return false;
}
stock bool HasFlag(int client, int iFlags)
{
	if(iFlags & 1 << client) return true;
	return false;
}
stock int AddFlag(int client, int iFlags)
{
	if(!HasFlag(client, iFlags))
	{
		iFlags |= 1 << client;
		return iFlags;
	}
	return iFlags;
}
stock int RemoveFlag(int client, int iFlags)
{
	if(HasFlag(client, iFlags))
	{
		iFlags &= ~(1 << client);
		return iFlags;
	}
	return iFlags;
}
/* Hud TEXT Stuff */
public Action Command_ReadChat(int client, const char[] command, int args)
{	
	/*
	char sCommand[32];
	GetCmdArgString(sCommand, sizeof(sCommand));
	StripQuotes(sCommand);
	PrintToChat(client, "sbuffer: %s, args: %i", sCommand, args);
	*/
	
	//seriously, chat is weird, if you type in say commands in console, it counts args correctly but not in the chatbox.
	
	if(HasFlag(client, cf.EditHUDTextMode_Chat)) 
	{
		if(args > 0)
		{
			char sBufferXY[32];
			
			GetCmdArgString(sBufferXY, sizeof(sBufferXY));
			StripQuotes(sBufferXY);
			//PrintToChatAll("sBuffer: %s", sBufferXY);
			
			if(!SetUserHUDPos2(client, sBufferXY))
			{
				ClearPadHUDText(client);
				MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_fail");
			}
			else
			{
				float x;
				float y;
				
				GetUserHUDPos2(client, x, y);
				
				ClearPadHUDText(client);

				ShowPadEditHUDText(client, x, y, 3.0, _, "Saved!\nX pos set: %f\nY pos set: %f", x, y);
				
				MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_success");
			}
			
			return Plugin_Stop;
		}
		else
		{
			ClearPadHUDText(client);
			MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_fail");
			
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
bool EditPadHUDText(int client, int buttons)
{
	float x = g_flETHM_Pos[client][0];
	float y = g_flETHM_Pos[client][1];
	
	float flTextspeed = g_flETHM_Text_Movespeed[client];
	
	//Use your movement keys to edit HUD text position.\nCrouch to toggle text move speed!\nJump to stop editing!
	
	if(HasFlag(client, cf.EHTMM_Cooldown)) return false;
	
	cf.EHTMM_Cooldown = AddFlag(client, cf.EHTMM_Cooldown);
	
	switch(buttons)
	{
		case IN_MOVELEFT:
		{
			x -= flTextspeed;
			
			if(x < 0.0 && x > -1.0)
			{
				x = 1.0;
			}
			else if(x < -1.0)
			{
				x = 1.0;
			}
		}
		case IN_MOVERIGHT:
		{
			x += flTextspeed;
			
			if(x > 1.0)
			{
				x = 0.0;
			}
			else if(x > -1.0 && x < 0.0)
			{
				x = 0.0;
			}
		}
		case IN_FORWARD:
		{
			y -= flTextspeed;
			
			if(y < 0.0 && y > -1.0)
			{
				y = 1.0;
			}
			else if(y < -1.0)
			{
				y = 1.0;
			}
		}
		case IN_BACK:
		{
			y += flTextspeed;
			
			if(y > 1.0) 
			{
				y = 0.0;
			}
			else if(y > -1.0 && y < 0.0)
			{
				y = 0.0;
			}
		}
	}
	
	CreateTimer(0.25, Timer_EditTextCooldown, client);
	
	ShowPadEditHUDText(client, x, y, _, _, "Sample Text\nCurrent X pos: %f\nCurrent Y pos: %f", x, y);
	DrawPadHUDPosPanel(client, 1);
	
	SetETHMArrays(client, x, y, flTextspeed);
	
	return true;
}
Action Timer_EditTextCooldown(Handle timer, int client)
{
	cf.EHTMM_Cooldown = RemoveFlag(client, cf.EHTMM_Cooldown);
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	Pad_SetConds(client, PadCond_None); //Resetting so you can use the pads again if you have used one before respawning

	ClearPadHUDText(client);
	
	DisplayPadBeingBuilt(client);
	
	return Plugin_Continue;
}
public Action OnLoadoutRefresh(Event event, const char[] name, bool dontBroadcast)
{
	//int client = GetClientOfUserId(event.GetInt("userid"));
	
	return Plugin_Continue;
}
void ResetAllFlags()
{
	cf.DisplayHUDText = 0;
	cf.TimerCooldown = 0;

	//HUD Text Editing

	cf.EditHUDTextMode_Movement = 0;
	cf.EditHUDTextMode_Chat = 0;
	cf.EHTMM_Cooldown = 0;
}
bool StartPadHudTextEdit(int client, int mode)
{
	if(HasFlag(client, cf.DisplayHUDText))
	{
		MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_deny_edit");
		return false;
	}
	
	if(HasFlag(client, cf.EditHUDTextMode_Chat))
	{
		ClearPadHUDText(client);
		MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_chat_disabled");
		return false;
	}
	else if(HasFlag(client, cf.EditHUDTextMode_Movement))
	{
		ClearPadHUDText(client);
		MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_movement_disabled");
		return false;
	}
	
	switch(mode)
	{
		case 0: // Chat
		{
			cf.EditHUDTextMode_Chat = AddFlag(client, cf.EditHUDTextMode_Chat);
			
			float x;
			float y;
			
			GetUserHUDPos2(client, x, y);
			
			MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_chat_enabled");
			DrawPadHUDPosPanel(client, 0);
			ShowPadEditHUDText(client, x, y, _, _, "Sample Text\nCurrent X pos: %f\nCurrent Y pos: %f", x, y);
			
			
			return true;
		}
		case 1: // Movement
		{
			int iEntityFlags = GetEntityFlags(client);
			
			cf.EditHUDTextMode_Movement = AddFlag(client, cf.EditHUDTextMode_Movement);
			
			iEntityFlags |= FL_ATCONTROLS;
			
			SetEntityFlags(client, iEntityFlags);
			
			float x;
			float y;
			
			GetUserHUDPos2(client, x, y);
			
			SetETHMArrays(client, x, y);
			
			MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_movement_enabled");
			
			ShowPadEditHUDText(client, x, y, _, _, "Sample Text\nCurrent X pos: %f\nCurrent Y pos: %f", x, y);
			DrawPadHUDPosPanel(client, 1);
			
			
			return true;
		}
		case 2: //Default
		{
			char sBuffer[32];

			float x = -1.0;
			float y = -1.0;
			
			FormatEx(sBuffer, sizeof(sBuffer), "%f %f", x, y);
			SetUserHUDPos2(client, sBuffer);
			
			MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_set_default");
			ShowPadEditHUDText(client, x, y, 3.0, _, "Restored to default!\nX pos set: %f\nY pos set: %f", x, y);
			
			return true;
		}
	}
	return false;
}
bool ClearPadHUDText(int client)
{
	if(HasFlag(client, cf.DisplayHUDText))
	{
		ShowPadHUDText(client, -1.0, -1.0, 0.1, _, ""); //Used to fully clear the message after using indefinite text duration
		
		cf.DisplayHUDText = RemoveFlag(client, cf.DisplayHUDText);
		ClearSyncHud(client, g_hHUDSync);
		
		FakeClientCommand(client, "menuselect 0"); //Close any menus open
		
		return true;
	}
	else if(HasFlag(client, cf.EditHUDTextMode_Chat))
	{
		ShowPadHUDText(client, -1.0, -1.0, 0.1, _, "");
		cf.EditHUDTextMode_Chat = RemoveFlag(client, cf.EditHUDTextMode_Chat);
		ClearSyncHud(client, g_hHUDSync);
		
		FakeClientCommand(client, "menuselect 0"); //Close any menus open
		
		return true;
	}
	else if(HasFlag(client, cf.EditHUDTextMode_Movement))
	{
		ShowPadHUDText(client, -1.0, -1.0, 0.1, _, "");
		int iEntityFlags = GetEntityFlags(client);
		
		iEntityFlags &= ~FL_ATCONTROLS;
		SetEntityFlags(client, iEntityFlags);
		
		cf.EditHUDTextMode_Movement = RemoveFlag(client, cf.EditHUDTextMode_Movement);
		
		ClearSyncHud(client, g_hHUDSync);
		
		FakeClientCommand(client, "menuselect 0"); //Close any menus open
		return true;
	}
	return false;
}
void ClearAllPadHudText()
{
	for(int client = 1; client < MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(HasFlag(client, cf.DisplayHUDText))
			{
				ShowPadHUDText(client, -1.0, -1.0, 0.1, _, "");
				cf.DisplayHUDText = RemoveFlag(client, cf.DisplayHUDText);
				ClearSyncHud(client, g_hHUDSync);
				
				FakeClientCommand(client, "menuselect 0"); //Close any menus open
				
			}
			else if(HasFlag(client, cf.EditHUDTextMode_Chat))
			{
				ShowPadHUDText(client, -1.0, -1.0, 0.1, _, "");
				cf.EditHUDTextMode_Chat = RemoveFlag(client, cf.EditHUDTextMode_Chat);
				ClearSyncHud(client, g_hHUDSync);
				
				FakeClientCommand(client, "menuselect 0"); //Close any menus open
			}
			else if(HasFlag(client, cf.EditHUDTextMode_Movement))
			{
				ShowPadHUDText(client, -1.0, -1.0, 0.1, _, "");
				int iEntityFlags = GetEntityFlags(client);
				
				iEntityFlags &= ~FL_ATCONTROLS;
				SetEntityFlags(client, iEntityFlags);
				
				cf.EditHUDTextMode_Movement = RemoveFlag(client, cf.EditHUDTextMode_Movement);
				
				ClearSyncHud(client, g_hHUDSync);
				
				FakeClientCommand(client, "menuselect 0"); //Close any menus open
			}
		}
	}
}
char GetPadTypeString(int iPadType)
{
	char sType[32] = "";
	
	switch(iPadType)
	{
		case 1:
		{
			FormatEx(sType, sizeof(sType), "padphrase_boost");
		}
		case 2:
		{
			FormatEx(sType, sizeof(sType), "padphrase_jump");
		}
		default:
		{
			FormatEx(sType, sizeof(sType), "Error lol, need to fix");
		}
	}
	return sType;
}
bool DisplayPadBeingBuilt(int client)
{
	//Don't display if they're editing HUD Pos Text
	if(HasFlag(client, cf.EditHUDTextMode_Movement)
	|| HasFlag(client, cf.EditHUDTextMode_Chat)) return false; 
	
	int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;
	
	int iObjectType;
	int iObjectBeingBuilt;
	int iPadType;
	
	char sClassname[32];
	GetEntityClassname(iActiveWeapon, sClassname, sizeof(sClassname));
	
	#if defined DEBUG
	PrintToChatAll("Active Weapon: %s", sClassname);
	#endif
	
	if(strcmp(sClassname, "tf_weapon_builder") == 0)
	{
		iObjectBeingBuilt = GetEntPropEnt(iActiveWeapon, Prop_Send, "m_hObjectBeingBuilt");
		if(!IsValidEntity(iObjectBeingBuilt)) return false;
		
		//Don't grab objecttype prop from the builder, it doesn't update properly in some cases.
		iObjectType = GetEntProp(iObjectBeingBuilt, Prop_Send, "m_iObjectType");
		
		#if defined DEBUG
		PrintToChatAll("OT: %i OBB: %i", iObjectType, iObjectBeingBuilt);
		#endif
		
		if(TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			switch(iObjectType)
			{
				case TFObject_Teleporter:
				{
					//Rotation 0/2 (Horizontal) = PadType 1 | Rotation 1/3 (Vertical) = PadType 2.
					iPadType = GetEntProp(iObjectBeingBuilt, Prop_Send, "m_iDesiredBuildRotations") % 2 + 1;
					#if defined DEBUG
					PrintToChatAll("Type: %i", iPadType);
					#endif
					
					float flX;
					float flY;
					
					PadHudTextFlags PHTF_Flags;
					
					GetUserHUDPos2(client, flX, flY, PHTF_Flags);
					
					if(!HasFlag(client, cf.DisplayHUDText))
					{
						cf.DisplayHUDText = AddFlag(client, cf.DisplayHUDText);
						
						switch(PHTF_Flags)
						{
							case PHTF_ShowText:
							{
								if(GetClientPadsEnabled(client))
								{
									ShowPadHUDText(client, flX, flY, _, _, "%t", "padphrase_info_buildpad", GetPadTypeString(iPadType));
								}
								else
								{
									ShowPadHUDText(client, flX, flY, _, _, "%t", "padphrase_info_togglepads");
								}
							}
							case PHTF_ShowText_MinMode:
							{
								if(GetClientPadsEnabled(client))
								{
									//PrintToChatAll("Showing HUD");
									ShowPadHUDText(client, flX, flY, _, _, "%t", "padphrase_info_buildpad_minmode", GetPadTypeString(iPadType));
								}
								else
								{
									//PrintToChatAll("Cleared HUD");
									ClearSyncHud(client, g_hHUDSync);
								}
							}
						}
					}
					else //Update the text
					{
						switch(PHTF_Flags)
						{
							case PHTF_ShowText:
							{
								if(GetClientPadsEnabled(client))
								{
									ShowPadHUDText(client, flX, flY, _, _, "%t", "padphrase_info_buildpad", GetPadTypeString(iPadType));
								}
								else
								{
									ShowPadHUDText(client, flX, flY, _, _, "%t", "padphrase_info_togglepads");
								}
							}
							case PHTF_ShowText_MinMode:
							{
								if(GetClientPadsEnabled(client))
								{
									//PrintToChatAll("Showing HUD");
									ShowPadHUDText(client, flX, flY, _, _, "%t", "padphrase_info_buildpad_minmode", GetPadTypeString(iPadType));
								}
								else
								{
									//PrintToChatAll("Cleared HUD");
									ClearSyncHud(client, g_hHUDSync);
								}
							}
						}
					}
					return true;
				}
				default: //Remove if it's not teleporters
				{
					ClearPadHUDText(client);
				}
			}
		}
	}
	return false;
}
bool ShowPadHUDText(int client, float x  = -1.0, float y = -1.0, float lifetime = 999.0, int iStringSize = 128, char[] message, any ...)
{
	ClearSyncHud(client, g_hHUDSync); //Just clear old messages before sending new ones
	
	char[] sFormatMessage = new char[iStringSize];
	
	int iTextColor[] = {240, 220, 200, 255};
	int iTextColorEffect[] = {90, 60, 60, 255};
	
	VFormat(sFormatMessage, iStringSize, message, 7);
	
	
	SetHudTextParamsEx(x, y, lifetime, iTextColor, iTextColorEffect, 2, 0.8, 0.0, 0.5);
	ShowSyncHudText(client, g_hHUDSync, sFormatMessage);
	
	return false;
}
/*
bool ShowPadHUDText(int client, int iStringSize = 128, char[] message, any ...)
{
	char[] sFormatMessage = new char[iStringSize];
	
	int iTextColor[] = {240, 220, 200, 255};
	int iTextColorEffect[] = {90, 60, 60, 255};
	
	DataPack dp_Pos = GetUserHUDPos(client);
	VFormat(sFormatMessage, iStringSize, message, 4);
	PrintToChatAll("Vformat: %s, message: %s", sFormatMessage, message);
	
	ClearSyncHud(client, g_hHUDSync); //Just clear old messages before sending new ones
	
	if(dp_Pos != null)
	{
		float x = dp_Pos.ReadFloat();
		float y = dp_Pos.ReadFloat();
		
		delete dp_Pos;
		
		SetHudTextParamsEx(x, y, 999.0, iTextColor, iTextColorEffect, 2, 0.8, 0.0, 0.5);
		ShowSyncHudText(client, g_hHUDSync, sFormatMessage);
		#if defined DEBUG
		PrintToChatAll("x: %f, y: %f", x, y);
		#endif
		return true;
	}
	else if(dp_Pos == null)
	{
		SetHudTextParamsEx(-1.0, -1.0, 999.0, iTextColor, iTextColorEffect, 2, 0.8, 0.0, 0.5);
		ShowSyncHudText(client, g_hHUDSync, sFormatMessage);
		#if defined DEBUG
		PrintToChatAll("Using defaults: -1.0");
		#endif
	}
	
	return false;
}
*/
bool ShowPadEditHUDText(int client, float x  = -1.0, float y = -1.0, float lifetime = 999.0, int iStringSize = 128, char[] message, any ...)
{
	ClearSyncHud(client, g_hHUDSync); //Just clear old messages before sending new ones
	
	char[] sFormatMessage = new char[iStringSize];
	
	int iTextColor[] = {240, 220, 200, 255};
	int iTextColorEffect[] = {90, 60, 60, 255};
	
	VFormat(sFormatMessage, iStringSize, message, 7);
	
	
	SetHudTextParamsEx(x, y, lifetime, iTextColor, iTextColorEffect, 2, 0.8, 0.0, 0.5);
	ShowSyncHudText(client, g_hHUDSync, sFormatMessage);
	
	return false;
}
bool SetupHUDTextCookie2(int client)
{
	char sHUDPosXY[32];
	
	float flX;
	float flY;
	
	PadHudTextFlags PHTF_Flags;
	
	if(GetUserHUDPos2(client, flX, flY, PHTF_Flags))
	{
		FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
			
		SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
		
		SetETHMArrays(client, flX, flY);
		return true;
	}
	return false;
}
bool SetupHUDTextCookie(int client)
{
	char sHUDPosX[16];
	char sHUDPosY[16];
	char sHUDFlags[16];
	char sHUDPosXY[32];
	
	float flX;
	float flY;
	
	PadHudTextFlags PHTF_Flags;
	
	int iMatches;
	
	GetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY, sizeof(sHUDPosXY));

	iMatches = g_rMatchFloats.MatchAll(sHUDPosXY);
	PrintToServer("iMatches: %i, sHUDPosXY: %s", iMatches, sHUDPosXY);
	
	if(iMatches == 1)
	{		 
		g_rMatchFloats.GetSubString(1, sHUDPosX, sizeof(sHUDPosX), 0);
		g_rMatchFloats.GetSubString(2, sHUDPosY, sizeof(sHUDPosY), 0);
		g_rMatchFloats.GetSubString(3, sHUDFlags, sizeof(sHUDFlags), 0);
		
		flX = StringToFloat(sHUDPosX);
		flY = StringToFloat(sHUDPosY);
		
		PHTF_Flags = StringToInt(sHUDFlags);
		
		if((flX >= -1.0 && flX <= 1.0) && (flY >= -1.0 && flY <= 1.0))
		{
			FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
			
			SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
			
			SetETHMArrays(client, flX, flY);
			
			return true;
		}
		else
		{
			//Set to a default value
			
			flX = -1.0;
			flY = -1.0;
			
			PHTF_Flags = PHTF_ShowText;
			
			FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
			
			SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
			
			SetETHMArrays(client, flX, flY);
			
			return true;
		}
	}
	else
	{
		//Set to a default value
			
		flX = -1.0;
		flY = -1.0;
		
		PHTF_Flags = PHTF_ShowText;
		
		FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
		
		SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
		
		SetETHMArrays(client, flX, flY);
	}
	return false;
}
bool SetUserHUDPos(int client, char[] sFloats)
{
	char sHUDPosX[16];
	char sHUDPosY[16];
	char sHUDFlags[16];
	char sHUDPosXY[32];
	
	float flX;
	float flY;
	
	PadHudTextFlags PHTF_Flags;
	
	int iMatches = g_rMatchFloats.Match(sFloats);
	PrintToServer("iMatches: %i", iMatches);
	//Debug
	
	if(iMatches == 6)
	{
		g_rMatchFloats.GetSubString(4, sHUDPosX, sizeof(sHUDPosX), 0);
		g_rMatchFloats.GetSubString(5, sHUDPosY, sizeof(sHUDPosY), 0);

		PrintToServer("X: %s, Y: %s", sHUDPosX, sHUDPosY);
		
		//PrintToChatAll("iMatches: %i", iMatches, iCaptures);
		return false;
	}
	else if(iMatches == 4)
	{
		g_rMatchFloats.GetSubString(1, sHUDPosX, sizeof(sHUDPosX), 0);
		g_rMatchFloats.GetSubString(2, sHUDPosY, sizeof(sHUDPosY), 0);
		g_rMatchFloats.GetSubString(3, sHUDFlags, sizeof(sHUDFlags), 0);
		PrintToServer("X: %s, Y: %s, Flags: %s", sHUDPosX, sHUDPosY, sHUDFlags);
		return false;
	}
	
	if(AreClientCookiesCached(client))
	{
		if(iMatches == 4)
		{
			g_rMatchFloats.GetSubString(1, sHUDPosX, sizeof(sHUDPosX), 0);
			g_rMatchFloats.GetSubString(2, sHUDPosY, sizeof(sHUDPosY), 0);
			g_rMatchFloats.GetSubString(3, sHUDFlags, sizeof(sHUDFlags), 0);
			
			flX = StringToFloat(sHUDPosX);
			flY = StringToFloat(sHUDPosY);
			
			PHTF_Flags = StringToInt(sHUDFlags);
			
			if(PHTF_Flags >= PHTF_NONE || PHTF_Flags <= PHTF_MAX_FLAGS)
			{
				DataPack dp_Pos = GetUserHUDPos(client);	
				
				dp_Pos.ReadFloat();
				dp_Pos.ReadFloat();
				
				PHTF_Flags = dp_Pos.ReadCell();
			}
			
			
			if((flX >= -1.0 && flX <= 1.0) 
			&& (flY >= -1.0 && flY <= 1.0))
			{
				FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
				
				SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
				
				SetETHMArrays(client, flX, flY);
				
				return true;
			}
			else
			{
				//Set to a default value
				
				flX = -1.0;
				flY = -1.0;
			
				PHTF_Flags = PHTF_ShowText;
	
				FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
				
				SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
				
				SetETHMArrays(client, flX, flY);
				
				return true;
			}
		}
		else if(iMatches == 6)
		{
			DataPack dp_Pos = GetUserHUDPos(client);
						
			float x = dp_Pos.ReadFloat();
			float y = dp_Pos.ReadFloat();
			
			PHTF_Flags = dp_Pos.ReadCell();
			
			g_rMatchFloats.GetSubString(4, sHUDPosX, sizeof(sHUDPosX), 0);
			g_rMatchFloats.GetSubString(5, sHUDPosY, sizeof(sHUDPosY), 0);
			
			flX = StringToFloat(sHUDPosX);
			flY = StringToFloat(sHUDPosY);
			
			FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
			
			SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
			
			SetETHMArrays(client, flX, flY);
			
			return true;
		}
	}
	return false;
}
DataPack GetUserHUDPos(int client)
{
	char sHUDPosX[16];
	char sHUDPosY[16];
	char sHUDFlags[16];
	char sHUDPosXY[32];
	
	DataPack dp_HUDPos;

	int iMatches;
	
	PadHudTextFlags PHTF_Flags;
	
	float flX;
	float flY;
	
	if(AreClientCookiesCached(client))
	{
		GetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY, sizeof(sHUDPosXY));
		
		iMatches = g_rMatchFloats.MatchAll(sHUDPosXY);
		
		#if defined DEBUG
		PrintToChatAll("GUHP - iMatches: %i", iMatches);
		#endif
		PrintToChatAll("GUHP - iMatches: %i", iMatches);
		
		if(iMatches == 1)
		{
			g_rMatchFloats.GetSubString(1, sHUDPosX, sizeof(sHUDPosX), 0);
			g_rMatchFloats.GetSubString(2, sHUDPosY, sizeof(sHUDPosY), 0);
			g_rMatchFloats.GetSubString(3, sHUDFlags, sizeof(sHUDFlags), 0);
			
			
			flX = StringToFloat(sHUDPosX);
			flY = StringToFloat(sHUDPosY);
			
			PHTF_Flags = StringToInt(sHUDFlags);
			
			if((flX >= -1.0 && flX <= 1.0) && (flY >= -1.0 && flY <= 1.0))
			{
				dp_HUDPos = new DataPack();
				
				dp_HUDPos.WriteFloat(flX);
				dp_HUDPos.WriteFloat(flY);
				dp_HUDPos.WriteCell(PHTF_Flags);
				
				dp_HUDPos.Reset();
				
				SetETHMArrays(client, flX, flY);
				
				return dp_HUDPos;
			}
			else
			{
				
				//Default Settings
				flX = -1.0;
				flY = -1.0;
				
				dp_HUDPos = new DataPack();
				
				dp_HUDPos.WriteFloat(flX);
				dp_HUDPos.WriteFloat(flY);
				dp_HUDPos.WriteCell(PHTF_Flags);
				
				dp_HUDPos.Reset();
				
				SetETHMArrays(client, flX, flY);
				
				return dp_HUDPos;
			}
		}
		else
		{
			
			//Default Settings
			flX = -1.0;
			flY = -1.0;
			
			PHTF_Flags = PHTF_ShowText;
			
			dp_HUDPos = new DataPack();
			
			dp_HUDPos.WriteFloat(flX);
			dp_HUDPos.WriteFloat(flY);
			dp_HUDPos.WriteCell(PHTF_Flags);
			
			dp_HUDPos.Reset();
			
			SetETHMArrays(client, flX, flY);
			
			return dp_HUDPos;
		}
	}
	else
	{
		//Give the default settings if the cookies can't be used for some reason
		//Default Settings
		
		flX = -1.0;
		flY = -1.0;
		
		PHTF_Flags = PHTF_ShowText;
		
		dp_HUDPos = new DataPack();
		
		dp_HUDPos.WriteFloat(flX);
		dp_HUDPos.WriteFloat(flY);
		dp_HUDPos.WriteCell(PHTF_Flags);
		
		dp_HUDPos.Reset();
		
		SetETHMArrays(client, flX, flY);
		
		return dp_HUDPos;
	}
}
bool SetUserHUDPos2(int client, char[] sFloats)
{
	char sHUDPosX[16];
	char sHUDPosY[16];
	char sHUDFlags[16];
	char sHUDPosXY[32];
	
	float flX;
	float flY;
	
	PadHudTextFlags PHTF_Flags;
	
	int iMatches = g_rMatchFloats.Match(sFloats);
	//PrintToServer("iMatches: %i", iMatches);
	//Debug
	/*
	if(iMatches == 6)
	{
		g_rMatchFloats.GetSubString(4, sHUDPosX, sizeof(sHUDPosX), 0);
		g_rMatchFloats.GetSubString(5, sHUDPosY, sizeof(sHUDPosY), 0);

		PrintToServer("X: %s, Y: %s", sHUDPosX, sHUDPosY);
		
		//PrintToChatAll("iMatches: %i", iMatches, iCaptures);
		return false;
	}
	else if(iMatches == 4)
	{
		g_rMatchFloats.GetSubString(1, sHUDPosX, sizeof(sHUDPosX), 0);
		g_rMatchFloats.GetSubString(2, sHUDPosY, sizeof(sHUDPosY), 0);
		g_rMatchFloats.GetSubString(3, sHUDFlags, sizeof(sHUDFlags), 0);
		PrintToServer("X: %s, Y: %s, Flags: %s", sHUDPosX, sHUDPosY, sHUDFlags);
		return false;
	}
	*/
	if(AreClientCookiesCached(client))
	{
		if(iMatches == 4)
		{
			g_rMatchFloats.GetSubString(1, sHUDPosX, sizeof(sHUDPosX), 0);
			g_rMatchFloats.GetSubString(2, sHUDPosY, sizeof(sHUDPosY), 0);
			g_rMatchFloats.GetSubString(3, sHUDFlags, sizeof(sHUDFlags), 0);
			
			flX = StringToFloat(sHUDPosX);
			flY = StringToFloat(sHUDPosY);
			
			PHTF_Flags = view_as<PadHudTextFlags>(StringToInt(sHUDFlags));
			
			if((flX >= -1.0 && flX <= 1.0) 
			&& (flY >= -1.0 && flY <= 1.0))
			{
			
				if(flX > -1.0 && flX < 0.0) //Don't allow any negatives besides -1.0
				flX *= -1.0;
				
				if(flY > -1.0 && flY < 0.0)
				flY *= -1.0;
				
				if(PHTF_Flags <= PHTF_NONE || PHTF_Flags >= PHTF_MAX_FLAGS)
				{
					PHTF_Flags = PHTF_ShowText;
				}
				
				FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
				
				SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
				
				SetETHMArrays(client, flX, flY);
				
				return true;
			}
			else
			{
				//Set to a default value
				
				flX = -1.0;
				flY = -1.0;
			
				PHTF_Flags = PHTF_ShowText;
	
				FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
				
				SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
				
				SetETHMArrays(client, flX, flY);
				
				return true;
			}
		}
		else if(iMatches == 6)
		{
			g_rMatchFloats.GetSubString(4, sHUDPosX, sizeof(sHUDPosX), 0);
			g_rMatchFloats.GetSubString(5, sHUDPosY, sizeof(sHUDPosY), 0);
			
			flX = StringToFloat(sHUDPosX);
			flY = StringToFloat(sHUDPosY);
			
			if((flX >= -1.0 && flX <= 1.0) 
			&& (flY >= -1.0 && flY <= 1.0))
			{
				//PrintToChatAll("X: %f, Y: %f", flX, flY);
					
				if(flX > -1.0 && flX < 0.0) //Don't allow any negatives besides -1.0
				flX *= -1.0;
				
				if(flY > -1.0 && flY < 0.0)
				flY *= -1.0;
					
				//PrintToChatAll("X: %f, Y: %f", flX, flY);
				
				GetUserHUDPos2(client, _, _, PHTF_Flags);
				
				FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
				
				SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
				
				SetETHMArrays(client, flX, flY);
				return true;
			}
			else
			{
				//Set to a default value
				
				flX = -1.0;
				flY = -1.0;
			
				PHTF_Flags = PHTF_ShowText;
	
				FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
				
				SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
				
				SetETHMArrays(client, flX, flY);
				
				return true;
			}
		}
	}
	return false;
}
bool GetUserHUDPos2(int client, float& x = -1.0, float& y = -1.0, PadHudTextFlags& HudFlags = PHTF_NONE)
{
	char sHUDPosX[16];
	char sHUDPosY[16];
	char sHUDFlags[16];
	char sHUDPosXY[32];
	
	int iMatches;
	
	PadHudTextFlags PHTF_Flags;
	
	float flX;
	float flY;
	
	if(AreClientCookiesCached(client))
	{
		GetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY, sizeof(sHUDPosXY));
		
		//PrintToChatAll("sHUDPosXY:%s", sHUDPosXY);
		
		if(!sHUDPosXY[0]) // If Cookie is unset, use defaults
		{
			//PrintToChatAll("Empty cookie, setting defaults");
			
			//Default Settings
			flX = -1.0;
			flY = -1.0;
			
			x = flX;
			y = flY;
			
			PHTF_Flags = PHTF_ShowText;
			
			HudFlags = PHTF_ShowText;
			
			FormatEx(sHUDPosXY, sizeof(sHUDPosXY), "%f %f %i", flX, flY, PHTF_Flags);
				
			SetClientCookie(client, g_Cookie_PadHUDText, sHUDPosXY);
			
			SetETHMArrays(client, flX, flY);
			
			return false;
		}
		
		iMatches = g_rMatchFloats.Match(sHUDPosXY);
		
		if(iMatches == 4)
		{
			g_rMatchFloats.GetSubString(1, sHUDPosX, sizeof(sHUDPosX), 0);
			g_rMatchFloats.GetSubString(2, sHUDPosY, sizeof(sHUDPosY), 0);
			g_rMatchFloats.GetSubString(3, sHUDFlags, sizeof(sHUDFlags), 0);
			
			
			flX = StringToFloat(sHUDPosX);
			flY = StringToFloat(sHUDPosY);
			
			PHTF_Flags = StringToInt(sHUDFlags);
			
			if((flX >= -1.0 && flX <= 1.0) 
			&& (flY >= -1.0 && flY <= 1.0))
			{
			
				if(flX > -1.0 && flX < 0.0) //Don't allow any negatives besides -1.0
				flX *= -1.0;
				
				else
				x = flX;
				
				if(flY > -1.0 && flY < 0.0)
				flY *= -1.0;
				
				else
				y = flY;
				
				if(PHTF_Flags <= PHTF_NONE || PHTF_Flags >= PHTF_MAX_FLAGS)
				{
					PHTF_Flags = PHTF_ShowText;
					HudFlags = PHTF_ShowText;
				}
				else
				{
					HudFlags = PHTF_Flags;
				}
				
				SetETHMArrays(client, flX, flY);
				return true;
			}
			else
			{
				
				//Default Settings
				flX = -1.0;
				flY = -1.0;
				
				x = flX;
				y = flY;
				
				PHTF_Flags = PHTF_ShowText;
				
				HudFlags = PHTF_ShowText;
				
				SetETHMArrays(client, flX, flY);
				
				return false;
			}
		}
		else
		{
			
			//Default Settings
			flX = -1.0;
			flY = -1.0;
			
			x = flX;
			y = flY;
			
			PHTF_Flags = PHTF_ShowText;
			
			HudFlags = PHTF_ShowText;
			
			SetETHMArrays(client, flX, flY);
			
			return false;
		}
	}
	else
	{
		//Give the default settings if the cookies can't be used for some reason
		//Default Settings
		
		//Default Settings
		flX = -1.0;
		flY = -1.0;
		
		x = flX;
		y = flY;
		
		PHTF_Flags = PHTF_ShowText;
		
		HudFlags = PHTF_ShowText;
		
		SetETHMArrays(client, flX, flY);
		
		return false;
	}
}
bool SetETHMArrays(int client, float x = -1.0, float y = -1.0, float textspeed = 0.02, bool bFetchCookie = false)
{
	//PrintToChatAll("ETHMArray: %f, %f, %f", x, y, textspeed);
	if(bFetchCookie)
	{
		float GUHP_x;
		float GUHP_y;
		
		GetUserHUDPos2(client, GUHP_x, GUHP_y);
		
		g_flETHM_Pos[client][0] = GUHP_x;
		g_flETHM_Pos[client][1] = GUHP_y;
		
		g_flETHM_Text_Movespeed[client] = textspeed;
		
		return true;
	}
	else
	{
		g_flETHM_Pos[client][0] = x;
		g_flETHM_Pos[client][1] = y;
		
		g_flETHM_Text_Movespeed[client] = textspeed;
		
		return true;
	}
}
/*HUD TEXT Stuff - End*/
void OnPadThink(int iPad)
{
	float flConstructed = GetEntPropFloat(iPad, Prop_Send, "m_flPercentageConstructed");
	bool bBuilding = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bBuilding"));
	bool bCarried = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bCarried"));
	bool bPlacing = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bPlacing"));
	bool bDisabled = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bDisabled"));
	bool bSapped = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bHasSapper"));
	
	if (bBuilding && flConstructed < 1.0)
	{
		if (TF2_GetBuildingState(iPad) != TELEPORTER_STATE_BUILDING)
			TF2_SetBuildingState(iPad, TELEPORTER_STATE_BUILDING);
		if (GetEntProp(iPad, Prop_Send, "m_iUpgradeLevel") != 3 && !bSapped)
		{
			SetEntProp(iPad, Prop_Send, "m_iHighestUpgradeLevel", 3);
			SetEntProp(iPad, Prop_Send, "m_iUpgradeLevel", 3);
		}
		return;
	}
	
	int iObjParti = EntRefToEntIndex(g_iObjectParticle[iPad]);
	
	if (bCarried || bPlacing || bDisabled)
	{
		if (bSapped)
		{
			if (GetEntProp(iPad, Prop_Send, "m_iUpgradeLevel") > 1)
			{
				SetEntProp(iPad, Prop_Send, "m_iUpgradeLevel", 1);	//Prevents the Red-Tape Recorder having to downgrade Pads before deconstructing.
				SetEntProp(iPad, Prop_Send, "m_iHighestUpgradeLevel", 1);
			}
		}
		if (IsValidEntity(iObjParti) && GetEntProp(iObjParti, Prop_Send, "m_bActive") && !bDisabled) //Want the particle in disabled state to still show even when disabled for recognition
			AcceptEntityInput(iObjParti, "Stop");
		return;
	}
	
	if (TF2_GetBuildingState(iPad) > TELEPORTER_STATE_BUILDING && TF2_GetBuildingState(iPad) < TELEPORTER_STATE_UPGRADING)
	{
		if (TF2_GetBuildingState(iPad) != TELEPORTER_STATE_READY && GetEntPropFloat(iPad, Prop_Send, "m_flRechargeTime") <= GetGameTime())
		{
			TF2_SetBuildingState(iPad, TELEPORTER_STATE_READY);	//Make sure the Pad always re-activates when it's supposed to.
			
			#if defined DEBUG
			PrintToChatAll("%i Ready!", iPad);
			#endif
		}
		if (TF2_GetBuildingState(iPad) == TELEPORTER_STATE_READY && IsValidEntity(iObjParti) && !GetEntProp(iObjParti, Prop_Send, "m_bActive"))
			AcceptEntityInput(iObjParti, "Start");
	}
	
	float flCooldown;
	switch (g_iPadType[iPad])
	{
		case PadType_Boost:	flCooldown = cvarPads[BoostCooldown].FloatValue;
		case PadType_Jump:	flCooldown = cvarPads[JumpCooldown].FloatValue;
	}
	SetEntPropFloat(iPad, Prop_Send, "m_flCurrentRechargeDuration", flCooldown);
	
	SetEntPropFloat(iPad, Prop_Send, "m_flYawToExit", GetEntPropFloat(iPad, Prop_Send, "m_flYawToExit") + 1.0);	//Make the arrow spin for fun, and to indicate its not a Teleporter (but mostly for fun)
	if (GetEntPropFloat(iPad, Prop_Send, "m_flYawToExit") > 360.0)
		SetEntPropFloat(iPad, Prop_Send, "m_flYawToExit", 0.0);
}

public Action OnPadTouch(int iPad, int iToucher)
{
					
					#if defined DEBUG
					PrintToChatAll("%i Hooked touch on:", iPad);
					#endif
					
	if (IsValidClient(iToucher))
	{		
		if (TF2_GetBuildingState(iPad) != TELEPORTER_STATE_READY)
			return Plugin_Continue;
		
		int iPadTeam = GetEntProp(iPad, Prop_Data, "m_iTeamNum");
		int iPadBuilder = GetEntPropEnt(iPad, Prop_Send, "m_hBuilder");
		/*if(GetClientButtons(iToucher) & IN_JUMP)
		{
			PrintToChat(iToucher, "%i", GetClientButtons(iToucher));
		}*/
		if ((GetClientTeam(iToucher) == iPadTeam || 
		(TF2_GetPlayerClass(iToucher) == TFClass_Spy)) && GetEntPropEnt(iToucher, Prop_Send, "m_hGroundEntity") == iPad
		||
		(GetClientTeam(iToucher) == iPadTeam || 
		(TF2_GetPlayerClass(iToucher) == TFClass_Spy && TF2_IsPlayerInCondition(iToucher, TFCond_Disguised) && 
		GetEntProp(iToucher, Prop_Send, "m_nDisguiseTeam") == iPadTeam)) && 
		GetEntPropEnt(iToucher, Prop_Send, "m_hGroundEntity") == iPad && GetConVarBool(cvarPads[DisguiseNeeded]) == true)
		{
			switch(g_iPadType[iPad])
			{
				case PadType_Boost:
				{
					if (!Pad_AddCond(iToucher, PadCond_Boost))
						return Plugin_Handled;	//Ignore players who already have a boost
					
					float flDur = cvarPads[BoostDuration].FloatValue;
					
					TF2_AddCondition(iToucher, TFCond_SpeedBuffAlly, flDur);
					TF2_AddCondition(iToucher, TFCond_TeleportedGlow, flDur);
					Pad_AddCond(iToucher, PadCond_DelayResponse);
					
					SDKHook(iToucher, SDKHook_PreThink, OnPreThink);
					g_flPlayerBoostEndTime[iToucher] = GetGameTime() + flDur;
					g_iPlayerDamageTaken[iToucher] = 0;
					
					TF2_SetBuildingState(iPad, TELEPORTER_STATE_RECEIVING_RELEASE);
					
					SetEntPropFloat(iPad, Prop_Send, "m_flRechargeTime", GetGameTime() + cvarPads[BoostCooldown].FloatValue);
					
					//AcceptEntityInput(EntRefToEntIndex(g_iObjectParticle[iPad]), "Stop"); //Removed to make it more obvious what pad it is while recharging
					
					EmitGameSoundToAll("Powerup.PickUpHaste", iToucher);
					EmitGameSoundToAll("Building_Teleporter.Send", iPad);
					
					#if defined DEBUG
					PrintToChatAll("%N Boosted!", iToucher);
					#endif
				}
				case PadType_Jump:
				{
					if (!Pad_AddCond(iToucher, PadCond_NoFallDmg))	//Wait for launched players to be unhooked before re-launching them
						return Plugin_Handled;
					
					TF2_AddCondition(iToucher, TFCond_TeleportedGlow, 5.0);

					Pad_AddCond(iToucher, PadCond_DelayResponse);
					
					RequestFrame(LaunchPlayer, iToucher);
					
					TF2_SetBuildingState(iPad, TELEPORTER_STATE_RECEIVING_RELEASE);
					
					SetEntPropFloat(iPad, Prop_Send, "m_flRechargeTime", GetGameTime() + cvarPads[JumpCooldown].FloatValue);
					
					//AcceptEntityInput(EntRefToEntIndex(g_iObjectParticle[iPad]), "Stop"); //Removed to make it more obvious what pad it is while recharging
					
					EmitGameSoundToAll("Passtime.BallSmack", iPad);
					EmitGameSoundToAll("TFPlayer.AirBlastImpact", iPad);
					EmitGameSoundToAll("Building_Teleporter.Send", iPad);
					
					#if defined DEBUG
					PrintToChatAll("%N Launched!", iToucher);
					#endif
				}
			}
			if (iToucher != iPadBuilder)
			{
				SetEntProp(iPad, Prop_Send, "m_iTimesUsed", GetEntProp(iPad, Prop_Send, "m_iTimesUsed") + 1);
				
				if (!(GetEntProp(iPad, Prop_Send, "m_iTimesUsed") % 6)) //Add +2 points every 6 uses
				{
					Event event = CreateEvent("player_escort_score", true);	//Using player_teleported unfortunately does not work.
					if (event != null)
					{
						event.SetInt("player", iPadBuilder);
						event.SetInt("points", 1);	//Not sure why this is adding double points
						event.Fire();
					}
				}
			}
			#if defined DEBUG
			PrintToChatAll("Conds: %i", view_as<int>(Pad_GetConds(iToucher)));
			#endif
		}
		return Plugin_Handled;	//Block client touch events to prevent enemy spies messing stuff up.
	}
	return Plugin_Continue;
}

/* Boost Pad Effects */
public void OnPreThink(int client)
{
	if (g_flPlayerBoostEndTime[client] <= GetGameTime() || !Pad_IsPlayerInCond(client, PadCond_Boost))	//If the player's boost duration is over, or they're still hooked without the boost cond.
	{
		if (IsPlayerAlive(client))
		{
			g_flPlayerBoostEndTime[client] = 0.0;
			g_iPlayerDamageTaken[client] = 0;
			Pad_RemoveCond(client, PadCond_Boost);
			TF2_RemoveCondition(client, TFCond_TeleportedGlow);
			TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);	//Recalc player's speed so they don't keep the boost forever
			
			if (Pad_IsPlayerInCond(client, PadCond_DelayResponse))
			{
				if (!Pad_IsPlayerInCond(client, PadCond_NoFallDmg)) //If player is still going to negate fall dmg, they'll need to say thanks later.
				{
					Pad_RemoveCond(client, PadCond_DelayResponse);
					TF2_SayTeleportResponse(client);
				}
			}
			
			#if defined DEBUG
			PrintToChatAll("%N's Boost Ended!", client);
			#endif
		}
		SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	}
	
	else if (Pad_IsPlayerInCond(client, PadCond_Boost))
	{
		float flBoostSpeed = cvarPads[BoostSpeed].FloatValue;
		if (flBoostSpeed && (!TF2_IsPlayerInCondition(client, TFCond_Slowed) || !cvarPads[BoostBlockAiming].BoolValue))	//Don't apply speed boost to Revved/Aiming players
		{
			if (GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") < flBoostSpeed)
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", flBoostSpeed);
		}
	}
}

/* Jump Pad Effects */
void LaunchPlayer(int client)
{
	float vVel[3], vVel2[3];
	float flMaxSpeed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	float flJumpSpeed = cvarPads[JumpSpeed].FloatValue;
	float flJumpHeight = cvarPads[JumpHeight].FloatValue;
	float flRatio = flJumpSpeed / flMaxSpeed;
	
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
	
	ScaleVector(vVel, flRatio);  //This ensures all classes will have the same launch distance.
	
	/* Get the horizontal vectors */
	vVel2[0] = vVel[0];
	vVel2[1] = vVel[1];
	
	float flHorizontalSpeed = GetVectorLength(vVel2);
	if (flHorizontalSpeed > flJumpSpeed)
		ScaleVector(vVel, flJumpSpeed / flHorizontalSpeed);
	
	vVel[2] = flJumpHeight;
	//if (GetEntityFlags(client) & FL_DUCKING)
	if (GetClientButtons(client) & IN_JUMP || GetEntityFlags(client) & FL_DUCKING)
	{
		ScaleVector(vVel, cvarPads[JumpCrouchSpeedMult].FloatValue);
		vVel[2] = flJumpHeight * cvarPads[JumpCrouchHeightMult].FloatValue;
	}
	
	#if defined DEBUG
	PrintToChatAll("Speed: %.2f (%.0f%%)", flHorizontalSpeed / flRatio, flHorizontalSpeed / flJumpSpeed * 100);
	PrintToChatAll("SpeedLaunch: %.2f", flHorizontalSpeed);
	PrintToChatAll("ScaleVector: %.2f", flJumpSpeed / flHorizontalSpeed);
	PrintToChatAll("Height: %.2f", vVel[2]);
	#endif
	
	if (vVel[2] < 300.0)	//Teleport the player up slightly to allow 'flJumpHeight' values lower than 300.0.
	{
		float vPos[3];
		GetClientAbsOrigin(client, vPos);
		vPos[2] += 20.0;
		SetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPos);
	}
	
	SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
	SetEntProp(client, Prop_Send, "m_bJumping", cvarPads[JumpBlockSnipers].IntValue);
	
	TF2_AddCondition(client, TFCond_GrapplingHookSafeFall, TFCondDuration_Infinite);
	
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public Action OnPlayerTakeDamage(int client, int &iAttacker, int &iInflictor, float &flDamage, int &iDamageType, int &iWeapon, float flDamageForce[3], float flDamagePosition[3], int iDamageCustom)
{
	if (!IsValidClient(client))
		return Plugin_Continue;
	
	if (iDamageType & DMG_FALL && Pad_IsPlayerInCond(client, PadCond_NoFallDmg))
	{			
		if (Pad_IsPlayerInCond(client, PadCond_DelayResponse))
		{
			if (!Pad_IsPlayerInCond(client, PadCond_Boost)) //If player is still being boosted, they'll need to say thanks later.
			{
				Pad_RemoveCond(client, PadCond_DelayResponse);
				TF2_SayTeleportResponse(client);
			}
		}
		TF2_AddCondition(client, TFCond_PasstimeInterception, 0.01);
		
		SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
		
		#if defined DEBUG
		PrintToChatAll("%N's Fall Damage negated!", client);
		#endif
		
		// return Plugin_Handled; //Returning Plugin_Handled causes fall damage sound+blood, which I don't want
	}
	
	return Plugin_Continue;
}
public void TF2_OnConditionRemoved(int client, TFCond iCond)
{
	switch (iCond)
	{
		case TFCond_GrapplingHookSafeFall:
		{
			if (Pad_RemoveCond(client, PadCond_NoFallDmg))
			{
				SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
				
				if (Pad_IsPlayerInCond(client, PadCond_DelayResponse))
				{
					if (!Pad_IsPlayerInCond(client, PadCond_Boost)) //If player is still being boosted, they'll need to say thanks later.
					{
						Pad_RemoveCond(client, PadCond_DelayResponse);
						TF2_SayTeleportResponse(client);
					}
				}
				#if defined DEBUG
				PrintToChatAll("%N OTD Unhooked!", client);
				#endif
			}
		}
	}
}

/* Pad Creation/Revertion */
void ConvertTeleporterToPad(int iEnt, int iPadType, bool bAddHealth)
{
	g_iPadType[iEnt] = iPadType;
	
	// SetEntityModel(iEnt, "MODEL_PAD");	//Coming soon™, maybe...
	
	SetEntProp(iEnt, Prop_Send, "m_iHighestUpgradeLevel", 3);	//Set Pads to level 3 for cosmetic reasons related to recharging
	SetEntProp(iEnt, Prop_Send, "m_iUpgradeLevel", 3);
	SetEntProp(iEnt, Prop_Send, "m_bMiniBuilding", true);			//Prevent upgrades and metal from gibs
	SetEntProp(iEnt, Prop_Send, "m_iMaxHealth", cvarPads[PadHealth].IntValue);			//Max HP reduced to 100
	if (bAddHealth)
	{
		SetVariantInt(RoundFloat(cvarPads[PadHealth].IntValue * 0.5));
		AcceptEntityInput(iEnt, "AddHealth", iEnt); //Spawns at 50% HP.
		SetEntProp(iEnt, Prop_Send, "m_iTimesUsed", 0);
	}
	
	SetEntProp(iEnt, Prop_Send, "m_nBody", 2);	//Give the arrow to Exits as well.
	SetEntPropFloat(iEnt, Prop_Send, "m_flModelScale", cvarPads[PadSize].FloatValue);
	RequestFrame(ResetSkin, iEnt); //Setting m_bMiniBuilding tries to set the skin to a 'mini' skin. Since teles don't have one, reset the skin.
	
	int iObjParti = CreatePadParticle(iEnt);
	g_iObjectParticle[iEnt] = EntIndexToEntRef(iObjParti);
	
	AcceptEntityInput(iObjParti, "Start"); //Shows what pad it is while getting ready to build
	
	TF2_SetMatchingTeleporter(iEnt, iEnt); //Set its matching Teleporter to itself.
	
	PrintToChatAll("Hooking");
	SDKHook(iEnt, SDKHook_Touch, OnPadTouch);

					

}

void ConvertPadToTeleporter(int iEnt)
{
	g_iPadType[iEnt] = PadType_None;
	
	SetEntProp(iEnt, Prop_Send, "m_iHighestUpgradeLevel", 1);
	SetEntProp(iEnt, Prop_Send, "m_iUpgradeLevel", 1);
	SetEntProp(iEnt, Prop_Send, "m_bMiniBuilding", false);
	SetVariantInt(150);
	AcceptEntityInput(iEnt, "SetHealth", iEnt);
	
	SetEntProp(iEnt, Prop_Send, "m_iTimesUsed", 0);
	
	SetEntProp(iEnt, Prop_Send, "m_nBody", 1);
	SetEntPropFloat(iEnt, Prop_Send, "m_flModelScale", 1.0);
	RequestFrame(ResetSkin, iEnt);
	
	int iObjParti = EntRefToEntIndex(g_iObjectParticle[iEnt]);
	if (IsValidEntity(iObjParti))
	{
		AcceptEntityInput(iObjParti, "Kill");
	}
	g_iObjectParticle[iEnt] = -1;
	
	SDKUnhook(iEnt, SDKHook_Touch, OnPadTouch);
}

void ConvertAllPadsToTeleporters()
{
	int i = -1;
	while ((i = FindEntityByClassname2(i, "obj_teleporter")) != -1)
	{
		if (IsValidEntity(i) && g_iPadType[i])
			ConvertPadToTeleporter(i);
			
		if (!GetEntProp(i, Prop_Send, "m_bHasSapper") && !GetEntProp(i, Prop_Send, "m_bPlasmaDisable") && TF2_GetMatchingTeleporter(i) == i)
			TF2_EnableObject(i);	//Re-enable disabled un-matched Teleporters
			
		TF2_SetMatchingTeleporter(i, -1); //If MatchingTeleporter is invalid, the game will auto-search for one (if it's active). Do this for all Teleporters just to be safe.
	}
}

int CreatePadParticle(int iPad)
{
	TFTeam iPadTeam = view_as<TFTeam>(GetEntProp(iPad, Prop_Send, "m_iTeamNum"));
	char szParticleName[128];
	switch (g_iPadType[iPad])
	{
		case PadType_Boost:	strcopy(szParticleName, sizeof(szParticleName), "powerup_icon_haste");
		case PadType_Jump:	strcopy(szParticleName, sizeof(szParticleName), "powerup_icon_agility");
	}
	switch (iPadTeam)
	{
		case TFTeam_Red:	StrCat(szParticleName, sizeof(szParticleName), "_red");
		case TFTeam_Blue:	StrCat(szParticleName, sizeof(szParticleName), "_blue");
	}
	int iParticle = SpawnParticle(szParticleName);
	
	float vPos[3];
	GetEntPropVector(iPad, Prop_Data, "m_vecAbsOrigin", vPos);
	vPos[2] += 40.0;
	TeleportEntity(iParticle, vPos, NULL_VECTOR, NULL_VECTOR);
	
	SetParent(iPad, iParticle);
	
	return iParticle;
}

/* Commands */

public Action Command_TestDP(int client, int args)
{
	if(args < 1)
	{
		ShowPadHUDTextPanel(client);
	}
	if(args > 1)
	{
		char sBuffer[32];
		GetCmdArgString(sBuffer, sizeof(sBuffer));
		StripQuotes(sBuffer);
		SetUserHUDPos2(client, sBuffer);
	}
}

public Action TogglePadsMenuCmd(int client, int nArgs)
{
	if (!client)	//if client was the server console
	{
		ReplyToCommand(client, "This command can only be used in-game!");
		return Plugin_Handled;
	}
	
	ShowPadMenu(client);
	return Plugin_Handled;
}

public Action ShowPadsInfoCmd(int client, int nArgs)
{
	if (!client)
	{
		ReplyToCommand(client, "This command can only be used in-game!");
		return Plugin_Handled;
	}
	
	ShowPadInfo(client);
	
	return Plugin_Handled;
}

/* Menus/Panels */
void ShowPadMenu(int client)
{
	if (!CheckCommandAccess(client, "sm_engipads_override", 0))
	{
		MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_noaccess");
		return;
	}
	
	PadHudTextFlags PHTF_Flags;
	GetUserHUDPos2(client, _, _, PHTF_Flags);

	Menu menu = new Menu(MenuHandlerPadMenu);
	
	char szTranslation[64];
	
	Format(szTranslation, sizeof(szTranslation), "%T\n \n", "padphrase_menutitle", client);
	menu.SetTitle(szTranslation);
	
	if(GetClientPadsEnabled(client))
	{
		FormatEx(szTranslation, sizeof(szTranslation), "%T\n(Status: Enabled)\n \n", "padphrase_menutoggle", client);
		menu.AddItem("toggle", szTranslation);
	}
	else
	{
		FormatEx(szTranslation, sizeof(szTranslation), "%T\n(Status: Disabled)\n \n", "padphrase_menutoggle", client);
		menu.AddItem("toggle", szTranslation);
	}
	
	if(PHTF_Flags == PHTF_ShowText_MinMode)
	{
		Format(szTranslation, sizeof(szTranslation), "%t\n \n", "padphrase_info_EPHT_minmode_status_enabled");
		menu.AddItem("minmode", szTranslation);
	}
	else
	{
		Format(szTranslation, sizeof(szTranslation), "%t\n \n", "padphrase_info_EPHT_minmode_status_disabled");
		menu.AddItem("minmode", szTranslation);
	}
	
	Format(szTranslation, sizeof(szTranslation), "%T", "padphrase_info_EPHT_select", client);
	menu.AddItem("EPHT", szTranslation);
	
	menu.ExitButton = true;
		
	menu.Display(client, MENU_TIME_FOREVER);
}
void DrawPadHUDPosPanel(int client, int mode)
{
	menu_PadHUDText.Pagination = MENU_NO_PAGINATION;
	
	menu_PadHUDText.ExitButton = false;
	menu_PadHUDText.ExitBackButton = false;
	
	switch(mode)
	{
		case 0:
		{
			menu_PadHUDText.SetTitle("HUD Text Position Editing - EngiPads\n \nType in chat two decimal values with a space between them ranging from 0.0 to 1.0\nExample: -1.0 0.25\n-1.0 can be used to center the positions.\n \nFirst decimal value moves the text on the X axis and the second on the Y axis.\n \nOptionally minimum text mode can be set\nExample; -1.0 0.25 2\n1 = default, 2 = Min Mode\n \n");
			
			menu_PadHUDText.RemoveAllItems();
			
			menu_PadHUDText.AddItem("mode_chat_remove", "Close Menu");
			menu_PadHUDText.AddItem("main_menu", "Back to main menu");
			
			menu_PadHUDText.Display(client, MENU_TIME_FOREVER);
		}
		case 1:
		{
			menu_PadHUDText.SetTitle("HUD Text Position Editing - EngiPads\n \nUse your movement keys to edit HUD text position.\n \n");
			
			menu_PadHUDText.RemoveAllItems();
			
			menu_PadHUDText.AddItem("mode_movement_save", "Save Position\n \n");
			menu_PadHUDText.AddItem("mode_movement_centerX", "Center X axis");
			menu_PadHUDText.AddItem("mode_movement_centerY", "Center Y axis\n \n");
			menu_PadHUDText.AddItem("mode_movement_textdistance", "Change text movement distance");
			menu_PadHUDText.AddItem("mode_movement_hide", "Hide Menu\n \n");
			menu_PadHUDText.AddItem("main_menu", "Back to main menu");
			
			menu_PadHUDText.Display(client, MENU_TIME_FOREVER);
		}
	}
	
	//Use menuselect <number> on the client to forcibly remove the menu 
	
	//delete panel_HUDText;
}
void ShowPadInfo(int client)
{
	Panel panel = new Panel();
	
	char szTranslation[256];
	Format(szTranslation, sizeof(szTranslation), "%T", "padphrase_infotitle", client);
	panel.SetTitle(szTranslation);
	
	Format(szTranslation, sizeof(szTranslation), "%T", "padphrase_infogeneral", client, cvarPads[PadHealth].IntValue);
	panel.DrawItem(szTranslation, ITEMDRAW_RAWLINE);
	
	if (cvarPads[PadsEnabled].IntValue != EngiPads_JumpOnly)
	{	
		Format(szTranslation, sizeof(szTranslation), "%T", "padphrase_infoboost", client, cvarPads[BoostDuration].FloatValue, cvarPads[BoostCooldown].FloatValue);
		panel.DrawItem(szTranslation, ITEMDRAW_RAWLINE);
	}
	
	if (cvarPads[PadsEnabled].IntValue != EngiPads_BoostOnly)
	{
		Format(szTranslation, sizeof(szTranslation), "%T", "padphrase_infojump", client, cvarPads[JumpCooldown].FloatValue);
		panel.DrawItem(szTranslation, ITEMDRAW_RAWLINE);
	}
	
	if (cvarPads[BlockEureka].BoolValue)
	{	
		Format(szTranslation, sizeof(szTranslation), "%T", "padphrase_infoeureka", client);
		panel.DrawItem(szTranslation, ITEMDRAW_RAWLINE);
	}
	
	if (cvarPads[JumpBlockSnipers].BoolValue)
	{
		Format(szTranslation, sizeof(szTranslation), "%T", "padphrase_infosniper", client);
		panel.DrawItem(szTranslation, ITEMDRAW_RAWLINE);
	}
	
	if (cvarPads[BoostBlockAiming].BoolValue)
	{
		Format(szTranslation, sizeof(szTranslation), "%T", "padphrase_infoaiming", client);
		panel.DrawItem(szTranslation, ITEMDRAW_RAWLINE);
	}
	
	Format(szTranslation, sizeof(szTranslation), "%T", "padphrase_infoexit", client);
	panel.DrawItem(szTranslation, ITEMDRAW_CONTROL);
	
	panel.Send(client, MenuHandlerPadInfo, MENU_TIME_FOREVER);
	
}
void ShowPadHUDTextPanel(int client)
{
	PadHudTextFlags PHTF_Flags;
	GetUserHUDPos2(client, _, _, PHTF_Flags);
	
	Panel panel = new Panel();
	
	char szTranslation[256];
	
	Format(szTranslation, sizeof(szTranslation), "%t\n \n", "padphrase_info_EPHT_select");
	panel.SetTitle(szTranslation);
	
	Format(szTranslation, sizeof(szTranslation), "%t\n \n", "padphrase_info_EPHT_default");
	panel.DrawItem(szTranslation, ITEMDRAW_DEFAULT);
	
	Format(szTranslation, sizeof(szTranslation), "%t", "padphrase_info_EPHT_EP_chat");
	panel.DrawItem(szTranslation, ITEMDRAW_DEFAULT);
	
	Format(szTranslation, sizeof(szTranslation), "%t\n \n", "padphrase_info_EPHT_EP_movement");
	panel.DrawItem(szTranslation, ITEMDRAW_DEFAULT);
	
	Format(szTranslation, sizeof(szTranslation), "Exit");
	panel.DrawItem(szTranslation, ITEMDRAW_DEFAULT);
	
	panel.Send(client, PanelHandler_PadEditHudText, MENU_TIME_FOREVER);
	
	delete panel;
	
}
int MenuHandler_PadEditHUDText(Menu menu, MenuAction iAction, int client, int iOption)
{
	switch(iAction)
	{
		case MenuAction_Start:
		{
		}
		case MenuAction_Display:
		{
		}
		case MenuAction_Select:
		{
			switch(iOption)
			{
				/*

					menu_PadHUDText.AddItem("mode_movement_save", "Save Position");
					menu_PadHUDText.AddItem("mode_movement_centerX", "Center X axis");
					menu_PadHUDText.AddItem("mode_movement_centerY", "Center Y axis\n \n");
					menu_PadHUDText.AddItem("mode_movement_hide", "Hide Menu\n \n");
					menu_PadHUDText.AddItem("main_menu", "Back to main menu");
					
				*/
				case 0:
				{
					char sBuffer[32];
					menu.GetItem(iOption, sBuffer, sizeof(sBuffer));
					
					if(StrContains(sBuffer, "mode_chat_remove") != -1)
					{
						ClearPadHUDText(client);
					}
					else if(StrContains(sBuffer, "mode_movement_save") != -1)
					{
						if(HasFlag(client, cf.EditHUDTextMode_Movement))
						{
							ClearPadHUDText(client);
			
							MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_success");
							ShowPadEditHUDText(client, g_flETHM_Pos[client][0], g_flETHM_Pos[client][1], 3.0, _, "Saved!\nX pos set: %f\nY pos set: %f", g_flETHM_Pos[client][0], g_flETHM_Pos[client][1]);
							
							FormatEx(sBuffer, sizeof(sBuffer), "%f %f", g_flETHM_Pos[client][0], g_flETHM_Pos[client][1]);
							SetUserHUDPos2(client, sBuffer);
							
						}
					}
				}
				case 1:
				{
					char sBuffer[32];
					menu.GetItem(iOption, sBuffer, sizeof(sBuffer));
					
					if(StrContains(sBuffer, "main_menu") != -1)
					{
						MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_cancel");
						ClearPadHUDText(client);
						ShowPadHUDTextPanel(client);
					}
					else if(StrContains(sBuffer, "mode_movement_centerX") != -1)
					{
						if(HasFlag(client, cf.EditHUDTextMode_Movement))
						{
							g_flETHM_Pos[client][0] = -1.0;
							
							ShowPadEditHUDText(client, g_flETHM_Pos[client][0], g_flETHM_Pos[client][1], _, _, "Sample Text\nCurrent X pos: %f\nCurrent Y pos: %f", g_flETHM_Pos[client][0], g_flETHM_Pos[client][1]);
							MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_movement_centerX");
						}
					}
				}
				case 2:
				{
					char sBuffer[32];
					menu.GetItem(iOption, sBuffer, sizeof(sBuffer));
					
					if(StrContains(sBuffer, "mode_movement_centerY") != -1)
					{
						if(HasFlag(client, cf.EditHUDTextMode_Movement))
						{
							g_flETHM_Pos[client][1] = -1.0;
							
							ShowPadEditHUDText(client, g_flETHM_Pos[client][0], g_flETHM_Pos[client][1], _, _, "Sample Text\nCurrent X pos: %f\nCurrent Y pos: %f", g_flETHM_Pos[client][0], g_flETHM_Pos[client][1]);
							MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_movement_centerY");
						}
					}
				}
				case 3:
				{
					char sBuffer[32];
					menu.GetItem(iOption, sBuffer, sizeof(sBuffer));
					
					if(StrContains(sBuffer, "mode_movement_textdistance") != -1)
					{
						//PrintToChatAll("Should speed up");
						
						float flTextspeed = g_flETHM_Text_Movespeed[client];
						float flTextspeed2;
						
						if(flTextspeed >= 0.1)
						{
							g_flETHM_Text_Movespeed[client] = 0.01;
						}
						else
						{
							g_flETHM_Text_Movespeed[client] = flTextspeed * 2.0;
						}
						
						if(g_flETHM_Text_Movespeed[client] == 0.01)
						{
							MC_PrintToChat(client, "{orange}[EngiPads]{default} Set text movement distance to {olive}0.01{default} per step");
						}
						else if(g_flETHM_Text_Movespeed[client] == 0.02)
						{
							MC_PrintToChat(client, "{orange}[EngiPads]{default} Set text movement distance to {olive}0.02{default} per step");
						}
						else if(g_flETHM_Text_Movespeed[client] == 0.04)
						{
							MC_PrintToChat(client, "{orange}[EngiPads]{default} Set text movement distance to {olive}0.04{default} per step");
						}
						else if(g_flETHM_Text_Movespeed[client] == 0.08)
						{
							MC_PrintToChat(client, "{orange}[EngiPads]{default} Set text movement distance to {olive}0.8{default} per step");
						}
						else if(g_flETHM_Text_Movespeed[client] == 0.16)
						{
							g_flETHM_Text_Movespeed[client] = 0.1;
							MC_PrintToChat(client, "{orange}[EngiPads]{default} Set text movement distance to {olive}0.1{default} per step");
						}
					}
				}
				case 4:
				{
					char sBuffer[32];
					menu.GetItem(iOption, sBuffer, sizeof(sBuffer));
					if(StrContains(sBuffer, "mode_movement_hide") != -1)
					{
						PrintToConsole(client, "Hid the menu!");
					}
				}
				case 5:
				{
					char sBuffer[32];
					menu.GetItem(iOption, sBuffer, sizeof(sBuffer));
					
					if(StrContains(sBuffer, "main_menu") != -1)
					{
						MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_EP_cancel");
						ClearPadHUDText(client);
						ShowPadHUDTextPanel(client);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
		}
		case MenuAction_End:
		{
		}
		case MenuAction_VoteEnd:
		{
		}
		case MenuAction_VoteStart:
		{
		}
		case MenuAction_VoteCancel:
		{
		}
		case MenuAction_DrawItem:
		{
			
		}
		case MenuAction_DisplayItem:
		{
		}
	}
}
int MenuHandlerPadMenu(Menu menu, MenuAction iAction, int client, int iOption)
{
	switch(iAction)
	{
		case MenuAction_Start:
		{
		}
		case MenuAction_Display:
		{
		}
		case MenuAction_Select:
		{
			switch(iOption)
			{
				case 0: //Toggle EngiPads
				{
					if(GetClientPadsEnabled(client))
					{
						MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_disabled");
						SetClientPadsEnabled(client, false);
						DisplayPadBeingBuilt(client);
					}
					else
					{
						MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_enabled");
						SetClientPadsEnabled(client, true);
						DisplayPadBeingBuilt(client);
					}
				}
				case 1:
				{
					char sBuffer[32];
				
					float x;
					float y;
					
					PadHudTextFlags PHTF_Flags;
					
					GetUserHUDPos2(client, x, y, PHTF_Flags);
					
					if(HasFlag(client, cf.DisplayHUDText)
					|| HasFlag(client, cf.EditHUDTextMode_Chat)
					|| HasFlag(client, cf.EditHUDTextMode_Movement))
					{
						MC_PrintToChat(client, "{orange}[EngiPads]{default} You can't toggle the text mode right now, put down your building first!");
						return MenuAction_Cancel;
					}
					if(PHTF_Flags != PHTF_ShowText_MinMode)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%f %f %i", x, y, PHTF_ShowText_MinMode);
						SetUserHUDPos2(client, sBuffer);
						MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_minmode_enabled");
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%f %f %i", x, y, PHTF_ShowText);
						SetUserHUDPos2(client, sBuffer);
						MC_PrintToChat(client, "{orange}[EngiPads]{default} %t", "padphrase_info_EPHT_minmode_disabled");
					}
				}
				case 2: // Edit Pad HUD Text
				{
					ShowPadHUDTextPanel(client);
				}
			}
		}
		case MenuAction_Cancel:
		{
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_VoteEnd:
		{
		}
		case MenuAction_VoteStart:
		{
		}
		case MenuAction_VoteCancel:
		{
		}
		case MenuAction_DrawItem:
		{
			
		}
		case MenuAction_DisplayItem:
		{
		}
	}
}

int MenuHandlerPadInfo(Menu menu, MenuAction iAction, int client, int iOption)
{
	delete menu;
}
int PanelHandler_PadEditHudText(Menu menu, MenuAction iAction, int client, int iOption)
{
	switch(iAction)
	{
		case MenuAction_Start:
		{
		}
		case MenuAction_Display:
		{
		}
		case MenuAction_Select:
		{
			switch(iOption)
			{
				case 1: //Set to defaults
				{
					StartPadHudTextEdit(client, 2);
				}
				case 2: //Edit positions by typing
				{
					StartPadHudTextEdit(client, 0);
				}
				case 3: //Edit positions using movement keys
				{
					StartPadHudTextEdit(client, 1);
				}
				case 4:
				{
				}
			}
			return MenuAction_Cancel;
		}
		case MenuAction_Cancel:
		{
		}
		case MenuAction_End:
		{
		}
		case MenuAction_VoteEnd:
		{
		}
		case MenuAction_VoteStart:
		{
		}
		case MenuAction_VoteCancel:
		{
		}
		case MenuAction_DrawItem:
		{
			
		}
		case MenuAction_DisplayItem:
		{
		}
	}
	return MenuAction_Cancel;
}
/* "Stocks" */
stock int TF2_GetMatchingTeleporter(int iTele)	//Get the matching teleporter entity of a given Teleporter
{
	int iMatch = -1;
	
	if (IsValidEntity(iTele) && HasEntProp(iTele, Prop_Send, g_szOffsetStartProp))
	{
		int iOffs = FindSendPropInfo("CObjectTeleporter", g_szOffsetStartProp) + g_iOffsetMatchingTeleporter;
		iMatch = GetEntDataEnt2(iTele, iOffs);
	}
	
	return iMatch;
}

stock void TF2_SetMatchingTeleporter(int iTele, int iMatch)	//Set the matching teleporter entity of a given Teleporter
{
	if (IsValidEntity(iTele) && HasEntProp(iTele, Prop_Send, g_szOffsetStartProp))
	{
		int iOffs = FindSendPropInfo("CObjectTeleporter", g_szOffsetStartProp) + g_iOffsetMatchingTeleporter;
		SetEntDataEnt2(iTele, iOffs, iMatch, true);
	}
}

stock void TF2_SayTeleportResponse(int client) //Plays the appropriate ThanksForTheTeleporter response line.
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		char szVO[512];
		
		TFClassType iClass = TF2_GetPlayerClass(client);
		if (iClass == TFClass_Spy && (TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseClass") != view_as<int>(iClass)))
			iClass = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
		
		switch (iClass)
		{
			case TFClass_Scout:
			{
				Format(szVO, sizeof(szVO), "Scout.ThanksForTheTeleporter0%d", GetRandomInt(1, 3));
			}
			case TFClass_Soldier:
			{
				Format(szVO, sizeof(szVO), "Soldier.ThanksForTheTeleporter0%d", GetRandomInt(1, 3));
			}
			case TFClass_Pyro:
			{
				strcopy(szVO, sizeof(szVO), "Pyro.ThanksForTheTeleporter01");
			}
			case TFClass_DemoMan:
			{
				Format(szVO, sizeof(szVO), "Demoman.ThanksForTheTeleporter0%d", GetRandomInt(1, 2));
			}
			case TFClass_Heavy:
			{
				Format(szVO, sizeof(szVO), "Heavy.ThanksForTheTeleporter0%d", GetRandomInt(1, 3));
			}
			case TFClass_Engineer:
			{
				Format(szVO, sizeof(szVO), "Engineer.ThanksForTheTeleporter0%d", GetRandomInt(1, 2));
			}
			case TFClass_Medic:
			{
				Format(szVO, sizeof(szVO), "Medic.ThanksForTheTeleporter0%d", GetRandomInt(1, 3));
			}
			case TFClass_Sniper:
			{
				Format(szVO, sizeof(szVO), "Sniper.ThanksForTheTeleporter0%d", GetRandomInt(1, 3));
			}
			case TFClass_Spy:
			{
				Format(szVO, sizeof(szVO), "Spy.ThanksForTheTeleporter0%d", GetRandomInt(1, 3));
			}
		}
		EmitGameSoundToAll(szVO, client);
	}
}

/* Returns true if player has condition */
stock bool Pad_IsPlayerInCond(int client, PadCond fCond)
{
	if (IsValidClient(client))
	{
		if (Pad_GetConds(client) & fCond) //Check if player has specified custom condition flag
			return true;
	}
	return false;
}
/* Returns true if condition was added to player (as in, not already present) */
stock bool Pad_AddCond(int client, PadCond fCond)
{
	if (IsValidClient(client))
	{
		if (!Pad_IsPlayerInCond(client, fCond))
		{
			g_fPadCondFlags[client] |= fCond;
			return true;
		}
	}
	return false;
}

/* Returns true if condition was removed from player */
stock bool Pad_RemoveCond(int client, PadCond fCond)
{
	if (IsValidClient(client))
	{
		if (Pad_IsPlayerInCond(client, fCond))
		{
			g_fPadCondFlags[client] &= ~fCond;
			return true;
		}
	}
	return false;
}

/* Set PadCondFlags directly*/
stock void Pad_SetConds(int client, PadCond fConds)
{
	g_fPadCondFlags[client] = fConds;
}

/* Get PadCondFlags directly*/
stock PadCond Pad_GetConds(int client)
{
	return g_fPadCondFlags[client];
}

stock int GetPadType(int iPad) //Actually just a GetDesiredBuildRotations stock.
{
	int iType = PadType_None;
	
	if (IsValidEntity(iPad))
	{
		iType = (GetEntProp(iPad, Prop_Send, "m_iDesiredBuildRotations") % 2) + 1; //Rotation 0/2 (Horizontal) = PadType 1 | Rotation 1/3 (Vertical) = PadType 2.
		switch (cvarPads[PadsEnabled].IntValue)
		{
			case EngiPads_BoostOnly: iType = PadType_Boost;
			case EngiPads_JumpOnly: iType = PadType_Jump;
		}
	}
	return iType;
}

stock int TF2_GetBuildingState(int iBuilding)
{
	int iState = -1;
	
	if (IsValidEntity(iBuilding))
	{
		iState = GetEntProp(iBuilding, Prop_Send, "m_iState");
	}
	
	return iState;
}

stock void TF2_SetBuildingState(int iBuilding, int iState = 0)
{	
	if (IsValidEntity(iBuilding))
	{
		SetEntProp(iBuilding, Prop_Send, "m_iState", iState);
	}
}

stock void TF2_DisableObject(int iObj)
{
	if (IsValidEntity(iObj))
	{
		AcceptEntityInput(iObj, "Disable");
	}
}

stock void TF2_EnableObject(int iObj)
{
	if (IsValidEntity(iObj))
	{
		AcceptEntityInput(iObj, "Enable");
	}
}

stock void ResetSkin(int iEnt)
{
	if (IsValidEntity(iEnt) && HasEntProp(iEnt, Prop_Send, "m_nSkin"))
	{
		int iTeam = GetEntProp(iEnt, Prop_Data, "m_iTeamNum");
		SetEntProp(iEnt, Prop_Send, "m_nSkin", iTeam - 2);
	}
}

stock void PrintPadTypeNameToClient(int iObjType, int client)
{
	char szType[64];
	
	switch(iObjType)
	{
		case PadType_Boost: strcopy(szType, sizeof(szType), "padphrase_boost");
		case PadType_Jump: Format(szType, sizeof(szType), "padphrase_jump");
	}
	MC_PrintToChatEx(client, client, "{orange}[EngiPads]{default} %t", "padphrase_deploy", szType);
}

stock bool GetClientPadsEnabled(int client)
{
	if (!IsValidClient(client)) return false;
	if (IsFakeClient(client)) return cvarPads[BotsCanBuild].BoolValue;
	if (!AreClientCookiesCached(client)) return false;
	char szToggle[3];
	GetClientCookie(client, g_hPadCookie, szToggle, sizeof(szToggle));
	return view_as<bool>(StringToInt(szToggle));
}

stock void SetClientPadsEnabled(int client, bool bEnabled)
{
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
	if (!AreClientCookiesCached(client)) return;
	char szToggle[3];
	IntToString(view_as<int>(bEnabled), szToggle, sizeof(szToggle));
	SetClientCookie(client, g_hPadCookie, szToggle);
}

stock bool IsValidClient(int client)
{
	return (0 < client && client <= MaxClients && IsClientInGame(client));
}

stock int SpawnParticle(char[] szParticleType)
{
	int iParti = CreateEntityByName("info_particle_system");
	if (IsValidEntity(iParti))
	{
		DispatchKeyValue(iParti, "effect_name", szParticleType);
		DispatchSpawn(iParti);
		ActivateEntity(iParti);
	}
	return iParti;
}

stock void SetParent(int iParent, int iChild, char[] szAttachPoint = "")
{
	SetVariantString("!activator");
	AcceptEntityInput(iChild, "SetParent", iParent, iChild);
	
	if (szAttachPoint[0] != '\0')
	{
		if (IsValidClient(iParent) && IsPlayerAlive(iParent))
		{
			SetVariantString(szAttachPoint);
			AcceptEntityInput(iChild, "SetParentAttachmentMaintainOffset", iChild, iChild, 0);
		}
	}
}

stock void ClearTimer(Handle &hTimer)
{
	if (hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
		
		#if defined DEBUG
		PrintToChatAll("Timer cleared!");
		#endif
	}
}

stock int FindEntityByClassname2(int startEnt, char[] classname)
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

#if !defined _smlib_included
/* SMLIB
 * Precaches the given particle system.
 * It's best to call this OnMapStart().
 * Code based on Rochellecrab's, thanks.
 *
 * @param particleSystem	Name of the particle system to precache.
 * @return					Returns the particle system index, INVALID_STRING_INDEX on error.
 */
stock int PrecacheParticleSystem(char[] particleSystem)
{
	int particleEffectNames = INVALID_STRING_TABLE;

	if (particleEffectNames == INVALID_STRING_TABLE) {
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
			return INVALID_STRING_INDEX;
		}
	}

	int index = FindStringIndex2(particleEffectNames, particleSystem);
	if (index == INVALID_STRING_INDEX) {
		int numStrings = GetStringTableNumStrings(particleEffectNames);
		if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) {
			return INVALID_STRING_INDEX;
		}

		AddToStringTable(particleEffectNames, particleSystem);
		index = numStrings;
	}

	return index;
}

/* SMLIB
 * Rewrite of FindStringIndex, because in my tests
 * FindStringIndex failed to work correctly.
 * Searches for the index of a given string in a string table.
 *
 * @param tableidx		A string table index.
 * @param str			String to find.
 * @return				String index if found, INVALID_STRING_INDEX otherwise.
 */
stock int FindStringIndex2(int tableidx, char[] str)
{
	char buf[1024];

	int numStrings = GetStringTableNumStrings(tableidx);
	for (int i=0; i < numStrings; i++) {
		ReadStringTable(tableidx, i, buf, sizeof(buf));

		if (StrEqual(buf, str)) {
			return i;
		}
	}

	return INVALID_STRING_INDEX;
}
#endif

bool isMiniBoss(int client)
{

    if(IsValidClient(client))
    {

        if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
        {

               return true;
        }
        else
        {
            
            return false;
        }
    }
    return false;
}