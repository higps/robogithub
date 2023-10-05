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

		AddRobot(robot, MakeGDeflectorH, PLUGIN_VERSION);
    }
    else
    {
        PrintToChatAll("Unable to retrieve 'name' from 'Robot'");
    }


}

public void DumpKeys(KeyValues kv, int depth)
{
    char buffer[256];
    char key[64], value[64];
	depth = 0;
    
    while (true)
    {
        kv.GetSectionName(key, sizeof(key));
        kv.GetString(NULL_STRING, value, sizeof(value));
        
        for (int i = 0; i < depth; i++) // Add some indentation for depth
        {
            buffer[i] = ' ';
        }
       Format(buffer[depth], sizeof(buffer) - depth, "%s : %s", key, value);
        PrintToChatAll("%s", buffer);

        if (kv.GotoFirstSubKey())
        {
            DumpKeys(kv, depth + 2);
            kv.GoBack();
        }
        
        if (!kv.GotoNextKey())
            break;
    }
}
// public void ReadConfig()
// {

// 	// if (g_hConfig.JumpToKey("Robot", false))
// 	// {
// 	// 	char robotName[64];
// 	// 	if(g_hConfig.GetString("name", robotName, sizeof(robotName)))
// 	// 	{
// 	// 		PrintToChatAll("Robot Name: %s", robotName);
// 	// 	}
// 	// 	else
// 	// 	{
// 	// 		PrintToChatAll("Unable to retrieve 'name' from 'Robot'");
// 	// 	}

// 	// 	g_hConfig.GoBack();
// 	// }
// 	// else
// 	// {
// 	// 	PrintToChatAll("'Robot' Key does not exist.");
// 	// }

// 	// if (g_hConfig.JumpToKey("Robot", false))
// 	// {
// 	// 	char robotName[64];
// 	// 	g_hConfig.GetString("name", robotName, sizeof(robotName));

// 	// 	PrintToChatAll("Robot Name: %s", robotName);

// 	// 	// ApplyChanges(client, entity, g_hConfig, sClass);  // Uncomment if needed
// 	// 	g_hConfig.GoBack();
// 	// }

// 	// if (g_hConfig.JumpToKey("Robot", false))
// 	// {
// 	// 	char robotName[64];
// 	// 	g_hConfig.GetString("name", robotName, sizeof(robotName));

// 	// 	PrintToChatAll("Robot Name: %s", robotName);
		
// 	// 	// ApplyChanges(client, entity, g_hConfig, sClass);  // Uncomment if needed
// 	// 	g_hConfig.GoBack();
// 	// }
// }

// public void ProcessCfgFile(const char[] fileName)
// {
//     char fullPath[256];
//     char line[1024];
//     Format(fullPath, sizeof(fullPath), "%s/%s", PATH, fileName);
    
//     Handle file = OpenFile(fullPath, "r");
//     if(!file)
//     {
//         LogError("Failed to open file: %s", fullPath);
//         return;
//     }

// 	ArrayList linesList = new ArrayList();
    
//     while(ReadFileLine(file, line, sizeof(line)))
//     {
//         // For now, we just print the lines, but you can process them however you need.
//         // LogMessage("File: %s, Line: %s", fileName, line);
// 		linesList.PushString(line);
		
//     }
//   	CloseHandle(file);
//     // ParseRobotConfig(linesList);
  
// 	delete linesList;
// }

// public void ParseRobotConfig(ArrayList linesList)
// {
// 	RobotDefinition robot
// 	bool isFirstLine = true;
//     for (int i = 0; i < linesList.Length; i++)
//     {
//         char line[2048];
//         linesList.GetString(i, line, sizeof(line));

//         char key[64];
//         char value[256];
//         ExtractKeyAndValue(line, key, sizeof(key), value, sizeof(value));
// 		// PrintToChatAll("Key is %s value is %s",key, value);
//         if(isFirstLine)
//         {
//             strcopy(robot.name, sizeof(robot.name), key);
			
//             isFirstLine = false;
//             continue;
//         }

// 		if (StrEqual(key, "role"))
// 			strcopy(robot.role, sizeof(robot.role), value);
// 		else if (StrEqual(key, "class"))
// 			strcopy(robot.class, sizeof(robot.class), value);
// 		else if (StrEqual(key, "subclass"))
// 			strcopy(robot.subclass, sizeof(robot.subclass), value);
// 		else if (StrEqual(key, "description"))
// 			strcopy(robot.shortDescription, sizeof(robot.shortDescription), value);
// 		else if (StrEqual(key, "tips"))
// 			strcopy(robot.tips, sizeof(robot.tips), value);
// 		else if (StrEqual(key, "on_death"))
// 			strcopy(robot.deathtip, sizeof(robot.deathtip), value);
// 		else if (StrEqual(key, "model"))
// 			strcopy(robot.model, sizeof(robot.model), value);
// 		else if (StrEqual(key, "difficulty"))
// 			robot.difficulty = StringToInt(value);
// 		else if (StrEqual(key, "health"))
// 			robot.health = StringToInt(value);
// 		else if (StrEqual(key, "scale"))
// 			robot.scale = StringToFloat(value);


// 		AddRobot(robot, MakeGDeflectorH, PLUGIN_VERSION);
//     }
// }

// public void ExtractKeyAndValue(const char[] line, char[] key, int keySize, char[] value, int valueSize)
// {
//     int equalsPos = StrContains(line, "\" \"");
//     if (equalsPos == -1)
//     {
// 		PrintToChatAll("Invalid line format: %s", line);
//         // LogError("Invalid line format: %s", line);
//         return;
//     }

//     int lineLen = strlen(line);

//     // Extract the key
//     for (int i = 0; i < equalsPos && i < keySize - 1; i++)
//     {
//         key[i] = line[i];
//     }
//     key[equalsPos] = '\0';

//     // Extract the value
//     int valueStart = equalsPos + 3;  // Skip past " \""
//     int valueEnd = lineLen - 1;      // Exclude the trailing " character
//     int valueLength = valueEnd - valueStart + 1;

//     if (valueLength < 0 || valueLength >= valueSize)
//     {
//         LogError("Value too long or invalid format in line: %s", line);
//         return;
//     }

//     for (int i = 0; i < valueLength; i++)
//     {
//         value[i] = line[valueStart + i];
//     }
//     value[valueLength] = '\0';

//     TrimString(key);
//     TrimString(value);
// }

MakeGDeflectorH(client)
{	
	PrintToChatAll("Robot stuff goes here");
}