#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>
#include <vphysics>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Zero G"

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
