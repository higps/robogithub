#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>
#include <sm_logger>
#include <berobot_constants>

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum (<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR
}
#include <berobot>
#include <berobot_core>
#include <berobot_core_restrictions>
#pragma newdecls required
#pragma semicolon 1

#define MAX_SELECTIONS 3

public Plugin myinfo =
{
	name = "berobot_selection",
	author = "Heavy Is GPS & icebear",
	description = "provides menus for client to select a robot",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

methodmap RobotSubclass < StringMap {
    property int Count {
        public get(){ 
            int value;
            this.GetValue("Count", value);
            return value;
        }
        public set(int value){
            this.SetValue("Count", value);
        }
    }
    property ArrayList Robots {
        public get(){ 
            ArrayList value;
            this.GetValue("Robots", value);
            return value;
        }
        public set(ArrayList value){
            this.SetValue("Robots", value);
        }
    }

    public RobotSubclass() {
        RobotSubclass category = view_as<RobotSubclass>(new StringMap());
        Robot robot;
        category.Robots = new ArrayList(sizeof(robot));
        category.Count = 0;
        return category;
    }

    public void Hydrate()
    {
        int count = 0;
        for(int i = 0; i < this.Robots.Length; i++)
        {
            Robot robot;
            this.Robots.GetArray(i, robot);
            count += GetRobotCount(robot.name);
        }
        this.Count = count;        
    }

    public void AddMenuItem(Menu menu, char name[NAMELENGTH], char key[NAMELENGTH])
    {
        int count = this.Count;
        int max = this.Robots.Length;

        int draw = ITEMDRAW_DEFAULT;
        if (count >= max)
            draw = ITEMDRAW_DISABLED;

        char display[128];
        Format(display, sizeof(display), "%s: (%i / %i)", name, count, max);

        menu.AddItem(key, display, draw);
    }

    public void Dispose()
    {
        delete this.Robots;
        delete this;
    }
}

methodmap RobotRole < StringMap {
    property int Count {
        public get(){ 
            int value;
            this.GetValue("Count", value);
            return value;
        }
        public set(int value){
            this.SetValue("Count", value);
        }
    }
    property int Max {
        public get(){ 
            int value;
            this.GetValue("Max", value);
            return value;
        }
        public set(int value){
            this.SetValue("Max", value);
        }
    }
    property StringMap Subclasses {
        public get(){ 
            StringMap value;
            this.GetValue("Subclasses", value);
            return value;
        }
        public set(StringMap value){
            this.SetValue("Subclasses", value);
        }
    }

    public RobotRole() {
        RobotRole category = view_as<RobotRole>(new StringMap());
        category.Subclasses = new StringMap();
        return category;
    }

    public RobotSubclass Get(char key[NAMELENGTH])
    {
        RobotSubclass robotSubclass;
        this.Subclasses.GetValue(key, robotSubclass);
        return robotSubclass;
    }

    public void Hydrate()
    {
        int count = 0;
        int max = 0;
        SMLogTag(SML_VERBOSE, "hydrating %i Subclasses in RobotRole", this.Subclasses.Size);
        StringMapSnapshot snapshot = this.Subclasses.Snapshot();
        for(int i = 0; i < snapshot.Length; i++)
        {
            char key[NAMELENGTH];
            snapshot.GetKey(i, key, sizeof(key));
            RobotSubclass robotSubclass = this.Get(key);
            robotSubclass.Hydrate();

            count += robotSubclass.Count;
            max += robotSubclass.Robots.Length;
        }
        delete snapshot;

        this.Count = count;
        this.Max = max;
        
        SMLogTag(SML_VERBOSE, "hydrated RobotRole %i / %i", this.Count, this.Max);
    }

    public void AddMenuItem(Menu menu)
    {
        StringMapSnapshot snapshot = this.Subclasses.Snapshot();
        for(int i = 0; i < snapshot.Length; i++)
        {
            char key[NAMELENGTH];
            snapshot.GetKey(i, key, sizeof(key));
            RobotSubclass robotSubclass = this.Get(key);
            robotSubclass.AddMenuItem(menu, key, key);
        }
        delete snapshot;
    }

    public void Dispose()
    {
        StringMapSnapshot snapshot = this.Subclasses.Snapshot();
        for(int i = 0; i < snapshot.Length; i++)
        {
            char key[NAMELENGTH];
            snapshot.GetKey(i, key, sizeof(key));
            RobotSubclass robotSubclass = this.Get(key);
            robotSubclass.Dispose();
        }
        delete snapshot;

        delete this;
    }
}

methodmap RobotCategory < StringMap {
    property int Count {
        public get(){ 
            int value;
            this.GetValue("Count", value);
            return value;
        }
        public set(int value){
            this.SetValue("Count", value);
        }
    }
    property int Max {
        public get(){ 
            int value;
            this.GetValue("Max", value);
            return value;
        }
        public set(int value){
            this.SetValue("Max", value);
        }
    }
    property StringMap Roles {
        public get(){ 
            StringMap value;
            this.GetValue("Roles", value);
            return value;
        }
        public set(StringMap value){
            this.SetValue("Roles", value);
        }
    }

    public RobotCategory() {
        RobotCategory category = view_as<RobotCategory>(new StringMap());
        category.Roles = new StringMap();
        return category;
    }

    public RobotRole Get(char key[NAMELENGTH])
    {
        RobotRole robotRole;
        this.Roles.GetValue(key, robotRole);
        return robotRole;
    }

    public void Hydrate()
    {
        int count = 0;
        int max = 0;
        SMLogTag(SML_VERBOSE, "hydrating %i Roles in RobotCategory", this.Roles.Size);
        StringMapSnapshot snapshot = this.Roles.Snapshot();
        for(int i = 0; i < snapshot.Length; i++)
        {
            char key[NAMELENGTH];
            snapshot.GetKey(i, key, sizeof(key));
            RobotRole robotRole = this.Get(key);
            robotRole.Hydrate();

            count += robotRole.Count;
            max += robotRole.Max;
        }
        delete snapshot;

        this.Count = count;
        this.Max = max;
        
        SMLogTag(SML_VERBOSE, "hydrated RobotCategory %i / %i", this.Count, this.Max);
    }

    public void AddMenuItem(Menu menu)
    {
        StringMapSnapshot snapshot = this.Roles.Snapshot();
        for(int i = 0; i < snapshot.Length; i++)
        {
            char key[NAMELENGTH];
            snapshot.GetKey(i, key, sizeof(key));
            RobotRole robotRole = this.Get(key);

            int draw = ITEMDRAW_DEFAULT;
            if (robotRole.Count >= robotRole.Max)
                draw = ITEMDRAW_DISABLED;

            char display[128];
            Format(display, sizeof(display), "%s: (%i / %i)", key, robotRole.Count, robotRole.Max);

            menu.AddItem(key, display, draw);
        }
        delete snapshot;
    }

    public void Dispose()
    {
        StringMapSnapshot snapshot = this.Roles.Snapshot();
        for(int i = 0; i < snapshot.Length; i++)
        {
            char key[NAMELENGTH];
            snapshot.GetKey(i, key, sizeof(key));
            RobotRole robotRole = this.Get(key);
            robotRole.Dispose();
        }
        delete snapshot;

        delete this;
    }
}

methodmap RobotSelectionMenu < StringMap {    
    public RobotSelectionMenu() {
        return view_as<RobotSelectionMenu>(new StringMap());
    }

    public RobotSubclass GetBosses()
    {
        RobotSubclass subclass;
        this.GetValue("ZBOSS", subclass);

        return subclass;
    }

    public void SetBosses(RobotSubclass robotSubclass)
    {
        this.SetValue("ZBOSS", robotSubclass);
    }

    public void GetKey(bool isFree, char key[5])
    {
        if (isFree)
            key = "Free";
        else
            key = "Paid";
    }

    public RobotCategory Get(bool isFree)
    {
        char key[5];
        this.GetKey(isFree, key);
        RobotCategory category;
        this.GetValue(key, category);
        return category;
    }

    public void Set(bool isFree, RobotCategory category)
    {
        char key[5];
        this.GetKey(isFree, key);
        this.SetValue(key, category);
    }

    public void Hydrate()
    {
        RobotCategory free = this.Get(true);
        if (free)
            free.Hydrate();
            
        RobotCategory paid = this.Get(false);
        if (paid)
            paid.Hydrate();
            
        RobotSubclass boss = this.GetBosses();
        if (boss)
            boss.Hydrate();
    }

    public void AddMenuItemForCategory(Menu menu, bool isFree, char[] name, char[] value)
    {
        RobotCategory category = this.Get(isFree);

        int draw = ITEMDRAW_DEFAULT;
        if (category.Count >= category.Max)
            draw = ITEMDRAW_DISABLED;

        char display[128];
        Format(display, sizeof(display), "%s: (%i / %i)", name, category.Count, category.Max);

        menu.AddItem(value, display, draw);
    }

    public void AddMenuItem(Menu menu)
    {
        this.AddMenuItemForCategory(menu, true, "MK I: Gain R₡", "Free");
        this.AddMenuItemForCategory(menu, false, "MK II: Spend R₡", "Paid");
        this.GetBosses().AddMenuItem(menu, "Bosses: Spend B₡ + R₡ ", "ZBOSS");
        // Robot-₡oins: %i\nBoss-₡oins:
    }

    public void Dispose()
    {
        this.GetBosses().Dispose();
        this.Get(true).Dispose();
        this.Get(false).Dispose();

        delete this;
    }
}

bool g_ClientIsRepicking[MAXPLAYERS + 1];
Menu g_chooseRobotMenus[MAXPLAYERS + 1];
RobotSelectionMenu g_menu;
char g_selections[MAXPLAYERS + 1][MAX_SELECTIONS + 1][NAMELENGTH];

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_selection started at %i", GetTime());
	
    LoadMenuTree();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("SetClientRepicking", Native_SetClientRepicking);
    CreateNative("IsRepicking", Native_IsRepicking);
    CreateNative("Menu_RobotSelection", Native_Menu_RobotSelection);
    return APLRes_Success;
}

