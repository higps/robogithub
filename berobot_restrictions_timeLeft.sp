#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <sm_logger>
#include <morecolors_newsyntax>
#include <team_round_timer>
#include <berobot_constants>
#include <berobot>
#include <berobot_core_restrictions>

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

ArrayList _restriciton;
Handle _timer;

public Plugin myinfo =
{
	name = "berobot_restrictions_timeLeft",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

public void OnPluginStart()
{
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    //aSMLOGTag(SML_INFO, "berobot_restrictions_timeLeft started at %i", GetTime());

    if (!IsEnabled())
        return;

    Start();
}

public void MM_OnEnabledChanged(int enabled)
{
    //aSMLOGTag(SML_VERBOSE, "MM_OnEnabledChanged called at %i with value %i", GetTime(), enabled);
    if (enabled == 0)
    {
        KillRestrictionTimer();
        UnhookEvent("teamplay_setup_finished",    OnSetupFinished,   EventHookMode_PostNoCopy);
        UnhookEvent("teamplay_timer_time_added",  TimerTimeAdded,    EventHookMode_PostNoCopy);
        return;
    }

    GetRestrictions();
    Start();
}

public void OnMapStart()
{
    //aSMLOGTag(SML_VERBOSE, "OnMapStart called at %i", GetTime());

    GetRestrictions();
    KillRestrictionTimer();
    _timer = CreateTimer(0.1, Tick);
}

public void MM_OnRobotStorageChanged()
{
    //aSMLOGTag(SML_VERBOSE, "MM_OnRobotStorageChanged called at %i", GetTime());

    GetRestrictions();
    KillRestrictionTimer();
    _timer = CreateTimer(0.1, Tick);
}

public void TimerTimeAdded(Handle event, const char[] name, bool dontBroadcast)
{
    //aSMLOGTag(SML_VERBOSE, "TimerTimeAdded called at %i", GetTime());

    KillRestrictionTimer();
    _timer = CreateTimer(0.1, Tick);
}

public void OnSetupFinished(Handle event, const char[] name, bool dontBroadcast)
{
    //aSMLOGTag(SML_VERBOSE, "OnSetupFinished called at %i", GetTime());

    KillRestrictionTimer();
    _timer = CreateTimer(0.1, Tick);
}

void Start()
{
    HookEvent("teamplay_setup_finished",    OnSetupFinished,   EventHookMode_PostNoCopy);
    HookEvent("teamplay_timer_time_added",  TimerTimeAdded,    EventHookMode_PostNoCopy);

    KillRestrictionTimer();
    _timer = CreateTimer(0.1, Tick);
}

void KillRestrictionTimer()
{
    if (_timer == null)
        return;
    if (_timer == INVALID_HANDLE)
        return;

    KillTimer(_timer);
    _timer = null;
}

void GetRestrictions()
{
    if (!IsEnabled())
        return;

    _restriciton = new ArrayList();

    ArrayList restrictions = GetRobotRestrictions();
    //aSMLOGTag(SML_VERBOSE, "%i restrictions found", restrictions.Length);
    
    for(int i = 0; i < restrictions.Length; i++)
    {
        Restrictions item = restrictions.Get(i);

        if (!item.TimeLeft.Active)
            continue;
        
        _restriciton.Push(item.TimeLeft);
    }
    _restriciton.SortCustom(TimeLeftRestrictionComparision);

    //aSMLOGTag(SML_VERBOSE, "%i TimeLeft-restrictions set", _restriciton.Length);
    for(int i = 0; i < _restriciton.Length; i++)
    {
        TimeLeftRestriction restriction = _restriciton.Get(i);
        //aSMLOGTag(SML_VERBOSE, "TimeLeft-restriction %i set: %i", i, restriction.SecondsBeforeEndOfRound);
    }
}
 
Action Tick(Handle timer)
{
    if (!IsEnabled())
    {
        //aSMLOGTag(SML_INFO, "Tick skipped, because MM is disabled.");
        _timer = null;
        return Plugin_Stop;
    }

    TeamRoundTimer teamRoundTimer = new TeamRoundTimer();
    float endtime;
    if (!teamRoundTimer.GetEndTime(endtime))
    {
        //aSMLOGTag(SML_VERBOSE, "round is not timed. TimeLeft-restricitons will not work.");
        DisableFrom(0);
        _timer = null;
        return Plugin_Stop;
    }

    float gametime = GetGameTime();
    //aSMLOGTag(SML_VERBOSE, "timer tick with gametime %f; endtime %f", gametime, endtime);
    float timeleft = endtime - gametime;
    if (timeleft < 0)
    {
        //aSMLOGTag(SML_VERBOSE, "round is over. TimeLeft-restricitons will not work.");
        DisableFrom(0);
        _timer = null;
        return Plugin_Stop;
    }
    //aSMLOGTag(SML_VERBOSE, "timer tick with %f time left", timeleft);

    int nextRestricitionSecondsBeforeEndOfRound;
    int nextRestricitionIndex = MAX_INT;
    for(int i = 0; i < _restriciton.Length; i++)
    {
        TimeLeftRestriction restriction = _restriciton.Get(i);
        if (restriction.SecondsBeforeEndOfRound < timeleft)
        {
            nextRestricitionSecondsBeforeEndOfRound = restriction.SecondsBeforeEndOfRound;
            nextRestricitionIndex = i;
            break;
        }

        if (restriction.Enabled)
            continue;

        restriction.Enabled = true;

        char robotName[NAMELENGTH];
        restriction.GetRobotName(robotName);

        OnRestrictionChanged(robotName);

        char msg[256];
        Format(msg, sizeof(msg), "timelimit for robot '%s' is not restricted anymore", robotName);
        //aSMLOGTag(SML_VERBOSE, msg);
        MM_PrintToChatAll(msg);
    }

    //make sure remaining restricitions are disabled
    DisableFrom(nextRestricitionIndex);

    if (nextRestricitionSecondsBeforeEndOfRound <= 0)
    {
        float timeTillEnd = timeleft + 0.1;
        //aSMLOGTag(SML_VERBOSE, "no further timeleft-restricitions. setting end of loop in %f seconds", timeTillEnd);
        _timer = CreateTimer(timeTillEnd, Tick);
        return Plugin_Stop;
    }

    float timeTillNextRestricition = timeleft - float(nextRestricitionSecondsBeforeEndOfRound);
    if (timeTillNextRestricition < 0.1)
        timeTillNextRestricition = 0.1;
    //aSMLOGTag(SML_VERBOSE, "setting next timer tick in %f seconds", timeTillNextRestricition);
    _timer = CreateTimer(timeTillNextRestricition, Tick);
    return Plugin_Stop;
}

void DisableFrom(int startIndex)
{
    for(int i = startIndex; i < _restriciton.Length; i++)
    {
        TimeLeftRestriction restriction = _restriciton.Get(i);
        restriction.Enabled = false;

        char robotName[NAMELENGTH];
        restriction.GetRobotName(robotName);
        //aSMLOGTag(SML_VERBOSE, "timelimit for robot '%s' is restricted", robotName);
    }
}

int TimeLeftRestrictionComparision(int index1, int index2, Handle array, Handle hndl)
{
    ArrayList list = view_as<ArrayList>(array); 
    TimeLeftRestriction a = list.Get(index1);
    TimeLeftRestriction b = list.Get(index2);

    if (a.SecondsBeforeEndOfRound > b.SecondsBeforeEndOfRound)
        return -1;

    if (a.SecondsBeforeEndOfRound < b.SecondsBeforeEndOfRound)
        return 1;

    return 0;
}