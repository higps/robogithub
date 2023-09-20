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
#include <stocksoup/var_strings>
//Includes for throw code
#include <smlib>
#include <vphysics>
#include <tf2utils>
#tryinclude <tf2hudmsg>

// #include <smmem>
// #include <sourcescramble>

#pragma semicolon 1
//#pragma newdecls required

#define PLUGIN_VERSION "1.0"
//new g_offsCollisionGroup;

int EngieTeam = 2;
// int engieid = -1;
// int g_iMaxEntities;
// int BossTeleporter;

int OwnerOffset;
// ConVar sm_dispenser_limit;
// ConVar sm_sentry_limit;
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

//THROW CODE VARIABLES

#define MASK_BUILDINGS MASK_PLAYERSOLID_BRUSHONLY

enum {
	BUILDING_INVALID_OBJECT = ((1<<8)-1), // s8_t:-1
	BUILDING_DISPENSER = 0,
	BUILDING_TELEPORTER,
	BUILDING_SENTRYGUN,
	BUILDING_ATTACHMENT_SAPPER,
}
enum {
	BS_IDLE,
	BS_SELECTING,
	BS_PLACING,
	BS_PLACING_INVALID,
};

enum struct AirbornData {
	int physObject;
	int building;
	int upright;
	float yaw;
	bool newBuild;
	float prevPos[3];
}

bool g_bPlayerThrow[MAXPLAYERS+1];
Handle sdk_fnStartBuilding;
//Handle sdk_fnIsPlacementPosValid;
ArrayList g_aAirbornObjects;
float g_flClientLastBeep[MAXPLAYERS+1];
float g_flClientLastNotif[MAXPLAYERS+1]; //for hud notifs, as those make noise

#define TBLOCK_WFP (1<<0)
int g_iBlockFlags;
#define TBFLAG_DISPENSER (1<<BUILDING_DISPENSER)
#define TBFLAG_TELEPORTER (1<<BUILDING_TELEPORTER)
#define TBFLAG_SENTRYGUN (1<<BUILDING_SENTRYGUN)
int g_iAllowTypes;
int g_iNoOOBTypes;
float g_flThrowForce;
float g_flUprightForce;
int g_iBuildingModelIndexLV1[3];

GlobalForward g_fwdToss, g_fwdTossPost, g_fwdLanded;

bool g_bDepHudMsg; //for fancy messages

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
	
	//Throw Code
		GameData data = new GameData("tbobj.games");
	if (data == null)
		SetFailState("Could not load gamedata: File is missing");
	
	StartPrepSDKCall(SDKCall_Entity); //weapon
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "StartBuilding");
	if ((sdk_fnStartBuilding = EndPrepSDKCall())==null)
		SetFailState("Could not load gamedata: StartBuilding Signature missing or outdated");
	
