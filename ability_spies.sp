#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Robot Spy logic",
	author = "HiGPS | Bmod.TF",
	description = "Adds logic for spies",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}




public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobotSpy(client, condition))
    {
		PrintToChatAll("Spy added cloak");	
		TF2Attrib_AddCustomPlayerAttribute(client, "health regen", 75.0);
	}
}

public bool IsRobotSpy(int client, TFCond condition)
{
	if (TF2_GetPlayerClass(client) == TFClass_Spy && IsAnyRobot(client) && condition == TFCond_Cloaked)
	{
		return true;
	}else
	{
		return false;
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if (IsRobotSpy(client, condition))
    {
		PrintToChatAll("Spy removed cloak");
		TF2Attrib_RemoveCustomPlayerAttribute(client, "health regen");
	}
}