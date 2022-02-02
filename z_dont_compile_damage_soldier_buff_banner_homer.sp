#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Buff Banner Homer"
#define ROBOT_ROLE "Damage"
#define ROBOT_DESCRIPTION "Manual Homing Rockets"

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


#define MAX_ENTITY_LIMIT 2048

// bool g_bHomingEnabled[MAX_ENTITY_LIMIT + 1];
// float g_flHomingAccuracy[MAX_ENTITY_LIMIT + 1];
// int g_iLauncher[MAX_ENTITY_LIMIT + 1];

// float g_flHomingPoint[MAX_ENTITY_LIMIT + 1][3];
// int g_iLatestProjectile[MAX_ENTITY_LIMIT + 1];

// Handle g_KillTimer[MAX_ENTITY_LIMIT + 1];

// int g_iBlueGlowModelID = -1;
// int g_iRedGlowModelID = -1;

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

public OnPluginStart()
{
    // SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

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
	// g_iBlueGlowModelID = PrecacheModel("sprites/blueglow1.vmt");
	// g_iRedGlowModelID = PrecacheModel("sprites/redglow1.vmt");
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

	
	// if (strncmp(sample, ")weapons/", 9, false) == 0)
	// {
	// 	if (StrContains(sample, "rocket_shoot.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE);
	// 		EmitSoundToAll(sample, entity);
			
	// 	}
	// 	else if (StrContains(sample, "rocket_shoot_crit.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE_CRIT);
	// 		EmitSoundToAll(sample, entity);
	// 	}
		
	// 	//Explosion doesnæt quite work
	// 	/* 		else if (StrContains(sample, "explode1.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
	// 		EmitSoundToAll(sample, entity);
	// 	}
	// 	else if (StrContains(sample, "explode2.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
	// 		EmitSoundToAll(sample, entity);
	// 	}
	// 	else if (StrContains(sample, "explode3.wav", false) != -1)
	// 	{
	// 		Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
	// 		EmitSoundToAll(sample, entity);
	// 	} */
	// 	return Plugin_Changed;
	// }
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
}

MakeGiantSoldier(client)
{
	// SMLogTag(SML_VERBOSE, "Createing Homer");
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
	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
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
	
	//TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , "Activate constant homing rockets with the buff banner");
	
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
#define ManInSlacks 30392
#define SteelShako 30017
stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		// g_bHomingEnabled[client] = true;
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		CreateRoboWeapon(client, "tf_weapon_rocketlauncher_directhit", 127, 6, 1, 2, 0);
		
//		CreateWeapon(client, "tf_weapon_shovel", 447, 6, 1, 2, 0);
		
		
		CreateRoboHat(client, ManInSlacks, 10, 6, 0.0, 0.75, -1.0);
		CreateRoboHat(client, SteelShako, 10, 6, 0.0, 0.75, -1.0);

	//	CreateHat(client, 30050, 10, 6, true); //Gatebot
		CreateRoboWeapon(client, "tf_weapon_buff_item", 129, 6, 1, 1, 0);
		//CreateHat(client, 647, 10, 6, true); //The All-Father
		//CreateHat(client, 343, 10, 6, true);//Professor speks

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			
			TF2Attrib_SetByName(Weapon1, "damage penalty", 1.25);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
		//	TF2Attrib_SetByName(Weapon1, "clipsize increase on kill", 4.0);		
			TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 1.0);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 1.1);
		//	TF2Attrib_SetByName(Weapon1, "faster reload rate", 2.5);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			//TF2Attrib_SetByName(Weapon1, "projectile speed decreased", 0.8);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);

			
			
			//TF2CustAttr_SetString(Weapon1, "homing_proj_mvm", "detection_radius=250.0 homing_mode=1 projectilename=tf_projectile_rocket");			
		//	TF2Attrib_SetByName(Weapon1, "rocket specialist", 1.0);
			//TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);
			
			
		//	TF2Attrib_SetByName(Weapon1, "disable fancy class select anim", 1.0);
						
\			
		}
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "increase buff duration", 99.5);
			TF2CustAttr_SetString(Weapon2, "custom buff type", "rocket-aiming-control");
			TF2CustAttr_SetString(Weapon2, "rocket control buff turn rate", "0.25");
		}

		
		

	}
}


public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));

	

// 
// {
// 	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
// 	{
// 		char wepclassname[64];
// 		int wep = GetPlayerWeaponSlot(client, slot);
// 		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
// 		{
// 			FakeClientCommandEx(client, "use %s", wepclassname);
// 			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
// 		}
// 	}
// }


