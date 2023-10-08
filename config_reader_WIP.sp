// #include <sourcemod>
// #include <berobot_constants>
// #include <berobot>

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>
#include <tf2attributes>

#define PATH "cfg/robots"
#define PLUGIN_VERSION "0.2"

StringMap s_RobotConfigPaths;

KeyValues g_hConfig;

#define MAX_PAINTS 100

char paintNames[MAX_PAINTS][64];
int paintValues1[MAX_PAINTS];
int paintValues2[MAX_PAINTS];
int numPaints = 0;

public void AddPaint(char[] name, int value1)
{
    _InternalAddPaint(name, value1, 0);
}

public void AddPaintTeam(char[] name, int value1, int value2)
{
    _InternalAddPaint(name, value1, value2);
}

public void _InternalAddPaint(char[] name, int value1, int value2)
{
    if (numPaints < MAX_PAINTS)
    {
        PrintToServer("Adding paint: %s", name);
        
        for (int i = 0; i < strlen(name) && i < 64; i++)
        {
            paintNames[numPaints][i] = name[i];
        }
        
        paintValues1[numPaints] = value1;
        paintValues2[numPaints] = value2;
        numPaints++;
    }
    else
    {
        PrintToServer("Error: numPaints exceeds or is equal to MAX_PAINTS. Not copying string.");
    }
}



public void OnPluginStart()
{
    s_RobotConfigPaths = new StringMap();
    char fileName[256];
    Handle dir = OpenDirectory(PATH);
    if(dir == null)
    {
        LogError("Failed to open directory: %s", PATH);
        return;
    }

    //Load paints if there are robots in the folder
    LoadPaints();
    while (ReadDirEntry(dir, fileName, sizeof(fileName)))
    {
        // Only process .cfg files
        if(StrContains(fileName, ".cfg") != -1)
        {

            char fullPath[256];
            Format(fullPath, sizeof(fullPath), "%s/%s", PATH, fileName);

            //Map the robot name to it's cfg path
            KeyValues kv = new KeyValues("Robot");
            kv.ImportFromFile(fullPath);

            char robotName[64];
            if (kv.GetString("name", robotName, sizeof(robotName)))
            {
                s_RobotConfigPaths.SetString(robotName, fullPath, true);
            }

            delete kv;
			LoadConfig(fileName);
            
        }
    }

    CloseHandle(dir);
     //Debug function to print the robot path
     //PrintConfigPathForRobotName("A-Robot");
}

//Debug function to print the robot path
public void PrintConfigPathForRobotName(const char[] robotName)
{
    char configPath[256];
    if (s_RobotConfigPaths.GetString(robotName, configPath, sizeof(configPath)))
    {
        PrintToServer("Robot: %s -> Config Path: %s", robotName, configPath);
    }
    else
    {
        PrintToServer("No config path found for Robot: %s", robotName);
    }
}

public void LoadConfig(char[] fileName)
{
	if (g_hConfig != INVALID_HANDLE)delete g_hConfig;

	g_hConfig = new KeyValues("Robot");
	char fullPath[256];
	Format(fullPath, sizeof(fullPath), "%s/%s", PATH, fileName);
	// PrintToChatAll("Filename %s, fullPath% %s", fileName, fullPath);
	g_hConfig.ImportFromFile(fullPath);
	ReadConfig();
}