//	StartPrepSDKCall(SDKCall_Entity); //building
//	PrepSDKCall_SetFromConf(data, SDKConf_Virtual, "IsPlacementPosValid");
//	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
//	if ((sdk_fnIsPlacementPosValid = EndPrepSDKCall())==null)
//		SetFailState("Could not load gamedata: IsPlacementPosValid Offset missing or outdated");
	
	delete data;
	
	ConVar cvarTypes = CreateConVar("sm_toss_building_types", "dispenser teleporter sentrygun", "Space separated list of building names that can be tossed: Dispenser Teleporter Sentrygun");
	ConVar cvarForce = CreateConVar("sm_toss_building_force", "520", "Base force to use when throwing buildings", _, true, 100.0, true, 10000.0);
	ConVar cvarUpright = CreateConVar("sm_toss_building_upright", "0", "How much to pull the prop upright in degree/sec. Will somethwat prevent the prop twriling, 0 to disable", _, true, 0.0, true, 3600.0);
	ConVar cvarOOB = CreateConVar("sm_toss_building_breakoob", "dispenser teleporter sentrygun", "Space separated list of building names that break out of bounds: Dispenser Teleporter Sentrygun");
	cvarTypes.AddChangeHook(OnTossBuildingTypesChanged);
	cvarForce.AddChangeHook(OnTossBuildingForceChanged);
	cvarUpright.AddChangeHook(OnTossBuildingUprightChanged);
	cvarOOB.AddChangeHook(OnTossBuildingOOBChanged);
	//always load values on startup
	char buffer[128];
	cvarTypes.GetString(buffer, sizeof(buffer));
	OnTossBuildingTypesChanged(cvarTypes, buffer, buffer);
	OnTossBuildingForceChanged(cvarForce, NULL_STRING, NULL_STRING);//doesn't use passed string
	OnTossBuildingUprightChanged(cvarUpright, NULL_STRING, NULL_STRING);//doesn't use passed string
	cvarOOB.GetString(buffer, sizeof(buffer));
	OnTossBuildingOOBChanged(cvarOOB, buffer, buffer);
	//load actual values from config
	AutoExecConfig();
	delete cvarTypes;
	delete cvarForce;
	delete cvarUpright;
	delete cvarOOB;
	
	ConVar cvarVersion = CreateConVar("sm_toss_building_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarVersion.AddChangeHook(LockConVar);
	cvarVersion.SetString(PLUGIN_VERSION);
	delete cvarVersion;
	
	HookEvent("player_carryobject", OnPlayerCarryObject);
	HookEvent("player_builtobject", OnPlayerBuiltObject);
	HookEvent("player_dropobject", OnPlayerBuiltObject);
	
	g_aAirbornObjects = new ArrayList(sizeof(AirbornData)); //phys parent, object, thrown angle (yaw)
	
	//let other plugins integrate :)
	g_fwdToss = CreateGlobalForward("TF2_OnTossBuilding", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_fwdTossPost = CreateGlobalForward("TF2_OnTossBuildingPost", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_fwdLanded = CreateGlobalForward("TF2_OnBuildingLanded", ET_Ignore, Param_Cell, Param_Cell);

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

int g_infinite_ammo;
// int g_SentryLimit;
// int g_DispenserLimit;
int g_yeet[MAXPLAYERS + 1] = {0,...};
float g_sentry_scale;
float g_dispenser_scale;
int g_upgradelevel_sentry;
int g_upgradelevel_dispenser;



bool HasStat(int client)
{
	// PrintToChatAll("%N had stat",client);
 	int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(Weapon3 == -1)
	{
		return false;
	}
	//PrintToChatAll("Checking has stat for %N", client);
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(Weapon3, "robot engineer", stat_buffer, sizeof(stat_buffer))) {
		//PrintToChatAll("Has Stat Not Found for %N", client);
		g_yeet[client] = 0;
		return false;
		
	}

	//PrintToChatAll("Has Stat Found for %N, setting variables", client);
	// g_SentryLimit = ReadIntVar(stat_buffer, "sentries", 1);
	g_sentry_scale = ReadFloatVar(stat_buffer, "sentry_scale", 0.0);
	// g_DispenserLimit = ReadIntVar(stat_buffer, "dispensers", 1);
	g_dispenser_scale = ReadFloatVar(stat_buffer, "dispenser_scale", 0.0);
	g_infinite_ammo = ReadIntVar(stat_buffer, "infinite_ammo", 0);
	g_upgradelevel_sentry = ReadIntVar(stat_buffer, "upgrade_level_sentry", -1);
	g_upgradelevel_dispenser = ReadIntVar(stat_buffer, "upgrade_level_dispenser", -1);
	g_yeet[client] = ReadIntVar(stat_buffer, "yeet", 0);

//PrintToChatAll("SG Limit: %i, SG Scale: %f, Disp Limit: %i, Disp Scale: %f, infinite ammo: %i, Yeet: %i for %N",g_SentryLimit, g_sentry_scale, g_DispenserLimit, g_dispenser_scale, g_infinite_ammo, g_yeet[owner], client);
// PrintToChatAll("Has Stat Found for %N, dispenser count was %i", client, g_DispenserLimit);

	// g_bmod_disciplinary = ReadIntVar(stat_buffer, "bmod-disciplinary", 0);
	return true;
}
// public OnMapStart()
// {

// 	//Multi Sentry Code
// 	// sm_dispenser_limit = CreateConVar("sm_dispenser_limit", "1", "Self explanatory");
// 	// sm_sentry_limit = CreateConVar("sm_sentry_limit", "1", "Self explanatory");

// 	// RegConsoleCmd("sm_destroy_dispensers", Command_destroy_dispensers);
// 	// RegConsoleCmd("sm_destroy_sentries", Command_destroy_sentries);
// }



public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));

	
	////PrintToChatAll("Buildt Object attribute! %N", iBuilder);



	if (IsValidClient(iBuilder) && HasStat(iBuilder)){



	// char stat_buffer[256];
	// if (!TF2CustAttr_GetString(iBuilder, "robot engineer", stat_buffer, sizeof(stat_buffer))) {
	// 	return;
		
	// }

		SDKUnhook(iBuilder, SDKHook_WeaponSwitch, WeaponSwitch);
		SDKHookEx(iBuilder, SDKHook_WeaponSwitch, WeaponSwitch);

		int iObj = event.GetInt("index");
		
		
		
		
		// int infinite_ammo = ReadIntVar(stat_buffer, "infinite_ammo", 0);
		

		
		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Sentry)
		{

			int flags = GetEntProp(iObj, Prop_Data, "m_spawnflags");

			if (g_sentry_scale > 0.0)
			{
			SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", g_sentry_scale);
			}

			if (g_infinite_ammo > 0)
			{
				SetEntProp(iObj, Prop_Data, "m_spawnflags", flags|1<<3);
			}

			if(g_upgradelevel_sentry != -1)
			{	
				SetEntProp(iObj, Prop_Send, "m_iHighestUpgradeLevel", g_upgradelevel_sentry);
				SetEntProp(iObj, Prop_Send, "m_iUpgradeLevel", g_upgradelevel_sentry-1);
				// SetEntPropFloat(iObj, Prop_Send, "m_flPercentageConstructed", 3.0);
				// DispatchKeyValue(iObj, "defaultupgrade", "2"); 
			}

		}

		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser)
		{
			if(g_upgradelevel_dispenser != -1)
			{	
				SetEntProp(iObj, Prop_Send, "m_iHighestUpgradeLevel", g_upgradelevel_dispenser);
				SetEntProp(iObj, Prop_Send, "m_iUpgradeLevel", g_upgradelevel_dispenser);
			}
			
		}
