#include <webcon>
#include <motdui>
#include <moonly>
#include <advanced_motd>
#include <smjansson>

#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 4

#define MAX_VIRTUAL_ID_SIZE      16
#define MAX_ROUTE_NAME_SIZE      32
#define MAX_ACCESS_TOKEN_SIZE    65
#define MAX_WEB_METHOD_NAME_SIZE 10

enum struct MUIPlugin
{
    Handle    m_hPlugin;
    char      m_szVirtualId[MAX_VIRTUAL_ID_SIZE];
    char      m_szPublicPath[PLATFORM_MAX_PATH];
    ArrayList m_Routes;
    StringMap m_RouteNames;
}

enum struct MUIRoute
{
    char     m_szMethod[MAX_WEB_METHOD_NAME_SIZE];
    char     m_szPath[PLATFORM_MAX_PATH];
    Function m_fnHandler;
}

ConVar    sm_motdui_loopback_url;
ConVar    sm_motdui_debug_auth_as;
ConVar    sm_motdui_debug_print_auth_url;

StringMap g_hVirtualMap;
StringMap g_hPluginToVirtualIdMap;
StringMap g_hExtContentType;
StringMap g_hAccessTokenOwner;

char      g_szTokenAlphabet[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
char      g_szAccessToken[MAXPLAYERS][MAX_ACCESS_TOKEN_SIZE];
char      g_szAuthRedirectToUrl[MAXPLAYERS][PLATFORM_MAX_PATH];

char      g_szWebCacheFilePath[PLATFORM_MAX_PATH];
char      g_szJsonCacheFilePath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
    name        = "Message of the Day UI",
    author      = "Moonly Days",
    description = "Use the Message of the Day system to display custom user interfaces.",
    version     = "1.1.0",
    url         = "https://github.com/MoonlyDays"
};

//---------------------------------------------------------------------------------
// Public Functions
//---------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen)
{
    RegPluginLibrary("motdui");

    CreateNative("MotdUI.RegisterVirtualId", Native_RegisterVirtualId);
    CreateNative("MotdUI.Route", Native_Route);
    CreateNative("MotdUI.GetRouteUrl", Native_GetRouteUrl);

    CreateNative("MotdUI.ShowPanelRoute", Native_ShowPanelRoute);
    CreateNative("MotdUI.ShowPanelUrl", Native_ShowPanelUrl);
    CreateNative("MotdUI.ShowPanelPublicAsset", Native_ShowPanelPublicAsset);
    CreateNative("MotdUI.ClosePanel", Native_ClosePanel);

    CreateNative("MotdUIRequest.GetParameter", Native_Request_GetParameter);

    CreateNative("MotdUIResponse.SendString", Native_Response_SendString);
    CreateNative("MotdUIResponse.SendFile", Native_Response_SendFile);
    CreateNative("MotdUIResponse.SendKeyValues", Native_Response_SendKeyValues);
    CreateNative("MotdUIResponse.SetHeader", Native_Response_SetHeader);
    CreateNative("MotdUIResponse.StatusCode.set", Native_Response_StatusCode_set);
    CreateNative("MotdUIResponse.StatusCode.get", Native_Response_StatusCode_get);

    return APLRes_Success;
}

