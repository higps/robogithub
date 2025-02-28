#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>

#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included


bool ControllingRocket[MAXPLAYERS+1];
bool PlayerControlRockets[MAXPLAYERS+1];
bool RocketOverride[2049];
int RocketID[MAXPLAYERS+1];

float LastControlTime[MAXPLAYERS+1] = {-1.0, ...};

//rocket settings
float g_rocketTurnRate = 180.0;
int g_rocketAimType = 1;


bool HasStat(int client)
{
	if(!IsValidClient(client))
	{
		return false;
	}

	int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (Weapon1 == -1)
	{
		return false;
	}

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(Weapon1, "mouse-control-rocket", stat_buffer, sizeof(stat_buffer)))
	{
		return false;
	}
	g_rocketTurnRate = ReadFloatVar(stat_buffer, "turnspeed", 180.0);
	g_rocketAimType = ReadIntVar(stat_buffer, "aim-mode", 1);
	// g_UpdateHitBox = ReadIntVar(stat_buffer, "update-hitbox", 1);
	// g_bmod_disciplinary = ReadIntVar(stat_buffer, "bmod-disciplinary", 0);
	// PlayerControlRockets[client] = false;

	return true;
}

stock bool IsValidClient(iClient)
{
	return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (weapon == slot && HasStat(client))
	{
		LastControlTime[client] = GetGameTime() + 0.1;
	}

	return Plugin_Continue;
}

public Plugin MyInfo =
{
	name = "Remote Controlled Rockets",
	author = "IvoryPal, Heavy Is GPS | Bmod.TF",
	description = "Control rockets remotely from the rocket's pov."
};



public void OnPluginStart()
{
	//Events

	HookEvent("player_death", PlayerDeath);
	HookEvent("object_deflected", OnAirblasted);

	//RegConsoleCmd("sm_rc", CmdControl);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			OnClientPostAdminCheck(client);
		}
	}
}

//Action CmdControl(int client, int args)
//{
//	ToggleControl[client] = !ToggleControl[client];
//	PrintToChat(client, "RC Rockets: %s", ToggleControl[client] ? "True" : "False");
//
//	return Plugin_Handled;
//}

Action PlayerDeath(Handle event, const char[] name, bool dBroad)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ControllingRocket[victim])
	{
		SetPlayerRCMode(victim, false);
	}

	return Plugin_Continue;
}

Action OnAirblasted(Event event, const char[] name, bool dBroad)
{
	int entity = event.GetInt("object_entindex");
	if (IsValidEdict(entity) && entity > 0 && RocketOverride[entity])
	{
		int owner = GetClientOfUserId(event.GetInt("ownerid"));
		if (owner > 0 && owner <= MaxClients && IsClientInGame(owner))
		{
			SetPlayerRCMode(owner, false);
		}
	}

	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	//clear variables
	ControllingRocket[client] = false;
	PlayerControlRockets[client] = false;
	RocketID[client] = INVALID_ENT_REFERENCE;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!(StrContains(classname, "tf_projectile_rocket")))
	{
		RequestFrame(OnRocketSpawned, entity);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || entity > 2048) return; //prevent ent refs being used
	if (IsValidEntity(entity))
	{
		if (RocketOverride[entity])
		{
			DisableRocket(entity);
		}
		RocketOverride[entity] = false;
	}
}

void DisableRocket(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (owner > 0 && owner <= MaxClients && IsClientInGame(owner))
	{
		RocketID[owner] = INVALID_ENT_REFERENCE;
		SetPlayerRCMode(owner, false);
	}
}

public void OnRocketSpawned(int rocket)
{
	if (!IsValidEntity(rocket)) return;
	int owner = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
	if (HasStat(owner) && PlayerControlRockets[owner] && !ControllingRocket[owner] && LastControlTime[owner] > GetGameTime())
	{
		RocketID[owner] = rocket;
		RocketOverride[rocket] = true;
		SetPlayerRCMode(owner, true);
	}
}

void SetPlayerRCMode(int client, bool status)
{
	ControllingRocket[client] = status;
	if (status && IsValidRocket(RocketID[client]))
	{
		SetClientViewEntity(client, RocketID[client]);
		SetEntityMoveType(client, MOVETYPE_NONE);
	}
	else
	{
		SetClientViewEntity(client, client);
		SetEntityMoveType(client, MOVETYPE_WALK);
		int rocket = RocketID[client];
		if (rocket > 0 && IsValidEdict(rocket))
		{
			RocketOverride[rocket] = false;
		}
		RocketID[client] = INVALID_ENT_REFERENCE;
	}
}

