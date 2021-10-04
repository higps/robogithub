#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR
}
#include <berobot_core>
#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "berobot_volunteer",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

ConVar _autoVolunteerTimeoutConVar;
int _autoVolunteerTimeout;
ConVar _autoVolunteerPriaoritizeAdminFlagConVar;
int _autoVolunteerAdminFlag;
ConVar _robocapTeamConVar;
int _robocapTeam;

bool _automaticVolunteerVoteIsInProgress;
Handle _countdownTimer;
int _countdownTarget;
Handle _autoVolunteerTimer;
bool _pickedOption[MAXPLAYERS + 1];
bool _volunteered[MAXPLAYERS + 1];

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_volunteer started at %i", GetTime());

    _autoVolunteerTimeoutConVar = CreateConVar("sm_auto_volunteer_timeout", "20", "duration the automatic volunteer-menu will be shown (in seconds) ('0' to disable)");
    _autoVolunteerTimeoutConVar.AddChangeHook(AutoVolunteerTimeoutCvarChangeHook);
    _autoVolunteerTimeout = GetConVarInt(_autoVolunteerTimeoutConVar);

    int defautlAdminFlag = ADMFLAG_ROOT;
    char defautlAdminFlagString[10];
    IntToString(defautlAdminFlag, defautlAdminFlagString, sizeof(defautlAdminFlagString));
    _autoVolunteerPriaoritizeAdminFlagConVar = CreateConVar("sm_auto_volunteer_prioitize_admin_flag", 
                                                            defautlAdminFlagString, 
                                                            "Users with this admin-flag get prioritized when picking volunteers. set to -1 to disable");
    _autoVolunteerPriaoritizeAdminFlagConVar.AddChangeHook(AutoVolunteerAdminFlagCvarChangeHook);
    _autoVolunteerAdminFlag = GetConVarInt(_autoVolunteerPriaoritizeAdminFlagConVar);

    _robocapTeamConVar = FindConVar(CONVAR_ROBOCAP_TEAM);
    _robocapTeamConVar.AddChangeHook(RobocapTeamCvarChangeHook);
    _robocapTeam = GetConVarInt(_robocapTeamConVar);

    Reset();
}

public void AutoVolunteerAdminFlagCvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    _autoVolunteerAdminFlag = StringToInt(sNewValue);
}

public void AutoVolunteerTimeoutCvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    _autoVolunteerTimeout = StringToInt(sNewValue);
}

public void RobocapTeamCvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    _robocapTeam = StringToInt(sNewValue);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("StartAutomaticVolunteerVote", Native_StartAutomaticVolunteerVote);
    CreateNative("AutomaticVolunteerVoteIsInProgress", Native_AutomaticVolunteerVoteIsInProgress);
    CreateNative("GetRandomVolunteer", Native_GetRandomVolunteer);
    return APLRes_Success;
}

public void OnMapStart()
{
    Reset();
}

void Reset()
{
    for(int i = 0; i < MAXPLAYERS; i++)
    {
        _volunteered[i] = false;
        _pickedOption[i] = false;
    }
}

int Native_AutomaticVolunteerVoteIsInProgress(Handle plugin, int numParams)
{
    return _automaticVolunteerVoteIsInProgress;
}

int Native_GetRandomVolunteer(Handle plugin, int numParams)
{
    ArrayList pickedVolunteers = PickVolunteers(1, false);
    if (pickedVolunteers.Length <= 0)
        return -1;

    return pickedVolunteers.Get(0);
}

int Native_StartAutomaticVolunteerVote(Handle plugin, int numParams)
{
    _automaticVolunteerVoteIsInProgress = true;
    Reset();
    for(int i = 1; i < MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsClientInGame(i))
            continue;
        Menu_AutomaticVolunteer(i);
    }

    _countdownTarget = GetTime() + _autoVolunteerTimeout;
    _autoVolunteerTimer = CreateTimer(float(_autoVolunteerTimeout), Timer_VolunteerAutomaticVolunteers);
    _countdownTimer = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
    Timer_Countdown(INVALID_HANDLE);
}

Action Timer_Countdown(Handle timer)
{
    int remainingSeconds = _countdownTarget - GetTime();
    int volunteerCount = CountVolunteers();
    char verb[5];
    if (volunteerCount == 1)
        verb = "has";
    else
        verb = "have";
    PrintCenterTextAll("%i seconds left to vote. %i/%i %s volunteered so far.", remainingSeconds, volunteerCount, _robocapTeam, verb);
}

Action Timer_VolunteerAutomaticVolunteers(Handle timer)
{
    KillTimer(_countdownTimer);
    VolunteerAutomaticVolunteers();
}

int CountVolunteers()
{
    int count = 0;
    for(int i = 0; i <= MaxClients; i++)
    {
        if (!_volunteered[i])
            continue;
        
        count++;
    }

    return count;
}