// public OnGameFrame()
// {
// 	for(new i = 1; i <= MaxClients; i++)
// 	{
// 		if(IsRobot(i, ROBOT_NAME))
// 		{
// 		//	SetHomingProjectile(i, "tf_projectile_arrow");
// 		//	SetHomingProjectile(i, "tf_projectile_energy_ball");
// 		//	SetHomingProjectile(i, "tf_projectile_flare");
// 		//	SetHomingProjectile(i, "tf_projectile_healing_bolt");
// 			SetHomingProjectile(i, "tf_projectile_rocket");
// 		//	SetHomingProjectile(i, "tf_projectile_sentryrocket");
// 		//	SetHomingProjectile(i, "tf_projectile_syringe");
// 		}
// 	}
// }

// SetHomingProjectile(client, const String:classname[])
// {
// 	new entity = -1; 
// 	while((entity = FindEntityByClassname(entity, classname))!=INVALID_ENT_REFERENCE)
// 	{
// 		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
// 		if(!IsValidEntity(owner)) continue;
// 		if(StrEqual(classname, "tf_projectile_sentryrocket", false)) owner = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");		
// 		new Target = GetClosestTarget(entity, owner);
// 		if(!Target) continue;
// 		if(owner == client)
// 		{
// 			new Float:ProjLocation[3], Float:ProjVector[3], Float:ProjSpeed, Float:ProjAngle[3], Float:TargetLocation[3], Float:AimVector[3];			
// 			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjLocation);
// 			GetClientAbsOrigin(Target, TargetLocation);
// 			TargetLocation[2] += 40.0;
// 			MakeVectorFromPoints(ProjLocation, TargetLocation , AimVector);
// 			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);					
// 			ProjSpeed = GetVectorLength(ProjVector);					
// 			AddVectors(ProjVector, AimVector, ProjVector);	
// 			NormalizeVector(ProjVector, ProjVector);
// 			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
// 			GetVectorAngles(ProjVector, ProjAngle);
// 			SetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);					
// 			ScaleVector(ProjVector, ProjSpeed);
// 			SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
// 		}
// 	}	
// }

// GetClosestTarget(entity, owner)
// {
// 	new Float:TargetDistance = 0.0;
// 	new ClosestTarget = 0;
// 	for(new i = 1; i <= MaxClients; i++) 
// 	{
// 		if(!IsClientConnected(i) || !IsPlayerAlive(i) || i == owner || (GetClientTeam(owner) == GetClientTeam(i))) continue;
// 		new Float:EntityLocation[3], Float:TargetLocation[3];
// 		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityLocation);
// 		GetClientAbsOrigin(i, TargetLocation);
		
// 		new Float:distance = GetVectorDistance(EntityLocation, TargetLocation);
// 		if(TargetDistance)
// 		{
// 			if(distance < TargetDistance) 
// 			{
// 				ClosestTarget = i;
// 				TargetDistance = distance;			
// 			}
// 		}
// 		else
// 		{
// 			ClosestTarget = i;
// 			TargetDistance = distance;
// 		}
// 	}
// 	return ClosestTarget;
// }


// public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
// {
// 	static bool bPressed[MAXPLAYERS + 1] =  { false, ... };
// 	if (IsClientInGame(client) && IsPlayerAlive(client))
// 	{
// 		int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
// 		if (IsRobot(client, ROBOT_NAME))
// 		{
// 			if(buttons & IN_ATTACK2)
// 			{
// 				if(!bPressed[client])
// 				{
// 					if(IsValidEntity(g_iLatestProjectile[weapon]))
// 					{
// 						g_bHomingEnabled[g_iLatestProjectile[weapon]] = true;
// 						GetPlayerEyePosition(client, g_flHomingPoint[g_iLatestProjectile[weapon]]);
// 					}else{
// 						ClientCommand(client, "playgamesound common/wpn_denyselect.wav");
// 					}
// 					bPressed[client] = true;
// 				}
// 			}else bPressed[client] = false;

// 			if (!TF2_IsPlayerInCondition(client, TFCond_Taunting) && !TF2_IsPlayerInCondition(client, TFCond_Taunting))
// 			{
// 				float flTargetPos[3];
// 				GetPlayerEyePosition(client, flTargetPos);

// 				if (GetClientTeam(client) == 2) TE_SetupGlowSprite( flTargetPos, g_iRedGlowModelID, 0.1, 0.17, 75 );
// 				else TE_SetupGlowSprite( flTargetPos, g_iBlueGlowModelID, 0.1, 0.17, 25 );

// 				TE_SendToClient(client);
// 			}
// 		}
// 	}
// }

// bool GetPlayerEyePosition(int client, float pos[3])
// {
// 	float vAngles[3], vOrigin[3];
// 	GetClientEyePosition(client, vOrigin);
// 	GetClientEyeAngles(client, vAngles);

