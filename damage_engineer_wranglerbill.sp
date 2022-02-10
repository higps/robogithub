#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
#include <sdktools>
//#include <collisionhook>
#include <tf_custom_attributes>

#pragma semicolon 1
//#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Wrangler Bill"
#define ROBOT_ROLE "Damage"
#define ROBOT_DESCRIPTION " Wrangler, 3 Minisentries, Teamporter"

#define ChangeDane             "models/bots/engineer/bot_engineer.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"


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

int EngieTeam = 2;
// int engieid = -1;
// int g_iMaxEntities;
// int BossTeleporter;

int OwnerOffset;
ConVar sm_dispenser_limit;
ConVar sm_sentry_limit;
//ConVar sm_instant_upgrade;

float vecSpawns[2][3];

static int g_iPadType[2048];
//static int g_iObjectParticle[2048];

static char g_szOffsetStartProp[64];
static int g_iOffsetMatchingTeleporter = -1;

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

Handle g_hUpdateOnRemove;

public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Bot Slinger",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Bot Slinger Bot from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    //g_offsCollisionGroup = FindSendPropInfo("DT_BaseEntity", "m_CollisionGroup");
    HookEvent("player_builtobject", ObjectBuilt, EventHookMode_Post);
	HookEvent("player_carryobject", ObjectCarry, EventHookMode_Post);
//	HookEvent("player_upgradedobject", ObjectCarry, EventHookMode_Post);

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


	//Remove all sappers code
	hGameConf = LoadGameConfigFile("bm_sh_data");
	
	
	g_hUpdateOnRemove = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	
	if(!DHookSetFromConf(g_hUpdateOnRemove, hGameConf, SDKConf_Signature, "CBaseObject::UpdateOnRemove"))
	SetFailState("Failed to find CBaseObject::UpdateOnRemove signature in the gamedata!");
	
	if(!DHookEnableDetour(g_hUpdateOnRemove, false, UpdateOnRemove))
	SetFailState("Failed to enable CBaseObject::UpdateOnRemove detour!");
	
	CloseHandle(hGameConf);

	//HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);


	//AddCommandListener(CommandListener_Build, "build");
	

	//RegConsoleCmd("sm_dane", Dane, "become dane");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Engineer";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeBotSlinger, PLUGIN_VERSION);

    for(int client = 1 ; client <= MaxClients ; client++)
    {
        if(IsClientInGame(client))
        {
            //SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
            SDKHook(client, SDKHook_Touch, OnTouch);
        }
    }
	
	//Multi sentry 
	OwnerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
	

}


public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
/* public OnEntityCreated(entity, const String:classname[])
{
    if(StrContains(classname[1], "item_ammopack", false) != -1 || StrContains(classname[1], "item_healthkit", false) != -1)
    {
        SDKHook(entity,    SDKHook_StartTouch,     StartTouch);
        SDKHook(entity,    SDKHook_Touch,             OnTouch);
    }
} */

/* public Action OnTouch(int client, int ent)
{
	char entname[MAX_NAME_LENGTH];
	GetEntityClassname(ent, entname, sizeof(entname));
	
	if (!StrContains(entname, "item_ammo") || !StrContains(entname, "item_health")){
		//PrintToChatAll("Ent: %s", entname);
    	if(GetEntProp(ent, Prop_Data, "m_bDisabled") == 1)
        return;
	}

	
} */

public Action OnTouch(int client, int ent)
{

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeBotSlinger", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheModel(ChangeDane);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);

	PrecacheSound(ENGIE_SPAWN_SOUND, true);
	PrecacheSound(ENGIE_SPAWN_SOUND2, true);
	PrecacheSound(TELEPORTER_ACTIVATE1, true);
	PrecacheSound(TELEPORTER_ACTIVATE2, true);
	PrecacheSound(TELEPORTER_ACTIVATE3, true);
	PrecacheSound(TELEPORTER_ACTIVATE4, true);
	PrecacheSound(TELEPORTER_ACTIVATE5, true);
	PrecacheSound(TELEPORTER_SPAWN, true);

	//Multi Sentry Code

	sm_dispenser_limit = CreateConVar("sm_dispenser_limit", "1", "Self explanatory");
	sm_sentry_limit = CreateConVar("sm_sentry_limit", "3", "Self explanatory");
	//sm_instant_upgrade = CreateConVar("sm_instant_upgrade","0","Self explanatory");

	//HookEvent("player_builtobject",Evt_BuiltObject,EventHookMode_Pre);

	RegConsoleCmd("sm_destroy_dispensers", Command_destroy_dispensers);
	RegConsoleCmd("sm_destroy_sentries", Command_destroy_sentries);

	
}