public void OnPluginStart()
{
    Web_RegisterRequestHandler("~", HandleRouteRequest, "Message of the Day UI", "Use the Message of the Day system to display custom user interfaces.");
    Web_RegisterRequestHandler("public", HandlePublicAssets);
    Web_RegisterRequestHandler("auth", HandleAuthRequest);

    AddCommandListener(ClosedMOTD, "closed_htmlpage");

    sm_motdui_loopback_url         = CreateConVar("sm_motdui_loopback_url", "http://127.0.0.1", "", FCVAR_PROTECTED);
    sm_motdui_debug_auth_as        = CreateConVar("sm_motdui_debug_auth_as", "0", "", FCVAR_PROTECTED);
    sm_motdui_debug_print_auth_url = CreateConVar("sm_motdui_debug_print_auth_url", "0", "", FCVAR_PROTECTED);

    g_hVirtualMap                  = new StringMap();
    g_hPluginToVirtualIdMap        = new StringMap();
    g_hAccessTokenOwner            = new StringMap();

    g_hExtContentType              = new StringMap();
    g_hExtContentType.SetString("html", "text/html");
    g_hExtContentType.SetString("htm", "text/html");
    g_hExtContentType.SetString("css", "text/css");
    g_hExtContentType.SetString("js", "application/javascript");
    g_hExtContentType.SetString("json", "application/json");
    g_hExtContentType.SetString("xml", "application/xml");
    g_hExtContentType.SetString("jpg", "image/jpeg");
    g_hExtContentType.SetString("jpeg", "image/jpeg");
    g_hExtContentType.SetString("png", "image/png");
    g_hExtContentType.SetString("webp", "image/webp");
    g_hExtContentType.SetString("svg", "image/svg+xml");
    g_hExtContentType.SetString("gif", "image/gif");
    g_hExtContentType.SetString("pdf", "application/pdf");
    g_hExtContentType.SetString("txt", "text/plain");

    BuildPath(Path_SM, g_szWebCacheFilePath, sizeof(g_szWebCacheFilePath), "data/_www_cache.txt");
    BuildPath(Path_SM, g_szJsonCacheFilePath, sizeof(g_szJsonCacheFilePath), "data/_json_cache.txt");
    AutoExecConfig(true, "motdui");
}

public void OnNotifyPluginUnloaded(Handle plugin)
{
    char szId[MAX_VIRTUAL_ID_SIZE];
    if (!FindPluginByVirtualId(plugin, szId, sizeof(szId)))
    {
        return;
    }

    MUIPlugin entry;
    g_hVirtualMap.GetArray(szId, entry, sizeof(entry));
    CloseHandle(entry.m_Routes);
    CloneHandle(entry.m_RouteNames);

    char szPluginName[PLATFORM_MAX_PATH];
    GetPluginFilename(plugin, szPluginName, sizeof(szPluginName));

    g_hVirtualMap.Remove(szId);
    g_hPluginToVirtualIdMap.Remove(szPluginName);
    LogMessage("Plugin \"%s\" with virtual ID \"%s\" is unloaded. Freeing...", szId, szPluginName);
}

//---------------------------------------------------------------------------------
// Private Functions
//---------------------------------------------------------------------------------

bool HandleAuthRequest(WebConnection connection, const char[] method, const char[] url)
{
    char szToken[MAX_ACCESS_TOKEN_SIZE];
    strcopy(szToken, sizeof(szToken), url[1]);

    int clientId;
    if (!g_hAccessTokenOwner.GetValue(szToken, clientId))
    {
        SendStringToConnection(connection, WebStatus_Unauthorized, "401 Unauthorized");
        return true;
    }

    char szTokenCookie[128];
    Format(szTokenCookie, sizeof(szTokenCookie), "token=%s; Max-Age=2592000; Path=/~", szToken);

    WebStringResponse resp = new WebStringResponse("");
    resp.AddHeader(WebHeader_Location, g_szAuthRedirectToUrl[clientId]);
    resp.AddHeader(WebHeader_SetCookie, szTokenCookie);
    connection.QueueResponse(WebStatus_TemporaryRedirect, resp);
    CloseHandle(resp);

    return true;
}

bool HandleRouteRequest(WebConnection connection, const char[] method, const char[] url)
{
    LogMessage("Handling route request: %s %s", method, url);

    MUIPlugin plugin;
    if (!ResolvePluginFromUrl(url, plugin))
    {
        SendStringToConnection(connection, WebStatus_NotFound, "Virtual ID is not mapped to any plugin");
        return true;
    }

    char szToken[MAX_ACCESS_TOKEN_SIZE];
    connection.GetRequestData(WebRequestDataType_Cookie, "token", szToken, sizeof(szToken));

    int clientId = sm_motdui_debug_auth_as.IntValue;

    if (clientId == 0)
    {
        if (!g_hAccessTokenOwner.GetValue(szToken, clientId))
        {
            SendStringToConnection(connection, WebStatus_Unauthorized, "401 Unauthorized");
            return true;
        }
    }

    char szPath[PLATFORM_MAX_PATH];
    strcopy(szPath, sizeof(szPath), url[strlen(plugin.m_szVirtualId) + 1]);
    NormalizeRoutePath(szPath, sizeof(szPath));

    MUIRoute route;
    if (!FindRouteByPath(plugin, method, szPath, route))
    {
        SendStringToConnection(connection, WebStatus_NotFound, "404 Not Found");
        return true;
    }

    DataPack reqPack = CreateRequestDataPack(connection, method, url);
    DataPack resPack = CreateResponseDataPack(reqPack, connection);

    Call_StartFunction(plugin.m_hPlugin, route.m_fnHandler);
    Call_PushCell(clientId);
    Call_PushCell(reqPack);
    Call_PushCell(resPack);
    Call_Finish();
    return true;
}