//Code for instant levels in case we need it in the future
			// 	SetVariantInt(0);
    // AcceptEntityInput(iObj, "SolidToPlayer");
		// SetEntProp(iObj, Prop_Send, "m_iHighestUpgradeLevel", 3);
		// SetEntProp(iObj, Prop_Send, "m_iUpgradeLevel", 3);
		// if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter){
		// SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.45);
		// SetEntPropFloat(iObj, Prop_Send, "m_flPercentageConstructed", 1.0);
		// DispatchKeyValue(iObj, "defaultupgrade", "2"); 

		if(view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser)
		{
			
			if (g_dispenser_scale > 0.0)
			{
			SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", g_dispenser_scale);
			}
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
		//////PrintToChatAll("Matching telepoters");
		int iOffs = FindSendPropInfo("CObjectTeleporter", g_szOffsetStartProp) + g_iOffsetMatchingTeleporter;
		SetEntDataEnt2(iTele, iOffs, iMatch, true);
	}
	
}

public void ObjectCarry(Event event, const char[] name, bool dontBroadcast)
{
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");

	if (IsValidClient(iBuilder) && HasStat(iBuilder))
	{

		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Sentry && g_sentry_scale > 0.0)
		{
			SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.0);
		}

		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser && g_dispenser_scale > 0.0)
		{
			SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.0);
		}

		// if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Teleporter && g_dispenser_scale > 0.0)
		// {
		// 	SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.0);
		// }
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
				//////PrintToChatAll("THINKING!");
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
	
	//////PrintToChatAll("Teleporter state: %i", TF2_GetBuildingState(iPad));

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
		//	////PrintToChatAll("Sapped");
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
			// ////PrintToChatAll("%i Ready!", iPad);
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
	if(HasStat(client))
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
//	////PrintToChatAll("Switching weapons");
	if(GetPlayerWeaponSlot(client,3)==weapon){
//		////PrintToChatAll("Running Function Allow Building");
		function_AllowBuilding(client);
		return Plugin_Continue;
	}//else if the client is not holding the building tool
	/* else if(GetEntProp(weapon,Prop_Send,"m_iItemDefinitionIndex")!=28){
		function_AllowDestroying(client);
		return Plugin_Continue;
	} */
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



	if (!HasStat(client)) {
		return;
	}
	// PrintToChatAll("%N has the stat, sentry limit is %i", client, g_SentryLimit);
	// int SentryLimit = g_SentryLimit;
	// int DispenserLimit = g_DispenserLimit;
	// int DispenserLimit = GetConVarInt(sm_sentry_limit);
	// int SentryLimit = GetConVarInt(sm_sentry_limit);
	// int DispenserCount = 0;
	// int SentryCount = 0;
	// if(IsRobot(client, ROBOT_NAME))
	// {
	// for(int i=0;i<2048;i++){

	// 	if(!IsValidEntity(i)){
	// 		continue;
	// 	}

	// 	decl String:netclass[32];
	// 	GetEntityNetClass(i, netclass, sizeof(netclass));
	// 	if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
	// 		continue;
	// 	}

	// 	if(GetEntDataEnt2(i, OwnerOffset) != client && HasStat(client)){
	// 		continue;
	// 	}


	// 	int type=view_as<int>(function_GetBuildingType(i));

	// 	//Switching the dispenser to a sapper type
	// 	if(type==view_as<int>(TFObject_Dispenser)){
	// 		DispenserCount=DispenserCount+1;
	// 		SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);
	// 		if(DispenserCount>=g_DispenserLimit){
	// 			//if the limit is reached, disallow building
	// 			SetEntProp(i, Prop_Send, "m_iObjectType", type);

	// 		}

	// 	//not a dispenser,
	// 	}else if(type==view_as<int>(TFObject_Sentry)){
	// 		SentryCount++;
	// 		PrintToChatAll("Sentry count is %i", SentryCount);
	// 		SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sapper);

	// 		if(SentryCount>=g_SentryLimit){
	// 			//if the limit is reached, disallow building
	// 			// PrintToChatAll("Sentry count reached for %N", client);
	// 			SetEntProp(i, Prop_Send, "m_iObjectType", type);
	// 		}else
	// 		{
	// 			SetEntProp(i, Prop_Send, "m_iObjectType", TFObject_Sentry);
	// 		}
	// 	}
	// }
}

// public void function_AllowDestroying(int client){
// 	for(int i=1;i<2048;i++){

// 		if(!IsValidEntity(i)){
// 			continue;
// 		}

// 		decl String:netclass[32];
// 		GetEntityNetClass(i, netclass, sizeof(netclass));

// 		if ( !(strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0) ){
// 			continue;
// 		}

// 		if(GetEntDataEnt2(i, OwnerOffset)!=client){
// 			continue;
// 		}

// 		SetEntProp(i, Prop_Send, "m_iObjectType", function_GetBuildingType(i));
// 	}

// }

// public TFObjectType function_GetBuildingType(int entIndex){
// 	//This function relies on Netclass rather than building type since building type
// 	//gets changed
// 	decl String:netclass[32];
// 	GetEntityNetClass(entIndex, netclass, sizeof(netclass));

// 	if(strcmp(netclass, "CObjectSentrygun") == 0){
// 		return TFObject_Sentry;
// 	}
// 	if(strcmp(netclass, "CObjectDispenser") == 0){
// 		return TFObject_Dispenser;
// 	}
// 	return TFObject_Sapper;
// }

