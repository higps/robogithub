#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Laugh Extractor"

#define SCREAM	"ambient/halloween/male_scream_10.wav"

bool g_button_held[MAXPLAYERS + 1] = false;
// float g_Recharge[MAXPLAYERS + 1] = 0.0;
// float g_RechargeCooldown = 5.0;
float g_skill;
int g_KillCount[MAXPLAYERS + 1] = {5,...};
int g_KillsNeeded = 5;

public Plugin:myinfo = 
{
	name = "[TF2] Laugh Extractor Ability",
	author = "HiGPS | Bmod.TF",
	description = "Laugh Extractor Ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}


public OnPluginStart()
{
    for (int i = 1; i <= MAXPLAYERS; i++)
    {
        g_KillCount[i] = 5;
    }
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantPyro", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
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

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{

		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE) ) 
		{
			//  PrintToChatAll("Press");
            g_button_held[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE) ) 
		{
			//  PrintToChatAll("Release");
			g_button_held[client] = false;
            
		}
		//0 = Shadow Leap
		//PrintToChat(client, "Throwing spell!");
		// UpdateCharge(client);
		g_skill = GetEngineTime();
		DrawHUD(client);
		
	}
}

// float g_hud_draw_delay = 0.1;
// float g_hud_post_time = 0.0;
bool isready;
void DrawHUD(int client)
{
	char sHUDText[128];
	// char sProgress[32];
	//int iPercents = RoundToCeil(float(g_Recharge[client]) / float(g_RechargeCooldown) * 100.0);
	int iCountDown = g_KillsNeeded- g_KillCount[client];
	
	// for (int j = 1; j <= 10; j++)
	// {
	// 	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	// 	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	// }

	Format(sHUDText, sizeof(sHUDText), "Laugh Extraction:\n%i kills remain", iCountDown);
	

	if(iCountDown <= 0)
	{
		Format(sHUDText, sizeof(sHUDText), "Laugh Extraction Ready!\nSpecial Attack to use!");
			
		SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);

		
	} else {
		SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);
		
		// PrintToChatAll("Not Ready!");
	}
	// if (g_hud_post_time + g_hud_draw_delay <= GetEngineTime() || g_hud_post_time == 0.0)
	// {
		 ShowHudText(client, -2, sHUDText);
	// 	 g_hud_post_time = GetEngineTime();
	// }

		if (!isready && iCountDown <= 0)
		{
			TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
			// PrintToChatAll("Ready!");
			isready = true;	
		}

	if (g_button_held[client] && iCountDown <= 0)
	{
		ApplyRadialStun(client, 3.0, 500.0);
		g_KillCount[client] = 0;
		// g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
		isready = false;
		
	}
}

// void LaughExtract(int client)
// {

// 	// TFTeam iTeam = TF2_GetClientTeam(client);
	
	
// }

public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsAnyRobot(victim) && IsRobot(attacker, ROBOT_NAME))
	{
		if(g_KillCount[attacker] <= g_KillsNeeded)
		{
			g_KillCount[attacker]++;
		}

		
		

	}
}

public void ApplyRadialStun(int hero, float flDuration, float flRadius)
{
	//positions
	float heroPos[3];
	float playerPos[3];
	int team = GetClientTeam(hero);
	//Get our hero's position
	GetClientAbsOrigin(hero, heroPos);
	int stunflag = TF_STUNFLAGS_GHOSTSCARE;
		
	//loop through players
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			int cteam = GetClientTeam(client);
			if (cteam == team) continue;
			
			GetClientAbsOrigin(client, playerPos);
			if (GetVectorDistance(playerPos, heroPos) <= flRadius)
			{
				
				TF2_StunPlayer(client, flDuration, 0.0, stunflag);
			}
		}
	}
	EmitSoundToAll(SCREAM, hero, SNDCHAN_ITEM, SNDLEVEL_GUNFIRE);
	EmitSoundToAll(SCREAM, hero, SNDCHAN_ITEM, SNDLEVEL_GUNFIRE);
	EmitSoundToAll(SCREAM, hero, SNDCHAN_ITEM, SNDLEVEL_GUNFIRE);
}