public void ReadConfig()
{
	
    char robotName[64];
    if (g_hConfig.GetString("name", robotName, sizeof(robotName)))
    {
        // PrintToChatAll("Robot Name: %s", robotName);

		char role[64], class[9], subclass[32], shortDescription[NAMELENGTH], tips[256];
        char deathtip[256], model[256];
        int difficulty, health, boss_cost;
        float scale, cost;

        // Attempt to fetch each attribute and set it
        g_hConfig.GetString("role", role, sizeof(role));
        g_hConfig.GetString("class", class, sizeof(class));
        g_hConfig.GetString("subclass", subclass, sizeof(subclass));
        g_hConfig.GetString("shortdescription", shortDescription, sizeof(shortDescription));
        g_hConfig.GetString("tips", tips, sizeof(tips));
        g_hConfig.GetString("deathtip", deathtip, sizeof(deathtip));
        g_hConfig.GetString("model", model, sizeof(model));
        
        difficulty = g_hConfig.GetNum("difficulty", difficulty);
        health = g_hConfig.GetNum("health", health);
        scale = g_hConfig.GetFloat("scale", scale);
        cost = g_hConfig.GetFloat("rc_cost", cost);
        boss_cost = g_hConfig.GetNum("boss_cost", boss_cost);

        // Map the attributes to robot's properties
        RobotDefinition robot;
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
        // PrintToChatAll("Health reading from config was %i", health);
        robot.scale = scale;
        // float cost;
        // robot.cost = cost;
        RestrictionsDefinition restrictions = new RestrictionsDefinition();
        
        restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
        restrictions.RobotCoins.PerRobot = cost; 

        if (boss_cost != 0)
        {
        restrictions.TeamCoins = new RobotCoinRestrictionDefinition();
        restrictions.TeamCoins.Overall = boss_cost;
        }
        


        //MAPPING SOUNDS LIKE THIS WORKS
        // char spawn[256], death[256];
        // g_hConfig.GetString("spawn", spawn, sizeof(spawn));
        // g_hConfig.GetString("death", death, sizeof(death));

        // robot.sounds.spawn = spawn;
        // robot.sounds.death = death;

        // Debug logs to verify the fetched sounds
        // PrintToChatAll("ROBOT SPAWN SOUND: %s", robot.sounds.spawn);
        // PrintToChatAll("ROBOT DEATH SOUND: %s", robot.sounds.death);

    // Only continue if there are sounds to be added
    if (g_hConfig.JumpToKey("sounds", false))
    {
        char sound[256];  // Adjust the size based on your expected maximum sound file path.
        
        if (g_hConfig.GetString("spawn", sound, sizeof(sound)))
        {
            robot.sounds.spawn = sound;
            // PrintToChatAll("ROBOT SPAWN SOUND: %s", robot.sounds.spawn);
        }

        if (g_hConfig.GetString("death", sound, sizeof(sound)))
        {
            robot.sounds.death = sound;
            // PrintToChatAll("ROBOT DEATH SOUND: %s", robot.sounds.death);
        }

        if (g_hConfig.GetString("loop", sound, sizeof(sound)))
        {
            robot.sounds.loop = sound;
            // PrintToChatAll("ROBOT LOOP SOUND: %s", robot.sounds.loop);
        }

        if (g_hConfig.GetString("footstep", sound, sizeof(sound)))
        {
            int footstep = StringToInt(sound);
            robot.footstep = footstep;
            // PrintToChatAll("ROBOT LOOP SOUND: %s", robot.sounds.loop);
        }

        if (g_hConfig.GetString("weaponsound", sound, sizeof(sound)))
        {

            int weaponsound = StringToInt(sound);
            robot.weaponsound = weaponsound;   
            // PrintToChatAll("Weaponsound ID was %i", weaponsound);
            if (g_hConfig.GetString("gunfire", sound, sizeof(sound)))
            {
                robot.sounds.gunfire = sound;
                // PrintToChatAll("ROBOT GUNFIRE SOUND: %s", robot.sounds.gunfire);
            }

            if (g_hConfig.GetString("gunspin", sound, sizeof(sound)))
            {
                robot.sounds.gunspin = sound;
                // PrintToChatAll("ROBOT GUNSPIN SOUND: %s", robot.sounds.gunspin);
            }

            if (g_hConfig.GetString("windup", sound, sizeof(sound)))
            {
                robot.sounds.windup = sound;
                // PrintToChatAll("ROBOT WINDUP SOUND: %s", robot.sounds.windup);
            }

            if (g_hConfig.GetString("winddown", sound, sizeof(sound)))
            {
                robot.sounds.winddown = sound;
                // PrintToChatAll("ROBOT WINDDOWN SOUND: %s", robot.sounds.winddown);
            }
        }

        g_hConfig.GoBack();  // Go back to the parent "Robot" key after processing all sounds.
    }
    // else
    // {
    //     PrintToChatAll("No sounds key found for the robot.");
    // }

	    AddRobot(robot, MakeRobot, PLUGIN_VERSION, restrictions);
    }
    // else
    // {
    //     PrintToChatAll("Unable to retrieve 'name' from 'Robot'");
    // }
}
public void OnPluginEnd()
{
    if (s_RobotConfigPaths != INVALID_HANDLE)
    {
        delete s_RobotConfigPaths;
    }
}

