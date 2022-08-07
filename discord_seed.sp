#pragma semicolon 1

#define PLUGIN_VERSION "1.1.2"

#include <sourcemod>
#include <morecolors>
#include <discord_api>
#include <SteamWorks>
#include <sdktools>
#include <prettymap>

#define ctftag "{creators}>>{default} "

public Plugin myinfo ={
	name = "[Discord] Server Seeding",
	author = "Nanochip",
	description = "Helps populate servers that have little to no players on them.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/xNanochip"
};

ConVar cvChannelID;
ConVar cvBotToken;
ConVar cvSeedDelay;
ConVar cvSeedMessage;
ConVar cvFollowingSeedMessage;
ConVar cvPlayerCount;
ConVar cvMaxPlayers;
ConVar cvUserID;

char g_sBotToken[128];
char g_sServerName[128];
char g_sServerNamePartial[128];
char g_sChannelID[64];
char g_sSeedMessage[256];
char g_sUserID[64];
char g_sSteamConnect[64];
char g_sCurrentMap[64];

char g_sLastMessageID[64];
float g_LastSeedTimeUntil;

int g_iMaxPlayers;
int g_iPlayerCount;

DiscordBot gBot = null;

float g_fSeedCooldown = 0.0;
float g_fSeedCooldownServer = 0.0;

//Hi-Bot

public void OnPluginStart()
{
	cvChannelID = CreateConVar("discord_seed_channelid", "1005845596034310195", "Which discord channel ID should the seed messages be sent to?");
	cvBotToken = CreateConVar("discord_seed_token", "OTc2MDk4MzE0ODIwOTMxNTg0.Gwr5S-.ocrSzC_mv1JrfurdlcCIAJz8e2o05wSi-l0JKw", "Bot token");
	cvSeedDelay = CreateConVar("discord_seed_delay", "900.0", "Time in seconds before another discord seed can be sent. 900 seconds = 15min.");
	cvSeedMessage = CreateConVar("discord_seed_message", "**{player}** wants to populate this server!\n||{steamid}||\n\nServer: `{server}`\nMap: `{map}`\nPlayers: `{playercount}`\nConnect: {connectlink}", "The message that gets sent in discord.");
	cvFollowingSeedMessage = CreateConVar("discord_seed_followingmessage", "`{server}` is filling up with players!\nMap: `{map}`\nPlayers: `{playercount}`\nConnect: {connectlink}", "The message that gets sent in discord after players start joining.");
	cvPlayerCount = CreateConVar("discord_seed_playercount", "18", "Don't allow server seeding when there is greater than this number of players on the server.");
	cvMaxPlayers = CreateConVar("discord_seed_maxplayers", "24", "Max number of real players allowed on the server.");
	cvUserID = CreateConVar("discord_seed_userid", "976098314820931584", "The discord bot's userID.");

	FindConVar("hostname").GetString(g_sServerName, sizeof g_sServerName);
	strcopy(g_sServerNamePartial, sizeof g_sServerNamePartial, g_sServerName);
	g_sServerNamePartial[strlen(g_sServerNamePartial)-5] = '\0'; //remove the last 5 characters to remove the server ID number.

	cvChannelID.GetString(g_sChannelID, sizeof g_sChannelID);
	cvBotToken.GetString(g_sBotToken, sizeof g_sBotToken);
	cvUserID.GetString(g_sUserID, sizeof g_sUserID);

	cvChannelID.AddChangeHook(OnCvarChanged);
	cvPlayerCount.AddChangeHook(OnCvarChanged);
	cvMaxPlayers.AddChangeHook(OnCvarChanged);

	g_iPlayerCount = cvPlayerCount.IntValue;
	g_iMaxPlayers = cvMaxPlayers.IntValue;

	RegConsoleCmd("sm_seed", Cmd_Seed, "Alert discord looking-to-play role to help populate (or seed) the server.");
}

public int OnCvarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == cvChannelID) g_sChannelID[63] = cvChannelID.IntValue;
	if (cvar == cvPlayerCount) g_iPlayerCount = cvPlayerCount.IntValue;
	if (cvar == cvMaxPlayers) g_iMaxPlayers = cvMaxPlayers.IntValue;
}