bool HandlePublicAssets(WebConnection connection, const char[] method, const char[] url)
{
    MUIPlugin plugin;
    if (!ResolvePluginFromUrl(url, plugin))
    {
        SendStringToConnection(connection, WebStatus_NotFound, "Virtual ID is not mapped to any plugin");
        return true;
    }

    char szPath[PLATFORM_MAX_PATH];
    strcopy(szPath, sizeof(szPath), url[strlen(plugin.m_szVirtualId) + 1]);
    Format(szPath, sizeof(szPath), "%s%s", plugin.m_szPublicPath, szPath);
    NormalizeRoutePath(szPath, sizeof(szPath));

    BuildPath(Path_SM, szPath, sizeof(szPath), "www/%s%s", plugin.m_szVirtualId, szPath);

    if (!FileExists(szPath))
    {
        SendStringToConnection(connection, WebStatus_NotFound, "");
        return true;
    }

    WebFileResponse resp = new WebFileResponse(szPath);

    char            szExt[11], szContentType[32];
    GetFileExtension(szPath, szExt, sizeof(szExt));
    if (ResolveContentType(szExt, szContentType, sizeof(szContentType)))
    {
        resp.AddHeader(WebHeader_ContentType, szContentType);
    }

    connection.QueueResponse(WebStatus_OK, resp);
    CloseHandle(resp);
    return true;
}

DataPack CreateRequestDataPack(WebConnection connection, const char[] method, const char[] url)
{
    DataPack pack = new DataPack();
    pack.WriteCell(connection);
    pack.WriteString(url);
    pack.WriteString(method);
    return pack;
}

void CloseRequestDataPack(DataPack pack)
{
    CloseHandle(pack);
}

DataPack CreateResponseDataPack(DataPack req, WebConnection connection)
{
    DataPack pack = new DataPack();
    pack.WriteCell(connection);
    pack.WriteCell(200);
    pack.WriteCell(new StringMap());
    pack.WriteCell(req);
    return pack;
}

void CloseResponseDataPack(DataPack pack)
{
    pack.Reset();
    pack.Position++;
    pack.Position++;

    StringMap map = pack.ReadCell();
    CloseHandle(map);

    DataPack req = pack.ReadCell();
    CloseRequestDataPack(req);

    CloseHandle(pack);
}

bool IsPluginRegistered(Handle plugin)
{
    char szName[PLATFORM_MAX_PATH];
    GetPluginFilename(plugin, szName, sizeof(szName));
    return g_hPluginToVirtualIdMap.ContainsKey(szName);
}

bool FindPluginByVirtualId(Handle plugin, char[] buffer, int len)
{
    char szName[PLATFORM_MAX_PATH];
    GetPluginFilename(plugin, szName, sizeof(szName));
    return g_hPluginToVirtualIdMap.GetString(szName, buffer, len);
}

bool FindRouteByPath(MUIPlugin plugin, const char[] method, const char[] path, MUIRoute buffer)
{
    MUIRoute route;
    for (int i = 0; i < plugin.m_Routes.Length; i++)
    {
        plugin.m_Routes.GetArray(i, route, sizeof(route));
        if (!StrEqual(route.m_szMethod, method))
        {
            continue;
        }

        if (!StrEqual(route.m_szPath, path))
        {
            continue;
        }

        buffer = route;
        return true;
    }

    return false;
}

bool FindRouteByName(MUIPlugin plugin, const char[] name, MUIRoute buffer)
{
    int arrIndex;
    if (!plugin.m_RouteNames.GetValue(name, arrIndex))
        return false;

    if (plugin.m_Routes.Length <= arrIndex)
    {
        LogError("FindRouteByName: m_RouteNames contained index >= then total routes count.");
        return false;
    }

    plugin.m_Routes.GetArray(arrIndex, buffer, sizeof(buffer));
    return true;
}

