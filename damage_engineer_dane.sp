#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <tfobjects>
#include <dhooks>
#include <sdktools>
//#include <collisionhook>
#include <tf_custom_attributes>

#pragma semicolon 1
//#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Uncle Dane"
#define ROBOT_ROLE "Damage"
#define ROBOT_DESCRIPTION " Widowmaker, Jag"

#define ChangeDane             "models/bots/engineer/bot_engineer.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

#define MUSIC "uncle_dane_dispenser.wav"


#define ENGIE_SPAWN_SOUND		"vo/announcer_mvm_engbot_arrive02.mp3"
#define ENGIE_SPAWN_SOUND2		"vo/announcer_mvm_engbot_arrive03.mp3"

#define TELEPORTER_ACTIVATE1	"vo/announcer_mvm_eng_tele_activated01.mp3"
#define TELEPORTER_ACTIVATE2	"vo/announcer_mvm_eng_tele_activated02.mp3"
#define TELEPORTER_ACTIVATE3	"vo/announcer_mvm_eng_tele_activated03.mp3"
#define TELEPORTER_ACTIVATE4	"vo/announcer_mvm_eng_tele_activated04.mp3"
#define TELEPORTER_ACTIVATE5	"vo/announcer_mvm_eng_tele_activated05.mp3"

#define TELEPORTER_SPAWN		"mvm/mvm_tele_deliver.wav"

#define TF_OBJECT_TELEPORTER	1
#define TF_TELEPORTER_ENTR	0

//new g_offsCollisionGroup;

bool engibotactive;
bool teleportercheck;
bool AnnouncerQuiet;


int EngieTeam = 2;
int engieid = -1;
int g_iMaxEntities;
int BossTeleporter;

float vecSpawns[2][3];

static int g_iPadType[2048];
static int g_iObjectParticle[2048];

static char g_szOffsetStartProp[64];
static int g_iOffsetMatchingTeleporter = -1;

bool g_ReadyToTeamPort[MAXPLAYERS + 1] = false;
bool g_Announcerquiet = false;

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
	PadType_Boss,
}

enum OBJSOLIDTYPE
{
	SOLID_TO_PLAYER_USE_DEFAULT = 0,
	SOLID_TO_PLAYER_YES,
	SOLID_TO_PLAYER_NO,
}

public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Uncle Dane",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Uncle Dane Bot from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    //g_offsCollisionGroup = FindSendPropInfo("DT_BaseEntity", "m_CollisionGroup");
    HookEvent("player_builtobject", ObjectBuilt, EventHookMode_Post);
	HookEvent("player_carryobject", ObjectCarry, EventHookMode_Post);
	HookEvent("player_upgradedobject", ObjectBuilt, EventHookMode_Post);

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

	//AddCommandListener(CommandListener_Build, "build");
	//HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

	//RegConsoleCmd("sm_dane", Dane, "become dane");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Engineer";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeUncleDane, PLUGIN_VERSION);
	
	PrecacheSound(ENGIE_SPAWN_SOUND, true);
	PrecacheSound(ENGIE_SPAWN_SOUND2, true);
	PrecacheSound(TELEPORTER_ACTIVATE1, true);
	PrecacheSound(TELEPORTER_ACTIVATE2, true);
	PrecacheSound(TELEPORTER_ACTIVATE3, true);
	PrecacheSound(TELEPORTER_ACTIVATE4, true);
	PrecacheSound(TELEPORTER_ACTIVATE5, true);
	PrecacheSound(TELEPORTER_SPAWN, true);



    // for(int client = 1 ; client <= MaxClients ; client++)
    // {
    //     if(IsClientInGame(client))
    //     {
    //       //  SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	// 	//PrintToChatAll("Hooking %N", client);
	// 	SDKHook(client, SDKHook_Touch, OnTouch);
    //     //SDKHook(client, SDKHook_EndTouchPost, OnTouch);
	// 	//SDKHook(client,SDKHook_EndTouch, OnTouchPost);
    //     }
    // }

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
// public OnEntityCreated(entity, const String:classname[])
// {
//     if(StrContains(classname[1], "item_ammopack", false) != -1 || StrContains(classname[1], "item_healthkit", false) != -1)
//     {
//        // SDKHook(entity,    SDKHook_StartTouch,     StartTouch);
//         SDKHook(entity,    SDKHook_Touch,             OnTouch);
//     }
// }