public MRESReturn UpdateOnRemove(int pThis)
{
	int iObjectType = GetEntProp(pThis, Prop_Send, "m_iObjectType");
	//int user = GetClientUserId(pThis);
	//////PrintToChatAll("Removed sapper %i", iObjectType);
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
			////PrintToChatAll("I builder client %i", iBuilderClient);
				//Proofing for when a building doesn't have an owner , when it's spawned
			if(!IsValidClient(iBuilderClient))
			{
				return MRES_Ignored;
			}
			if(HasStat(iBuilderClient))
			{
					char stat_buffer[256];
				if (!TF2CustAttr_GetString(iBuilderClient, "robot engineer", stat_buffer, sizeof(stat_buffer))) {
					return MRES_Ignored;
				}
				int remove_all_sappers = ReadIntVar(stat_buffer, "remove_all_sappers", 0);
				if (remove_all_sappers > 0)
				{
									new ent = -1;	//Check all buildings owned by robot and remove sappers
					while ((ent = FindEntityByClassname(ent, "obj_attachment_sapper")) != -1)
					{
						////PrintToChatAll("Looking for sappers!");

						// int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
						// if (IsValidClient(iBuilder))
						// {
						// 	////PrintToChatAll("iBulder %N", iBuilder);	
						// // }
						if (IsValidEntity(ent))
						{
							
							int uBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuiltOnEntity");
							int uBuilderClient;
							//////PrintToChatAll("iBulder %N", uBuilder);	
							if(uBuilder != -1)
							{
								uBuilderClient = GetEntPropEnt(uBuilder, Prop_Send, "m_hBuilder");
							
								if (HasStat(uBuilderClient))
									{

										////PrintToChatAll("Removing sappers for %N, ent was: %i", uBuilderClient, ent);
										
										//SetVariantInt(999);
										RequestFrame(DetonateObject, ent);
										//DetonateObject(ent);
										
									}
							}
						}
					}
				}

				}
		}
	//////PrintToChatAll("Remove Sapper: %i, OT: %i", pThis, GetEntProp(pThis, Prop_Send, "m_iObjectType"));
	//////PrintToChatAll("Built on: %i", GetEntPropEnt(pThis, Prop_Send, "m_hBuiltOnEntity"));
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


////THROWING CODE

public void LockConVar(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (!StrEqual(newValue, PLUGIN_VERSION)) convar.SetString(PLUGIN_VERSION);
}
public void OnTossBuildingTypesChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	_ParseTypesTo(g_iAllowTypes, newValue);
}
public void OnTossBuildingForceChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_flThrowForce = convar.FloatValue;
}
public void OnTossBuildingOOBChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	_ParseTypesTo(g_iNoOOBTypes, newValue);
}
public void OnTossBuildingUprightChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_flUprightForce = convar.FloatValue;
}
static void _ParseTypesTo(int& value, const char[] typesString) {
	if (StrContains(typesString, "dispenser", false)>=0) {
		value |= TBFLAG_DISPENSER;
	} else {
		value &=~ TBFLAG_DISPENSER;
	}
	if (StrContains(typesString, "teleporter", false)>=0) {
		value |= TBFLAG_TELEPORTER;
	} else {
		value &=~ TBFLAG_TELEPORTER;
	}
	if (StrContains(typesString, "sentry", false)>=0) {
		value |= TBFLAG_SENTRYGUN;
	} else {
		value &=~ TBFLAG_SENTRYGUN;
	}
}

public void OnMapStart() {
	g_aAirbornObjects.Clear();
	CreateTimer(0.1, Timer_PlaceBuildings, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
	
	for (int i=0;i<3;i++) {
		char buffer[PLATFORM_MAX_PATH];
		GetModelForBuilding(i, buffer, sizeof(buffer));
		if ((g_iBuildingModelIndexLV1[i] = PrecacheModel(buffer, true))==0)
			ThrowError("Could not precache building model for type %i", i);
	}
}

public void OnClientDisconnect(int client) {
	g_bPlayerThrow[client] = false;
	g_flClientLastBeep[client] = 0.0;
	g_flClientLastNotif[client] = 0.0;
}

public void OnAllPluginsLoaded() {
	g_bDepHudMsg = LibraryExists("tf2hudmsg");
}
public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "tf2hudmsg")) g_bDepHudMsg = true;
}
public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "tf2hudmsg")) g_bDepHudMsg = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	if (!(1<=client<=MaxClients) || !IsClientInGame(client) || IsFakeClient(client)) return Plugin_Continue;
	if ((buttons & IN_RELOAD)!=0 && !g_bPlayerThrow[client] && g_yeet[client] == 1) {
		if ( IsThrowBlocked(client) ) {
			if (GetClientTime(client) - g_flClientLastNotif[client] >= 1.0) {
				g_flClientLastNotif[client] = GetClientTime(client);
				HudNotify(client, 0, "You can't toss this building");
			}
		} else {
			//trigger force build and throw on Reload
			g_bPlayerThrow[client] = true;
			if (CheckThrowPos(client)) StartBuilding(client);
			g_bPlayerThrow[client] = false;
		}
	}
	return Plugin_Continue;
}

