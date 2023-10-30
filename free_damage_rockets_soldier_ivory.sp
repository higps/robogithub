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


#define ExplodeSound	"ambient/explosions/explode_8.wav"
#define SENTRYROCKETS "models/buildables/sentry3_rockets.mdl"

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
bool g_rocketCurve;
ConVar g_showDebug;
ConVar g_rocketAngle;
ConVar g_rocketDiverge;

#define GUNFIRE	"weapons/sentry_rocket.wav"
#define GUNFIRE_CRIT	"weapons/sentry_rocket.wav"

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

public OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

	LoadTranslations("common.phrases");


	g_rocketDelay = CreateConVar("ivory_mirv_rocket_delay", "0.6", "Delay before a mirv rocket splits into other rockets");
	g_rocketCount = CreateConVar("ivory_mirv_rocket_count", "4", "How many rockets a mirv rocket splits into", _, true, 2.0, true, 6.0);
	g_rocketCurve = true;
	//g_rocketCurve = CreateConVar("mirv_converge_rockets", "0", "Do rockets converge on a single point after splitting", _, true, 0.0, true, 1.0);
	g_showDebug = CreateConVar("ivory_mirv_converge_debug", "0", "Show debug angles and trajectory for converging rockets", _, true, 0.0, true, 1.0);
	g_rocketAngle = CreateConVar("ivory_mirv_split_angle", "60.0", "Positive angle from the down vector at which mirv rockets will split at (0.0 = directly down, 90.0 = no deviation)");
	g_rocketDiverge = CreateConVar("ivory_mirv_split_variance", "10.0", "Random angle variance added onto mirv rockets");
	//HookConVarChange(g_rocketCurve, OnMirvSettingsChanged);

	ShouldMirvConverge =  view_as<bool>(g_rocketCurve);

	ExplodeSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound(ExplodeSound);



	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			OnClientPostAdminCheck(client);
		}
	}


}

public OnMapStart()
{

	ExplodeSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	glow = PrecacheModel("materials/sprites/laser.vmt");
	PrecacheSound(ExplodeSound);
	PrecacheModel(SENTRYROCKETS);
}

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

// #define ExplodeSound	"ambient/explosions/explode_8.wav"

public void OnMirvSettingsChanged(ConVar convar, char[] oldVal, char[] newVal)
{
	int cvarValue = StringToInt(newVal);
	ShouldMirvConverge = view_as<bool>(cvarValue);
}

bool g_PushButton[MAXPLAYERS + 1] = {false, ...};

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME) && buttons & (IN_ATTACK3|IN_USE) && !g_PushButton[client])
	{
		
		if (g_rocketCurve == true)
		{	
			g_rocketCurve = false;
			ShouldMirvConverge = false;
			PrintCenterText(client, "MIRV MODE:  MORTAR");
		}else{
			g_rocketCurve = true;
			ShouldMirvConverge = true;
			PrintCenterText(client, "MIRV MODE: CONVERGE");
		}
		g_PushButton[client] = true;
		CreateTimer(0.2, Button_Reset, client);
	}
	


	if (IsRobot(client, ROBOT_NAME) && buttons & IN_ATTACK2 && !g_PushButton[client])
	{
		
		//Loop through all rockets
		int i = 1;
		while (((i = FindEntityByClassname(i, "tf_projectile_rocket")) != -1))
		{
			
			int owner = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
			if (owner == client){
				
				if (IsValidRocket(i) && RocketOverride[i])
				{

				SplitRocket(i, ShouldMirvConverge);
				// PrintToChatAll("Splitting rocket for %i",i);
				}
				
				
			}
			g_PushButton[client] = true;
			CreateTimer(0.2, Button_Reset, client);
		}

	}
	return Plugin_Continue;
}


public Action Button_Reset(Handle timer, int client)
{
	g_PushButton[client] = false;

	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	PlayerHasMirv[client] = false;
}

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
	//	CreateTimer(GetConVarFloat(g_rocketDelay), RocketTimer, ref, TIMER_FLAG_NO_MAPCHANGE);
		RequestFrame(SetProjectileModel, rocket);
		
	}
}

void SetProjectileModel (int iEntity)
{
	if(IsValidEntity(iEntity))
	{
		SetEntityModel(iEntity, SENTRYROCKETS);
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 2.0);
	}
}

public Action RocketTimer(Handle timer, any ref)
{
	// int rocket = EntRefToEntIndex(ref);
	// //PrintToChatAll("Rocket: %i", rocket);
	// if (IsValidRocket(rocket) && RocketOverride[rocket])
	// {
	// 	SplitRocket(rocket, g_rocketCurve);
	// }
	return Plugin_Continue;
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

	int launcher = GetEntPropEnt(rocket, Prop_Send, "m_hLauncher");

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
		SetVariantInt(team);
		AcceptEntityInput(mirv, "SetTeam");
		
		SetEntPropEnt(mirv, Prop_Send, "m_hOwnerEntity", owner);
		SetEntPropEnt(mirv, Prop_Send, "m_hLauncher", launcher);
		SetEntPropEnt(mirv, Prop_Send, "m_hOriginalLauncher", launcher);

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