// public Action OnTouchPost(int client, int ent)
// {
// 	// char entname[MAX_NAME_LENGTH];
// 	// GetEntityClassname(ent, entname, sizeof(entname));
// 	// //PrintToChatAll("Touching %N", client);
// 	// // if (!StrContains(entname, "dispenser") || !StrContains(entname, "sentry")){
// 	// // 	PrintToChatAll("Ent: %s", entname);
//     // // 	if(GetEntProp(ent, Prop_Data, "m_bDisabled") == 1)
//     // //     return;
// 	// // }
// 	// if (IsRobot(client, ROBOT_NAME))
// 	// {

// 	// 	if (!StrContains(entname, "obj_dispenser") || !StrContains(entname, "obj_sentrygun")){
// 	// 		PrintToChatAll("Ent: %s", entname);

// 	// 		int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");

// 	// 		PrintToChatAll("Builder was %i", iBuilder);
// 	// 		// if(GetEntProp(ent, Prop_Data, "m_bDisabled") == 1)
// 	// 		// return;

// 	// 		SetEntPropEnt(ent, Prop_Send, "m_hBuilder", client);

// 	// 	}
		
// 	// }
	
	
// }

// public Action OnTouch(int client)
// {
// 	PrintToChatAll("TOUCHING! %N", client);
// }

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeUncleDane", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheModel(ChangeDane);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);

	PrecacheSound(MUSIC);
	

}




/* public bool ShouldCollide(entity, collisiongroup, contentmask, bool result)
{	
	PrintToChatAll("Returning false");
	return false;
}
 */
//trigger the event
// public void PlayerUpgradedobject(Event evnet, const char[] name, bool dontBroadcast)
// {
// PrintToChatAll("Upgrade complete");
// }

public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	// if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)
	// return;
	
	
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	//int entRef = EntIndexToEntRef(iObj);
	//PrintToChatAll("iObj %i", iObj);
	
	if (IsValidClient(iBuilder) && IsRobot(iBuilder, ROBOT_NAME)){

	// 	SetVariantInt(0);
    // AcceptEntityInput(iObj, "SolidToPlayer");
		// SetEntProp(iObj, Prop_Send, "m_iHighestUpgradeLevel", 3);
		// SetEntProp(iObj, Prop_Send, "m_iUpgradeLevel", 3);
		if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter){
		SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.65);
		SetEntPropFloat(iObj, Prop_Send, "m_flPercentageConstructed", 1.0);
		DispatchKeyValue(iObj, "defaultupgrade", "2"); 
	
		}

		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser)
		{
			//PrintToChatAll("Playing Music");
			EmitSoundToAll(MUSIC, iObj);
			EmitSoundToAll(MUSIC, iObj);
			EmitSoundToAll(MUSIC, iObj);
			EmitSoundToAll(MUSIC, iObj);
		}

		// SetVariantInt(2);
		// AcceptEntityInput(iObj, "SetSolidToPlayer");
		//FakeClientCommandEx(iBuilder, "stuck");

	}
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



public void ObjectCarry(Event event, const char[] name, bool dontBroadcast)
{
	// if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)
	// return;
	
	
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	//int entRef = EntIndexToEntRef(iObj);
	//PrintToChatAll("iObj %i", iObj);
	
	if (IsValidClient(iBuilder) && IsRobot(iBuilder, ROBOT_NAME)){
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
		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser)
			{
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			//PrintToChatAll("Attempting music stop");
		}
	}
}

/* public Action:CH_PassFilter( ent1, ent2, &bool:result )
{
	PrintToChatAll("Should stop");
			result = false;
			return Plugin_Stop;

}  */

/* public bool:ShouldCollide( entity, collisiongroup, contentsmask, bool:result )
{
	PrintToChatAll("Should not collide");
    return false;
}  */

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");



		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		
		
	}
}
// public Action Dane(int client, int args)
// {
// 	// TF2_SetPlayerClass(client, TFClass_Engineer);
//     // TF2_RegeneratePlayer(client);
// 	MakeUncleDane(client);
// }