public void OnPlayerCarryObject(Event event, const char[] name, bool dontBroadcast) {
	int owner = GetClientOfUserId(event.GetInt("userid"));
	int objecttype = event.GetInt("object");
	int building = event.GetInt("index");
	if ((g_yeet[owner] == 1 && BUILDING_DISPENSER <= objecttype <= BUILDING_SENTRYGUN) && IsClientInGame(owner) && IsValidEdict(building) && ( g_iAllowTypes&(1<<objecttype) )!=0) {
		//small sanity check: was this building picked up while flagged as thrown?
		if (g_aAirbornObjects.FindValue(EntIndexToEntRef(building), AirbornData::building) != -1) {
			//visually destory the building, the check timer will clean up the phys prop later
			BreakBuilding(building);
		} else {
			HudNotify(owner, _, "Press [RELOAD] to toss the building");
		}
	}
}
public void OnPlayerBuiltObject(Event event, const char[] name, bool dontBroadcast) {
	int owner = GetClientOfUserId(event.GetInt("userid"));
	int objecttype = event.GetInt("object");
	int building = event.GetInt("index");
	
	if ((g_yeet[owner] == 1 && BUILDING_DISPENSER <= objecttype <= BUILDING_SENTRYGUN) && IsClientInGame(owner) && IsValidEdict(building) && g_bPlayerThrow[owner]) {
		g_bPlayerThrow[owner] = false;
		RequestFrame(ThrowBuilding,EntIndexToEntRef(building));
	}
}

public void TF2_OnWaitingForPlayersStart() {
	g_iBlockFlags |= TBLOCK_WFP;
}
public void TF2_OnWaitingForPlayersEnd() {
	g_iBlockFlags &=~ TBLOCK_WFP;
}

public Action Timer_PlaceBuildings(Handle timer) {
	ValidateThrown();
}

public bool TEF_HitSelfFilter(int entity, int contentsMask, any data) {
	return entity != data;
}
public bool TEF_HitSelfFilterPassClients(int entity, int contentsMask, any data) {
	return entity > MaxClients && entity != data;
}
public bool TEF_HitThrownFilter(int entity, int contentsMask, any data) {
	if (!entity) return contentsMask != CONTENTS_EMPTY;
	AirbornData edicts;
	g_aAirbornObjects.GetArray(data,edicts);
	int entref = EntIndexToEntRef(entity);
	return entity > MaxClients && entref != edicts.physObject && entref != edicts.building;
}

public void ThrowBuilding(any buildref) {
	int building = EntRefToEntIndex(buildref);
	if (building == INVALID_ENT_REFERENCE) return;
	int owner = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
	if (owner < 1 || owner > MaxClients || !IsClientInGame(owner)) return;
	int type = GetEntProp(building, Prop_Send, "m_iObjectType");



	
	if (g_fwdToss.FunctionCount>0) {
		Action result;
		Call_StartForward(g_fwdToss);
		Call_PushCell(building);
		Call_PushCell(type);
		Call_PushCell(owner);
		if (Call_Finish(result) != SP_ERROR_NONE || result != Plugin_Continue) {
			return;
		}
	}
	
	float eyes[3];
	float origin[3];
	float angles[3];
	float fwd[3];
	float velocity[3];
	GetClientEyePosition(owner, origin);
	eyes = origin;
	//set origin in front of player
	GetClientEyeAngles(owner, angles);
	angles[0]=angles[2]=0.0;
	GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 64.0);
	AddVectors(origin, fwd, origin);
	//get angles/velocity
	GetClientEyeAngles(owner, angles);
	GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, g_flThrowForce);
	fwd[2] += (g_flThrowForce/3.25);//bit more archy
	Entity_GetAbsVelocity(owner, velocity);
	AddVectors(velocity, fwd, velocity);
	angles[0] = angles[2] = 0.0; //upright angle = 0.0 yaw 0.0
	
	int phys = CreateEntityByName("prop_physics_multiplayer");
	if (phys == INVALID_ENT_REFERENCE) return;
	
	char targetName[24];
	Format(targetName, sizeof(targetName), "physbuilding_%08X", EntIndexToEntRef(phys));
	char buffer[PLATFORM_MAX_PATH];
	GetModelForBuilding(type, buffer, sizeof(buffer));
	DispatchKeyValue(phys, "targetname", targetName);
	DispatchKeyValue(phys, "model", buffer);
	DispatchKeyValue(phys, "physicsmode", "2"); //don't push (hard collide) with player (1), but get pushed (soft collide)
	DispatchKeyValueVector(phys, "origin", origin);
	DispatchKeyValueVector(phys, "angles", angles);
	Format(buffer, sizeof(buffer), "%i", GetEntProp(building, Prop_Send, "m_nSkin"));
	DispatchKeyValue(phys, "skin", buffer);
	if (GetEntProp(building, Prop_Send, "m_bDisposableBuilding")) buffer = "0.66";
	else if (GetEntProp(building, Prop_Send, "m_bMiniBuilding")) buffer = "0.75";
	else buffer = "1.0";
	DispatchKeyValue(phys, "modelscale", buffer);//mini sentries are .75
//	DispatchKeyValue(phys, "solid", "2"); //2 bbox 6 vphysics
	if (!DispatchSpawn(phys)) {
		PrintToChat(owner, "Failed to spawn physics prop");
		return;
	}
	ActivateEntity(phys);
