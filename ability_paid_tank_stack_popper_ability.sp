#pragma semicolon 1
#include <tf2_stocks>
#include <berobot_constants>
#include <berobot>
#include <sourcemod>
#include <tf2>

 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME "Stack Popper"

public Plugin:myinfo =
{
	name = "Stack Popper",
	author = "HiGPS | Bmod.TF",
	description = "Stack Popper",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_PlayerSpawn);

}
int mostCommonClasses[TFClass_Engineer+1] = {0};

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	// RequestFrame(DelayCheck, client);
    
    if (IsRobot(client, ROBOT_NAME))
    {
		// PrintToChatAll("Was robot name");
		GetMostCommonEnemyClasses(client,mostCommonClasses);
    }


    return Plugin_Continue;
}

// void DelayCheck(int client)
// {

// }
// // Function to populate an external array with the most common enemy classes
void GetMostCommonEnemyClasses(int client, int mostCommonClasses[TFClass_Engineer+1])
{
    TFTeam team = GetClientTeam(client);
    TFTeam enemyTeam = (team == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;
    int classCounts[TFClass_Engineer+1] = {0}; // Initialize all counts to 0

    // Clear the mostCommonClasses array
    for (int i = TFClass_Unknown; i <= TFClass_Engineer; i++)
    {
        mostCommonClasses[i] = 0;
    }
	for(int i = 1; i <= MaxClients+1; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) == enemyTeam)
		{
			TFClassType playerClass = TF2_GetPlayerClass(i);
            classCounts[playerClass]++;
			PrintToChatAll("Player class count: %i for class: %i", classCounts[playerClass],playerClass);
		}
	}

    // Find the highest class count
    int maxCount = 0;
    for (int i = TFClass_Scout; i <= TFClass_Engineer; i++)
    {
        if (classCounts[i] > maxCount)
        {
            maxCount = classCounts[i];
        }
    }

    // Mark all classes with the highest count
    bool found = false;
    for (int i = TFClass_Scout; i <= TFClass_Engineer; i++)
    {
        if (classCounts[i] == maxCount && maxCount > 0)
        {
            mostCommonClasses[i] = 1;
            found = true;
        }
    }

    // If no enemy or class found, set the player's class as the most common
    if (!found)
    {
        TFClassType playerClass = TF2_GetPlayerClass(client);
        if (playerClass >= TFClass_Unknown && playerClass <= TFClass_Engineer)
        {
            mostCommonClasses[playerClass] = 1;
        }
        else
        {
            mostCommonClasses[TFClass_Unknown] = 1;
        }
    }
	AnnounceMostCommonClasses(client, mostCommonClasses);
}



void AnnounceMostCommonClasses(int client, int mostCommonClasses[TFClass_Engineer+1])
{
    char message[256];
    StrCat(message, sizeof(message), "Stats boosted to destroy:\n");

    bool first = true; // Track if we're adding the first class to the message

	// TF2_RemoveCondition(client, TFCond_UberBulletResist);
	// TF2_RemoveCondition(client, TFCond_UberBlastResist);
	// TF2_RemoveCondition(client, TFCond_UberFireResist);
    for (int i = TFClass_Unknown; i <= TFClass_Engineer; i++)
    {
        if (mostCommonClasses[i] == 1)
        {
            // Append class names to the message
            switch(i)
            {
                case TFClass_Scout:
				{
					TF2_AddCondition(client, TFCond_UberBulletResist);
                    StrCat(message, sizeof(message), first ? "Scouts\n" : "Scouts\n");
					
				}
                case TFClass_Sniper:
				{
					TF2_AddCondition(client, TFCond_UberBulletResist);
                    StrCat(message, sizeof(message), first ? "Snipers\n" : "Snipers\n");
					
				}
                case TFClass_Soldier:
				{
					TF2_AddCondition(client, TFCond_UberBlastResist);
                    StrCat(message, sizeof(message), first ? "Soldiers\n" : "Soldiers\n");
				}

                case TFClass_DemoMan:
				{
					TF2_AddCondition(client, TFCond_UberBlastResist);
                    StrCat(message, sizeof(message), first ? "Demomen\n" : "Demomen\n");
					
				}
                case TFClass_Medic:
				{
					TF2_AddCondition(client, TFCond_UberBulletResist);
                    StrCat(message, sizeof(message), first ? "Medics\n" : "Medics\n");
					
				}

                case TFClass_Heavy:
				{
					TF2_AddCondition(client, TFCond_UberBulletResist);
                    StrCat(message, sizeof(message), first ? "Heavies\n" : "Heavies\n");
					
				}
                case TFClass_Pyro:
				{
					TF2_AddCondition(client, TFCond_UberFireResist);
                    StrCat(message, sizeof(message), first ? "Pyros\n" : "Pyros\n");
					

				}  
                case TFClass_Spy:
				{
                    
					TF2_AddCondition(client, TFCond_UberBulletResist);
					StrCat(message, sizeof(message), first ? "Spies\n" : "Spies\n");
				}   
                case TFClass_Engineer:
                {    
					
					TF2_AddCondition(client, TFCond_UberBulletResist);
					// TF2_AddCondition(client, TFCond_CritCanteen,-1.0);
					StrCat(message, sizeof(message), first ? "Engineers\n" : "Engineers\n");
				}   
            }
            if (first) first = false;
        }
    }

    if (first) // If no class was marked as most common
    {
        StrCat(message, sizeof(message), "Error not a number");
    }

    PrintCenterText(client, message);
}