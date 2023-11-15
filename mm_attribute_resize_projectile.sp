#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>

#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included

float g_Size = 0.0;
int g_UpdateHitBox = 0;


bool ActiveHasStatClient(int client)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "projectile-size", stat_buffer, sizeof(stat_buffer))) {
	return false;
	}
	g_Size = ReadFloatVar(stat_buffer, "size", 1.0);
	g_UpdateHitBox = ReadIntVar(stat_buffer, "update-hitbox", 1);
	// g_UpdateHitBox = ReadIntVar(stat_buffer, "update-hitbox", 1);

	// g_bmod_disciplinary = ReadIntVar(stat_buffer, "bmod-disciplinary", 0);
	return true;
}

stock bool IsValidClient(iClient)
{
	return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
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

	if (0 < iClient && iClient <= MaxClients && ActiveHasStatClient(iClient)) {
		
		// PrintToChatAll("SETTING SCALE")
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", g_Size);
		if (g_UpdateHitBox)RequestFrame(SetProjectileSize, iEntity);
	}
}



void SetProjectileSize (int iEntity)
{


		// PrintToChatAll("SETTING HITBOX SIZE")
		// g_fStockvecMin[0] = -g_Size + -g_Size;
		// g_fStockvecMin[1] = -g_Size + -g_Size;
		// g_fStockvecMin[2] = -g_Size + -g_Size;
// ScaleVector(g_fStockvecMin, -g_Size;)
// ScaleVector(g_fStockvecMax, g_Size;)
		// g_fStockvecMax[0] = g_Size + g_Size;
		// g_fStockvecMax[1] = g_Size + g_Size;
		// g_fStockvecMax[2] = g_Size + g_Size;

		// g_fStockvecMin[0] = -500.0;
		// g_fStockvecMin[1] = -500.0;
		// g_fStockvecMin[2] = -500.0;

		// g_fStockvecMax[0] = 500.0;
		// g_fStockvecMax[1] = 500.0;
		// g_fStockvecMax[2] = 500.0;
		float g_fStockvecMin[3] = {-1.0, -1.0, -1.0};
		float g_fStockvecMax[3] = {1.0, 1.0, 1.0};
		ScaleVector(g_fStockvecMin, g_Size);
		ScaleVector(g_fStockvecMax, g_Size);

		SetEntPropVector(iEntity, Prop_Send, "m_vecMins", g_fStockvecMin);
		SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", g_fStockvecMax);
	
}