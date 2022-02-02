#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Ivory"
#define ROBOT_ROLE "Damage"
#define ROBOT_DESCRIPTION "MIRV Rocket Launcher"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"


#define ExplodeSound	"ambient/explosions/explode_8.wav"

bool PlayerHasMirv[MAXPLAYERS+1];
bool RocketOverride[2049];
bool MirvRocket[2049];
bool MirvConverge[2049];

bool ShouldMirvConverge;

float ConvergePoint[2049][3];
float MinFlightTime[2049];

int ExplodeSprite;
int glow;

ConVar g_rocketDelay;
ConVar g_rocketCount;
int g_rocketCurve;
ConVar g_showDebug;
ConVar g_rocketAngle;
ConVar g_rocketDiverge;

// #define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
// #define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
// #define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Basic Soldier",
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


    AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION);


	g_rocketDelay = CreateConVar("mirv_rocket_delay", "0.6", "Delay before a mirv rocket splits into other rockets");
	g_rocketCount = CreateConVar("mirv_rocket_count", "5", "How many rockets a mirv rocket splits into", _, true, 2.0, true, 6.0);
	g_rocketCurve = 1;
	//g_rocketCurve = CreateConVar("mirv_converge_rockets", "0", "Do rockets converge on a single point after splitting", _, true, 0.0, true, 1.0);
	g_showDebug = CreateConVar("mirv_converge_debug", "0", "Show debug angles and trajectory for converging rockets", _, true, 0.0, true, 1.0);
	g_rocketAngle = CreateConVar("mirv_split_angle", "60.0", "Positive angle from the down vector at which mirv rockets will split at (0.0 = directly down, 90.0 = no deviation)");
	g_rocketDiverge = CreateConVar("mirv_split_variance", "10.0", "Random angle variance added onto mirv rockets");
	//HookConVarChange(g_rocketCurve, OnMirvSettingsChanged);

	ShouldMirvConverge =  view_as<bool>(g_rocketCurve);

	ExplodeSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound(ExplodeSound);

	//Events
	// AddCommandListener(MirvModeToggle, "+use");
	// AddCommandListener(MirvModeToggle, "+attack2");
	// AddCommandListener(MirvModeToggle, "+reload");

	//RegConsoleCmd("sm_mirv", CmdControl);

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

	// PrecacheSound(GUNFIRE);
	// PrecacheSound(GUNFIRE_CRIT);
	// PrecacheSound(GUNFIRE_EXPLOSION);
	

	PrecacheSound(LEFTFOOT);
	PrecacheSound(LEFTFOOT1);
	PrecacheSound(RIGHTFOOT);
	PrecacheSound(RIGHTFOOT1);
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);

	ExplodeSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	glow = PrecacheModel("materials/sprites/laser.vmt");
	PrecacheSound(ExplodeSound);
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

	float scale = 1.75;
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.1);
float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	//TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	//
	TF2Attrib_SetByName(client, "head scale", 0.75);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	//TF2Attrib_SetByName(client, "head scale", 0.5);
	UpdatePlayerHitbox(client,scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , "Your rockets explodes in to more rockets!\nUse M2, reload or special attack to change modes!");
	
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

#define WhirlyWarrior 30118
#define GourdGrin 31127
#define Flakcatcher 30853
 


stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_rocketlauncher", 18, 6, 1, 2, 0);

		CreateRoboHat(client, WhirlyWarrior, 10, 6, 2960676.0, 1.0, -1.0);
		CreateRoboHat(client, GourdGrin, 10, 6, 2960676.0, 1.0, -1.0);
		CreateRoboHat(client, Flakcatcher, 10, 6, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		
		if(IsValidEntity(Weapon1))
		{

			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.00);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 1.5);				
			TF2Attrib_SetByName(Weapon1, "Projectile speed decreased", 0.75);				
			
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
		}

	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));
	

#pragma semicolon 1
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>

public Plugin MyInfo =
{
	name = "MIRV Rockets",
	author = "IvoryPal",
	description = "Rockets split into smaller rockets after a short delay."
};

