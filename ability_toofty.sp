#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME "Toofty"


public Plugin:myinfo =
{
	name = "[TF2] Toofty Ability",
	author = "HiGPS | Bmod.TF",
	description = "Adds logic for spies",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (condition == TFCond_Parachute)
    {

		if (IsValidToofty(client))
		{
			// PrintToChatAll("apply");
			int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
			TF2Attrib_SetByName(Weapon1, "fuse bonus", 2.5);
			TF2Attrib_SetByName(Weapon1, "clip size bonus", 3.0);
		}
		
		
		
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_Parachute)
	{
		if (IsValidToofty(client))
		{
			// PrintToChatAll("remove");
			int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
			TF2Attrib_SetByName(Weapon1, "fuse bonus", 0.7);
			TF2Attrib_SetByName(Weapon1, "clip size bonus", 1.0);
		}
	}
}

public bool IsValidToofty(int client)
{
	if (IsRobot(client, ROBOT_NAME))
	{
		return true;
	}else
	{
		return false;
	}
}