MakeRobot(client)
{
    Robot robot;   
    char robotName[NAMELENGTH];
    GetRobot(client, robotName, NAMELENGTH);
    GetRobotDefinition(robotName, robot);
    // PrintToChatAll("Robot name for %N was %s", client, robot.name);

    char configPath[256];
    s_RobotConfigPaths.GetString(robotName, configPath, sizeof(configPath));

    TFClassType iRobot_class = StringToTFClassType(robot.class)
    TF2_SetPlayerClass(client, iRobot_class);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);

	SetModel(client, robot.model);

	RoboSetHealth(client,iRobot_class, robot.health);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", robot.scale);
    UpdatePlayerHitbox(client, robot.scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);

    g_hConfig.DeleteThis();  // Clear any previous data.
    g_hConfig = new KeyValues("Robot");

    if (!g_hConfig.ImportFromFile(configPath))
    {
        PrintToChatAll("Failed to import robot config from path %s for robot name %s", configPath, robotName);
        return;
    }

    // Now, fetch the name from the configuration to verify.
    char configRobotName[NAMELENGTH];
    g_hConfig.GetString("name", configRobotName, sizeof(configRobotName));

    // Verify if the name in the config matches the expected name.
    if (strcmp(robotName, configRobotName) != 0)
    {
        PrintToChatAll("Mismatch! Expected robot name %s but got %s from config.", robotName, configRobotName);
        return;
    }
    // Reading player attributes and setting them.
    if (g_hConfig.JumpToKey("player_attributes"))
    {
        char sSection[64];
        g_hConfig.GetSectionName(sSection, sizeof(sSection));
        if (g_hConfig.GotoFirstSubKey(.keyOnly=false))
        {
            do
            {
              // The section name is directly the attribute name in this format.
                char attributeName[256];
                g_hConfig.GetSectionName(attributeName, sizeof(attributeName));
                // Fetch the value for this attribute.
                float attributeValue = g_hConfig.GetFloat(NULL_STRING); 
                // PrintToChatAll("Attribute %s, value %f", attributeName, attributeValue);
                TF2Attrib_SetByName(client, attributeName, attributeValue);
            }
            while (g_hConfig.GotoNextKey(false))// Iterate through all the attributes            
             g_hConfig.GoBack(); // Go back to the parent "Robot" key after processing all attributes.      
        }
    }
    g_hConfig.GoBack(); 
    // char sSection[64];
    // g_hConfig.GetSectionName(sSection, sizeof(sSection));
    // // PrintToChatAll("Post player attribute Section %s", sSection);
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		MakeEquipment(client);
}

