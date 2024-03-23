#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Dewill"

#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


public Plugin:myinfo = 
{
	name = "[TF2] The DEWILL rapid fire ability",
	author = "HiGPS | Bmod.TF",
	description = "Ability for Dewill",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}



bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_duration = 6.0;
float FireModeTimer = -1.0;
// float g_currenttime;
bool g_FireMode = false;
float g_skill; 
float g_skill_cooldown = 12.0;
float g_skill_time;
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
	if( GetEntProp( client, Prop_Data, "m_afButtonPressed" ) & IN_ATTACK3 ) 
	{
	g_button_held[client] = true;
	}



	if( GetEntProp( client, Prop_Data, "m_afButtonReleased" ) & IN_ATTACK3 ) 
	{
	g_button_held[client] = false;

	}




	g_skill = GetEngineTime();

	DrawHUD(client);

	}
	return Plugin_Continue;
}

void EnterRapidFireMode(int client)
{

	g_skill_time = g_duration;
	PrintCenterText(client, "Entering Firing mode");
	g_FireMode = true;
	FireModeTimer = GetEngineTime() + g_duration;

	TF2_AddCondition(client, TFCond_RuneHaste, g_duration);

	TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 0.01);

	int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon1))
	{
		TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.35);
		TF2Attrib_SetByName(Weapon1, "major increased jump height", 0.0);		
	}
}

void ResetWeapon(int client)
{
	g_FireMode = false;
	TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 0.5);
	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	g_skill_time = g_skill + g_skill_cooldown;

	int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon1))
	{
		TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.85);
		TF2Attrib_SetByName(Weapon1, "major increased jump height", 1.0);		
	}

}


void DrawHUD(int client)
{
	char sHUDText[128];

	int iCountDown = RoundToCeil(g_skill_time - g_skill);
	int iCountDownFiring = RoundToCeil(FireModeTimer - g_skill);

	Format(sHUDText, sizeof(sHUDText), "Rapid Fire: %i   ",iCountDown);

	if(iCountDown <= 0)
	{

	if (g_FireMode){
	Format(sHUDText, sizeof(sHUDText), "Rapid Fire! %i", iCountDownFiring);
	SetHudTextParams(0.85, 0.6, 0.1, 255, 69, 0, 255);
	}else{
	Format(sHUDText, sizeof(sHUDText), "Rapid Fire Ready!\nUse Special Attack to Activate!");
	SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);	
	}



	}else {

	SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 0, 255);
	}

	if (g_button_held[client] && iCountDown <= 0 && !g_FireMode)
	{
	if (FireModeTimer <= GetEngineTime() || FireModeTimer == -1.0)
	{
	EnterRapidFireMode(client);
	}
	}

	if (FireModeTimer <= GetEngineTime() && g_FireMode)
	{
	ResetWeapon(client);
	}


	ShowHudText(client, -3, sHUDText);

}