#define ExplodeSound	"ambient/explosions/explode_8.wav"

public void OnMirvSettingsChanged(ConVar convar, char[] oldVal, char[] newVal)
{
	int cvarValue = StringToInt(newVal);
	ShouldMirvConverge = view_as<bool>(cvarValue);
}

bool g_PushButton[MAXPLAYERS + 1] = false;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME) && buttons & (IN_ATTACK3|IN_RELOAD|IN_USE|IN_ATTACK2) && !g_PushButton[client])
	{
		if (g_rocketCurve == 1)
		{	
			g_rocketCurve = 0;
			ShouldMirvConverge = false;
			PrintCenterText(client, "MIRV MODE:  MORTAR");
		}else{
			g_rocketCurve = 1;
			ShouldMirvConverge = true;
			PrintCenterText(client, "MIRV MODE: CONVERGE");
		}
		g_PushButton[client] = true;
		CreateTimer(0.2, Button_Reset, client);
		
		
	}
}


public Action Button_Reset(Handle timer, int client)
{
	g_PushButton[client] = false;
}

public void OnClientPostAdminCheck(int client)
{
	PlayerHasMirv[client] = false;
}

// Action CmdControl(int client, int args)
// {
// 	if (TF2_GetPlayerClass(client) != TFClass_Soldier)
// 	{
// 		PrintToChat(client, "[SM] You must be a soldier to use this command!");
// 	}
// 	else
// 	{
// 		PlayerHasMirv[client] = !PlayerHasMirv[client];
// 		PrintToChat(client, "[SM] MIRV Rockets %s!", PlayerHasMirv[client] ? "enabled" : "disabled");
// 	}
// }

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!(StrContains(classname, "tf_projectile_rocket")) || !(StrContains(classname, "tf_projectile_energy_ball")))
	{
		//SDKHook(entity, SDKHook_SpawnPost, OnRocketSpawned);
		RequestFrame(OnRocketSpawned, entity);
		SDKHook(entity, SDKHook_Touch, OnRocketEnd);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || entity > 2048) return; //prevent ent refs being used
	if (IsValidEntity(entity))
	{
		RocketOverride[entity] = false;
		MirvRocket[entity] = false;
		MirvConverge[entity] = false;
	}
}