stock MakeEquipment(client)
{
	if (IsValidClient(client))
	{
		//Remove items and hats
		RoboRemoveAllWearables(client);
        RemoveWeaponSlots(client);

    if (g_hConfig.JumpToKey("weapons"))
    {
        
        if (g_hConfig.GotoFirstSubKey())
        {
            do
            {
                // Get the weapon's class name
                char weaponClassName[256];
                g_hConfig.GetSectionName(weaponClassName, sizeof(weaponClassName));

                int itemIndex = g_hConfig.GetNum("itemindex", 0);
                int quality = g_hConfig.GetNum("quality", 0);
                int level = g_hConfig.GetNum("level", 0);
                int slot = g_hConfig.GetNum("slot", 0);
                int paint = g_hConfig.GetNum("paint", 0);
                int remove_attributes = g_hConfig.GetNum("remove_attributes", 0);


                // Create the weapon for the client using the details fetched above.
                int iWeapon = CreateRoboWeapon(client, weaponClassName, itemIndex, quality, level, slot, paint);
                // PrintToChatAll("iWeapon %i", iWeapon);

                //Remove attributes if set to 1
                if(remove_attributes)TF2Attrib_RemoveAll(iWeapon);

                // Now, if the "attributes" key exists, loop through weapon attributes
                if (g_hConfig.JumpToKey("attributes"))
                {
                    //First we need to check if the attributes uses index or string. Preferably string as then we can create and apply attributes at the same time
                    // PrintToChatAll("IN  ATTRIBUTES");
                    if (g_hConfig.GotoFirstSubKey(.keyOnly=false))
                    {
                        // PrintToChatAll("GOT THE FIRST KEY");
                        do
                        {
                            char attributeKey[256];
                            g_hConfig.GetSectionName(attributeKey, sizeof(attributeKey));
                            float attributeValue = g_hConfig.GetFloat(NULL_STRING);

                            // Apply each weapon attribute here.
                            // Note: Assuming you will have a function or mechanism to apply these attributes to the weapon
                            // Example: TF2Attrib_SetByNameForWeapon(client, weaponClassName, attributeKey, attributeValue);
                            // PrintToChatAll("Key: %s, Attribute %f", attributeKey, attributeValue)
                            TF2Attrib_SetByName(iWeapon, attributeKey, attributeValue);
                        } while (g_hConfig.GotoNextKey(false));
                        
                        g_hConfig.GoBack(); // Jump back to the weapon key after processing all attributes
                    }
                    g_hConfig.GoBack(); // Jump back to the "weapons" section after processing the "attributes" key
                }

            } while (g_hConfig.GotoNextKey()); // Iterate through all the weapons

            g_hConfig.GoBack(); // Go back to the parent "Robot" key after processing all weapons.
        }
        g_hConfig.GoBack();
    }
        // char sSection[64];
        // g_hConfig.GetSectionName(sSection, sizeof(sSection));
        // PrintToChatAll("After to remove Weapons Section %s", sSection);
        if (g_hConfig.JumpToKey("cosmetics"))
        {
            if (g_hConfig.GotoFirstSubKey())
            {
                do
                {
                    int itemIndex = g_hConfig.GetNum("itemindex", 0);
                    int level = g_hConfig.GetNum("level", 10);
                    int quality = g_hConfig.GetNum("quality", 6);
                    
                    // Handle paint as a float or string (like "TeamPaint")
                    char paintName[256];
                    g_hConfig.GetString("paint", paintName, sizeof(paintName));

                    int paint, paint2;
                    GetPaintValuesByName(paintName, paint, paint2);

                    float scale = g_hConfig.GetFloat("scale", 1.0);  // Default to 1.0 if not specified
                    float style = g_hConfig.GetFloat("style", -1.0); // Default to -1.0 if not specified

                    // Create the hat for the client using the details fetched above.
                    CreateRoboHat(client, itemIndex, level, quality, paint, paint2, scale, style);

                } while (g_hConfig.GotoNextKey()); // Iterate through all the cosmetics

                g_hConfig.GoBack(); // Go back to the parent "Robot" key after processing all cosmetics.
            }
        }



	}
}

