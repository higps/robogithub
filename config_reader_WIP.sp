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
#define PLUGIN_VERSION "0.01"

StringMap s_RobotConfigPaths;

KeyValues g_hConfig;
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
int g_config_count = 0;
public void ReadConfig()
{
	
    char robotName[64];
    if (g_hConfig.GetString("name", robotName, sizeof(robotName)))
    {
        // PrintToChatAll("Robot Name: %s", robotName);

		char role[64], class[9], subclass[32], shortDescription[NAMELENGTH], tips[256];
        char deathtip[256], model[256];
        int difficulty, health;
        float scale;

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

        char spawn[256], death[256];
        g_hConfig.GetString("spawn", spawn, sizeof(spawn));
        g_hConfig.GetString("death", death, sizeof(death));

        robot.sounds.spawn = spawn;
        robot.sounds.death = death;

        // Debug logs to verify the fetched sounds
        // PrintToChatAll("ROBOT SPAWN SOUND: %s", robot.sounds.spawn);
        // PrintToChatAll("ROBOT DEATH SOUND: %s", robot.sounds.death);

    // Only continue if there are sounds to be added
    // if (g_hConfig.JumpToKey("sounds", false))
    // {
    //     char sound[256] = "";  // Adjust the size based on your expected maximum sound file path.
        
    //     if (g_hConfig.GetString("spawn", sound, sizeof(sound)))
    //     {
    //         robot.sounds.spawn = sound;
    //         PrintToChatAll("ROBOT SPAWN SOUND: %s", robot.sounds.spawn);
    //     }

    //     if (g_hConfig.GetString("death", sound, sizeof(sound)))
    //     {
    //         robot.sounds.death = sound;
    //         PrintToChatAll("ROBOT DEATH SOUND: %s", robot.sounds.death);
    //     }

    //     if (g_hConfig.GetString("loop", sound, sizeof(sound)))
    //     {
    //         robot.sounds.loop = sound;
    //         // PrintToChatAll("ROBOT LOOP SOUND: %s", robot.sounds.loop);
    //     }

    //     if (g_hConfig.GetString("gunfire", sound, sizeof(sound)))
    //     {
    //         robot.sounds.gunfire = sound;
    //         // PrintToChatAll("ROBOT GUNFIRE SOUND: %s", robot.sounds.gunfire);
    //     }

    //     if (g_hConfig.GetString("gunspin", sound, sizeof(sound)))
    //     {
    //         robot.sounds.gunspin = sound;
    //         // PrintToChatAll("ROBOT GUNSPIN SOUND: %s", robot.sounds.gunspin);
    //     }

    //     if (g_hConfig.GetString("windup", sound, sizeof(sound)))
    //     {
    //         robot.sounds.windup = sound;
    //         // PrintToChatAll("ROBOT WINDUP SOUND: %s", robot.sounds.windup);
    //     }

    //     if (g_hConfig.GetString("winddown", sound, sizeof(sound)))
    //     {
    //         robot.sounds.winddown = sound;
    //         // PrintToChatAll("ROBOT WINDDOWN SOUND: %s", robot.sounds.winddown);
    //     }

        g_hConfig.GoBack();  // Go back to the parent "Robot" key after processing all sounds.
    // }
    // else
    // {
    //     PrintToChatAll("No sounds key found for the robot.");
    // }

	    AddRobot(robot, MakeRobot, PLUGIN_VERSION);
    }
    else
    {
        PrintToChatAll("Unable to retrieve 'name' from 'Robot'");
    }
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
    PrintToChatAll("CONFIG PATH %s", configPath);
    // PrintToChatAll("SPAWNED ROBOT SPAWN SOUND: %s", robot.sounds.spawn);
    // PrintToChatAll("SPAWNED ROBOT DEATH SOUND: %s", robot.sounds.death);

    // PrintToChatAll("Class was %s", robot.class);
    // PrintToChatAll("ROBOT LOOP SOUND: %s", robot.sounds.loop);
    // PrintToChatAll("ROBOT GUNFIRE SOUND: %s", robot.sounds.gunfire);
    // PrintToChatAll("ROBOT GUNSPIN SOUND: %s", robot.sounds.gunspin);
    // PrintToChatAll("ROBOT WINDUP SOUND: %s", robot.sounds.windup);
    // PrintToChatAll("ROBOT WINDDOWN SOUND: %s", robot.sounds.winddown);


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

    // PrintToChatAll("Robot health was %i or %s", robot.health, robot.health);
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

// 	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
// 	TF2Attrib_SetByName(client, "damage force reduction", 0.1);
// 	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.0);
	
// 	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
// 	TF2Attrib_SetByName(client, "ammo regen", 100.0);
// 	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
// 	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	

   

// //	float spreadpenalty = scale * spreadmodifier;
// 	PrintHintText(client , ROBOT_TIPS);

//Reads the player attributes and adds them until there's nothing left
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
    char sSection[64];
    g_hConfig.GetSectionName(sSection, sizeof(sSection));
    PrintToChatAll("Post player attribute Section %s", sSection);
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

                // Create the weapon for the client using the details fetched above.
                int iWeapon = CreateRoboWeapon(client, weaponClassName, itemIndex, quality, level, slot, paint);
                
                // Now, if the "attributes" key exists, loop through weapon attributes
                if (g_hConfig.JumpToKey("attributes"))
                {
                    if (g_hConfig.GotoFirstSubKey())
                    {
                        do
                        {
                            char attributeKey[256];
                            g_hConfig.GetSectionName(attributeKey, sizeof(attributeKey));
                            float attributeValue = g_hConfig.GetFloat(NULL_STRING);

                            // Apply each weapon attribute here.
                            // Note: Assuming you will have a function or mechanism to apply these attributes to the weapon
                            // Example: TF2Attrib_SetByNameForWeapon(client, weaponClassName, attributeKey, attributeValue);
                            TF2Attrib_SetByName(iWeapon, attributeKey, attributeValue);
                        } while (g_hConfig.GotoNextKey(false));
                        
                        g_hConfig.GoBack(); // Jump back to the weapon key after processing all attributes
                    }
                    g_hConfig.GoBack(); // Jump back to the "weapons" section after processing the "attributes" key
                }

            } while (g_hConfig.GotoNextKey()); // Iterate through all the weapons

            g_hConfig.GoBack(); // Go back to the parent "Robot" key after processing all weapons.
        }
    }


		//TF2_RemoveAllWearables(client);
		// TF2_RemoveWeaponSlot(client, 0);
		// TF2_RemoveWeaponSlot(client, 1);
		// TF2_RemoveWeaponSlot(client, 2);

		//Cosmetic code
		// TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		// float TeamPaint = 0.0;

		// if (iTeam == TFTeam_Blue){
		// 	TeamPaint = 5801378.0;
			
		// }
		// if (iTeam == TFTeam_Red){
			
		// 	TeamPaint = 12073019.0;
		// }

		// CreateRoboHat(client, ROTATIONSENSATION, 10, 6, TeamPaint, 0.75, -1.0);//Rotation sensation
		// CreateRoboHat(client, SUMMERSHADES, 10, 6, 1315860.0, 0.75, -1.0);//Summer shades
		// CreateRoboHat(client, WEIGHTROOMWARMER, 10, 6, 0.0, 1.0, -1.0);//Weightroom warmer

		// CreateRoboWeapon(client, "tf_weapon_minigun", 850, 6, 1, 0, 0);
		


		// int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		// if(IsValidEntity(Weapon1))
		// {
		// 	TF2Attrib_RemoveAll(Weapon1);
		// 	TF2Attrib_SetByName(Weapon1, "attack projectiles", 1.0);
		// 	TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
		// 	TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
		// 	TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);
			
			
		// }
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
       char sSection[64];
    g_hConfig.GetSectionName(sSection, sizeof(sSection));
    PrintToChatAll("Prior to remove Weapons Section %s", sSection);
    PrintToChatAll("Got 1");
    if (g_hConfig.JumpToKey("remove_weapon_slots"))
    {
        PrintToChatAll("Got 2");
        if (g_hConfig.GotoFirstSubKey(.keyOnly=false))
        {
            PrintToChatAll("Got 3");
            do
            {
                PrintToChatAll("Got 4");
                int slotNumber = g_hConfig.GetNum(NULL_STRING, -1); // Assuming -1 indicates a failure to fetch

                // Check if we have a valid slotNumber and it's within the expected range (0 to 5, for now)
                if (slotNumber >= 0 && slotNumber <= 5) 
                {
                    PrintToChatAll("Got 5");
                    // Remove the weapon slot
                    PrintToChatAll("Slotnumber %i", slotNumber);
                    TF2_RemoveWeaponSlot(client, slotNumber);
                }

            } while (g_hConfig.GotoNextKey(false));

            g_hConfig.GoBack();  // Go back to the parent key after processing all weapon slots
        }
    }
    g_hConfig.GoBack();
}