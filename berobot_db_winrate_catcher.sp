
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>

#define PLUGIN_VERSION "0.1"

Database hDatabase = null;
char g_map_name[256] = "";
char g_ServerName[64] = ""; 
// int g_Map_Timestamp_ID;
char g_time[64];

bool g_random_robot[MAXPLAYERS + 1] = {false,...};

public void OnMapStart()
{
    //Generate Timestamp here, each map has it's own timestamp
    // char g_time[64];
    int Map_Timestamp_ID = GetTime();
    FormatTime(g_time, sizeof(g_time), "%Y-%m-%d %H:%M:%S", Map_Timestamp_ID);

    
    GetCurrentMap(g_map_name, sizeof(g_map_name));               // Get map name. (itemtest, ctf_2fort)
    GetMapDisplayName(g_map_name, g_map_name, sizeof(g_map_name)); 

    Handle convar = FindConVar("hostname");
    GetConVarString(convar, g_ServerName, sizeof(g_ServerName)); 

    Database.Connect(GotDatabase, "mm_winrates");


}

public void OnPluginStart()
{
    HookEvent("teamplay_round_win", Event_teamplay_robot_win_table, EventHookMode_Post);
    // HookEvent("teamplay_round_win", Event_teamplay_human_comp, EventHookMode_Post);

    
}

public void GotDatabase(Database db, const char[] error, any data)
{

    PrintToServer("Database connection %s", db ? "successful" : "failed");
    if (db == null)
    {
        LogError("Database failure: %s", error);
    } 
    else 
    {
        hDatabase = db;
    }
    

    InitializeTablesFirstRun(db);
}

public void InitializeTablesFirstRun(Database db){

        if (db) {
            // If the connection is successful, create the table
            SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS mm_robot_win (id INT AUTO_INCREMENT PRIMARY KEY, game_id_timestamp TIMESTAMP, win_team VARCHAR(3), total_gametime BIGINT, map VARCHAR(255), player_count INT, robot_count INT, human_count INT, robot_team_win TINYINT, server VARCHAR(128))");
            SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS mm_robot_individual_win (id INT AUTO_INCREMENT PRIMARY KEY, game_id_timestamp TIMESTAMP, client_steamId VARCHAR(30), robot_name VARCHAR(30), total_gametime BIGINT, robot_team_win TINYINT)");
            SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS mm_robot_pickrate (id INT AUTO_INCREMENT PRIMARY KEY, game_id_timestamp TIMESTAMP, robot_name VARCHAR(30), map VARCHAR(255), team VARCHAR(3), random TINYINT, pick_time BIGINT, client_id VARCHAR(20), server VARCHAR(128))");
            SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS mm_robot_human_comp (id INT AUTO_INCREMENT PRIMARY KEY, game_id_timestamp TIMESTAMP, client_steamId VARCHAR(30), class TINYINT, total_gametime BIGINT)");

            SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS classes (class_id INT PRIMARY KEY, class_name VARCHAR(20))");

            SQL_FastQuery(db, "INSERT INTO classes (class_id, class_name) VALUES \
            (0, 'Unknown'), \
            (1, 'Scout'), \
            (2, 'Sniper'), \
            (3, 'Soldier'), \
            (4, 'DemoMan'), \
            (5, 'Medic'), \
            (6, 'Heavy'), \
            (7, 'Pyro'), \
            (8, 'Spy'), \
            (9, 'Engineer')");
        }

}    

