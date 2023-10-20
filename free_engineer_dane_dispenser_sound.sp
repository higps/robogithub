#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
#include <dhooks>
#include <sdktools>
#include <tf_custom_attributes>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Uncle Dane"

#define MUSIC "uncle_dane_dispenser.wav"


public Plugin:myinfo =
{
	name = "[TF2] Uncle Dane Dispensere",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Uncle Dane Bot from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{

    //g_offsCollisionGroup = FindSendPropInfo("DT_BaseEntity", "m_CollisionGroup");
    HookEvent("player_builtobject", ObjectBuilt, EventHookMode_Post);
	HookEvent("player_carryobject", ObjectCarry, EventHookMode_Post);
	HookEvent("player_upgradedobject", ObjectBuilt, EventHookMode_Post);
	

}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

public OnMapStart()
{

	PrecacheSound(MUSIC);
	
}

//Custom code needed for Dane's theme
float g_disp_build_time = 0.0;
float g_disp_build_cool_down = 60.0;
public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");

	
	if (IsValidClient(iBuilder) && IsRobot(iBuilder, ROBOT_NAME)){


		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser &&
		GetEngineTime() >= g_disp_build_time)
		{

			EmitSoundToAll(MUSIC, iObj);
			EmitSoundToAll(MUSIC, iObj);
			g_disp_build_time = GetEngineTime() + g_disp_build_cool_down;

		}


	}
}




public void ObjectCarry(Event event, const char[] name, bool dontBroadcast)
{
	
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	
	if (IsValidClient(iBuilder) && IsRobot(iBuilder, ROBOT_NAME)){

		if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.0);

		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser)
			{
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			//PrintToChatAll("Attempting music stop");
		}
	}
}