//	Entity_SetCollisionGroup(phys, COLLISION_GROUP_DEBRIS_TRIGGER);
	SetEntityRenderMode(phys, RENDER_NORMAL); //why is it sometimes not rendered?
	
	int angleMgr = INVALID_ENT_REFERENCE;
	if (g_flUprightForce > 0.01) {
		angleMgr = CreateEntityByName("phys_keepupright");
		if (angleMgr != INVALID_ENT_REFERENCE) {
			DispatchKeyValue(angleMgr, "attach1", targetName);
			DispatchKeyValueFloat(angleMgr, "angularlimit", g_flUprightForce);
			DispatchKeyValueVector(angleMgr, "angles", angles);
			if (!DispatchSpawn(angleMgr))
				//oops; edict should go away on it's own
				angleMgr = INVALID_ENT_REFERENCE;
			else {
				ActivateEntity(angleMgr);
				AcceptEntityInput(angleMgr, "TurnOn");
			}
		}
	}
	
	//set properties to prevent the building from progressing construction
	bool newlyBuilt = GetEntProp(building, Prop_Send, "m_bCarryDeploy")==0;
	SetEntProp(building, Prop_Send, "m_bCarried", 1);
	SetEntProp(building, Prop_Send, "m_bBuilding", 0);
	if (newlyBuilt) { //set health above 66% to suppress the client side alert
		int maxhp = TF2Util_GetEntityMaxHealth(building);
		Entity_SetHealth(building, maxhp);
	}
	//put it in a state similar to carried for collision/rendering
	Entity_SetSolidFlags(building, FSOLID_NOT_SOLID);
	SetEntityRenderMode(building, RENDER_NONE);
	TeleportEntity(building, origin, NULL_VECTOR, NULL_VECTOR);
	//parent to phys and throw
	SetVariantString("!activator");
	AcceptEntityInput(building, "SetParent", phys);
	Phys_ApplyForceCenter(phys, velocity);// works best
	
	AirbornData onade;
	onade.physObject=EntIndexToEntRef(phys);
	onade.building=EntIndexToEntRef(building);
	onade.upright= (angleMgr != INVALID_ENT_REFERENCE) ? EntIndexToEntRef(angleMgr) : INVALID_ENT_REFERENCE;
	onade.yaw=angles[1];
	onade.newBuild=newlyBuilt;
	onade.prevPos=origin;
	g_aAirbornObjects.PushArray(onade);
	
	if (g_fwdTossPost.FunctionCount>0) {
		Call_StartForward(g_fwdToss);
		Call_PushCell(building);
		Call_PushCell(type);
		Call_PushCell(owner);
		Call_Finish();
	}
}

void ValidateThrown() {
	for (int i=g_aAirbornObjects.Length-1; i>=0; i--) {
		AirbornData data;
		g_aAirbornObjects.GetArray(i,data);
		int phys = EntRefToEntIndex(data.physObject);
		int obj = EntRefToEntIndex(data.building);
		int angMgr = (data.upright != INVALID_ENT_REFERENCE) ? EntRefToEntIndex(data.upright) : INVALID_ENT_REFERENCE;
		//if at least one of the entities went away, something went wrong
		// -> remove and continue
		if (!IsValidEdict(phys)) {
			if (IsValidEdict(angMgr)) AcceptEntityInput(angMgr, "Kill");
			if (IsValidEdict(obj)) BreakBuilding(obj);
			g_aAirbornObjects.Erase(i);
			PrintToServer("Phys entity invalid");
			continue;
		} else if (!IsValidEdict(obj)) {
			if (IsValidEdict(angMgr)) AcceptEntityInput(angMgr, "Kill");
			if (IsValidEdict(phys)) AcceptEntityInput(phys, "Kill");
			g_aAirbornObjects.Erase(i);
			PrintToServer("Building entity invalid");
			continue;
		}
		int type = GetEntProp(obj, Prop_Send, "m_iObjectType");
		
		float mins[3],maxs[3],pos[3],vec[3];
		//get bounds for collision
		Entity_GetMinSize(obj,mins);
		Entity_GetMaxSize(obj,maxs);
		//find local center point, as mins/maxs is for the AABB
		AddVectors(mins,maxs,vec);
		ScaleVector(vec,0.5);
		//using this call we can get the world center
		Phys_LocalToWorld(obj, pos, vec);
		//check for playerclips
		if (BUILDING_DISPENSER <= type <= BUILDING_SENTRYGUN && (g_iNoOOBTypes & (1<<type))!=0 ) {
			TR_TraceRayFilter(data.prevPos, pos, CONTENTS_PLAYERCLIP, RayType_EndPoint, TEF_HitThrownFilter, i);
			if (TR_DidHit()) {
				BreakBuilding(obj);
				if (IsValidEdict(angMgr)) AcceptEntityInput(angMgr, "Kill");
				AcceptEntityInput(phys, "Kill");
				g_aAirbornObjects.Erase(i);
				continue;
			}
		}
		data.prevPos = pos;
		g_aAirbornObjects.SetArray(i, data); //update position vector
		//get ray end
		//teles are wider than high, find the largest dimension for ground testing
		SubtractVectors(maxs,mins,vec);
		float offz = vec[2] * 0.55;
		if (offz < 24.0) offz = 24.0;
		//from pos, send the ray over half maxdim down, so we can always find ground
		vec = pos;
		vec[2] -= offz;
		//make trace hull discy
		mins[2] = 0.0; //7 up from bottom
		maxs[2] = 1.0; //8 up from bottom
		//scan
//		if (TR_PointOutsideWorld(pos)) {
//			AcceptEntityInput(phys, "Kill");
//			AcceptEntityInput(obj, "Kill");
//			g_aAirbornObjects.Erase(i);
//			PrintToServer("Building fell out of world, destroying!");
//			continue;
//		}
		TR_TraceHullFilter(pos,vec, mins,maxs, MASK_BUILDINGS, TEF_HitThrownFilter, i);
		if (!TR_DidHit()) {
			continue;
		}
		TR_GetEndPosition(pos);
		TR_GetPlaneNormal(INVALID_HANDLE, vec); //vanilla is not snapping to this
		
		//check surface slope
		float up[3]; up[2]=1.0;
		float slope = ArcCosine( GetVectorDotProduct(vec, up) ) * 180.0/3.1415927;
		if (slope > 35.0) {
			//this slope is too steep to place a building. let it roll
			continue;
		}
		//construct angles by random direction, using standard right to get propper forward
		float angles[3];
		angles[1]=data.yaw;
		//clear parent
		AcceptEntityInput(obj, "ClearParent");
		//fix building
		float zeros[3];
		TeleportEntity(obj, pos, angles, zeros); //use 0-velocity to calm down bouncyness
		//restore other props: get it out of peudo carry state 
		SetEntProp(obj, Prop_Send, "m_bBuilding", 1);
		SetEntProp(obj, Prop_Send, "m_bCarried", 0);
		SetEntProp(obj, Prop_Send, "m_bCarryDeploy", data.newBuild?0:1);
		if (data.newBuild) {
			Entity_SetHealth(obj,1,_,false);
		} else if (GetEntProp(obj, Prop_Send, "m_iUpgradeLevel") > 1) {
			//properly appear as level 1 building after placement
			Entity_SetModelIndex(obj, g_iBuildingModelIndexLV1[type]);
			SetEntProp(obj, Prop_Send, "m_iUpgradeLevel", 1);
			//the sequence would have to be restarted as well, but i couldn't find any way to do that
		}
		Entity_RemoveSolidFlags(obj, FSOLID_NOT_SOLID);
		SetEntityRenderMode(obj, RENDER_NORMAL);
		//check valid
		CreateTimer(0.1, ValidateBuilding, EntIndexToEntRef(obj), TIMER_FLAG_NO_MAPCHANGE);
		//we no longer need the "carrier"
		if (IsValidEdict(angMgr)) AcceptEntityInput(angMgr, "Kill");
		AcceptEntityInput(phys, "Kill");
		g_aAirbornObjects.Erase(i);
	}
}

