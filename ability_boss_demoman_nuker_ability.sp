#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Nuker"

#define BLU_MODEL	"models/props_trainyard/bomb_cart.mdl"
#define RED_MODEL "models/props_trainyard/bomb_cart_red.mdl"
// #define PMODEL "models/props_td/atom_bomb.mdl"

int g_iTeam;

public Plugin:myinfo =
{
	name = "[TF2] Nuker Payload Model Swap",
	author = "HiGPS | Bmod.TF",
	description = "Nuker payload model swap",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnMapStart()
{
	PrecacheModel(RED_MODEL);
	PrecacheModel(BLU_MODEL);

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
	//	SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.75);

		g_iTeam = GetClientTeam(iClient);
		RequestFrame(SetProjectileModel, iEntity);
	}
}
float g_fStockvecMin[3] = {-10.0, -10.0, -10.0};
float g_fStockvecMax[3] = {10.0, 10.0, 10.0};

void SetProjectileModel (int iEntity)
{
	if(g_iTeam == 2)
	{
		SetEntityModel(iEntity, RED_MODEL);
		
	}else
	{
		SetEntityModel(iEntity, BLU_MODEL);
	}


	SetEntPropVector(iEntity, Prop_Send, "m_vecMins", g_fStockvecMin);
	SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", g_fStockvecMax);

}
