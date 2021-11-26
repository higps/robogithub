#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <morecolors_newsyntax>
#include <team_round_timer>
#include <berobot_constants>
#include <berobot_core_resources>
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

ArrayList _resources[TEAMCOUNT];
int _teamResources[TEAMCOUNT];
char _lastUnrestrictedRobot[MAXPLAYERS + 1][NAMELENGTH];

public Plugin myinfo =
{
	name = "berobot_resource_team",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_resource_team started at %i", GetTime());

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
    CreateNative("AddTeamResource", Native_AddTeamResource);
    CreateNative("AddTeamResourceFor", Native_AddTeamResourceFor);
    CreateNative("GetTeamResource", Native_GetTeamResource);
    CreateNative("GetTeamResourceFor", Native_GetTeamResourceFor);
    CreateNative("PayResource", Native_PayResource);
    return APLRes_Success;
}

public any Native_AddTeamResourceFor(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    int amount = GetNativeCell(2);
    
    TFTeam team = view_as<TFTeam>(GetClientTeam(clientId));
    AddTeamResource(team, amount);
}

public any Native_AddTeamResource(Handle plugin, int numParams)
{
    TFTeam team = view_as<TFTeam>(GetNativeCell(1));
    int amount = GetNativeCell(2);
    
    _teamResources[team] = _teamResources[team] + amount;
    UpdateResources();
}

public any Native_GetTeamResourceFor(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);    
    TFTeam team = view_as<TFTeam>(GetClientTeam(clientId));
    
    return GetTeamResource(team);
}

public any Native_GetTeamResource(Handle plugin, int numParams)
{
    TFTeam team = view_as<TFTeam>(GetNativeCell(1));
    
    return _teamResources[team];
}

public any Native_PayResource(Handle plugin, int numParams)
{
    Resources resources = view_as<Resources>(GetNativeCell(1));
    int clientId = GetNativeCell(2);
    SMLogTag(SML_VERBOSE, "paying resources for %L ", clientId);
    
    TeamResource teamResource = resources.GetTeamResourceFor(clientId);
    char robotName[NAMELENGTH];
    teamResource.GetRobotName(robotName);

    if (!teamResource.Active)
    {
        SMLogTag(SML_VERBOSE, "%L paying nothing for %s, because it's free", clientId, robotName);
        return true;
    }
    if (!teamResource.Enabled)
    {
        SMLogTag(SML_ERROR, "%L could not pay for %s, because it's not enabled yet", clientId, robotName);
        return false;
    }
    
    int team = GetClientTeam(clientId);
    int price = teamResource.GetPrice();
    int available = _teamResources[team];
    if (price > available)
    {
        SMLogTag(SML_ERROR, "%L could not pay for %s, because price %i is too high (team-resources: %i)", clientId, robotName, price, available);
        return false;
    }

    SaveLastUnrestrictedRobot(clientId);

    SMLogTag(SML_VERBOSE, "%L paying %i from team %i's team-resources %i for %s", clientId, price, team, available, robotName);
    _teamResources[team] = available - price;
    UpdateResources();
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
    AddTeamResource(team, amount);

    return Plugin_Handled;
}

public void OnMapStart()
{
    SMLogTag(SML_VERBOSE, "OnMapStart called at %i", GetTime());
    GetResources();
    ResetTeamResources();
}

public void MM_OnRobotStorageChanged()
{
    SMLogTag(SML_VERBOSE, "MM_OnRobotStorageChanged called at %i", GetTime());
    GetResources();
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
    SMLogTag(SML_VERBOSE, "berobot_resource_team started at %i", GetTime());

    GetResources();
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
    ResetTeamResources();
}

void ResetTeamResources()
{
    for(TFTeam i = TFTeam_Unassigned; i <= TFTeam_Blue; i++)
    {
        _teamResources[i] = 0;
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

    TeamResource teamResource = robot.resources.GetTeamResourceFor(clientId);
    return teamResource.Active;
}

void UpdateResources()
{
    UpdateResourcesFor(TFTeam_Red);
    UpdateResourcesFor(TFTeam_Blue);
}

void UpdateResourcesFor(TFTeam team)
{
    for(int i = 0; i < _resources[team].Length; i++)
    {
        TeamResource resource = _resources[team].Get(i);
        char robotName[NAMELENGTH];
        resource.GetRobotName(robotName);

        int price = resource.GetPrice();
        if (price > _teamResources[team])
        {
            if (!resource.Enabled)
            {
                SMLogTag(SML_VERBOSE, "team %i robot %s: price %i not met (%i teamresources), but was disabled already", team, robotName, price, _teamResources[team]);
                continue;
            }

            SetResource(resource, robotName, false);
            continue;
        }
        if (resource.Enabled)
        {
            SMLogTag(SML_VERBOSE, "team %i robot %s: price %i is met (%i teamresources), but was enabled already", team, robotName, price, _teamResources[team]);
            continue;
        }

        SetResource(resource, robotName, true);
    }
}

void SetResource(TeamResource resource, char robotName[NAMELENGTH], bool enable)
{
    resource.Enabled = enable;

    OnResourceChanged(robotName);
    
    char msg[256];
    if (enable)
        Format(msg, sizeof(msg), "robot '%s' is not restricted by team-resources anymore", robotName);
    else
        Format(msg, sizeof(msg), "robot '%s' is restricted by team-resources again", robotName);

    SMLogTag(SML_VERBOSE, msg);
    MM_PrintToChatAll(msg);
}

void GetResources()
{
    if (!IsEnabled())
        return;

    ArrayList resources = GetRobotResources();
    SMLogTag(SML_VERBOSE, "%i TeamDeaths-resources found", resources.Length);

    GetResource(TFTeam_Red, resources);
    GetResource(TFTeam_Blue, resources);
}

void GetResource(TFTeam team, ArrayList resources)
{
    _resources[team] = new ArrayList();
    
    for(int i = 0; i < resources.Length; i++)
    {
        Resources item = resources.Get(i);

        TeamResource resource = item.GetTeamResource(team);
        if (resource == null)
        {
            SMLogTag(SML_ERROR, "could not find TeamResource for team %i", team);
            return;
        }

        if (resource.Active)
            _resources[team].Push(resource);        
    }

    _resources[team].SortCustom(TeamResourceComparision);
    
    SMLogTag(SML_VERBOSE, "%i team-resources for team %i set", _resources[team].Length, team);
    for(int i = 0; i < _resources[team].Length; i++)
    {
        TeamResource resource = _resources[team].Get(i);
        SMLogTag(SML_VERBOSE, "TeamResource set for team %i %i: %i PerRobot; %i Overall", team, i, resource.PerRobot, resource.Overall);
    }
}

int TeamResourceComparision(int index1, int index2, Handle array, Handle hndl)
{
    ArrayList list = view_as<ArrayList>(array); 
    TeamResource a = list.Get(index1);
    TeamResource b = list.Get(index2);

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