public void OnMapStart()
{
	GetCurrentMap(g_sCurrentMap, sizeof g_sCurrentMap);
	if (StrContains(g_sCurrentMap, "workshop") != -1)
	{
		GetMapDisplayName(g_sCurrentMap, g_sCurrentMap, sizeof g_sCurrentMap);
	}

	cvSeedMessage.GetString(g_sSeedMessage, sizeof g_sSeedMessage);

	int ip[4];
	char sPort[16];
	FindConVar("hostport").GetString(sPort, sizeof sPort);
	SteamWorks_GetPublicIP(ip);
	Format(g_sSteamConnect, sizeof g_sSteamConnect, "steam://connect/%d.%d.%d.%d:%s", ip[0], ip[1], ip[2], ip[3], sPort);

	// Get our host name on map change/start in case our region name is different
	// This is here because of Stephanie's config & startup changes.
	FindConVar("hostname").GetString(g_sServerName, sizeof g_sServerName);
	strcopy(g_sServerNamePartial, sizeof g_sServerNamePartial, g_sServerName);
	g_sServerNamePartial[strlen(g_sServerNamePartial)-5] = '\0'; //remove the last 5 characters to remove the server ID number.
}

public void OnAllPluginsLoaded()
{
	//Create bot with a token
	gBot = new DiscordBot(g_sBotToken);
	gBot.MessageCheckInterval = 1.0;
	gBot.GetGuilds(GuildList);
}

public void GuildList(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data)
{
	//Retrieve all channels for the guild
	bot.GetGuildChannels(id, ChannelList);
}

public void ChannelList(DiscordBot bot, char[] guild, DiscordChannel Channel, any data)
{
	char sID[64];
	Channel.GetID(sID, sizeof sID);

	if (StrEqual(sID, g_sChannelID))
	{
		bot.StartListeningToChannel(Channel, OnMessageFromDiscord);
		CreateTimer(30.0, Timer_CheckIfListening); //sometimes it failes to retrieve messages, so let's check for that and retry.
	}
}

public Action Timer_CheckIfListening(Handle hTimer)
{
	if (!gBot.IsListeningToChannelID(g_sChannelID))
	{
		PrintToServer("[DISCORD SEED] The server wasn't listening to the channel, retrying...");
		gBot.GetGuilds(GuildList);
	}
}

public void OnClientPostAdminCheck(int client)
{
	// Once we're fully in a server and we can still update our old message,
	// send a new one here.
	if (GetEngineTime() < g_LastSeedTimeUntil)
	{
		// Delete this current message. We'll send a new one when it's actually deleted.
		PrintToServer("Attempting to delete on OnClientPostAdminCheck");
		gBot.DeleteMessageID(g_sChannelID, g_sLastMessageID, OnMessageDeleted, StringToInt(g_sLastMessageID));
	}
}

public void OnClientDisconnect(int client)
{
	// Update our old message here.
	if (GetEngineTime() < g_LastSeedTimeUntil)
	{
		PrintToServer("Attempting to delete on OnClientDisconnect");
		// Delete this current message. We'll send a new one when it's actually deleted.
		gBot.DeleteMessageID(g_sChannelID, g_sLastMessageID, OnMessageDeleted, StringToInt(g_sLastMessageID));
	}
}

public void OnMessageDeleted(DiscordBot bot, any data)
{
	// If the message we've deleted was our old message ID, send a new message.
	if (data == StringToInt(g_sLastMessageID) && GetRealClientCount() != 0)
	{
		// Grab our ConVar string.
		char sMessage[1024];
		cvFollowingSeedMessage.GetString(sMessage, sizeof(sMessage));

		// Construct the parts of our string.
		char sPlayers[8];
		Format(sPlayers, sizeof(sPlayers), "%d/%d", GetRealClientCount(), g_iMaxPlayers);
		char sPrettyMap[96];
		GetPrettyMapName(g_sCurrentMap, sPrettyMap, sizeof(sPrettyMap));

		// Finally, put our string together.
		ReplaceString(sMessage, sizeof sMessage, "{server}", g_sServerName);
		ReplaceString(sMessage, sizeof sMessage, "{map}", sPrettyMap);
		ReplaceString(sMessage, sizeof sMessage, "{playercount}", sPlayers);
		ReplaceString(sMessage, sizeof sMessage, "{connectlink}", g_sSteamConnect);

		// Send message to the discord, and update our last message.
		gBot.SendMessageToChannelID(g_sChannelID, sMessage);
	}
}

