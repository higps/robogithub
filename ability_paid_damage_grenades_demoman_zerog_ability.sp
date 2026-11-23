#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>
#include <sdktools>
#include <vphysics>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Zero G"
#define PUSH_SPEED 800.0
#define AIM_RANGE 8192.0
#define STICKY_PUSH_COOLDOWN 0.5
#define STICKY_TRAIL_RED "stickybombtrail_red"
#define STICKY_TRAIL_BLUE "stickybombtrail_blue"

float g_StickyReadyTime[MAXPLAYERS + 1];
int g_StickyTrailRef[2048];

public Plugin:myinfo =
{
	name = "[TF2] ZeroG sticky ability",
	author = "HiGPS | Bmod.TF",
	description = "No grav sticks",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public void OnEntityCreated(int iEntity, const char[] sClassName) 
{
	if (StrContains(sClassName, "tf_projectile") == 0)
	{
		SDKHook(iEntity, SDKHook_Spawn, Hook_OnProjectileSpawn);
	}
	
}

public void Hook_OnProjectileSpawn(iEntity) {
	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
	if (0 < iClient && iClient <= MaxClients && IsRobot(iClient, ROBOT_NAME)) {
		
		RequestFrame(SetGrav, iEntity);
	}
}

void SetGrav(int iEntity)
{
	Phys_EnableGravity(iEntity, false);
	SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.25);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		DrawHUD(client);
		if ((GetEntProp(client, Prop_Data, "m_afButtonPressed") & (IN_RELOAD|IN_USE|IN_ATTACK3)) && GetEngineTime() >= g_StickyReadyTime[client])
		{
			PushStickies(client);
			g_StickyReadyTime[client] = GetEngineTime() + STICKY_PUSH_COOLDOWN;
		}
	}
	return Plugin_Continue;
}

void DrawHUD(int client)
{
	char sHUDText[128];
	float remaining = g_StickyReadyTime[client] - GetEngineTime();
	float ownerVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", ownerVel);
	float speedBonus = GetVectorLength(ownerVel);

	if (remaining > 0.0)
	{
		Format(sHUDText, sizeof(sHUDText), "M3/USE to push sticks\nRedirect Speed Bonus: %.0f\nReady in %.1fs", speedBonus, remaining);
		SetHudTextParams(1.0, 0.7, 1.0, 255, 0, 0, 255);
	}
	else
	{
		Format(sHUDText, sizeof(sHUDText), "M3/USE to push sticks\nRedirect Speed Bonus: %.0f", speedBonus);
		SetHudTextParams(1.0, 0.7, 1.0, 0, 255, 0, 255);
	}
	ShowHudText(client, -2, sHUDText);
}

void PushStickies(int client)
{
	PrintToChatAll("Pushing sticks");
	float eyePos[3], eyeAng[3], aimVec[3], aimPos[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	GetAngleVectors(eyeAng, aimVec, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(aimVec, AIM_RANGE);
	AddVectors(eyePos, aimVec, aimPos);

	// Trace to the aim point so stickies are pushed toward what the robot is looking at
	Handle trace = TR_TraceRayFilterEx(eyePos, aimPos, MASK_SHOT, RayType_EndPoint, TraceFilter_IgnoreOwner, client);
	TR_GetEndPosition(aimPos, trace);
	CloseHandle(trace);

	int sticky = MaxClients + 1;
	float ownerVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", ownerVel);
	while ((sticky = FindEntityByClassname(sticky, "tf_projectile_pipe_remote")) != -1)
	{
		PrintToChatAll("while test");
		if (GetEntPropEnt(sticky, Prop_Data, "m_hThrower") != client)
		{
			PrintToChatAll("true 1");
			continue;
		}
		// Stuck stickies have m_bTouched set; only push ones still in flight
		if (GetEntProp(sticky, Prop_Send, "m_bTouched"))
		{
			PrintToChatAll("true 2");
			continue;
		}
		PrintToChatAll("Found bomb");
		// Stickies are VPhysics objects, so velocity must be applied through vphysics; TeleportEntity is overridden by the simulation
		float stickyPos[3], dir[3];
		GetEntPropVector(sticky, Prop_Data, "m_vecOrigin", stickyPos);

		MakeVectorFromPoints(stickyPos, aimPos, dir);
		NormalizeVector(dir, dir);
		ScaleVector(dir, PUSH_SPEED);
		// Robot's own velocity is added so moving fast redirects stickies harder
		AddVectors(dir, ownerVel, dir);

		Phys_AddVelocity(sticky, dir, NULL_VECTOR);
		AttachStickyTrail(sticky, client);
	}
}

void AttachStickyTrail(int sticky, int client)
{
	int oldTrail = EntRefToEntIndex(g_StickyTrailRef[sticky]);
	if (oldTrail > MaxClients && IsValidEntity(oldTrail))
	{
		RemoveEntity(oldTrail);
	}

	int particle = CreateEntityByName("info_particle_system");
	if (particle == -1)
	{
		return;
	}

	float pos[3];
	GetEntPropVector(sticky, Prop_Data, "m_vecOrigin", pos);
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(particle, "effect_name", TF2_GetClientTeam(client) == TFTeam_Red ? STICKY_TRAIL_RED : STICKY_TRAIL_BLUE);
	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", sticky, particle, 0);

	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");

	g_StickyTrailRef[sticky] = EntIndexToEntRef(particle);
}

public bool TraceFilter_IgnoreOwner(int entity, int contentsMask, any data)
{
	return entity != data;
}
