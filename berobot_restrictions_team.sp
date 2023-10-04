#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <morecolors>
#include <team_round_timer>
#include <berobot_constants>
#include <berobot_core_restrictions>
#include <berobot>
#include <tf2_stocks>

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

ArrayList _teamCoinRestrictions[TEAMCOUNT];
int _robotCoinsAvailable[TEAMCOUNT];
StringMap _robotCoinsSpent[TEAMCOUNT];
int _teamCoins[TEAMCOUNT];
char _lastUnrestrictedRobot[MAXPLAYERS + 1][NAMELENGTH];

public Plugin myinfo =
{
	name = "berobot_restrictions_team",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_restrictions_team started at %i", GetTime());

    char addRobotCoinsDescription[64];
    Format(addRobotCoinsDescription, sizeof(addRobotCoinsDescription), "add robot-coins for a team (%i for red; %i for blu)", TFTeam_Red, TFTeam_Blue);
    RegAdminCmd("sm_addrobotcoins", Command_AddRobotCoins, ADMFLAG_SLAY, addRobotCoinsDescription);
    RegAdminCmd("sm_addrbtcns", Command_AddRobotCoins, ADMFLAG_SLAY, addRobotCoinsDescription);
    RegAdminCmd("sm_arc", Command_AddRobotCoins, ADMFLAG_SLAY, addRobotCoinsDescription);
    SMLogTag(SML_INFO, "berobot_restrictions_team started at %i", GetTime());

    char addTeamCoinsDescription[64];
    Format(addTeamCoinsDescription, sizeof(addTeamCoinsDescription), "add team-coins for a team (%i for red; %i for blu)", TFTeam_Red, TFTeam_Blue);
    RegAdminCmd("sm_addteamcoins", Command_AddTeamCoins, ADMFLAG_SLAY, addTeamCoinsDescription);
    RegAdminCmd("sm_addtmcns", Command_AddTeamCoins, ADMFLAG_SLAY, addTeamCoinsDescription);
    RegAdminCmd("sm_atc", Command_AddTeamCoins, ADMFLAG_SLAY, addTeamCoinsDescription);

    TeamRoundTimer teamRoundTimer = new TeamRoundTimer();
    teamRoundTimer.HookOnFinished(OnRoundFinished);

    for(TFTeam i = TFTeam_Unassigned; i <= TFTeam_Blue; i++)
    {
        _robotCoinsSpent[i] = new StringMap();
    }

    if (IsEnabled())
        Start();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("AddRobotCoins", Native_AddRobotCoins);
    CreateNative("AddRobotCoinsFor", Native_AddRobotCoinsFor);
    CreateNative("AddTeamCoins", Native_AddTeamCoins);
    CreateNative("AddTeamCoinsFor", Native_AddTeamCoinsFor);
    CreateNative("GetRobotCoinsFor", Native_GetRobotCoinsFor);
    CreateNative("GetTeamCoinsFor", Native_GetTeamCoinsFor);
    CreateNative("PayRobotCoin", Native_PayRobotCoin);
    CreateNative("ResetCoins", Native_ResetCoins);
    return APLRes_Success;
}

public any Native_AddRobotCoinsFor(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    int amount = GetNativeCell(2);
    
    TFTeam team = view_as<TFTeam>(GetClientTeam(clientId));
    AddRobotCoins(team, amount);
}

public any Native_AddRobotCoins(Handle plugin, int numParams)
{
    TFTeam team = view_as<TFTeam>(GetNativeCell(1));
    int amount = GetNativeCell(2);
    
    _robotCoinsAvailable[team] = _robotCoinsAvailable[team] + amount;
    UpdateRestrictions();
}

public any Native_AddTeamCoinsFor(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    int amount = GetNativeCell(2);
    
    TFTeam team = view_as<TFTeam>(GetClientTeam(clientId));
    AddTeamCoins(team, amount);
}

public any Native_AddTeamCoins(Handle plugin, int numParams)
{
    TFTeam team = view_as<TFTeam>(GetNativeCell(1));
    int amount = GetNativeCell(2);
    
    _teamCoins[team] = _teamCoins[team] + amount;
    UpdateRestrictions();
}

public any Native_GetTeamCoinsFor(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    TFTeam team = view_as<TFTeam>(GetClientTeam(clientId));
    
    return _teamCoins[team];
}