void NormalizeRoutePath(char[] path, int len)
{
    ReplaceString(path, len, "\\", "/");
    TrimString(path);

    // First character must be a slash
    if (path[0] != '/')
    {
        Format(path, len, "/%s", path);
    }

    // Remove everything after first "?";
    char szExploded[2][PLATFORM_MAX_PATH];
    ExplodeString(path, "?", szExploded, sizeof(szExploded), sizeof(szExploded[]));
    strcopy(path, len, szExploded[0]);
}

bool FindVirtualEntryById(const char[] id, MUIPlugin buffer)
{
    return g_hVirtualMap.GetArray(id, buffer, sizeof(buffer));
}

bool FindVirtualEntryByPlugin(Handle plugin, MUIPlugin buffer)
{
    char szVirtualId[MAX_VIRTUAL_ID_SIZE];
    if (!FindPluginByVirtualId(plugin, szVirtualId, sizeof(szVirtualId)))
    {
        return false;
    }

    return FindVirtualEntryById(szVirtualId, buffer);
}

bool ResolvePluginFromUrl(const char[] url, MUIPlugin buffer)
{
    char szVirtualId[1][MAX_VIRTUAL_ID_SIZE];
    ExplodeString(url[1], "/", szVirtualId, sizeof(szVirtualId), sizeof(szVirtualId[]));

    return FindVirtualEntryById(szVirtualId[0], buffer);
}

bool ResolveContentType(const char[] ext, char[] contentType, int len)
{
    return g_hExtContentType.GetString(ext, contentType, len);
}

int GenerateAccessToken(const char[] alphabet, char[] output, int len)
{
    int choices = strlen(alphabet);
    for (int i = 0; i < len - 1; i++)
        output[i] = alphabet[GetRandomInt(0, choices - 1)];

    return len;
}

void RegenerateClientToken(int client)
{
    g_hAccessTokenOwner.Remove(g_szAccessToken[client]);
    GenerateAccessToken(g_szTokenAlphabet, g_szAccessToken[client], sizeof(g_szAccessToken[]));
    g_hAccessTokenOwner.SetValue(g_szAccessToken[client], client);
}

void ApplyHeadersToResponse(StringMap headers, WebResponse response)
{
    char              szHeader[128], szValue[512];
    StringMapSnapshot snap = headers.Snapshot();
    for (int i = 0; i < snap.Length; i++)
    {
        snap.GetKey(i, szHeader, sizeof(szHeader));
        headers.GetString(szHeader, szValue, sizeof(szValue));
        response.AddHeader(szHeader, szValue);
    }
}

void ShowClientUrlPage(int client, const char[] redirectUrl, bool useAuth = true)
{
    DataPack pack = new DataPack();
    pack.WriteString(redirectUrl);
    pack.WriteCell(useAuth);
    pack.Reset();

    QueryClientConVar(client, "cl_disablehtmlmotd", OnDisableHtmlMotdChecked, pack);
}

void SendStringToConnection(WebConnection connection, WebStatus code, const char[] msg, StringMap headers = null)
{
    WebStringResponse resp = new WebStringResponse(msg);
    if (headers != INVALID_HANDLE) ApplyHeadersToResponse(headers, resp);
    connection.QueueResponse(code, resp);
    CloseHandle(resp);
}

public Action ClosedMOTD(int client, const char[] command, int argc)
{
    AdvMOTD_ShowMOTDPanel(client, "", "about:blank", MOTDPANEL_TYPE_URL, false, false);
    return Plugin_Continue;
}

//---------------------------------------------------------------------------------
// Natives
//---------------------------------------------------------------------------------

int Native_RegisterVirtualId(Handle plugin, int numParams)
{
    char szVirtualId[MAX_VIRTUAL_ID_SIZE];
    GetNativeString(1, szVirtualId, sizeof(szVirtualId));

    if (g_hVirtualMap.ContainsKey(szVirtualId))
    {
        ThrowNativeError(SP_ERROR_ABORTED, "Virtual ID \"%s\" is already taken by another plugin.", szVirtualId);
    }

    char szPluginName[PLATFORM_MAX_PATH];
    GetPluginFilename(plugin, szPluginName, sizeof(szPluginName));
    if (IsPluginRegistered(plugin))
    {
        ThrowNativeError(SP_ERROR_ABORTED, "Plugin \"%s\" is already owning another virtual ID.", szPluginName);
    }

    MUIPlugin entry;
    entry.m_hPlugin    = plugin;
    entry.m_Routes     = new ArrayList(sizeof(MUIRoute));
    entry.m_RouteNames = new StringMap();
    strcopy(entry.m_szVirtualId, sizeof(entry.m_szVirtualId), szVirtualId);
    GetNativeString(2, entry.m_szPublicPath, sizeof(entry.m_szPublicPath));

    g_hVirtualMap.SetArray(szVirtualId, entry, sizeof(entry));
    g_hPluginToVirtualIdMap.SetString(szPluginName, szVirtualId);

    LogMessage("Virtual ID \"%s\" allocated by \"%s\".", szVirtualId, szPluginName);
    return 0;
}