/** Invalid preconditions PASS! as this is used for message printing only */
bool IsThrowBlocked(int client) {
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;
	int weapon = Client_GetActiveWeapon(client);
	int item = IsValidEdict(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
	if (item != 28)
		return false; //require builder
	int bstate = GetEntProp(weapon, Prop_Send, "m_iBuildState");
	if (bstate != BS_PLACING && bstate != BS_PLACING_INVALID)
		return false; //currently not placing
	int objectToBuild = GetEntPropEnt(weapon, Prop_Send, "m_hObjectBeingBuilt");
	if (objectToBuild == INVALID_ENT_REFERENCE) {
		RequestFrame(FixNoObjectBeingHeld, GetClientUserId(client));
		return false; //no object being buil!?
	}
	int type = GetEntProp(objectToBuild, Prop_Send, "m_iObjectType");
	if (!(BUILDING_DISPENSER <= type <= BUILDING_SENTRYGUN))
		return false; //supported buildings, not always correct on weapon_builder
	
	return ( g_iAllowTypes&(1<<type) )==0;
}

bool CheckThrowPos(int client) {
	if (g_iBlockFlags != 0) return false;
	float eyes[3];
	float origin[3];
	float angles[3];
	float fwd[3];
	GetClientEyePosition(client, origin);
	eyes = origin;
	//set origin in front of player
	GetClientEyeAngles(client, angles);
	angles[0]=angles[2]=0.0;
	GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fwd, 64.0);
	AddVectors(origin, fwd, origin);
	//ensure we see the target
	Handle trace = TR_TraceRayFilterEx(eyes, origin, MASK_PLAYERSOLID, RayType_EndPoint, TEF_HitSelfFilterPassClients, client);
	bool hit = TR_DidHit(trace);
	delete trace;
	//can't see throw point (prevent through walls)? make noise
	if (hit) Beep(client);
	return !hit;
}