public any Native_GetRobotCoinsFor(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    
    if (IsFakeClient(clientId))
        return 0;
    if (!IsValidClient(clientId))
        return 0;

    char steamId[64];
    TFTeam team = view_as<TFTeam>(GetClientTeam(clientId));
    int spentCoins = GetSpentRobotCoins(clientId, team, steamId);
    return _robotCoinsAvailable[team] - spentCoins;
}

public any Native_PayRobotCoin(Handle plugin, int numParams)
{
    Restrictions restrictions = view_as<Restrictions>(GetNativeCell(1));
    int clientId = GetNativeCell(2);
    SMLogTag(SML_VERBOSE, "paying coins for %L ", clientId);
    
    RobotCoins teamCoins = restrictions.GetTeamCoinsFor(clientId);
    RobotCoins robotCoins = restrictions.GetRobotCoinsFor(clientId);
    char robotName[NAMELENGTH];
    robotCoins.GetRobotName(robotName);

    if (!teamCoins.Active && !robotCoins.Active)
    {
        SMLogTag(SML_VERBOSE, "%L paying nothing for %s, because it's free", clientId, robotName);
        return true;
    }
    if (!teamCoins.Enabled)
    {
        SMLogTag(SML_ERROR, "%L could not pay team-coins for %s, because it's not enabled yet", clientId, robotName);
        return false;
    }
    
    TFTeam team = view_as<TFTeam>(GetClientTeam(clientId));

    char steamId[64];
    int spentRobotCoins = GetSpentRobotCoins(clientId, team, steamId);

    int availableRobotCoins = _robotCoinsAvailable[team] - spentRobotCoins;

    int priceRobotCoins = robotCoins.GetPrice();
    if (priceRobotCoins > availableRobotCoins)
    {
        SMLogTag(SML_ERROR, "%L could not pay robot-coins for %s, because price %i is too high (robot-coins: %i)", clientId, robotName, priceRobotCoins, availableRobotCoins);
        return false;
    }

    int availableTeamCoins = _teamCoins[team];
    int priceTeamCoins = teamCoins.GetPrice();
    if (priceTeamCoins > availableTeamCoins)
    {
        SMLogTag(SML_ERROR, "%L could not pay team-coins for %s, because price %i is too high (team-coins: %i)", clientId, robotName, priceTeamCoins, availableTeamCoins);
        return false;
    }

    SaveLastUnrestrictedRobot(clientId);

    SMLogTag(SML_VERBOSE, "%L paying %i of their %i robot-coins for %s", clientId, priceRobotCoins, availableRobotCoins, robotName);
    _robotCoinsSpent[team].SetValue(steamId, spentRobotCoins + priceRobotCoins);

    SMLogTag(SML_VERBOSE, "%L paying %i from team %i's team-coins %i for %s", clientId, priceTeamCoins, team, availableTeamCoins, robotName);
    _teamCoins[team] = availableTeamCoins - priceTeamCoins;

    UpdateRestrictions();
    return true;
}

public any Native_ResetCoins(Handle plugin, int numParams)
{
    Internal_ResetCoins();
}

public Action Command_AddRobotCoins(int client, int numParams)
{
    if (numParams < 2)
    {
        PrintToConsole(client, "parameters missing");
        PrintToConsole(client, "example: sm_addrobotcoins 2 50");
        return Plugin_Handled;
    }

    char rawTeam[2];
    GetCmdArg(1, rawTeam, sizeof(rawTeam));
    TFTeam team = view_as<TFTeam>(StringToInt(rawTeam));

    char rawAmount[64];
    GetCmdArg(2, rawAmount, sizeof(rawAmount));
    int amount = StringToInt(rawAmount);
    
    SMLogTag(SML_VERBOSE, "Command_AddRobotCoins: adding %i bot-coins for team %i", amount, team);
    AddRobotCoins(team, amount);

    return Plugin_Handled;
}

public Action Command_AddTeamCoins(int client, int numParams)
{
    if (numParams < 2)
    {
        PrintToConsole(client, "parameters missing");
        PrintToConsole(client, "example: sm_addteamcoins 2 50");
        return Plugin_Handled;
    }
    
    char rawTeam[2];
    GetCmdArg(1, rawTeam, sizeof(rawTeam));
    TFTeam team = view_as<TFTeam>(StringToInt(rawTeam));

    char rawAmount[64];
    GetCmdArg(2, rawAmount, sizeof(rawAmount));
    int amount = StringToInt(rawAmount);
    
    SMLogTag(SML_VERBOSE, "Command_AddTeamCoins: adding %i team-coins for team %i", amount, team);
    AddTeamCoins(team, amount);

    return Plugin_Handled;
}

