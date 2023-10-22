#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <dhooks>
#include <tf_ontakedamage>
#include <tf2_isPlayerInSpawn>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Skill for the Boxing Champ",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}


bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 5.0;
float g_skill;

bool isready;
bool setspeed;


public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, "Boxing Champ"))
	{
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		// if(GetEntProp(client, Prop_Data, "m_bDucking")) 
		// {
		// 	// PrintToChatAll("Press");
        //     // g_button_held[client] = true;
		// 	GetEntProp(client, Prop_Data, "m_bDucking")) 
		// }
			

		if( GetEntProp( client, Prop_Data, "m_afButtonReleased" )  & IN_DUCK) 
		{
			// PrintToChatAll("Release");
			// g_button_held[client] = false;

			if (g_Recharge[client] <= GetEngineTime() && isready && !TF2Spawn_IsClientInSpawn(client) && !setspeed) 
			{
			SetSpeed(client);
			g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
			
			}


			ResetSpeed(client);
            
		}
		g_skill = GetEngineTime();
		DrawHUD(client);
	}
	return Plugin_Continue;
}

void SetSpeed(int client)
{
	// TF2Attrib_AddCustomPlayerAttribute(client, "increased jump height", 0.01, 1.0);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.5);
	TF2_AddCondition(client, TFCond_Buffed, 1.5);
	// TF2_AddCondition(client, 130, 0.5);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 520.0);
	setspeed = true;
}

void ResetSpeed(int client)
{
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
	TF2_StunPlayer(client, 0.0, 0.0, TF_STUNFLAG_SLOWDOWN);
	setspeed = false;
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

	Format(sHUDText, sizeof(sHUDText), "Crouch Dash: %i   ", iCountDown);
	

	if(iCountDown <= 0)
	{
		Format(sHUDText, sizeof(sHUDText), "Crouch Dash Ready!");
			
		SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);

		
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
