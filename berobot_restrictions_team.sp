#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <morecolors_newsyntax>
#include <team_round_timer>
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

ArrayList _restrictions[TEAMCOUNT];
int _robotCoins[TEAMCOUNT];
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

    char description[64];
    Format(description, sizeof(description), "add robot-coins for a team (%i for red; %i for blu)", TFTeam_Red, TFTeam_Blue);
    RegAdminCmd("sm_addrobotcoins", Command_AddRobotCoins, ADMFLAG_SLAY, description);
    RegAdminCmd("sm_addrbtcns", Command_AddRobotCoins, ADMFLAG_SLAY, description);
    RegAdminCmd("sm_arc", Command_AddRobotCoins, ADMFLAG_SLAY, description);

    TeamRoundTimer teamRoundTimer = new TeamRoundTimer();
    teamRoundTimer.HookOnFinished(OnRoundFinished);

    if (IsEnabled())
        Start();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("AddRobotCoins", Native_AddRobotCoins);
    CreateNative("AddRobotCoinsFor", Native_AddRobotCoinsFor);
    CreateNative("GetRobotCoins", Native_GetRobotCoins);
    CreateNative("GetRobotCoinsFor", Native_GetRobotCoinsFor);
    CreateNative("PayRobotCoin", Native_PayRobotCoin);
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
    
    _robotCoins[team] = _robotCoins[team] + amount;
    UpdateRestrictions();
}

public any Native_GetRobotCoinsFor(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);    
    TFTeam team = view_as<TFTeam>(GetClientTeam(clientId));
    
    return GetRobotCoins(team);
}

public any Native_GetRobotCoins(Handle plugin, int numParams)
{
    TFTeam team = view_as<TFTeam>(GetNativeCell(1));
    
    return _robotCoins[team];
}

public any Native_PayRobotCoin(Handle plugin, int numParams)
{
    Restrictions restrictions = view_as<Restrictions>(GetNativeCell(1));
    int clientId = GetNativeCell(2);
    SMLogTag(SML_VERBOSE, "paying robot-coins for %L ", clientId);
    
    RobotCoins robotCoins = restrictions.GetRobotCoinsFor(clientId);
    char robotName[NAMELENGTH];
    robotCoins.GetRobotName(robotName);

    if (!robotCoins.Active)
    {
        SMLogTag(SML_VERBOSE, "%L paying nothing for %s, because it's free", clientId, robotName);
        return true;
    }
    if (!robotCoins.Enabled)
    {
        SMLogTag(SML_ERROR, "%L could not pay for %s, because it's not enabled yet", clientId, robotName);
        return false;
    }
    
    int team = GetClientTeam(clientId);
    int price = robotCoins.GetPrice();
    int available = _robotCoins[team];
    if (price > available)
    {
        SMLogTag(SML_ERROR, "%L could not pay for %s, because price %i is too high (robot-coins: %i)", clientId, robotName, price, available);
        return false;
    }

    SaveLastUnrestrictedRobot(clientId);

    SMLogTag(SML_VERBOSE, "%L paying %i from team %i's robot-coins %i for %s", clientId, price, team, available, robotName);
    _robotCoins[team] = available - price;
    UpdateRestrictions();
    return true;
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

public void OnMapStart()
{
    SMLogTag(SML_VERBOSE, "OnMapStart called at %i", GetTime());
    GetRestrictions();
    ResetRobotCoins();
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
}

public void OnDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victimUserId = event.GetInt("userid", -1);
    int victimClientId = GetClientOfUserId(victimUserId);
    SMLogTag(SML_VERBOSE, "OnDeath called at %i for %L (userid: %i) with last unresticted robot %s", GetTime(), victimClientId, victimUserId, _lastUnrestrictedRobot[victimUserId]);

    if (_lastUnrestrictedRobot[victimUserId][0] == '\0')
    {
        SMLogTag(SML_VERBOSE, "not resetting %L (userid: %i)'s robot, because it was not bought", victimClientId, victimUserId);
        return;
    }
    
    SMLogTag(SML_VERBOSE, "resetting %L (userid: %i)'s bought robot to %s after death", victimClientId, victimUserId, _lastUnrestrictedRobot[victimUserId]);
    CreateRobot(_lastUnrestrictedRobot[victimUserId], victimClientId, "");
    _lastUnrestrictedRobot[victimUserId] = "";
}

void OnRoundFinished(const char[] output, int caller, int activator, float delay)
{
    ResetRobotCoins();
}

void ResetRobotCoins()
{
    for(TFTeam i = TFTeam_Unassigned; i <= TFTeam_Blue; i++)
    {
        _robotCoins[i] = 0;
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
    GetPickedRobot(clientId, robotName, sizeof(robotName));

    if (IsPaidRobot(clientId, robotName))
    {
        SMLogTag(SML_VERBOSE, "ignoring SaveLastUnrestrictedRobot for %L, because client is paid robot", clientId);
        return;
    }

    int userId = GetClientUserId(clientId);
    SMLogTag(SML_VERBOSE, "SaveLastUnrestrictedRobot for %L (userid: %i) to %s", clientId, userId, robotName);
    _lastUnrestrictedRobot[userId] = robotName;
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
    for(int i = 0; i < _restrictions[team].Length; i++)
    {
        RobotCoins restriction = _restrictions[team].Get(i);
        char robotName[NAMELENGTH];
        restriction.GetRobotName(robotName);

        int price = restriction.GetPrice();
        if (price > _robotCoins[team])
        {
            if (!restriction.Enabled)
            {
                SMLogTag(SML_VERBOSE, "team %i robot %s: price %i not met (%i robot-coins), but was disabled already", team, robotName, price, _robotCoins[team]);
                continue;
            }

            SetRestriciton(restriction, robotName, false);
            continue;
        }
        if (restriction.Enabled)
        {
            SMLogTag(SML_VERBOSE, "team %i robot %s: price %i is met (%i robot-coins), but was enabled already", team, robotName, price, _robotCoins[team]);
            continue;
        }

        SetRestriciton(restriction, robotName, true);
    }
}

void SetRestriciton(RobotCoins restriction, char robotName[NAMELENGTH], bool enable)
{
    restriction.Enabled = enable;

    OnRestrictionChanged(robotName);
    
    char msg[256];
    if (enable)
        Format(msg, sizeof(msg), "robot '%s' is not restricted by robot-coins anymore", robotName);
    else
        Format(msg, sizeof(msg), "robot '%s' is restricted by robot-coins again", robotName);

    SMLogTag(SML_VERBOSE, msg);
    MM_PrintToChatAll(msg);
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
    _restrictions[team] = new ArrayList();
    
    for(int i = 0; i < restrictions.Length; i++)
    {
        Restrictions item = restrictions.Get(i);

        RobotCoins restriction = item.GetRobotCoins(team);
        if (restriction == null)
        {
            SMLogTag(SML_ERROR, "could not find RobotCoins for team %i", team);
            return;
        }

        if (restriction.Active)
            _restrictions[team].Push(restriction);        
    }

    _restrictions[team].SortCustom(RobotCoinsComparision);
    
    SMLogTag(SML_VERBOSE, "%i robot-coins for team %i set", _restrictions[team].Length, team);
    for(int i = 0; i < _restrictions[team].Length; i++)
    {
        RobotCoins restriction = _restrictions[team].Get(i);
        SMLogTag(SML_VERBOSE, "RobotCoins set for team %i %i: %i PerRobot; %i Overall", team, i, restriction.PerRobot, restriction.Overall);
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