/* public bool ShouldCollide(entity, collisiongroup, contentmask, bool result)
{	
	//PrintToChatAll("Returning false");
	return false;
}
 */
//trigger the event
// public void PlayerUpgradedobject(Event evnet, const char[] name, bool dontBroadcast)
// {
// //PrintToChatAll("Upgrade complete");
// }

public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	// if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)
	// return;
	
	
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	int flags = GetEntProp(iObj, Prop_Data, "m_spawnflags");
	//int entRef = EntIndexToEntRef(iObj);
	////PrintToChatAll("iObj %i", iObj);
	
	if (IsValidClient(iBuilder) && IsRobot(iBuilder, ROBOT_NAME)){
		// SetEntProp(iObj, Prop_Send, "m_iHighestUpgradeLevel", 3);
		// SetEntProp(iObj, Prop_Send, "m_iUpgradeLevel", 3);
		
		SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.25);
		SetEntPropFloat(iObj, Prop_Send, "m_flPercentageConstructed", 1.0);
				
		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser)
		{
			////PrintToChatAll("Buildt dispenser");
			DispatchKeyValue(iObj, "defaultupgrade", "2"); 
		}

		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Sentry)
		{
			////PrintToChatAll("Buildt dispenser");
			//SetEntProp(iObj, Prop_Send, "m_iAmmoShells", 10000);
			
			SetEntProp(iObj, Prop_Data, "m_spawnflags", flags|1<<3);
			//DispatchKeyValue(iObj, "defaultupgrade", "2"); 
		}
		
		
		// if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Teleporter){
						
		// 				SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.0);
		// 				SetEntProp(iObj, Prop_Send, "m_iHighestUpgradeLevel", 3);	//Set Pads to level 3 for cosmetic reasons related to recharging
		// 				SetEntProp(iObj, Prop_Send, "m_iUpgradeLevel", 3);
		// 				SetEntProp(iObj, Prop_Send, "m_bMiniBuilding", true);
						
		// 				 //Setting m_bMiniBuilding tries to set the skin to a 'mini' skin. Since teles don't have one, reset the skin.
		// 				SetEntProp(iObj, Prop_Send, "m_iTimesUsed", 0);
		// 				RequestFrame(ResetSkin, iObj);
		// 				TF2_SetMatchingTeleporter(iObj, iObj);

		// 				//Set teleporter to itself - does not work yet

		// 				// int iObjParti = CreatePadParticle(iObj, "teleporter_mvm_bot_persist");
		// 				// g_iObjectParticle[iObj] = EntIndexToEntRef(iObjParti);
		// 				//AcceptEntityInput(iObjParti, "Start");

		// 				SetVariantInt(RoundFloat(500.0));
		// 				AcceptEntityInput(iObj, "AddHealth", iObj); //Spawns at 50% HP.
		// 				SetEntProp(iObj, Prop_Send, "m_iTimesUsed", 0);


		// 				float position[3];
		// 				GetEntPropVector(iObj, Prop_Data, "m_vecOrigin", position);	
		// 				int attach = CreateEntityByName("trigger_push");
		// 				TeleportEntity(attach, position, NULL_VECTOR, NULL_VECTOR);
		// 				TE_Particle("teleported_mvm_bot", position, _, _, attach, 1,0);	
		// 				//TE_Particle("teleporter_mvm_bot_persist", position, _, _, attach, 1,0);	
		// 				int soundswitch = GetRandomInt(1, 5);
						
		// 				g_iPadType[iObj] = PadType_Boss;

		// 				switch(soundswitch)
		// 				{
		// 					case 1:
		// 					{
		// 						EmitSoundToAll(TELEPORTER_ACTIVATE1);
		// 					}
		// 					case 2:
		// 					{
		// 						EmitSoundToAll(TELEPORTER_ACTIVATE2);
		// 					}
		// 					case 3:
		// 					{
		// 						EmitSoundToAll(TELEPORTER_ACTIVATE3);
		// 					}
		// 					case 4:
		// 					{
		// 						EmitSoundToAll(TELEPORTER_ACTIVATE4);
		// 					}
		// 					case 5:
		// 					{
		// 						EmitSoundToAll(TELEPORTER_ACTIVATE5);
		// 					}
		// 				}
		// }
		//SetEntProp(iObj, Prop_Send, "m_CollisionGroup", 2); 
		//SetEntPropFloat(iObj, Prop_Send, "m_bDisposableBuilding", 1.0);	
		
		//SetEntPropFloat(iObj, Prop_Send, "m_iUpgradeMetalRequired ", 0.1);
		//SDKHook(iObj, SDKHook_ShouldCollide, ShouldCollide );
		//CH_PassFilter(iBuilder, iObj, false);
		//SetEntData(iObj, g_offsCollisionGroup, 2, 4, false);
						
	
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

