#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"
#define MAX_ROBOT_NAME_LEN 128
#define MAX_TRANSFORM_FIELDS 8
#define MAX_TRANSFORM_FIELD_LEN 128

public Plugin myinfo =
{
    name = "[TF2] Robot Photo Automation",
    author = "GitHub Copilot",
    description = "Manual robot photo workflow: apply next robot and teleport on command.",
    version = PLUGIN_VERSION,
    url = "www.sourcemod.net"
};

// Hardcoded placeholders. Replace these with your actual values.
char g_TargetName[64] = "Scout";
char g_CameraName[64] = "Heavy Is GPS | Bmod.TF";

float g_TargetPos[3] = {0.0, 0.0, 0.0};
float g_TargetAng[3] = {0.0, 0.0, 0.0};

float g_CameraPos[3] = {0.0, 0.0, 0.0};
float g_CameraAng[3] = {0.0, 0.0, 0.0};

// Optional camera command after teleport (for example: "jpeg").
bool g_RunCameraCommand = false;
char g_CameraCommand[128] = "jpeg";

// CSV path relative to addons/sourcemod.
char g_RobotListRelativePath[PLATFORM_MAX_PATH] = "configs/robot_names.csv";
char g_TransformCsvRelativePath[PLATFORM_MAX_PATH] = "configs/robot_photo_transforms.csv";

ArrayList g_RobotNames;
bool g_RobotSessionActive = false;
int g_CurrentIndex = 0;
int g_LastAppliedIndex = -1;
bool g_AutoLoadTransformsOnStart = true;
float g_SwitchToRespawnDelay = 0.5;
float g_RespawnToTeleportDelay = 0.5;
float g_PostTeleportAngleDelay1 = 0.05;
float g_PostTeleportAngleDelay2 = 0.20;

public void OnPluginStart()
{
    g_RobotNames = new ArrayList(ByteCountToCells(MAX_ROBOT_NAME_LEN));

    RegAdminCmd("sm_robot_photo_start", Command_Start, ADMFLAG_ROOT, "Start robot photo automation.");
    RegAdminCmd("sm_robot_photo_next", Command_Next, ADMFLAG_ROOT, "Apply next robot and teleport target/cameraman.");
    RegAdminCmd("sm_robot_photo_retry", Command_Retry, ADMFLAG_ROOT, "Retry last applied robot without changing order.");
    RegAdminCmd("sm_robot_photo_prev", Command_Prev, ADMFLAG_ROOT, "Load previous robot and move order pointer back by one.");
    RegAdminCmd("sm_robot_photo_stop", Command_Stop, ADMFLAG_ROOT, "Stop robot photo automation.");
    RegAdminCmd("sm_robot_photo_reload", Command_Reload, ADMFLAG_ROOT, "Reload robot names from CSV.");
    RegAdminCmd("sm_robot_photo_get_target", Command_GetTargetTransform, ADMFLAG_ROOT, "Print current target position and angles.");
    RegAdminCmd("sm_robot_photo_get_camera", Command_GetCameraTransform, ADMFLAG_ROOT, "Print current camera position and angles.");
    RegAdminCmd("sm_robot_photo_get_all", Command_GetAllTransforms, ADMFLAG_ROOT, "Capture target + camera transforms and save to CSV.");
    RegAdminCmd("sm_robot_photo_load_transforms", Command_LoadTransforms, ADMFLAG_ROOT, "Load target + camera transforms from CSV.");
    RegAdminCmd("sm_robot_photo_autoload", Command_AutoloadToggle, ADMFLAG_ROOT, "Toggle startup autoload for transform CSV.");
    RegAdminCmd("sm_robot_photo_clear_ammo", Command_ClearAmmoPacks, ADMFLAG_ROOT, "Remove all dropped ammo packs currently on the map.");

    if (g_AutoLoadTransformsOnStart)
    {
        if (LoadTransformsFromCsv(0, true))
        {
            PrintToServer("[RobotPhoto] Auto-loaded transforms from CSV on startup.");
        }
        else
        {
            PrintToServer("[RobotPhoto] Auto-load skipped (CSV missing/invalid). Use sm_robot_photo_get_all to create or refresh it.");
        }
    }
}

public void OnPluginEnd()
{
    delete g_RobotNames;
}

