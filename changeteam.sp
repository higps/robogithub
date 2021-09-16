#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "MrSquid"
#define PLUGIN_VERSION "1.0.1"

#define RED 2
#define BLUE 3
#define SPECTATE 1
#define UNASSIGNED 0

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required


public Plugin myinfo = 
{
	name = "Change Team",
	author = PLUGIN_AUTHOR,
	description = "Change team of a player or block a player from changing teams. Modified slightly.",
	version = PLUGIN_VERSION,
	url = ""
};

int blocked[MAXPLAYERS];
int blocked_team[MAXPLAYERS];
bool override = false;

public void OnPluginStart()
{	
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_changeteam", Command_changeTeam, ADMFLAG_SLAY, "Change the team of target");
	RegAdminCmd("sm_ct", Command_changeTeam, ADMFLAG_SLAY, "Change the team of target");
	
	RegAdminCmd("sm_changeteam_block", Command_changeTeamDisabled, ADMFLAG_SLAY, "Disable team changing for target");
	RegAdminCmd("sm_ctb", Command_changeTeamDisabled, ADMFLAG_SLAY, "Disable team changing for target");
	
	HookEvent("player_team", Event_playerTeam, EventHookMode_Pre);
	
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		blocked[i] = -1;
	}
}

public void OnMapEnd() //Clears the block list after map ends
{
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		blocked[i] = -1;
	}
}
public Action Command_changeTeamDisabled(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_changeteam_block <#userid|name> <0|1>");
		return Plugin_Handled;
	}
	
	char arg1[32], arg2[32];
	bool disable;
	
	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int num = StringToInt(arg2, 10);
	if (num == 0)
	{
		disable = false;
	}
	else if (num == 1)
	{
		disable = true;
	}
	else
	{
		ReplyToCommand(client, "Usage: sm_changeteam_block <#userid|name> <0|1>");
		return Plugin_Handled;
	}
	
	//get targets
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (!CanUserTarget(client, target_list[i]))
		{
			ReplyToCommand(client, "[SM] You cannot target this player.");
			return Plugin_Handled;
		}
	 
	 	for (int c = 0; c < MAXPLAYERS; c++)
		{
			if (blocked[c] != -1)
			{
				if (GetClientUserId(target_list[i]) == blocked[c] && disable == true)
				{
					// client is already blocked
					ReplyToCommand(client, "[SM] Changing teams disabled for %s.", target_name);
					return Plugin_Handled;
				}
				else if (GetClientUserId(target_list[i]) == blocked[c] && disable == false)
				{
					// unblock the blocked client
					blocked[c] = -1;
					ReplyToCommand(client, "[SM] Changing teams enabled for %s.", target_name);
					return Plugin_Handled;
				}
			}
		}
		
		for (int c = 0; c < MAXPLAYERS; c++)
		{
			if (-1 == blocked[c] && disable == true)
			{
				// block the client
				blocked[c] = GetClientUserId(target_list[i]);
				blocked_team[c] = GetClientTeam(target_list[i]);
				ReplyToCommand(client, "[SM] Changing teams disabled for %s.", target_name);
				return Plugin_Handled;
			}
			else if (-1 == blocked[c] && disable == false)
			{
				// client is already unblocked
				ReplyToCommand(client, "[SM] Changing teams enabled for %s.", target_name);
				return Plugin_Handled;
			}
		}
	}
	
 
	return Plugin_Handled;
}

