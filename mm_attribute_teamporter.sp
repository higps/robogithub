#pragma semicolon 1
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
#include <sdktools>
//#include <collisionhook>
#include <tf2_isPlayerInSpawn>
#include <morecolors>
#include <tfobjects>

//#pragma newdecls required
#define PLUGIN_VERSION "1.0"

#define ENGIE_SPAWN_SOUND		"vo/announcer_mvm_engbot_arrive02.mp3"
#define ENGIE_SPAWN_SOUND2		"vo/announcer_mvm_engbot_arrive03.mp3"

/*
#define TELEPORTER_ACTIVATE1	"vo/announcer_mvm_eng_tele_activated01.mp3"
#define TELEPORTER_ACTIVATE2	"vo/announcer_mvm_eng_tele_activated02.mp3"
#define TELEPORTER_ACTIVATE3	"vo/announcer_mvm_eng_tele_activated03.mp3"
#define TELEPORTER_ACTIVATE4	"vo/announcer_mvm_eng_tele_activated04.mp3"
#define TELEPORTER_ACTIVATE5	"vo/announcer_mvm_eng_tele_activated05.mp3"
*/

//Easier to have all the sounds we want in a single variable array for better access
static const char TeleActivateSounds[][256] =
{
	"vo/announcer_mvm_eng_tele_activated01.mp3",
	"vo/announcer_mvm_eng_tele_activated02.mp3",
	"vo/announcer_mvm_eng_tele_activated03.mp3",
	"vo/announcer_mvm_eng_tele_activated04.mp3",
	"vo/announcer_mvm_eng_tele_activated05.mp3"
};



#define TELEPORTER_SPAWN		"mvm/mvm_tele_deliver.wav"
#define TELEPORTER_ACTIVATE		"mvm/mvm_tele_activate.wav"

#define TF_OBJECT_TELEPORTER	1
#define TF_TELEPORTER_ENTR	0
// #define DEBUG
//new g_offsCollisionGroup;

/*
///
/// unused variables, keeping these here in case they were meant to be used at some point. Otherwise they just cause warnings in the compiler
///

bool AnnouncerQuiet;
int engieid = -1;
int g_iMaxEntities;
int BossTeleporter;
int g_iObjectParticle[2048];
bool teleportercheck;
bool engibotactive;
int EngieTeam = 2;

*/

bool g_Teleported[MAXPLAYERS + 1];
float vecSpawns[2][3];
int g_iPadType[2048];
char g_szOffsetStartProp[64];
int g_iOffsetMatchingTeleporter = -1;

int g_Recharge[MAXPLAYERS + 1] = 0;
int g_RechargeCap = 500;

bool g_TouchHooked[MAXPLAYERS + 1] = false;
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

enum //Custom ObjectType
{
	PadType_None = 0,
	PadType_Boost,
	PadType_Jump,
	PadType_Boss
}

enum // Return values for tele check
{
	TELE_WRONGTEAM = 0,
	TELE_IS_BUILDING,
	TELE_CARRIED,
	TELE_NOTEXIT,
	TELE_SAPPER,
	TELE_NOT_BOSS,
	TELE_RECHARGING,
 	TELE_READY,
	TELE_NO_TELE
}

enum struct ObjectPointer
{
	int reference; //reference

	void set(int entity)
	{
		if (IsValidEntity(entity) && entity > 0)
			this.reference = EntIndexToEntRef(entity);
		else
			this.reference = INVALID_ENT_REFERENCE;
	}

	int get()
	{
		return EntRefToEntIndex(this.reference);
	}

	void GetPos(float pos[3])
	{
		if (this.valid())
			GetEntPropVector(this.get(), Prop_Data, "m_vecOrigin", pos);
	}

	void GetAng(float angles[3])
	{
		if (this.valid())
			GetEntPropVector(this.get(), Prop_Send, "m_angRotation", angles);

	}

	bool valid()
	{
		int ent = this.get();
		if (IsValidEntity(ent) && ent > 0)
		{
			// if (GetTeleporterStatus(ent) == TELE_READY)
			// {
				return true;
			// }

		}
			

		return false;
	}
}

ObjectPointer PlayerTele[MAXPLAYERS + 1];

int SelectedIndex[MAXPLAYERS + 1];

// enum //TFOBjectType
// {
// 	TFObject_CartDispenser = 0,
// 	TFObject_Dispenser,
// 	TFObject_Teleporter,
// 	TFObject_Sentry,	
// 	TFObject_Sapper
// }

// TFObjectMode
// enum
// {
// 	TFObjectMode_None = 0,
// 	TFObjectMode_Entrance,	
// 	TFObjectMode_Exit,
// }
//List of teleporters used to determine the teamporter exists
int g_teleporters[MAXPLAYERS+1] = {-1, ...};