public Action Command_Start(int client, int args)
{
    g_RobotSessionActive = true;
    g_CurrentIndex = 0;
    g_LastAppliedIndex = -1;
    g_RobotNames.Clear();

    bool loaded = LoadTransformsFromCsv(client, false);

    if (loaded)
    {
        if (client > 0)
        {
            PrintCenterText(client, "[RobotPhoto] Saved camera/target positions loaded.");
        }
        else
        {
            PrintToServer("[RobotPhoto] Saved camera/target positions loaded.");
        }

        ReplyToCommand(client, "[RobotPhoto] Start ready. Use sm_robot_photo_next to load first robot.");
    }
    else
    {
        if (client > 0)
        {
            PrintCenterText(client, "[RobotPhoto] Failed to load saved positions.");
        }
        else
        {
            PrintToServer("[RobotPhoto] Failed to load saved positions.");
        }

        ReplyToCommand(client, "[RobotPhoto] Start ready, but saved positions were not loaded.");
    }

    return Plugin_Handled;
}

public Action Command_Next(int client, int args)
{
    if (!g_RobotSessionActive)
    {
        ReplyToCommand(client, "[RobotPhoto] Session not active. Use sm_robot_photo_start first.");
        return Plugin_Handled;
    }

    if (g_RobotNames.Length <= 0)
    {
        if (!LoadRobotNames())
        {
            ReplyToCommand(client, "[RobotPhoto] Failed to load robot names. Check CSV path/content.");
            return Plugin_Handled;
        }

        ReplyToCommand(client, "[RobotPhoto] Loaded %d robot names.", g_RobotNames.Length);
    }

    if (g_CurrentIndex >= g_RobotNames.Length)
    {
        g_RobotSessionActive = false;
        ReplyToCommand(client, "[RobotPhoto] End of list reached. Use sm_robot_photo_start to restart.");
        return Plugin_Handled;
    }

    char robotName[MAX_ROBOT_NAME_LEN];
    g_RobotNames.GetString(g_CurrentIndex, robotName, sizeof(robotName));

    ApplyRobotAtIndex(client, g_CurrentIndex, "NEXT");

    g_LastAppliedIndex = g_CurrentIndex;
    g_CurrentIndex++;
    if (g_CurrentIndex >= g_RobotNames.Length)
    {
        g_RobotSessionActive = false;
        ReplyToCommand(client, "[RobotPhoto] Completed robot list.");
    }

    return Plugin_Handled;
}

public Action Command_Retry(int client, int args)
{
    if (g_LastAppliedIndex < 0 || g_LastAppliedIndex >= g_RobotNames.Length)
    {
        ReplyToCommand(client, "[RobotPhoto] Nothing to retry yet. Use sm_robot_photo_next first.");
        return Plugin_Handled;
    }

    ApplyRobotAtIndex(client, g_LastAppliedIndex, "RETRY");
    return Plugin_Handled;
}

public Action Command_Prev(int client, int args)
{
    if (g_LastAppliedIndex <= 0)
    {
        ReplyToCommand(client, "[RobotPhoto] No previous robot available.");
        return Plugin_Handled;
    }

    int prevIndex = g_LastAppliedIndex - 1;
    ApplyRobotAtIndex(client, prevIndex, "PREV");

    g_LastAppliedIndex = prevIndex;
    g_CurrentIndex = prevIndex + 1;
    g_RobotSessionActive = true;

    ReplyToCommand(client, "[RobotPhoto] Pointer moved back. Next will continue from index %d.", g_CurrentIndex + 1);
    return Plugin_Handled;
}

public Action Command_Stop(int client, int args)
{
    g_RobotSessionActive = false;
    ReplyToCommand(client, "[RobotPhoto] Session stopped.");
    return Plugin_Handled;
}

public Action Command_Reload(int client, int args)
{
    if (!LoadRobotNames())
    {
        ReplyToCommand(client, "[RobotPhoto] Reload failed.");
        return Plugin_Handled;
    }

    ReplyToCommand(client, "[RobotPhoto] Reloaded %d robot names.", g_RobotNames.Length);
    return Plugin_Handled;
}

