#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <sm_logger>
#include <morecolors_newsyntax>
#include <berobot_constants>
#include <berobot>


char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum (<<= 1)
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

StringMap _vipSteamIds;
bool _automaticVolunteerVoteIsInProgress;
Handle _countdownTimer;
int _countdownTarget;
Handle _autoVolunteerTimer;
bool _pickedOption[MAXPLAYERS + 1];
bool _volunteered[MAXPLAYERS + 1];

public void OnPluginStart()
{
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    //aSMLOGTag(SML_INFO, "berobot_volunteer started at %i", GetTime());

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

    RegAdminCmd("sm_setvolunteer", Command_SetVolunteer, ADMFLAG_SLAY, "sets the volunteer status to true/enabled");
    RegAdminCmd("sm_unsetvolunteer", Command_UnsetVolunteer, ADMFLAG_SLAY, "sets the volunteer status to false/disabled");
    RegAdminCmd("sm_reload_vip_volunteers", Command_ReloadVipVolunteers, ADMFLAG_SLAY, "reloads VIP-SteamIds from file");

    RegConsoleCmd("sm_volunteer", Command_Volunteer, "Volunters you to be a giant robot");
    RegConsoleCmd("sm_vlntr", Command_Volunteer, "Volunters you to be a giant robot");

    LoadVipSteamIds();    

    Reset();
}

public void OnConfigsExecuted()
{
    _robocapTeamConVar = FindConVar(CONVAR_ROBOCAP_TEAM);
    _robocapTeamConVar.AddChangeHook(RobocapTeamCvarChangeHook);
    _robocapTeam = GetConVarInt(_robocapTeamConVar);
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
    _automaticVolunteerVoteIsInProgress = false;
    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        _volunteered[i] = false;
        _pickedOption[i] = false;
    }
}

void LoadVipSteamIds()
{
    _vipSteamIds = new StringMap();
    File file = OpenFile("mm_volunteer_vip.txt", "r");
    if (file == null)
    {
        //aSMLOGTag(SML_INFO, "VIPs could not be loaded, because file 'mm_volunteer_vip.txt' was not found", _vipSteamIds.Size);
        return;
    }

    while(!file.EndOfFile())
    {
        char steamId[64];
        file.ReadLine(steamId, sizeof(steamId));
        _vipSteamIds.SetValue(steamId, true);
    }
    CloseHandle(file);

    //aSMLOGTag(SML_INFO, "%i VIPs loaded", _vipSteamIds.Size);
}

public Action Command_ReloadVipVolunteers(int client, int args)
{
    LoadVipSteamIds();
}

public Action Command_SetVolunteer(int client, int args)
{
    if (!IsEnabled())
    {
        MM_PrintToChat(client, "Unable to volunteer, robot-mode is not enabled");
        //aSMLOGTag(SML_VERBOSE, "Command_SetVolunteer cancled for %L, because robot-mode is not enabled", client);
        return Plugin_Handled;
    }

    if (IsYTEnabled())
    {
        MM_PrintToChat(client, "Unable to volunteer, robot-mode is not enabled");
        //aSMLOGTag(SML_VERBOSE, "Command_SetVolunteer cancled for %L, because robot-mode is not enabled", client);
        return Plugin_Handled;
    }

    char target[32];
    if(args < 1)
    {
        target = "";
    }
    else
        GetCmdArg(1, target, sizeof(target));

    VolunteerTargets(client, target, true);

    return Plugin_Handled;
}

public Action Command_UnsetVolunteer(int client, int args)
{
    if (!IsEnabled())
    {
        MM_PrintToChat(client, "Unable to volunteer, robot-mode is not enabled");
        //aSMLOGTag(SML_VERBOSE, "Command_UnsetVolunteer cancled for %L, because robot-mode is not enabled", client);
        return Plugin_Handled;
    }

    char target[32];
    if(args < 1)
    {
        target = "";
    }
    else
        GetCmdArg(1, target, sizeof(target));

    VolunteerTargets(client, target, false);

    return Plugin_Handled;
}

