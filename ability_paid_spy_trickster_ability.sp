#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Trickster"
#define SHRINK    "sound/ui/gmm_rank_up.wav"
#define SIZE_RESTORED    "sound/ui/gmm_rank_up.wav/mm_rank_up_achieved.wav"


#define CHAR_FULL "■"
#define CHAR_EMPTY "□"

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 25.0;
float g_skill;

public Plugin:myinfo =
{
	name = "[TF2] Trickster Ability",
	author = "HiGPS | Bmod.TF",
	description = "Trickster Ability for MM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

//bool g_bisGSPY[MAXPLAYERS + 1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	HookEvent("player_death", Event_Death, EventHookMode_Post);
	
}

public OnMapStart()
{
	// PrecacheModel(MODEL);
	PrecacheSound(SHRINK, true);
	PrecacheSound(SIZE_RESTORED, true);

}
int g_souls = 0;
int g_soul_required = 3;
float g_scale = 1.5;
float g_mini_scale = 0.9;
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsRobot(attacker, ROBOT_NAME) && !IsAnyRobot(victim) && g_souls < g_soul_required)
	{
		g_souls++;
		SetEntPropFloat(attacker, Prop_Send, "m_flModelScale", g_scale);
		UpdatePlayerHitbox(attacker, g_scale);
	}
}

void SetSpeed(int client)
{
	
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
}

//Spell code

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		SetSpeed(client);

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
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		// UpdateCharge(client);
		g_skill = GetEngineTime();
		DrawHUD(client);
		
	}
	return Plugin_Continue;
}

public void CastSpell(int client) {

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_mini_scale);
	UpdatePlayerHitbox(client, g_mini_scale);
	EmitSoundToAll(SHRINK,client);
}

// float g_hud_draw_delay = 0.1;
// float g_hud_post_time = 0.0;
bool isready;
void DrawHUD(int client)
{
	char sHUDText[128];
	int iCountDown = RoundToCeil(g_Recharge[client] - g_skill);

	Format(sHUDText, sizeof(sHUDText), "Shrink: %i/%i", g_souls, g_soul_required);
	
	if(g_souls >= g_soul_required)
	{

	Format(sHUDText, sizeof(sHUDText), "Shrink: %i/%i\nReady!",g_souls, g_soul_required);

	
	SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);


	} else {
	SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);

	}
	ShowHudText(client, -2, sHUDText);
	if (!isready && iCountDown <= 0)
	{
	TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
	isready = true;	
	}

	if (g_button_held[client] && g_souls >= 3 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_CloakFlicker))
	{

	RequestFrame(CastSpell, client);
	g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
	isready = false;
	g_souls = 0;
	}
}
