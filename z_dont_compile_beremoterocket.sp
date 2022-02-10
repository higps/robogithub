#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
//#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>

#include <tf2>
#include <sdkhooks>
#include <sdktools>


bool ControllingRocket[MAXPLAYERS+1];
bool PlayerControlRockets[MAXPLAYERS+1];
bool RocketOverride[2049];
int RocketID[MAXPLAYERS+1];

//rocket settings
int AimType;
float RotRate;

ConVar g_rocketTurnRate;
ConVar g_rocketAimType;

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Remote Rocket"
#define ROBOT_ROLE "Damage"
#define ROBOT_DESCRIPTION "Remotely control Rockets"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

#define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
#define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
#define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"


#define CROSSCOMM 764

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Homer Soldier",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Homer",
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


public void OnPluginStart()
{
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

    LoadTranslations("common.phrases");

    //	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
    AddNormalSoundHook(BossHomer);

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Soldier";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION);

	g_rocketTurnRate = CreateConVar("rc_rocket_turn_rate", "100.0", "Degrees per second at which rockets rotate when being controlled by player movement");
	g_rocketAimType = CreateConVar("rc_rocket_aim_type", "1", "Method for aiming rockets. 0 = player movement | 1 = player aim");
	HookConVarChange(g_rocketAimType, OnRocketAimChanged);

	//Events
	AddCommandListener(PlayerJoinClass, "joinclass");
	HookEvent("player_death", PlayerDeath);

	RegConsoleCmd("sm_rc", CmdControl);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			OnClientPostAdminCheck(client);
		}
	}
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

	PrecacheSound(GUNFIRE);
	PrecacheSound(GUNFIRE_CRIT);
	PrecacheSound(GUNFIRE_EXPLOSION);
	

	PrecacheSound(LEFTFOOT);
	PrecacheSound(LEFTFOOT1);
	PrecacheSound(RIGHTFOOT);
	PrecacheSound(RIGHTFOOT1);
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);
	
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

public Action:BossHomer(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
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

	
	if (strncmp(sample, ")weapons/", 9, false) == 0)
	{
		if (StrContains(sample, "rocket_shoot.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE);
			EmitSoundToAll(sample, entity);
			
		}
		else if (StrContains(sample, "rocket_shoot_crit.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_CRIT);
			EmitSoundToAll(sample, entity);
		}
		
		//Explosion doesnæt quite work
		/* 		else if (StrContains(sample, "explode1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "explode2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "explode3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		} */
		return Plugin_Changed;
	}
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
}

MakeGiantSoldier(client)
{
	//aSMLOGTag(SML_VERBOSE, "Createing Homer");
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
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.6);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.1);
float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintToChat(client, "1. You are now Homer soldier !");
	
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

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{	
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		
			
		CreateRoboHat(client, CROSSCOMM, 10, 6, 0.0, 0.75, -1.0); //Bobby Bonnet


		CreateRoboWeapon(client, "tf_weapon_rocketlauncher", 513, 6, 1, 2, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "damage penalty", 0.5);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);				
			TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 3.0);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.8);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 2.75);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			TF2Attrib_SetByName(Weapon1, "projectile speed decreased", 0.25);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			//TF2CustAttr_SetString(Weapon1, "homing_proj_mvm", "detection_radius=250.0 homing_mode=1 projectilename=tf_projectile_rocket");			
		}
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));


public void OnEntityCreated(int entity, const char[] classname)
{
	if (!(StrContains(classname, "tf_projectile_rocket")))
	{
		//SDKHook(entity, SDKHook_SpawnPost, OnRocketSpawned);
		RequestFrame(OnRocketSpawned, entity);
		SDKHook(entity, SDKHook_Touch, OnRocketEnd);
		SDKHook(entity, SDKHook_Spawn, Hook_OnProjectileSpawn);
	}
}

public void Hook_OnProjectileSpawn(iEntity) {
	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
	if (0 < iClient && iClient <= MaxClients && IsRobot(iClient, ROBOT_NAME)) {
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.75);
	}
}


public void OnRocketAimChanged(ConVar convar, char[] oldVal, char[] newVal)
{
	AimType = StringToInt(newVal);
}

public void OnRocketRateChanged(ConVar convar, char[] oldVal, char[] newVal)
{
	RotRate = StringToFloat(newVal);
}

