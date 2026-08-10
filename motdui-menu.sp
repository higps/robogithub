#include <motdui>
#include <moonly>

public Plugin myinfo =
{
    name        = "Motd Example",
    author      = "Moonly Days",
    description = "",
    version     = "1.0.0",
    url         = "https://github.com/MoonlyDays"
};

public void OnPluginStart()
{
    MotdUI.RegisterVirtualId("foobar", "");
    MotdUI.Route("GET", "/", HttpMenu);
    MotdUI.Route("GET", "/robot_selection.json", HttpJson);
    MotdUI.Route("GET", "/robot_image", HttpRobotImage);
    MotdUI.Route("GET", "/mr", HttpMr);

    RegConsoleCmd("sm_menu", cMenu);
}

void HttpMenu(int client, MotdUIRequest req, MotdUIResponse res)
{
    res.SendFile("robots/robot_selection.html");
}

void HttpJson(int client, MotdUIRequest req, MotdUIResponse res)
{
    res.SendFile("robots/robot_selection.json");
}

void HttpRobotImage(int client, MotdUIRequest req, MotdUIResponse res)
{
    char szRobotName[128];
    req.GetParameter("name", szRobotName, sizeof(szRobotName));

    char szFileName[128];
    BuildRobotImageFileName(szRobotName, szFileName, sizeof(szFileName));

    char szPath[PLATFORM_MAX_PATH];
    Format(szPath, sizeof(szPath), "robots/img/%s.webp", szFileName);

    char szAbsPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szAbsPath, sizeof(szAbsPath), "%s", szPath);

    if (!FileExists(szAbsPath))
    {
        strcopy(szPath, sizeof(szPath), "robots/img/default.webp");

        BuildPath(Path_SM, szAbsPath, sizeof(szAbsPath), "%s", szPath);
        if (!FileExists(szAbsPath))
        {
            res.StatusCode = 404;
            res.SendString("Image not found");
            return;
        }
    }

    res.SetHeader("Content-Type", "image/webp");
    res.SendFile(szPath);
}

void HttpMr(int client, MotdUIRequest req, MotdUIResponse res)
{
    char szName[PLATFORM_MAX_PATH];
    req.GetParameter("name", szName, sizeof(szName));

    ClientCommand(client, "sm_cr \"%s\"", szName);
    MotdUI.ClosePanel(client);
    res.SendString("OK");
}

public Action cMenu(int client, int args)
{
    MotdUI.ShowPanelUrl(client, "/");
    return Plugin_Handled;
}

void BuildRobotImageFileName(const char[] source, char[] output, int maxlen)
{
    int out = 0;

    for (int i = 0; source[i] != '\0' && out < maxlen - 1; i++)
    {
        char c = source[i];

        if (c >= 'A' && c <= 'Z')
        {
            c = c + ('a' - 'A');
        }

        if (c == ' ')
        {
            c = '_';
        }

        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_')
        {
            output[out++] = c;
        }
    }

    output[out] = '\0';

    if (out == 0)
    {
        strcopy(output, maxlen, "default");
    }
}