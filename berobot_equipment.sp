#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf2_stocks>
#include <tf2attributes>

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
    // SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
	// SMLogTag(SML_INFO, "berobot_equipment started at %i", GetTime());

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
	CreateNative("CreateRoboHat", Native_CreateRoboHat);
	CreateNative("RoboRemoveAllWearables", Native_RoboRemoveAllWearables);
	
	return APLRes_Success;
}

public any Native_EquipWearable(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int item = GetNativeCell(2);
	SDKCall(g_hEquipWearable, client, item);
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
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1); 
	
	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomInt(1,99));
	}

	switch (itemindex)
    {
    case 25, 26:
        {
            DispatchSpawn(weapon);
            EquipPlayerWeapon(client, weapon); 

            return true;             
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
	//if (paint)
	//{
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	//}

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


	return true;
}

public any Native_CreateRoboHat(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int itemindex = GetNativeCell(2);
	int level = GetNativeCell(3);
	int quality = GetNativeCell(4);
	float paint = GetNativeCell(5);
	float scale = GetNativeCell(6);
	float style = GetNativeCell(7);


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

	if (paint != 0.0){
		TF2Attrib_SetByDefIndex(hat, 142, view_as<float>(paint));
		TF2Attrib_SetByDefIndex(hat, 261, view_as<float>(paint));
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
}

// - Regular paints -
//set item tint RGB
// A Color Similar to Slate					3100495
// A Deep Commitment to Purple					8208497
// A Distinctive Lack of Hue					1315860
// A Mann's Mint								12377523
// After Eight									2960676
// Aged Moustache Grey							8289918
// An Extraordinary Abundance of Tinge			15132390
// Australium Gold								15185211	
// Color No. 216-190-216						14204632
// Dark Salmon Injustice						15308410
// Drably Olive								8421376
// Indubitably Green							7511618
// Mann Co. Orange								13595446
// Muskelmannbraun								10843461
// Noble Hatter's Violet						5322826
// Peculiarly Drab Tincture					12955537
// Pink as Hell								16738740
// Radigan Conagher Brown						6901050
// The Bitter Taste of Defeat and Lime			3329330
// The Color of a Gentlemann's Business Pants	15787660
// Ye Olde Rustic Colour						8154199
// Zepheniah's Greed							4345659

// - Team colors -

// An Air of Debonair:
// set item tint RGB : 6637376
// set item tint RGB 2 : 2636109

// Balaclavas Are Forever
// set item tint RGB : 3874595
// set item tint RGB 2 : 1581885

// Cream Spirit
// set item tint RGB : 12807213
// set item tint RGB 2 : 12091445

// Operator's Overalls
// set item tint RGB : 4732984
// set item tint RGB 2 : 3686984

// Team Spirit
// set item tint RGB : 12073019
// set item tint RGB 2 : 5801378

// The Value of Teamwork
// set item tint RGB : 8400928
// set item tint RGB 2 : 2452877

// Waterlogged Lab Coat
// set item tint RGB : 11049612
// set item tint RGB 2 : 8626083