MakeUncleDane(client)
{
	
	TF2_SetPlayerClass(client, TFClass_Engineer);
	TF2_RegeneratePlayer(client);

	EngieTeam = GetClientTeam(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 2)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 2);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, ChangeDane);

	int iHealth = 1250;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;
	float OverHealRate = 1.5;

	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;
	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	float scale = 1.65;
	
	TF2_SetHealth(client, iHealth);
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.6);
	TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "maxammo metal increased", 2.5);
	TF2Attrib_SetByName(client, "metal regen", 150.0);
	TF2Attrib_SetByName(client, "building cost reduction", 2.5);
	TF2Attrib_SetByName(client, "mod teleporter cost", 4.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client, "Widowmaker deals 250 precent damage to your sentry's target\nYou build lvl 3 in one swing\nYou have teamporters");
	PrintCenterText(client, "Use !stuck if you get stuck in buildings");
	
	SetEntProp(client, Prop_Send, "m_iAmmo", 500, _, 3);

//	EmitGameSoundToAll("Announcer.MVM_Engineer_Teleporter_Activated");
//Doesn't work for whatever reason
	///EmitGameSoundToAll("Announcer.MVM_First_Engineer_Teleport_Spawned");

	
	if (IsPlayerAlive(client) && !g_Announcerquiet)
	{
		// StopSound(client, SNDCHAN_AUTO, ENGIE_SPAWN_SOUND);
		// StopSound(client, SNDCHAN_AUTO, ENGIE_SPAWN_SOUND2);
		int soundswitch = GetRandomInt(1, 2);
		switch(soundswitch)
		{
			case 1:
			{
				EmitSoundToAll(ENGIE_SPAWN_SOUND);
			}
			case 2:
			{
				EmitSoundToAll(ENGIE_SPAWN_SOUND2);
			}
		}
		g_Announcerquiet = true;
		CreateTimer(10.0, Spawn_Clamp, client);
	}


	
}

public Action Spawn_Clamp(Handle timer, any client)
{
	g_Announcerquiet = false;
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveBigRoboDane(client);
}

// public Action:Timer_Resize(Handle:timer, any:hat)
// {
	// if (IsValidClient(client))
	// GiveBigRoboDane(client);
// }

#define THEDANGER 30420
#define GOLDDIGGER 30172
#define INSULATOR 30539

stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_shotgun_primary", 527, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_wrench", 197, 9, 1, 2, 0);


		//CreateWeapon(client, "tf_weapon_wrench", 7, 9, 69, 2, 0);


		CreateRoboHat(client, THEDANGER, 10, 6, 15132390.0, 1.25, -1.0);
		CreateRoboHat(client, GOLDDIGGER, 10, 6, 15132390.0, 1.0, -1.0);
		CreateRoboHat(client, INSULATOR, 10, 6, 15132390.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		//SetEntData(Weapon3, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);

		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			//TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.7);
			TF2Attrib_SetByName(Weapon1, "damage bonus", 1.25);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "mod ammo per shot", 30.0);
			TF2Attrib_SetByName(Weapon1, "engineer building teleporting pickup", 10.0);
			TF2Attrib_SetByName(Weapon1, "damage bonus bullet vs sentry target", 2.5);
			
		}
		if(IsValidEntity(Weapon3))
		{
			//TF2Attrib_RemoveAll(Weapon3);
			// TF2Attrib_SetByName(Weapon1, "is australium item", 1.0);
			// TF2Attrib_SetByName(Weapon1, "item style override", 1.0);
			//TF2Attrib_SetByName(Weapon3, "fire rate bonus", 1.0);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 2.0);
			TF2Attrib_SetByName(Weapon3, "Construction rate increased", 10.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.65);
			TF2Attrib_SetByName(Weapon3, "Repair rate increased", 4.0);
			TF2Attrib_SetByName(Weapon3, "single wep deploy time increased", 1.6);
			TF2Attrib_SetByName(Weapon3, "engineer building teleporting pickup", 10.0);
			TF2Attrib_SetByName(Weapon3, "engy building health bonus", 2.32);
			TF2Attrib_SetByName(Weapon3, "engy dispenser radius increased", 6.0);
			TF2CustAttr_SetString(Weapon3, "mod building health", "teleporter=500");
		}
		
	}
}