public Action Command_GetTargetTransform(int client, int args)
{
    int target = FindClientByExactName(g_TargetName);
    if (target <= 0)
    {
        ReplyToCommand(client, "[RobotPhoto] Target not found: %s", g_TargetName);
        return Plugin_Handled;
    }

    GetClientAbsOrigin(target, g_TargetPos);
    GetClientEyeAngles(target, g_TargetAng);

    PrintClientTransform(client, target, "Target");
    SaveTransformsToCsv(client);
    return Plugin_Handled;
}

public Action Command_GetCameraTransform(int client, int args)
{
    int camera = FindClientByExactName(g_CameraName);
    if (camera <= 0)
    {
        ReplyToCommand(client, "[RobotPhoto] Cameraman not found: %s", g_CameraName);
        return Plugin_Handled;
    }

    GetClientAbsOrigin(camera, g_CameraPos);
    GetClientEyeAngles(camera, g_CameraAng);

    PrintClientTransform(client, camera, "Camera");
    SaveTransformsToCsv(client);
    return Plugin_Handled;
}

public Action Command_GetAllTransforms(int client, int args)
{
    int target = FindClientByExactName(g_TargetName);
    int camera = FindClientByExactName(g_CameraName);

    bool ok = true;
    if (target <= 0)
    {
        ReplyToCommand(client, "[RobotPhoto] Target not found: %s", g_TargetName);
        ok = false;
    }

    if (camera <= 0)
    {
        ReplyToCommand(client, "[RobotPhoto] Cameraman not found: %s", g_CameraName);
        ok = false;
    }

    if (!ok)
    {
        return Plugin_Handled;
    }

    GetClientAbsOrigin(target, g_TargetPos);
    GetClientEyeAngles(target, g_TargetAng);
    GetClientAbsOrigin(camera, g_CameraPos);
    GetClientEyeAngles(camera, g_CameraAng);

    PrintClientTransform(client, target, "Target");
    PrintClientTransform(client, camera, "Camera");

    SaveTransformsToCsv(client);
    return Plugin_Handled;
}

public Action Command_LoadTransforms(int client, int args)
{
    if (!LoadTransformsFromCsv(client, false))
    {
        ReplyToCommand(client, "[RobotPhoto] Failed to load transforms CSV.");
        return Plugin_Handled;
    }

    ReplyToCommand(client, "[RobotPhoto] Loaded transforms from CSV.");
    ReplyToCommand(client, "[RobotPhoto] Target Pos: %.3f %.3f %.3f", g_TargetPos[0], g_TargetPos[1], g_TargetPos[2]);
    ReplyToCommand(client, "[RobotPhoto] Target Ang: %.3f %.3f %.3f", g_TargetAng[0], g_TargetAng[1], g_TargetAng[2]);
    ReplyToCommand(client, "[RobotPhoto] Camera Pos: %.3f %.3f %.3f", g_CameraPos[0], g_CameraPos[1], g_CameraPos[2]);
    ReplyToCommand(client, "[RobotPhoto] Camera Ang: %.3f %.3f %.3f", g_CameraAng[0], g_CameraAng[1], g_CameraAng[2]);

    return Plugin_Handled;
}

public Action Command_AutoloadToggle(int client, int args)
{
    if (args >= 1)
    {
        char arg[16];
        GetCmdArg(1, arg, sizeof(arg));

        if (StrEqual(arg, "1") || StrEqual(arg, "on", false) || StrEqual(arg, "true", false))
        {
            g_AutoLoadTransformsOnStart = true;
        }
        else if (StrEqual(arg, "0") || StrEqual(arg, "off", false) || StrEqual(arg, "false", false))
        {
            g_AutoLoadTransformsOnStart = false;
        }
        else
        {
            ReplyToCommand(client, "[RobotPhoto] Usage: sm_robot_photo_autoload [0/1|off/on]");
            return Plugin_Handled;
        }
    }
    else
    {
        g_AutoLoadTransformsOnStart = !g_AutoLoadTransformsOnStart;
    }

    ReplyToCommand(
        client,
        "[RobotPhoto] Startup autoload is now: %s",
        g_AutoLoadTransformsOnStart ? "ON" : "OFF"
    );

    return Plugin_Handled;
}

public Action Command_ClearAmmoPacks(int client, int args)
{
    int count = 0;
    int entity = -1;

    while ((entity = FindEntityByClassname(entity, "tf_ammo_pack")) != -1)
    {
        if (IsValidEntity(entity))
        {
            AcceptEntityInput(entity, "Kill");
            count++;
        }
    }

    ReplyToCommand(client, "[RobotPhoto] Removed %d dropped ammo pack(s).", count);
    return Plugin_Handled;
}

