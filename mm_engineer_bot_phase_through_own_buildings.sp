#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Enables giant engineer robots to phase through their own buildings",
	author = "Balancemod.TF",
	description = "Temporarily changes the owner of the building of dispensers and sentries allowing the robot engineers to pass through.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    for(int client = 1 ; client <= MaxClients ; client++)
    {
        if(IsClientInGame(client))
        {

		//PrintToChatAll("Hooking %N", client);
		SDKHook(client, SDKHook_Touch, OnTouch);
        //SDKHook(client, SDKHook_EndTouchPost, OnTouch);
		//SDKHook(client,SDKHook_EndTouch, OnTouchPost);
        }
    }

}

public Action OnTouch(int client, int ent)
{
	char entname[MAX_NAME_LENGTH];
	GetEntityClassname(ent, entname, sizeof(entname));

	if (IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{


		if (!StrContains(entname, "obj_dispenser") || !StrContains(entname, "obj_sentrygun")){

			//	PrintToChatAll("Ent: %s", entname);
		int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");

		if (iBuilder == client)
		{
				//Sets the owner to nobody
				SetEntPropEnt(ent, Prop_Send, "m_hBuilder", -1);
				DataPack a = new DataPack();
				a.WriteCell(client);
				a.WriteCell(ent);
				a.Reset();
				CreateTimer(2.0, Reset_Timer, a);

			}
		}
	}
}


public Action Reset_Timer(Handle timer, DataPack data)
{
	int client = data.ReadCell();
	int ent = data.ReadCell();
	if (IsClientInGame(client))
	{ 
		SetEntPropEnt(ent, Prop_Send, "m_hBuilder", client);
	}
	delete data;
}