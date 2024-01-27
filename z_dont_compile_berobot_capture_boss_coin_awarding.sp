#include <berobot_constants>
#include <berobot>
#include <sourcemod>
#include <sm_logger>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "berobot_getgamemode",
	author = "heavy is gps",
	description = "Manned Machines GameMode Getter",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};


int b_is_koth;

public void OnPluginStart()
{
    HookEvent("teamplay_point_captured", Event_Teamplay_Point_Captured, EventHookMode_Post);
}

public void OnMapStart()
{
    b_is_koth = GameRules_GetProp("m_bPlayingKoth");
}

public Action Event_Teamplay_Point_Captured(Event event, char[] name, bool dontBroadcast)
{
    //int team = GetEventInt(event, "team");
    //PrintToChatAll("Team wws %i", team);
    if (!b_is_koth)
    {
        // AddTeamCoins(TFTeam_Blue, 1);
        // AddTeamCoins(TFTeam_Red, 1);
    }else
    {
        int Team_that_captured = GetEventInt(event, "team");
        PrintToChatAll("Team that captured was %i", Team_that_captured);
        int RoboTeam = GetRobotTeam();
        
        //2 Is red
        //3 is blu
    }
}


// public Action Event_Teamplay_Point_Captured(Event event, char[] name, bool dontBroadcast)
// {
//     //int team = GetEventInt(event, "team");
//     //PrintToChatAll("Team wws %i", team);

//     PrintToChatAll("ATtempting to post times:");
//         // Get the Red team round timer entity

//     int timerRed = GameRules_GetPropEnt("m_hRedKothTimer");
//     int timerBlu = GameRules_GetPropEnt("m_hBlueKothTimer");

//     float redtime = GetEntPropFloat(timerRed, Prop_Send, "m_flTimeRemaining");
//     float blutime = GetEntPropFloat(timerBlu, Prop_Send, "m_flTimeRemaining");

//     char redTimeFormatted[16];
//     char blueTimeFormatted[16];



//     FormatTime_Float(redtime, redTimeFormatted);
//     FormatTime_Float(blutime, blueTimeFormatted);
    

//     PrintToChatAll("Red: %s, Blu: %s", redTimeFormatted, blueTimeFormatted);
//     return Plugin_Continue;
// }

// char FormatTime_Float(float seconds, char formattedTime[16])
// {
//     int minutes = RoundFloat(seconds / 60.0);
//     int remainingSeconds = RoundFloat(seconds) % 60;

//     Format(formattedTime, sizeof(formattedTime), "%d:%02d", minutes, remainingSeconds);

//     return formattedTime;


// }