int Native_Route(Handle plugin, int numParams)
{
    MUIPlugin entry;
    if (!FindVirtualEntryByPlugin(plugin, entry))
    {
        ThrowNativeError(SP_ERROR_ABORTED, "Plugin does not have a registered Virtual ID");
    }

    char szName[32];
    GetNativeString(4, szName, sizeof(szName));
    TrimString(szName);

    if (strlen(szName) > 0)
    {
        if (entry.m_RouteNames.ContainsKey(szName))
        {
            ThrowNativeError(SP_ERROR_ABORTED, "Route named \"%s\" already exists for this plugin.", szName);
        }

        entry.m_RouteNames.SetValue(szName, entry.m_Routes.Length);
    }

    MUIRoute route;
    GetNativeString(1, route.m_szMethod, sizeof(route.m_szMethod));
    GetNativeString(2, route.m_szPath, sizeof(route.m_szPath));
    NormalizeRoutePath(route.m_szPath, sizeof(route.m_szPath));
    route.m_fnHandler = GetNativeFunction(3);
    entry.m_Routes.PushArray(route, sizeof(route));

    return 0;
}

int Native_GetRouteUrl(Handle plugin, int numParams)
{
    MUIPlugin entry;
    if (!FindVirtualEntryByPlugin(plugin, entry))
    {
        ThrowNativeError(SP_ERROR_ABORTED, "Plugin does not have a registered Virtual ID");
    }

    char szName[32];
    GetNativeString(1, szName, sizeof(szName));

    MUIRoute route;
    if (!FindRouteByName(entry, szName, route))
    {
        ThrowNativeError(SP_ERROR_ABORTED, "Route named \"%s\" is not found", szName);
    }

    char szUrl[PLATFORM_MAX_PATH];
    Format(szUrl, sizeof(szUrl), "/~/%s%s", entry.m_szVirtualId, route.m_szPath);

    int len = GetNativeCell(3);
    SetNativeString(2, szUrl, len);
    return 0;
}

any Native_Request_GetParameter(Handle plugin, int numParams)
{
    int keyLen;
    GetNativeStringLength(2, keyLen);
    char[] szKey = new char[keyLen++];
    GetNativeString(2, szKey, keyLen);
    LogMessage("key: %s", szKey);

    DataPack reqPack = GetNativeCell(1);
    reqPack.Reset();

    char          szUrl[PLATFORM_MAX_PATH];
    char          szMethod[32];
    WebConnection connection = reqPack.ReadCell();
    reqPack.ReadString(szUrl, sizeof(szUrl));
    reqPack.ReadString(szMethod, sizeof(szMethod));
    LogMessage("url: %s, method: %s", szUrl, szMethod);

    int bufferLen = GetNativeCell(4);
    LogMessage("buffer len: %d", bufferLen);
    char[] szBuffer = new char[bufferLen++];
    connection.GetRequestData(WebRequestDataType_Get, szKey, szBuffer, bufferLen);
    LogMessage("Extracted: %s", szBuffer);
    SetNativeString(3, szBuffer, bufferLen);

    return 0;
}

any Native_Response_SendString(Handle plugin, int numParams)
{
    int strLen;
    GetNativeStringLength(2, strLen);

    char[] buffer = new char[strLen++];
    GetNativeString(2, buffer, strLen);

    DataPack respPack = GetNativeCell(1);
    respPack.Reset();
    WebConnection connection = respPack.ReadCell();
    WebStatus     statusCode = respPack.ReadCell();
    StringMap     headers    = respPack.ReadCell();

    SendStringToConnection(connection, statusCode, buffer, headers);
    CloseResponseDataPack(respPack);
    return 0;
}

