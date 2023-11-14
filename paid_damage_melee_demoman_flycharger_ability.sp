#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
 
#define ROBOT_NAME	"FlyCharger"
#define PLUGIN_VERSION "1.0"
public Plugin:myinfo =
{
	name = "[TF2] FlyCharger ability",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "FlyCharger Ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

float g_cooldown = 0.05;
float g_last_used;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Charging))
		{
			float vOrigin[3], vAngles[3], vForward[3], vVelocity[3];
			GetClientEyePosition(client, vOrigin);
			GetClientEyeAngles(client, vAngles);
			
			// Get the direction we want to go
			GetAngleVectors(vAngles, vForward, NULL_VECTOR, NULL_VECTOR);
			
			// make it usable
			float flDistance = 100.0;
			ScaleVector(vForward, flDistance);	
			
			// add it to the current velocity to avoid just being able to do full 180s
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
			AddVectors(vVelocity, vForward, vVelocity);
			
			float flDistanceVertical = 10.0;
				
			vVelocity[2] += flDistanceVertical; // we always want to go a bit up
			
			// And set it

			//PrintToChatAll("Charging");
			//PrintToChatAll("Last Used: %f\nEngineTime: %f",g_last_used + g_cooldown, GetEngineTime());

			if(g_last_used < GetEngineTime())
			{
				
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
				g_last_used = GetEngineTime() + g_cooldown;
				// PrintToChatAll("PORTING %f",g_last_used);
			}
		}
	}
}