public void OnMessageFromDiscord(DiscordBot Bot, DiscordChannel Channel, DiscordMessage message)
{
	char userID[64];
	message.GetAuthor().GetID(userID, sizeof userID);

	char sMessage[1024];
	message.GetContent(sMessage, sizeof sMessage);

	if (StrEqual(userID, g_sUserID))
	{
		// Was this from our server?
		if (StrContains(sMessage, g_sServerName, false) != -1)
		{
			// Store our message ID for other purposes.
			message.GetID(g_sLastMessageID, sizeof(g_sLastMessageID));
		
			// We can send a new seed message for the next little while. This is set to 30 seconds
			// as we're allowing multiple messages (including followups) to be created.
			g_LastSeedTimeUntil = GetEngineTime() + 180.0;

			//quickplay server (or anything else)
			if (g_fSeedCooldown <= 0.0)
			{
				g_fSeedCooldown = cvSeedDelay.FloatValue;
				CreateTimer(1.0, Timer_SeedDelay, _, TIMER_REPEAT);
			}
		}
		else
		{
			if (StrContains(sMessage, g_sServerNamePartial, false) != -1)
			{
				// This wasn't from our server. What we'll do is type a message out in chat saying something along the lines of
				// "Server #201 is currently seeding with 7/24 players on koth_harvest." IF their playercount is greater than ours.
				// This is going to be very hacky, so enjoy the ride.
				
				// This is the structure of our message:
				/*
					@Looking to Play - Central NA
		
					dillonator ★ is looking to populate this server!
					STEAM_0:0:45522544
					
					Server: Creators.TF | Central NA | Quickplay | #201
					Map: koth_clearcut_b15
					Players: 3/24
					Connect: steam://connect/104.128.48.3:27015
				*/
				
				// Grab the position of the servers players in the string.
				int iPlayersStringPosition = StrContains(sMessage, "Players: ");
				if (iPlayersStringPosition != -1)
				{
					// Get map position.
					int iMapPosition = StrContains(sMessage, "Map: ");
					
					char sPlayers[2];
					int iPlayers;
					
					// Store the player count value. This is also very hacky.
					sPlayers[0] = sMessage[iPlayersStringPosition+9+1];		// The +1 is here to account for "`" characters.
					sPlayers[1] = sMessage[iPlayersStringPosition+10+1];	// The +1 is here to account for "`" characters.
					
					// Is this a '/' character? If so, we're dealing with double digits.
					if (sPlayers[1] != '/') iPlayers = StringToInt(sPlayers);
					else iPlayers = StringToInt(sPlayers[0]);
					
					// Is this playercount less than ours?
					if (GetRealClientCount() < iPlayers)
					{
						char sServerID[3];
						
						// Bit of a HACK to get the server ID.
						sServerID[0] = sMessage[iMapPosition-5];	// 2
						sServerID[1] = sMessage[iMapPosition-4];	// 0
						sServerID[2] = sMessage[iMapPosition-3];	// 1
						
						// Grab our map name. We'll do a bit of a HACK thing here where we'll compare the player
						// and map string positions.
						int iStartingPoint = iMapPosition + 5 + 1; // +5 here for "Map: ", The +1 is here to account for "`" characters.
						
						// 96 characters SHOULD hopefully be enough for maps.
						char sMapBuffer[96];
						int i = 0;
						
						// Grab characters to construct the mapname.
						do
						{
							sMapBuffer[i] = sMessage[iStartingPoint+i];
							if (sMessage[i+1] == '`') break;
							i++;
						} while (sMapBuffer[i-1] != '`');
						
						// Get the *fancy* mapname.
						char sPrettyMap[96];
						GetPrettyMapName(sMapBuffer, sPrettyMap, sizeof(sPrettyMap));
						
						// FINALLY - Let's construct our server message.
						// I'm going to hardcode the 24 player max for now as we're not doing MvM anytime soon. Bother
						// me if this needs to be changed - ZoNiCaL.
						MC_PrintToChatAll("Server %s is currently seeding with {lightgreen}%d/24{default} players on {lightgreen}%s{default}. You can connect to the server at {orange}bmod.tf/servers.", sServerID, iPlayers, sPrettyMap);
					}
				}
			}
		}
	}
}

