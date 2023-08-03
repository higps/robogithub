#include <sourcemod>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1


bool saytip[MAXPLAYERS + 1] = {false,...};
bool g_blocksaytip[MAXPLAYERS + 1] = {false,...};
float g_recommended_medics_per_robot = 0.5;

public Plugin myinfo =
{
	name = "berobot_teamcomptip",
	author = "heavy is gps",
	description = "Manned Machines Team Comp Suggester",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};



public void OnPluginStart()
{

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    RegConsoleCmd("sm_showcomptips", Command_ShowCompTips, "Toggles showing composition tips for your team");


}

public Action Command_ShowCompTips(int client, int args)
{
    if(g_blocksaytip[client])
    {
        g_blocksaytip[client] = false;
        MC_PrintToChatEx(client, client, "{orange}Team Composition tips: {red}off");
    }else
    {
        g_blocksaytip[client] = true;
        MC_PrintToChatEx(client, client, "{orange}Team Composition tips: {green}on");
    }
    return Plugin_Continue;
}


public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    //For Humans
    if (!IsAnyRobot(client) && GetRobotTeam() != GetClientTeam(client))
    {

        CreateTimer(0.5, Tip_Timer, client);
    }

}


public Action Tip_Timer(Handle timer, any client)
{
        int CurrentRobots = 0;
        // int CurrentHumans = 0;
        int MedicCount = 0;
        int EngineerCount = 0;
        int PyroCount = 0;
        int HeavyCount = 0;
        int SoldierCount = 0;
        int DemoCount = 0;
        for(int i = 0; i <= MaxClients+1; i++)
        {
            if(IsAnyRobot(i))
            {
                CurrentRobots++;
            }

            if(!IsAnyRobot(i) && IsValidClient(i))
            {
                // CurrentHumans++;

                if(TF2_GetPlayerClass(i) == TFClass_Medic)MedicCount++;
                if(TF2_GetPlayerClass(i) == TFClass_Engineer)EngineerCount++;
                if(TF2_GetPlayerClass(i) == TFClass_Pyro)PyroCount++;
                if(TF2_GetPlayerClass(i) == TFClass_Heavy)HeavyCount++;
                if(TF2_GetPlayerClass(i) == TFClass_Soldier)SoldierCount++;
                if(TF2_GetPlayerClass(i) == TFClass_DemoMan)DemoCount++;
                
            }

        }
        
        if (CurrentRobots != 0)
        {
        char chat_display[512];
        
        

        
        saytip[client] = false;
        int PowerClasses = HeavyCount+SoldierCount+DemoCount;
        if (CurrentRobots > 1 && PowerClasses < 2)
        {
            Format(chat_display, sizeof(chat_display), "%s more power classes,",chat_display);
            saytip[client] = true;
        }

        if(CurrentRobots > 1 && EngineerCount == 0)
        {
            Format(chat_display, sizeof(chat_display), "%s an engineer,",chat_display);
            saytip[client] = true;
        }

        if(CurrentRobots > 1 && PyroCount == 0)
        {
            Format(chat_display, sizeof(chat_display), "%s a pyro,",chat_display);
            saytip[client] = true;
        }



        float target_medics = float(CurrentRobots)*g_recommended_medics_per_robot;
        float medic_ratio = float(MedicCount)/float(CurrentRobots);
        bool multimedics = false;
        int needed_medics = RoundToNearest(target_medics)-MedicCount;
        if (needed_medics > 0){
            
            

            Format(chat_display, sizeof(chat_display), "%s %i more medic",chat_display, needed_medics);

            if (needed_medics > 1)
            {
                Format(chat_display, sizeof(chat_display), "%ss",chat_display);
            }
            Format(chat_display, sizeof(chat_display), "%s,",chat_display);
            multimedics = true;
            saytip[client] = true;
        }

        if(CurrentRobots > 1 && MedicCount == 0 && !multimedics)
        {
            Format(chat_display, sizeof(chat_display), "%s a medic,",chat_display);
            saytip[client] = true;
        }

        if(saytip[client]){
        Format(chat_display, sizeof(chat_display), "Your team could use%s to better fight the robots\nUse !showcomptips to toggle this tip",chat_display);

        // if (saytip[client] && !g_blocksaytip[client])
        PrintHintText(client,chat_display);
        }
        // PrintHintText(client,"chat_display");

//PrintToChatAll("You had %i medics on your team.\nRecommend Medic ratio %.0f\nCurrent Medic Ratio: %0.f", MedicCount, recommended_medics, medic_ratio);
        // PrintToChatAll("You had %i medics on your team.\nTarget Medics %.0f\nCurrent Medic Ratio: %0.f", MedicCount, target_medics, medic_ratio);
        }
}