public Action Event_teamplay_robot_win_table(Event event, char[] name, bool dontBroadcast)
{
    // 2 = red
    // 3 = blu
    int team = GetEventInt(event, "team");
    int RobotTeam = GetRobotTeam();

    char win_team_str[4];
    if (team == TFTeam_Blue) {
        win_team_str = "BLU";
    } else if (team == TFTeam_Red) {
        win_team_str = "RED";
    }
    else
    {
        win_team_str = "ERR";
    } 
    

    // PrintToChatAll("Time: %s",time);


    int total_gametime = RoundToNearest(GetGameTime());
    int robot_team_win = (team == RobotTeam) ? 1 : 0;

    int CurrentRobots = GetCurrentRobotCount();
    int CurrentHumans = GetCurrentHumanCount();
    int player_count = CurrentRobots+CurrentHumans;
    // g_Map_Timestamp_ID = g_Map_Timestamp_ID;
    // PrintToChatAll("Round Won: Timestamp: %s, Robot team was %i, Gametime was: %i Robot win? %i, ROBOT STR %s, MAP WAS %s", g_time, RobotTeam, total_gametime, robot_team_win, win_team_str,g_map_name);


    // timestamp, , total_gametime, g_map_name. player_count, CurrentRobots, CurrentHumans,robot_team_win
    // SQL_FastQuery(hDatabase, "INSERT INTO mm_robot_win (timestamp, team, total_gametime, map, player_count, robot_team_win) VALUES (NOW(), 'RED', 600, 'cp_dustbowl', 12, 1)");    

    // Create the SQL query string with formatted variables
   
    

    // PrintToChatAll("%s",g_ServerName);

    char query[1024];
    hDatabase.Format(query, sizeof(query), "INSERT INTO mm_robot_win (game_id_timestamp, win_team, total_gametime, map, player_count, robot_count, human_count, robot_team_win, server) VALUES ('%s', '%s', %i, '%s', %i, %i, %i, %i, '%s')", g_time, win_team_str, total_gametime, g_map_name, player_count, CurrentRobots, CurrentHumans, robot_team_win, g_ServerName);
    SQL_FastQuery(hDatabase, query);
    // char query[1024];
    // Format(query, sizeof(query), "INSERT INTO mm_robot_win (game_id_timestamp, win_team, total_gametime, map, player_count, robot_count, human_count, robot_team_win, server) VALUES ('%s', '%s', %i, '%s', %i, %i, %i, %i, '%s')", g_time, win_team_str, total_gametime, g_map_name, player_count, CurrentRobots, CurrentHumans, robot_team_win, g_ServerName);

    // Execute the SQL query in a threaded manner
    // hDatabase.Query(T_DBInsert, query);
   // Execute the SQL query


    //Code for individual players
    for(int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            char steamID[45];
            GetClientAuthId(i, AuthId_SteamID64, steamID, sizeof(steamID));
            if(StrEqual(steamID, "STEAM_ID_STOP_IGNORING_RETVALS")) {
            steamID = "BOT";
            }

            if (!IsAnyRobot(i))
            {
                // char query[1024];
                // Get the player's current class
                int playerClass = TF2_GetPlayerClass(i);
                hDatabase.Format(query, sizeof(query), "INSERT INTO mm_robot_human_comp (game_id_timestamp, client_steamId, class, total_gametime) VALUES ('%s', '%s', %i, %i)", g_time, steamID, playerClass, total_gametime);
                SQL_FastQuery(hDatabase, query);
            }

            // if (!IsAnyRobot(i))
            // {
            // // Get the player's current class
            // int playerClass = TF2_GetPlayerClass(i);

            // char query[512];
            // Format(query, sizeof(query), "INSERT INTO mm_robot_human_comp (game_id_timestamp, client_steamId, class, total_gametime) VALUES ('%s', '%s', %d, %d)", g_time, steamID, playerClass, total_gametime);

            // Execute the SQL query in a threaded manner
            hDatabase.Query(T_DBInsert, query);
            // }

            if (IsAnyRobot(i))
            {
                char robotName[NAMELENGTH];
                Robot robot;
                GetRobot(i, robotName, NAMELENGTH);
                GetRobotDefinition(robotName, robot);
                // PrintToChatAll("Robot name was %s", robotName);
                hDatabase.Format(query, sizeof(query), "INSERT INTO mm_robot_individual_win (game_id_timestamp, client_steamId, robot_name, total_gametime, robot_team_win) VALUES ('%s', '%s', '%s', %i, %i)", g_time, steamID, robotName, total_gametime, robot_team_win);
                SQL_FastQuery(hDatabase, query);
            }

            // if (IsAnyRobot(i))
            // {
            //     char robotName[NAMELENGTH];
            //     Robot robot;
            //     GetRobot(i, robotName, NAMELENGTH);
            //     GetRobotDefinition(robotName, robot);

            //     char query[512];
            //     Format(query, sizeof(query), "INSERT INTO mm_robot_individual_win (game_id_timestamp, client_steamId, robot_name, total_gametime, robot_team_win) VALUES ('%s', '%s', '%s', %i, %i)", g_time, steamID, robotName, total_gametime, robot_team_win);

            //     // Execute the SQL query in a threaded manner
            //     hDatabase.Query(T_DBInsert, query);
            // }
        }
    }
    return Plugin_Continue;
}

public void T_DBInsert(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || error[0] != '\0')
    {
        LogError("Threaded query failed: %s", error);
    }
    else
    {
        // Query successful, handle the result if needed
    }
}
public void MM_PickRobotAndPreviousRobot(int client, int random, const char[] robotName)
{
    // MC_PrintToChatAll("Call was for %N with string:%s:", client, robotName);
    char steamID[45];
    GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID));
    if(StrEqual(steamID, "STEAM_ID_STOP_IGNORING_RETVALS")) {
    steamID = "BOT";
    }
    
    int team = GetClientTeam(client);
    char team_str[4];
    if (team == TFTeam_Blue) {
        team_str = "BLU";
    } else if (team == TFTeam_Red) {
        team_str = "RED";
    }
    else
    {
        team_str = "ERR";
    } 

    int pick_time = RoundToNearest(GetEngineTime());
    char query[1024];
    hDatabase.Format(query, sizeof(query), "INSERT INTO mm_robot_pickrate (game_id_timestamp, robot_name, map, team, random, pick_time, client_id, server) VALUES ('%s', '%s', '%s', '%s', %i, %i, '%s', '%s')", 
                                                                                g_time, robotName, g_map_name, team_str, g_random_robot[client], pick_time, steamID, g_ServerName);

    SQL_FastQuery(hDatabase, query);
    PrintToConsoleAll(query);
    g_random_robot[client] = false;
}

public void MM_WasRandomRobotForward(int client)
{
    g_random_robot[client] = true;
}