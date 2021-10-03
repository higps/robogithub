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
    SML_ERROR,
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
bool _automaticVolunteerVoteIsInProgress;
int _neededRobots;
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

    Reset();
}

public void AutoVolunteerTimeoutCvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    _autoVolunteerTimeout = StringToInt(sNewValue);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("StartAutomaticVolunteerVote", Native_StartAutomaticVolunteerVote);
    CreateNative("AutomaticVolunteerVoteIsInProgress", Native_AutomaticVolunteerVoteIsInProgress);
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

int Native_StartAutomaticVolunteerVote(Handle plugin, int numParams)
{
    _automaticVolunteerVoteIsInProgress = true;
    Reset();
    _neededRobots = GetNativeCell(1);
    for(int i = 1; i < MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsClientInGame(i))
            continue;
        Menu_AutomaticVolunteer(i);
    }

    _autoVolunteerTimer = CreateTimer(float(_autoVolunteerTimeout), Timer_VolunteerAutomaticVolunteers);
}

Action Timer_VolunteerAutomaticVolunteers(Handle timer)
{
    VolunteerAutomaticVolunteers();
}

void VolunteerAutomaticVolunteers()
{
    ArrayList volunteers = new ArrayList();
    ArrayList nonVolunteers = new ArrayList();
    
    for(int i = 0; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
            continue;
        if (!IsClientInGame(i))
            continue;

        if (_volunteered[i])
        {
            SMLogTag(SML_VERBOSE, "%L has volunteered", i);
            volunteers.Push(i);
        }
        else
        {
            SMLogTag(SML_VERBOSE, "%L has not volunteered", i);
            nonVolunteers.Push(i);
        }
    }

    while(volunteers.Length < _neededRobots)        //add nonvolunteers until we have enough
    {
        if (nonVolunteers.Length == 0)
            break;
        
        int i = GetRandomInt(0, nonVolunteers.Length -1);
        volunteers.Push(nonVolunteers.Get(i));
        nonVolunteers.Erase(i);
    }
    while(volunteers.Length > _neededRobots)        //remove volunteers until we have just enough
    {
        int i = GetRandomInt(0, volunteers.Length -1);
        volunteers.Erase(i);
    }

    int[] volunteerArray = new int[volunteers.Length];
    for(int i = 0; i < volunteers.Length; i++)
    {
        volunteerArray[i] = volunteers.Get(i);
        SMLogTag(SML_VERBOSE, "setting %L as volunteered", volunteerArray[i]);
    }
    SetVolunteers(volunteerArray, volunteers.Length);
    _automaticVolunteerVoteIsInProgress = false;
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