stock DestroyBuildings(int client)
{
	decl String:strObjects[3][] = {"obj_sentrygun","obj_dispenser","obj_teleporter"};
	
	int owner = -1; 
	
	for(int o = 0; o < sizeof(strObjects); o++)
	{
		int iEnt = -1;
		while((iEnt = FindEntityByClassname(iEnt, strObjects[o])) != -1)
			if(IsValidEntity(iEnt) && GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == EngieTeam)
			{
				//owner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
				owner = GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder");				
				
				if (client == -1 || owner == client)
				{	
					//PrintToServer("[REX] Destroyed object %i, owner - %N", iEnt, owner);
					SetEntityHealth(iEnt, 100);
					SetVariantInt(1488);
					AcceptEntityInput(iEnt, "RemoveHealth");
				}
			}
	}
}
public Action DeleteTrigger(Handle timer, any Ent)
{
	if (!IsValidEntity(Ent)) return;
	char cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "trigger_push", false)) AcceptEntityInput(Ent, "Kill");
	return;
}

// public Action CommandListener_Build(client, const char[] command, argc)
// {
// 	char sObjectMode[256], sObjectType[256];
// 	GetCmdArg(1, sObjectType, sizeof(sObjectType));
// 	GetCmdArg(2, sObjectMode, sizeof(sObjectMode));
// 	int iObjectMode = StringToInt(sObjectMode);
// 	int iObjectType = StringToInt(sObjectType);
// 	//char sClassName[32];
// 	// PrintToChat(client,"Object type: %i", iObjectType);
// 	// PrintToChat(client,"Object mode: %i", iObjectMode);
// 	// for(int i = MaxClients + 1; i < g_iMaxEntities; i++)
// 	// {
// 	// 	PrintToChatAll("Client: %i", i);
// 	// 	if(!IsValidEntity(i)) continue;
		
// 	// 	GetEntityNetClass(i, sClassName, sizeof(sClassName));
// 		if(IsRobot(client, ROBOT_NAME) && iObjectType == TF_OBJECT_TELEPORTER && iObjectMode == TF_TELEPORTER_ENTR)
// 		{
// 			PrintCenterText(client,"You can't build enterance, you can only build a exit teleporter!");
// 			PrintToChat(client,"You can't build enterance , you can only build a exit teleporter!");
// 			return Plugin_Handled;
// 		}
// 	// }
// 	return Plugin_Continue;
// }

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
	
		

	if (TF2_GetBuildingState(iPad) > TELEPORTER_STATE_BUILDING && TF2_GetBuildingState(iPad) < TELEPORTER_STATE_UPGRADING)
	{
		if (TF2_GetBuildingState(iPad) != TELEPORTER_STATE_READY)/*  && GetEntPropFloat(iPad, Prop_Send, "m_flRechargeTime") <= GetGameTime() */
		{
			//AcceptEntityInput(iPad, "Start");
			TF2_SetBuildingState(iPad, TELEPORTER_STATE_READY);	//Make sure the Pad always re-activates when it's supposed to.
			
		//	AcceptEntityInput(iObjParti, "Start");
			// #if defined DEBUG
			// PrintToChatAll("%i Ready!", iPad);
			// #endif
		}
		// if (TF2_GetBuildingState(iPad) == TELEPORTER_STATE_READY && IsValidEntity(iObjParti) && !bSapped)
		// {
		// 	AcceptEntityInput(iObjParti, "Start");
		// }
			
	}
	SetEntPropFloat(iPad, Prop_Send, "m_flCurrentRechargeDuration", 1.0);
	SetEntPropFloat(iPad, Prop_Send, "m_flYawToExit", GetEntPropFloat(iPad, Prop_Send, "m_flYawToExit") + 10.0);	//Make the arrow spin for fun, and to indicate its not a Teleporter (but mostly for fun)
	if (GetEntPropFloat(iPad, Prop_Send, "m_flYawToExit") > 360.0){
		SetEntPropFloat(iPad, Prop_Send, "m_flYawToExit", 0.0);
	}

		
}
stock int FindEntityByClassname2(int startEnt, char[] classname)
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
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
	//	PrintToChatAll("Setting state to %i", iState);
	}
}

// stock void TF2_DisableObject(int iObj)
// {
// 	if (IsValidEntity(iObj))
// 	{
// 		AcceptEntityInput(iObj, "Disable");
// 	}
// }

// stock void TF2_EnableObject(int iObj)
// {
// 	if (IsValidEntity(iObj))
// 	{
// 		AcceptEntityInput(iObj, "Enable");
// 	}
// }