public void MM_OnClientResetting(int clientId)
{
    g_ClientIsRepicking[clientId] = false;
    g_selections[clientId][0] = "";
    g_selections[clientId][1] = "";
    g_selections[clientId][2] = "";
    if (g_chooseRobotMenus[clientId] == null)
        return;
    
    SMLogTag(SML_VERBOSE, "canceling ChooseRobot-menu for %L", clientId);
    g_chooseRobotMenus[clientId].Cancel();
    g_chooseRobotMenus[clientId] = null;
}

public void MM_OnRobotStorageChanged()
{
    LoadMenuTree();
}

public void LoadMenuTree()
{
    ArrayList robotNames = GetRobotNames();
    SMLogTag(SML_VERBOSE, "%i robots found", robotNames.Length);

    ArrayList robotDefinitions = new ArrayList(sizeof(Robot));
    for(int i = 0; i < robotNames.Length; i++)
    {
        char name[NAMELENGTH];
        robotNames.GetString(i, name, NAMELENGTH);
        Robot item;
        if (GetRobotDefinition(name, item) != 0)
        {
            SMLogTag(SML_ERROR, "could not volunteer. no robot with name '%s' found", name);
            return;
        }

        robotDefinitions.PushArray(item);
    }
    delete robotNames;
    robotDefinitions.SortCustom(RobotDefinitionComparision);

    RobotSelectionMenu menu = new RobotSelectionMenu();
    char bossRole[NAMELENGTH] = "ZBOSS";
    for(int i = 0; i < robotDefinitions.Length; i++)
    {
        Robot robot;
        robotDefinitions.GetArray(i, robot);
        bool isFree = !robot.restrictions.IsActive();
        bool isBoss = strcmp(robot.role, bossRole) == 0;

        if (isBoss)
        {
            RobotSubclass bossRobotRole = menu.GetBosses();
            if (!bossRobotRole)
            {
                bossRobotRole = new RobotSubclass();
                menu.SetBosses(bossRobotRole);
            }
            bossRobotRole.Robots.PushArray(robot);
            SMLogTag(SML_VERBOSE, "adding Boss-Robot %s", robot.name);
        }
        else
        {
            RobotCategory category = menu.Get(isFree);
            if (!category)
            {
                category = new RobotCategory();
                menu.Set(isFree, category);
            }

            char subclass[32];
            if (robot.subclass[0] == '\0')
                subclass = "Other";
            else
                strcopy(subclass, sizeof(subclass), robot.subclass);
            

            RobotRole robotRole;
            if (!category.Roles.GetValue(robot.role, robotRole))
            {
                robotRole = new RobotRole();
                category.Roles.SetValue(robot.role, robotRole);
            }

            RobotSubclass robotSubclass;
            if (!robotRole.Subclasses.GetValue(subclass, robotSubclass))
            {
                robotSubclass = new RobotSubclass();
                robotRole.Subclasses.SetValue(subclass, robotSubclass);
            }

            robotSubclass.Robots.PushArray(robot);
            SMLogTag(SML_VERBOSE, "adding nonBoss-Robot %s (free: %i)", robot.name, isFree);
        }
    }
    delete robotDefinitions;

    StringMap freeCategory = menu.Get(true);
    SMLogTag(SML_VERBOSE, "Free-Robots %i", freeCategory);
    StringMap paidCategory = menu.Get(false);
    SMLogTag(SML_VERBOSE, "Paid-Robots %i", paidCategory);

    menu.Hydrate();

    if (g_menu)
    {
        RobotSelectionMenu oldMenu = g_menu;
        g_menu = null;
        oldMenu.Dispose();
    }
    g_menu = menu;
}