public Plugin myinfo =
{
	name = "[Manned Machines] Teamporter attribute",
	author = "HiGPS",
	description = "Adds Teamporter functionality for robots",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	//g_offsCollisionGroup = FindSendPropInfo("DT_BaseEntity", "m_CollisionGroup");
	HookEvent("player_builtobject", ObjectBuilt, EventHookMode_Post);
	HookEvent("player_carryobject", ObjectCarry, EventHookMode_Post);
	//HookEvent("player_upgradedobject", ObjectCarry, EventHookMode_Post);

	Handle hGameConf = LoadGameConfigFile("tf2.teleporters");
	if (hGameConf == INVALID_HANDLE)
		SetFailState("[EngiPads] Unable to load gamedata file 'tf2.teleporters.txt'");

	bool bFoundProp = GameConfGetKeyValue(hGameConf, "StartProp", g_szOffsetStartProp, sizeof(g_szOffsetStartProp));
	g_iOffsetMatchingTeleporter = GameConfGetOffset(hGameConf, "m_hMatchingTeleporter");

	if (!bFoundProp || g_iOffsetMatchingTeleporter < 0)
		SetFailState("[EngiPads] Unable to get m_hMatchingTeleporter offset from 'tf2.teleporters.txt'. Check gamedata!");

	CloseHandle(hGameConf);

	AddCommandListener(CommandListener_Build, "build");
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

	for(int i = 1; i <= MaxClients+1; i++)
	{
		if (IsValidClient(i))
		{
			SDKHook(i, SDKHook_Touch, OnTouch);
		}
	}
	// HookEvent("player_death", Event_Death, EventHookMode_Post);
	
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	return APLRes_Success;
}

public void OnMapStart()
{
	// HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

	//sound and model precaching should always be done in OnMapStart
	int size = sizeof TeleActivateSounds;
	for (int i = 0; i < size; i++)
		PrecacheSound(TeleActivateSounds[i], true);

	PrecacheSound(TELEPORTER_SPAWN, true);
	PrecacheSound(TELEPORTER_ACTIVATE, true);

	

}

// public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
// {
// 	//int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
// 	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

// 	if (IsValidClient(victim))
// 	{
// 		g_TouchHooked[victim] = false;
// 		SDKUnhook(victim, SDKHook_Touch, OnTouch);
// 	}
// }

// public void OnClientDisconnect_Post(int client)
// {
// 	if (IsValidClient(client))
// 	{
// 		g_TouchHooked[client] = false;
// 		SDKUnhook(client, SDKHook_Touch, OnTouch);
		
// 	} 
// }

public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");

	if (IsValidClient(iBuilder) && IsAnyRobot(iBuilder))
	{
		#if defined DEBUG
			PrintToChatAll("Found robot builder!");
		#endif

		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Teleporter)
		{

			g_teleporters[iBuilder] = EntIndexToEntRef(iObj);
			//PrintToChatAll("Iobj %i", iObj);
			#if defined DEBUG
				PrintToChatAll("Built builder teleporter!");
			#endif
			SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.0);
			SetEntProp(iObj, Prop_Send, "m_iHighestUpgradeLevel", 3);	//Set Pads to level 3 for cosmetic reasons related to recharging
			SetEntProp(iObj, Prop_Send, "m_iUpgradeLevel", 3);
			SetEntProp(iObj, Prop_Send, "m_bMiniBuilding", true);
			 //Setting m_bMiniBuilding tries to set the skin to a 'mini' skin. Since teles don't have one, reset the skin.
			SetEntProp(iObj, Prop_Send, "m_iTimesUsed", 0);
			RequestFrame(ResetSkin, iObj);
			TF2_SetMatchingTeleporter(iObj, iObj);

			SetVariantInt(RoundFloat(500.0));
			AcceptEntityInput(iObj, "AddHealth", iObj); //Spawns at 50% HP.
			SetEntProp(iObj, Prop_Send, "m_iTimesUsed", 0);


			//Set teleporter to itself - does not work yet
			// int iObjParti = CreatePadParticle(iObj, "teleporter_mvm_bot_persist");
			// g_iObjectParticle[iObj] = EntIndexToEntRef(iObjParti);
			//AcceptEntityInput(iObjParti, "Start");

			float position[3];
			GetEntPropVector(iObj, Prop_Data, "m_vecOrigin", position);
			int attach = CreateEntityByName("trigger_push");
			TeleportEntity(attach, position, NULL_VECTOR, NULL_VECTOR);

			if (TF2_GetClientTeam(iBuilder) == TFTeam_Blue)
			{
				TE_Particle("teleported_mvm_bot", position, _, _, attach, 1,0);
			}else
			{
				TE_Particle("teleported_mvm_bot_dust", position, _, _, attach, 1,0);	
				// TE_Particle("teleported_mvm_bot", position, _, _, attach, 1,0);	
			}
			
			//TE_Particle("teleporter_mvm_bot_persist", position, _, _, attach, 1,0);
			//TE_Particle("particles/teleported_mvm_bot_red", position, _, _, attach, 1,0);
			

			g_iPadType[iObj] = PadType_Boss;
			#if defined DEBUG
			PrintToChatAll("SetPadtype to %i", g_iPadType[iObj]);
			#endif
			//Doesn't work for some reason
			//EmitGameSoundToAll("Announcer.MVM_Engineer_Teleporter_Activated");

			int size = sizeof TeleActivateSounds;
			int soundswitch = GetRandomInt(0, size - 1);
			EmitSoundToAll(TeleActivateSounds[soundswitch]);

			/*switch(soundswitch)
			{
				case 1: EmitSoundToAll(TELEPORTER_ACTIVATE1);
				case 2: EmitSoundToAll(TELEPORTER_ACTIVATE2);
				case 3: EmitSoundToAll(TELEPORTER_ACTIVATE3);
				case 4: EmitSoundToAll(TELEPORTER_ACTIVATE4);
				case 5: EmitSoundToAll(TELEPORTER_ACTIVATE5);
			}
			*/
		}
	}
}

