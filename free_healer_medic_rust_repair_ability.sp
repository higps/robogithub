#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
#include <tf_custom_attributes>
#include <sdkhooks>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Rust Repair"
#define ROBOT_ROLE "Healer"
#define ROBOT_CLASS "Medic"
#define ROBOT_SUBCLASS "Healer"
#define ROBOT_DESCRIPTION "Vita-Saw Medic Healer"
#define ROBOT_TIPS "Each organ gives 0.5 additional self-buff duration\nMini-Crit Injection grants speed and mini-crits"
#define ROBOT_ON_DEATH "Use airblast to push this robot away from his teammates"
#define GMEDIC             "models/bots/medic/bot_medic.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_demoman/giant_demoman_loop.wav"

#define DMG_TYPE_MELEE 134221952
#define DMG_TYPE_MELEE_CRIT 135270528
 
bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
int g_Heal_Bolts_Hits_Needed = 16;
int g_healcount = 0;
float g_duration = 8.0;
float g_organ_duration_bonus_modifier = 2.0;
float g_organ_bonus = 0.0;
public Plugin:myinfo =
{
	name = "[TF2] Rust Repair Ability",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Rust Repair Ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{

	for(int client = 1 ; client <= MaxClients ; client++)
	{
		if(IsClientInGame(client))
		{
			SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
		}
	}
	// AddNormalSoundHook(BossIcebear);
}


public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack); // hook for when someone joins in the middle of a round
}



public TF2_OnConditionRemoved(int client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_RuneHaste)
    {
       TF2_AddCondition(client,TFCond_SpeedBuffAlly, 0.1);

    }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{

		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE|IN_ATTACK2) ) 
		{
            g_button_held[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE|IN_ATTACK2) ) 
		{
			g_button_held[client] = false;
            
		}
		DrawHUD(client);
		
	}
	return Plugin_Continue;
}

bool isready;
#define CHAR_FULL "■"
#define CHAR_EMPTY "□"

void DrawHUD(int client)
{
	char sHUDText[128];
	char sProgress[32];
	// int iPercents = RoundToCeil((GetEngineTime() / g_Recharge[client])  * 100.0);
	int iCountDown = g_Heal_Bolts_Hits_Needed - g_healcount;

	int iCountDownActive = RoundToCeil(g_Recharge[client] + g_organ_bonus - (GetEngineTime()));

	int iPercents = RoundToCeil(iCountDownActive / g_duration + g_organ_bonus * 100.0);
	for (int j = 1; j <= 10; j++)
	{
	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}

	if (TF2_IsPlayerInCondition(client, TFCond_CritHype))
	{
	Format(sHUDText, sizeof(sHUDText), "Mini-Crit Injection! %i", iCountDownActive);
	//Format(sHUDText, sizeof(sHUDText), "Speed Injection Active!\n               %s", sProgress);
	SetHudTextParams(1.0, 0.8, 0.5, 255, 69, 0, 255);
	}
	else if(iCountDown <= 0)
	{


	Format(sHUDText, sizeof(sHUDText), "Mini-Crit Injection: Ready!");
	SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);

	}else
	{
	Format(sHUDText, sizeof(sHUDText), "Mini-Crit Injection: %i", iCountDown);
	SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);


	}

	ShowHudText(client, -2, sHUDText);

	if (!isready && iCountDown <= 0)
	{
	TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
	// PrintToChatAll("Ready!");
	isready = true;	
	}

	if (g_button_held[client] && iCountDown <= 0 || IsFakeClient(client))
	{
	isready = false;

	TF2_AddCondition(client, TFCond_CritHype, g_duration + g_organ_bonus);
	TF2_AddCondition(client, TFCond_Buffed, g_duration + g_organ_bonus);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, g_duration + g_organ_bonus);
	TF2_AddCondition(client, TFCond_RuneHaste, g_duration + g_organ_bonus);
	// PrintToChatAll("SELF BUFF DURATION %f", GetOrganBonus(client)); 
	g_healcount = 0;
	SetEntProp(client, Prop_Send, "m_iDecapitations", 0);
	g_Recharge[client] = GetEngineTime() + g_duration;
	}
}

float GetOrganBonus(int client)
{

	int organs = GetEntProp(client, Prop_Send, "m_iDecapitations");
	// PrintToChatAll("Organs %i", organs);
	if (organs == 0)
	{
		return 0.0;
	}else
	{
		return (float(organs) / g_organ_duration_bonus_modifier);	
	}
	
}


public bool IsKritzed(int client){
	if (TF2_IsPlayerInCondition(client, (TFCond_Kritzkrieged)) || TF2_IsPlayerInCondition(client, (TFCond_Buffed)) || TF2_IsPlayerInCondition(client, (TFCond_CritCanteen)))
	{
		return true;
	}else
	{
		return false;
	}
}    



public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if (IsValidClient(victim) && IsRobot(attacker, ROBOT_NAME))
	{
		if(!TF2_IsPlayerInCondition(attacker, TFCond_CritHype))
		{
			g_healcount++;
			g_organ_bonus = GetOrganBonus(attacker);
		}
	}
	return Plugin_Continue;
}

public Action OnTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{

	if((IsValidEntity(victim) && IsValidEntity(attacker) && IsValidEntity(inflictor)) &&
	(victim <= MaxClients && victim > 0) &&
	(attacker <= MaxClients && attacker > 0) &&
	(inflictor <= MaxClients && inflictor > 0)) //Validity checks
	{


		if((IsClientInGame(victim) && IsClientInGame(attacker) && IsClientInGame(inflictor)) &&
		(TF2_GetClientTeam(attacker) == TF2_GetClientTeam(victim))
		&& IsRobot(attacker, ROBOT_NAME)
		&& (inflictor == attacker) 
		&& (damagetype == DMG_TYPE_MELEE || damagetype == DMG_TYPE_MELEE_CRIT))
		{

			int healer = attacker;
			int target = victim;

			if(!TF2_IsPlayerInCondition(healer, TFCond_CritHype))
			{
				g_healcount++;
				g_organ_bonus = GetOrganBonus(attacker);
			}

			if (TF2_IsPlayerInCondition(healer, TFCond_CritHype))
			{
			float team_duration = g_duration  + g_organ_bonus;

			TF2_AddCondition(target, TFCond_SpeedBuffAlly, team_duration);
			TF2_AddCondition(target, TFCond_Buffed, team_duration);
			
			}

		}
	}
	return Plugin_Continue;
}

