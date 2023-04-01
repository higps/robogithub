
#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
//#include <sendproxy>
#include <dhooks>
#include <sdktools>
#include <tf2attributes>
//#include <collisionhook>
// #include <berobot_constants>
// #include <berobot>

float g_scale = 0.35;

bool isTinyDeskEngineer[MAXPLAYERS + 1] = {false,...};
//#pragma newdecls required


public OnPluginStart()
{

    //g_offsCollisionGroup = FindSendPropInfo("DT_BaseEntity", "m_CollisionGroup");
    HookEvent("player_builtobject", ObjectBuilt, EventHookMode_Post);
	HookEvent("player_carryobject", ObjectCarry, EventHookMode_Post);
	HookEvent("player_upgradedobject", ObjectBuilt, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);

	HookEvent("post_inventory_application", Event_post_inventory_application, EventHookMode_Post);

	RegConsoleCmd("sm_tinydeskengineer", MakeTinyDeskEngineer, "Become tiny desk engineer");
	RegConsoleCmd("sm_tde", MakeTinyDeskEngineer, "Become tiny desk engineer");
}

public Action Event_post_inventory_application(Event event, const char[] name, bool dontBroadcast)
{

    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsValidClient(client) && IsPlayerAlive(client))
    {
		
		bool IsSniper = false;
	for(int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && TF2_GetPlayerClass(i) == TFClass_Sniper)
        {
            IsSniper = true;

        }


    }

	// for(int i = 1; i <= MaxClients; i++)
    // {
    //     if (IsValidClient(i))
    //     {
		if(IsSniper)RequestFrame(SetTorsoStat, client);
            

    //     }


    // }



	}
}

void SetTorsoStat(int client)
{
	PrintCenterText(client, "Sniper detected, altering torso!");
	TF2Attrib_SetByName(client, "torso scale", GetRandomFloat(0.25, 2.0));
}

public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	// if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)
	// return;
	
	
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	//int entRef = EntIndexToEntRef(iObj);
	//PrintToChatAll("iObj %i", iObj);
	
	if (IsValidClient(iBuilder) && isTinyDeskEngineer[iBuilder]){



		SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", g_scale);
		

	}
}


public void ObjectCarry(Event event, const char[] name, bool dontBroadcast)
{
	// if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)
	// return;
	
	
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	//int entRef = EntIndexToEntRef(iObj);
	//PrintToChatAll("iObj %i", iObj);
	
	if (IsValidClient(iBuilder) && isTinyDeskEngineer[iBuilder]){
		// SetEntProp(iObj, Prop_Send, "m_iHighestUpgradeLevel", 3);
		// SetEntProp(iObj, Prop_Send, "m_iUpgradeLevel", 3);
		if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", g_scale);
		

	}
}


public Action MakeTinyDeskEngineer(int client, int args)
{
	if (isMiniBoss(client)){
		PrintCenterText(client, "You can't be tiny desk engineer as robot you fool!");
		return;
	}
	


	isTinyDeskEngineer[client] = true;
    TFClassType iClass = TF2_GetPlayerClass(client);
    char model[32];
	 switch(iClass)
    {
		case TFClass_Engineer:
		{
			model = "models/player/engineer.mdl";
		}
    }

    SetVariantString(model);
    AcceptEntityInput(client, "SetCustomModel");
    SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	TF2_SetPlayerClass(client, TFClass_Engineer);
	TF2_RegeneratePlayer(client);
	TF2_RespawnPlayer(client);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_scale);
	UpdatePlayerHitbox(client, g_scale);

	int clientid = GetClientUserId(client);


	// PrintToChatAll("Float squared %f",SquareRoot(g_scale));

	TF2Attrib_SetByName(client, "move speed penalty", SquareRoot(g_scale));
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	CreateTimer(0.5, CauseTaunt, clientid);    
}

public Action CauseTaunt(Handle timer, int client)
{
    ServerCommand("sm_tauntem #%i %i", client, 1157);
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(victim))
	{
		isTinyDeskEngineer[victim] = false;
	}

}

bool isMiniBoss(int client)
{
    if(IsValidClient(client))
    {
        if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
        {
       //     if(g_cv_bDebugMode) PrintToChatAll("%N Was mini boss", client);
            return true;
        }
        else
        {
//            if(g_cv_bDebugMode)PrintToChatAll("%N Was not mini boss", client);
            return false;
        }
    }
    return false;
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
    if(client <= 0 || client > MaxClients)
        return false;
    if(!IsClientInGame(client))
        return false;
    if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
        return false;
    if(replaycheck)
    {
        if(IsClientSourceTV(client) || IsClientReplay(client))
            return false;
    }
    return true;
}


stock void UpdatePlayerHitbox(const int client, const float fScale)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };

	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;

	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);

	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}