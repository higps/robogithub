#pragma semicolon 1
#include <tf2_stocks>
#include <berobot_constants>
#include <berobot>
#include <sourcemod>
#include <tf2>

 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Dr. Crossbow Cop"

public Plugin:myinfo =
{
	name = "[TF2] Dr. Crossbow Cop Ability",
	author = "HiGPS | Bmod.TF",
	description = "Crossbowcop Ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("post_inventory_application", Event_PlayerSpawn);
	HookEvent("crossbow_heal", Event_Crossbow_Heal, EventHookMode_Post);
}



bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
int g_Heal_Bolts_Hits_Needed = 12;
int g_healcount = 0;
float g_duration = 8.0;

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IsRobot(client, ROBOT_NAME))
    {
        g_healcount = 0;
    }

    return Plugin_Continue;
}



public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{

		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE|IN_ATTACK2) ) 
		{
            g_button_held[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE|IN_ATTACK2) ) 
		{
			g_button_held[client] = false;
            
		}
		DrawHUD(client);
		
	}
	return Plugin_Continue;
}

bool isready;
#define CHAR_FULL "■"
#define CHAR_EMPTY "□"
void DrawHUD(int client)
{
	char sHUDText[128];
	char sProgress[32];
	// int iPercents = RoundToCeil((GetEngineTime() / g_Recharge[client])  * 100.0);
	int iCountDown = g_Heal_Bolts_Hits_Needed - g_healcount;

	int iCountDownActive = RoundToCeil(g_Recharge[client] - (GetEngineTime()));

	int iPercents = RoundToCeil(iCountDownActive / g_duration  * 100.0);
	for (int j = 1; j <= 10; j++)
	{
	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}

	if (TF2_IsPlayerInCondition(client, TFCond_CritHype))
	{
	Format(sHUDText, sizeof(sHUDText), "Strength Bolts Active!\n               %s", sProgress);
	SetHudTextParams(1.0, 0.8, 0.5, 255, 69, 0, 255);
	}
	else if(iCountDown <= 0)
	{


	Format(sHUDText, sizeof(sHUDText), "Strength Bolts Ready!");
	SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);

	}else
	{
	Format(sHUDText, sizeof(sHUDText), "Strength Bolts: %i", iCountDown);
	SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);


	}

	ShowHudText(client, -2, sHUDText);

	if (!isready && iCountDown <= 0)
	{
	TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
	// PrintToChatAll("Ready!");
	isready = true;	
	}

	if (g_button_held[client] && iCountDown <= 0 || IsFakeClient(client))
	{
	isready = false;

	TF2_AddCondition(client, TFCond_CritHype, g_duration);
	TF2_AddCondition(client, TFCond_RuneStrength, g_duration);
	g_healcount = 0;
	g_Recharge[client] = GetEngineTime() + g_duration;
	}
}


public bool IsKritzed(int client){
	if (TF2_IsPlayerInCondition(client, (TFCond_Kritzkrieged)) || TF2_IsPlayerInCondition(client, (TFCond_Buffed)) || TF2_IsPlayerInCondition(client, (TFCond_CritCanteen)))
	{
		return true;
	}else
	{
		return false;
	}
}    

public Action Event_Crossbow_Heal(Event event, const char[] name, bool dontBroadcast)
{
	int healer = GetClientOfUserId(GetEventInt(event, "healer"));
	int target = GetClientOfUserId(GetEventInt(event, "target"));

	if (IsRobot(healer, ROBOT_NAME))
	{

	if(!TF2_IsPlayerInCondition(healer, TFCond_CritHype))g_healcount++;


	//PrintToChatAll("%N Healed %N, healcount was %i ", healer, target, g_healcount);

	if (TF2_IsPlayerInCondition(healer, TFCond_CritHype))
	{
	float reduced_duration = (g_duration / 2.0) + 1.0;



	if (IsRobot(target, "Pancop"))
	{
	TF2_AddCondition(target, TFCond_RuneHaste, reduced_duration);
	}else if (IsRobot(target, "Riotcop"))
	{
	TF2_AddCondition(target, TFCond_RuneHaste, reduced_duration);
	}else
	{
	TF2_AddCondition(target, TFCond_RuneStrength, reduced_duration);
	}




	if (IsKritzed(healer))
	{
	TF2_AddCondition(target, TFCond_CritCanteen, reduced_duration);
	}
	}

	}
	return Plugin_Continue;
}