void TeleportSubjectsNow()
{
    int target = FindClientByExactName(g_TargetName);
    int camera = FindClientByExactName(g_CameraName);

    if (target > 0)
    {
        TeleportEntity(target, g_TargetPos, g_TargetAng, NULL_VECTOR);
    }
    else
    {
        PrintToServer("[RobotPhoto] Target not found: %s", g_TargetName);
    }

    if (camera > 0)
    {
        TeleportEntity(camera, g_CameraPos, g_CameraAng, NULL_VECTOR);
    }
    else
    {
        PrintToServer("[RobotPhoto] Cameraman not found: %s", g_CameraName);
    }

    // Some robot/spectator transitions can override view angles right after teleport.
    // Re-apply view angles in two short passes for stability.
    CreateTimer(g_PostTeleportAngleDelay1, Timer_ReapplyAnglesPass1);
    CreateTimer(g_PostTeleportAngleDelay2, Timer_ReapplyAnglesPass2);
}

void ApplyRobotAtIndex(int requester, int robotIndex, const char[] mode)
{
    char robotName[MAX_ROBOT_NAME_LEN];
    g_RobotNames.GetString(robotIndex, robotName, sizeof(robotName));

    ReplyToCommand(
        requester,
        "[RobotPhoto] %s %d/%d -> %s",
        mode,
        robotIndex + 1,
        g_RobotNames.Length,
        robotName
    );

    ServerCommand("sm_mr \"%s\" \"%s\"", robotName, g_TargetName);
    ServerExecute();

    CreateTimer(g_SwitchToRespawnDelay, Timer_RespawnTargetAfterSwitch);
}

public Action Timer_RespawnTargetAfterSwitch(Handle timer)
{
    int target = FindClientByExactName(g_TargetName);
    if (target <= 0)
    {
        PrintToServer("[RobotPhoto] Target not found before respawn: %s", g_TargetName);
        return Plugin_Stop;
    }

    TF2_RespawnPlayer(target);
    CreateTimer(g_RespawnToTeleportDelay, Timer_TeleportAfterRespawn);
    return Plugin_Stop;
}

public Action Timer_TeleportAfterRespawn(Handle timer)
{
    TeleportSubjectsNow();
    return Plugin_Stop;
}

public Action Timer_ReapplyAnglesPass1(Handle timer)
{
    ReapplyAnglesOnly();
    return Plugin_Stop;
}

public Action Timer_ReapplyAnglesPass2(Handle timer)
{
    ReapplyAnglesOnly();

    int camera = FindClientByExactName(g_CameraName);
    if (camera > 0 && g_RunCameraCommand)
    {
        FakeClientCommand(camera, "%s", g_CameraCommand);
    }

    return Plugin_Stop;
}

void ReapplyAnglesOnly()
{
    int target = FindClientByExactName(g_TargetName);
    int camera = FindClientByExactName(g_CameraName);

    if (target > 0)
    {
        float targetPos[3];
        GetClientAbsOrigin(target, targetPos);
        TeleportEntity(target, targetPos, g_TargetAng, NULL_VECTOR);
    }

    if (camera > 0)
    {
        float cameraPos[3];
        GetClientAbsOrigin(camera, cameraPos);
        TeleportEntity(camera, cameraPos, g_CameraAng, NULL_VECTOR);
    }
}

bool LoadRobotNames()
{
    g_RobotNames.Clear();

    char fullPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, fullPath, sizeof(fullPath), "%s", g_RobotListRelativePath);

    File file = OpenFile(fullPath, "r");
    if (file == null)
    {
        LogError("[RobotPhoto] Could not open robot list: %s", fullPath);
        return false;
    }

    char line[8192];
    while (!file.EndOfFile() && file.ReadLine(line, sizeof(line)))
    {
        TrimString(line);
        if (line[0] == '\0')
        {
            continue;
        }

        ParseCsvLine(line);
    }

    delete file;

    if (g_RobotNames.Length <= 0)
    {
        LogError("[RobotPhoto] No robot names were parsed from %s", fullPath);
        return false;
    }

    return true;
}