public void OnRocketSpawned(int rocket)
{
	if (!HasEntProp(rocket, Prop_Send, "m_hOwnerEntity")) return; //prevent errors if this function somehow hooks an entity that isn't a rocket
	
	int owner = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(owner)) return;

	if (IsRobot(owner, ROBOT_NAME) && !MirvRocket[rocket])
	{
		//PrintToChat(owner, "Rocket Spawned");
		RocketOverride[rocket] = true;
		int ref = EntIndexToEntRef(rocket);
		CreateTimer(GetConVarFloat(g_rocketDelay), RocketTimer, ref, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action RocketTimer(Handle timer, any ref)
{
	int rocket = EntRefToEntIndex(ref);
	//PrintToChatAll("Rocket: %i", rocket);
	if (IsValidRocket(rocket) && RocketOverride[rocket])
	{
		SplitRocket(rocket, g_rocketCurve);
	}
}

void SplitRocket(int rocket, bool converge)
{
	float pos[3], rocketAngle[3], convergePos[3], rocketVel[3], speed;
	char classname[64], netname[64];
	int owner = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(owner)) return;
	if (!IsValidEntity(rocket) || rocket < MaxClients) return;

	GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(rocket, Prop_Send, "m_angRotation", rocketAngle);
	GetEntPropVector(rocket, Prop_Data, "m_vecVelocity", rocketVel);
	speed = GetVectorLength(rocketVel);
	int crit = 0;
	if (HasEntProp(rocket, Prop_Send, "m_bCritical"))
		crit = GetEntProp(rocket, Prop_Send, "m_bCritical");
	GetEntityClassname(rocket, classname, sizeof classname);
	GetEntityNetClass(rocket, netname, sizeof netname);
	RocketOverride[rocket] = false;
	AcceptEntityInput(rocket, "Kill");

	//converge
	float variance;
	if (converge)
	{
		SetupConvergePoint(pos, rocketAngle, 2500.0, convergePos, owner);
		variance = ClampFloat((GetVectorDistance(pos, convergePos) / 5.0), 3.0, 30.0);
	}
	else
		rocketAngle[0] = (89.0 - GetConVarFloat(g_rocketAngle));

	EmitSoundToAll(ExplodeSound, rocket);
	TE_SetupExplosion(pos, ExplodeSprite, 3.0, 1, 0, 1, 1);
	TE_SendToAll();
	int count = GetConVarInt(g_rocketCount);
	float angVar = GetConVarFloat(g_rocketDiverge);
	//PrintToChat(owner, "Mirv count: %i", count);
	for (int i = 1; i <= count; i++)
	{
		float angles[3], newPos[3];
		for (int axis = 0; axis <= 2; axis++)
		{
			newPos[axis] = pos[axis] + GetRandomFloat(-3.0, 3.0); //prevent rockets from colliding with each other
			if (converge) //much larger spread if rockets converge on a point
				angles[axis] = rocketAngle[axis] + GetRandomFloat((-1.0 * variance), variance);
			else
				angles[axis] = rocketAngle[axis] + GetRandomFloat((-1.0 * angVar), angVar);
		}

		int mirv = CreateEntityByName(classname);
		MirvRocket[mirv] = true;
		int team = GetClientTeam(owner);
		SetVariantInt(team);
		AcceptEntityInput(mirv, "TeamNum");
		AcceptEntityInput(mirv, "SetTeam");
		SetEntPropEnt(mirv, Prop_Send, "m_hOwnerEntity", owner);
		float vel[3];
		GetAngleVectors(angles, vel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vel, speed);
		TeleportEntity(mirv, newPos, angles, vel);
		DispatchSpawn(mirv);
		if (HasEntProp(rocket, Prop_Send, "m_bCritical"))
			SetEntProp(mirv, Prop_Send, "m_bCritical", crit);
		SetEntDataFloat(mirv, FindSendPropInfo(netname, "m_iDeflected") + 4, 50.0);

		if (converge)
		{
			MirvConverge[mirv] = true;
			MinFlightTime[mirv] = GetEngineTime() + 1.0;
			ConvergePoint[mirv][0] = convergePos[0] += GetRandomFloat(-20.0, 20.0);
			ConvergePoint[mirv][1] = convergePos[1] += GetRandomFloat(-20.0, 20.0);
			ConvergePoint[mirv][2] = convergePos[2] += GetRandomFloat(-20.0, 20.0);
		}
	}
}

public bool FilterCollision(int entity, int ContentsMask)
{
	if (entity == 0)
	{
		return true;
	}
	return false;
}

void SetupConvergePoint(float pos[3], float angle[3], float range, float bufferPos[3], int owner)
{
	float forwardPos[3];
	GetAngleVectors(angle, forwardPos, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(forwardPos, range);
	AddVectors(pos, forwardPos, forwardPos);
	Handle trace = TR_TraceRayFilterEx(pos, forwardPos, MASK_PLAYERSOLID, RayType_EndPoint, FilterCollision);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(bufferPos, trace);
		if (GetConVarBool(g_showDebug))
		{
			//TE_SetupBeamPoints(pos, bufferPos, glow, glow, 0, 1, 5.0, 5.0, 5.0, 10, 0.0, {0, 255, 0, 255}, 10);
			//TE_SendToClient(owner);
		}
		CloseHandle(trace);
		return;
	}
	if (GetConVarBool(g_showDebug))
	{
		TE_SetupBeamPoints(pos, forwardPos, glow, glow, 0, 1, 5.0, 5.0, 5.0, 10, 0.0, {255, 0, 0, 255}, 10);
		TE_SendToClient(owner);
	}
	CloseHandle(trace);
	bufferPos = forwardPos;
	return;
}

public void OnGameFrame()
{
	if (ShouldMirvConverge)
	{
		int rocket = MaxClients + 1;
		while (((rocket = FindEntityByClassname(rocket, "tf_projectile_rocket")) != -1))
		{
			if (MirvConverge[rocket])
			{
				ConvergeRocket(rocket);
			}
		}
		rocket = MaxClients + 1;
		while (((rocket = FindEntityByClassname(rocket, "tf_projectile_energy_ball")) != -1))
		{
			if (MirvConverge[rocket])
			{
				ConvergeRocket(rocket);
			}
		}
	}
}

void ConvergeRocket(int rocket)
{
	if (IsValidEntity(rocket) && MirvConverge[rocket])
	{
		float curPos[3], curAngle[3], trajectory[3], vel[3], speed;
		GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", curPos);
		GetEntPropVector(rocket, Prop_Data, "m_angRotation", curAngle);
		GetEntPropVector(rocket, Prop_Data, "m_vecAbsVelocity", vel);
		speed = GetVectorLength(vel);

		MakeVectorFromPoints(curPos, ConvergePoint[rocket], trajectory);
		NormalizeVector(trajectory, trajectory);
		float distance = ClampFloat(GetMagnitudeFromDistance(GetVectorDistance(curPos, ConvergePoint[rocket])), 35.0, 400.0);
		ScaleVector(trajectory, distance);
		AddVectors(curPos, trajectory, curPos);

		AddVectors(vel, trajectory, vel);
		NormalizeVector(vel, vel);
		GetVectorAngles(vel, curAngle);
		ScaleVector(vel, speed);
		TeleportEntity(rocket, NULL_VECTOR, curAngle, vel);

		//Check angles between forward vector of rocket and vector to converge point
		float forwardVec[3], angleVec[3];
		GetAngleVectors(curAngle, forwardVec, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(forwardVec, 150.0);
		AddVectors(curPos, forwardVec, forwardVec);
		angleVec = trajectory;
		NormalizeVector(angleVec, angleVec);
		ScaleVector(angleVec, 150.0);
		AddVectors(curPos, angleVec, angleVec);

		if (GetConVarBool(g_showDebug))
		{
			//forward visual
			TE_SetupBeamPoints(curPos, forwardVec, glow, glow, 0, 1, 5.0, 5.0, 5.0, 10, 0.0, {100, 0, 200, 255}, 10);
			TE_SendToAll();
			//converge vector
			TE_SetupBeamPoints(curPos, angleVec, glow, glow, 0, 1, 5.0, 5.0, 5.0, 10, 0.0, {255, 255, 0, 255}, 10);
			TE_SendToAll();
		}

		NormalizeVector(forwardVec, forwardVec);
		NormalizeVector(angleVec, angleVec);
		float dot = GetVectorDotProduct(forwardVec, angleVec) / GetVectorLength(forwardVec, true);
		float deg = RadToDeg(ArcCosine(dot));
		if ((deg <= 1.35 || deg >= 7.0) && MinFlightTime[rocket] <= GetEngineTime()) //stop converging once the angle is small enough
			MirvConverge[rocket] = false;
	}
}

float GetMagnitudeFromDistance(float distance)
{
	float magnitude;
	magnitude = 600.0 / distance;
	return magnitude;
}

public Action OnRocketEnd(int rocket, int victim)
{
	if (RocketOverride[rocket])
	{
		if (!IsValidClient(victim))
		{
			char classname[64];
			GetEntityClassname(victim, classname, sizeof classname);
			if (victim == 0 || !StrContains(classname, "prop_", false) || !StrContains(classname, "obj_", false) || !StrContains(classname, "func_door")) //solid props
			{
					RocketOverride[rocket] = false;
			}
		}
	}
	return Plugin_Continue;
}

bool IsValidRocket(int rocket)
{
	if (!IsValidEntity(rocket))
		return false;
	if (RocketOverride[rocket] && rocket > MaxClients)
		return true;

	return false;
}

float ClampFloat(float value, float min, float max)
{
	if (value > max) return max;
	if (value < min) return min;
	return value;
}