void VolunteerAutomaticVolunteers()
{
    ArrayList pickedVolunteers = PickVolunteers(_robocapTeam);

    int[] volunteerArray = new int[pickedVolunteers.Length];
    for(int i = 0; i < pickedVolunteers.Length; i++)
    {
        volunteerArray[i] = pickedVolunteers.Get(i);
        SMLogTag(SML_VERBOSE, "setting %L as volunteered", volunteerArray[i]);
    }
    SetVolunteers(volunteerArray, pickedVolunteers.Length);
    _automaticVolunteerVoteIsInProgress = false;
}

ArrayList PickVolunteers(int neededVolunteers, bool pickNonvolunteers = true)
{
    ArrayList adminVolunteers = new ArrayList();
    ArrayList volunteers = new ArrayList();
    ArrayList nonVolunteers = new ArrayList();
    ArrayList pickedVolunteers = new ArrayList();
    
    for(int i = 0; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
            continue;
        if (!IsClientInGame(i))
            continue;

        if (_volunteered[i])
        {
            if (_autoVolunteerAdminFlag >= 0)
            {
                int userflags = GetUserFlagBits(i);
                if (userflags & _autoVolunteerAdminFlag)
                {
                    SMLogTag(SML_VERBOSE, "%L has volunteered and gets prioritized, because they have admin-flag %i", i, _autoVolunteerAdminFlag);
                    adminVolunteers.Push(i);
                    continue;
                }
            }

            SMLogTag(SML_VERBOSE, "%L has volunteered", i);
            volunteers.Push(i);
        }
        else
        {
            SMLogTag(SML_VERBOSE, "%L has not volunteered", i);
            nonVolunteers.Push(i);
        }
    }

    while(pickedVolunteers.Length < neededVolunteers)      //add adminVolunteers until we have enough
    {
        if (adminVolunteers.Length == 0)
            break;
        
        int i = GetRandomInt(0, adminVolunteers.Length -1);
        pickedVolunteers.Push(adminVolunteers.Get(i));
        adminVolunteers.Erase(i);
    }

    while(pickedVolunteers.Length < neededVolunteers)      //add volunteers until we have enough
    {
        if (volunteers.Length == 0)
            break;
        
        int i = GetRandomInt(0, volunteers.Length -1);
        pickedVolunteers.Push(volunteers.Get(i));
        volunteers.Erase(i);
    }

    if (pickNonvolunteers)
    {
        while(pickedVolunteers.Length < neededVolunteers)   //add nonvolunteers until we have enough
        {
            if (nonVolunteers.Length == 0)
                break;
            
            int i = GetRandomInt(0, nonVolunteers.Length -1);
            pickedVolunteers.Push(nonVolunteers.Get(i));
            nonVolunteers.Erase(i);
        }
    }

    while(pickedVolunteers.Length > neededVolunteers)      //remove volunteers until we have just enough
    {
        int i = GetRandomInt(0, pickedVolunteers.Length -1);
        pickedVolunteers.Erase(i);
    }

    return pickedVolunteers;
}

bool EveryClientAnsweredVote()
{
    for(int i = 1; i < MaxClients; i++)
    {        
        if (!IsValidClient(i) || !IsClientInGame(i))
            continue;
        if (!_pickedOption[i])
            return false;
    }

    return true;
}

Action Menu_AutomaticVolunteer(int client)
{
    Menu menu = new Menu(MenuHandler);

    menu.SetTitle("Do you want to play as a robot?");
    menu.ExitButton = false;

    menu.AddItem(MENU_ANSWER_YES, "Yes");
    menu.AddItem(MENU_ANSWER_NO, "No");

    int timeout = _autoVolunteerTimeout;
    menu.Display(client, timeout);
    SMLogTag(SML_VERBOSE, "AutomaticVolunteer-menu displayed to %L for %i seconds", client, timeout);

    return Plugin_Handled;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if(action == MenuAction_Select)
    {
        char answer[32];
        bool found = menu.GetItem(param2, answer, sizeof(answer));
        PrintToConsole(param1, "You selected item: %d (found? %d answer: %s)", param2, found, answer);

        _volunteered[param1] = StrEqual(answer, MENU_ANSWER_YES);
        _pickedOption[param1] = true;
        if (EveryClientAnsweredVote())
        {
            VolunteerAutomaticVolunteers();            
            //if (IsValidHandle(_autoVolunteerTimer))
            KillTimer(_autoVolunteerTimer);
            KillTimer(_countdownTimer);
        }
    }
    /* If the menu was cancelled, print a message to the server about it. */
    else if(action == MenuAction_Cancel)
    {
        _volunteered[param1] = false;
    }

    /* If the menu has ended, destroy it */
    else if(action == MenuAction_End)
    {
        delete menu;
    }
}