// 	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer, client);

// 	if (TR_DidHit(trace))
// 	{
// 		TR_GetEndPosition(pos, trace);
// 		delete trace;
// 		return true;
// 	}
// 	delete trace;
// 	return false;
// }

// public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data)
// {
// 	if (entity <= 0) return true;
// 	if (entity == data) return false;

// 	char sClassname[128];
// 	GetEdictClassname(entity, sClassname, sizeof(sClassname));
// 	if (StrEqual(sClassname, "func_respawnroomvisualizer", false)) return false;
// 	else return true;
// }

// public void OnGameFrame()
// {
// 	int entity;
// 	while ((entity = FindEntityByClassname(entity, "tf_projectile_*")) != INVALID_ENT_REFERENCE)
// 	{
// 		if(IsValidEntity(g_iLauncher[entity]))
// 		{
// 			if(g_bHomingEnabled[entity])
// 			{
// 				int iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
// 				if (iOwner == -1)continue;
// 				int iActiveWeapon = GetEntPropEnt(iOwner, Prop_Data, "m_hActiveWeapon");

// 				if (iActiveWeapon != g_iLauncher[entity])continue;
// 				if(
// 					!IsClientInGame(iOwner) ||
// 					!IsPlayerAlive(iOwner) ||
// 					(
// 						HasEntProp(entity, Prop_Send, "m_iDeflected") &&
// 						GetEntProp(entity, Prop_Send, "m_iDeflected") == 1
// 					)
// 				)
// 				{
// 					g_bHomingEnabled[entity] = false;
// 					continue;
// 				}

// 				float flRocketAng[3];
// 				float flRocketVec[3];
// 				float flRocketPos[3];

// 				float flTargetPos[3];
// 				float flTargetVec[3];

// 				for (int i = 0; i < 3; i++)flTargetPos[i] = g_flHomingPoint[entity][i];

// 				GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", flRocketPos);
// 				GetEntPropVector(entity, Prop_Data, "m_angRotation", flRocketAng);
// 				GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", flRocketVec);
// 				float flRocketSpeed = GetVectorLength( flRocketVec );

// 				SubtractVectors(flTargetPos, flRocketPos, flTargetVec);
// 				ScaleVector(flTargetVec, g_flHomingAccuracy[entity]);
// 				AddVectors(flTargetVec, flRocketVec, flRocketVec);
// 				NormalizeVector(flRocketVec, flRocketVec);
// 				GetVectorAngles(flRocketVec, flRocketAng);
// 				ScaleVector(flRocketVec, flRocketSpeed);

// 				SetEntPropVector(entity, Prop_Data, "m_angRotation", flRocketAng);

// 				SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", flRocketVec);
// 			}
// 		}
// 	}
// }
// public void OnEntityCreated(int entity, const char[] classname)
// {
// 	if (entity < 1) return;

// 	g_iLauncher[entity] = 0;
// 	g_bHomingEnabled[entity] = false;
// 	g_flHomingAccuracy[entity] = 0.0;
// 	g_iLatestProjectile[entity] = INVALID_ENT_REFERENCE;

// 	if (StrContains(classname, "tf_projectile_") != -1)
// 	{
// 		CreateTimer(0.001, Timer_OnSpawn, entity);
// 	}
// }
// public Action Timer_OnSpawn(Handle timer, any entity)
// {
// 	if (!IsValidEdict(entity))return;
// 	int iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
// 	if (iOwner > 0 && iOwner <= MaxClients)
// 	{
// 		int weapon = GetEntPropEnt(iOwner, Prop_Data, "m_hActiveWeapon");
// 		if(IsValidEdict(weapon))
// 		{
// 			float flPower = 15.0;
// 			if(flPower > 0.0)
// 			{
// 				g_iLauncher[entity] = weapon;
// 				g_bHomingEnabled[entity] = false;
// 				g_flHomingAccuracy[entity] = flPower;
// 				g_iLatestProjectile[weapon] = entity;
// 			}
// 			float flLifetime = 15.0;
// 			if(flLifetime > 0.0)
// 			{
// 				g_KillTimer[entity] = CreateTimer(flLifetime, Timer_ExplodeProjectile, entity);
// 			}
// 		}
	
// 	}
// }
// public Action Timer_ExplodeProjectile(Handle timer, any rocket)
// {
// 	g_KillTimer[rocket] = INVALID_HANDLE;
// 	if(IsValidEdict(rocket))
// 	{
// 		char classname[256];
// 		GetEdictClassname(rocket, classname, sizeof(classname));

// 		if(StrContains(classname, "tf_projectile_") != -1)
// 		{
// 			AcceptEntityInput(rocket, "Kill");
// 		}
// 	}
// }
