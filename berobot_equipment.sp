#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2utils>
#include <tf2items>
#include <tf2>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo =
{
	name = "berobot_equipment",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

Handle g_hEquipWearable;

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
	SMLogTag(SML_INFO, "berobot_equipment started at %i", GetTime());

	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamdata
	
	if (!hTF2)
	SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	if (!g_hEquipWearable)
	SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("EquipWearable", Native_EquipWearable);
	CreateNative("CreateRoboWeapon", Native_CreateRoboWeapon);
	CreateNative("CreateRoboWeaponWithAttributes", Native_CreateRoboWeaponWithAttributes);
	CreateNative("CreateRoboHat", Native_CreateRoboHat);
	CreateNative("RoboRemoveAllWearables", Native_RoboRemoveAllWearables);
	CreateNative("RoboCorrectClipSize", Native_RoboCorrectClipSize);
	
	return APLRes_Success;
}

public any Native_EquipWearable(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int item = GetNativeCell(2);
	SDKCall(g_hEquipWearable, client, item);
	return Plugin_Continue;
}

// public any Native_CreateRoboWeapon(Handle plugin, int numParams)
// {
// 	int client = GetNativeCell(1);
// 	char classname[64];
// 	GetNativeString(2, classname, sizeof(classname));
// 	int itemindex = GetNativeCell(3);
// 	int quality = GetNativeCell(4);
// 	int level = GetNativeCell(5);
// 	int slot = GetNativeCell(6);
// 	int paint = GetNativeCell(7);
// }
public any Native_CreateRoboWeaponWithAttributes(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char name[64];
	GetNativeString(2, name, sizeof(name));
	int index = GetNativeCell(3);
	int quality = GetNativeCell(5);
	int level = GetNativeCell(4);
	bool visible = GetNativeCell(6);
	bool preserve = GetNativeCell(7);
	char attribute[NAMELENGTH];
	GetNativeString(8, attribute, sizeof(attribute));
	// const char[] attribute = GetNativeCell(8);

    if (client > MaxClients || client == 0 || !IsClientInGame(client))
    {
        LogMessage("Passed client reference is invalid! Make sure you are passing through a client that is valid and in-game!");
        return -1;
    }

    if (StrEqual(name, "saxxy", false)) // if "saxxy" is specified as the name, replace with appropiate name
    {
        switch (TF2_GetPlayerClass(client))
        {
            case TFClass_Scout: ReplaceString(name, 64, "saxxy", "tf_weapon_bat", false);
            case TFClass_Soldier: ReplaceString(name, 64, "saxxy", "tf_weapon_shovel", false);
            case TFClass_Pyro: ReplaceString(name, 64, "saxxy", "tf_weapon_fireaxe", false);
            case TFClass_DemoMan: ReplaceString(name, 64, "saxxy", "tf_weapon_bottle", false);
            case TFClass_Heavy: ReplaceString(name, 64, "saxxy", "tf_weapon_fists", false);
            case TFClass_Engineer: ReplaceString(name, 64, "saxxy", "tf_weapon_wrench", false);
            case TFClass_Medic: ReplaceString(name, 64, "saxxy", "tf_weapon_bonesaw", false);
            case TFClass_Sniper: ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
            case TFClass_Spy: ReplaceString(name, 64, "saxxy", "tf_weapon_knife", false);
        }
    }

    // tf_weapon_shotgun isn't an actual internal name for any weapons, so replace with the appropriate class appended
    if (StrEqual(name, "tf_weapon_shotgun", false)) 
    {
        switch (TF2_GetPlayerClass(client))
        {
            case TFClass_Soldier:    ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
            case TFClass_Pyro:    ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
            case TFClass_Heavy:    ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
            case TFClass_Engineer:    ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
        }
    }

    // Spawn the actual weapon and apply properties
    Handle weapon = TF2Items_CreateItem((preserve ? PRESERVE_ATTRIBUTES : OVERRIDE_ALL));
    TF2Items_SetClassname(weapon, name);
    TF2Items_SetItemIndex(weapon, index);
    TF2Items_SetLevel(weapon, level);
    TF2Items_SetQuality(weapon, quality);

    // Attribute processing
    char attributes[32][32];
    int count = ExplodeString(attribute, ";", attributes, 32, 32); // Find all attributes separated by semicolon
    if (count%2!=0) // make sure we don't have any extra entries, each attribute should have a value, so if we have any extra entries then an attribute is missing a value
    {
        count--;
    }

    // If we have any actual attributes, let's set them here
    if (count > 0)
    {
        TF2Items_SetNumAttributes(weapon, count/2);
        int i2 = 0;
        for (int i = 0; i < count; i += 2)
        {
            int attrib = StringToInt(attributes[i]);
            if (attrib == 0)
            {
                LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
                return -1;
            }
            TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
            i2++;
        }
    }
    else
    {
        TF2Items_SetNumAttributes(weapon, 0);
    }

    if (weapon == INVALID_HANDLE)
    {
        LogMessage("Error: Invalid weapon spawned. client = %d name = %s idx = %d attr = %s", client, name, index/* , attribute */);
        return -1;
    }

    int wep = TF2Items_GiveNamedItem(client, weapon);
    delete weapon;

    // Allows weapon to be seen
    if (visible)
        SetEntProp(wep, Prop_Send, "m_bValidatedAttachedEntity", 1);

    EquipPlayerWeapon(client, wep);

    return wep;
}

