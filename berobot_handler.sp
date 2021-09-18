#define PLUGIN_NAME "Giant Robot Plugin Handler"
#define PLUGIN_DESCRIPTION "Handles backstab modifier as well as other functions for the giant robot plugins"
#define PLUGIN_AUTHOR "Fragancia & Heavy Is GPS"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "Balancemod.tf"

#define RED 2
#define BLUE 3
#define SPECTATE 1
#define UNASSIGNED 0

#include <morecolors_newsyntax>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf_ontakedamage>
#include <sm_logger>
#include <berobot>

// #include <stocksoup/memory>
// #include <stocksoup/tf/entity_prop_stocks>
// #include <stocksoup/tf/tempents_stocks>
// #include <stocksoup/tf/weapon>


#include <dhooks>
#include <tf2attributes>

#pragma newdecls required
#pragma semicolon 1


char LOG_TAGS[][] =	 {"VERBOSE", "INFO", "ERROR"};
enum (<<= 1)
{
	SML_VERBOSE = 1,
	SML_INFO,
	SML_ERROR,
}

enum //Convar names
{
    CV_flSpyBackStabModifier,
    CV_bDebugMode,
    CV_flYoutuberMode,
    CV_g_RoboCapTeam,
    CV_g_RoboCap,
    CV_g_RoboMode,
    CV_PluginVersion
}
/* Global Variables */

/* Global Handles */

//Handle g_hGameConf;

/* Dhooks */

/* Convar Handles */

ConVar g_cvCvarList[CV_PluginVersion + 1];

/* Convar related global variables */

bool g_cv_bDebugMode;

bool g_BossMode = false;

bool g_cv_BlockTeamSwitch = false;

bool g_cv_Volunteered[MAXPLAYERS + 1];
bool g_cv_RobotPicked[MAXPLAYERS + 1];


float g_CV_flSpyBackStabModifier;
float g_CV_flYoutuberMode;

int g_RoboCapTeam;
int g_RoboTeam;
int g_HumanTeam;

ArrayList g_Volunteers;
StringMap g_RobotCount;


// Handle g_SDKCallInternalGetEffectBarRechargeTime;
// Handle g_SDKCallIsBaseEntityWeapon;

//In Global Scope

Handle g_hRegen;
Handle g_hGameConf;

//In OnPluginStart


// Global scope


public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};
public void OnPluginStart()
{
	//TODO: Release
	// SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_VERBOSE|SML_INFO|SML_ERROR, SML_ALL);
	SMLogTag(SML_INFO, "berobot_store started at %i", GetTime());

    /* Convars */


    g_cvCvarList[CV_PluginVersion] = CreateConVar("sm_yt_v_mvm_version", PLUGIN_VERSION, "Plugin Version.", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);
    g_cvCvarList[CV_bDebugMode] = CreateConVar("sm_yt_v_mvm_debug", "1", "Enable Debugging for Market Garden and Reserve Shooter damage", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_flSpyBackStabModifier] = CreateConVar("sm_yt_mvm_backstab_reduction", "500.0", "Backstab damage");
    g_cvCvarList[CV_flYoutuberMode] = CreateConVar("sm_yt_mode", "0", "Uses youtuber mode for the official mode to set youtubers as the proper classes");
    g_cvCvarList[CV_g_RoboCapTeam] = CreateConVar("sm_robocap_team", "2", "The total amount of giant robots on a team");
    g_cvCvarList[CV_g_RoboCap] = CreateConVar("sm_robocap", "1", "The amount of giant robots allowed per robot-type");
    g_cvCvarList[CV_g_RoboMode] = CreateConVar("sm_both_teams_have_robots", "0", "0 = Main Mode, 1 = Both teams have bots");

    /* Convar global variables init */

    g_cv_bDebugMode = GetConVarBool(g_cvCvarList[CV_bDebugMode]);
    g_CV_flSpyBackStabModifier = GetConVarFloat(g_cvCvarList[CV_flSpyBackStabModifier]);
    g_CV_flYoutuberMode = GetConVarFloat(g_cvCvarList[CV_flYoutuberMode]);
    g_RoboCapTeam = GetConVarInt(g_cvCvarList[CV_g_RoboCapTeam]);


    /* Convar Change Hooks */

    g_cvCvarList[CV_bDebugMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_flSpyBackStabModifier].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_flYoutuberMode].AddChangeHook(CvarChangeHook);
    g_cvCvarList[CV_g_RoboCapTeam].AddChangeHook(CvarChangeHook);
    
    

    RegAdminCmd("sm_boss_mode", Command_YT_Robot_Start, ADMFLAG_SLAY, "Sets up the team and starts the robot");
    RegConsoleCmd("sm_volunteer", Command_Volunteer, "Volunters you to be a giant robot");
    RegAdminCmd("sm_me_boss", Command_Me_Boss, ADMFLAG_SLAY, "Checks if you are a boss");

    /* Hooks */
    HookEvent("teamplay_round_start", Event_teamplay_round_start, EventHookMode_Post);


    g_Volunteers = new ArrayList(ByteCountToCells(g_RoboCapTeam));
    g_RobotCount = new StringMap();

    g_cv_BlockTeamSwitch = false;
    g_BossMode = false;

    for(int i = 0; i < MAXPLAYERS; i++)
    {
        g_cv_Volunteered[i] = false;
    }

    g_Volunteers.Clear();

    g_hGameConf = LoadGameConfigFile("sm-tf2.games");
    if(g_hGameConf == null)
        SetFailState("Failed to setup gamedata!");

    g_hRegen = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
    if(g_hRegen == null)
        SetFailState("Failed to setup OnRegenerate hook!");

    if(!DHookSetFromConf(g_hRegen, g_hGameConf, SDKConf_Signature, "Regenerate"))
        SetFailState("Failed to config Regenerate signature!");

    DHookAddParam(g_hRegen, HookParamType_Bool);

    if(!DHookEnableDetour(g_hRegen, false, OnRegenerate))
        SetFailState("Failed to detour OnRegenerate!");

    delete g_hGameConf;
}