stock void TF2_SetMatchingTeleporter(int iTele, int iMatch)	//Set the matching teleporter entity of a given Teleporter
{

	if (IsValidEntity(iTele) && HasEntProp(iTele, Prop_Send, g_szOffsetStartProp))
	{
		//PrintToChatAll("Matching telepoters");
		int iOffs = FindSendPropInfo("CObjectTeleporter", g_szOffsetStartProp) + g_iOffsetMatchingTeleporter;
		SetEntDataEnt2(iTele, iOffs, iMatch, true);


	}

}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_Touch, OnTouch);
}

public void OnClientDisconnected(int client)
{
	SDKUnhook(client, SDKHook_Touch, OnTouch);
}

public void ObjectCarry(Event event, const char[] name, bool dontBroadcast)
{
	// if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)
	// return;
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	//int entRef = EntIndexToEntRef(iObj);
	//PrintToChatAll("iObj %i", iObj);

	if (IsValidClient(iBuilder) && IsAnyRobot(iBuilder))
	{
		// SetEntProp(iObj, Prop_Send, "m_iHighestUpgradeLevel", 3);
		// SetEntProp(iObj, Prop_Send, "m_iUpgradeLevel", 3);
		if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.0);

	//	SetEntPropFloat(iObj, Prop_Send, "m_flPercentageConstructed", 1.0);
		//SetEntProp(iObj, Prop_Send, "m_CollisionGroup", 2);
		//SetEntPropFloat(iObj, Prop_Send, "m_bDisposableBuilding", 1.0);
//		DispatchKeyValue(iObj, "defaultupgrade", "2");
		//SetEntPropFloat(iObj, Prop_Send, "m_iUpgradeMetalRequired ", 0.1);
		//SDKHook(iObj, SDKHook_ShouldCollide, ShouldCollide );
		//CH_PassFilter(iBuilder, iObj, false);
		//SetEntData(iObj, g_offsCollisionGroup, 2, 4, false);

	}
}

bool g_spawnclamp[MAXPLAYERS + 1] = false;

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_Teleported[client])
		return Plugin_Continue;

	#if defined DEBUG
	PrintToChatAll("%N spawned", client);
	#endif
	if (!IsAnyRobot(client))
	{
		#if defined DEBUG
		PrintToChatAll("%N spawned and was not a robot", client);
		#endif
		return Plugin_Changed;
	}
	
	if (IsAnyRobot(client)){

	g_Recharge[client] = 0;
	g_TouchHooked[client] = true;
	
	// FindRoboExit(client);

	}
	
	// int team = GetClientTeam(client);

	// // if (team != EngieTeam)
	// // 	return Plugin_Continue;
	
	// float angles[3], pos[3];
	// if (GetTeamporterTransform(team, angles, pos) && !g_spawnclamp[client])
	// {
	// 	MC_PrintToChatEx(client, client, "{orange}==[TEAMPORTER ACTIVE]==");
	// 	MC_PrintToChatEx(client, client, "{teamcolor}==[HOLD CROUCH TO CHARGE TELEPORT IN SPAWN!]==");
	// 	//EmitSoundToAll(TELEPORTER_ACTIVATE, client, _,_,_,0.3);
	// 	EmitSoundToClient(client, TELEPORTER_ACTIVATE);
	// 	g_spawnclamp[client] = true;
	// 	CreateTimer(1.5, SpawnSound_Clamp, client);
	// }

	return Plugin_Continue;
}
// bool g_b_CanGetTeled[MAXPLAYERS + 1];

public Action OnTouch(int client, int ent)
{

	if (IsValidClient(client) && IsClientInGame(client))
	{
		char entname[MAX_NAME_LENGTH];
		GetEntityClassname(ent, entname, sizeof(entname));

		if (!StrContains(entname, "func_respawnroom"))
		{
			// PrintToChatAll("%N is touching %s", client, entname);
			if (IsAnyRobot(client) && TF2Spawn_IsClientInSpawn(client) && TeamHasRoboEngineer(client))
			{
				UpdateCharge(client);
				DrawHUD(client);
				// PrintCenterText(client, "Touching Spawn Robo");
				// g_b_CanGetTeled[client] = true;
			}
			else if (!IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Spy)
			{
				int EntTeamNum = GetEntProp(ent, Prop_Send, "m_iTeamNum");
				int clientTeam = GetClientTeam(client);
				if (EntTeamNum != clientTeam)
				{
					UpdateCharge(client);
					DrawHUD(client);
					// PrintCenterText(client, "Touching Enemy Spawn Spy");
					// g_b_CanGetTeled[client] = true;
				}
			}
		
				
				
		}
	}
	return Plugin_Continue;
}

// public Action Teleport_Player_old(int client)
// {
// 	if (g_Teleported[client])
// 		return Plugin_Continue;

// 	#if defined DEBUG
// 	PrintToChatAll("%N spawned", client);
// 	#endif

// 	int team = GetClientTeam(client);

// 	// if (team != EngieTeam)
// 	// 	return Plugin_Continue;

// 	float angles[3], pos[3];
// 	if (GetTeamporterTransform(team, angles, pos) == 1)
// 	{
// 		pos[2] += 15.0;
// 		// Don't get stuck inside of teleporter
// 		#if defined DEBUG
// 			PrintToChatAll("%N was teleported", client);
// 		#endif
// 		TeleportEntity(client, pos, angles, NULL_VECTOR);
// 		EmitSoundToAll(TELEPORTER_SPAWN, client, _,_,_, 0.3);
// 		CreateTimer(0.5, Teleport_Clamp, client);
// 		g_Recharge[client] = 1;
// 		g_Teleported[client] = true;
// 		float oober = 3.0;
// 		TF2_AddCondition(client, TFCond_Ubercharged, oober);
// 		TF2_AddCondition(client, TFCond_TeleportedGlow, 5.0);
// 		g_spawnclamp[client] = false;
		
