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
	CreateNative("CreateWeapon", Native_CreateWeapon);
	
	return APLRes_Success;
}

public any Native_EquipWearable(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int item = GetNativeCell(2);
	SDKCall(g_hEquipWearable, client, item);
}

public bool Native_CreateWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot)
{
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

public any Native_CreateHat(int client, int itemindex, int level, int quality, float paint, float scale)
{
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
		TF2Attrib_SetByDefIndex(hat, 142, paint);
		TF2Attrib_SetByDefIndex(hat, 261, paint);
	}
	
	if (scale != 0.0){
	SetEntData(hat, FindSendPropInfo(entclass, "m_flModelScale"), scale);
	}

	DispatchSpawn(hat);
	EquipWearable(client, hat);
	return true;
}

stock void RemoveAllWearables(int client)
{
	int edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
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