public void OnMapStart(){

    g_cv_BlockTeamSwitch = false;
    g_BossMode = false;

    g_Volunteers.Clear();
    g_RobotCount.Clear();

    for(int i = 0; i < MAXPLAYERS; i++)
    {
        g_cv_Volunteered[i] = false;
        g_cv_RobotPicked[i] = false;
    }


}

public void OnClientDisconnect(int client)
{

    if(g_cv_Volunteered[client]) g_Volunteers.Erase(client);
    
    PrintToChatAll("%N disconnected", client);
}

/* Publics */

public Action Event_teamplay_round_start(Event event, char[] name, bool dontBroadcast)
{

    
/*     bool fullreset = GetEventBool(event, "full_reset");

    PrintToChatAll("Fullreset %b", fullreset); */
    return Plugin_Continue;
}

public MRESReturn OnRegenerate(int pThis, Handle hReturn, Handle hParams)
{
    //int client = GetClientOfUserId(GetEventInt(pThis, "userid"));
    //Write the code you want here, consult dhooks.inc for return types and so on
    // PrintToChatAll("MRESReturn trigger");
    if(isMiniBoss(pThis))
        return MRES_Supercede;

    return MRES_Ignored;
}


public void CvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    if(convar == g_cvCvarList[CV_bDebugMode])
        g_cv_bDebugMode = view_as<bool>(StringToInt(sNewValue));
    if(convar == g_cvCvarList[CV_flSpyBackStabModifier])
        g_CV_flSpyBackStabModifier = StringToFloat(sNewValue);
    if(convar == g_cvCvarList[CV_flYoutuberMode])
        g_CV_flYoutuberMode = StringToFloat(sNewValue);
}

/* Plugin Exclusive Functions */
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    if(IsValidClient(victim))
    {
        if(IsValidClient(attacker))
        {
            TFClassType iClass = TF2_GetPlayerClass(attacker);
            if(iClass == TFClass_Spy)
            {
                // Checks if boss is on
                if(g_cv_bDebugMode)
                    //   PrintToChatAll("Attacker was spy");
                    if(isMiniBoss(victim) && damagecustom == TF_CUSTOM_BACKSTAB)
                    {
                        damage = g_CV_flSpyBackStabModifier;
                        if(g_cv_bDebugMode)
                            //    PrintToChatAll("Set damage to %f", damage);
                            return Plugin_Changed;
                    }
            }
        }
    }
    return Plugin_Continue;
}