// 	}
// 	return Plugin_Continue;
// }

//This should find the nearest teleporter exit built by a robo engie and give its rotation and position
int GetTeamporterTransform(int team, float angles[3], float pos[3])
{
	//PrintToChatAll("Got here1");
	int j = 1;
	int ent = -1;
	int tele;
	int status = 0;
	int i = (team == 2 ? 1 : 0);
	float vecSpawn[3];
	float vecIsActuallyGoingToSpawn[3] = {-99999.0, -99999.0, -99999.0};
	float dist, otherdist = GetVectorDistance(vecIsActuallyGoingToSpawn, vecSpawns[i]);
	//g_teleporters[client] 
// while ((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1)
	while(j++ <= MaxClients+1)
	{
	//	PrintToChatAll("Got here");

		if (IsValidClient(j) && IsClientInGame(j))
		{
			if(IsValidEntity(g_teleporters[j])){
					//	PrintToChatAll("ITERATING in WHILE %N, %i", j, g_teleporters[j]);
						continue;
		}
		
		
		ent = EntRefToEntIndex(g_teleporters[j]);

		//PrintToChatAll("Got here");
		if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != team)
			continue;


		if (GetEntProp(ent, Prop_Send, "m_bBuilding"))
		{
			status = 2;
			continue;	
		}
		if (GetEntProp(ent, Prop_Send, "m_bCarried"))	// If being carried
			continue;
		if (GetEntProp(ent, Prop_Send, "m_iObjectMode") != 1)	// If not exit
			continue;
		if (GetEntProp(ent, Prop_Send, "m_bHasSapper")){			//has sapper
			status = 3;
			continue;
		}
		if (g_iPadType[ent] != PadType_Boss)
			continue;
		if (TF2_GetBuildingState(ent) != TELEPORTER_STATE_READY)
			continue;
		// if (TF2_GetBuildingState(ent) == TELEPORTER_STATE_READY)
		// 	continue;

		// int state = TF2_GetBuildingState(ent);
		// PrintToChatAll("%i state", state);

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecSpawn);
		dist = GetVectorDistance(vecSpawn, vecSpawns[i]);
		if (dist < otherdist)
		{
			otherdist = dist;
			vecIsActuallyGoingToSpawn = vecSpawn;
			pos = vecSpawn;
			GetEntPropVector(ent, Prop_Send, "m_angRotation", angles);	// Force players to look in the direction of teleporter on spawn
			tele = ent;
		}
	}
	// If no teleporters found
	//if (GetVectorDistance(vecIsActuallyGoingToSpawn, vecSpawns[i]) >= 70000)

	if (status == 3)
	{
		// PrintToChatAll("IsSapped");
		return 3;
	}

	if (status == 2)
	{
		// PrintToChatAll("IsBuilding");
		return 2;
	}
	if (!tele)
	{
		#if defined DEBUG
			PrintToChatAll("No teleporters found!");
		#endif
		// PrintToChatAll("No teleporters found!");
		return 0;
	}

	return 1;
	}
}

int GetTeleporterStatus(int ent){
	
		int team = GetEntProp(ent, Prop_Data, "m_iTeamNum");

		if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != team)
			return TELE_WRONGTEAM;
		if (GetEntProp(ent, Prop_Send, "m_bBuilding"))
		{
			// PrintToChatAll("Building");
			return TELE_IS_BUILDING;
		}
		if (GetEntProp(ent, Prop_Send, "m_bCarried"))
		{
			// PrintToChatAll("Carried");	// If being carried
			return TELE_CARRIED;
		}
		if (GetEntProp(ent, Prop_Send, "m_iObjectMode") != 1)	// If not exit
		{
			// PrintToChatAll("Not Exit");
			return TELE_NOTEXIT;
		}
		if (GetEntProp(ent, Prop_Send, "m_bHasSapper"))
		{			//has sapper
			// PrintToChatAll("Is Sapped");
			return TELE_SAPPER;
		}
		if (g_iPadType[ent] != PadType_Boss)
		{
			//	PrintToChatAll("Not boss");
			return TELE_NOT_BOSS;
		}
		if (TF2_GetBuildingState(ent) != TELEPORTER_STATE_READY)
		{
		//	PrintToChatAll("Tele was not ready");
			return TELE_RECHARGING;
			
		}
		//PrintToChatAll("Good To GO!");
		return TELE_READY;
}

public Action Teleport_Clamp(Handle timer, int client)
{
	g_Teleported[client] = false;
}

public Action SpawnSound_Clamp(Handle timer, int client)
{
	g_spawnclamp[client] = false;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (CanUseTele(client) && buttons & (IN_DUCK))
	{

		if(g_Recharge[client] == g_RechargeCap && TF2_IsPlayerInCondition(client, TFCond_TeleportedGlow))
		{
			Teleport_Player(client);
		}
	}
}

//Charging the tele to spawn

