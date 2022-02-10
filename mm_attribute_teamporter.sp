#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
#include <sdktools>
//#include <collisionhook>

#pragma semicolon 1
//#pragma newdecls required
#define PLUGIN_VERSION "1.0"

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
//#define DEBUG
//new g_offsCollisionGroup;

bool engibotactive;
bool teleportercheck;
bool AnnouncerQuiet;

bool g_Teleported[MAXPLAYERS + 1];

int EngieTeam = 2;
int engieid = -1;
int g_iMaxEntities;
int BossTeleporter;

float vecSpawns[2][3];

static int g_iPadType[2048];
static int g_iObjectParticle[2048];

static char g_szOffsetStartProp[64];
static int g_iOffsetMatchingTeleporter = -1;

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

public Plugin:myinfo =
{
	name = "[Manned Machines] Teamporter attribute",
	author = "HiGPS",
	description = "Adds Teamporter functionality for robots",
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
	
	CloseHandle(hGameConf);

	AddCommandListener(CommandListener_Build, "build");
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

	PrecacheSound(TELEPORTER_ACTIVATE1, true);
	PrecacheSound(TELEPORTER_ACTIVATE2, true);
	PrecacheSound(TELEPORTER_ACTIVATE3, true);
	PrecacheSound(TELEPORTER_ACTIVATE4, true);
	PrecacheSound(TELEPORTER_ACTIVATE5, true);
	PrecacheSound(TELEPORTER_SPAWN, true);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

public OnMapStart()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{

	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	
	if (IsValidClient(iBuilder) && IsAnyRobot(iBuilder)){

			#if defined DEBUG
			PrintToChatAll("Found robot builder!");
			#endif
		
		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Teleporter){
		
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
						TE_Particle("teleported_mvm_bot", position, _, _, attach, 1,0);	
						//TE_Particle("teleporter_mvm_bot_persist", position, _, _, attach, 1,0);	

						g_iPadType[iObj] = PadType_Boss;
						

						#if defined DEBUG
			PrintToChatAll("SetPadtype to %i", g_iPadType[iObj]);
			#endif
						//Doesn't work for some reason
						//EmitGameSoundToAll("Announcer.MVM_Engineer_Teleporter_Activated"); 
						
						int soundswitch = GetRandomInt(1,5);

						switch(soundswitch)
						{
							case 1:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE1);
							}
							case 2:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE2);
							}
							case 3:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE3);
							}
							case 4:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE4);
							}
							case 5:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE5);
							}
						}
		}
	}
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

stock void TF2_SetMatchingTeleporter(int iTele, int iMatch)	//Set the matching teleporter entity of a given Teleporter
{

	if (IsValidEntity(iTele) && HasEntProp(iTele, Prop_Send, g_szOffsetStartProp))
	{
		//PrintToChatAll("Matching telepoters");
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
	//PrintToChatAll("iObj %i", iObj);
	
	if (IsValidClient(iBuilder) && IsAnyRobot(iBuilder)){
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

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_Teleported[client]){
		return Plugin_Continue;
	}
	#if defined DEBUG
	PrintToChatAll("%N spawned", client);
	#endif 
	if (!IsAnyRobot(client))
	{
		#if defined DEBUG
		PrintToChatAll("%N spawned and was not a robot", client);
		#endif
		return Plugin_Continue;
	}
	
	int team = GetClientTeam(client);

	// if (team != EngieTeam)
	// 	return Plugin_Continue;

	int ent = -1;
	int i = (team == 2 ? 1 : 0);
	float vecSpawn[3];
	float vecIsActuallyGoingToSpawn[3] = {-99999.0, -99999.0, -99999.0};
	float dist, otherdist = GetVectorDistance(vecIsActuallyGoingToSpawn, vecSpawns[i]);
	float vecRotation[3];

	while ((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != team)
			continue;
		if (GetEntProp(ent, Prop_Send, "m_bBuilding"))	// If being built
			continue;
		if (GetEntProp(ent, Prop_Send, "m_bCarried"))	// If being carried
			continue;
		if (GetEntProp(ent, Prop_Send, "m_iObjectMode") != 1)	// If not exit
			continue;
		if (GetEntProp(ent, Prop_Send, "m_bHasSapper"))//has sapper
			continue;

		 //check if the padtype is a poss
			
		// if (!IsValidEntity(GetEntDataEnt2(ent, FindSendPropInfo("CObjectTeleporter", "m_bMatchBuilding")+4)))	// Props to Pelipoika
		// 	continue;

		if (g_iPadType[ent] != PadType_Boss)
			continue;


		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecSpawn);
		dist = GetVectorDistance(vecSpawn, vecSpawns[i]);
		if (dist < otherdist)
		{
			otherdist = dist;
			vecIsActuallyGoingToSpawn = vecSpawn;
			GetEntPropVector(ent, Prop_Send, "m_angRotation", vecRotation);	// Force players to look in the direction of teleporter on spawn
		}
	}
	// If no teleporters found
	if (GetVectorDistance(vecIsActuallyGoingToSpawn, vecSpawns[i]) >= 70000){
			#if defined DEBUG
			PrintToChatAll("No teleporters found!");
			#endif
		return Plugin_Continue;
	}	
		

	vecIsActuallyGoingToSpawn[2] += 15.0;
		// Don't get stuck inside of teleporter
						#if defined DEBUG
			PrintToChatAll("%N was teleported", client);
			#endif
	
	TeleportEntity(client, vecIsActuallyGoingToSpawn, vecRotation, NULL_VECTOR);
	EmitSoundToAll(TELEPORTER_SPAWN, client, _,_,_, 0.3);
	CreateTimer(0.5, Teleport_Clamp, client);
	g_Teleported[client] = true;
	float oober = 3.0;
	if (oober != 0.0)
	TF2_AddCondition(client, TFCond_Ubercharged, oober);
	return Plugin_Continue;
}



public Action Teleport_Clamp(Handle timer, int client)
{

	g_Teleported[client] = false;
}


stock TE_Particle(char[] Name, float origin[3] = NULL_VECTOR, float start[3] = NULL_VECTOR, float angles[3] = NULL_VECTOR, entindex=-1, attachtype=-1, attachpoint=-1, bool resetParticles=true, customcolors = 0, float color1[3] = NULL_VECTOR, float color2[3] = NULL_VECTOR, controlpoint = -1, controlpointattachment = -1, float controlpointoffset[3] = NULL_VECTOR)
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
		PrintCenterText(client,"You can't build enterance, you can only build a exit teleporter!");
		PrintToChat(client,"You can't build enterance , you can only build a exit teleporter!");
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
	if (IsValidEntity(iBuilding) && g_iPadType[iBuilding] == PadType_Boss)
	{
	SetEntProp(iBuilding, Prop_Send, "m_iState", iState);
	//	PrintToChatAll("Setting state to %i", iState);
	}
}