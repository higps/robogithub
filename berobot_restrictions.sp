#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <sm_logger>
#include <morecolors_newsyntax>
#include <berobot_constants>
#include <berobot_core_restrictions>
#include <berobot>

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}
#include <berobot_core>
#pragma newdecls required
#pragma semicolon 1

GlobalForward _restrictionChangedForward;

public Plugin myinfo =
{
	name = "berobot_restrictions",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

public void OnPluginStart()
{
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    //aSMLOGTag(SML_INFO, "berobot_restrictions started at %i", GetTime());

    _restrictionChangedForward = new GlobalForward("MM_OnRestrictionChanged", ET_Ignore, Param_String);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("OnRestrictionChanged", Native_OnRestrictionChanged);
    return APLRes_Success;
}

public any Native_OnRestrictionChanged(Handle plugin, int numParams)
{
    char name[NAMELENGTH];
    GetNativeString(1, name, NAMELENGTH);

    Call_StartForward(_restrictionChangedForward);
    Call_PushString(name);
    Call_Finish();
}