void UpdateCharge(int client)
{
	// if we are already at max charge, no need to check anything
	if(CanUseTele(client))
	{
		if(IsFakeClient(client))
		{
			Teleport_Player(client);
		}
		if(g_Recharge[client] >= g_RechargeCap)
		{
		g_Recharge[client] = g_RechargeCap;
		}else
		{
			g_Recharge[client]++;
		}	
	}
}

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"

bool b_hud_clamp[MAXPLAYERS + 1] = false;

public Action DrawHUD(int client)
{

	if (IsClientInGame(client) && IsValidClient(client)){
	char sHUDText[128];
	char sProgress[32];
	int iPercents = RoundToCeil(float(g_Recharge[client]) / float(g_RechargeCap) * 100.0);

	for (int j = 1; j <= 10; j++)
	{
		if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
		else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}

	// int team = GetClientTeam(client);

	// float angles[3], pos[3];
	// Format(sHUDText, sizeof(sHUDText), "Charging Teamporter: %d%%%%   \n%s   ", iPercents, sProgress);
	// SetHudTextParams(-1.0, -0.2, 0.1, 255, 255, 255, 255);

	ObjectPointer teleporters[32];
	ObjectPointer farthest;
	GetFarthestTele(client, farthest, teleporters);

	if(iPercents >= 100)
	{
		//Charge is 100% check for teleporters


		// CreateTeleMenu(client, teleporters);

		// GetActiveSelection(client, PlayerTele[client], farthest);

		// ObjectPointer tele;
		// tele = PlayerTele[client];

		// char description[256];
		
		
		if (farthest.valid())
		{
			//Check if teleporters are in the correct status
			int teleporter = farthest.get();
			

			switch(GetTeleporterStatus(teleporter))
			{
				case TELE_IS_BUILDING:
				{
				//	PrintCenterTextAll("Ready");
					Format(sHUDText, sizeof sHUDText, "Teamporter Ready!\nTeamporter is building");
					SetHudTextParams(-1.0, -0.2, 0.1, 0, 130, 130, 255);
				}
				case TELE_CARRIED:
				{
				//	PrintCenterTextAll("Ready");
					Format(sHUDText, sizeof sHUDText, "Teamporter Ready!\nTeamporter is being carried");
					SetHudTextParams(-1.0, -0.2, 0.1, 130, 130, 0, 255);
				}
				case TELE_SAPPER:
				{
				//	PrintCenterTextAll("Ready");
					Format(sHUDText, sizeof sHUDText, "Teamporter Ready!\nTeamporter is Disabled / Sapped");
					SetHudTextParams(-1.0, -0.2, 0.1, 133, 0, 130, 255);
				}
				case TELE_RECHARGING:
				{
				//	PrintCenterTextAll("Ready");
					Format(sHUDText, sizeof sHUDText, "Teamporter Ready!\nEngipad Teamporter is Recharging...");
					SetHudTextParams(-1.0, -0.2, 0.1, 50, 50, 100, 255);
				}
				case TELE_READY:
				{
				//	PrintCenterTextAll("Ready");
					Format(sHUDText, sizeof(sHUDText), "Teamporter Ready!\nCrouch to Teleport!");
					TF2_AddCondition(client, TFCond_TeleportedGlow, 1.0);
					SetHudTextParams(-1.0, -0.2, 0.1, 0, 255, 0, 255);
				}
				// case TELE_WRONGTEAM:
				// {
				// //	PrintCenterTextAll("Ready");
				// 	Format(sHUDText, sizeof(sHUDText), "Wrong Team!\nCrouch to Teleport!");
				// 	TF2_AddCondition(client, TFCond_TeleportedGlow, 1.0);
				// 	SetHudTextParams(-1.0, -0.2, 0.1, 0, 255, 0, 255);
				// }
				// default:
				// {
				// 	Format(sHUDText, sizeof(sHUDText), "Teamporter Ready!\nNo active Teleporter");
				// 	SetHudTextParams(-1.0, -0.2, 0.1, 255, 0, 0, 255);
				// }

			}
		//PrintCenterText(client, description);
		// return Plugin_Continue;	
		}else
		{
		Format(sHUDText, sizeof(sHUDText), "Teamporter Ready!\nNo active Teleporter");
		SetHudTextParams(-1.0, -0.2, 0.1, 255, 0, 0, 255);
		}

	
	// if(iPercents >= 100)
	// {
	// 	if (GetTeamporterTransform(team, angles, pos))
	// 	{
	// 		if (GetTeamporterTransform(team, angles, pos) == 2){
	// 			Format(sHUDText, sizeof(sHUDText), "Teamporter Ready!\nTeamporter is building");
	// 			SetHudTextParams(-1.0, -0.2, 0.1, 0, 130, 130, 255);
	// 		}else if (GetTeamporterTransform(team, angles, pos) == 3){
	// 			Format(sHUDText, sizeof(sHUDText), "Teamporter Ready!\nTeamporter is sapped");
	// 			SetHudTextParams(-1.0, -0.2, 0.1, 133, 0, 130, 255);
	// 		}else{
	// 			Format(sHUDText, sizeof(sHUDText), "Teamporter Ready!\nCrouch to Teleport!");
	// 			TF2_AddCondition(client, TFCond_TeleportedGlow, 1.0);
	// 			SetHudTextParams(-1.0, -0.2, 0.1, 0, 255, 0, 255);
	// 		}
			
	// 		if (!g_spawnclamp[client])
	// 		{
	// 			EmitSoundToClient(client, TELEPORTER_ACTIVATE, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.35);
	// 			g_spawnclamp[client] = true;
	// 		}
	// 	}else if (!GetTeamporterTransform(team, angles, pos))
	// 	{
	// 		Format(sHUDText, sizeof(sHUDText), "Teamporter Ready!\nNo active Teleporter");
	// 		SetHudTextParams(-1.0, -0.2, 0.1, 255, 0, 0, 255);
	// 	}
		
	// } else {

	// 	SetHudTextParams(-1.0, -0.2, 0.1, 255, 255, 255, 255);
	// }


	}else
	{	
	Format(sHUDText, sizeof(sHUDText), "Charging Teamporter: %d%%%%   \n%s   ", iPercents, sProgress);
	
	SetHudTextParams(-1.0, -0.2, 0.1, 255, 255, 255, 255);

	if (farthest.valid())
		{
			//Check if teleporters are in the correct status
			int teleporter = farthest.get();

			switch(GetTeleporterStatus(teleporter))
			{
				case TELE_IS_BUILDING:
				{
					Format(sHUDText, sizeof(sHUDText), "%s\nTeamporter is building", sHUDText);
					SetHudTextParams(-1.0, -0.2, 0.1, 0, 130, 130, 255);
				}
				case TELE_CARRIED:
				{
					Format(sHUDText, sizeof(sHUDText), "%s\nTeamporter is being carried", sHUDText);
					SetHudTextParams(-1.0, -0.2, 0.1, 130, 130, 0, 255);
				}
				case TELE_SAPPER:
				{
					Format(sHUDText, sizeof(sHUDText), "%s\nnTeamporter is Disabled / Sapped", sHUDText);
					SetHudTextParams(-1.0, -0.2, 0.1, 133, 0, 130, 255);
				}
				case TELE_RECHARGING:
				{
				Format(sHUDText, sizeof(sHUDText), "%s\nEngipad Teamporter is Recharging...", sHUDText);
					SetHudTextParams(-1.0, -0.2, 0.1, 50, 50, 100, 255);
				}
				case TELE_READY:
				{
					Format(sHUDText, sizeof(sHUDText), "%s\nTeamporter ready!", sHUDText);
					SetHudTextParams(-1.0, -0.2, 0.1, 0, 255, 0, 255);
				}
				// case TELE_WRONGTEAM:
				// {
				// //	PrintCenterTextAll("Ready");
				// 	Format(sHUDText, sizeof(sHUDText), "Wrong Team!\nCrouch to Teleport!");
				// 	TF2_AddCondition(client, TFCond_TeleportedGlow, 1.0);
				// 	SetHudTextParams(-1.0, -0.2, 0.1, 0, 255, 0, 255);
				// }
				// default:
				// {
				// 	Format(sHUDText, sizeof(sHUDText), "Teamporter Ready!\nNo active Teleporter");
				// 	SetHudTextParams(-1.0, -0.2, 0.1, 255, 0, 0, 255);
				// }

			}
		//PrintCenterText(client, description);
		// return Plugin_Continue;	
		}else
		{
			Format(sHUDText, sizeof(sHUDText), "%s\nNo active Teleporter",sHUDText);
			SetHudTextParams(-1.0, -0.2, 0.1, 255, 0, 0, 255);
		}



	}
	ShowHudText(client, -2, sHUDText);
	b_hud_clamp[client] = false;
	}
}