public Action Command_changeTeam(int client, int args)
{
	override = true;
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_changeteam <#userid|name> [team]");
		override = false;
		return Plugin_Handled;
	}
	
	char arg1[32], arg2[32];
 
	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if (strcmp(arg2, "red", true) != 0 && strcmp(arg2, "blue", true) != 0 && strcmp(arg2, "spectate", true) != 0 && strcmp(arg2, "spec", true) != 0 && args == 2)
	{
		ReplyToCommand(client, "[SM] Invalid team specified.");
		override = false;
		return Plugin_Handled;
	}
	
	//get targets
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		override = false;
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (!CanUserTarget(client, target_list[i]))
		{
			ReplyToCommand(client, "You cannot target this player.");
			override = false;
			return Plugin_Handled;
		}
		if(args == 1)
		{			
			if(TF2_GetClientTeam(target_list[i]) == TFTeam_Red)
			{
				TF2_SwapTeamAndRespawn(target_list[i], BLUE);
			}
			else if(TF2_GetClientTeam(target_list[i]) == TFTeam_Blue)
			{
				TF2_SwapTeamAndRespawn(target_list[i], RED);
			}
		}
		if(args == 2)
		{
			if(TF2_GetClientTeam(target_list[i]) == TFTeam_Spectator)
			{
				if(strcmp(arg2, "red", false) == 0)
				{
					TF2_SwapTeamAndRespawn(target_list[i], RED);
				}
				else if(strcmp(arg2, "blue", false) == 0)
				{
					TF2_SwapTeamAndRespawn(target_list[i], BLUE);
				}
			}
			if(TF2_GetClientTeam(target_list[i]) == TFTeam_Red)
			{
				if(strcmp(arg2, "spectate", false) == 0 || strcmp(arg2, "spec", false) == 0)
				{
					TF2_SwapTeam(target_list[i], SPECTATE);
				}
				else if(strcmp(arg2, "blue", false) == 0)
				{
					TF2_SwapTeamAndRespawn(target_list[i], BLUE);
				}
			}
			if(TF2_GetClientTeam(target_list[i]) == TFTeam_Blue)
			{
				if(strcmp(arg2, "red", false) == 0)
				{
					TF2_SwapTeamAndRespawn(target_list[i], RED);
				}
				else if(strcmp(arg2, "spectate", false) == 0 || strcmp(arg2, "spec", false) == 0)
				{
					TF2_SwapTeam(target_list[i], SPECTATE);
				}
			}
		}
		for (int c = 0; c < MAXPLAYERS; c++)
		{
			//int teamID;
			if (blocked[c] != -1)
			{
				if (GetClientUserId(target_list[i]) == blocked[c])
				{
					switch(TF2_GetClientTeam(blocked_team[c]))
					{
						case TFTeam_Red:
						{
							blocked_team[c] = RED;
						}
						case TFTeam_Blue:
						{
							blocked_team[c] = BLUE;
						}
						case TFTeam_Spectator:
						{
							blocked_team[c] = SPECTATE;
						}
					}
				}
			}
		}
		char name[MAX_NAME_LENGTH];
		GetClientName(target_list[i], name, sizeof(name));
		//MsgToClient(client, target_list[i], name);
		PrintToConsole(client, "%s has changed teams!", name);
		//PrintToChat(target_list[i], "You have been moved to team: %s", arg2);
	}
	
	return Plugin_Handled;
}


/*
stock void MsgToClient(int client, int target, char[] name)
{
	ReplyToCommand(client, "%s has changed teams!", name);
	case RED:
	{
		PrintToChat(client, "You have been moved to the RED team!");
	}
	case BLUE:
	{
		PrintToChat(client, "You have been moved to the BLU team!");
	}
	case SPECTATE:
	{
		PrintToChat(client, "You have been moved to the Spectator team!");
	}
}
*/
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

// Swaps a player to a specified team.

stock void TF2_SwapTeam(int client, int team)
{
	ChangeClientTeam(client, team);
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
		case SPECTATE:
		{
			PrintCenterText(client, "You have been moved to the Spectator team!");
		}
	}
}
// intercept and block client jointeam command if required

public Action OnClientCommand(int client, int args)
{
	char cmd[16];
 
	/* Get the argument */
	GetCmdArg(0, cmd, sizeof(cmd));
	
	if(strcmp(cmd, "jointeam", true) == 0)
	{
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (blocked[i] != -1)
			{
				if (client == GetClientOfUserId(blocked[i]) && override == false)
				{
					PrintToChat(client, "[SM] You are not currently allowed to change teams.");
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

// hook when client has changed teams
public Action Event_playerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		if (blocked[i] != -1)
		{
			if (client == GetClientOfUserId(blocked[i]) && override == false)
			{
				PrintToChat(client, "[SM] You are not currently allowed to change teams.");
				CreateTimer(1.5, Timer_rejoin, i);
				return Plugin_Handled;
			}
		}
	}
	override = false;
	return Plugin_Continue;
}
public Action Timer_rejoin(Handle timer, int index)
{
	char team[30];
	if (blocked_team[index] == RED)
	{
		strcopy(team, sizeof(team), "red");
	}
	else if (blocked_team[index] == BLUE)
	{
		strcopy(team, sizeof(team), "blue");
	}
	else if (blocked_team[index] == SPECTATE)
	{
		strcopy(team, sizeof(team), "spectate");
	}
	
	char cmd[99];
	Format(cmd, sizeof(cmd), "sm_changeteam #%d %s", blocked[index], team);
	ServerCommand(cmd);
}