public Action PlayerDeath(Handle event, const char[] name, bool dBroad)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ControllingRocket[victim])
	{
		SetPlayerRCMode(victim, false);
	}
}

public Action PlayerJoinClass(int client, const char[] command, int argc)
{
	if (TF2_GetPlayerClass(client) == TFClass_Soldier && PlayerControlRockets[client])
	{
		PlayerControlRockets[client] = false;
		PrintToChat(client, "[SM] Disabling RC rockets due to class change.");
	}
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	//clear variables
	ControllingRocket[client] = false;
	PlayerControlRockets[client] = false;
	RocketID[client] = INVALID_ENT_REFERENCE;
}

Action CmdControl(int client, int args)
{
	if (TF2_GetPlayerClass(client) != TFClass_Soldier)
	{
		PrintToChat(client, "[SM] You must be a soldier to use this command!");
	}
	else
	{

		PlayerControlRockets[client] = !PlayerControlRockets[client];
	}
}



public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || entity > 2048) return; //prevent ent refs being used
	if (IsValidEntity(entity))
	{
		RocketOverride[entity] = false;
	}
}

public void OnRocketSpawned(int rocket)
{
	int owner = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
	if (PlayerControlRockets[owner])
	{
		RocketID[owner] = rocket;
		RocketOverride[rocket] = true;
		SetPlayerRCMode(owner, true);
	}
}

void SetPlayerRCMode(int client, bool status)
{
	ControllingRocket[client] = status;
	if (status && IsValidRocket(RocketID[client]))
	{
		SetClientViewEntity(client, RocketID[client]);
		SetEntityMoveType(client, MOVETYPE_NONE);
	}
	else
	{
		SetClientViewEntity(client, client);
		SetEntityMoveType(client, MOVETYPE_WALK);
		RocketID[client] = INVALID_ENT_REFERENCE;
	}
}

//Make sure to take the player out of the remote control state upon a rocket hitting something
public Action OnRocketEnd(int rocket, int victim)
{
	if (RocketOverride[rocket])
	{
		int owner = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
		if (!IsValidClient(victim))
		{
			char classname[64];
			GetEntityClassname(victim, classname, sizeof classname);
			if (victim == 0 || !StrContains(classname, "prop_", false) || !StrContains(classname, "obj_", false) || !StrContains(classname, "func_door")) //solid props
			{
				SetPlayerRCMode(owner, false);
			}
		}
		else if (IsValidClient(victim))
		{
			bool sameTeam = (GetClientTeam(owner) == GetClientTeam(victim)); //check if the player we hit is an enemy player
			if (sameTeam)
			{
				//return Plugin_Handled; //pass through teammates to prevent control being lost on player overlap - DOESNT WORK NEED A BETTER METHOD
			}
			else
			{
				SetPlayerRCMode(owner, false);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (ControllingRocket[client] && IsValidRocket(RocketID[client]))
	{
		buttons &= ~IN_ATTACK;
		int rocket = RocketID[client];
		float rocketAngle[3], forwardVec[3], velocity[3], speed;
		float rate = RotRate / 67.0; //this function executes ~67 times per second, so divide by 67 to get our turn rate in degrees per second.
		GetEntPropVector(rocket, Prop_Data, "m_vecVelocity", velocity);
		GetEntPropVector(rocket, Prop_Send, "m_angRotation", rocketAngle);
		speed = GetVectorLength(velocity);
		//movement
		switch (AimType)
		{
			case 0: //player movement
			{
				if (buttons & IN_FORWARD) //angle down
				{
					rocketAngle[0] += rate;
				}
				if (buttons & IN_BACK) //angle up
				{
					rocketAngle[0] -= rate;
				}
				if (buttons & IN_MOVERIGHT)
				{
					rocketAngle[1] -= rate;
				}
				if (buttons & IN_MOVELEFT)
				{
					rocketAngle[1] += rate;
				}
			}
			case 1:
			{
				GetClientEyeAngles(client, rocketAngle);
			}
		}
		GetAngleVectors(rocketAngle, forwardVec, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(forwardVec, speed);
		TeleportEntity(rocket, NULL_VECTOR, rocketAngle, forwardVec);
	}
}

bool IsValidRocket(int rocket)
{
	if (RocketOverride[rocket] && IsValidEntity(rocket) && rocket > MaxClients)
		return true;

	return false;
}