stock void TE_Particle(char[] Name, float origin[3] = NULL_VECTOR, float start[3] = NULL_VECTOR, float angles[3] = NULL_VECTOR, entindex=-1, attachtype=-1, attachpoint=-1, bool resetParticles=true, customcolors = 0, float color1[3] = NULL_VECTOR, float color2[3] = NULL_VECTOR, controlpoint = -1, controlpointattachment = -1, float controlpointoffset[3] = NULL_VECTOR)
{
    // find string table
    int tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx == INVALID_STRING_TABLE)
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    float delay = 3.0;
    // find particle index
    char tmp[256];
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;

    for (int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx == INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }

    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex !=- 1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype != -1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint != -1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);

    if(customcolors)
    {
        TE_WriteNum("m_bCustomColors", customcolors);
        TE_WriteVector("m_CustomColors.m_vecColor1", color1);
        if(customcolors == 2)
        {
            TE_WriteVector("m_CustomColors.m_vecColor2", color2);
        }
    }
    if(controlpoint != -1)
    {
        TE_WriteNum("m_bControlPoint1", controlpoint);
        if(controlpointattachment != -1)
        {
            TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", controlpointattachment);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", controlpointoffset[0]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", controlpointoffset[1]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", controlpointoffset[2]);
        }
    }
    TE_SendToAll(delay);
}

// public Action DeleteTrigger(Handle timer, any Ent)
// {
// 	if (!IsValidEntity(Ent)) return;
// 	char cls[25];
// 	GetEdictClassname(Ent, cls, sizeof(cls));
// 	if (StrEqual(cls, "trigger_push", false)) AcceptEntityInput(Ent, "Kill");
// 	return;
// }