int StartBuilding(int client) {
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return -1;
	int weapon = Client_GetActiveWeapon(client);
	int item = IsValidEdict(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
	if (item != 28)
		return -1; //require builder
	int bstate = GetEntProp(weapon, Prop_Send, "m_iBuildState");
	if (bstate != BS_PLACING && bstate != BS_PLACING_INVALID)
		return -1; //currently not placing
	int objectToBuild = GetEntPropEnt(weapon, Prop_Send, "m_hObjectBeingBuilt");
	if (objectToBuild == INVALID_ENT_REFERENCE) {
		RequestFrame(FixNoObjectBeingHeld, GetClientUserId(client));
		return -1; //no object being buil!?
	}
	int type = GetEntProp(objectToBuild, Prop_Send, "m_iObjectType");
	if (!(BUILDING_DISPENSER <= type <= BUILDING_SENTRYGUN))
		return -1; //supported buildings, not always correct on weapon_builder
	
	SetEntPropEnt(weapon, Prop_Send, "m_hOwner", client);
	SetEntProp(weapon, Prop_Send, "m_iBuildState", BS_PLACING); //if placing_invalid
	SDKCall(sdk_fnStartBuilding, weapon);
	return objectToBuild;
}

void FixNoObjectBeingHeld(int user) {
	//go through all validation again
	int client = GetClientOfUserId(user);
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	int weapon = Client_GetActiveWeapon(client);
	int item = IsValidEdict(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
	if (item != 28)
		return; //weapon switched
	int type = GetEntProp(weapon, Prop_Send, "m_iObjectType");
	if (!(BUILDING_DISPENSER <= type <= BUILDING_SENTRYGUN))
		return; //unsupported building
	int bstate = GetEntProp(weapon, Prop_Send, "m_iBuildState");
	if (bstate != BS_PLACING && bstate != BS_PLACING_INVALID)
		return; //not in a glitched state
	int objectToBuild = GetEntPropEnt(weapon, Prop_Send, "m_hObjectBeingBuilt");
	if (objectToBuild == INVALID_ENT_REFERENCE) {
		//holding empty box, try to find another weapon to switch to
		for (int i=2;i>=0;i-=1) {
			weapon = Client_GetWeaponBySlot(client, i);
			if (weapon != INVALID_ENT_REFERENCE) {
				Client_SetActiveWeapon(client, weapon);
			}
		}
	}
}

//crashes, idk why
//bool IsPlacementPosValid(int building) {
//	char classname[64];
//	if (!IsValidEdict(building)
//	|| !GetEntityClassname(building, classname, sizeof(classname))
//	|| !(StrEqual(classname, "obj_sentrygun")
//	   || StrEqual(classname, "obj_teleporter")
//	   || StrEqual(classname, "obj_dispenser")
//	   ))
//		ThrowError("Entity is not a building");
//	return SDKCall(sdk_fnIsPlacementPosValid, building);
//}

//wow, searching a type of entity at a certain location sure sucks
static bool bTEEFuncNobuildFound;
//return true to continue search
public bool TEE_SearchFuncNobuild(int entity, any data) {
	char classname[32];
	if (entity == data) return true;
	GetEntityClassname(entity, classname, sizeof(classname));
	// TF2Util_IsPointInRespawnRoom is only checking for same team spawn room - daheck?
	if (StrEqual(classname, "func_nobuild") || StrEqual(classname, "func_respawnroom")) {
		bTEEFuncNobuildFound = true;
		return false;
	}
	return true;
}

public Action ValidateBuilding(Handle timer, any building) {
	int obj = EntRefToEntIndex(building);
	if (obj == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	float mins[3],maxs[3],origin[3];
	float four[3];
	four[0]=four[1]=four[2]=4.0;
	Entity_GetAbsOrigin(obj,origin);
	Entity_GetMinSize(obj,mins);
	Entity_GetMaxSize(obj,maxs);
	AddVectors(mins,four,mins);
	SubtractVectors(maxs,four,maxs);
	
	TR_TraceHullFilter(origin, origin, mins, maxs, MASK_BUILDINGS, TEF_HitSelfFilter, obj);
	bool invalid = TR_DidHit() || TF2Util_IsPointInRespawnRoom(origin, obj);
	if (!invalid) {
		//look for nobuild areas
		bTEEFuncNobuildFound = false;
		TR_EnumerateEntitiesHull(origin, origin, mins, maxs, PARTITION_TRIGGER_EDICTS, TEE_SearchFuncNobuild, obj);
		if (bTEEFuncNobuildFound) {
			invalid = true;
		}
	}
	
	if (invalid) BreakBuilding(obj);
	if (g_fwdLanded.FunctionCount>0) {
		Call_StartForward(g_fwdLanded);
		Call_PushCell(building);
		Call_PushCell(!invalid);
		Call_Finish();
	}
	return Plugin_Stop;
}

void BreakBuilding(int building) {
	SetVariantInt(RoundToCeil(Entity_GetHealth(building)*1.5));
	AcceptEntityInput(building, "RemoveHealth");
}

void Beep(int client) {
	if (!(1<=client<=MaxClients) || !IsClientInGame(client) || IsFakeClient(client)) return;
	if (GetClientTime(client) - g_flClientLastBeep[client] >= 1.0) {
		g_flClientLastBeep[client] = GetClientTime(client);
		EmitSoundToClient(client, "common/wpn_denyselect.wav");//should aready be precached by game
	}
}

void HudNotify(int client, int color=-1, const char[] format, any ...) {
	char buffer[128];
	VFormat(buffer, sizeof(buffer), format, 3);
#if defined _inc_tf2hudmsg
	if (g_bDepHudMsg)
//		TF2_HudNotificationCustom(client, "obj_status_icon_wrench", TFTeam_Red, _, "%s", buffer);
		TF2_HudNotificationCustom(client, "ico_build", color, _, "%s", buffer);
	else
		PrintHintText(client, "%s", buffer);
#else
	PrintHintText(client, "%s", buffer);
#endif
}

void GetModelForBuilding(int buildingType, char[] model, int maxlen) {
	switch (buildingType) {
		case BUILDING_SENTRYGUN: strcopy(model, maxlen, "models/buildables/sentry1.mdl");
		case BUILDING_DISPENSER: strcopy(model, maxlen, "models/buildables/dispenser_light.mdl");
		case BUILDING_TELEPORTER: strcopy(model, maxlen, "models/buildables/teleporter_light.mdl");
		default: ThrowError("Unsupported Building Type %i", buildingType);
	}
}