TFClassType StringToTFClassType(const char[] className) {
    if (!className) {
        return TFClass_Unknown;
    }
    
    if (StrEqual(className, "Scout", false)) {
        return TFClass_Scout;
    } else if (StrEqual(className, "Soldier", false)) {
        return TFClass_Soldier;
    } else if (StrEqual(className, "Pyro", false)) {
        return TFClass_Pyro;
    } else if (StrEqual(className, "DemoMan", false) || StrEqual(className, "Demoman", false)) {
        return TFClass_DemoMan;
    } else if (StrEqual(className, "Heavy", false)) {
        return TFClass_Heavy;
    } else if (StrEqual(className, "Engineer", false)) {
        return TFClass_Engineer;
    } else if (StrEqual(className, "Medic", false)) {
        return TFClass_Medic;
    } else if (StrEqual(className, "Sniper", false)) {
        return TFClass_Sniper;
    } else if (StrEqual(className, "Spy", false)) {
        return TFClass_Spy;
    }

    return TFClass_Unknown; // Default to unknown if none of the above matches
}

void RemoveWeaponSlots(int client)
{

    if (g_hConfig.JumpToKey("remove_weapon_slots"))
    {

        if (g_hConfig.GotoFirstSubKey(.keyOnly=false))
        {
            // PrintToChatAll("Got 3");
            do
            {
                // PrintToChatAll("Got 4");
                int slotNumber = g_hConfig.GetNum(NULL_STRING, -1); // Assuming -1 indicates a failure to fetch

                // Check if we have a valid slotNumber and it's within the expected range (0 to 5, for now)
                if (slotNumber >= 0 && slotNumber <= 5) 
                {
                    // PrintToChatAll("Got 5");
                    // Remove the weapon slot
                    // PrintToChatAll("Slotnumber %i", slotNumber);
                    TF2_RemoveWeaponSlot(client, slotNumber);
                }

            } while (g_hConfig.GotoNextKey(false));

            g_hConfig.GoBack();  // Go back to the parent key after processing all weapon slots
        }
    }
    g_hConfig.GoBack();
}

// Initialization or setup function where you load the paints when the plugin starts or when needed
public void LoadPaints()
{
    // Regular paints
    AddPaint("A Color Similar to Slate", 3100495);
    AddPaint("A Deep Commitment to Purple", 8208497);
    AddPaint("A Distinctive Lack of Hue", 1315860);
    AddPaint("A Mann's Mint", 12377523);
    AddPaint("After Eight", 2960676);
    AddPaint("Aged Moustache Grey", 8289918);
    AddPaint("An Extraordinary Abundance of Tinge", 15132390);
    AddPaint("Australium Gold", 15185211);
    AddPaint("Color No. 216-190-216", 14204632);
    AddPaint("Dark Salmon Injustice", 15308410);
    AddPaint("Drably Olive", 8421376);
    AddPaint("Indubitably Green", 7511618);
    AddPaint("Mann Co. Orange", 13595446);
    AddPaint("Muskelmannbraun", 10843461);
    AddPaint("Noble Hatter's Violet", 5322826);
    AddPaint("Peculiarly Drab Tincture", 12955537);
    AddPaint("Pink as Hell", 16738740);
    AddPaint("Radigan Conagher Brown", 6901050);
    AddPaint("The Bitter Taste of Defeat and Lime", 3329330);
    AddPaint("The Color of a Gentlemann's Business Pants", 15787660);
    AddPaint("Ye Olde Rustic Colour", 8154199);
    AddPaint("Zepheniah's Greed", 4345659);
    
    // Team colors
    AddPaintTeam("An Air of Debonair", 6637376, 2636109);
    AddPaintTeam("Balaclavas Are Forever", 3874595, 1581885);
    AddPaintTeam("Cream Spirit", 12807213, 12091445);
    AddPaintTeam("Operator's Overalls", 4732984, 3686984);
    AddPaintTeam("Team Spirit", 12073019, 5801378);
    AddPaintTeam("The Value of Teamwork", 8400928, 2452877);
    AddPaintTeam("Waterlogged Lab Coat", 11049612, 8626083);

}

public void GetPaintValuesByName(const char[] name, int &paint1, int &paint2)
{
    paint1 = 0;  // default to 0
    paint2 = 0;  // default to 0

    for (int i = 0; i < numPaints; i++)
    {
        if (StrEqual(name, paintNames[i]))
        {
            paint1 = paintValues1[i];
            paint2 = paintValues2[i];
            return;
        }
    }
}