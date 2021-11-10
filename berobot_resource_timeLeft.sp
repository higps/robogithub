#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <morecolors_newsyntax>
#include <berobot_constants>
#include <berobot>
#include <berobot_core_resources>

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

ArrayList _resources;
Handle _timer;

public Plugin myinfo =
{
	name = "berobot_resource_timeLeft",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_resource_timeLeft started at %i", GetTime());

    if (!IsEnabled())
        return;

    _timer = CreateTimer(0.1, Tick);
}

public void OnMapStart()
{
    SMLogTag(SML_VERBOSE, "OnMapStart called at %i", GetTime());
    GetResources();
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
        KillResourceTimer();
        return;
    }

    GetResources();
    _timer = CreateTimer(0.1, Tick);
}

public void OnMapTimeLeftChanged()
{
    SMLogTag(SML_VERBOSE, "OnMapTimeLeftChanged called at %i", GetTime());

    KillResourceTimer();
    _timer = CreateTimer(0.1, Tick);
}

void KillResourceTimer()
{
    if (_timer == null)
        return;
    if (_timer == INVALID_HANDLE)
        return;

    KillTimer(_timer);
    _timer = null;
}

void GetResources()
{
    if (!IsEnabled())
        return;

    _resources = new ArrayList();

    ArrayList resources = GetRobotResources();
    SMLogTag(SML_VERBOSE, "%i TimeLeft-resources found", resources.Length);
    
    for(int i = 0; i < resources.Length; i++)
    {
        Resources item = resources.Get(i);

        if (!item.TimeLeft.Active)
            continue;
        
        _resources.Push(item.TimeLeft);
    }

    _resources.SortCustom(TimeLeftResourceComparision);
    

    SMLogTag(SML_VERBOSE, "%i TimeLeft-resources set", _resources.Length);
    for(int i = 0; i < _resources.Length; i++)
    {
        TimeLeftResource resource = _resources.Get(i);
        SMLogTag(SML_VERBOSE, "TimeLeft-resource %i set: %i", i, resource.SecondsBeforeEndOfRound);
    }
}
 
public Action Tick(Handle timer)
{
    if (!IsEnabled())
    {
        SMLogTag(SML_ERROR, "Tick skipped, because MM is disabled.");
        _timer = null;
        return Plugin_Stop;
    }

    int timeleft;
    if (!GetMapTimeLeft(timeleft))
    {
        SMLogTag(SML_ERROR, "GetMapTimeLeft not supported. TimeLeft-resources will not work.");
        _timer = null;
        return Plugin_Stop;
    }

    if (timeleft < 0)
    {
        SMLogTag(SML_INFO, "GetMapTimeLeft returned infinite. TimeLeft-resources will not work.");
        _timer = null;
        return Plugin_Stop;
    }
    SMLogTag(SML_VERBOSE, "timer tick with %i time left", timeleft);

    int nextResourceSecondsBeforeEndOfRound;
    int nextResourceIndex = MAX_INT;
    for(int i = 0; i < _resources.Length; i++)
    {
        TimeLeftResource resource = _resources.Get(i);
        if (resource.SecondsBeforeEndOfRound < timeleft)
        {
            nextResourceSecondsBeforeEndOfRound = resource.SecondsBeforeEndOfRound;
            nextResourceIndex = i;
            break;
        }

        if (resource.Enabled)
            continue;

        resource.Enabled = true;

        char robotName[NAMELENGTH];
        resource.GetRobotName(robotName);

        OnResourceChanged(robotName);

        char msg[256];
        Format(msg, sizeof(msg), "timelimit for robot '%s' is not restricted anymore", robotName);
        SMLogTag(SML_VERBOSE, msg);
        MM_PrintToChatAll(msg);
    }

    //make sure remaining resources are disabled
    for(int i = nextResourceIndex; i < _resources.Length; i++)
    {
        TimeLeftResource resource = _resources.Get(i);
        resource.Enabled = false;

        char robotName[NAMELENGTH];
        resource.GetRobotName(robotName);
        SMLogTag(SML_VERBOSE, "timelimit for robot '%s' is restricted", robotName);
    }

    if (nextResourceSecondsBeforeEndOfRound <= 0)
    {
        SMLogTag(SML_VERBOSE, "no further timeleft-resources. stopping loop");
        _timer = null;
        return Plugin_Stop;
    }

    float timeTillNextResource = float(timeleft - nextResourceSecondsBeforeEndOfRound);
    SMLogTag(SML_VERBOSE, "setting next timer tick in %f seconds", timeTillNextResource);    
    _timer = CreateTimer(timeTillNextResource, Tick);
    return Plugin_Stop;
}

int TimeLeftResourceComparision(int index1, int index2, Handle array, Handle hndl)
{
    ArrayList list = view_as<ArrayList>(array); 
    TimeLeftResource a = list.Get(index1);
    TimeLeftResource b = list.Get(index2);

    if (a.SecondsBeforeEndOfRound > b.SecondsBeforeEndOfRound)
        return -1;

    if (a.SecondsBeforeEndOfRound < b.SecondsBeforeEndOfRound)
        return 1;

    return 0;
}