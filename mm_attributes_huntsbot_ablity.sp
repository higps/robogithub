#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>

bool  g_button_held[MAXPLAYERS + 1] = { false, ... };
// float g_currenttime;
bool  g_FireMode					= false;
float g_skill;
float g_skill_cooldown = 30.0;
float g_skill_time;
float g_f_duration = 8.0;
bool  b_alerted	   = false;
float g_fired_cooldown;
#define ROBOT_NAME "Huntsbot"

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		if (GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_ATTACK3)
		{
			g_button_held[client] = true;
		}

		if (GetEntProp(client, Prop_Data, "m_afButtonReleased") & IN_ATTACK3)
		{
			g_button_held[client] = false;
		}

		g_skill = GetEngineTime();

		DrawHUD(client);
	}
	return Plugin_Continue;
}

void DrawHUD(int client)
{
	char sHUDText[128];

	int	 iCountDown = RoundToCeil(g_skill_time - g_skill);
	int iFireDuration = RoundToCeil(g_f_duration - g_f_duration);
	Format(sHUDText, sizeof(sHUDText), "Rapid Fire in %i", iCountDown);

	if (iCountDown <= 0)
	{
		if (g_FireMode)
		{
			Format(sHUDText, sizeof(sHUDText), "Cooldown! %i", iCountDown);
			SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 0, 0);
		}
		else {
			if (!b_alerted)
			{
				TF2_AddCondition(client, TFCond_InHealRadius, 0.5);

				b_alerted = true;
			}

			Format(sHUDText, sizeof(sHUDText), "Rapid Fire Ready!\nUse Special Attack to Activate!");
			SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);
		}
	}
	else {
		SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 0, 255);
	}

	if (g_button_held[client] && iCountDown <= 0)
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		TF2_AddCondition(client, TFCond_RuneHaste, g_f_duration);
		g_skill_time = GetEngineTime() + g_skill_cooldown;
		b_alerted	 = false;
		g_fired_cooldown = GetEngineTime() + g_f_duration;
	}

	// if (FireModeTimer <= GetEngineTime() && g_FireMode)
	// {
	// ResetWeapon(client);
	// }
	// if (TF2_IsPlayerInCondition(TFCond_RuneHaste, client))
	// {
	// 	Format(sHUDText, sizeof(sHUDText), "Rapid Fire! %i", iFireDuration);
	// 	// SetHudTextParams(0.85, 0.6, 0.1, 255, 69, 0, 255);
	// }

	ShowHudText(client, -3, sHUDText);
}