bool g_PushButton[MAXPLAYERS + 1] = {false, ...};
bool g_toggethirdperson[MAXPLAYERS + 1] = {false, ...};
public Action Button_Reset(Handle timer, int client)
{
	g_PushButton[client] = false;
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{

	if (HasStat(client))
	{
		DrawHUD(client);

		if(buttons & (IN_ATTACK2) && !g_PushButton[client])
		{
			if (PlayerControlRockets[client] == false && ControllingRocket[client] == false)
			{	
				PlayerControlRockets[client] = true;

				// PrintCenterText(client, "REMOTE ROCKET CONTROL: ON");
			}
			else if (PlayerControlRockets[client] == true /*&& ControllingRocket[client] == false*/)
			{
				PlayerControlRockets[client] = false;

				if (ControllingRocket[client])
				{
					SetPlayerRCMode(client, false);
				}

				// PrintCenterText(client, "REMOTE ROCKET CONTROL: OFF");
			}
			g_PushButton[client] = true;
			CreateTimer(0.2, Button_Reset, client);
		}
	}

	if (HasStat(client) && buttons & (IN_ATTACK3|IN_USE) && !g_PushButton[client])
	{
		if (g_toggethirdperson[client] == false && ControllingRocket[client] == false)
		{	
			g_toggethirdperson[client] = true;

			SetVariantInt(1);
			AcceptEntityInput(client, "SetForcedTauntCam");
		}
		else if (g_toggethirdperson[client] == true && ControllingRocket[client] == false)
		{
			g_toggethirdperson[client] = false;

			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
		}
		g_PushButton[client] = true;
		CreateTimer(0.2, Button_Reset, client);
	}

	if (HasStat(client) && IsValidRocket(RocketID[client]))
	{
		buttons &= ~IN_ATTACK;
		int rocket = RocketID[client];
		float rocketAngle[3], forwardVec[3], velocity[3], speed;
		float rate = g_rocketTurnRate / 67.0; //this function executes ~67 times per second, so divide by 67 to get our turn rate in degrees per second.
		GetEntPropVector(rocket, Prop_Data, "m_vecVelocity", velocity);
		GetEntPropVector(rocket, Prop_Send, "m_angRotation", rocketAngle);
		speed = GetVectorLength(velocity);
		//movement
		switch (g_rocketAimType)
		{
			case 0: //player movement
			{
				if (buttons & IN_FORWARD) //angle up
				{
					rocketAngle[0] -= rate;
				}
				if (buttons & IN_BACK) //angle down
				{
					rocketAngle[0] += rate;
				}
				if (buttons & IN_MOVERIGHT)
				{
					rocketAngle[1] -= rate;
				}
				if (buttons & IN_MOVELEFT)
				{
					rocketAngle[1] += rate;
				}
			}
			case 1:
			{
				float currentAngle[3], targetAngle[3];

				currentAngle = rocketAngle;
				GetClientEyeAngles(client, targetAngle);

				rocketAngle = InterpRotation(currentAngle, targetAngle, GetGameFrameTime(), g_rocketTurnRate);
			}
		}
		GetAngleVectors(rocketAngle, forwardVec, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(forwardVec, speed);
		TeleportEntity(rocket, NULL_VECTOR, rocketAngle, forwardVec);
	}

	return Plugin_Continue;
}

void DrawHUD(int client)
{
	char sHUDText[128];

	
	// Format(sHUDText, sizeof(sHUDText), "Remote Control: M2\nMode: ");
	

	if(!PlayerControlRockets[client] != 0)
	{
		Format(sHUDText, sizeof(sHUDText), "Thirdperson: M3\nToggle Remote: M2\nRemote Control: OFF");
			
		// SetHudTextParams(1.0, 0.5, 0.3, 255, 0, 0, 255);

		
	} else {
		Format(sHUDText, sizeof(sHUDText), "Thirdperson: M3\nToggle Remote: M2\nRemote Control: ON");
		// SetHudTextParams(1.0, 0.5, 0.3, 0, 255, 0, 255);
		
		// PrintToChatAll("Not Ready!");
	}
	SetHudTextParams(1.0, 0.5, 0.5, 0, 255, 0, 255);
	ShowHudText(client, -2, sHUDText);
}

bool IsValidRocket(int rocket)
{
	if (rocket == -1) return false;
	
	if (RocketOverride[rocket] && IsValidEntity(rocket) && rocket > MaxClients)
		return true;

	return false;
}

/*
* Interpolates from a starting angle to the given target angle in a smooth transition -- Ported from UE5, should work fine
*
* @param current          Starting angle
* @param target           Angle to interpolate to
* @param delta            The frame time for this interpolation, can usually just be GetGameFrameTime()
* @param speed            How fast the interpolation should be (value of 0.0 = no interpolation).
*
* @return                 Angle between the current and target rotators based on the delta given        
*/
stock float[] InterpRotation(float current[3], float target[3], float delta, float speed)
{
	// if delta is 0, do not perform any interpolation (Location was already calculated for that frame)
	if (delta == 0.0 || VectorEquals(current, target))
		return current;

	// If no interp speed, jump to target value
	if (speed <= 0.0)
	{
		return target;
	}

	float deltaSpeed = speed * delta;
	
	float deltaRotation[3];
	SubtractVectors(target, current, deltaRotation);
	NormalizeAngle(deltaRotation);

	float result[3];
	result = current;

	result[0] += ClampFloat(deltaRotation[0], -deltaSpeed, deltaSpeed);
	result[1] += ClampFloat(deltaRotation[1], -deltaSpeed, deltaSpeed);
	result[2] += ClampFloat(deltaRotation[2], -deltaSpeed, deltaSpeed);
	
	NormalizeAngle(result);
	return result;
}

stock void NormalizeAngle(float angle[3])
{
	while (angle[0] > 89.0) angle[0] -= 180.0;
	while (angle[0] < -89.0) angle[0] += 180.0;
	while (angle[1] > 180.0) angle[1] -= 360.0;
	while (angle[1] < -180.0) angle[1] += 360.0;
}

stock bool VectorEquals(float test[3], float target[3])
{
	if (test[0] == target[0] && test[1] == target[1] && test[2] == target[2])
		return true;

	return false;
}

stock float ClampFloat(const float value, const float min, const float max)
{
	return (value < min) ? min : (value < max) ? value : max;
}