any Native_SetClientRepicking(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    bool repicking = GetNativeCell(2);

    g_ClientIsRepicking[client] = repicking;
}

any Native_IsRepicking(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    return g_ClientIsRepicking[client];
}

any Native_Menu_RobotSelection(Handle plugin, int numParams)
{
    int clientId = GetNativeCell(1);
    bool redrawing = GetNativeCell(2);

    if (!redrawing)
    {
        g_selections[clientId][0] = "";
        g_selections[clientId][1] = "";
        g_selections[clientId][2] = "";
    }

    Menu_TopLevel(clientId);
}

void Menu_TopLevel(int clientId)
{
    g_menu.Hydrate();

    if (g_selections[clientId][0][0] != '\0')
    {
        Menu_SecondLevel(clientId, g_selections[clientId][0]);
        return;
    }

    Menu menu = new Menu(Menu_TopLevel_Handler);

    menu.SetTitle("Select Your Robot Type");
    menu.ExitButton = true;

    g_menu.AddMenuItem(menu);
    
    if (g_chooseRobotMenus[clientId] != null)
        g_chooseRobotMenus[clientId].Cancel();
    g_chooseRobotMenus[clientId] = menu;

    int timeout = MENU_TIME_FOREVER;
    menu.Display(clientId, timeout);
    SMLogTag(SML_VERBOSE, "menu displayed to %L for %i seconds", clientId, timeout);

}
public int Menu_TopLevel_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if(action == MenuAction_Select)
    {
        if (g_chooseRobotMenus[param1] == null)
            return;
        g_chooseRobotMenus[param1] = null;

        char info[NAMELENGTH];
        bool found = menu.GetItem(param2, info, sizeof(info));
        PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

        g_selections[param1][0] = info;
        Menu_SecondLevel(param1, info);
    }
    /* If the menu was cancelled, print a message to the server about it. */
    else if(action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_Interrupted)return;
        g_chooseRobotMenus[param1] = null;
        ResetSelection(param1);

        switch (param2)
        {
            case MenuCancel_Exit:
                g_ClientIsRepicking[param1] = false;
            case MenuCancel_ExitBack:
                Menu_TopLevel(param1);
        }
        // PrintToChatAll("Client %d's menu was cancelled.  Reason: %d", param1, param2);
    }

    /* If the menu has ended, destroy it */
    else if(action == MenuAction_End)
    {
        for(int i = 0; i <= MaxClients; i++)
        {
            if (g_chooseRobotMenus[i] == menu)
                g_chooseRobotMenus[i] = null;
        }
        delete menu;
    }
}

