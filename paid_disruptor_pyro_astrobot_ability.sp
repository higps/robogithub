#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Astrobot"


public Plugin:myinfo = 
{
	name = "[TF2] Astro bot flying skill",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Agro Pyro from Kritzkast",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

float fl_NextSecondaryAttack[MAXPLAYERS+1] = {0.0,...};
float AirblastPower = 175.0;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(IsRobot(client, ROBOT_NAME) && IsPlayerAlive(client))
	{

			// Class Check
				new String:weaponname[64], wep, Float:fl_EyeAngles[3], Float:fl_vel[3];
				GetClientEyeAngles(client, fl_EyeAngles);
				fl_EyeAngles[0] = DegToRad(-1.0 * fl_EyeAngles[0]);
				fl_EyeAngles[1] = DegToRad(fl_EyeAngles[1]);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", fl_vel);
				wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				GetEntityClassname(wep, weaponname, sizeof(weaponname));

				if(buttons & IN_ATTACK2 &&
				(GetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack") - fl_NextSecondaryAttack[client]) > 0.0)
				{
					fl_NextSecondaryAttack[client] = GetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack");
					fl_vel[0] -= AirblastPower * Cosine(fl_EyeAngles[0]) * Cosine(fl_EyeAngles[1]);
					fl_vel[1] -= AirblastPower * Cosine(fl_EyeAngles[0]) * Sine(fl_EyeAngles[1]);
					fl_vel[2] -= AirblastPower * Sine(fl_EyeAngles[0]);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fl_vel);
				}
				
				// // Flamethrower Jetpack
				// if(buttons & IN_ATTACK && RadToDeg(-fl_EyeAngles[0]) >= 60.0)
				// {
				// 	fl_vel[0] -= GetConVarFloat(mobp_JetpackPower) * Cosine(fl_EyeAngles[0]) * Cosine(fl_EyeAngles[1]);
				// 	fl_vel[1] -= GetConVarFloat(mobp_JetpackPower) * Cosine(fl_EyeAngles[0]) * Sine(fl_EyeAngles[1]);
				// 	fl_vel[2] -= GetConVarFloat(mobp_JetpackPower) * Sine(fl_EyeAngles[0]);
				// 	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fl_vel);
				// }
		}
}
