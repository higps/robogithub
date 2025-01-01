/**
 * vim: set ai et ts=4 sw=4 :
 * File: remote.sp
 * Description: Remote Controlled Sentries
 * Author(s): twistedeuphoria,CnB|Omega,Tsunami,-=|JFH|=-Naris
 * Modified by: -=|JFH|=-Naris (Murray Wilson)
 *              -- Added Native interface
 *              -- Added build support
 *              -- Merged Tsunami's build limit
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#tryinclude "amp_node"
#tryinclude "ztf2grab"
#define REQUIRE_PLUGIN

#define MAXENTITIES 2048

#define PLUGIN_VERSION "5.1"

//#include <remote>
// These define the permissions
#define HAS_REMOTE 		            (1 << 0)
#define REMOTE_CAN_ZOMBIE		    (1 << 1)
#define REMOTE_CAN_STEAL		    (1 << 2)
#define REMOTE_CAN_BUILD_INSTANTLY	(1 << 3)
#define REMOTE_CAN_BUILD_FLOATING	(1 << 4)
#define REMOTE_CAN_BUILD_MINI       (1 << 5)
#define REMOTE_CAN_BUILD_LEVEL_1    (1 << 6)
#define REMOTE_CAN_BUILD_LEVEL_2    (1 << 7)
#define REMOTE_CAN_BUILD_LEVEL_3    (1 << 8)
#define REMOTE_CAN_BUILD_AMPLIFIER  (1 << 9)
#define REMOTE_CAN_BUILD_REPAIR     (1 << 10)

// These define the HasBuiltFlags
enum HasBuiltFlags (<<= 1)
{
    HasBuiltNothing = 0,
    HasBuiltDispenser = 1,
    HasBuiltTeleporterEntrance,
    HasBuiltTeleporterExit,
    HasBuiltSentry
}

#define REMOTE_CAN_BUILD            (REMOTE_CAN_BUILD_MINI|REMOTE_CAN_BUILD_LEVEL_1|REMOTE_CAN_BUILD_LEVEL_2|REMOTE_CAN_BUILD_LEVEL_3)
#define REMOTE_CAN_BUILD_UPGRADED   (REMOTE_CAN_BUILD_LEVEL_2|REMOTE_CAN_BUILD_LEVEL_3)
#define CAN_BUILD_ACTIVATED         REMOTE_CAN_BUILD_INSTANTLY

new g_RemoteObjectRef[MAXPLAYERS+1];
new bool:g_RemoteBuild[MAXPLAYERS+1];
new TFExtObjectType:g_RemoteType[MAXPLAYERS+1];
new g_WatcherEntRef[MAXPLAYERS+1];
new clientPermissions[MAXPLAYERS+1] = { -1, ... };
new Float:clientSpeed[MAXPLAYERS+1];
new Float:clientFallSpeed[MAXPLAYERS+1];
new Float:clientJumpSpeed[MAXPLAYERS+1];
new Float:clientPosition[MAXPLAYERS+1][3];

new Float:levelFactor[3] = { 0.50, 1.00, 1.50 };
new Float:defaultSpeed = 400.0;
new Float:defaultFallSpeed = -500.0;
new Float:defaultJumpSpeed = 2000.0;
new bool:defaultZombie = false;

// forwards
new Handle:g_fwdOnBuildCommand = INVALID_HANDLE;
new Handle:fwdOnBuildObject = INVALID_HANDLE;
new Handle:fwdOnControlObject = INVALID_HANDLE;

// convars
new Handle:cvarObjectsTxt = INVALID_HANDLE;
new Handle:cvarRemote = INVALID_HANDLE;
new Handle:cvarSteal = INVALID_HANDLE;
new Handle:cvarZombie = INVALID_HANDLE;
new Handle:cvarBuild = INVALID_HANDLE;
new Handle:cvarLevel = INVALID_HANDLE;
new Handle:cvarMini = INVALID_HANDLE;
new Handle:cvarInstant = INVALID_HANDLE;
new Handle:cvarAlways = INVALID_HANDLE;
new Handle:cvarFactor = INVALID_HANDLE;
new Handle:cvarSpeed = INVALID_HANDLE;
new Handle:cvarJump = INVALID_HANDLE;
new Handle:cvarFall = INVALID_HANDLE;

new Handle:cvarBuildEnabled = INVALID_HANDLE;
new Handle:cvarBuildImmunity = INVALID_HANDLE;

#if defined _amp_node_included
    new Handle:cvarAmp = INVALID_HANDLE;
    new Handle:cvarRepair = INVALID_HANDLE;
#endif

#if defined _amp_node_included || defined _ztf2grab_included
    stock bool:m_AmpNodeAvailable = false;
    stock bool:m_GravgunAvailable = false;
#endif

public Plugin:myinfo = {
    name = "Remote Control Sentries",
    author = "twistedeuphoria,CnB|Omega,Tsunami,-=|JFH|=-Naris",
    description = "Remotely control your sentries",
    version = PLUGIN_VERSION,
    url = "http://www.jigglysfunhouse.net"
};

/**
 * Description: Function to check the entity limit.
 *              Use before spawning an entity.
 */
