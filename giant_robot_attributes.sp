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

//new g_offsCollisionGroup;

int EngieTeam = 2;
// int engieid = -1;
// int g_iMaxEntities;
// int BossTeleporter;

int OwnerOffset;
ConVar sm_dispenser_limit;
ConVar sm_sentry_limit;
//ConVar sm_instant_upgrade;

// float vecSpawns[2][3];

static int g_iPadType[2048];
//static int g_iObjectParticle[2048];

static char g_szOffsetStartProp[64];
static int g_iOffsetMatchingTeleporter = -1;

// bool g_Announcerquiet = false;

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
	name = "[TF2] Robot Building Attributes",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Attributes for buildings for Robot Engineers",
	version = PLUGIN_VERSION,
	url = "www.bmod.tf"
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

	//Multi sentry 
	OwnerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
	

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

public OnMapStart()
{

	//Multi Sentry Code
	sm_dispenser_limit = CreateConVar("sm_dispenser_limit", "1", "Self explanatory");
	sm_sentry_limit = CreateConVar("sm_sentry_limit", "1", "Self explanatory");

	RegConsoleCmd("sm_destroy_dispensers", Command_destroy_dispensers);
	RegConsoleCmd("sm_destroy_sentries", Command_destroy_sentries);
}



public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	int flags = GetEntProp(iObj, Prop_Data, "m_spawnflags");

	if (IsValidClient(iBuilder) && IsRobot(iBuilder, ROBOT_NAME)){

		
		SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.25);

		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Sentry)
		{

			SetEntProp(iObj, Prop_Data, "m_spawnflags", flags|1<<3);
		}
		
						
	
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
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");

	if (IsValidClient(iBuilder) && IsRobot(iBuilder, ROBOT_NAME)){

		if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.0);
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

	}
}

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

	int DispenserLimit = GetConVarInt(sm_sentry_limit);
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