#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"

enum
{
	SOLID_NONE			= 0,	// no solid model
	SOLID_BSP			= 1,	// a BSP tree
	SOLID_BBOX			= 2,	// an AABB
	SOLID_OBB			= 3,	// an OBB (not implemented yet)
	SOLID_OBB_YAW		= 4,	// an OBB, constrained so that it can only yaw
	SOLID_CUSTOM		= 5,	// Always call into the entity for tests
	SOLID_VPHYSICS		= 6,	// solid vphysics object, get vcollide from the model and collide with that
	SOLID_LAST,
};

// Taken from smlib
enum
{
	FSOLID_CUSTOMRAYTEST		= 0x0001,	// Ignore solid type + always call into the entity for ray tests
	FSOLID_CUSTOMBOXTEST		= 0x0002,	// Ignore solid type + always call into the entity for swept box tests
	FSOLID_NOT_SOLID			= 0x0004,	// Are we currently not solid?
	FSOLID_TRIGGER				= 0x0008,	// This is something may be collideable but fires touch functions
											// even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
	FSOLID_NOT_STANDABLE		= 0x0010,	// You can't stand on this
	FSOLID_VOLUME_CONTENTS		= 0x0020,	// Contains volumetric contents (like water)
	FSOLID_FORCE_WORLD_ALIGNED	= 0x0040,	// Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
	FSOLID_USE_TRIGGER_BOUNDS	= 0x0080,	// Uses a special trigger bounds separate from the normal OBB
	FSOLID_ROOT_PARENT_ALIGNED	= 0x0100,	// Collisions are defined in root parent's local coordinate space
	FSOLID_TRIGGER_TOUCH_DEBRIS	= 0x0200,	// This trigger will touch debris objects

	FSOLID_MAX_BITS	= 10
};