any Native_Response_SendFile(Handle plugin, int numParams)
{
    int strLen;
    GetNativeStringLength(2, strLen);

    char[] path = new char[strLen++];
    GetNativeString(2, path, strLen);

    DataPack respPack = GetNativeCell(1);
    respPack.Reset();
    WebConnection connection = respPack.ReadCell();
    WebStatus     statusCode = respPack.ReadCell();
    StringMap     headers    = respPack.ReadCell();

    char          szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof(szPath), path);
    LogMessage("Sending file: %s", szPath);

    if (!FileExists(szPath))
    {
        SendStringToConnection(connection, WebStatus_NotFound, "File to send not found.", headers);
        CloseResponseDataPack(respPack);
        return 0;
    }

    char szExt[11], szContentType[32];
    GetFileExtension(path, szExt, sizeof(szExt));

    WebFileResponse resp = new WebFileResponse(szPath);
    ApplyHeadersToResponse(headers, resp);
    if (ResolveContentType(szExt, szContentType, sizeof(szContentType)))
    {
        resp.AddHeader(WebHeader_ContentType, szContentType);
    }

    connection.QueueResponse(statusCode, resp);
    CloseHandle(resp);
    return 0;
}

any Native_Response_SendKeyValues(Handle plugin, int numParams)
{
    KeyValues kv = GetNativeCell(2);
    kv.GotoFirstSubKey(false);
    kv.GoBack();

    DataPack respPack = GetNativeCell(1);
    respPack.Reset();
    WebConnection connection = respPack.ReadCell();
    WebStatus     statusCode = respPack.ReadCell();
    StringMap     headers    = respPack.ReadCell();

    char          szKey[32];
    kv.GetSectionName(szKey, sizeof(szKey));

    Handle json = KeyValuesToJSON(kv);
    json        = json_object_get(json, szKey);
    json_dump_file(json, g_szJsonCacheFilePath, 0);

    WebFileResponse resp = new WebFileResponse(g_szJsonCacheFilePath);
    resp.AddHeader("Content-Type", "application/json");
    ApplyHeadersToResponse(headers, resp);
    connection.QueueResponse(statusCode, resp);
    CloseHandle(resp);

    CloseResponseDataPack(respPack);
    return 0;
}

any Native_Response_SetHeader(Handle plugin, int numParams)
{
    int headerLen;
    GetNativeStringLength(2, headerLen);
    char[] header = new char[headerLen++];
    GetNativeString(2, header, headerLen);

    int valueLen;
    GetNativeStringLength(3, valueLen);
    char[] value = new char[valueLen++];
    GetNativeString(3, value, valueLen);

    DataPack pack = GetNativeCell(1);
    pack.Reset();
    pack.Position++;
    pack.Position++;
    StringMap headers = pack.ReadCell();

    headers.SetString(header, value);
    return 0;
}

any Native_Response_StatusCode_set(Handle plugin, int numParams)
{
    int      value = GetNativeCell(2);

    DataPack pack  = GetNativeCell(1);
    pack.Reset();
    pack.Position++;
    pack.WriteCell(value);

    return 0;
}

any Native_Response_StatusCode_get(Handle plugin, int numParams)
{
    DataPack pack = GetNativeCell(1);
    pack.Reset();
    pack.Position++;
    return pack.ReadCell();
}

any Native_ShowPanelRoute(Handle plugin, int numParams)
{
    int       client = GetNativeCell(1);

    MUIPlugin entry;
    if (!FindVirtualEntryByPlugin(plugin, entry))
    {
        ThrowNativeError(SP_ERROR_ABORTED, "Plugin does not have a registered Virtual ID");
    }

    char szUrl[PLATFORM_MAX_PATH];
    GetNativeString(2, szUrl, sizeof(szUrl));

    MUIRoute route;
    if (!FindRouteByName(entry, szUrl, route))
    {
        ThrowNativeError(SP_ERROR_ABORTED, "Route named \"%s\" is not found", szUrl);
    }

    Format(szUrl, sizeof(szUrl), "/~/%s%s", entry.m_szVirtualId, route.m_szPath);
    ShowClientUrlPage(client, szUrl);
    return 0;
}