public Action CommandListener_Build(client, const char[] command, argc)
{
	char sObjectMode[256], sObjectType[256];
	GetCmdArg(1, sObjectType, sizeof(sObjectType));
	GetCmdArg(2, sObjectMode, sizeof(sObjectMode));
	int iObjectMode = StringToInt(sObjectMode);
	int iObjectType = StringToInt(sObjectType);

	if(IsAnyRobot(client) && iObjectType == TF_OBJECT_TELEPORTER && iObjectMode == TF_TELEPORTER_ENTR)
	{
		PrintCenterText(client,"You can't build an entrance, you can only build an exit teleporter!");
		PrintToChat(client,"You can't build an entrance , you can only build an exit teleporter!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock void ResetSkin(int iEnt)
{
	if (IsValidEntity(iEnt) && HasEntProp(iEnt, Prop_Send, "m_nSkin"))
	{
		int iTeam = GetEntProp(iEnt, Prop_Data, "m_iTeamNum");
		SetEntProp(iEnt, Prop_Send, "m_nSkin", iTeam - 2);



	}
}

public void OnGameFrame()
{
	// if (cvarPads[PadsEnabled].IntValue == EngiPads_Disabled)
	// 	return;
	//PrintToChatAll("THINKING1!");
	int i = -1;
	while ((i = FindEntityByClassname2(i, "obj_teleporter")) != -1)
	{
		if (IsValidEntity(i))
		{
			if (g_iPadType[i] == PadType_Boss){
				//PrintToChatAll("THINKING!");
				OnPadThink(i);
			}

		}
	}
}

void OnPadThink(int iPad)
{
	float flConstructed = GetEntPropFloat(iPad, Prop_Send, "m_flPercentageConstructed");
	bool bBuilding = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bBuilding"));
	bool bCarried = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bCarried"));
	bool bPlacing = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bPlacing"));
	bool bDisabled = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bDisabled"));
	bool bSapped = view_as<bool>(GetEntProp(iPad, Prop_Send, "m_bHasSapper"));

	//PrintToChatAll("Teleporter state: %i", TF2_GetBuildingState(iPad));

	if (bCarried || bPlacing || bDisabled)
	{
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
	}
	//int iObjParti = EntRefToEntIndex(g_iObjectParticle[iPad]);

	if (bSapped)
	{
		if (GetEntProp(iPad, Prop_Send, "m_iUpgradeLevel") > 1)
		{
			SetEntProp(iPad, Prop_Send, "m_iUpgradeLevel", 1);	//Prevents the Red-Tape Recorder having to downgrade Pads before deconstructing.
			SetEntProp(iPad, Prop_Send, "m_iHighestUpgradeLevel", 1);
			TF2_SetBuildingState(iPad, TELEPORTER_STATE_IDLE);

		}
		//	PrintToChatAll("Sapped");
		return;
	}



	// if (TF2_GetBuildingState(iPad) > TELEPORTER_STATE_BUILDING && TF2_GetBuildingState(iPad) < TELEPORTER_STATE_UPGRADING)
	// {
	// 	if (TF2_GetBuildingState(iPad) != TELEPORTER_STATE_READY)/*  && GetEntPropFloat(iPad, Prop_Send, "m_flRechargeTime") <= GetGameTime() */
	// 	{
	// 		//AcceptEntityInput(iPad, "Start");
	// 		TF2_SetBuildingState(iPad, TELEPORTER_STATE_READY);	//Make sure the Pad always re-activates when it's supposed to.

	// 	//	AcceptEntityInput(iObjParti, "Start");
	// 		// #if defined DEBUG
	// 		// PrintToChatAll("%i Ready!", iPad);
	// 		// #endif
	// 	}
	// 	// if (TF2_GetBuildingState(iPad) == TELEPORTER_STATE_READY && IsValidEntity(iObjParti) && !bSapped)
	// 	// {
	// 	// 	AcceptEntityInput(iObjParti, "Start");
	// 	// }

	// }
	SetEntPropFloat(iPad, Prop_Send, "m_flCurrentRechargeDuration", 1.0);
	SetEntPropFloat(iPad, Prop_Send, "m_flYawToExit", GetEntPropFloat(iPad, Prop_Send, "m_flYawToExit") + 10.0);	//Make the arrow spin for fun, and to indicate its not a Teleporter (but mostly for fun)
	if (GetEntPropFloat(iPad, Prop_Send, "m_flYawToExit") > 360.0){
		SetEntPropFloat(iPad, Prop_Send, "m_flYawToExit", 0.0);
	}



}
int FindEntityByClassname2(int startEnt, char[] classname)
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

int TF2_GetBuildingState(int iBuilding)
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
	if (IsValidEntity(iBuilding) && g_iPadType[iBuilding] == PadType_Boss)
	{
	SetEntProp(iBuilding, Prop_Send, "m_iState", iState);
	//	PrintToChatAll("Setting state to %i", iState);
	}
}

bool TeamHasRoboEngineer(int client)
{
	TFTeam Team = TF2_GetClientTeam(client);
	// int positive = 0;
	for(int i = 1; i <= MaxClients+1; i++)
	{
		if (IsValidClient(i) && IsClientInGame(i))
		{
			TFTeam iTeam = TF2_GetClientTeam(i);
			if(iTeam == Team)
			{
				TFClassType iClass = TF2_GetPlayerClass(i);
				if (iClass == TFClass_Engineer && IsAnyRobot(i))
				{

					// FindRoboExit(i);
					return true;
					
					// positive++;
					
				}
			}
		}
	}
	return false;
}

// void FindRoboExit(int client)
// {
// 	if (IsAnyRobot(client))
// 	{
// 		int NumObjects = TF2_GetNumObjects(client, TFObjectMode_Exit, TFObject_Teleporter, false);
// 		//Found the teleporter
// 		if (NumObjects == 1)
// 		{
// 			// int teleporter = TF2_GetObject(client, TFObject_Teleporter);

// 			int teleporter = TF2_GetObjectOfType(client, TFObjectMode_Exit, TFObjectMode_None, false);
// 			// g_teleporters[client] = teleporter;
// 			//PrintToChatAll("%N had %i objects. Teleporter %i", client, NumObjects, teleporter);
// 			//return teleporter;
// 		}else
// 		{
// 			// g_teleporters[client] = 0;
// 		}

// 	// AcceptEntityInput(teleporter, "Kill");
// 	}
	
// 	//return 0;
// }

// public void OnPluginStart()
// {
// 	RegConsoleCmd("sm_teleportto", CmdTele);
// }

Action Teleport_Player(int client)
{
	ObjectPointer target;
	target = PlayerTele[client];
	
	ObjectPointer teleporters[32];
	ObjectPointer farthest;
	GetFarthestTele(client, farthest, teleporters);
	
	target = farthest;

	int teleporter = target.get();

	if (target.valid() && GetTeleporterStatus(teleporter) == TELE_READY)
	{

		float destination[3];
		float angles[3];
		target.GetPos(destination);
		target.GetAng(angles);
		destination[2] += 15.0;

		TeleportEntity(client, destination, angles, NULL_VECTOR);

		//TeleportEntity(client, pos, angles, NULL_VECTOR);
		EmitSoundToAll(TELEPORTER_SPAWN, client, _,_,_, 0.3);
		CreateTimer(0.5, Teleport_Clamp, client);
		g_Recharge[client] = 1;
		g_Teleported[client] = true;
		float oober = 3.0;
		TF2_AddCondition(client, TFCond_Ubercharged, oober);
		TF2_AddCondition(client, TFCond_TeleportedGlow, 5.0);
		g_spawnclamp[client] = false;
	}
	// else
	// 	PrintCenterText(client, "No teleporters found");

	// return Plugin_Continue;
}

void GetFarthestTele(int client, ObjectPointer target, ObjectPointer teleporters[32]) //shouldn't ever be more than 32 teleporters at a time... really only 16 for team teleporters but doing 32 just in case
{
	float distance = 0.0;

	float origin[3], destination[3];

	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (IsAnyRobot(i) && GetClientTeam(client) == GetClientTeam(i)
			|| !IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Spy && GetClientTeam(client) != GetClientTeam(i)) //engineers on same team
			{
				ObjectPointer tele;
				tele.set(TF2_GetObjectOfType(i, TFObject_Teleporter, TFObjectMode_Exit, false));
				// PrintToChatAll("Checking if valid");
				if (tele.valid())
				{
					teleporters[count] = tele;
					// PrintToChatAll("Was valid");
					count++;

					tele.GetPos(destination);
					GetClientAbsOrigin(client, origin);

					float teleDistance = GetVectorDistance(origin, destination);
					if (teleDistance >= distance)
					{
						distance = teleDistance;
						target = tele;
						// PrintToChatAll("Setting valid");
					}
				}
			}
		}
	}
}