void ParseCsvLine(const char[] line)
{
    char token[MAX_ROBOT_NAME_LEN];
    int tokenLen = 0;
    bool inQuotes = false;

    int len = strlen(line);
    for (int i = 0; i < len; i++)
    {
        char c = line[i];

        if (c == '"')
        {
            if (inQuotes && i + 1 < len && line[i + 1] == '"')
            {
                if (tokenLen < sizeof(token) - 1)
                {
                    token[tokenLen++] = '"';
                    token[tokenLen] = '\0';
                }
                i++;
            }
            else
            {
                inQuotes = !inQuotes;
            }
            continue;
        }

        if (c == ',' && !inQuotes)
        {
            token[tokenLen] = '\0';
            AddTokenAsRobotName(token);
            tokenLen = 0;
            token[0] = '\0';
            continue;
        }

        if (tokenLen < sizeof(token) - 1)
        {
            token[tokenLen++] = c;
            token[tokenLen] = '\0';
        }
    }

    token[tokenLen] = '\0';
    AddTokenAsRobotName(token);
}

void AddTokenAsRobotName(char[] token)
{
    TrimString(token);
    if (token[0] == '\0')
    {
        return;
    }

    g_RobotNames.PushString(token);
}

int FindClientByExactName(const char[] wanted)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
        {
            continue;
        }

        char current[64];
        GetClientName(i, current, sizeof(current));

        if (StrEqual(current, wanted, false))
        {
            return i;
        }
    }

    return 0;
}

void PrintClientTransform(int requester, int subject, const char[] label)
{
    float pos[3];
    float ang[3];

    GetClientAbsOrigin(subject, pos);
    GetClientEyeAngles(subject, ang);

    ReplyToCommand(requester, "[RobotPhoto] %s \"%N\"", label, subject);
    ReplyToCommand(requester, "[RobotPhoto] %s Pos: %.3f %.3f %.3f", label, pos[0], pos[1], pos[2]);
    ReplyToCommand(requester, "[RobotPhoto] %s Ang: %.3f %.3f %.3f", label, ang[0], ang[1], ang[2]);

    ReplyToCommand(requester, "[RobotPhoto] Paste -> float g_%sPos[3] = {%.3f, %.3f, %.3f};", label, pos[0], pos[1], pos[2]);
    ReplyToCommand(requester, "[RobotPhoto] Paste -> float g_%sAng[3] = {%.3f, %.3f, %.3f};", label, ang[0], ang[1], ang[2]);
}

void SaveTransformsToCsv(int requester)
{
    char fullPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, fullPath, sizeof(fullPath), "%s", g_TransformCsvRelativePath);

    File file = OpenFile(fullPath, "w");
    if (file == null)
    {
        ReplyToCommand(requester, "[RobotPhoto] Failed to write CSV: %s", fullPath);
        return;
    }

    WriteFileLine(file, "\"role\",\"name\",\"pos_x\",\"pos_y\",\"pos_z\",\"ang_x\",\"ang_y\",\"ang_z\"");
    WriteTransformCsvLine(file, "target", g_TargetName, g_TargetPos, g_TargetAng);
    WriteTransformCsvLine(file, "camera", g_CameraName, g_CameraPos, g_CameraAng);

    delete file;
    ReplyToCommand(requester, "[RobotPhoto] Saved transforms CSV: %s", fullPath);
}

void WriteTransformCsvLine(File file, const char[] role, const char[] name, const float pos[3], const float ang[3])
{
    char escapedName[128];
    strcopy(escapedName, sizeof(escapedName), name);
    ReplaceString(escapedName, sizeof(escapedName), "\"", "\"\"");

    WriteFileLine(
        file,
        "\"%s\",\"%s\",%.3f,%.3f,%.3f,%.3f,%.3f,%.3f",
        role,
        escapedName,
        pos[0],
        pos[1],
        pos[2],
        ang[0],
        ang[1],
        ang[2]
    );
}