any Native_ShowPanelUrl(Handle plugin, int numParams)
{
    int       client = GetNativeCell(1);

    MUIPlugin entry;
    if (!FindVirtualEntryByPlugin(plugin, entry))
    {
        ThrowNativeError(SP_ERROR_ABORTED, "Plugin does not have a registered Virtual ID");
    }

    char szUrl[PLATFORM_MAX_PATH];
    GetNativeString(2, szUrl, sizeof(szUrl));
    NormalizeRoutePath(szUrl, sizeof(szUrl));
    Format(szUrl, sizeof(szUrl), "/~/%s%s", entry.m_szVirtualId, szUrl);

    ShowClientUrlPage(client, szUrl);
    return 0;
}

any Native_ShowPanelPublicAsset(Handle plugin, int numParams)
{
    int       client = GetNativeCell(1);

    MUIPlugin entry;
    if (!FindVirtualEntryByPlugin(plugin, entry))
    {
        ThrowNativeError(SP_ERROR_ABORTED, "Plugin does not have a registered Virtual ID");
    }

    char szUrl[PLATFORM_MAX_PATH];
    GetNativeString(2, szUrl, sizeof(szUrl));
    NormalizeRoutePath(szUrl, sizeof(szUrl));
    Format(szUrl, sizeof(szUrl), "/public/%s%s", entry.m_szVirtualId, szUrl);

    ShowClientUrlPage(client, szUrl, false);
    return 0;
}

any Native_ClosePanel(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    AdvMOTD_ShowMOTDPanel(client, "", "about:blank", MOTDPANEL_TYPE_URL, false, false);
    return 0;
}

void OnDisableHtmlMotdChecked(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, DataPack pack)
{
    char redirectUrl[PLATFORM_MAX_PATH];
    pack.ReadString(redirectUrl, sizeof(redirectUrl));
    bool useAuth = pack.ReadCell();
    CloseHandle(pack);

    if (!StrEqual(cvarValue, "0"))
    {
        PrintToChat(client, "\x01* You have HTML page support disabled. Please enter \x03cl_disablehtmlmotd 0 \x01in the console and try running the command again.");
        PrintHintText(client, "You have HTML page support disabled. Please enter \n'cl_disablehtmlmotd 0' in the console and try running the command again.");
        return;
    }

    char szMotdUrl[PLATFORM_MAX_PATH];
    sm_motdui_loopback_url.GetString(szMotdUrl, sizeof(szMotdUrl));

    if (useAuth)
    {
        strcopy(g_szAuthRedirectToUrl[client], sizeof(g_szAuthRedirectToUrl), redirectUrl);
        RegenerateClientToken(client);

        Format(
            szMotdUrl, sizeof(szMotdUrl),
            "%s/auth/%s",
            szMotdUrl,
            g_szAccessToken[client]);

        if (sm_motdui_debug_print_auth_url.BoolValue)
        {
            LogMessage(szMotdUrl);
            return;
        }
    }
    else
    {
        Format(szMotdUrl, sizeof(szMotdUrl), "%s%s", szMotdUrl, redirectUrl);
    }

    AdvMOTD_ShowMOTDPanel(client, "MOTDUI", szMotdUrl, MOTDPANEL_TYPE_URL, true, true, TEXTWINDOW_CMD_CLOSED_HTMLPAGE);
}

Handle KeyValuesToJSON(Handle kv)
{
    Handle obj = json_object();
    IterateKeyValues(kv, obj);
    return obj;
}

void IterateKeyValues(Handle kv, Handle &hObj)
{
    do
    {
        char sSection[255];
        KvGetSectionName(kv, sSection, sizeof(sSection));

        char sValue[255];
        KvGetString(kv, "", sValue, sizeof(sValue));

        bool bIsSubSection = ((KvNodesInStack(kv) == 0) || (KvGetDataType(kv, "") == KvData_None && KvNodesInStack(kv) > 0));

        if (!bIsSubSection)
        {
            // if(type != KvData_None) {
            json_object_set_new(hObj, sSection, json_string(sValue));
        }
        else {
            // We have no value, this must be another section
            Handle hChild = json_object();

            if (KvGotoFirstSubKey(kv, false))
            {
                IterateKeyValues(kv, hChild);
                KvGoBack(kv);
            }

            json_object_set_new(hObj, sSection, hChild);
        }
    }
    while (KvGotoNextKey(kv, false));
}