stock void TF2_SetMatchingTeleporter(int iTele, int iMatch)	//Set the matching teleporter entity of a given Teleporter
{

	if (IsValidEntity(iTele) && HasEntProp(iTele, Prop_Send, g_szOffsetStartProp))
	{
		////PrintToChatAll("Matching telepoters");
		int iOffs = FindSendPropInfo("CObjectTeleporter", g_szOffsetStartProp) + g_iOffsetMatchingTeleporter;
		SetEntDataEnt2(iTele, iOffs, iMatch, true);
	}
	
}

public void ObjectCarry(Event event, const char[] name, bool dontBroadcast)
{
	// if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)
	// return;
	
	
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	//int entRef = EntIndexToEntRef(iObj);
	////PrintToChatAll("iObj %i", iObj);
	
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
	
	}
}

/* public Action:CH_PassFilter( ent1, ent2, &bool:result )
{
	//PrintToChatAll("Should stop");
			result = false;
			return Plugin_Stop;

}  */

/* public bool:ShouldCollide( entity, collisiongroup, contentsmask, bool:result )
{
	//PrintToChatAll("Should not collide");
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

MakeBotSlinger(client)
{
	
	TF2_SetPlayerClass(client, TFClass_Engineer);
	TF2_RegeneratePlayer(client);

	SDKUnhook(client, SDKHook_WeaponSwitch, WeaponSwitch);
	SDKHookEx(client, SDKHook_WeaponSwitch, WeaponSwitch);

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
	int MaxHealth = 150;
	int iAdditiveHP = iHealth - MaxHealth;

	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.65);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.6);
	TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "maxammo metal increased", 2.5);
	TF2Attrib_SetByName(client, "metal regen", 150.0);
	TF2Attrib_SetByName(client, "building cost reduction", 2.5);
	TF2Attrib_SetByName(client, "mod teleporter cost", 4.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	SetEntProp(client, Prop_Send, "m_iAmmo", 500, _, 3);

	
	//TF2CustAttr_SetString(Weapon3, "shake on hit", "amplitude=20.0 frequency=5.0 duration=1.0");
	
	UpdatePlayerHitbox(client, 1.65);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , "Use build menu to build up to 3 sentries!\nRemove all sappers at once");
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

#define CUTESUIT 30367
#define ANTLERS 993
#define MARXMAN 816

stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_laser_pointer", 30668, 6, 1, 1, 0);
		CreateRoboWeapon(client, "tf_weapon_robot_arm", 142, 6, 1, 2, 0);

 		CreateRoboHat(client, CUTESUIT, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, ANTLERS, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, MARXMAN, 10, 6, 0.0, 1.0, -1.0);

		// CreateHat(client, 993, 10, 6, 0.0); //Cute suit
		// CreateHat(client, 816, 10, 6, 0.0); //Cute suit
		// CreateHat(client, 30367, 10, 6, 0.0); //Cute suit
		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
			TF2Attrib_SetByName(Weapon3, "fire rate bonus", 0.85);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.5);
			TF2Attrib_SetByName(Weapon3, "Construction rate increased", 10.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.65);
			TF2Attrib_SetByName(Weapon3, "Repair rate increased", 4.0);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.75);
			TF2Attrib_SetByName(Weapon3, "engineer building teleporting pickup", 10.0);
			TF2Attrib_SetByName(Weapon3, "engy building health bonus", 2.32);
			TF2Attrib_SetByName(Weapon3, "engy dispenser radius increased", 6.0);
			TF2CustAttr_SetString(Weapon3, "mod building health", "teleporter=500");
			TF2Attrib_SetByName(Weapon3, "engy sentry fire rate increased", 0.8);
			
			
		}
	
		//CreateTimer(0.4, Particle_Teleporter);
		
		
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
// 	// 	//PrintToChatAll("Client: %i", i);
// 	// 	if(!IsValidEntity(i)) continue;
		
// 	// 	GetEntityNetClass(i, sClassName, sizeof(sClassName));
// 	if(IsRobot(client, ROBOT_NAME) && iObjectType == TF_OBJECT_TELEPORTER && iObjectMode == TF_TELEPORTER_ENTR)
// 	{
// 		PrintCenterText(client,"You can't build enterance, you can only build a exit teleporter!");
// 		PrintToChat(client,"You can't build enterance , you can only build a exit teleporter!");
// 		return Plugin_Handled;
// 	}

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
	////PrintToChatAll("THINKING1!");
	int i = -1;
	while ((i = FindEntityByClassname2(i, "obj_teleporter")) != -1)
	{
		if (IsValidEntity(i))
		{
			if (g_iPadType[i] == PadType_Boss){
				////PrintToChatAll("THINKING!");
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
	
	////PrintToChatAll("Teleporter state: %i", TF2_GetBuildingState(iPad));

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
		//	//PrintToChatAll("Sapped");
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
			// //PrintToChatAll("%i Ready!", iPad);
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
	//	//PrintToChatAll("Setting state to %i", iState);
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
// }public void OnClientPostAdminCheck(client){

///============MULTIPLE SENTRIES CODE//////

// public Action Evt_BuiltObject(Event event, const char[] name, bool dontBroadcast){
// 	int ObjIndex = event .GetInt("index");

// 	if(GetConVarInt(sm_instant_upgrade)>0){
// 		SetEntProp(ObjIndex, Prop_Send, "m_iUpgradeMetal", 600);
// 		SetEntProp(ObjIndex,Prop_Send,"m_iUpgradeMetalRequired",0);
// 	}
// 	return Plugin_Continue;
// }


public Action WeaponSwitch(client, weapon){
	//Safety Checks
	if(IsRobot(client, ROBOT_NAME))
	{

	if(!IsClientInGame(client)){
		return Plugin_Continue;
	}
	if(TF2_GetPlayerClass(client)!=TFClass_Engineer){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,1))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,3))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(GetPlayerWeaponSlot(client,4))){
		return Plugin_Continue;
	}
	if(!IsValidEntity(weapon)){
		return Plugin_Continue;
	}

	//if the building pda is opened
	//Switches some buildings to sappers so the game doesn't count them as engie buildings
//	//PrintToChatAll("Switching weapons");
	if(GetPlayerWeaponSlot(client,3)==weapon){
//		//PrintToChatAll("Running Function Allow Building");
		function_AllowBuilding(client);
		return Plugin_Continue;
	}//else if the client is not holding the building tool
	else if(GetEntProp(weapon,Prop_Send,"m_iItemDefinitionIndex")!=28){
		function_AllowDestroying(client);
		return Plugin_Continue;
	}
	}
	return Plugin_Continue;

}

public Action Command_destroy_dispensers(int client, int args){

	for(int i=1;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if (!strcmp(netclass, "CObjectDispenser") == 0){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}
		SetVariantInt(9999);
		AcceptEntityInput(i,"RemoveHealth");
	}

	return Plugin_Handled;


}

public Action Command_destroy_sentries(int client, int args){

	for(int i=1;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if ( !(strcmp(netclass, "CObjectSentrygun") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}
		SetVariantInt(9999);
		AcceptEntityInput(i,"RemoveHealth");
	}

	return Plugin_Handled;

}

public void function_AllowBuilding(int client){

	int DispenserLimit = GetConVarInt(sm_dispenser_limit);
	int SentryLimit = GetConVarInt(sm_sentry_limit);

	int DispenserCount = 0;
	int SentryCount = 0;
	// if(IsRobot(client, ROBOT_NAME))
	// {
	for(int i=0;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset) != client && IsRobot(client, ROBOT_NAME)){
			continue;
		}


		int type=view_as<int>(function_GetBuildingType(i));

		//Switching the dispenser to a sapper type
		if(type==view_as<int>(TFObject_Dispenser)){
			DispenserCount=DispenserCount+1;
			SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);
			if(DispenserCount>=DispenserLimit){
				//if the limit is reached, disallow building
				SetEntProp(i, Prop_Send, "m_iObjectType", type);

			}

		//not a dispenser,
		}else if(type==view_as<int>(TFObject_Sentry)){
			SentryCount++;
		//	//PrintToChatAll("Sentry count is %i", SentryCount);
			SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);
			if(SentryCount>=SentryLimit){
				//if the limit is reached, disallow building
				SetEntProp(i, Prop_Send, "m_iObjectType", type);
			}
		}
	//every building is in the desired state

	}
	

}
public void function_AllowDestroying(int client){
	for(int i=1;i<2048;i++){

		if(!IsValidEntity(i)){
			continue;
		}

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
			continue;
		}

		if(GetEntDataEnt2(i, OwnerOffset)!=client){
			continue;
		}

		SetEntProp(i, Prop_Send, "m_iObjectType", function_GetBuildingType(i));
	}

}

public TFObjectType function_GetBuildingType(int entIndex){
	//This function relies on Netclass rather than building type since building type
	//gets changed
	decl String:netclass[32];
	GetEntityNetClass(entIndex, netclass, sizeof(netclass));

	if(strcmp(netclass, "CObjectSentrygun") == 0){
		return TFObject_Sentry;
	}
	if(strcmp(netclass, "CObjectDispenser") == 0){
		return TFObject_Dispenser;
	}
	return TFObject_Sapper;
}

public MRESReturn UpdateOnRemove(int pThis)
{
	int iObjectType = GetEntProp(pThis, Prop_Send, "m_iObjectType");
	//int user = GetClientUserId(pThis);
	////PrintToChatAll("Removed sapper %i", iObjectType);
	int iBuiltOnEntity;
	int iBuilderClient;
//	int iObjectTypeBOE;
	
	switch(iObjectType)
	{
		case TFObject_Sapper:
		{
			iBuiltOnEntity = GetEntPropEnt(pThis, Prop_Send, "m_hBuiltOnEntity");
			if(iBuiltOnEntity == -1) return MRES_Ignored;
			
			iBuilderClient = GetEntPropEnt(iBuiltOnEntity, Prop_Send, "m_hBuilder");

			if(IsRobot(iBuilderClient, ROBOT_NAME))
			{
				new ent = -1;	//Check all buildings owned by robot and remove sappers
				while ((ent = FindEntityByClassname(ent, "obj_attachment_sapper")) != -1)
				{
					//PrintToChatAll("Looking for sappers!");

					// int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
					// if (IsValidClient(iBuilder))
					// {
					// 	//PrintToChatAll("iBulder %N", iBuilder);	
					// // }
					if (IsValidEntity(ent))
					{
						
						int uBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuiltOnEntity");
						int uBuilderClient;
						////PrintToChatAll("iBulder %N", uBuilder);	
						if(uBuilder != -1)
						{
							uBuilderClient = GetEntPropEnt(uBuilder, Prop_Send, "m_hBuilder");
						
							if (IsRobot(uBuilderClient, ROBOT_NAME))
								{

									//PrintToChatAll("Removing sappers for %N, ent was: %i", uBuilderClient, ent);
									
									//SetVariantInt(999);
        							RequestFrame(DetonateObject, ent);
									//DetonateObject(ent);
									
								}
						}
					}
				}
				}
		}
	////PrintToChatAll("Remove Sapper: %i, OT: %i", pThis, GetEntProp(pThis, Prop_Send, "m_iObjectType"));
	////PrintToChatAll("Built on: %i", GetEntPropEnt(pThis, Prop_Send, "m_hBuiltOnEntity"));
	//return MRES_Ignored;
	}
	return MRES_Ignored;
}

void DetonateObject(any iObj) {
    if (IsValidEntity(iObj)) {
        // SetVariantInt(1);
        // AcceptEntityInput(iObj, "SetHealth");
        SetVariantInt(999);
        AcceptEntityInput(iObj, "RemoveHealth");
    }
}