public void OnMapStart()
{
    SMLogTag(SML_VERBOSE, "OnMapStart called at %i", GetTime());
    GetRestrictions();
    Internal_ResetCoins();

    for(int i = 0; i <= MaxClients; i++)
    {
        _lastUnrestrictedRobot[i] = "";
    }
}

public void MM_OnRobotStorageChanged()
{
    SMLogTag(SML_VERBOSE, "MM_OnRobotStorageChanged called at %i", GetTime());
    GetRestrictions();
}

public void MM_OnEnabledChanged(int enabled)
{
    SMLogTag(SML_VERBOSE, "MM_OnEnabledChanged called at %i with value %i", GetTime(), enabled);
    if (enabled == 0)
    {
        UnhookEvent("player_death", OnDeath, EventHookMode_PostNoCopy);
        return;
    }

    Start();
}

void Start()
{
    SMLogTag(SML_VERBOSE, "berobot_restrictions_team started at %i", GetTime());

    GetRestrictions();
    HookEvent("player_death", OnDeath, EventHookMode_PostNoCopy);

    Internal_ResetCoins();
}

public void OnClientConnected(int client)
{
    _lastUnrestrictedRobot[client] = "";
}

public void OnDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victimUserId = event.GetInt("userid", -1);
    int victimClientId = GetClientOfUserId(victimUserId);

    int deathflags = GetEventInt(event, "death_flags");

    

    if (!(deathflags & TF_DEATHFLAG_DEADRINGER)){
    SMLogTag(SML_VERBOSE, "OnDeath called at %i for %L with last unresticted robot %s", GetTime(), victimClientId, _lastUnrestrictedRobot[victimClientId]);

    if (_lastUnrestrictedRobot[victimClientId][0] == '\0')
    {
        SMLogTag(SML_VERBOSE, "not resetting %L's robot, because it was not bought", victimClientId);
        return;
    }

    int count = GetRobotCount(_lastUnrestrictedRobot[victimClientId]);
    int roboCap = GetRobotCap(_lastUnrestrictedRobot[victimClientId]);
    if (count >= roboCap)
    {
        SMLogTag(SML_VERBOSE, "resetting %L's bought robot to random after death, because %s is already taken", victimClientId, _lastUnrestrictedRobot[victimClientId]);
        SetRandomRobot(victimClientId);
        return;
    }
    
    SMLogTag(SML_VERBOSE, "resetting %L's bought robot to %s after death", victimClientId, _lastUnrestrictedRobot[victimClientId]);
    CreateRobot(_lastUnrestrictedRobot[victimClientId], victimClientId, "");
    _lastUnrestrictedRobot[victimClientId] = "";
    }
}

void OnRoundFinished(const char[] output, int caller, int activator, float delay)
{
    Internal_ResetCoins();
}

int GetSpentRobotCoins(int clientId, TFTeam team, char steamId[64])
{
    // steamId = "TEST";
    if (!GetClientAuthId(clientId, AuthId_Steam2, steamId, sizeof(steamId)))
    {
        SMLogTag(SML_ERROR, "could not read steamid for %L. using %i as spent RobotCoins", clientId, _robotCoinsAvailable[team]);
        return _robotCoinsAvailable[team];
    }
    SMLogTag(SML_VERBOSE, "%L has steamId %s", clientId, steamId);

    int spentCoins;
    if (!_robotCoinsSpent[team].GetValue(steamId, spentCoins))
    {
        SMLogTag(SML_VERBOSE, "could not read spent robot coins for %L. using %i as spent RobotCoins", clientId, _robotCoinsAvailable[team]);
        return 0;
    }

    SMLogTag(SML_VERBOSE, "%L (%s) currently spent %i robot-coins on team %i", clientId, steamId, spentCoins, team);
    return spentCoins;
}

void Internal_ResetCoins()
{
    for(TFTeam i = TFTeam_Unassigned; i <= TFTeam_Blue; i++)
    {
        _teamCoins[i] = 0;
        _robotCoinsAvailable[i] = 0;
        _robotCoinsSpent[i].Clear();
    }
}