public Action Timer_SeedDelay(Handle hTimer)
{
	if (g_fSeedCooldown > 0.0) g_fSeedCooldown--;
	else
	{
		g_fSeedCooldown = 0.0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Cmd_Seed(int client, int args)
{
	if (g_fSeedCooldownServer > 0.0)
	{
		int secs = RoundFloat(g_fSeedCooldownServer);
		if (secs >= 60)
		{
			int mins = RoundToFloor(secs/60.0);
			secs = secs - mins*60;
			MC_ReplyToCommand(client, "This server recently sent a seed ping, therefore you must wait another {lightgreen}%d minutes{default}, {lightgreen}%d seconds{default}.", mins, secs);
		}
		else MC_ReplyToCommand(client, "This server recently sent a seed ping, therefore you must wait another {lightgreen}%d seconds{default}.", secs);
		return Plugin_Handled;
	}

	if (g_fSeedCooldown > 0.0)
	{
		int secs = RoundFloat(g_fSeedCooldown);
		if (secs >= 60)
		{
			int mins = RoundToFloor(secs/60.0);
			secs = secs - mins*60;
			MC_ReplyToCommand(client, "There was recently a seed ping in this region, therefore you must wait another {lightgreen}%d minutes{default}, {lightgreen}%d seconds{default}.", mins, secs);
		}
		else MC_ReplyToCommand(client, "There was recently a seed ping in this region, therefore you must wait another {lightgreen}%d seconds{default}.", secs);
		return Plugin_Handled;
	}

	int playerCount = GetRealClientCount();
	if (playerCount > g_iPlayerCount)
	{
		MC_ReplyToCommand(client, "Server seeding is not allowed when there are {lightgreen}%d {default}or more players on the server.", g_iPlayerCount);
		return Plugin_Handled;
	}
	// if (playerCount == 0)
	// {
	// 	//Don't send if server is empty
	// 	return Plugin_Handled;
	// }

	char sPing[32];
	char sPlayers[32];
	char sMessage[1024];
	char name[MAX_NAME_LENGTH];
	char steamid[32];

	if (client != 0)
	{
		GetClientName(client, name, sizeof name);
		ReplaceString(name, sizeof name, "@", ""); // prevent an @everyone ping from a player's name (lol)
		ReplaceString(name, sizeof name, "mvm_", ""); // prevent a player name from making my checks think this seed ping is mvm related (spaghetti)
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof steamid);
	}

	// Get the *fancy* mapname.
	char sPrettyMap[96];
	GetPrettyMapName(g_sCurrentMap, sPrettyMap, sizeof(sPrettyMap));

	Format(sMessage, sizeof sMessage, "%s", g_sSeedMessage);
	
	// Format our message with server information.
	Format(sPlayers, sizeof sPlayers, "%d/%d", playerCount, g_iMaxPlayers);
	ReplaceString(sMessage, sizeof sMessage, "{player}", name);
	ReplaceString(sMessage, sizeof sMessage, "{steamid}", steamid);
	ReplaceString(sMessage, sizeof sMessage, "{server}", g_sServerName);
	ReplaceString(sMessage, sizeof sMessage, "{map}", sPrettyMap);
	ReplaceString(sMessage, sizeof sMessage, "{playercount}", sPlayers);
	ReplaceString(sMessage, sizeof sMessage, "{connectlink}", g_sSteamConnect);

	// gonna hard code the role pings for now, i know this is awful spaghetti, please ignore this
	// note from steph: use ce_region and ce_type cvars lol

	// I've gone ahead and removed all regions that are currently not supported. Add them back
	// later on! - ZoNiCaL.
	// if (StrContains(g_sServerName, "Central NA") != -1) 	sPing = "<@&802974792213987368>";
	// else if (StrContains(g_sServerName, "West EU") != -1) 	sPing = "<@&802974790527746068>";
	// else
	// {
	// 	MC_ReplyToCommand(client, "Could not find the server region for the current server. Please report this bug in discord, #bug-reports.");
	// 	return Plugin_Handled;
	// }
	
	// For testing purposes, do NOT send a ping.
	if (client < 1) sPing = "";

	// Format our finalised message, including our ping.
	Format(sMessage, sizeof(sMessage), "%s\n\n%s", sPing, sMessage);

	// Send message to Discord.
	gBot.SendMessageToChannelID(g_sChannelID, sMessage);
	MC_ReplyToCommand(client, "{orange}Message has been sent to discord.");

	// We can send a new seed message for the next little while. This is set to 30 seconds
	// as we're allowing multiple messages (including followups) to be created.
	g_LastSeedTimeUntil = GetEngineTime() + 180.0;

	//adding this here too in case they mass spam this command with console resulting in mass discord pings.
	if (g_fSeedCooldown <= 0.0)
	{
		g_fSeedCooldown = cvSeedDelay.FloatValue;
		CreateTimer(1.0, Timer_SeedDelay, _, TIMER_REPEAT);
	}

	return Plugin_Handled;
}

//only do this for mvm so people don't spam ping the same mission over and over
public Action Timer_SeedDelayServer(Handle hTimer)
{
	if (g_fSeedCooldownServer > 0.0) g_fSeedCooldownServer--;
	else
	{
		g_fSeedCooldownServer = 0.0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

OnClientPutInServer(int client)
{

}

stock int GetRealClientCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) /* && !IsFakeClient(i) && !IsClientSourceTV(i) && !IsClientReplay(i) */)
		{
			count++;
		}
	}
	return count;
}

stock bool TF2MvM_IsPlayingMvM()
{
	return (GameRules_GetProp("m_bPlayingMannVsMachine") != 0);
}
