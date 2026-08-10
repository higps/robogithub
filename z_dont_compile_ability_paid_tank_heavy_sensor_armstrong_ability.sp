#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Sensor Armstrong"

bool g_Nanomode = false;
float g_DamageDone = 0.0;

public Plugin:myinfo =
{
	name = "[TF2] Sensor Armstrong Ability",
	author = "HiGPS | Bmod.TF",
	description = "The Ability for Sensor Armstrong Robot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	// if(!IsValidClient(attacker))
	// return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME) || IsRobot(victim, ROBOT_NAME))
	{
			 if (IsRobot(victim, ROBOT_NAME))
			 {
				if (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) || (TF2_IsPlayerInCondition(victim, TFCond_UberchargedCanteen)))
				{
					return Plugin_Continue;
				}
			 }

			 if (IsRobot(attacker, ROBOT_NAME))
			 {
				if (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) || (TF2_IsPlayerInCondition(victim, TFCond_UberchargedCanteen)
				|| TF2_IsPlayerInCondition(attacker, TFCond_Ubercharged) || TF2_IsPlayerInCondition(attacker, TFCond_UberchargedCanteen) ))
				{
					return Plugin_Continue;
				}
			 }

			
			g_DamageDone += damage;
		
	}
	return Plugin_Continue;
}


bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_duration = 5.0;
float FireModeTimer = -1.0;
float g_skill; 
float g_skill_cooldown = 2500.0;
// float g_skill_time;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		if( GetEntProp( client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE) ) 
		{
			// PrintToChatAll("Press");
            g_button_held[client] = true;
		}



		if( GetEntProp( client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE) ) 
		{
			// PrintToChatAll("Release");
			g_button_held[client] = false;
            
		}




		g_skill = GetEngineTime();
		
		DrawHUD(client);

	}
	return Plugin_Continue;
}

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"
void DrawHUD(int client)
{
	char sHUDText[128];
	char sProgress[32];
	int iPercents = RoundToCeil(g_DamageDone / g_skill_cooldown * 100.0);

	for (int j = 1; j <= 10; j++)
	{
		if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
		else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}
	//PrintToChatAll("Damage: %f, skilltime %f", g_DamageDone, g_skill_cooldown);

	// int iCountDown = RoundToCeil(g_skill_time - g_skill);
	int iCountDownFiring = RoundToCeil(FireModeTimer - g_skill);
	
	Format(sHUDText, sizeof(sHUDText), "Nanomachines: %i %%%%\n    %s",iPercents, sProgress);

	if(iPercents >= 100)
	{

			if (g_Nanomode){
				Format(sHUDText, sizeof(sHUDText), "Nanomachines! %i", iCountDownFiring);
				SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 0, 255);
			}else{
				Format(sHUDText, sizeof(sHUDText), "Nanomachines Ready!\nUse Special Attack to Activate!");
				SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);	
				}


			
	}else {

		SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 255, 255);
	}

	if (g_button_held[client] && iPercents >= 100 && !g_Nanomode)
		{
			if (FireModeTimer <= GetEngineTime() || FireModeTimer == -1.0)
			{
				TF2_AddCondition(client, TFCond_UberchargedCanteen, g_duration);
				TF2_AddCondition(client, TFCond_HalloweenQuickHeal, g_duration);
				TF2Attrib_AddCustomPlayerAttribute(client, "healing received bonus", 4.0, g_duration);
				TF2Attrib_AddCustomPlayerAttribute(client, "mod weapon blocks healing", 1.0, g_duration);
				TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 0.9);
				g_DamageDone = 0.0;
			}
		}

	if (FireModeTimer <= GetEngineTime() && g_Nanomode)
	{
		g_Nanomode = false;
		g_DamageDone = 0.0;
	}


	ShowHudText(client, -3, sHUDText);
	// b_hud_clamp[client] = false;
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	//PrintToChatAll("CONDITION REMOVED!");
	if (IsRobot(client, ROBOT_NAME)){

	
    if(condition == TFCond_UberchargedCanteen){
		TF2Attrib_RemoveCustomPlayerAttribute(client, "move speed penalty");
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		TF2Attrib_SetByName(client, "move speed penalty", 1.2);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	}
	// TF2_RemoveCondition(client, TFCond_Dazed);
	// TF2_RemoveCondition(client, TFCond_KnockedIntoAir);
	// PrintToChatAll("Condition was: %i", condition);
   }

}