void SaveLastUnrestrictedRobot(int clientId)
{
    SMLogTag(SML_VERBOSE, "SaveLastUnrestrictedRobot called for %L", clientId);

    if (!IsAnyRobot(clientId))
    {
        SMLogTag(SML_VERBOSE, "ignoring SaveLastUnrestrictedRobot for %L, because client is not a robot", clientId);
        return;
    }
        
    char robotName[NAMELENGTH];
    GetRobot(clientId, robotName, sizeof(robotName));

    if (IsPaidRobot(clientId, robotName))
    {
        SMLogTag(SML_VERBOSE, "ignoring SaveLastUnrestrictedRobot for %L, because client is paid robot", clientId);
        return;
    }

    SMLogTag(SML_VERBOSE, "SaveLastUnrestrictedRobot for %L to %s", clientId, robotName);
    _lastUnrestrictedRobot[clientId] = robotName;
}

bool IsPaidRobot(int clientId, char robotName[NAMELENGTH])
{
    Robot robot;
    GetRobotDefinition(robotName, robot);

    RobotCoins robotCoins = robot.restrictions.GetRobotCoinsFor(clientId);
    return robotCoins.Active;
}

void UpdateRestrictions()
{
    UpdateRestrictionsFor(TFTeam_Red);
    UpdateRestrictionsFor(TFTeam_Blue);
}

void UpdateRestrictionsFor(TFTeam team)
{
    for(int i = 0; i < _teamCoinRestrictions[team].Length; i++)
    {
        RobotCoins restriction = _teamCoinRestrictions[team].Get(i);
        char robotName[NAMELENGTH];
        restriction.GetRobotName(robotName);

        int price = restriction.GetPrice();
        if (price > _teamCoins[team])
        {
            if (!restriction.Enabled)
            {
                SMLogTag(SML_VERBOSE, "team %i robot %s: price %i not met (%i team-coins), but was disabled already", team, robotName, price, _teamCoins[team]);
                continue;
            }

            SetRestriciton(restriction, robotName, false);
            continue;
        }
        if (restriction.Enabled)
        {
            SMLogTag(SML_VERBOSE, "team %i robot %s: price %i is met (%i team-coins), but was enabled already", team, robotName, price, _teamCoins[team]);
            continue;
        }

        SetRestriciton(restriction, robotName, true);
    }
}

void SetRestriciton(RobotCoins restriction, char robotName[NAMELENGTH], bool enable)
{
    restriction.Enabled = enable;

    OnRestrictionChanged(robotName);
    
    // char msg[256];
    // if (enable)
        // Format(msg, sizeof(msg), "Robot '%s' now available for purchase", robotName);
    // else
        // Format(msg, sizeof(msg), "Robot '%s' currently not affordable", robotName);

    // SMLogTag(SML_VERBOSE, msg);
    // MM_PrintToChatAll(msg);
}

void GetRestrictions()
{
    if (!IsEnabled())
        return;

    ArrayList restrictions = GetRobotRestrictions();
    SMLogTag(SML_VERBOSE, "%i restrictions found", restrictions.Length);

    GetRestriction(TFTeam_Red, restrictions);
    GetRestriction(TFTeam_Blue, restrictions);
}

void GetRestriction(TFTeam team, ArrayList restrictions)
{
    _teamCoinRestrictions[team] = new ArrayList();
    
    for(int i = 0; i < restrictions.Length; i++)
    {
        Restrictions item = restrictions.Get(i);

        RobotCoins restriction = item.GetTeamCoins(team);
        if (restriction == null)
        {
            SMLogTag(SML_ERROR, "could not find TeamCoins for team %i", team);
            return;
        }

        if (restriction.Active)
            _teamCoinRestrictions[team].Push(restriction);        
    }

    _teamCoinRestrictions[team].SortCustom(RobotCoinsComparision);
    
    SMLogTag(SML_VERBOSE, "%i TeamCoins for team %i set", _teamCoinRestrictions[team].Length, team);
    for(int i = 0; i < _teamCoinRestrictions[team].Length; i++)
    {
        RobotCoins restriction = _teamCoinRestrictions[team].Get(i);
        SMLogTag(SML_VERBOSE, "TeamCoins set for team %i %i: %f PerRobot; %i Overall", team, i, restriction.PerRobot, restriction.Overall);
    }
}

int RobotCoinsComparision(int index1, int index2, Handle array, Handle hndl)
{
    ArrayList list = view_as<ArrayList>(array); 
    RobotCoins a = list.Get(index1);
    RobotCoins b = list.Get(index2);

    if (a.Overall < b.Overall)
        return -1;

    if (a.Overall > b.Overall)
        return 1;

    if (a.PerRobot < b.PerRobot)
        return -1;

    if (a.PerRobot > b.PerRobot)
        return 1;

    return 0;
}