void Menu_SecondLevel(int clientId, char key[NAMELENGTH])
{
    SMLogTag(SML_VERBOSE, "choosing second level based on key %s with first char %c for %L", key, key, clientId);
    switch(key[0])
    {
        case 'F':   //Free
        {
            RobotCategory category = g_menu.Get(true);
            Menu_RobotCategory(clientId, category);
        }
        case 'P':   //Paid
        {
            RobotCategory category = g_menu.Get(false);
            Menu_RobotCategory(clientId, category);
        }
        case 'Z':   //ZBOSS
        {
            RobotSubclass robotRole = g_menu.GetBosses();
            Menu_RobotSubclass(clientId, robotRole);
        }
    }
}

void Menu_RobotCategory(int clientId, RobotCategory category)
{
    if (g_selections[clientId][1][0] != '\0')
    {
        Menu_ThirdLevel(clientId, g_selections[clientId][1]);
        return;
    }




    Menu menu = new Menu(Menu_RobotCategory_Handler);

    menu.SetTitle("Select Your Robot Type");
    menu.ExitBackButton = true;

    category.AddMenuItem(menu);
    
    if (g_chooseRobotMenus[clientId] != null)
        g_chooseRobotMenus[clientId].Cancel();
    g_chooseRobotMenus[clientId] = menu;

    int timeout = MENU_TIME_FOREVER;
    menu.Display(clientId, timeout);
    SMLogTag(SML_VERBOSE, "menu displayed to %L for %i seconds", clientId, timeout);

}
public int Menu_RobotCategory_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if(action == MenuAction_Select)
    {
        if (g_chooseRobotMenus[param1] == null)
            return;
        g_chooseRobotMenus[param1] = null;

        char info[NAMELENGTH];
        bool found = menu.GetItem(param2, info, sizeof(info));
        PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

        g_selections[param1][1] = info;

        Menu_ThirdLevel(param1, info);
    }

    /* If the menu was cancelled, print a message to the server about it. */
    else if(action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_Interrupted)return;
        g_chooseRobotMenus[param1] = null;
        ResetSelection(param1);

        switch (param2)
        {
            case MenuCancel_Exit:
                g_ClientIsRepicking[param1] = false;
            case MenuCancel_ExitBack:
                Menu_TopLevel(param1);
        }
        // PrintToChatAll("Client %d's menu was cancelled.  Reason: %d", param1, param2);
    }

    /* If the menu has ended, destroy it */
    else if(action == MenuAction_End)
    {
        for(int i = 0; i <= MaxClients; i++)
        {
            if (g_chooseRobotMenus[i] == menu)
                g_chooseRobotMenus[i] = null;
        }
        delete menu;
    }
}

