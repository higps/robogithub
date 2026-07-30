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

void HttpMr(int client, MotdUIRequest req, MotdUIResponse res)
{
    char szName[PLATFORM_MAX_PATH];
    req.GetParameter("name", szName, sizeof(szName));

    ClientCommand(client, "sm_mr \"%s\"", szName);
    //PrintToChat(client, "sm_mr \"%s\"", szName);
    MotdUI.ClosePanel(client);
    res.SendString("OK");
}

public Action cMenu(int client, int args)
{
    MotdUI.ShowPanelUrl(client, "/");
    return Plugin_Handled;
}