bool LoadTransformsFromCsv(int requester, bool silent)
{
    char fullPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, fullPath, sizeof(fullPath), "%s", g_TransformCsvRelativePath);

    File file = OpenFile(fullPath, "r");
    if (file == null)
    {
        if (!silent)
        {
            if (requester > 0)
            {
                ReplyToCommand(requester, "[RobotPhoto] Could not open transforms CSV: %s", fullPath);
            }
            else
            {
                PrintToServer("[RobotPhoto] Could not open transforms CSV: %s", fullPath);
            }
        }
        return false;
    }

    char line[1024];
    bool loadedTarget = false;
    bool loadedCamera = false;

    while (!file.EndOfFile() && file.ReadLine(line, sizeof(line)))
    {
        TrimString(line);
        if (line[0] == '\0')
        {
            continue;
        }

        if (line[0] == '"' && StrContains(line, "\"role\"") == 0)
        {
            continue;
        }

        if (ApplyTransformCsvLine(line, loadedTarget, loadedCamera))
        {
            if (loadedTarget && loadedCamera)
            {
                break;
            }
        }
    }

    delete file;

    if (!loadedTarget)
    {
        if (!silent)
        {
            if (requester > 0)
            {
                ReplyToCommand(requester, "[RobotPhoto] Missing target row in transforms CSV.");
            }
            else
            {
                PrintToServer("[RobotPhoto] Missing target row in transforms CSV.");
            }
        }
    }

    if (!loadedCamera)
    {
        if (!silent)
        {
            if (requester > 0)
            {
                ReplyToCommand(requester, "[RobotPhoto] Missing camera row in transforms CSV.");
            }
            else
            {
                PrintToServer("[RobotPhoto] Missing camera row in transforms CSV.");
            }
        }
    }

    return loadedTarget && loadedCamera;
}

bool ApplyTransformCsvLine(const char[] line, bool &loadedTarget, bool &loadedCamera)
{
    char fields[MAX_TRANSFORM_FIELDS][MAX_TRANSFORM_FIELD_LEN];
    if (!ParseCsvFields(line, fields, MAX_TRANSFORM_FIELDS, MAX_TRANSFORM_FIELD_LEN))
    {
        return false;
    }

    if (fields[0][0] == '\0')
    {
        return false;
    }

    float pos[3];
    float ang[3];
    pos[0] = StringToFloat(fields[2]);
    pos[1] = StringToFloat(fields[3]);
    pos[2] = StringToFloat(fields[4]);
    ang[0] = StringToFloat(fields[5]);
    ang[1] = StringToFloat(fields[6]);
    ang[2] = StringToFloat(fields[7]);

    if (StrEqual(fields[0], "target", false))
    {
        strcopy(g_TargetName, sizeof(g_TargetName), fields[1]);
        g_TargetPos = pos;
        g_TargetAng = ang;
        loadedTarget = true;
        return true;
    }

    if (StrEqual(fields[0], "camera", false))
    {
        strcopy(g_CameraName, sizeof(g_CameraName), fields[1]);
        g_CameraPos = pos;
        g_CameraAng = ang;
        loadedCamera = true;
        return true;
    }

    return false;
}

bool ParseCsvFields(const char[] line, char fields[][MAX_TRANSFORM_FIELD_LEN], int maxFields, int fieldSize)
{
    int fieldIndex = 0;
    int tokenLen = 0;
    bool inQuotes = false;

    char token[MAX_TRANSFORM_FIELD_LEN];
    token[0] = '\0';

    int len = strlen(line);
    for (int i = 0; i < len; i++)
    {
        char c = line[i];

        if (c == '"')
        {
            if (inQuotes && i + 1 < len && line[i + 1] == '"')
            {
                if (tokenLen < fieldSize - 1)
                {
                    token[tokenLen++] = '"';
                    token[tokenLen] = '\0';
                }
                i++;
            }
            else
            {
                inQuotes = !inQuotes;
            }
            continue;
        }

        if (c == ',' && !inQuotes)
        {
            if (fieldIndex >= maxFields)
            {
                return false;
            }

            token[tokenLen] = '\0';
            TrimString(token);
            strcopy(fields[fieldIndex], fieldSize, token);

            fieldIndex++;
            tokenLen = 0;
            token[0] = '\0';
            continue;
        }

        if (tokenLen < fieldSize - 1)
        {
            token[tokenLen++] = c;
            token[tokenLen] = '\0';
        }
    }

    if (fieldIndex >= maxFields)
    {
        return false;
    }

    token[tokenLen] = '\0';
    TrimString(token);
    strcopy(fields[fieldIndex], fieldSize, token);
    fieldIndex++;

    if (fieldIndex != maxFields)
    {
        return false;
    }

    return true;
}
