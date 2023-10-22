#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

// MvMPlayer properties
static int g_PlayerTeamCount[MAXPLAYERS + 1];
static TFTeam g_PlayerTeam[MAXPLAYERS + 1][8];
static int g_PlayerIsMiniBossCount[MAXPLAYERS + 1];
static int g_PlayerIsMiniBoss[MAXPLAYERS + 1][8];
static int g_PlayerFlagsCount[MAXPLAYERS + 1];
static int g_PlayerFlags[MAXPLAYERS + 1][8];
static bool g_PlayerHasPurchasedUpgrades[MAXPLAYERS + 1];
static bool g_PlayerIsClosingUpgradeMenu[MAXPLAYERS + 1];
static int g_PlayerAcquiredCredits[MAXPLAYERS + 1];

// MvMTeam properties
static int g_TeamAcquiredCredits[view_as<int>(TFTeam_Blue) + 1];
static int g_TeamWorldMoney[view_as<int>(TFTeam_Blue) + 1];

methodmap MvMPlayer
{
	public MvMPlayer(int client)
	{
		return view_as<MvMPlayer>(client);
	}
	
	property int _client
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	public void AddFlags(int flags)
	{
		int index = g_PlayerFlagsCount[this._client]++;
		g_PlayerFlags[this._client][index] = GetEntityFlags(this._client);
		SetEntityFlags(this._client, g_PlayerFlags[this._client][index] | flags);
	}
	
	public void ResetFlags()
	{
		int index = --g_PlayerFlagsCount[this._client];
		SetEntityFlags(this._client, g_PlayerFlags[this._client][index]);
	}
	
	public void RespecUpgrades()
	{
		// This clears the upgrade history and removes upgrade attributes from the player and their items
		KeyValues respec = new KeyValues("MVM_Respec");
		FakeClientCommandKeyValues(this._client, respec);
		delete respec;
	}
	
	public void Reset()
	{
		this.HasPurchasedUpgrades = false;
		this.IsClosingUpgradeMenu = false;
		this.AcquiredCredits = 0;
		this.Currency = mvm_currency_starting.IntValue;
	}
}

methodmap MvMTeam
{
	public MvMTeam(TFTeam team)
	{
		return view_as<MvMTeam>(team);
	}
	
	property int _teamNum
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	property int AcquiredCredits
	{
		public get()
		{
			return g_TeamAcquiredCredits[this._teamNum];
		}
		public set(int value)
		{
			g_TeamAcquiredCredits[this._teamNum] = value;
		}
	}
	
	property int WorldMoney
	{
		public get()
		{
			return g_TeamWorldMoney[this._teamNum];
		}
		public set(int value)
		{
			g_TeamWorldMoney[this._teamNum] = value;
		}
	}
	
	public void Reset()
	{
		this.AcquiredCredits = 0;
		this.WorldMoney = 0;
	}
};

Handle g_hGameConf;
Handle g_hGameModeUsesUpgrades;

public void OnPluginStart()
{
    //GameConfig
    g_hGameConf = LoadGameConfigFile("mannvsmann");
    
    /* Dhooks */
    // CTFGameRules::GameModeUsesUpgrades
    CreateDynamicDetour(g_hGameConf, "CTFGameRules::GameModeUsesUpgrades", _, OnGameModeUsesUpgrades_Post);
    DHooks_AddDynamicDetour(g_hGameConf, "CBaseObject::FindSnapToBuildPos", DHookCallback_FindSnapToBuildPos_Pre, DHookCallback_FindSnapToBuildPos_Post);
    delete g_hGameConf;
}

public MRESReturn OnGameModeUsesUpgrades_Post(DHookReturn hReturn)
{
    hReturn.Value = true;
    return MRES_Supercede;
}

static void CreateDynamicDetour(GameData gamedata, const char[] name, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
    DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
    if (detour)
    {
        if (callbackPre != INVALID_FUNCTION)
            detour.Enable(Hook_Pre, callbackPre);
        
        if (callbackPost != INVALID_FUNCTION)
            detour.Enable(Hook_Post, callbackPost);
    }
    else
    {
        LogError("Failed to create detour setup handle for %s", name);
    }
}

public MRESReturn DHookCallback_FindSnapToBuildPos_Pre(int obj, DHookReturn ret, DHookParam params)
{
	// Allows placing sappers on other players
	SetMannVsMachineMode(true);
	
	int builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
	
	// The robot sapper only works on bots, give every player the fake client flag
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && client != builder)
		{
			MvMPlayer(client).AddFlags(FL_FAKECLIENT);
		}
	}
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_FindSnapToBuildPos_Post(int obj, DHookReturn ret, DHookParam params)
{
	ResetMannVsMachineMode();
	
	int builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && client != builder)
		{
			MvMPlayer(client).ResetFlags();
		}
	}
	
	return MRES_Ignored;
}

static int g_IsMannVsMachineModeCount;
static bool g_IsMannVsMachineModeState[8];
static int g_PlayerFlagsCount[MAXPLAYERS + 1];
static int g_PlayerFlags[MAXPLAYERS + 1][8];

void SetMannVsMachineMode(bool value)
{
	int index = g_IsMannVsMachineModeCount++;
	g_IsMannVsMachineModeState[index] = IsMannVsMachineMode();
	GameRules_SetProp("m_bPlayingMannVsMachine", value);
}

void ResetMannVsMachineMode()
{
	int index = --g_IsMannVsMachineModeCount;
	GameRules_SetProp("m_bPlayingMannVsMachine", g_IsMannVsMachineModeState[index]);
}

public void AddFlags(int flags)
{
    int index = g_PlayerFlagsCount[this._client]++;
    g_PlayerFlags[this._client][index] = GetEntityFlags(this._client);
    SetEntityFlags(this._client, g_PlayerFlags[this._client][index] | flags);
}

public void ResetFlags()
{
    int index = --g_PlayerFlagsCount[this._client];
    SetEntityFlags(this._client, g_PlayerFlags[this._client][index]);
}