public Action Command_Volunteer(int client, int args)
{
    //aSMLOGTag(SML_VERBOSE, "Command_Volunteer called for %L", client);

    if (!IsEnabled())
    {
        MM_PrintToChat(client, "Unable to volunteer, robot-mode is not enabled");
        //aSMLOGTag(SML_VERBOSE, "Command_Volunteer cancled for %L, because robot-mode is not enabled", client);
        return Plugin_Handled;
    }
    //     if (IsYTEnabled())
    // {
    //     MM_PrintToChat(client, "Unable to volunteer, because Youtube mode is active");
    //     //aSMLOGTag(SML_VERBOSE, "Command_Volunteer cancled for %L, because robot-mode is in youtube mode", client);
    //     return Plugin_Handled;
    // }

    // if (AutomaticVolunteerVoteIsInProgress()) 
    // {
    //     MM_PrintToChat(client, "Unable to volunteer, a vote for volunteers is in progress");
    //     return Plugin_Handled;
    // }

    char target[32];
    if(args < 1)
    {
        target = "";
    }
    else
        GetCmdArg(1, target, sizeof(target));

    VolunteerTargets(client, target, !_volunteered[client]);

    return Plugin_Handled;
}

public Action VolunteerTargets(int client, char target[32], bool volunteering)
{
    int targetFilter = 0;
    if(target[0] == '\0')
    {
        target = "@me";
        targetFilter = COMMAND_FILTER_NO_IMMUNITY;
    }

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if((target_count = ProcessTargetString(
          target,
          client,
          target_list,
          MAXPLAYERS,
          targetFilter,
          target_name,
          sizeof(target_name),
          tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    for(int i = 0; i < target_count; i++)
    {
        int targetClientId = target_list[i];
        Volunteer(targetClientId, volunteering);
    }

    return Plugin_Handled;
}

public Action Volunteer(int client, bool volunteering)
{
    _volunteered[client] = volunteering;
    _pickedOption[client] = true;

    if (volunteering)
        MM_PrintToChat(client, "You volunteered to be a robot.");
    else
    {
        MM_PrintToChat(client, "You no longer volunteer to be a robot.");
        UnmakeRobot(client);
    }

    EnsureRobotCount();
}

int Native_AutomaticVolunteerVoteIsInProgress(Handle plugin, int numParams)
{
    return _automaticVolunteerVoteIsInProgress;
}

int Native_GetRandomVolunteer(Handle plugin, int numParams)
{
    int length = GetNativeCell(2);
    int[] ignoredClientIds = new int[length];
    GetNativeArray(1, ignoredClientIds, length);
    //aSMLOGTag(SML_VERBOSE, "Native_GetRandomVolunteer read %i ignroedClientIds", length);

    ArrayList pickedVolunteers = PickVolunteers(1, ignoredClientIds, length, false);
    if (pickedVolunteers.Length <= 0)
        return -1;

    int clientId = pickedVolunteers.Get(0);
    //aSMLOGTag(SML_VERBOSE, "Native_GetRandomVolunteer picked %L", clientId);

    delete pickedVolunteers;

    return clientId;
}

int Native_StartAutomaticVolunteerVote(Handle plugin, int numParams)
{
    _automaticVolunteerVoteIsInProgress = true;
    for(int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsClientInGame(i))
            continue;
        if (_pickedOption[i])
        {            
            if (_volunteered[i])
                MM_PrintToChat(i, "You already volunteered to be a robot. type '!volunteer' to cancle your volunteer-state.");
            else
                MM_PrintToChat(i, "You already decided not volunteering to be a robot. type '!volunteer' to volunteer again.");
            continue;
        }
        
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
    if (remainingSeconds < 0)
        return Plugin_Stop;
        
    int volunteerCount = CountVolunteers();
    char verb[5];
    if (volunteerCount == 1)
        verb = "has";
    else
        verb = "have";
    PrintCenterTextAll("%i seconds left to vote. %i/%i %s volunteered so far. Random volunteers are picked to be robots.", remainingSeconds, volunteerCount, _robocapTeam, verb);
    
    return Plugin_Continue;
}

Action Timer_VolunteerAutomaticVolunteers(Handle timer)
{
    if (_countdownTimer != null)
    {
        KillTimer(_countdownTimer);
        _countdownTimer = null;
    }
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
    int[] ignoredClientIds = new int[0];
    ArrayList pickedVolunteers = PickVolunteers(_robocapTeam, ignoredClientIds, 0);

    int[] volunteerArray = new int[pickedVolunteers.Length];
    for(int i = 0; i < pickedVolunteers.Length; i++)
    {
        volunteerArray[i] = pickedVolunteers.Get(i);
        //aSMLOGTag(SML_VERBOSE, "setting %L as volunteered", volunteerArray[i]);
    }
    SetVolunteers(volunteerArray, pickedVolunteers.Length);

    delete pickedVolunteers;

    //aSMLOGTag(SML_VERBOSE, "setting _automaticVolunteerVoteIsInProgress to false");
    _automaticVolunteerVoteIsInProgress = false;
}

ArrayList PickVolunteers(int neededVolunteers, int[] ignoredClientIds, int ignoredClientIdsLength, bool pickNonvolunteers = true)
{
    StringMap ignoredClientIdLookup = new StringMap();
    for(int i = 0; i < ignoredClientIdsLength; i++)
    {
        int ignoredClientId = ignoredClientIds[i];
        char str[10];
        IntToString(ignoredClientId, str, 10);

        //aSMLOGTag(SML_VERBOSE, "adding %s for %i to ignored volunteers", str, ignoredClientId);
        ignoredClientIdLookup.SetValue(str, true);
    }

    ArrayList adminVolunteers = new ArrayList();
    ArrayList vipVolunteers = new ArrayList();
    ArrayList volunteers = new ArrayList();
    ArrayList nonVolunteers = new ArrayList();
    
    for(int i = 0; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
            continue;
        if (!IsClientInGame(i))
            continue;

        char str[10];
        IntToString(i, str, 10);
        bool value;
        if (ignoredClientIdLookup.GetValue(str, value))
        {
            //aSMLOGTag(SML_VERBOSE, "ignoring %L for picking volunteers", i);
            continue;
        }

        if (!_volunteered[i])
        {
            //aSMLOGTag(SML_VERBOSE, "%L has not volunteered", i);
            nonVolunteers.Push(i);
            continue;
        }

        if (_autoVolunteerAdminFlag >= 0)
        {
            int userflags = GetUserFlagBits(i);
            if (userflags & _autoVolunteerAdminFlag)
            {
                //aSMLOGTag(SML_VERBOSE, "%L has volunteered and gets prioritized, because they have admin-flag %i", i, _autoVolunteerAdminFlag);
                adminVolunteers.Push(i);
                continue;
            }
        }

        char steamId[64];
        GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));        
        if (_vipSteamIds.GetValue(steamId, value))
        {
            //aSMLOGTag(SML_VERBOSE, "%L has volunteered and gets prioritized, because they are a vip", i);
            vipVolunteers.Push(i);
            continue;
        }

        //aSMLOGTag(SML_VERBOSE, "%L has volunteered", i);
        volunteers.Push(i);
    }

    ArrayList pickedVolunteers = new ArrayList();
    AddVolunteers(pickedVolunteers, adminVolunteers, neededVolunteers);     //add adminVolunteers until we have enough
    AddVolunteers(pickedVolunteers, vipVolunteers, neededVolunteers);       //add vipVolunteers until we have enough
    AddVolunteers(pickedVolunteers, volunteers, neededVolunteers);          //add volunteers until we have enough

    if (pickNonvolunteers)
    {
        AddVolunteers(pickedVolunteers, nonVolunteers, neededVolunteers);   //add nonvolunteers until we have enough
    }

    while(pickedVolunteers.Length > neededVolunteers)      //remove volunteers until we have just enough
    {
        int i = GetRandomInt(0, pickedVolunteers.Length -1);
        pickedVolunteers.Erase(i);
    }

    delete adminVolunteers;
    delete volunteers;
    delete nonVolunteers;

    return pickedVolunteers;
}

void AddVolunteers(ArrayList destination, ArrayList source, int neededVolunteers)
{
    while(destination.Length < neededVolunteers)      
    {
        if (source.Length == 0)
            return;
        
        int i = GetRandomInt(0, source.Length -1);
        destination.Push(source.Get(i));
        source.Erase(i);
    }
}

bool EveryClientAnsweredVote()
{
    for(int i = 1; i <= MaxClients; i++)
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
    //aSMLOGTag(SML_VERBOSE, "AutomaticVolunteer-menu displayed to %L for %i seconds", client, timeout);

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
            KillTimer(_autoVolunteerTimer);
            if (_countdownTimer != null)
            {
                KillTimer(_countdownTimer);
                _countdownTimer = null;
            }
            VolunteerAutomaticVolunteers();
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