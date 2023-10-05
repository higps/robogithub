#include <sourcemod>
#include <berobot_constants>
#include <berobot>
#define PATH "cfg/robots"
#define PLUGIN_VERSION "0.01"
KeyValues g_hConfig;
public void OnPluginStart()
{
    char fileName[256];
    Handle dir = OpenDirectory(PATH);
    if(dir == null)
    {
        LogError("Failed to open directory: %s", PATH);
        return;
    }
    
    while (ReadDirEntry(dir, fileName, sizeof(fileName)))
    {
        // Only process .cfg files
        if(StrContains(fileName, ".cfg") != -1)
        {
			// ProcessCfgFile(fileName);
			LoadConfig(fileName);
        }
    }
    
    CloseHandle(dir);
}

public void LoadConfig(char[] fileName)
{
	if (g_hConfig != INVALID_HANDLE)delete g_hConfig;

	g_hConfig = new KeyValues("Robot");
	char fullPath[256];
	Format(fullPath, sizeof(fullPath), "%s/%s", PATH, fileName);
	PrintToChatAll("Filename %s, fullPath% %s", fileName, fullPath);
	g_hConfig.ImportFromFile(fullPath);
	ReadConfig();



}

public void ReadConfig()
{
	
    char robotName[64];
    if (g_hConfig.GetString("name", robotName, sizeof(robotName)))
    {
        PrintToChatAll("Robot Name: %s", robotName);

		char role[64], class[9], subclass[32], shortDescription[NAMELENGTH], tips[256];
        char deathtip[256], model[256];
        int difficulty, health;
        float scale;
		RobotDefinition robot;
        // Attempt to fetch each attribute and set it
        g_hConfig.GetString("role", role, sizeof(role));
        g_hConfig.GetString("class", class, sizeof(class));
        g_hConfig.GetString("subclass", subclass, sizeof(subclass));
        g_hConfig.GetString("shortdescription", shortDescription, sizeof(shortDescription));
        g_hConfig.GetString("tips", tips, sizeof(tips));
        g_hConfig.GetString("deathtip", deathtip, sizeof(deathtip));
        g_hConfig.GetString("model", model, sizeof(model));
        g_hConfig.GetNum("difficulty", difficulty);
        g_hConfig.GetNum("health", health);
        g_hConfig.GetFloat("scale", scale);

        // Map the attributes to robot's properties
        robot.name = robotName;
        robot.role = role;
        robot.class = class;
        robot.subclass = subclass;
        robot.shortDescription = shortDescription;
        robot.tips = tips;
        robot.deathtip = deathtip;
        robot.model = model;
        robot.difficulty = difficulty;
        robot.health = health;
        robot.scale = scale;

    // Only continue if there are sounds to be added
    if (g_hConfig.JumpToKey("sounds", false))
    {
        char sound[256];  // Adjust the size based on your expected maximum sound file path.

        if (g_hConfig.GetString("spawn", sound, sizeof(sound)))
        {
            PrintToChatAll("Spawn Sound: %s", sound);
            robot.sounds.spawn = sound;
        }

        if (g_hConfig.GetString("death", sound, sizeof(sound)))
        {
            PrintToChatAll("Death Sound: %s", sound);
            robot.sounds.death = sound;
        }

        if (g_hConfig.GetString("loop", sound, sizeof(sound)))
        {
            PrintToChatAll("Loop Sound: %s", sound);
            robot.sounds.loop = sound;
        }

        if (g_hConfig.GetString("gunfire", sound, sizeof(sound)))
        {
            PrintToChatAll("Gunfire Sound: %s", sound);
            robot.sounds.gunfire = sound;
        }

        if (g_hConfig.GetString("gunspin", sound, sizeof(sound)))
        {
            PrintToChatAll("Gunspin Sound: %s", sound);
            robot.sounds.gunspin = sound;
        }

        if (g_hConfig.GetString("windup", sound, sizeof(sound)))
        {
            PrintToChatAll("Windup Sound: %s", sound);
            robot.sounds.windup = sound;
        }

        if (g_hConfig.GetString("winddown", sound, sizeof(sound)))
        {
            PrintToChatAll("Winddown Sound: %s", sound);
            robot.sounds.winddown = sound;
        }

        g_hConfig.GoBack();  // Go back to the parent "Robot" key after processing all sounds.
    }
    else
    {
        PrintToChatAll("No sounds key found for the robot.");
    }



		AddRobot(robot, MakeRobot, PLUGIN_VERSION);
    }
    else
    {
        PrintToChatAll("Unable to retrieve 'name' from 'Robot'");
    }


}


MakeRobot(client)
{	
	PrintToChatAll("Robot stuff goes here");
}