void Menu_ThirdLevel(int clientId, char key[NAMELENGTH])
{
    // PrintToChatAll("Third level triggered for %N", clientId);
    RobotCategory category;
    switch(g_selections[clientId][0][0])
    {
        case 'F':   //Free
        {
            category = g_menu.Get(true);
        }
        case 'P':   //Paid
        {
            category = g_menu.Get(false);
        }
    }
    RobotRole robotRole = category.Get(key);
    Menu_RobotRole(clientId, robotRole);
}

void Menu_RobotRole(int client, RobotRole robotRole)
{
    if (robotRole.Subclasses.Size == 0)
    {
        SMLogTag(SML_ERROR, "aborting subclasses-menu for %L since none where defined", client);
        return;
    }

    if (robotRole.Subclasses.Size == 1)
    {
        char key[NAMELENGTH];
        robotRole.Subclasses.Snapshot().GetKey(0, key, sizeof(key));

        SMLogTag(SML_ERROR, "skipping subclasses-menu for %L since only one was defined. selecting %s automatically", client, key);
        Menu_ForthLevel(client, key);
        return;
    }

    if (g_selections[client][2][0] != '\0')
    {
        Menu_ForthLevel(client, g_selections[client][2]);
        return;
    }

    SMLogTag(SML_VERBOSE, "showing %i subclasses for %L", robotRole.Subclasses.Size, client);

    Menu menu = new Menu(Menu_RobotRole_Handler);

    menu.SetTitle("Select Your Robot Type");
    menu.ExitBackButton = true;

    robotRole.AddMenuItem(menu);
    
    if (g_chooseRobotMenus[client] != null)
        g_chooseRobotMenus[client].Cancel();
    g_chooseRobotMenus[client] = menu;

    int timeout = MENU_TIME_FOREVER;
    menu.Display(client, timeout);
    SMLogTag(SML_VERBOSE, "menu displayed to %L for %i seconds", client, timeout);
}

