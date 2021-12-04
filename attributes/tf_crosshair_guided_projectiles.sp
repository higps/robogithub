#pragma semicolon 1
#pragma newdecls required

#include <cecon_items>
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

public Plugin myinfo =
{
	name = "[CE Attribute] crosshair guided projectiles",
	author = "Creators.TF Team",
	description = "crosshair guided projectiles",
	version = "1.00",
	url = "https://creators.tf"
};

#define MAX_ENTITY_LIMIT 2048

bool g_bHomingEnabled[MAX_ENTITY_LIMIT + 1];
float g_flHomingAccuracy[MAX_ENTITY_LIMIT + 1];
int g_iLauncher[MAX_ENTITY_LIMIT + 1];

float g_flHomingPoint[MAX_ENTITY_LIMIT + 1][3];
int g_iLatestProjectile[MAX_ENTITY_LIMIT + 1];

Handle g_KillTimer[MAX_ENTITY_LIMIT + 1];

int g_iBlueGlowModelID = -1;
int g_iRedGlowModelID = -1;

public void OnPluginStart()
{
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	static bool bPressed[MAXPLAYERS + 1] =  { false, ... };
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if (CEconItems_GetEntityAttributeFloat(weapon, "crosshair guided projectiles") > 0.0)
		{
			if(buttons & IN_ATTACK2)
			{
				if(!bPressed[client])
				{
					if(IsValidEntity(g_iLatestProjectile[weapon]))
					{
						g_bHomingEnabled[g_iLatestProjectile[weapon]] = true;
						GetPlayerEyePosition(client, g_flHomingPoint[g_iLatestProjectile[weapon]]);
					}else{
						ClientCommand(client, "playgamesound common/wpn_denyselect.wav");
					}
					bPressed[client] = true;
				}
			}else bPressed[client] = false;

			if (!TF2_IsPlayerInCondition(client, TFCond_Taunting) && !TF2_IsPlayerInCondition(client, TFCond_Taunting))
			{
				float flTargetPos[3];
				GetPlayerEyePosition(client, flTargetPos);

				if (GetClientTeam(client) == 2) TE_SetupGlowSprite( flTargetPos, g_iRedGlowModelID, 0.1, 0.17, 75 );
				else TE_SetupGlowSprite( flTargetPos, g_iBlueGlowModelID, 0.1, 0.17, 25 );

				TE_SendToClient(client);
			}
		}
	}
}

public void OnMapStart()
{
	g_iBlueGlowModelID = PrecacheModel("sprites/blueglow1.vmt");
	g_iRedGlowModelID = PrecacheModel("sprites/redglow1.vmt");
}

public void OnClientPutInServer(int iClient)
{
}

public void OnClientDisconnect(int iClient)
{
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity < 1) return;

	g_iLauncher[entity] = 0;
	g_bHomingEnabled[entity] = false;
	g_flHomingAccuracy[entity] = 0.0;
	g_iLatestProjectile[entity] = INVALID_ENT_REFERENCE;

	if (StrContains(classname, "tf_projectile_") != -1)
	{
		CreateTimer(0.001, Timer_OnSpawn, entity);
	}
}

public Action Timer_OnSpawn(Handle timer, any entity)
{
	if (!IsValidEdict(entity))return;
	int iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (iOwner > 0 && iOwner <= MaxClients)
	{
		int weapon = GetEntPropEnt(iOwner, Prop_Data, "m_hActiveWeapon");
		if(IsValidEdict(weapon))
		{
			float flPower = CEconItems_GetEntityAttributeFloat(weapon, "crosshair guided projectiles");
			if(flPower > 0.0)
			{
				g_iLauncher[entity] = weapon;
				g_bHomingEnabled[entity] = false;
				g_flHomingAccuracy[entity] = flPower;
				g_iLatestProjectile[weapon] = entity;
			}
			float flLifetime = CEconItems_GetEntityAttributeFloat(weapon, "projectile lifetime");
			if(flLifetime > 0.0)
			{
				g_KillTimer[entity] = CreateTimer(flLifetime, Timer_ExplodeProjectile, entity);
			}
		}
	}
}

public Action Timer_ExplodeProjectile(Handle timer, any rocket)
{
	g_KillTimer[rocket] = INVALID_HANDLE;
	if(IsValidEdict(rocket))
	{
		char classname[256];
		GetEdictClassname(rocket, classname, sizeof(classname));

		if(StrContains(classname, "tf_projectile_") != -1)
		{
			AcceptEntityInput(rocket, "Kill");
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity > 0)
	{
		if (g_KillTimer[entity] != INVALID_HANDLE) {
			CloseHandle(g_KillTimer[entity]);
			g_KillTimer[entity] = INVALID_HANDLE;
		}

		for (int i = 0; i < MAX_ENTITY_LIMIT; i++)
		{
			if (g_iLatestProjectile[i] == entity)g_iLatestProjectile[i] = INVALID_ENT_REFERENCE;
		}

		g_iLauncher[entity] = 0;
		g_bHomingEnabled[entity] = false;
		g_flHomingAccuracy[entity] = 0.0;
		g_iLatestProjectile[entity] = INVALID_ENT_REFERENCE;
	}
}

public void OnGameFrame()
{
	int entity;
	while ((entity = FindEntityByClassname(entity, "tf_projectile_*")) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(g_iLauncher[entity]))
		{
			if(g_bHomingEnabled[entity])
			{
				int iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
				if (iOwner == -1)continue;
				int iActiveWeapon = GetEntPropEnt(iOwner, Prop_Data, "m_hActiveWeapon");

				if (iActiveWeapon != g_iLauncher[entity])continue;
				if(
					!IsClientInGame(iOwner) ||
					!IsPlayerAlive(iOwner) ||
					(
						HasEntProp(entity, Prop_Send, "m_iDeflected") &&
						GetEntProp(entity, Prop_Send, "m_iDeflected") == 1
					)
				)
				{
					g_bHomingEnabled[entity] = false;
					continue;
				}

				float flRocketAng[3];
				float flRocketVec[3];
				float flRocketPos[3];

				float flTargetPos[3];
				float flTargetVec[3];

				for (int i = 0; i < 3; i++)flTargetPos[i] = g_flHomingPoint[entity][i];

				GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", flRocketPos);
				GetEntPropVector(entity, Prop_Data, "m_angRotation", flRocketAng);
				GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", flRocketVec);
				float flRocketSpeed = GetVectorLength( flRocketVec );

				SubtractVectors(flTargetPos, flRocketPos, flTargetVec);
				ScaleVector(flTargetVec, g_flHomingAccuracy[entity]);
				AddVectors(flTargetVec, flRocketVec, flRocketVec);
				NormalizeVector(flRocketVec, flRocketVec);
				GetVectorAngles(flRocketVec, flRocketAng);
				ScaleVector(flRocketVec, flRocketSpeed);

				SetEntPropVector(entity, Prop_Data, "m_angRotation", flRocketAng);

				SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", flRocketVec);
			}
		}
	}
}

bool GetPlayerEyePosition(int client, float pos[3])
{
	float vAngles[3], vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		delete trace;
		return true;
	}
	delete trace;
	return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data)
{
	if (entity <= 0) return true;
	if (entity == data) return false;

	char sClassname[128];
	GetEdictClassname(entity, sClassname, sizeof(sClassname));
	if (StrEqual(sClassname, "func_respawnroomvisualizer", false)) return false;
	else return true;
}