public any Native_CreateRoboWeapon(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char classname[64];
	GetNativeString(2, classname, sizeof(classname));
	int itemindex = GetNativeCell(3);
	int quality = GetNativeCell(4);
	int level = GetNativeCell(5);
	int slot = GetNativeCell(6);
	int paint = GetNativeCell(7);

	TF2_RemoveWeaponSlot(client, slot);
	
	int weapon = CreateEntityByName(classname);
	

	if (!IsValidEntity(weapon) && !IsAnyRobot(client))
	{
		return -1;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1); 
	
	if (level > 0)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomInt(1,99));
	}

	if (quality > 0)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);
	}	
	DispatchSpawn(weapon);
	switch (itemindex)
    {
    case 25, 26:
        {
            DispatchSpawn(weapon);
            EquipPlayerWeapon(client, weapon); 

            return weapon;             
        }
    case 735, 736, 810, 933, 1080, 1102: //sapper
        {
            SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
            SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
            SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
            SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
            SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
            SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
        }    
    case 998:
        {
            SetEntProp(weapon, Prop_Send, "m_nChargeResistType", GetRandomInt(0,2));
        }
    }


	if(quality == 9)
	{
		TF2Attrib_SetByName(weapon, "is australium item", 1.0);
		TF2Attrib_SetByName(weapon, "item style override", 1.0);
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
	}
	if (paint > 0)
	{
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	}

	//Check if wearable, dispatch it.
	if (itemindex == 405 || itemindex == 608 || itemindex == 1101 || itemindex == 133 || itemindex == 444 || itemindex == 57 || itemindex == 231 || itemindex == 642 || itemindex == 131 || itemindex == 406 || itemindex == 1099 || itemindex == 1144)
	{
		DispatchSpawn(weapon);
		EquipWearable(client, weapon);
	}
	else
	{
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon);
	}

	// if (StrContains(entclass, "tf_wearable", false) !=-1)
	// {
	// 	PrintToChatAll("WAS WEARABLE");
	// }else
	// {
	// 	PrintToChatAll("NOT WEARABLE");
	// }

	return weapon;
}

public any Native_CreateRoboHat(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int itemindex = GetNativeCell(2);
	int level = GetNativeCell(3);
	int quality = GetNativeCell(4);
	int paint = GetNativeCell(5);
	int paint2 = GetNativeCell(6);
	float scale = GetNativeCell(7);
	float style = GetNativeCell(8);


	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);  	

	//Team colored paints have 2 values, if the first paint has no value we don't do anything
	if (paint != 0){
		TF2Attrib_SetByDefIndex(hat, 142, float(paint));	
	}

	if (paint2 != 0){
	TF2Attrib_SetByDefIndex(hat, 261, float(paint2));
	}else{
		// If paint2 is 0 (doesn't exist), then set paint to attribute 261 as well
		TF2Attrib_SetByDefIndex(hat, 261, float(paint));
	}
	
	if (scale != 0.0){
	SetEntData(hat, FindSendPropInfo(entclass, "m_flModelScale"), scale);
	}

	if (style != -1.0){
		TF2Attrib_SetByDefIndex(hat, 542, style);
	}

	DispatchSpawn(hat);
	EquipWearable(client, hat);
	return true;
}

public any Native_RoboRemoveAllWearables(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
	return Plugin_Continue;
}

public any Native_RoboCorrectClipSize(Handle plugin, int numParams)
{
		int item = GetNativeCell(1);
		int ammoType = GetEntProp(item, Prop_Send, "m_iPrimaryAmmoType");
		if (ammoType != -1) {
			// PrintToChatAll("Max clip: %i", TF2Util_GetWeaponMaxClip(item));
			SetEntProp(item, Prop_Send, "m_iClip1", TF2Util_GetWeaponMaxClip(item));
			return true;
		}
		return false;
}
