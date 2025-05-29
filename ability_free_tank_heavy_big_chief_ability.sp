#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_ontakedamage>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>
#include <morecolors>
#define ROBOT_NAME	"Big Chief"
#define PLUGIN_VERSION "1.0"
public Plugin:myinfo =
{
	name = "[TF2] Big Chiefability",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Ability for Big Chief Bot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
int amount_stack[MAXPLAYERS + 1] = {0,...};

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	// PrintToChatAll("DED");
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsRobotWhenDead(client, ROBOT_NAME))
	{
		amount_stack[client] = 0;
	}
	    
}

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 10.0;
float g_skill;
float g_dash_duration = 2.5;
float g_done_dash;
bool isready;



public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		// if(GetEntProp(client, Prop_Data, "m_bDucking")) 
		// {
		// 	// PrintToChatAll("Press");
        //     // g_button_held[client] = true;
		// 	GetEntProp(client, Prop_Data, "m_bDucking")) 
		// }
			

		if( GetEntProp( client, Prop_Data, "m_afButtonReleased" )  & IN_RELOAD) 
		{
			// PrintToChatAll("Release");
			// g_button_held[client] = false;
			int IsJumping = GetEntProp(client, Prop_Send, "m_bJumping");
			if (g_Recharge[client] <= GetEngineTime() && isready && IsJumping != 1)
			{
			SetSpeed(client);
			g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
			isready = false;
			}
            
		}
		if(g_done_dash + g_dash_duration > GetEngineTime())
		{
			// ResetSpeed(client);
		}
		g_skill = GetEngineTime();
		DrawHUD(client);
	}
	return Plugin_Continue;
}

void SetSpeed(int client)
{
    float vOrigin[3], vAngles[3], vForward[3], vVelocity[3];
    GetClientEyePosition(client, vOrigin);
    GetClientEyeAngles(client, vAngles);

    // Get the forward direction, ignoring pitch (set pitch to 0 for a flat direction)
    vAngles[0] = 0.0; // Neutralize pitch to ensure only forward direction is used
    GetAngleVectors(vAngles, vForward, NULL_VECTOR, NULL_VECTOR);

    // Set forward momentum
    float flDistance = 400.0;
    ScaleVector(vForward, flDistance);

    // Add current velocity to preserve existing momentum
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
    AddVectors(vVelocity, vForward, vVelocity);
	TF2_AddCondition(client, TFCond_CritHype, 1.0);
    // Set a constant vertical velocity
    float flVerticalVelocity = 310.0;
    vVelocity[2] = flVerticalVelocity; // Overwrite vertical component

    // Apply the velocity
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
	ReduceMaxHealth(client, 100);
}



void DrawHUD(int client)
{
	char sHUDText[128];
	// char sProgress[32];
	//int iPercents = RoundToCeil(float(g_Recharge[client]) / float(g_RechargeCooldown) * 100.0);
	int iCountDown = RoundToCeil(g_Recharge[client] - g_skill);
	
	// for (int j = 1; j <= 10; j++)
	// {
	// 	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	// 	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	// }

	Format(sHUDText, sizeof(sHUDText), "Horizontal Jump: %i   ", iCountDown);
	

	if(iCountDown <= 0)
	{
		SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);
		Format(sHUDText, sizeof(sHUDText), "Horizontal Jump!\nReload to use");
			

		
	} else {
		SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);
		
		// PrintToChatAll("Not Ready!");
	}
	// if (g_hud_post_time + g_hud_draw_delay <= GetEngineTime() || g_hud_post_time == 0.0)
	// {
		 ShowHudText(client, -2, sHUDText);
	// 	 g_hud_post_time = GetEngineTime();
	// }

		if (!isready && iCountDown <= 0)
		{
			TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
			// PrintToChatAll("Ready!");
			isready = true;	
		}

	if (g_button_held[client] && iCountDown <= 0)
	{
		g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
		isready = false;
		
	}
}



void ReduceMaxHealth(int client, int amount)
{
    // Check if the client is valid and connected
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    // Get the current maximum health directly from the player entity
    // int maxHealth = GetEntProp(client, Prop_Data, "m_iHealth");
    // PrintToChatAll("Current HP is: %i", maxHealth);

    // // Calculate the new maximum health
    // int newMaxHealth = maxHealth - amount;
    // PrintToChatAll("New Max HP is: %i", newMaxHealth);
    // // Ensure the new maximum health is not less than 1
    // if (newMaxHealth < 1)
    //     newMaxHealth = 1;

    // Set the new maximum health
    // SetEntProp(client, Prop_Data, "m_iMaxHealth", newMaxHealth);

    // Adjust current health if it's higher than the new maximum
    // int currentHealth = GetClientHealth(client);
    // if (currentHealth > newMaxHealth)
    // {
    //     SetEntityHealth(client, newMaxHealth);
    // }
	amount_stack[client] = amount_stack[client] + amount;
	TF2Attrib_SetByName(client, "max health additive penalty", -float(amount_stack[client]));
}



stock int TF2_GetPlayerMaxHealth(int client)
{
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}