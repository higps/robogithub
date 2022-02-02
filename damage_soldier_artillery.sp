#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"ICBM"
#define ROBOT_ROLE "Damage"
#define ROBOT_DESCRIPTION "Artillery Rocket Launcher"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

// #define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
// #define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
// #define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"

//Artillery code

#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


public Plugin MyInfo =
{
	name = "[TF2] Artillery Rocket Launcher",
	author = "IvoryPal",
	description = "Rocket launcher that fires volleys of rockets.",
	version = "1.0"
}

ConVar g_arcDelay;
ConVar g_arcGrav;
bool arcRockets[MAXPLAYERS+1];
bool weaponArc[2049];
bool shouldArc[2049];
float arcDelay[2049];


public Plugin:myinfo = 
{
	name = "[TF2] Be the ICBM",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Icebear from Frankfurt",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

public OnPluginStart()
{
    // SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

    LoadTranslations("common.phrases");

    //	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
    AddNormalSoundHook(BossIcebear);

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Soldier";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION, null, 2);

	//Artillery Code
	RegConsoleCmd("sm_arcrocket", CmdToggleArc);
	
	//HookEvent("post_inventory_application", Event_PlayerResupply);
	
	g_arcDelay = CreateConVar("tf_rocket_arc_delay", "0.5", "Delay in seconds before a rocket is affected by gravity");
	g_arcGrav = CreateConVar("tf_rocket_arc_gravity", "3.5", "Gravity to apply to arcing rockets");
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantSoldier", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheModel(GSOLDIER);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);

	// PrecacheSound(GUNFIRE);
	// PrecacheSound(GUNFIRE_CRIT);
	// PrecacheSound(GUNFIRE_EXPLOSION);
	

	PrecacheSound(LEFTFOOT);
	PrecacheSound(LEFTFOOT1);
	PrecacheSound(RIGHTFOOT);
	PrecacheSound(RIGHTFOOT1);
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);
	
}

/* public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_bIsGSoldier[client])
	{
		g_bIsGSoldier[client] = false;
	}
} */

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

public Action:BossIcebear(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
}

MakeGiantSoldier(client)
{
	// SMLogTag(SML_VERBOSE, "Createing Soldier");
	TF2_SetPlayerClass(client, TFClass_Soldier);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GSOLDIER);
	
	int iHealth = 3800;
		
	int MaxHealth = 200;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	float OverHealRate = 1.5;

	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;

	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;

	float scale = 1.65;
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	
	// TF2Attrib_SetByName(client, "self dmg push force increased", 6.0);
	// TF2Attrib_SetByName(client, "boots falling stomp", 6.0);
	
	//
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	//TF2Attrib_SetByName(client, "head scale", 0.5);
	UpdatePlayerHitbox(client,scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , "You have rocket specialist\nRockets travel in an arc");
	
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

// #define SergeantsDrillHat 183
// 
#define peacebreaker 31044

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_rocketlauncher", 1104, 6, 1, 2, 0);
		// CreateRoboWeapon(client, "tf_weapon_shotgun_soldier", 10, 6, 1, 2, 0);
		//CreateRoboWeapon(client, "tf_weapon_shovel", 416, 6, 1, 2, 0);
		
		CreateRoboHat(client, 31044, 10, 6, 0.0, 0.75, -1.0);


		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

		
		if(IsValidEntity(Weapon1))
		{

			//TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 2.0);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 1.25);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.8);				
			TF2Attrib_SetByName(Weapon1, "rocket specialist", 1.0);
			TF2Attrib_SetByName(Weapon1, "Projectile speed increased", 1.0);
			TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 4.0);

			
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
		}

		

	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));
	


public void OnClientPutInServer(int client)
{
	arcRockets[client] = false;
}

public Action CmdToggleArc(int client, int args)
{
	arcRockets[client] = !arcRockets[client];
	PrintToChat(client, "Artillery Launcher %s", arcRockets[client] ? "Enabled. Resupply to obtain it." : "Removed.");
}

// public Action Event_PlayerResupply(Handle event, const char[] name, bool dbroad)
// {
// 	int client = GetClientOfUserId(GetEventInt(event, "userid"));
// 	if (0 < client <= MaxClients && IsClientInGame(client))
// 	{
// 		int launcher = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
// 		if (IsValidEntity(launcher) && launcher > MaxClients && arcRockets[client])
// 		{
// 			weaponArc[launcher] = true;
// 			TF2Attrib_SetByName(launcher, "clip size bonus", 5.0);
// 		}
// 	}
// 	return Plugin_Continue;
// }

public void OnEntityDestroyed(int ent)
{
	if (IsValidEntity(ent) && ent > MaxClients && weaponArc[ent])
	{
		weaponArc[ent] = false;
	}
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_rocket") || StrEqual(classname, "tf_projectile_energy_rocket"))
	{
		SDKHook(ent, SDKHook_SpawnPost, OnProjSpawn);
		SDKHook(ent, SDKHook_Spawn, Hook_OnProjectileSpawn);
	}
}

public void Hook_OnProjectileSpawn(iEntity) {
	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
	if (0 < iClient && iClient <= MaxClients && IsRobot(iClient, ROBOT_NAME)) {
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.5);
	}
}

public void OnGameFrame()
{
	int ent = MaxClients + 1;
	while ((ent = FindEntityByClassname(ent, "tf_projectile_rocket")) != -1 || (ent = FindEntityByClassname(ent, "tf_projectile_energy_rocket")) != -1)
	{
		if (shouldArc[ent] && arcDelay[ent] <= GetEngineTime())
		{
			ArcRocket(ent);
		}
	}
}

public Action OnProjSpawn(int proj)
{
	int owner = GetEntPropEnt(proj, Prop_Send, "m_hOwnerEntity");
	//int launcher = GetEntPropEnt(proj, Prop_Send, "m_hLauncher");
	
	if (IsRobot(owner, ROBOT_NAME))
	{
		shouldArc[proj] = true;
		arcDelay[proj] = GetEngineTime() + GetConVarFloat(g_arcDelay);
	}
	else
		shouldArc[proj] = false;
}

public void ArcRocket(int rocket)
{
	float vel[3], rot[3];
	float grav = GetConVarFloat(g_arcGrav);
	
	GetEntPropVector(rocket, Prop_Data, "m_vecVelocity", vel);
	GetEntPropVector(rocket, Prop_Send, "m_angRotation", rot);
	
	vel[2] -= Pow(grav, 2.0);
	
	GetVectorAngles(vel, rot);
	ClampAngle(rot);
	
	SetEntPropVector(rocket, Prop_Data, "m_vecVelocity", vel);
	SetEntPropVector(rocket, Prop_Send, "m_angRotation", rot);
	TeleportEntity(rocket, NULL_VECTOR, rot, vel);
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}