public int Menu_RobotRole_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if(action == MenuAction_Select)
    {
        if (g_chooseRobotMenus[param1] == null)
            return;
        g_chooseRobotMenus[param1] = null;

        char info[NAMELENGTH];
        bool found = menu.GetItem(param2, info, sizeof(info));
        PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

        g_selections[param1][2] = info;

        Menu_ForthLevel(param1, info);
    }
    /* If the menu was cancelled, print a message to the server about it. */
    else if(action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_Interrupted)return;
        g_chooseRobotMenus[param1] = null;
        ResetSelection(param1);

        switch (param2)
        {
            case MenuCancel_Exit:
                g_ClientIsRepicking[param1] = false;
            case MenuCancel_ExitBack:
                Menu_TopLevel(param1);
        }
        // PrintToChatAll("Client %d's menu was cancelled.  Reason: %d", param1, param2);
    }

    /* If the menu has ended, destroy it */
    else if(action == MenuAction_End)
    {
        for(int i = 0; i <= MaxClients; i++)
        {
            if (g_chooseRobotMenus[i] == menu)
                g_chooseRobotMenus[i] = null;
        }
        delete menu;
    }
}

void Menu_ForthLevel(int clientId, char key[NAMELENGTH])
{
    RobotCategory category;
    switch(g_selections[clientId][0][0])
    {
        case 'F':   //Free
        {
            category = g_menu.Get(true);
        }
        case 'P':   //Paid
        {
            category = g_menu.Get(false);
        }
    }
    RobotRole robotRole = category.Get(g_selections[clientId][1]);
    RobotSubclass robotSubclass = robotRole.Get(key);
    Menu_RobotSubclass(clientId, robotSubclass);
}

void Menu_RobotSubclass(int client, RobotSubclass robotSubclass)
{
    SMLogTag(SML_VERBOSE, "showing %i robots per subclass for %L", robotSubclass.Robots.Length, client);

    Menu menu = new Menu(Menu_RobotSubclass_Handler);

    menu.SetTitle("Select Your Robot Type");
    menu.ExitBackButton = true;

    for(int i = 0; i < robotSubclass.Robots.Length; i++)
    {
        Robot item;
        robotSubclass.Robots.GetArray(i, item);

        char notes[15];
        int draw;
        GenerateNotes(item, client, notes, draw);

        char display[128];
        //Format(display, sizeof(display), "%s: %s - %s - %s (%s)", item.role, item.class, item.name, item.shortDescription, notes);
        Format(display, sizeof(display), "%s: %s - %s (%s)", item.class, item.name, item.shortDescription, notes);

        menu.AddItem(item.name, display, draw);

        SMLogTag(SML_VERBOSE, "added option for %s: %s", item.name, display);
    }
    
    if (g_chooseRobotMenus[client] != null)
        g_chooseRobotMenus[client].Cancel();
    g_chooseRobotMenus[client] = menu;

    int timeout = MENU_TIME_FOREVER;
    menu.Display(client, timeout);
    SMLogTag(SML_VERBOSE, "menu displayed to %L for %i seconds", client, timeout);
}

public int Menu_RobotSubclass_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if(action == MenuAction_Select)
    {
        if (g_chooseRobotMenus[param1] == null)
            return;
        g_chooseRobotMenus[param1] = null;

        char info[NAMELENGTH];
        bool found = menu.GetItem(param2, info, sizeof(info));
        PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

        SetRobot(info, param1);
    }
    /* If the menu was cancelled, print a message to the server about it. */
    else if(action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_Interrupted)return;
        g_chooseRobotMenus[param1] = null;
        ResetSelection(param1);

        switch (param2)
        {
            case MenuCancel_Exit:
                g_ClientIsRepicking[param1] = false;
            case MenuCancel_ExitBack:
                Menu_TopLevel(param1);
        }
        // PrintToChatAll("Client %d's menu was cancelled.  Reason: %d", param1, param2);
    }

    /* If the menu has ended, destroy it */
    else if(action == MenuAction_End)
    {
        for(int i = 0; i <= MaxClients; i++)
        {
            if (g_chooseRobotMenus[i] == menu)
                g_chooseRobotMenus[i] = null;
        }
        delete menu;
    }
}