public Action Command_Me_Boss(int client, int args)
{
    if(isMiniBoss(client))
    {

        PrintToChat(client, "You are miniboss");
    }
    else
    {
        PrintToChat(client, "You are not miniboss");
    }
    return Plugin_Handled;
}


// intercept and block client jointeam command if required
public Action Command_YT_Robot_Start(int client, int args)
{
    if(!g_cv_BlockTeamSwitch)
    {
        PrintCenterTextAll("Sarting Giant Robot Event mode");
        g_cv_BlockTeamSwitch = true;
        ServerCommand("mp_forceautoteam 0");
        ServerCommand("mp_teams_unbalance_limit 0");
        ServerCommand("mp_disable_respawn_times 1");
        ServerCommand("sm_cvar tf_dropped_weapon_lifetime 0");
        ServerCommand("mp_restartgame 5");

        //Randomly set which team is roboteam and humanteam
        int RandomTeam = GetRandomInt(1, 2);
        PrintToChatAll("Randomteam was %i", RandomTeam);
        if(RandomTeam == 1)
        {

            g_RoboTeam = BLUE;
            g_HumanTeam = RED;
        }
        else
        {

            g_RoboTeam = RED;
            g_HumanTeam = BLUE;
        }

        PrintToChatAll("Robots will be Team %i", g_RoboTeam);
        PrintToChatAll("Humans will be Team %i", g_HumanTeam);
    }
    else
    {
        g_cv_BlockTeamSwitch = false;
        PrintCenterTextAll("Stopping Giant Robot Event mode");
        ServerCommand("mp_forceautoteam 1");
        ServerCommand("sm_cvar tf_dropped_weapon_lifetime 30");
        ServerCommand("mp_teams_unbalance_limit 1");
        ServerCommand("mp_disable_respawn_times 0");
        ServerCommand("mp_restartgame 5");

        g_BossMode = false;
    }

    if(g_cv_BlockTeamSwitch)
    {

        if(g_CV_flYoutuberMode)
        {
            ServerCommand("sm_ct @all red");
            ServerCommand("sm_ct @blue red");

            //Loops through all players and checks if the set ID's are present. Then sets them on blue while the rest is red
            g_RoboTeam = BLUE;
            for(int i = 1; i < MaxClients; i++)
            {

                if(IsClientInGame(i) && IsValidClient(i))
                {

                    char sSteamID[64];
                    GetClientAuthId(i, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
                    int playerID = GetClientUserId(i);


                    //PrintToChatAll("Looping on %i", playerID);
                    //Hardcoding
                    //GPS
                    if(StrEqual(sSteamID, "76561197963998743"))
                    {
                        ServerCommand("sm_begps #%i", playerID);
                        ServerCommand("sm_ct #%i blue", playerID);
                    }

                    //Bearded
                    if(StrEqual(sSteamID, "76561198031657211"))
                    {
                        ServerCommand("sm_bebearded #%i", playerID);
                        ServerCommand("sm_ct #%i blue", playerID);
                    }


                    //ArraySeven
                    if(StrEqual(sSteamID, "76561198013749611"))
                    {
                        ServerCommand("sm_bearray #%i", playerID);
                        ServerCommand("sm_ct #%i blue", playerID);
                    }

                    //Uncle Dane
                    if(StrEqual(sSteamID, "76561198057999536"))
                    {
                        ServerCommand("sm_bedane #%i", playerID);
                        ServerCommand("sm_ct #%i blue", playerID);
                    }

                    //Agro
                    if(StrEqual(sSteamID, "76561197970498549"))
                    {
                        ServerCommand("sm_beagro #%i", playerID);
                        ServerCommand("sm_ct #%i blue", playerID);
                    }

                    //Solar
                    if(StrEqual(sSteamID, "76561198070962612"))
                    {
                        ServerCommand("sm_besolar #%i", playerID);
                        ServerCommand("sm_ct #%i blue", playerID);
                    }
                }
            }

            // ServerCommand("sm_begps %i", i);
            // ServerCommand("sm_bebearded %i", i);
            // ServerCommand("sm_bearray %i", i);
            // ServerCommand("sm_besolar %i", i);
            // ServerCommand("sm_beagro %i", i);
            // ServerCommand("sm_bedane %i", i);


            //PrintToChat(client, "AuthId_SteamID64 = %s", sSteamID);

            // int SteamID64;
            // Format(sSteamID, sizeof SteamID64, "%i %s", SteamID64, sSteamID);

            //PrintToChatAll("SteamID64 %i", SteamID64);


            //
        }
        else
        {


            //Set everyone to spectate first
            
            //ServerCommand("sm_ct @all spectate");
            
            //Make volunteer robots go here
            for(int i = 0; i < MaxClients; i++)
            {

                //PrintToChatAll("Looping players %i", i);
                if(IsValidClient(i))
                {


                    
                    
                    if(IsClientInGame(i))
                    {
                        TF2_ChangeClientTeam(i, TFTeam_Spectator);
                       // int playerID = GetClientUserId(i);
                        //ServerCommand("sm_ct #%i red", playerID);
                        //int index = FindValueInArray(g_Volunteers, i);

                        if(g_cv_Volunteered[i])
                        {
                            PrintToChat(i, "You are on the Robot Team");
                           // ServerCommand("sm_begps #%i", playerID);
                            //ServerCommand("sm_ct #%i %i", playerID, g_RoboTeam);
                            ChangeClientTeam(i, g_RoboTeam);
                            TF2_RespawnPlayer(i);
                            Menu_Volunteer(i);
                        }
                        else
                        {
                            PrintToChat(i,"You are on the Human team");
                            // ServerCommand("sm_ct #%i %i", playerID, g_HumanTeam);
                            ChangeClientTeam(i, g_HumanTeam);
                            TF2_RespawnPlayer(i);
                        }
                    }
                }
            }
        }
    }
}

public Action Command_Volunteer(int client, int args)
{

    if(g_BossMode)
    {
        MC_PrintToChatEx(client, client, "{teamcolor}Game has already started, volunteering not available.", g_RoboCapTeam);
        return Plugin_Handled;
    }

    if(g_RoboCapTeam == g_Volunteers.Length)
    {


        MC_PrintToChatEx(client, client, "{teamcolor}The max amount of %i volunteers has been reached, starting Boss Mode", g_RoboCapTeam);

        Command_YT_Robot_Start(client, true);
        
        g_Volunteers.Resize(g_RoboCapTeam);
        g_BossMode = true;
        return Plugin_Handled;
    }

    if(!g_cv_Volunteered[client])
    {
        g_cv_Volunteered[client] = true;

        g_Volunteers.Push(client);

        //PrintToChat(client, "You have volunteered to be a giant robot");
    }
    else //Remove from volunteer list
    {
        g_cv_Volunteered[client] = false;

        int index = FindValueInArray(g_Volunteers, client);
        g_Volunteers.Erase(index);

        //  MC_PrintToChatEx(client, client, "{teamcolor}You are not volunteering to be a giant robot anymore");
        int islots = g_RoboCapTeam - g_Volunteers.Length;
        MC_PrintToChatAllEx(client, "{teamcolor}%N {default}is no longer volunteering to be a giant robot. %i/%i robot slots remains.", client, islots, g_RoboCapTeam);
    }

    for(int i = 0; i < g_Volunteers.Length; i++)
    {

        int clientId = g_Volunteers.Get(i);
        if(IsValidClient(clientId) && IsClientInGame(clientId))
        {

            int islots = g_RoboCapTeam - g_Volunteers.Length;
            MC_PrintToChatAllEx(client, "{teamcolor}%N {default}has volunteered to be a giant robot. %i/%i robot slots remains.", clientId, islots, g_RoboCapTeam);
        }
    }

    //Menu Stuff here
    
    //PrintToChatAll("%i arraylength", g_Volunteers.Length);
}


public Action Menu_Volunteer(int client)
{
    ArrayList robotNames = GetRobotNames();
    SMLogTag(SML_VERBOSE, "%i robots found", robotNames.Length);

    Menu menu = new Menu(MenuHandler);

    menu.SetTitle("Select Your Robot Type");

    for(int i = 0; i < robotNames.Length; i++)
    {
        char name[NAMELENGTH];
        robotNames.GetString(i, name, NAMELENGTH);
        char class[9];
        GetRobotClass(name, class);

        int roboCap = GetConVarInt(g_cvCvarList[CV_g_RoboCap]);
        int count;
        g_RobotCount.GetValue(name, count);
        int draw = count >= roboCap ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
        
        char display[128];
        Format(display, sizeof(display), "%s: %s (%i / %i used)", class, name, count, roboCap);

        menu.AddItem(name, display, draw);

        SMLogTag(SML_VERBOSE, "added option for %s: %s", name, display);
    }

    int timeout = MENU_TIME_FOREVER;
    menu.Display(client, timeout);
    SMLogTag(SML_VERBOSE, "menu displayed to %L for %i seconds", client, timeout);
 
    return Plugin_Handled;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if (action == MenuAction_Select)
    {
        char info[32];
        bool found = menu.GetItem(param2, info, sizeof(info));
        PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

        CreateRobot(info, param1, "");

        int currentCount;
        g_RobotCount.GetValue(info, currentCount);
        g_RobotCount.SetValue(info, currentCount+1);
        g_cv_RobotPicked[param1] = true;

        for(int i = 0; i < MaxClients; i++)
        {
            if(g_cv_RobotPicked[i]) //don't open menu for players, who have already picked a robot
                continue;

            if(!IsValidClient(i))
                continue;   

            if(!IsClientInGame(i))
                continue;

            if(!g_cv_Volunteered[i])
                continue;
            
            Menu_Volunteer(i);
        }

        //Make the picked option unavailable, redraw for all volunteers

       
    ///Handle menu selection, making selected robots unavailable
/*        switch (param2)
        {
            
            case 1: 
            {
                ServerCommand("%d #%i", found, param1);
                PrintToChatAll("%d #%i", found, param1);
            }
            case 2: 
            {
                ServerCommand("%d #%i", found, param1);
            }
            case 3: 
            {
                ServerCommand("%d #%i", found, param1);
            }
            case 4: 
            {
                ServerCommand("%d #%i", found, param1);
            }
            case 5: 
            {
                ServerCommand("%d #%i", found, param1);
            }
            case 6: 
            {
                ServerCommand("%d #%i", found, param1);
            }

        } */

    }
    /* If the menu was cancelled, print a message to the server about it. */
    else if (action == MenuAction_Cancel)
    {
       // PrintToChatAll("Client %d's menu was cancelled.  Reason: %d", param1, param2);
    }
    
    /* If the menu has ended, destroy it */
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

public Action OnClientCommand(int client, int args)
{
    char cmd[16];

    /* Get the argument */
    GetCmdArg(0, cmd, sizeof(cmd));

    TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));

    if(strcmp(cmd, "jointeam", true) == 0)
    {

        if(g_cv_BlockTeamSwitch)
        {
            PrintCenterText(client, "Boss mode is activated: Teams are locked");

            //If someone joins while the event is going, set correct player team

            if(iTeam == TFTeam_Unassigned)
            {


                //Puts players in the correct team
                if(!isMiniBoss(client))
                    ChangeClientTeam(client, g_HumanTeam);

                if(isMiniBoss(client))
                    ChangeClientTeam(client, g_RoboTeam);

                //Sets you as random class when you join when boss mode is active
                int irandomclass = GetRandomInt(1, 9);
                TF2_SetPlayerClass(client, view_as<TFClassType>(irandomclass));
                TF2_RespawnPlayer(client);
            }

            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}


bool isMiniBoss(int client)
{

    if(IsValidClient(client))
    {

        if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
        {
            if(g_cv_bDebugMode)
//                PrintToChatAll("%N Was mini boss", client);
            return true;
        }
        else
        {
            if(g_cv_bDebugMode)
              //  PrintToChatAll("%N Was not mini boss", client);
            return false;
        }
    }
    return false;
}


/* Stocks */
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
/*
	Swaps and respawns a player to a specified team.
	
	TFTeam_Unassigned = 0,
	TFTeam_Spectator = 1,
	TFTeam_Red = 2,
	TFTeam_Blue = 3
*/
stock void TF2_SwapTeamAndRespawn(int client, int team)
{
    SetEntProp(client, Prop_Send, "m_lifeState", 2);
    ChangeClientTeam(client, team);
    TF2_RespawnPlayer(client);
    SetEntProp(client, Prop_Send, "m_lifeState", 0);

    switch(team)
    {
    case RED:
    {
        PrintCenterText(client, "You have been moved to the RED team!");
    }
    case BLUE:
    {
        PrintCenterText(client, "You have been moved to the BLU team!");
    }
    }
}