bool CanUseTele(int client)
{
	if (TF2_GetPlayerClass(client) == TFClass_Spy || IsAnyRobot(client)) // Spies can use whatever teleporter they want, so we don't bother checking teams
		return true;

	// return (GetClientTeam(client) == GetClientTeam(engi)); // Otherwise check to see we are on the same team
}

///
/// Finds all active teleporters, sets the farthest teleport as the current active teleporter
/// Status of the farthest teleporter
/// Just move this to wherever you need it to be
///


// Creates a menu with all active teleporters
void CreateTeleMenu(int client, ObjectPointer teleporters[32])
{
	if (!teleporters[0].valid()) // Only create a menu if teleporters exist
		return;

	Menu selection = new Menu(SelectionCallback);
	selection.SetTitle("Choose Teamporter");

	selection.AddItem("-1", "Farthest");

	for (int i = 0; i < 32; i++)
	{
		if (teleporters[i].valid())
		{
			int tele = teleporters[i].get();

			char index[8], teleName[256], teleStatus[32];
			IntToString(tele, index, sizeof index);

			int owner = GetEntPropEnt(tele, Prop_Send, "m_hBuilder");

			if (GetEntProp(tele, Prop_Send, "m_bDisabled"))
				FormatEx(teleStatus, sizeof teleStatus, "Sapped");
			else if (GetEntProp(tele, Prop_Send, "m_bBuilding"))
			FormatEx(teleStatus, sizeof teleStatus, "Building");
			else
				FormatEx(teleStatus, sizeof teleStatus, "Active");

			// Get the name of the teleporter's owner, otherwise set the teleporter's index as the name as a fallback
			if (IsClientInGame(owner))
				FormatEx(teleName, sizeof teleName, "%N's Exit (%s)", owner, teleStatus);
			else
				FormatEx(teleName, sizeof teleName, "Exit %i (%s)", tele, teleStatus);

			selection.AddItem(index, teleName);
		}
		else	// Stop populating if we find an invalid index
			break;
	}

	selection.Display(client, 3);
}

int SelectionCallback(Menu menu, MenuAction action, int client, int selection)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char value[8];
			menu.GetItem(selection, value, sizeof value);

			SelectedIndex[client] = StringToInt(value);
		}
	}
	return 0;
}

void GetActiveSelection(int client, ObjectPointer teleporter, ObjectPointer farthest)
{
	if (SelectedIndex[client] == -1) // farthest selection
		teleporter = farthest;
	else
		teleporter.set(SelectedIndex[client]);
}


