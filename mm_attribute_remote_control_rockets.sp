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

//rocket settings
float g_rocketTurnRate;
int g_rocketAimType;


bool HasStat(int client)
{

	int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (Weapon1 == -1)
	{
		return false;
	}

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(Weapon1, "mouse-control-rocket", stat_buffer, sizeof(stat_buffer))) {
	return false;
	}
	g_rocketTurnRate = ReadFloatVar(stat_buffer, "turnspeed", 1.0);
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

	// RegConsoleCmd("sm_rc", CmdControl);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			OnClientPostAdminCheck(client);
		}
	}
}

public void OnMapStart()
{
	
}

public Action PlayerDeath(Handle event, const char[] name, bool dBroad)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ControllingRocket[victim])
	{
		SetPlayerRCMode(victim, false);
	}
	return Plugin_Continue;
}

// public Action PlayerJoinClass(int client, const char[] command, int argc)
// {
// 	if (TF2_GetPlayerClass(client) == TFClass_Soldier && PlayerControlRockets[client])
// 	{
// 		PlayerControlRockets[client] = false;
// 		PrintToChat(client, "[SM] Disabling RC rockets due to class change.");
// 	}
// 	return Plugin_Continue;
// }

public void OnClientPostAdminCheck(int client)
{
	//clear variables
	ControllingRocket[client] = false;
	PlayerControlRockets[client] = false;
	RocketID[client] = INVALID_ENT_REFERENCE;
}

// Action CmdControl(int client)
// {
// 	if (TF2_GetPlayerClass(client) != TFClass_Soldier)
// 	{
// 		PrintToChat(client, "[SM] You must be a soldier to use this attribute!");
// 	}
// 	else
// 	{
// 		PlayerControlRockets[client] = !PlayerControlRockets[client];
// 	}
// }

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!(StrContains(classname, "tf_projectile_rocket")))
	{
		//SDKHook(entity, SDKHook_SpawnPost, OnRocketSpawned);
		RequestFrame(OnRocketSpawned, entity);
		SDKHook(entity, SDKHook_Touch, OnRocketEnd);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || entity > 2048) return; //prevent ent refs being used
	if (IsValidEntity(entity))
	{
		RocketOverride[entity] = false;
	}
}

public void OnRocketSpawned(int rocket)
{
	int owner = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
	if (HasStat(owner) && PlayerControlRockets[owner])
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
		RocketID[client] = INVALID_ENT_REFERENCE;
	}
}

//Make sure to take the player out of the remote control state upon a rocket hitting something
public Action OnRocketEnd(int rocket, int victim)
{
	if (RocketOverride[rocket])
	{
		int owner = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
		if (!IsValidClient(victim))
		{
			char classname[64];
			GetEntityClassname(victim, classname, sizeof classname);
			if (victim == 0 || !StrContains(classname, "prop_", false) || !StrContains(classname, "obj_", false) || !StrContains(classname, "func_door")) //solid props
			{
				SetPlayerRCMode(owner, false);
			}
		}
		else if (IsValidClient(victim))
		{
			bool sameTeam = (GetClientTeam(owner) == GetClientTeam(victim)); //check if the player we hit is an enemy player
			if (sameTeam)
			{
				//return Plugin_Handled; //pass through teammates to prevent control being lost on player overlap - DOESNT WORK NEED A BETTER METHOD
			}
			else
			{
				SetPlayerRCMode(owner, false);
			}
		}
	}
	return Plugin_Continue;
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

	if (HasStat(client) && buttons & (IN_ATTACK2) && !g_PushButton[client])
	{
		if (PlayerControlRockets[client] == false && ControllingRocket[client] == false)
		{	
			PlayerControlRockets[client] = true;

			PrintCenterText(client, "REMOTE ROCKET CONTROL: ON");


		}else if (PlayerControlRockets[client] == true && ControllingRocket[client] == false) {
				
				PlayerControlRockets[client] = false;

				PrintCenterText(client, "REMOTE ROCKET CONTROL: OFF");
		}
		g_PushButton[client] = true;
		CreateTimer(0.2, Button_Reset, client);


	}

	if (HasStat(client) && buttons & (IN_ATTACK3|IN_USE) && !g_PushButton[client])
	{
		if (g_toggethirdperson[client] == false && ControllingRocket[client] == false)
		{	
			g_toggethirdperson[client] = true;

			SetVariantInt(1);
			AcceptEntityInput(client, "SetForcedTauntCam");
		}else if (g_toggethirdperson[client] == true && ControllingRocket[client] == false) {

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
				GetClientEyeAngles(client, rocketAngle);
			}
		}
		GetAngleVectors(rocketAngle, forwardVec, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(forwardVec, speed);
		TeleportEntity(rocket, NULL_VECTOR, rocketAngle, forwardVec);
	}

	return Plugin_Continue;
}

bool IsValidRocket(int rocket)
{
	if (RocketOverride[rocket] && IsValidEntity(rocket) && rocket > MaxClients)
		return true;

	return false;
}