#tryinclude <entlimit>
#if !defined _entlimit_included
    stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
        new max = GetMaxEntities();
        new count = GetEntityCount();
        new remaining = max - count;
        if (remaining <= warn)
        {
            if (count <= critical)
            {
                PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
                LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            else
            {
                PrintToServer("Caution: Entity count is getting high!");
                LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            return count;
        }
        else
            return 0;
    }
#endif

/**
 * Description: Stocks to return information about TF2 player condition, etc.
 */
#tryinclude <tf2_player>
#if !defined _tf2_player_included
    #define TF2_IsPlayerDisguised(%1)    TF2_IsPlayerInCondition(%1,TFCond_Disguised)
    #define TF2_IsPlayerCloaked(%1)      TF2_IsPlayerInCondition(%1,TFCond_Cloaked)
    #define TF2_IsPlayerDeadRingered(%1) TF2_IsPlayerInCondition(%1,TFCond_DeadRingered)
    #define TF2_IsPlayerBonked(%1)       TF2_IsPlayerInCondition(%1,TFCond_Bonked)
#endif

/**
 * Description: Functions to return infomation about TF2 objects.
 */
#tryinclude <tf2_objects>
#if !defined _tf2_objects_included
    enum TFExtObjectType
    {
        TFExtObject_Unknown = -1,
        TFExtObject_CartDispenser = 0,
        TFExtObject_Dispenser = 0,
        TFExtObject_Teleporter = 1,
        TFExtObject_Sentry = 2,
        TFExtObject_Sapper = 3,
        TFExtObject_TeleporterEntry,
        TFExtObject_TeleporterExit,
        TFExtObject_MiniSentry,
        TFExtObject_Amplifier,
        TFExtObject_RepairNode
    };

    stock const String:TF2_ObjectClassNames[TFExtObjectType][] =
    {
        "obj_dispenser",
        "obj_teleporter",
        "obj_sentrygun",
        "obj_sapper",
        "obj_teleporter", // _entrance
        "obj_teleporter", // _exit
        "obj_sentrygun",  // minisentry
        "obj_dispenser",  // amplifier
        "obj_dispenser"   // repair_node
    };

    stock const String:TF2_ObjectNames[TFExtObjectType][] =
    {
        "Dispenser",
        "Teleporter",
        "Sentry Gun",
        "Sapper",
        "Teleporter Entrance",
        "Teleporter Exit",
        "Mini Sentry Gun",
        "Amplifier",
        "Repair Node"
    };

    stock TF2_ObjectModes[TFExtObjectType] =
    {
        -1, // dispenser
        -1, // teleporter (either)
        -1, // sentrygun
        -1, // sapper
         0, // telporter_entrance
         1, // teleporter_exit
        -1, // minisentry
        -1, // amplifier
        -1  // repair_node
    };

    // Max Sentry Ammo for Level:         mini,   1,   2,   3, max
    stock const TF2_MaxSentryShells[]  = { 150, 100, 120, 144,  255 };
    stock const TF2_MaxSentryRockets[] = {   0,   0,   0,  20,   63 };
    stock const TF2_SentryHealth[]     = { 100, 150, 180, 216, 8191 };

    stock const TF2_MaxUpgradeMetal    = 200;
    stock const TF2_MaxDispenserMetal  = 400;

    stock TFExtObjectType:TF2_GetExtObjectType(entity, bool:specific=false)
    {
        decl String:class[5];
        if (GetEdictClassname(entity, class, sizeof(class)) &&
            strncmp(class, "obj_", 4) == 0)
        {
            new TFExtObjectType:type = TFExtObjectType:GetEntProp(entity, Prop_Send, "m_iObjectType");
            if (specific)
            {
                if (type == TFExtObject_Teleporter)
                {
                    type = (TF2_GetObjectMode(entity) == TFObjectMode_Exit)
                    ? TFExtObject_TeleporterExit
                    : TFExtObject_TeleporterEntry;
                }
                else if (type == TFExtObject_Sentry)
                {
                    if (GetEntProp(entity, Prop_Send, "m_bMiniBuilding"))
                    type = TFExtObject_MiniSentry;
                }
            }
            return type;
        }
        else
            return TFExtObject_Unknown;
    }
#endif

// build limits
new Handle:gTimer;       
new g_iMaxEntities = MAXENTITIES;
new bool:g_bNativeControl = false;
new bool:g_WasBuilt[MAXENTITIES];
new HasBuiltFlags:g_HasBuilt[MAXPLAYERS+1];

new Handle:cvarLimits[4][TFExtObjectType];
new g_isAllowed[MAXPLAYERS+1][TFExtObjectType]; // how many buildings each player is allowed

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2wearables>
#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>

float g_allow_sentry = 0.0;
// float g_allow_dispenser = 0.0;
// float g_allow_teleport_ent = 0.0;
// float g_allow_teleport_exit = 0.0;

bool HasStats(int client)
{   
    
    if (IsValidClient(client))
    {

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "remote-building-control", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
    // PrintToChatAll("Had stat");
    g_allow_sentry = ReadFloatVar(stat_buffer, "sentry", 1.0);
    // g_allow_dispenser = ReadFloatVar(stat_buffer, "dispenser", 1.0);
    // g_allow_teleport_ent = ReadFloatVar(stat_buffer, "tele-entrance", 1.0);
    // g_allow_teleport_exit = ReadFloatVar(stat_buffer, "tele-exit", 1.0);
	return true;
    }
    return false;
	
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("ControlRemote",Native_ControlRemote);
    CreateNative("SetRemoteControl",Native_SetRemoteControl);
    CreateNative("RemoteControlObject",Native_RemoteControlObject);
    CreateNative("StopControllingObject",Native_StopControllingObject);

    // Build Natives
    CreateNative("AddBuildingsToMenu",Native_AddBuildingsToMenu);
    CreateNative("DestroyBuildingMenu",Native_DestroyBuildingMenu);
    CreateNative("DestroyBuildings",Native_DestroyBuildings);
    CreateNative("CountBuildings",Native_CountBuildings);
    CreateNative("CountObjects",Native_CountObjects);

    // Build Limit Natives
    CreateNative("ControlBuild",Native_ControlBuild);
    // CreateNative("ResetBuild",Native_ResetBuild);
    CreateNative("CheckBuild",Native_CheckBuild);
    CreateNative("GiveBuild",Native_GiveBuild);

    // Register Forwards
    fwdOnBuildObject=CreateGlobalForward("OnBuildObject",ET_Hook,Param_Cell,Param_Cell);
    fwdOnControlObject=CreateGlobalForward("OnControlObject",ET_Hook,Param_Cell,Param_Cell,Param_Cell);

    // Build Limit Forwards
    g_fwdOnBuildCommand=CreateGlobalForward("OnBuildCommand",ET_Hook,Param_Cell,Param_Cell,Param_Cell,Param_Cell);

    RegPluginLibrary("remote");
    return APLRes_Success;
}

public OnPluginStart()
{		
    CreateConVar("sm_remote_version", PLUGIN_VERSION, "Remote Control/Build/Limit Buildings Version", FCVAR_REPLICATED|FCVAR_NOTIFY);

    cvarRemote = CreateConVar("sm_remote_enable", "1", "Enable or disable remote control.");
    cvarSteal = CreateConVar("sm_remote_steal", "0", "Set true to allow stealing other people's buildings.");
    cvarZombie = CreateConVar("sm_remote_zombie", "0", "Set false to stop controlling buildings when controller dies.");
    cvarBuild = CreateConVar("sm_remote_build", "0", "Set true to spawn desired building if it doesn't exist.");
    cvarLevel = CreateConVar("sm_remote_build_level", "1", "Max level building (sentry) that can be built.");
    cvarMini = CreateConVar("sm_remote_build_mini", "1", "Set true to allow mini sentries to be built.");
    cvarInstant = CreateConVar("sm_remote_instant", "0", "Set true to build buildings instantly (from the remote menu).");
    cvarAlways = CreateConVar("sm_remote_always_builds", "0", "Set true allow remote to always build new objects (within limits).");
    cvarFactor = CreateConVar("sm_remote_factor", "0.50", "Object Speed Factor: Specify either 1 factor (multiplied by (4 - upgrade level) or 3 values (one per upgrade level) separated with spaces");
    cvarSpeed = CreateConVar("sm_remote_speed", "300.0", "Speed at which remote objects move.");
    cvarJump = CreateConVar("sm_remote_jump", "2000.0", "Speed at which remote objects jump.");
    cvarFall = CreateConVar("sm_remote_fall", "500.0", "Speed at which remote objects fall.");
    cvarObjectsTxt = CreateConVar("sm_build_objects_txt", "0", "Set true if objects.txt has been modified to allow multiple buildings.");

    #if defined _amp_node_included
        cvarAmp = CreateConVar("sm_remote_build_amp", "1", "Set true to allow amplifiers to be built.");
        cvarRepair = CreateConVar("sm_remote_build_mini", "1", "Set true to allow repair nodes to be built.");

        HookConVarChange(cvarAmp, RemoteCvarChange);
        HookConVarChange(cvarRepair, RemoteCvarChange);
    #endif

    HookConVarChange(cvarRemote, RemoteCvarChange);
    HookConVarChange(cvarSteal, RemoteCvarChange);
    HookConVarChange(cvarZombie, RemoteCvarChange);
    HookConVarChange(cvarBuild, RemoteCvarChange);
    HookConVarChange(cvarMini, RemoteCvarChange);
    HookConVarChange(cvarInstant, RemoteCvarChange);
    HookConVarChange(cvarAlways, RemoteCvarChange);
    HookConVarChange(cvarFactor, RemoteCvarChange);
    HookConVarChange(cvarSpeed, RemoteCvarChange);
    HookConVarChange(cvarJump, RemoteCvarChange);

    //RegConsoleCmd("sm_remote_on", RemoteOn, "Start remote controlling your buildings(sentry gun).", 0);
    //RegConsoleCmd("sm_remote_off", RemoteOff, "Stop remote controlling your buildings.", 0);
    RegConsoleCmd("sm_remote", Remote, "Start/stop remote controlling your buildings(sentry gun).", 0);

    HookEvent("player_builtobject", PlayerBuiltObject);
    HookEvent("object_destroyed", ObjectDestroyed);
    HookEvent("player_death", PlayerDeathEvent);
    HookEvent("player_spawn",PlayerSpawnEvent);
    HookEvent("player_team",PlayerChangeTeamEvent);
    HookEventEx("teamplay_round_win",EventRoundOver,EventHookMode_PostNoCopy);
    HookEventEx("teamplay_round_stalemate",EventRoundOver,EventHookMode_PostNoCopy);
}


public OnConfigsExecuted()
{
    ParseFactorVar();
    defaultZombie = GetConVarBool(cvarZombie);
    defaultSpeed = GetConVarFloat(cvarSpeed);
    defaultJumpSpeed = GetConVarFloat(cvarJump);
    defaultFallSpeed = GetConVarFloat(cvarFall);
    if (defaultFallSpeed > 0)
        defaultFallSpeed *= -1.0;
}        

public OnMapStart()
{
    // start timer
    gTimer = CreateTimer(0.1, UpdateObjects, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    g_iMaxEntities  = GetMaxEntities();
}

public OnMapEnd()
{
    CloseHandle(gTimer);
}
ParseFactorVar()
{
    new String:factorValue[32];
    new String:values[sizeof(levelFactor)][8];
    GetConVarString(cvarFactor, factorValue , sizeof(factorValue));
    if (factorValue[0])
    {
        new count = ExplodeString(factorValue," ",values, sizeof(values), sizeof(values[]));
        if (count > sizeof(levelFactor))
            count = sizeof(levelFactor);

        new level=0;
        for (;level < count; level++)
            levelFactor[level] = StringToFloat(values[level]);

        for (;level < sizeof(levelFactor); level++)
            levelFactor[level] = levelFactor[level-1] + levelFactor[0];
    }
}

public Action:UpdateObjects(Handle:timer)
{
    for (new i=1;i<MaxClients;i++)
    {
        new ref = g_RemoteObjectRef[i];
        if (ref != 0 && IsClientInGame(i))
        {
            int i_object = EntRefToEntIndex(ref);
            if (i_object > 0)
            {
                new permissions = clientPermissions[i];
                new bool:zombie = (permissions < 0) ? ((permissions & REMOTE_CAN_ZOMBIE) != 0) : defaultZombie;
                if (!zombie && !IsPlayerAlive(i))
                    RemoteOff(i, 0);
                else
                {
                    if (permissions > 0) // Hack to find native bits
                    {
                        switch (TF2_GetPlayerClass(i))
                        {
                            case TFClass_Spy:
                            {
                                if (TF2_IsPlayerCloaked(i) || TF2_IsPlayerDeadRingered(i))
                                {
                                    RemoteOff(i, 0);
                                    continue;
                                }
                                else if (TF2_IsPlayerDisguised(i))
                                    TF2_RemovePlayerDisguise(i);
                            }
                            case TFClass_Scout:
                            {
                                if (TF2_IsPlayerBonked(i))
                                {
                                    RemoteOff(i, 0);
                                    continue;
                                }
                            }
                        }
                    }

                    new Float:speed = (clientSpeed[i] > 0.0) ? clientSpeed[i] : defaultSpeed;
                    new level = GetEntProp(i_object, Prop_Send, "m_iUpgradeLevel");
                    if (level > sizeof(levelFactor))
                        speed *= levelFactor[0];
                    else if (level > 0)
                        speed *= levelFactor[sizeof(levelFactor)-level];
                    else
                        speed *= levelFactor[sizeof(levelFactor)-1];

                    new Float:nspeed = speed * -1.0;

                    new Float:angles[3];
                    GetClientEyeAngles(i, angles);
                    angles[0] = 0.0;

                    new Float:fwdvec[3];
                    new Float:rightvec[3];
                    new Float:upvec[3];
                    GetAngleVectors(angles, fwdvec, rightvec, upvec);

                    new Float:vel[3];
                    vel[2] = (clientFallSpeed[i] < 0.0) ? clientFallSpeed[i] : defaultFallSpeed;

                    new buttons = GetClientButtons(i);
                    if (buttons & IN_FORWARD)
                    {
                        vel[0] += fwdvec[0] * speed;
                        vel[1] += fwdvec[1] * speed;
                    }
                    if (buttons & IN_BACK)
                    {
                        vel[0] += fwdvec[0] * nspeed;
                        vel[1] += fwdvec[1] * nspeed;
                    }
                    if (buttons & IN_MOVELEFT)
                    {
                        vel[0] += rightvec[0] * nspeed;
                        vel[1] += rightvec[1] * nspeed;
                    }
                    if (buttons & IN_MOVERIGHT)
                    {
                        vel[0] += rightvec[0] * speed;
                        vel[1] += rightvec[1] * speed;
                    }

                    if (buttons & IN_JUMP)
                    {
                        new flags = GetEntityFlags(i_object);
                        if (flags & FL_ONGROUND)
                            vel[2] += (clientJumpSpeed[i] > 0.0) ? clientJumpSpeed[i] : defaultJumpSpeed;
                    }

                    TeleportEntity(i_object, NULL_VECTOR, angles, vel);

                    /*
                    new Float:objectpos[3];
                    GetEntPropVector(object, Prop_Send, "m_vecOrigin", objectpos);

                    objectpos[0] += fwdvec[0] * -150.0;
                    objectpos[1] += fwdvec[1] * -150.0;
                    objectpos[2] += upvec[2] * 75.0;

                    new watcher = EntRefToEntIndex(g_WatcherEntRef[client]);
                    if (watcher > 0)
                        TeleportEntity(watcher, objectpos, angles, NULL_VECTOR);
                    */
                }
            }
            else
                RemoteOff(i, 0);
        }
    }
    return Plugin_Continue;
}

public Action:Remote(client, args)
{
    // PrintToChatAll("REMOTE args were %i for client %N", args, client);
    if(HasStats(client))
    {
        // PrintToChatAll("1");
        new objectRef = g_RemoteObjectRef[client];
        if (objectRef != 0 && EntRefToEntIndex(objectRef) > 0)
        {
            RemoteOff(client, args);
            // PrintToChatAll("11");
        }
        else
        {
            decl String:arg[64];
            GetCmdArg(0, arg, sizeof(arg));
            // PrintToChatAll("2");
            new TFExtObjectType:type = TFExtObject_Unknown;
            if (StrContains(arg, "sentry", false) >= 0)
                type = TFExtObject_Sentry;
            else if (StrContains(arg, "disp", false) >= 0)
                type = TFExtObject_Dispenser;
            else if (StrContains(arg, "enter", false) >= 0)
                type = TFExtObject_TeleporterEntry;
            else if (StrContains(arg, "exit", false) >= 0)
                type = TFExtObject_TeleporterExit;
            else if (GetCmdArgs() >= 1)
            {
                PrintToChatAll("3");
                GetCmdArg(1, arg, sizeof(arg));
                new value = StringToInt(arg);
                if (value >= 1)
                    type = TFExtObjectType:(value-1);
                else
                {
                    if (StrContains(arg, "sentry", false) >= 0)
                        type = TFExtObject_Sentry;
                    else if (StrContains(arg, "disp", false) >= 0)
                        type = TFExtObject_Dispenser;
                    else if (StrContains(arg, "enter", false) >= 0)
                        type = TFExtObject_TeleporterEntry;
                    else if (StrContains(arg, "exit", false) >= 0)
                        type = TFExtObject_TeleporterExit;
                }
            }
            // PrintToChatAll("4");
            RemoteControl(client, type);
        }


    }
        return Plugin_Handled;

}

public Action:RemoteOn(client, args)
{
    RemoteControl(client, TFExtObject_Unknown);
    return Plugin_Handled;
}

public Action:Build(client, args)
{
    decl String:arg[64];
    GetCmdArg(0, arg, sizeof(arg));

    new TFExtObjectType:type = TFExtObject_Unknown;
    if (StrContains(arg, "sentry", false) >= 0)
        type = TFExtObject_Sentry;
    else if (StrContains(arg, "disp", false) >= 0)
        type = TFExtObject_Dispenser;
    else if (StrContains(arg, "enter", false) >= 0)
        type = TFExtObject_TeleporterEntry;
    else if (StrContains(arg, "exit", false) >= 0)
        type = TFExtObject_TeleporterExit;
    else if (GetCmdArgs() >= 1)
    {
        GetCmdArg(1, arg, sizeof(arg));
        new value = StringToInt(arg);
        if (value >= 1)
            type = TFExtObjectType:(value-1);
        else
        {
            if (StrContains(arg, "sentry", false) >= 0)
                type = TFExtObject_Sentry;
            else if (StrContains(arg, "disp", false) >= 0)
                type = TFExtObject_Dispenser;
            else if (StrContains(arg, "enter", false) >= 0)
                type = TFExtObject_TeleporterEntry;
            else if (StrContains(arg, "exit", false) >= 0)
                type = TFExtObject_TeleporterExit;
        }
    }
    BuildObject(client, type);
    return Plugin_Handled;
}

RemoteControl(client, TFExtObjectType:type)
{
    new permissions = GetPermissions(client);
    if (permissions == 0)
    {
        PrintToChat(client, "You are not authorized to use remote controls.");
        return;
    }

    // Save the client's position so we can restore it later
    GetClientAbsOrigin(client, clientPosition[client]);

    new target = GetClientAimTarget(client, false);
    if (target > 0) 
    {
        type = TF2_GetExtObjectType(target, true);
        if (type < TFExtObject_Unknown)
        {
            if ((permissions & REMOTE_CAN_STEAL) ||
                GetEntPropEnt(target,  Prop_Send, "m_hBuilder") == client)
            {
                control(client, target, type);
            }
            else
            {
                PrintToChat(client, "You don't own that!");
            }
            return;
        }
    }

    if (type == TFExtObject_Unknown)
    {
        new Handle:menu=CreateMenu(ObjectSelected);
        SetMenuTitle(menu,"Remote Control which Building:");

        new sum = -1;
        new counts[TFExtObjectType];
        new bool:okToBuild = false;
        if ((permissions & REMOTE_CAN_BUILD) != 0)
        {
            if (!g_bNativeControl)
                GetAllowances(client);

            sum = CountBuildings(client, counts);
            for (new i=0; i < sizeof(g_isAllowed[]); i++)
            {
                new num = g_isAllowed[client][i];
                if (num < 0 || counts[i] < num)
                {
                    okToBuild = true;
                    break;
                }
            }

            AddMenuItem(menu,"0","Build a Dispenser",
                        (counts[TFExtObject_Dispenser] >= g_isAllowed[client][TFExtObject_Dispenser])
                        ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

            #if defined _amp_node_included
                if (m_AmpNodeAvailable)
                {
                    if ((permissions & REMOTE_CAN_BUILD_AMPLIFIER) != 0)
                    {
                        AddMenuItem(menu,"7","Build an Amplifier",
                                    (counts[TFExtObject_Dispenser] >= g_isAllowed[client][TFExtObject_Dispenser])
                                    ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                    }

                    if ((permissions & REMOTE_CAN_BUILD_REPAIR) != 0)
                    {
                        AddMenuItem(menu,"8","Build a Repair Node",
                                    (counts[TFExtObject_Dispenser] >= g_isAllowed[client][TFExtObject_Dispenser])
                                    ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                    }
                }
            #endif

            AddMenuItem(menu,"4","Build a Teleporter Entry",
                        (counts[TFExtObject_TeleporterEntry] >= g_isAllowed[client][TFExtObject_TeleporterEntry])
                        ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

            AddMenuItem(menu,"5","Build a Teleporter Exit",
                        (counts[TFExtObject_TeleporterExit] >= g_isAllowed[client][TFExtObject_TeleporterExit])
                        ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

            new flag = (counts[TFExtObject_Sentry] >= g_isAllowed[client][TFExtObject_Sentry])
                       ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;

            if ((permissions & REMOTE_CAN_BUILD_MINI))
                AddMenuItem(menu,"6","Build a Mini Sentry Gun", flag);

            if ((permissions & REMOTE_CAN_BUILD_LEVEL_1) != 0)
            {
                if ((permissions & REMOTE_CAN_BUILD_UPGRADED) == 0)
                    AddMenuItem(menu,"2","Build a Sentry Gun", flag);
                else
                {
                    AddMenuItem(menu,"9","Build a Level 1 Sentry Gun", flag);
                    AddMenuItem(menu,"10","Build a Level 2 Sentry Gun", flag);
                    if ((permissions & REMOTE_CAN_BUILD_LEVEL_3) != 0)
                        AddMenuItem(menu,"11","Build a Level 3 Sentry Gun", flag);
                }
            }

            AddMenuItem(menu,"12","Destroy a Structure", ((sum > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
        }

        if (sum != 0)
            sum = AddBuildingsToMenu(menu, client, false, counts, target);

        if (okToBuild)
            DisplayMenu(menu,client,MENU_TIME_FOREVER);
        else if (sum == 1)
        {
            CancelMenu(menu);
            control(client, target, TF2_GetExtObjectType(target));
            return;
        }
        else if (sum == 0)
        {
            CancelMenu(menu);
            PrintToChat(client, "You have nothing to remote control!");
        }
        else
            DisplayMenu(menu,client,MENU_TIME_FOREVER);
    }
    else
    {
        new objectid = -1;
        while ((objectid = FindEntityByClassname(objectid, TF2_ObjectClassNames[type])) != -1)
        {
            if (GetEntPropEnt(objectid, Prop_Send, "m_hBuilder") == client)
                break;
        }

        if (objectid <= 0 && ((permissions & REMOTE_CAN_BUILD) != 0))
        {
            if ((permissions & REMOTE_CAN_BUILD_INSTANTLY) == 0 &&
                TF2_GetPlayerClass(client) == TFClass_Engineer &&
                (GetConVarBool(cvarObjectsTxt) ||
                 CountObjects(client,TF2_ObjectClassNames[type], TF2_ObjectModes[type]) <= 0))
            {
                g_RemoteType[client] = type;
                g_RemoteBuild[client] = true;
                g_RemoteObjectRef[client] = 0;

                int i_object, mode;
                if (type == TFExtObject_TeleporterEntry ||
                    type == TFExtObject_TeleporterExit)
                {
                    i_object = _:TFExtObject_Teleporter;
                    mode = _:(type - TFExtObject_TeleporterEntry);
                }
                else if (type == TFExtObject_MiniSentry)
                {
                    i_object = _:TFExtObject_Sentry;
                    mode = 1; // Not sure if this will work?
                }
                else
                {
                    i_object =_:type;
                    mode = 0;
                }
                ClientCommand(client, "build %d %d", i_object, mode);
            }
            else
            {
                objectid = BuildSelectedObject(client, type, 1, true,
                                               .remote=((permissions & REMOTE_CAN_BUILD_INSTANTLY) == 0),
                                               .check=((permissions & REMOTE_CAN_BUILD_FLOATING) != 0));
            }
        }
        else if (objectid > 0)
            control(client, objectid, type);
        else
            PrintToChat(client, "%s not found!", TF2_ObjectNames[type]);
    }
}

BuildMenu(client, permissions, bool:control)
{
    if (!g_bNativeControl)
        GetAllowances(client);

    g_RemoteObjectRef[client] = 0;
    g_RemoteBuild[client] = control;
    new Handle:menu=CreateMenu(BuildSelected);
    SetMenuTitle(menu,"Build & Remote Control:");

    new counts[TFExtObjectType];
    new sum = CountBuildings(client, counts);

    AddMenuItem(menu,"0","Dispenser",
                (counts[TFExtObject_Dispenser] >= g_isAllowed[client][TFExtObject_Dispenser])
                ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

    #if defined _amp_node_included
        if (m_AmpNodeAvailable)
        {
            if ((permissions & REMOTE_CAN_BUILD_AMPLIFIER) != 0)
            {
                AddMenuItem(menu,"7","Amplifier",
                            (counts[TFExtObject_Dispenser] >= g_isAllowed[client][TFExtObject_Dispenser])
                            ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
            }

            if ((permissions & REMOTE_CAN_BUILD_REPAIR) != 0)
            {
                AddMenuItem(menu,"8","Repair Node",
                            (counts[TFExtObject_Dispenser] >= g_isAllowed[client][TFExtObject_Dispenser])
                            ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
            }
        }
    #endif

    AddMenuItem(menu,"4","Teleporter Entry",
                (counts[TFExtObject_TeleporterEntry] >= g_isAllowed[client][TFExtObject_TeleporterEntry])
                ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
                
    AddMenuItem(menu,"5","Teleporter Exit",
                (counts[TFExtObject_TeleporterExit] >= g_isAllowed[client][TFExtObject_TeleporterExit])
                ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

    new flag = (counts[TFExtObject_Sentry] >= g_isAllowed[client][TFExtObject_Sentry])
               ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;

    if ((permissions & REMOTE_CAN_BUILD_MINI) != 0)
        AddMenuItem(menu,"6","Mini Sentry Gun", flag);

    if ((permissions & REMOTE_CAN_BUILD_LEVEL_1) != 0)
    {
        if ((permissions & REMOTE_CAN_BUILD_UPGRADED) == 0)
            AddMenuItem(menu,"2","Sentry Gun", flag);
        else
        {
            AddMenuItem(menu,"9","Level 1 Sentry Gun", flag);
            AddMenuItem(menu,"10","Level 2 Sentry Gun", flag);
            if ((permissions & REMOTE_CAN_BUILD_LEVEL_3) != 0)
                AddMenuItem(menu,"11","Level 3 Sentry Gun", flag);
        }
    }

    AddMenuItem(menu,"12","Destroy Structure", ((sum > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
    DisplayMenu(menu,client,MENU_TIME_FOREVER);
}

public BuildSelected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        decl String:SelectionInfo[12];
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));

        new permissions = GetPermissions(client);
        new item = StringToInt(SelectionInfo);
        if (item == 12)
            DestroyBuildingMenu(client);
        else
        {
            new level;
            new bool:mini = false;
            new TFExtObjectType:type;
            if (item == 4)
            {
                type = TFExtObject_TeleporterEntry;
                level = 1;
            }
            else if (item == 5)
            {
                type = TFExtObject_TeleporterExit;
                level = 1;
            }
            else if (item == 6)
            {
                type = TFExtObject_Sentry;
                mini = true;
                level = 1;
            }
            else if (item == 7 || item == 8) // Amplifier || Repair Node
            {
                type = TFExtObject_Dispenser;
                level = 1;
            }
            else if (item >= 9)
            {
                type = TFExtObject_Sentry;
                level = item - 8;
            }
            else
            {
                type = TFExtObjectType:item;
                level = 1;
            }

            if ((permissions & REMOTE_CAN_BUILD_INSTANTLY) == 0 &&
                TF2_GetPlayerClass(client) == TFClass_Engineer &&
                (GetConVarBool(cvarObjectsTxt) ||
                 CountObjects(client,TF2_ObjectClassNames[selection], TF2_ObjectModes[selection]) <= 0))
            {
                g_RemoteType[client] = type;

                int i_object, mode;
                if (type == TFExtObject_TeleporterEntry ||
                    type == TFExtObject_TeleporterExit)
                {
                    i_object = _:TFExtObject_Teleporter;
                    mode = _:(type - TFExtObject_TeleporterEntry);
                }
                else if (type == TFExtObject_MiniSentry)
                {
                    i_object = _:TFExtObject_Sentry;
                    mode = 1; // Not sure if this will work?
                }
                else
                {
                    i_object =_:type;
                    mode = 0;
                }
                ClientCommand(client, "build %d %d", i_object, mode);
            }
            else
            {
                BuildSelectedObject(client, type, level, mini, .remote=g_RemoteBuild[client],
                                    .disable=((permissions & REMOTE_CAN_BUILD_INSTANTLY) == 0),
                                    .check=((permissions & REMOTE_CAN_BUILD_FLOATING) != 0));
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

BuildSelectedObject(client, TFExtObjectType:type, iLevel=1, bool:mini=false,
                    bool:shield=false, bool:disable=true, iHealth=-1,
                    iMaxHealth=-1, Float:flPercentage=1.0, bool:remote=false,
                    bool:drop=true, bool:check=true, Float:objectPosition[3]={0.0})
{
    new objectid = -1;

    if (TF2_GetPlayerClass(client) == TFClass_Spy)
    {
        if (TF2_IsPlayerCloaked(client) || TF2_IsPlayerDeadRingered(client))
            return objectid;
        else if (TF2_IsPlayerDisguised(client))
            TF2_RemovePlayerDisguise(client);
    }
    else if (GetClientTeam(client) < _:TFTeam_Red)
        return objectid;
    else if (check && !CheckBuild(client, type))
        return objectid;
    else if (IsEntLimitReached(.client=client, .message="unable to create tf2 building"))
        return objectid;

    new Action:res = Plugin_Continue;
    Call_StartForward(fwdOnBuildObject);
    Call_PushCell(client);
    Call_PushCell(type);
    Call_Finish(res);

    if (res == Plugin_Continue)
    {
        new Float:pos[3];
        GetClientAbsOrigin(client, pos);

        new Float:angles[3];
        if (!GetClientEyeAngles(client, angles))
            GetClientAbsAngles(client, angles);

        angles[0] = 0.0; // Remove any pitch
        angles[2] = 0.0; // and/or roll

        switch (type)
        {
            case TFExtObject_Sentry:
            {
                objectid = BuildSentry(client, pos, angles, iLevel, disable, mini, shield,
                                       iHealth, iMaxHealth, .flPercentage=flPercentage);
            }
            case TFExtObject_MiniSentry:
            {
                objectid = BuildSentry(client, pos, angles, iLevel, disable, true, shield,
                                       iHealth, iMaxHealth, .flPercentage=flPercentage);
            }
            case TFExtObject_Teleporter, TFExtObject_TeleporterEntry:
            {
                objectid = BuildTeleporterEntry(client, pos, angles, iLevel, disable,
                                                iHealth, iMaxHealth, flPercentage);
            }
            case TFExtObject_TeleporterExit:
            {
                objectid = BuildTeleporterExit(client, pos, angles, iLevel, disable,
                                               iHealth, iMaxHealth, flPercentage);
            }
            case TFExtObject_Dispenser, TFExtObject_Amplifier, TFExtObject_RepairNode:
            {
                objectid = BuildDispenser(client, pos, angles, iLevel, disable,
                                          iHealth, iMaxHealth, .flPercentage=flPercentage,
                                          .type=type);
            }
        }

        if (objectid > 0)
        {
            objectPosition[0] = pos[0];
            objectPosition[1] = pos[1];
            objectPosition[2] = pos[2];

            if (remote)
            {
                // Save the player's position so we can put him back.
                clientPosition[client][0] = pos[0];
                clientPosition[client][1] = pos[1];
                clientPosition[client][2] = pos[2];

                // Move player up ontop of new object
                new Float:size[3];
                GetEntPropVector(objectid, Prop_Send, "m_vecBuildMaxs", size);

                pos[2] += (size[2] * 1.1);
                TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);

                if (!control(client, objectid, type))
                {
                    if (type != TFExtObject_Teleporter &&
                        type != TFExtObject_TeleporterEntry &&
                        type != TFExtObject_TeleporterExit)
                    {
                        // Make it noclip so you don't get stuck
                        SetEntProp(objectid, Prop_Send, "m_CollisionGroup", 5);

                        // Teleport player back to floor.
                        pos[2] = clientPosition[client][2];
                        TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
                    }
                }
            }
            else
            {
                if (type == TFExtObject_Teleporter ||
                    type == TFExtObject_TeleporterEntry ||
                    type == TFExtObject_TeleporterExit)
                {
                    // Move player up ontop of new object
                    new Float:size[3];
                    GetEntPropVector(objectid, Prop_Send, "m_vecBuildMaxs", size);

                    pos[2] += (size[2] * 1.1);
                    TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
                }
                else
                {
                    // Make it noclip so you don't get stuck
                    SetEntProp(objectid, Prop_Send, "m_CollisionGroup", 5);
                }
            }

            #if defined _ztf2grab_included
                if (drop && m_GravgunAvailable)
                    DropEntity(objectid);
            #else
                #pragma unused drop
            #endif

            if (disable || !remote)
            {
                new Float:delay;
                switch (type)
                {
                    case TFExtObject_Sentry:      delay = float(iLevel) * (mini ? 2.5 : 10.0);
                    case TFExtObject_MiniSentry:  delay = float(iLevel) * 2.5;
                    default:                      delay = 20.0;
                }
                CreateTimer(delay, Activate, EntIndexToEntRef(objectid), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }

    return objectid;
}

CountBuildings(client, counts[TFExtObjectType])
{
    new sum;
    for (new TFExtObjectType:t = TFExtObject_Dispenser;t <= TFExtObject_TeleporterExit; t++)
    {
        if (t != TFExtObject_Teleporter)
        {
            counts[t] = CountObjects(client, TF2_ObjectClassNames[t], TF2_ObjectModes[t]);
            sum += counts[t];
        }
    }
    counts[TFExtObject_Amplifier]  = counts[TFExtObject_Dispenser];
    counts[TFExtObject_RepairNode] = counts[TFExtObject_Dispenser];
    counts[TFExtObject_MiniSentry] = counts[TFExtObject_Sentry];
    counts[TFExtObject_Teleporter] = counts[TFExtObject_TeleporterEntry]
                                   + counts[TFExtObject_TeleporterExit];
    return sum;
}

CountObjects(client, const String:ClassName[], mode=-1)
{
    new ent = -1;
    new count = 0;
    while ((ent = FindEntityByClassname(ent, ClassName)) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hBuilder") == client &&
            (mode < 0 || GetEntProp(ent, Prop_Send, "m_iObjectMode") == mode))
        {
            count++;
        }
    }
    return count;
}

AddObjectsToMenu(Handle:menu, client, const String:ClassName[], mode=-1,
                 const String:ObjectName[], bool:all=false, &target=0)
{
    decl String:buf[12], String:item[64];
    new ent = -1;
    new count = 0;
    while ((ent = FindEntityByClassname(ent, ClassName)) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hBuilder") == client &&
            (mode < 0 || GetEntProp(ent, Prop_Send, "m_iObjectMode") == mode) &&
            GetEntProp(ent, Prop_Send, "m_bPlacing") == 0 &&
            (all || (GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") >= 1.0 &&
                     !GetEntProp(ent, Prop_Send, "m_bHasSapper") &&
                     !GetEntProp(ent, Prop_Send, "m_bDisabled"))))
        {
            count++;
            target=ent;
            IntToString(EntIndexToEntRef(ent), buf, sizeof(buf));
            Format(item,sizeof(item),"%s (%d)", ObjectName, ent);
            AddMenuItem(menu,buf,item);
        }
    }
    return count;
}

AddBuildingsToMenu(Handle:menu, client, bool:all=false, counts[TFExtObjectType]=0, &target=0)
{
    new sum;
    for (new TFExtObjectType:t = TFExtObject_Dispenser;t <= TFExtObject_TeleporterExit; t++)
    {
        if (t != TFExtObject_Teleporter)
        {
            counts[t] = AddObjectsToMenu(menu, client, TF2_ObjectClassNames[t],
                                         TF2_ObjectModes[t], TF2_ObjectNames[t],
                                         all, target);
            sum += counts[t];
        }
    }
    counts[TFExtObject_Amplifier]  = counts[TFExtObject_Dispenser];
    counts[TFExtObject_RepairNode] = counts[TFExtObject_Dispenser];
    counts[TFExtObject_MiniSentry] = counts[TFExtObject_Sentry];
    counts[TFExtObject_Teleporter] = counts[TFExtObject_TeleporterEntry]
                                   + counts[TFExtObject_TeleporterExit];
    return sum;
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index

    // Save the client's position so we won't teleport a newly spawned player elsewhere.
    GetClientAbsOrigin(client, clientPosition[client]);
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid")); // Get clients index

    new objectRef = g_RemoteObjectRef[client];
    if (objectRef != 0 && EntRefToEntIndex(objectRef) > 0)
    {
        new permissions = clientPermissions[client];
        new bool:zombie = (permissions < 0) ? ((permissions & REMOTE_CAN_ZOMBIE) != 0) : defaultZombie;
        if (!zombie)
            RemoteOff(client, 0);
    }
}

public PlayerBuiltObject(Handle:event,const String:name[],bool:dontBroadcast)
{
    new objectid = GetEventInt(event,"index");
    if (GetEventInt(event,"sourcemod") <= 0)
        g_WasBuilt[objectid] = false;

    new index = GetClientOfUserId(GetEventInt(event,"userid"));
    if (g_RemoteBuild[index])
    {
        new TFExtObjectType:type = TFExtObjectType:GetEventInt(event,"object");
        if (g_RemoteType[index] == type)
        {
            if (objectid <= 0)
            {
                for (new i=MaxClients+1;i<g_iMaxEntities;i++)
                {
                    if (IsValidEdict(i) && IsValidEntity(i))
                    {
                        if (TF2_GetExtObjectType(i) == type)
                        {
                            if (GetEntPropEnt(i,  Prop_Send, "m_hBuilder") == index)
                            {
                                objectid = i;
                                g_RemoteBuild[index] = false;
                                break;
                            }
                        }
                    }
                }
            }

            if (objectid > 0)
                control(index, objectid, type);
        }
    }
}

public ObjectDestroyed(Handle:event,const String:name[],bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event,"userid"));
    if (index > 0)
    {
        int i_object = GetEventInt(event,"index");
        if (i_object >= 0)
            g_WasBuilt[i_object] = false;
    }
}

public Action:PlayerChangeTeamEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    new HasBuiltFlags:flags = g_HasBuilt[client];
    if (client > 0 && flags != HasBuiltNothing)
    {
        if ((flags & HasBuiltDispenser) != HasBuiltNothing)
            DestroyObjects(TF2_ObjectClassNames[TFExtObject_Dispenser], client, false);

        if ((flags & HasBuiltSentry) != HasBuiltNothing)
            DestroyObjects(TF2_ObjectClassNames[TFExtObject_Sentry], client, false);

        if ((flags & HasBuiltTeleporterEntrance) != HasBuiltNothing ||
            (flags & HasBuiltTeleporterExit) != HasBuiltNothing)
        {
            DestroyObjects(TF2_ObjectClassNames[TFExtObject_Teleporter], client, false);
        }

        g_HasBuilt[client] = HasBuiltNothing;
    }
    return Plugin_Continue;
}

public EventRoundOver(Handle:event,const String:name[],bool:dontBroadcast)
{
    // Destroy all the objects that have been built.
    DestroyObjects(TF2_ObjectClassNames[TFExtObject_Dispenser], -1, false);
    DestroyObjects(TF2_ObjectClassNames[TFExtObject_Teleporter], -1, false);
    DestroyObjects(TF2_ObjectClassNames[TFExtObject_Sentry], -1, false);

    for (new index=0;index<sizeof(g_HasBuilt);index++)
        g_HasBuilt[index] = HasBuiltNothing;

    for (new entity=0;entity<sizeof(g_WasBuilt);entity++)
        g_WasBuilt[entity] = false;
}

public Action:Activate(Handle:timer,any:ref)
{
    int i_object = EntRefToEntIndex(ref);
    if (i_object > 0 && IsValidEdict(i_object) && IsValidEntity(i_object))
    {
        SetEntProp(i_object, Prop_Send, "m_bDisabled", 0);
        AcceptEntityInput(i_object, "TurnOn");

        if (TF2_GetObjectType(i_object) != TFObject_Teleporter &&
            GetEntProp(i_object, Prop_Send, "m_CollisionGroup") != 0)
        {
            int builder = GetEntPropEnt(i_object, Prop_Send, "m_hBuilder");
            if (builder > 0 && IsClientInGame(builder) && IsPlayerAlive(builder))
            {
                float playerPos[3];
                GetClientAbsOrigin(builder, playerPos);

                float objectPos[3];
                GetEntPropVector(i_object, Prop_Send, "m_vecOrigin", objectPos);

                decl Float:size[3];
                GetEntPropVector(i_object, Prop_Send, "m_vecBuildMaxs", size);

                float distance = GetVectorDistance(objectPos, playerPos);
                if (distance < size[0] * -1.1 || distance > size[0] * 1.1)
                    SetEntProp(i_object, Prop_Send, "m_CollisionGroup", 0);
                else
                    CreateTimer(2.0, Activate, ref, TIMER_FLAG_NO_MAPCHANGE);
            }
            else
                SetEntProp(i_object, Prop_Send, "m_CollisionGroup", 0);
        }
    }
    return Plugin_Stop;
}

public ObjectSelected(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        decl String:SelectionInfo[12];
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
        new objectRef = StringToInt(SelectionInfo);
        if (objectRef >= 0 && objectRef <= 12) // 0-12 are build options
        {
            g_RemoteBuild[client] = true;
            BuildSelected(menu,action,client,selection);
        }
        else
        {
            new objectid = EntRefToEntIndex(objectRef);
            if (objectid > 0 && IsValidEdict(objectid) && IsValidEntity(objectid))
                control(client, objectid, TF2_GetExtObjectType(objectid));
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

bool:control(client, objectid, TFExtObjectType:type)
{
    new Action:res = Plugin_Continue;
    Call_StartForward(fwdOnControlObject);
    Call_PushCell(client);
    Call_PushCell(client); // builder);
    Call_PushCell(objectid);
    Call_Finish(res);

    if (res == Plugin_Continue &&
        !IsEntLimitReached(.client=client,.message="unable to create info_observer_point"))
    {
        new watcher = CreateEntityByName("info_observer_point");
        if (watcher > 0 && IsValidEdict(watcher) && DispatchSpawn(watcher))
        {
            new Float:angles[3];
            GetEntPropVector(objectid, Prop_Send, "m_angRotation", angles);

            new Float:fwdvec[3];
            new Float:rightvec[3];
            new Float:upvec[3];
            GetAngleVectors(angles, fwdvec, rightvec, upvec);

            new Float:pos[3];
            GetEntPropVector(objectid, Prop_Send, "m_vecOrigin", pos);

            pos[0] += fwdvec[0] * -150.0;
            pos[1] += fwdvec[1] * -150.0;
            pos[2] += upvec[2] * 75.0;

            TeleportEntity(watcher, pos, angles, NULL_VECTOR);

            SetClientViewEntity(client, watcher);

            // Set the watcher's parent to the object.
            new String:strTargetName[64];
            IntToString(objectid, strTargetName, sizeof(strTargetName));

            DispatchKeyValue(objectid, "targetname", strTargetName);

            SetVariantString(strTargetName);
            AcceptEntityInput(watcher, "SetParent", -1, -1, 0);

            SetEntityMoveType(objectid, MOVETYPE_STEP);
            SetEntityMoveType(client, MOVETYPE_NONE); // MOVETYPE_STEP);

            g_RemoteType[client] = type;
            g_WatcherEntRef[client] = EntIndexToEntRef(watcher);
            g_RemoteObjectRef[client] = EntIndexToEntRef(objectid);
            return true;
        }
    }
    return false;
}

public Action:RemoteOff(client, args)
{
    //  PrintToChatAll("REMOTE OFF");
    new objectRef = g_RemoteObjectRef[client];
    if (objectRef != 0)
    {
        int i_object = EntRefToEntIndex(objectRef);
        if (i_object > 0 && IsValidEdict(i_object) && IsValidEntity(i_object))
        {
            new Float:angles[3];
            GetClientEyeAngles(client, angles);	
            angles[0] = 0.0;

            TeleportEntity(i_object, NULL_VECTOR, angles, NULL_VECTOR);

            new TFExtObjectType:type = g_RemoteType[client];
            if ((type != TFExtObject_Teleporter &&
                 type != TFExtObject_TeleporterEntry &&
                 type != TFExtObject_TeleporterExit) &&
                IsPlayerAlive(client))
            {
                new Float:objectPos[3];
                GetEntPropVector(i_object, Prop_Send, "m_vecOrigin", objectPos);

                decl Float:size[3];
                GetEntPropVector(i_object, Prop_Send, "m_vecBuildMaxs", size);

                new Float:distance = GetVectorDistance(objectPos, clientPosition[client]);
                if (distance < size[0] * -1.1 || distance > size[0] * 1.1)
                {
                    SetEntProp(i_object, Prop_Send, "m_CollisionGroup", 5);
                    //CreateTimer(2.0, Activate, EntIndexToEntRef(object), TIMER_FLAG_NO_MAPCHANGE);
                }
            }
        }

        if (IsClientInGame(client))
        {
            SetClientViewEntity(client, client);
            SetEntityMoveType(client, MOVETYPE_WALK);

            if (IsPlayerAlive(client))
                TeleportEntity(client, clientPosition[client], NULL_VECTOR, NULL_VECTOR);
        }
    }

    new watcher = EntRefToEntIndex(g_WatcherEntRef[client]);
    if (watcher > 0)
        RemoveEdict(watcher);

    g_RemoteBuild[client] = false;
    g_WatcherEntRef[client] = 0;
    g_RemoteObjectRef[client] = 0;
    g_RemoteType[client] = TFExtObject_Unknown;
    return Plugin_Handled;
}

/**
 * Description: Build Restrictions for TF2
 * Author(s): Tsunami
 */

public OnClientPutInServer(client)
{
    g_RemoteBuild[client] = false;
    g_WatcherEntRef[client] = 0;
    g_RemoteObjectRef[client] = 0;
    g_RemoteType[client] = TFExtObject_Unknown;

    g_HasBuilt[client] = HasBuiltNothing;
}

public OnClientDisconnect(client)
{
    g_HasBuilt[client] = HasBuiltNothing;
}

public Native_ControlRemote(Handle:plugin,numParams)
{
    SetConVarInt(cvarRemote, 0);
}

public Native_SetRemoteControl(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    clientPermissions[client] = GetNativeCell(2);
    clientSpeed[client] = Float:GetNativeCell(3);
    clientFallSpeed[client] = Float:GetNativeCell(4);
    clientJumpSpeed[client] = Float:GetNativeCell(5);
}

public Native_RemoteControlObject(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    if (g_RemoteObjectRef[client] != 0)
        RemoteOff(client, 0);
    else
        RemoteControl(client, GetNativeCell(2));
}

public Native_StopControllingObject(Handle:plugin,numParams)
{
    RemoteOff(GetNativeCell(1), 0);
}

public Native_CountBuildings(Handle:plugin,numParams)
{
    new counts[TFExtObjectType];
    new retval = CountBuildings(GetNativeCell(1), counts);

    // Get rid of index tag to make compiler happy :(
    new nativeCounts[sizeof(counts)];
    for (new i = 0; i < sizeof(nativeCounts); i++)
        nativeCounts[i] = counts[i];

    SetNativeArray(2, nativeCounts, sizeof(nativeCounts));
    return retval;
}

public Native_CountObjects(Handle:plugin,numParams)
{
    decl String:class[64];
    GetNativeString(2,class,sizeof(class));
    return CountObjects(GetNativeCell(1), class, GetNativeCell(3));
}

public Native_AddBuildingsToMenu(Handle:plugin,numParams)
{
    new target;
    new counts[TFExtObjectType];
    new retval = AddBuildingsToMenu(Handle:GetNativeCell(1), GetNativeCell(2),
                                    bool:GetNativeCell(3), counts, target);

    // Get rid of index tag to make compiler happy :(
    new nativeCounts[sizeof(counts)];
    for (new i = 0; i < sizeof(nativeCounts); i++)
        nativeCounts[i] = counts[i];

    SetNativeArray(4, nativeCounts, sizeof(nativeCounts));
    SetNativeCellRef(5, target);
    return retval;                                       
}


#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <dhooks>
#include <tf_ontakedamage>
#include <tf2_isPlayerInSpawn>

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 7.0;
float g_skill;
float g_dash_duration = 2.5;
float g_done_dash;
bool isready;
char emptyArgs[1] = "";
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    // PrintToServer("Running");
	if (HasStats(client))
	{

		if( GetEntProp( client, Prop_Data, "m_afButtonReleased" )  & IN_RELOAD) 
		{
			// PrintToChatAll("Release");
			// g_button_held[client] = false;

			if (g_Recharge[client] <= GetEngineTime() && isready && !TF2Spawn_IsClientInSpawn(client)) 
			{
            // Handle hArgs = ; // Example Handle
            FakeClientCommand(client, "sm_remote");
            // int args;
            // Remote(client, args);
			g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
			isready = false;
			}           
		}
		if(g_done_dash + g_dash_duration > GetEngineTime())
		{
			// ResetSpeed(client);
		}
		g_skill = GetEngineTime();
		DrawHUD(client);
	}
	return Plugin_Continue;
}


void DrawHUD(int client)
{
	char sHUDText[128];
	// char sProgress[32];
	//int iPercents = RoundToCeil(float(g_Recharge[client]) / float(g_RechargeCooldown) * 100.0);
	int iCountDown = RoundToCeil(g_Recharge[client] - g_skill);
	
	// for (int j = 1; j <= 10; j++)
	// {
	// 	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	// 	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	// }

	Format(sHUDText, sizeof(sHUDText), "Remote Control: %i   ", iCountDown);
	

	if(iCountDown <= 0)
	{
		if(!TF2Spawn_IsClientInSpawn(client))
		{
		Format(sHUDText, sizeof(sHUDText), "Remote Control:!\nPress Special Attack!");
			
		SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);
		}else
		{
			Format(sHUDText, sizeof(sHUDText), "Remote Control:\nUnavailable in spawn");
			SetHudTextParams(1.0, 0.8, 0.5, 255, 0, 0, 255);
		}
		
	} else {
		SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);
		
		// PrintToChatAll("Not Ready!");
	}
	// if (g_hud_post_time + g_hud_draw_delay <= GetEngineTime() || g_hud_post_time == 0.0)
	// {
		 ShowHudText(client, -2, sHUDText);
	// 	 g_hud_post_time = GetEngineTime();
	// }

		if (!isready && iCountDown <= 0)
		{
			TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
			// PrintToChatAll("Ready!");
			isready = true;	
		}

	if (g_button_held[client] && iCountDown <= 0)
	{
		g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
		isready = false;
		
	}
}
