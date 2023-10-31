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
#include <tf_custom_attributes>

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
        //PrintToServer("Adding paint: %s", name);
        
        for (int i = 0; i < strlen(name) && i < 64; i++)
        {
            paintNames[numPaints][i] = name[i];
        }
        
        paintValues1[numPaints] = value1;
        paintValues2[numPaints] = value2;
        numPaints++;
    }
    // else
    // {
    //     PrintToServer("Error: numPaints exceeds or is equal to MAX_PAINTS. Not copying string.");
    // }
}



public void OnPluginStart()
{

    RegAdminCmd("sm_reload_robot_configs", Cmd_ReloadRobotConfigs, ADMFLAG_SLAY, "Reload the robot configs");
    Initialize();
    
     //Debug function to print the robot path
     //PrintConfigPathForRobotName("A-Robot");
}

public Action Initialize()
{
    // PrintToChatAll("Initializing");
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

}

public Action Cmd_ReloadRobotConfigs(int client, int argc)
{

    Initialize();
    if(IsValidClient)ReplyToCommand(client, "[SM] Robot configs reloaded successfully!");

    return Plugin_Handled;
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

        char sString[256];
        char processedString[256] = "";
        int iInteger;
        float fFloat;
        RobotDefinition robot;
        robot.name = robotName;
        if (g_hConfig.GetString("class", sString, sizeof(robot.class)))
        {
            
            strcopy(robot.class, sizeof(robot.class), sString);
        }

        // For 'role'
        if (g_hConfig.GetString("role", sString, sizeof(robot.role)))
        {
            strcopy(robot.role, sizeof(robot.role), sString);
        }

        // For 'subclass'
        if (g_hConfig.GetString("subclass", sString, sizeof(robot.subclass)))
        {
            strcopy(robot.subclass, sizeof(robot.subclass), sString);
        }

        // For 'shortdescription'
        if (g_hConfig.GetString("shortdescription", sString, sizeof(robot.shortDescription)))
        {
            strcopy(robot.shortDescription, sizeof(robot.shortDescription), sString);
        }

        // Fetch tips
        if (g_hConfig.GetString("tips", sString, sizeof(sString)))
        {
            processedString = "";
            int j = 0;

            for(int i = 0; sString[i] != '\0' && j < sizeof(processedString) - 1; i++)
            {
                if(sString[i] == '\\' && sString[i+1] == 'n')
                {
                    processedString[j] = '\n'; // Add newline character
                    j++;
                    i++; // Skip the next character which is 'n'
                }
                else
                {
                    processedString[j] = sString[i];
                    j++;
                }
            }

            robot.tips = processedString;
        }

        // Fetch deathtip
        if (g_hConfig.GetString("deathtip", sString, sizeof(sString)))
        {
            processedString = "";
            int j = 0;

            for(int i = 0; sString[i] != '\0' && j < sizeof(processedString) - 1; i++)
            {
                if(sString[i] == '\\' && sString[i+1] == 'n')
                {
                    processedString[j] = '\n'; // Add newline character
                    j++;
                    i++; // Skip the next character which is 'n'
                }
                else
                {
                    processedString[j] = sString[i];
                    j++;
                }
            }
            robot.deathtip = processedString;
        }

        // Fetch model
        if (g_hConfig.GetString("model", sString, sizeof(sString)))
        {
            robot.model = sString;
        }

        // Fetch difficulty
        iInteger = g_hConfig.GetNum("difficulty", iInteger);
        robot.difficulty = iInteger;

       // PrintToChatAll("SetDifficulty for %s to %i", robot.name, iInteger);

        //Could optmize these to be read from the config later, but it doesn't really matter too much I think
        // Fetch health
        iInteger = g_hConfig.GetNum("health", iInteger);
        robot.health = iInteger;
   //     PrintToChatAll("Setting Robot health for %s to %i", robot.name, iInteger);
        // Fetch scale
        if(g_hConfig.GetFloat("scale"))
        {
            fFloat = g_hConfig.GetFloat("scale", fFloat);
        }else
        {
            fFloat = 1.75
        }
        
        robot.scale = fFloat;

        RestrictionsDefinition restrictions = new RestrictionsDefinition();
        bool hasRestrictions = false;
        // Fetch boss_cost
        if (g_hConfig.GetNum("boss_cost"))
        {
            iInteger = g_hConfig.GetNum("boss_cost", iInteger);
            if (restrictions.TeamCoins == null)
            {
                restrictions.TeamCoins = new RobotCoinRestrictionDefinition();
            }
            restrictions.TeamCoins.Overall = iInteger;
            hasRestrictions = true;
        }
        // Fetch cost
        if (g_hConfig.GetFloat("rc_cost"))
        {
            // fFloat = g_hConfig.GetFloat("rc_cost", fFloat);
            if (restrictions.RobotCoins == null)
            {
                restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
            }
            restrictions.RobotCoins.PerRobot = fFloat;
            hasRestrictions = true;
        }



        if (!hasRestrictions)
        {
            delete restrictions;
            restrictions = null;
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
        }else
        {
            robot.footstep = ROBOT_FOOTSTEP_GIANTCOMMON;
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
    RequestFrame(MakeRobotFrame, client);
}

MakeRobotFrame(client)
{
    
    Robot robot;   
    char robotName[NAMELENGTH];
    GetRobot(client, robotName, NAMELENGTH);

    GetRobotDefinition(robotName, robot);
    // PrintToChatAll("===");
    // PrintToChatAll("%N: Robot name: %s", client, robotName);

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


	SetModel(client, robot.model);

	RoboSetHealth(client,iRobot_class, robot.health);
	RoboRemoveAllWearables(client);
    // RemoveWeaponSlots(client);





	SetEntPropFloat(client, Prop_Send, "m_flModelScale", robot.scale);
    UpdatePlayerHitbox(client, robot.scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);

    //g_hConfig.DeleteThis();  // Clear any previous data.
    KeyValues i_hConfig = new KeyValues("Robot");
	// CreateTimer(0.0, Timer_Switch, client);
    // MakeEquipment(client, robot);
    if (!i_hConfig.ImportFromFile(configPath))
    {
        PrintToChatAll("Failed to import robot config from path %s for robot name %s", configPath, robotName);
        return;
    }

    // Now, fetch the name from the configuration to verify.
    char configRobotName[NAMELENGTH];
    i_hConfig.GetString("name", configRobotName, sizeof(configRobotName));
    // PrintToChatAll("%N: Config name: %s", client,configRobotName);
    // Verify if the name in the config matches the expected name.
    if (strcmp(robotName, configRobotName) != 0)
    {
        //PrintToChatAll("Mismatch! Expected robot name %s but got %s from config.", robotName, configRobotName);
        return;
    }

    if (i_hConfig.JumpToKey("remove_weapon_slots"))
    {

        if (i_hConfig.GotoFirstSubKey(.keyOnly=false))
        {
            // PrintToChatAll("Got 3");
            do
            {
                // PrintToChatAll("Got 4");
                int slotNumber = i_hConfig.GetNum(NULL_STRING, -1); // Assuming -1 indicates a failure to fetch

                // Check if we have a valid slotNumber and it's within the expected range (0 to 5, for now)
                if (slotNumber >= 0 && slotNumber <= 5) 
                {
                    // PrintToChatAll("Got 5");
                    // Remove the weapon slot
                    // PrintToChatAll("Slotnumber %i", slotNumber);
                    TF2_RemoveWeaponSlot(client, slotNumber);
                }

            } while (i_hConfig.GotoNextKey(false));

            i_hConfig.GoBack();  // Go back to the parent key after processing all weapon slots
        }
        i_hConfig.GoBack();
    }
    


 if (i_hConfig.JumpToKey("weapons"))
    {
        
        if (i_hConfig.GotoFirstSubKey())
        {
            do
            {
                // Get the weapon's class name
                char weaponClassName[256];
                i_hConfig.GetSectionName(weaponClassName, sizeof(weaponClassName));

                int itemIndex = i_hConfig.GetNum("itemindex", 0);
                
                int quality = i_hConfig.GetNum("quality", 0);

                int level = i_hConfig.GetNum("level", 0);
                
                int slot = i_hConfig.GetNum("slot", 0);
                

                int paint = i_hConfig.GetNum("warpaint_id", 0);
                //Only used for Sandman and Wrap Assasin
                int weaponammo = i_hConfig.GetNum("weaponammo", 0);
                int remove_attributes = i_hConfig.GetNum("remove_attributes", 0);
                
                    int red, green, blue, alpha;
                    bool rgba = false;
                    if (GetRGBA(i_hConfig, red, green, blue, alpha))
                    {
                        // RGBA value successfully fetched and parsed
                        // Now, you can use red, green, blue, and alpha variables as required
                        // For example, store them, print them, or use in some logic
                        //PrintToChatAll("RGBA for %s: %d, %d, %d, %d", weaponClassName, red, green, blue, alpha);
                        rgba = true;
                    }
                    // else
                    // {
                    //     // Handle the error or default the RGBA values if necessary
                    //     // Example: Set them to some default value or print an error message
                    //     PrintToChatAll("Failed to parse RGBA for %s", weaponClassName);
                    // }

                int iWeapon;
            // Check for special weapon ID 1101
                if(itemIndex == 1101)
                {
                    iWeapon = CreateRoboWeaponWithAttributes(client, "tf_weapon_parachute", 1101, 6, 77, true, true, "");
                }
                else
                {
                    // // Create the weapon for the client using the details fetched above.
                    // PrintToChatAll("%N: Creating weapon with %s", client, weaponClassName);
                    iWeapon = CreateRoboWeapon(client, weaponClassName, itemIndex, quality, level, slot, paint);
                }
                //Remove attributes if set to 1
                if(remove_attributes)TF2Attrib_RemoveAll(iWeapon);
                
                //Sets weapon ammo for Sandman and Wrapassasin if value is more than 1
                //PrintToChatAll("WeaponAmmo %i, quality %i", weaponammo, quality);
                if(weaponammo)TF2_SetWeaponAmmo(iWeapon, weaponammo);

                if(rgba)SetEntityRenderColor(iWeapon, red,green,blue,alpha);

                // Now, if the "attributes" key exists, loop through weapon attributes
                if (i_hConfig.JumpToKey("attributes") && IsValidEntity(iWeapon))
                {
                    //First we need to check if the attributes uses index or string. Preferably string as then we can create and apply attributes at the same time
                    // PrintToChatAll("IN  ATTRIBUTES");
                    if (i_hConfig.GotoFirstSubKey(.keyOnly=false))
                    {
                        // PrintToChatAll("GOT THE FIRST KEY");
                        do
                        {
                            char attributeKey[256];
                            i_hConfig.GetSectionName(attributeKey, sizeof(attributeKey));
                            float attributeValue = i_hConfig.GetFloat(NULL_STRING);

                            if (IsStringInteger(attributeKey))
                            {
                                int attributeIndex = StringToInt(attributeKey);
                                // Handle applying attribute by index here
                                TF2Attrib_SetByDefIndex(iWeapon, attributeIndex, attributeValue);
                            }
                            else
                            {
                            // Apply each weapon attribute here.
                            // Note: Assuming you will have a function or mechanism to apply these attributes to the weapon
                            // Example: TF2Attrib_SetByNameForWeapon(client, weaponClassName, attributeKey, attributeValue);
                            TF2Attrib_SetByName(iWeapon, attributeKey, attributeValue);
                            }


                        } while (i_hConfig.GotoNextKey(false));
                        
                        i_hConfig.GoBack(); // Jump back to the weapon key after processing all attributes
                    }
                    if(IsValidEntity(iWeapon))
                    {
                    if (HasEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType"))
                     {
                        RoboCorrectClipSize(iWeapon);
                     }
                    }
                   i_hConfig.GoBack(); // Jump back to the "weapons" section after processing the "attributes" key
                    
                }
                // char sSection[64];
                // i_hConfig.GetSectionName(sSection, sizeof(sSection));
                // PrintToChatAll("After Attributes, heading to custom_attributes Section %s", sSection);
                //Now let's handle the custom attributes
                if (i_hConfig.JumpToKey("custom_attributes_weapon"))
                {
                    //  PrintToChatAll("Inside custom attribute");
                    if (i_hConfig.GotoFirstSubKey(.keyOnly=false))
                    {
                        // PrintToChatAll("Got 1");
                        do
                        {
                            
                            char attributeKey[256], attributeValue[256];

                            i_hConfig.GetSectionName(attributeKey, sizeof(attributeKey));
                            i_hConfig.GetString(NULL_STRING, attributeValue, sizeof(attributeValue));

                            // Apply the custom attribute to the weapon
                            //PrintToChatAll("attributeKey %s, attributeValue %s", attributeKey, attributeValue);
                            TF2CustAttr_SetString(iWeapon, attributeKey, attributeValue);

                        } while (i_hConfig.GotoNextKey(false));
                        
                        i_hConfig.GoBack(); // Jump back to the weapon key after processing all custom attributes
                    }

                    i_hConfig.GoBack(); // Jump back to the "weapons" section after processing the "custom_attributes" key
                }

            } while (i_hConfig.GotoNextKey()); // Iterate through all the weapons

            i_hConfig.GoBack(); // Go back to the parent "Robot" key after processing all weapons.
        }
        i_hConfig.GoBack();
    }
        // char sSection[64];
        // i_hConfig.GetSectionName(sSection, sizeof(sSection));
        // PrintToChatAll("After to remove Weapons Section %s", sSection);
        if (i_hConfig.JumpToKey("cosmetics"))
        {
            if (i_hConfig.GotoFirstSubKey())
            {
                do
                {
                    int itemIndex = i_hConfig.GetNum("itemindex", 0);
                    
                    int level;
                    if(i_hConfig.GetNum("level", 10))
                    {
                        level = i_hConfig.GetNum("level", 10);
                    }else
                    {
                        level = 10
                    }
                    int quality;
                    if (i_hConfig.GetNum("quality", 6))
                    {
                        quality = i_hConfig.GetNum("quality", 6);
                    }else
                    {
                        quality = 6;
                    }
                    
                    
                    // Handle paint as a float or string (like "TeamPaint")
                    char paintName[256];
                    i_hConfig.GetString("paint", paintName, sizeof(paintName));

                    int paint, paint2;
                    GetPaintValuesByName(paintName, paint, paint2);

                    float scale = i_hConfig.GetFloat("scale", 1.0);  // Default to 1.0 if not specified
                    float style = i_hConfig.GetFloat("style", -1.0); // Default to -1.0 if not specified
                    
                    //Specific code for team specific cosmetics
                    int team = i_hConfig.GetNum("create_only_on_team_number", -1)// Default to -1.0 if not specified
                    
                    int iTeam = TF2_GetClientTeam(client);
                    // Create the hat for the client using the details fetched above.

                    // PrintToChatAll("ITEMINDEX: %i, Team was %i, iTeam: %i", itemIndex, team, iTeam);
                    if (team == -1)CreateRoboHat(client, itemIndex, level, quality, paint, paint2, scale, style);
                    if (team == iTeam)CreateRoboHat(client, itemIndex, level, quality, paint, paint2, scale, style);
                    // if (team == )
/* 	TFTeam_Unassigned = 0,
	TFTeam_Spectator = 1,
	TFTeam_Red = 2,
	TFTeam_Blue = 3 */
                } while (i_hConfig.GotoNextKey()); // Iterate through all the cosmetics

                i_hConfig.GoBack(); // Go back to the parent "Robot" key after processing all cosmetics.
            }
            i_hConfig.GoBack();
        }

	








    int bonus_hp = 0;
    if(i_hConfig.GetNum("health_bonus_per_player"))
    {
        bonus_hp = i_hConfig.GetNum("health_bonus_per_player", bonus_hp);
      //  PrintToChatAll("Found bonus HP it was %i", bonus_hp);
        bonus_hp *= GetCurrentHumanCount();
    }

    RoboSetHealth(client, iRobot_class, robot.health + bonus_hp);

    // Reading player attributes and setting them.
    if (i_hConfig.JumpToKey("player_attributes"))
    {
        char sSection[64];
        i_hConfig.GetSectionName(sSection, sizeof(sSection));
        if (i_hConfig.GotoFirstSubKey(.keyOnly=false))
        {
            do
            {
              // The section name is directly the attribute name in this format.
                char attributeName[256];
                i_hConfig.GetSectionName(attributeName, sizeof(attributeName));
                // Fetch the value for this attribute.
                float attributeValue = i_hConfig.GetFloat(NULL_STRING); 

                if (IsStringInteger(attributeName))
                {
                    int attributeIndex = StringToInt(attributeName);
                    // Handle applying attribute by index here
                    TF2Attrib_SetByDefIndex(client, attributeIndex, attributeValue);
                }else
                {
                    // PrintToChatAll("Attribute %s, value %f", attributeName, attributeValue);
                    TF2Attrib_SetByName(client, attributeName, attributeValue);    
                }
                
            }
            while (i_hConfig.GotoNextKey(false))// Iterate through all the attributes            
             i_hConfig.GoBack();
        }
        i_hConfig.GoBack();

    // char sSection[64];
    // i_hConfig.GetSectionName(sSection, sizeof(sSection));
    // PrintToChatAll("Post player attribute Section %s", sSection);
    char attributeKey[256], attributeValue[256];
        //Code for player conditions such as crit_canteens.

    if (i_hConfig.JumpToKey("player_conditions"))
    {
        char sSection[64];
        i_hConfig.GetSectionName(sSection, sizeof(sSection));
        if (i_hConfig.GotoFirstSubKey(.keyOnly=false))
        {
            do
            {
                // The section name is directly the condition ID in this format.
                char conditionIDStr[64];
                i_hConfig.GetSectionName(conditionIDStr, sizeof(conditionIDStr));

                // Convert the condition ID from string to integer.
                int conditionID = StringToInt(conditionIDStr);

                // Fetch the duration for this condition.
                float duration = i_hConfig.GetFloat(NULL_STRING); 

                // Apply the condition with the specified duration.
                if (duration >= 0.0)
                {
                    TF2_AddCondition(client, conditionID, duration);
                }
                else
                {
                    TF2_AddCondition(client, conditionID);
                }

            } while (i_hConfig.GotoNextKey(false)); // Iterate through all the conditions.
            i_hConfig.GoBack();
        }
        i_hConfig.GoBack();
    }

    i_hConfig.GoBack();

        if (i_hConfig.JumpToKey("custom_attributes_player"))
        {
            if (i_hConfig.GotoFirstSubKey(.keyOnly=false))
            {
                // PrintToChatAll("Got 1");
                do
                {
                    // char attributeKey[256], attributeValue[256];

                    i_hConfig.GetSectionName(attributeKey, sizeof(attributeKey));
                    i_hConfig.GetString(NULL_STRING, attributeValue, sizeof(attributeValue));

                    // Apply the custom attribute to the weapon
                    //PrintToChatAll("attributeKey %s, attributeValue %s", attributeKey, attributeValue);
                    TF2CustAttr_SetString(client, attributeKey, attributeValue);

                } while (i_hConfig.GotoNextKey(false));
                
            }

            i_hConfig.GoBack(); // Jump back to the "weapons" section after processing the "custom_attributes" key
        }
    }

    i_hConfig.DeleteThis();
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

// public Action:Timer_Switch(Handle:timer, any:client)
// {
// 	if (IsValidClient(client))
// 		MakeEquipment(client);
// }

// stock MakeEquipment(int client)
// {
// 	if (IsValidClient(client))
// 	{
// 		//Remove items and hats
// 		RoboRemoveAllWearables(client);
//         RemoveWeaponSlots(client);

//     if (g_hConfig.JumpToKey("weapons"))
//     {
        
//         if (g_hConfig.GotoFirstSubKey())
//         {
//             do
//             {
//                 // Get the weapon's class name
//                 char weaponClassName[256];
//                 g_hConfig.GetSectionName(weaponClassName, sizeof(weaponClassName));

//                 int itemIndex = g_hConfig.GetNum("itemindex", 0);
                
//                 int quality = g_hConfig.GetNum("quality", 0);

//                 int level = g_hConfig.GetNum("level", 0);
                
//                 int slot = g_hConfig.GetNum("slot", 0);
                

//                 int paint = g_hConfig.GetNum("paint", 0);
//                 int remove_attributes = g_hConfig.GetNum("remove_attributes", 0);

//                 int iWeapon;
//             // Check for special weapon ID 1101
//                 if(itemIndex == 1101)
//                 {
//                     iWeapon = CreateRoboWeaponWithAttributes(client, "tf_weapon_parachute", 1101, 6, 77, true, true, "");
//                 }
//                 else
//                 {
//                     // // Create the weapon for the client using the details fetched above.
//                     PrintToChatAll("%N: Creating weapon with %s", client, weaponClassName);
//                     iWeapon = CreateRoboWeapon(client, weaponClassName, itemIndex, quality, level, slot, paint);
//                 }
//                 //Remove attributes if set to 1
//                if(remove_attributes)TF2Attrib_RemoveAll(iWeapon);

//                 // Now, if the "attributes" key exists, loop through weapon attributes
//                 if (g_hConfig.JumpToKey("attributes") && IsValidEntity(iWeapon))
//                 {
//                     //First we need to check if the attributes uses index or string. Preferably string as then we can create and apply attributes at the same time
//                     // PrintToChatAll("IN  ATTRIBUTES");
//                     if (g_hConfig.GotoFirstSubKey(.keyOnly=false))
//                     {
//                         // PrintToChatAll("GOT THE FIRST KEY");
//                         do
//                         {
//                             char attributeKey[256];
//                             g_hConfig.GetSectionName(attributeKey, sizeof(attributeKey));
//                             float attributeValue = g_hConfig.GetFloat(NULL_STRING);

//                             if (IsStringInteger(attributeKey))
//                             {
//                                 int attributeIndex = StringToInt(attributeKey);
//                                 // Handle applying attribute by index here
//                                 TF2Attrib_SetByDefIndex(iWeapon, attributeIndex, attributeValue);
//                             }
//                             else
//                             {
//                             // Apply each weapon attribute here.
//                             // Note: Assuming you will have a function or mechanism to apply these attributes to the weapon
//                             // Example: TF2Attrib_SetByNameForWeapon(client, weaponClassName, attributeKey, attributeValue);
//                             TF2Attrib_SetByName(iWeapon, attributeKey, attributeValue);
//                             }


//                         } while (g_hConfig.GotoNextKey(false));
                        
//                         g_hConfig.GoBack(); // Jump back to the weapon key after processing all attributes
//                     }

//                    g_hConfig.GoBack(); // Jump back to the "weapons" section after processing the "attributes" key
                    
//                 }
//                 // char sSection[64];
//                 // g_hConfig.GetSectionName(sSection, sizeof(sSection));
//                 // PrintToChatAll("After Attributes, heading to custom_attributes Section %s", sSection);
//                 //Now let's handle the custom attributes
//                 if (g_hConfig.JumpToKey("custom_attributes_weapon"))
//                 {
//                     //  PrintToChatAll("Inside custom attribute");
//                     if (g_hConfig.GotoFirstSubKey(.keyOnly=false))
//                     {
//                         // PrintToChatAll("Got 1");
//                         do
//                         {
                            
//                             char attributeKey[256], attributeValue[256];

//                             g_hConfig.GetSectionName(attributeKey, sizeof(attributeKey));
//                             g_hConfig.GetString(NULL_STRING, attributeValue, sizeof(attributeValue));

//                             // Apply the custom attribute to the weapon
//                             //PrintToChatAll("attributeKey %s, attributeValue %s", attributeKey, attributeValue);
//                             TF2CustAttr_SetString(iWeapon, attributeKey, attributeValue);

//                         } while (g_hConfig.GotoNextKey(false));
                        
//                         g_hConfig.GoBack(); // Jump back to the weapon key after processing all custom attributes
//                     }

//                     g_hConfig.GoBack(); // Jump back to the "weapons" section after processing the "custom_attributes" key
//                 }

//             } while (g_hConfig.GotoNextKey()); // Iterate through all the weapons

//             g_hConfig.GoBack(); // Go back to the parent "Robot" key after processing all weapons.
//         }
//         g_hConfig.GoBack();
//     }
//         // char sSection[64];
//         // g_hConfig.GetSectionName(sSection, sizeof(sSection));
//         // PrintToChatAll("After to remove Weapons Section %s", sSection);
//         if (g_hConfig.JumpToKey("cosmetics"))
//         {
//             if (g_hConfig.GotoFirstSubKey())
//             {
//                 do
//                 {
//                     int itemIndex = g_hConfig.GetNum("itemindex", 0);
                    
//                     int level;
//                     if(g_hConfig.GetNum("level", 10))
//                     {
//                         level = g_hConfig.GetNum("level", 10);
//                     }else
//                     {
//                         level = 10
//                     }
//                     int quality;
//                     if (g_hConfig.GetNum("quality", 6))
//                     {
//                         quality = g_hConfig.GetNum("quality", 6);
//                     }else
//                     {
//                         quality = 6;
//                     }
                    
                    
//                     // Handle paint as a float or string (like "TeamPaint")
//                     char paintName[256];
//                     g_hConfig.GetString("paint", paintName, sizeof(paintName));

//                     int paint, paint2;
//                     GetPaintValuesByName(paintName, paint, paint2);

//                     float scale = g_hConfig.GetFloat("scale", 1.0);  // Default to 1.0 if not specified
//                     float style = g_hConfig.GetFloat("style", -1.0); // Default to -1.0 if not specified

//                     // Create the hat for the client using the details fetched above.
//                     CreateRoboHat(client, itemIndex, level, quality, paint, paint2, scale, style);

//                 } while (g_hConfig.GotoNextKey()); // Iterate through all the cosmetics

//                 g_hConfig.GoBack(); // Go back to the parent "Robot" key after processing all cosmetics.
//             }
//         }

// 	}
// }

bool IsStringInteger(const char[] string)
{
    for(int i = 0; string[i] != '\0'; i++)
    {
        if (string[i] < '0' || string[i] > '9')
            return false;
    }
    return true;
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

// void RemoveWeaponSlots(int client)
// {

//     if (g_hConfig.JumpToKey("remove_weapon_slots"))
//     {

//         if (g_hConfig.GotoFirstSubKey(.keyOnly=false))
//         {
//             // PrintToChatAll("Got 3");
//             do
//             {
//                 // PrintToChatAll("Got 4");
//                 int slotNumber = g_hConfig.GetNum(NULL_STRING, -1); // Assuming -1 indicates a failure to fetch

//                 // Check if we have a valid slotNumber and it's within the expected range (0 to 5, for now)
//                 if (slotNumber >= 0 && slotNumber <= 5) 
//                 {
//                     // PrintToChatAll("Got 5");
//                     // Remove the weapon slot
//                     // PrintToChatAll("Slotnumber %i", slotNumber);
//                     TF2_RemoveWeaponSlot(client, slotNumber);
//                 }

//             } while (g_hConfig.GotoNextKey(false));

//             g_hConfig.GoBack();  // Go back to the parent key after processing all weapon slots
//         }
//     }
//     g_hConfig.GoBack();
// }

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

stock void TF2_SetWeaponAmmo(int weapon, int amount) {
	int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
	
	if (client > 0 && client <= MaxClients && ammoType != -1) {
		SetEntProp(client, Prop_Send, "m_iAmmo", amount, 4, ammoType);
	}
}

#include <string>

stock bool GetRGBA(KeyValues i_hConfig, int &red, int &green, int &blue, int &alpha)
{
    char rgbaString[32];
    if (!i_hConfig.GetString("RGBA", rgbaString, sizeof(rgbaString)))
    {
        return false; // key "RGBA" not found or its value couldn't be fetched
    }
    
    char buffer[4][32];  // Adjusted this line for correct SourcePawn syntax
    int numComponents = ExplodeString(rgbaString, ",", buffer, 4, 32);
    
    if (numComponents != 4)
    {
        return false; // RGBA string doesn't have four components
    }
    
    red = StringToInt(buffer[0]);
    green = StringToInt(buffer[1]);
    blue = StringToInt(buffer[2]);
    alpha = StringToInt(buffer[3]);
    
    return true;
}