public Plugin:myinfo =
{
	name = "[TF2] Enables giant engineer robots to phase through their own buildings",
	author = "bmod.tf",
	description = "Temporarily changes the owner of the building of dispensers and sentries allowing the robot engineers to pass through.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

bool g_IsHooked[MAXPLAYERS + 1] = false;
// bool g_IsPhased[2048] = false;

public OnPluginStart()
{

	HookEvent("post_inventory_application", post_inventory_application, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
    // for(int client = 1 ; client <= MaxClients ; client++)
    // {
    //     if(IsClientInGame(client))
    //     {

	// 	//PrintToChatAll("Hooking %N", client);
	// 	SDKHook(client, SDKHook_Touch, OnTouch);
	// 	// SDKHook(client, SDKHook_ShouldCollide, ShouldCollide );
    //     //SDKHook(client, SDKHook_EndTouchPost, OnTouch);
	// 	//SDKHook(client,SDKHook_EndTouch, OnTouchPost);
		
    //     }
    // }

}

public void OnClientDisconnect_Post(int client)
{
	if (IsValidClient(client))
	{
		SDKUnhook(client, SDKHook_Touch, OnTouch);
		g_IsHooked[client] = false;
	} 
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	//int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsAnyRobot(victim) && TF2_GetPlayerClass(victim) == TFClass_Engineer && g_IsHooked[victim])
	{
		SDKUnhook(victim, SDKHook_Touch, OnTouch);
		g_IsHooked[victim] = false;
		// PrintToChatAll("UnHooked %N", victim);
	}
}


public Action post_inventory_application(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Engineer && !g_IsHooked[client])
	{
		SDKHook(client, SDKHook_Touch, OnTouch);

		// SDKHook(client, SDKHook_StartTouch, StartTouch);
		

		
		g_IsHooked[client] = true;
	}
}
// public bool:ShouldCollide( entity, collisiongroup, contentsmask, bool:result )
// {
// 	PrintToChatAll("Should not collide");
//     return false;
// } 

public Action OnTouch(int client, int ent)
{
	char entname[MAX_NAME_LENGTH];
	GetEntityClassname(ent, entname, sizeof(entname));

	if (IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{


		if (!StrContains(entname, "obj_sentrygun")){
			StartPhasing(ent, 0, client);
		}

		if (!StrContains(entname, "obj_dispenser"))
		{
			StartPhasing(ent, 1, client);
		}
	}
}

// public Action OnTouch(int client, int ent)
// {
// 	char entname[MAX_NAME_LENGTH];
// 	GetEntityClassname(ent, entname, sizeof(entname));

// 	if (IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
// 	{


// 		if (!StrContains(entname, "obj_sentrygun")){
//  	PrintToChatAll("STart touch!");
// 		}
			
			
		
// 	}
// }



void StartPhasing(int ent, int state, int client)
{
		int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
		// int iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		// PrintToChatAll("iOwner was %i", iOwner);
		//PrintToChatAll("Building state: %i", TF2_GetBuildingState(ent));

		if (iBuilder == client && TF2_GetBuildingState(ent) != state)
		{
				//Sets the owner to nobody
				SetEntPropEnt(ent, Prop_Send, "m_hBuilder", -1);
				//PrintToChatAll("Touching your own building!");
				//SetEntitySolid(ent, false);
				// SDKHook(ent, SDKHook_ShouldCollide, ShouldCollide);
				DataPack a = new DataPack();
				a.WriteCell(client);
				a.WriteCell(ent);
				a.Reset();
				CreateTimer(1.2, Reset_Timer, a);

		}
}


// public Action OnTouchPost(int client, int ent)
// {
// 	char entname[MAX_NAME_LENGTH];
// 	GetEntityClassname(ent, entname, sizeof(entname));

// 	if (IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
// 	{


// 		if (!StrContains(entname, "obj_dispenser") || !StrContains(entname, "obj_sentrygun")){

// 			//	PrintToChatAll("Ent: %s", entname);

// 		PrintToChatAll("Touching something! Post");

// 		int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");

// 		if (iBuilder == client)
// 		{
// 				//Sets the owner to nobody
// 				SetEntPropEnt(ent, Prop_Send, "m_hBuilder", client);
				
// 				//SetEntitySolid(ent, false);
// 				// SDKHook(ent, SDKHook_ShouldCollide, ShouldCollide);
// 				DataPack a = new DataPack();
// 				a.WriteCell(client);
// 				a.WriteCell(ent);
// 				a.Reset();
// 				CreateTimer(2.0, Reset_Timer, a);

// 			}
// 		}
// 	}
// }


public Action Reset_Timer(Handle timer, DataPack data)
{
	int client = data.ReadCell();
	int entity = data.ReadCell();
	if (IsClientInGame(client) && IsValidClient(client))
	{ 

	// if( GetEntProp(entity, Prop_Send, "m_nSolidType", 1) == SOLID_NONE )
	// {
		//ReplyToCommand(client, "[SM] sm_collision: Set target %d solid.", entity);
		//SetEntitySolid(entity, true);

		if (IsValidEntity(entity))
		{
		// 			int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		// PrintToChatAll("iOwner was %i", iOwner);
			SetEntPropEnt(entity, Prop_Send, "m_hBuilder", client);
			// g_IsPhased[entity] = true;
		}
	// }
	// else
	// {
	// 	//ReplyToCommand(client, "[SM] sm_collision: Set target %d non-solid.", entity);
	// 	SetEntitySolid(entity, false);
	// }
	// 	//SetEntPropEnt(ent, Prop_Send, "m_hBuilder", client);
	}
	delete data;
}
// public bool:ShouldCollide( entity, collisiongroup, contentsmask, bool:result )
// {
// 	PrintToChatAll("Should collide");
//     return true;
// } 

public Action CmdColli(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity;

	if( args == 0 )
	{
		entity = GetClientAimTarget(client, false);
		if( entity == -1 )
		{
			ReplyToCommand(client, "[SM] sm_collision: Invalid aim target.");
			return Plugin_Handled;
		}
	} else {
		char sArg[8];
		GetCmdArg(1 ,sArg, sizeof(sArg));

		entity = StringToInt(sArg);
		if( entity <= 0 || entity >= 2048 || !IsValidEntity(entity) )
		{
			ReplyToCommand(client, "[SM] sm_collision: Invalid entity specified.");
			return Plugin_Handled;
		}
	}

	if( GetEntProp(entity, Prop_Send, "m_nSolidType", 1) == SOLID_NONE )
	{
		ReplyToCommand(client, "[SM] sm_collision: Set target %d solid.", entity);
		SetEntitySolid(entity, true);
	}
	else
	{
		ReplyToCommand(client, "[SM] sm_collision: Set target %d non-solid.", entity);
		SetEntitySolid(entity, false);
	}

	return Plugin_Handled;
}

stock void SetEntitySolid(int entity, bool doSolid)
{
	int m_nSolidType	= GetEntProp(entity, Prop_Data, "m_nSolidType", 1);
	int m_usSolidFlags	= GetEntProp(entity, Prop_Data, "m_usSolidFlags", 2);
	
	if( doSolid )
	{
		if( m_nSolidType == 0 )
			SetEntProp(entity, Prop_Send,	"m_nSolidType",		SOLID_VPHYSICS,	1);
			
		if( m_usSolidFlags & FSOLID_NOT_SOLID )
			SetEntProp(entity, Prop_Send,	"m_usSolidFlags", 	m_usSolidFlags & ~FSOLID_NOT_SOLID,	2);
	}
	else
	{
		if( m_nSolidType != 0 )
			SetEntProp(entity, Prop_Send,	"m_nSolidType",		view_as<int>(SOLID_NONE),	1);
			
		if( m_usSolidFlags & FSOLID_NOT_SOLID == 0 )
			SetEntProp(entity, Prop_Send,	"m_usSolidFlags", 	m_usSolidFlags | FSOLID_NOT_SOLID,	2);
	}
}

public Action TF2_GetBuildingState(int iBuilding)
{
	if (IsValidEntity(iBuilding))
	{
		int iState = GetEntProp(iBuilding, Prop_Send, "m_iState");
		// PrintToChatAll("State was %i", iState);
		return iState;
	
	}
	return -2;
}