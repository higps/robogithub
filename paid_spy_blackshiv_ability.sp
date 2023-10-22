#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
#include <dhooks>
#include <tf_ontakedamage.inc>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Black Shiv"

bool g_PressedButton[MAXPLAYERS + 1] = {false, ...};

public Plugin:myinfo =
{
	name = "[TF2] BlackShiv Ability",
	author = "HiGPS | Bmod.TF",
	description = "BlackShiv Ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

//bool g_bisGSPY[MAXPLAYERS + 1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}



public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME) && buttons & (IN_ATTACK3|IN_USE))
	{
		if (!g_PressedButton[client])
		{
		FakeClientCommand(client, "use tf_weapon_grapplinghook");
		CreateTimer(1.0, Timer_Button, client);
		}
		g_PressedButton[client] = true;
	}
	return Plugin_Continue;
}

public Action Timer_Button(Handle timer, any client)
{
	g_PressedButton[client] = false;
	return Plugin_Continue;
}