void GenerateNotes(Robot item, int client, char notes[15], int& draw)
{
    int count = GetRobotCount(item.name);
    int roboCap = GetRobotCap(item.name);
    if (count >= roboCap)
    {
        Format(notes, sizeof(notes), "%i / %i", count, roboCap);
        draw = ITEMDRAW_DISABLED;
        return;
    }



    SMLogTag(SML_VERBOSE, "Restrictions handle %b for robot %s", item.restrictions, item.name);
    SMLogTag(SML_VERBOSE, "TimeLeft handle %b for robot %s", item.restrictions.TimeLeft, item.name);
    if (!item.restrictions.TimeLeft.Enabled)
    {
        Format(notes, sizeof(notes), "timeleft: %is", item.restrictions.TimeLeft.SecondsBeforeEndOfRound);
        draw = ITEMDRAW_DISABLED;
        return;
    }

    RobotCoins teamCoins = item.restrictions.GetTeamCoinsFor(client);
    int availableTeamCoins = GetTeamCoinsFor(client);
    int teamCost = teamCoins.GetPrice();
    SMLogTag(SML_VERBOSE, "client %i robot %s teamCost %i", client, item.name, teamCost);
    SMLogTag(SML_VERBOSE, "client %i robot %s availableTeamCoins %i", client, item.name, availableTeamCoins);

    RobotCoins robotCoins = item.restrictions.GetRobotCoinsFor(client);
    int availableRobotCoins = GetRobotCoinsFor(client);
    int robotCost = robotCoins.GetPrice();
    SMLogTag(SML_VERBOSE, "client %i robot %s robotCost %i", client, item.name, robotCost);
    SMLogTag(SML_VERBOSE, "client %i robot %s availableRobotCoins %i", client, item.name, availableRobotCoins);

    
    GenerateCoinNotes(notes, teamCost, robotCost, count, roboCap);

    if (!teamCoins.Enabled)
    {
        draw = ITEMDRAW_DISABLED;
        return;
    }

    if (availableRobotCoins < robotCost)
    {

        draw = ITEMDRAW_DISABLED;
        return;
    }

    // bool BossActive = true;
    if (IsBossActive() && StrContains(notes,"B₡") != -1)
    {
        // PrintToChatAll(notes);
        draw = ITEMDRAW_DISABLED;
        return;
    }
    

    draw = ITEMDRAW_DEFAULT;
}

void GenerateCoinNotes(char notes[15], int teamCost, int robotCost, int count, int roboCap)
{
    //Robot costs boss and robot coints
    if (teamCost > 0 && robotCost > 0)
    {
        Format(notes, sizeof(notes), "%iB₡,%iR₡", teamCost, robotCost);
        return;
    }
    // Robot costs more than 0
    if (teamCost > 0)
    {
        Format(notes, sizeof(notes), "%iB₡", teamCost);
        return;
    }

    if (robotCost == 0)
    {
        Format(notes, sizeof(notes), "%i/%i", count, roboCap);  
        return;
    }
    
    //Format(notes, sizeof(notes), "", robotCost);

    Format(notes, sizeof(notes), "%iR₡)(%i/%i", robotCost, count, roboCap);  
}

void ResetSelection(int clientId)
{
    for(int i = MAX_SELECTIONS; i >= 0; --i)
    {
        if (g_selections[clientId][i][0] != '\0')
        {
            g_selections[clientId][i] = "";
            return;
        }
    }
}

int RobotDefinitionComparision(int index1, int index2, Handle array, Handle hndl)
{
    ArrayList list = view_as<ArrayList>(array); 
    Robot a, b;
    list.GetArray(index1, a);
    list.GetArray(index2, b);


    int rolecmp = strcmp(a.role, b.role);
    if (rolecmp != 0)
        return rolecmp;

    int classcmp = strcmp(a.class, b.class);
    if (classcmp != 0)
        return classcmp;

    int namecmp = strcmp(a.name, b.name);
    if (namecmp != 0)
        return namecmp;

    return strcmp(a.shortDescription, b.shortDescription);
}

bool IsBossActive(){

    for(int i = 1; i <= MaxClients; i++)
    {
        if (IsBoss(i))
        {
            // PrintToChatAll("Boss found, %N was boss", i);
            return true;
        }
    }
    // PrintToChatAll("No Boss found");
    return false;
}