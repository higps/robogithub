


#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <berobot_constants>
#include <berobot>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define DEMO_ARMS "models/bots/weapons/c_models/c_bot_demo_arms.mdl"
#define ENGI_ARMS "models/bots/weapons/c_models/c_bot_engineer_arms.mdl"
#define ENGI_GUNSLINGER_ARMS "models/bots/weapons/c_models/c_bot_engineer_gunslinger.mdl"
#define HEAVY_ARMS "models/bots/weapons/c_models/c_bot_heavy_arms.mdl"
#define MEDIC_ARMS "models/bots/weapons/c_models/c_bot_medic_arms.mdl"
#define PYRO_ARMS "models/bots/weapons/c_models/c_bot_pyro_arms.mdl"
#define SCOUT_ARMS "models/bots/weapons/c_models/c_bot_scout_arms.mdl"
#define SNIPER_ARMS "models/bots/weapons/c_models/c_bot_sniper_arms.mdl"
#define SOLDIER_ARMS "models/bots/weapons/c_models/c_bot_soldier_arms.mdl"
#define SPY_ARMS "models/bots/weapons/c_models/c_bot_spy_arms.mdl"

// #define TEST "mm/models/bots/weapons/c_models/c_bot_spy_arms.mdl"

char g_ArmsModels[10][] = {
    "",                         // 0 - Unknown (TFClass_Unknown)
    SCOUT_ARMS,                 // 1 - TFClass_Scout
    SNIPER_ARMS,                // 2 - TFClass_Sniper
    SOLDIER_ARMS,               // 3 - TFClass_Soldier
    DEMO_ARMS,                  // 4 - TFClass_DemoMan
    MEDIC_ARMS,                 // 5 - TFClass_Medic
    HEAVY_ARMS,                 // 6 - TFClass_Heavy
    PYRO_ARMS,                  // 7 - TFClass_Pyro
    SPY_ARMS,                   // 8 - TFClass_Spy
    ENGI_ARMS                   // 9 - TFClass_Engineer
};

public Plugin myinfo = {
	name = "MM Arm",
	author = "Sandy, Heavy Is GPS | Bmod.TF",
	description = "MM Robot Arm Giver, based off of The FF2R sub-plugin allow bosses to give custom arms",
	version = "1.0.0",
	url = ""
};

bool g_b_robot_hands = false;
public void OnMapStart()
{
	g_b_robot_hands = false;
	// PrintToChatAll("PLUGIN!");
		for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}

    // Check if the current map is in the list
    // char mapName[PLATFORM_MAX_PATH];
    // GetCurrentMap(mapName, sizeof(mapName));

    // int pos = StrContains(mapName, ".ugc");
    // if (pos != -1)
    // {
    //     char workshopID[32];
    //     strcopy(workshopID, sizeof(workshopID), mapName[pos + 4]); // everything after ".ugc"
    //     PrintToServer("Workshop map detected! ID: %s", workshopID);
	// 	g_b_robot_hands = true;
    // }
    // else
    // {
    //     PrintToServer("Map %s is not a workshop map.", mapName);
	// 	g_b_robot_hands = false;
    // }
	    // Whitelisted maps (normal + workshop)
    char whitelist[][] = 
    {
        //Test
        "workshop/2649883639",
        //Calamity
        "workshop/2897811023",
        //Upward
        "workshop/3156008215",
        "test_mm_assets"
    };

    char mapName[PLATFORM_MAX_PATH];
    GetCurrentMap(mapName, sizeof(mapName));

    char normalizedName[PLATFORM_MAX_PATH];
    NormalizeMapName(mapName, normalizedName, sizeof(normalizedName));

    bool isWhitelisted = false;
    for (int i = 0; i < sizeof(whitelist); i++)
    {
        if (StrEqual(normalizedName, whitelist[i], false))
        {
            isWhitelisted = true;
            break;
        }
    }

    if (isWhitelisted)
    {
        PrintToServer("Map %s (normalized: %s) is in whitelist!", mapName, normalizedName);
		g_b_robot_hands = true;
    }
    else
    {
        PrintToServer("Map %s (normalized: %s) is NOT in whitelist.", mapName, normalizedName);
		g_b_robot_hands = false;
    }
}

/**
 * Normalizes map name:
 * - Extracts workshop ID if `.ugc` present → "workshop/XXXXXXXXX"
 * - Otherwise keeps the plain map name
 */
void NormalizeMapName(const char[] mapName, char[] output, int maxLen)
{
    int pos = StrContains(mapName, ".ugc");
    if (pos != -1)
    {
        // Extract number after ".ugc"
        char id[32];
        strcopy(id, sizeof(id), mapName[pos + 4]); // skip ".ugc"
        Format(output, maxLen, "workshop/%s", id);
    }
    else
    {
        // Normal map — copy as-is
        strcopy(output, maxLen, mapName);
    }
}


public void OnPluginStart() {
	g_b_robot_hands = false;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public Action OnWeaponEquip(int client, int weapon) {

	if (g_b_robot_hands)
	{
		if (IsValidEntity(weapon) && IsValidHumanClient(client) && IsAnyRobot(client)){


		// if (class <= TFClass_Unknown || class > TFClass_Engineer)
		// {
		//     PrintToChatAll("Invalid class for client %d", client);
		// }

		// PrintToChatAll("Client %N's class: %d, model: %s", client, class, g_ArmsModels[class]);

			TFClassType class = TF2_GetPlayerClass(client);
			PrecacheModel(g_ArmsModels[class]);
			// PrintToChatAll("Setting Model for %N", client);
			SetEntityModel(weapon, g_ArmsModels[class]);
			SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
			SetEntProp(weapon, Prop_Send, "m_iViewModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));


			// PrintToChatAll("Client %N's class: %d, model: %s", client, class, g_ArmsModels[class]);

			// // PrecacheModel(TEST);
			// // PrintToChatAll("Setting Model for %N", client);
			// SetEntityModel(weapon, TEST);
			// SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
			// SetEntProp(weapon, Prop_Send, "m_iViewModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
			
		}
	}
	return Plugin_Continue;
}

bool IsValidHumanClient(int client)
{
    return (client > 0 &&
            client <= MaxClients &&
            IsClientInGame(client) &&
            !IsFakeClient(client) &&
            !IsClientSourceTV(client) &&
            !IsClientReplay(client));
}