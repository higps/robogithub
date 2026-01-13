#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_ontakedamage>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>
#include <morecolors>
#include <tf2utils>
#include <smlib>

#define ROBOT_NAME	"Megaton"
#define PLUGIN_VERSION "1.0"
public Plugin:myinfo =
{
	name = "[TF2] Megaton",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Ability for Megaton",
	version = PLUGIN_VERSION,
	url = "www.bmod.tf"
}
float amount_stack = 0.0;

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}
int g_robot_player = -1;


#define sHealNoise "items/medshot4.wav"

public void OnMapStart()
{	
	PrecacheSound(sHealNoise);
}

public void OnRoundStart()
{
	amount_stack = 0.0;
}
public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));


	if(IsAnyRobot(victim))
	{
		
		if(IsValidClient(g_robot_player) && IsPlayerAlive(g_robot_player) && IsRobot(g_robot_player, ROBOT_NAME))
		{
			// PrintToChat(g_robot_player,"Current Max HP %i", TF2Util_GetEntityMaxHealth(g_robot_player));
			// int hp_heal = RoundToNearest(float(TF2Util_GetEntityMaxHealth(g_robot_player)) / (3.0 + float(GetCurrentRobotCount())));
			int hp_heal = RoundToNearest(float(TF2Util_GetEntityMaxHealth(g_robot_player)) / (2.0 + (float(GetCurrentRobotCount()) / 3.0 )));
			// PrintToChat(g_robot_player, "Entity HP: %i Healing for %i", TF2Util_GetEntityMaxHealth(g_robot_player), hp_regen);
			// PrintToChatAll("HEALING %i", hp_heal);
			HealClientByAmount(g_robot_player, hp_heal);
			ShowHealthGain(g_robot_player, hp_heal, g_robot_player);
			// TF2Attrib_AddCustomPlayerAttribute(g_robot_player, "health regen", float(hp_regen), 1.3);
			TF2_AddCondition(g_robot_player, TFCond_InHealRadius, 1.3);
		}
		
	}
	    
}

void HealClientByAmount(int client, int heal)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
    {
        return;
    }

	// PrintToChatAll("DOING");
    // Get current health
    int currentHealth = GetClientHealth(client);
	// PrintToChatAll("Current HP: %i", currentHealth);
    // Get current possible max health (dynamic, respects other mods)
    int maxHealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
	// PrintToChatAll("MaxHP: %i", maxHealth);
    // Heal by 1000, but clamp to maxHealth
    int newHealth = currentHealth + heal;
    if (newHealth > maxHealth)
    {
        newHealth = maxHealth;
    }

    // Apply health
	SetEntProp(client, Prop_Send, "m_iHealth", newHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", newHealth, 1);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", newHealth, 1);
	EmitSoundToAll(sHealNoise, g_robot_player);
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME))
	{
		IncreaseMaxHealth(attacker, damage);
		g_robot_player = attacker;
		int bonus_hp_damage = RoundToNearest(float(GetClientHealth(victim)) / 3.0) ;
		// PrintToChatAll("%i",bonus_hp_damage);
		damage = damage + bonus_hp_damage;

		return Plugin_Changed;
	}
}

void IncreaseMaxHealth(int client, float amount)
{
    // Check if the client is valid and connected
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

	amount_stack = amount_stack + amount;
	// PrintToChatAll("Amount stack %f", amount_stack[client] );
	TF2Attrib_SetByName(client, "max health additive penalty", amount_stack);
}

stock void ShowHealthGain(int iPatient, int iHealth, int iHealer = -1, bool bAddToScore = true)
{
	int iUserId = GetClientUserId(iPatient);
	
	Handle hEvent = CreateEvent("player_healed", true);
	
	SetEventBool(hEvent, "sourcemod", true);
	SetEventInt(hEvent, "patient", iUserId);
	SetEventInt(hEvent, "healer", IsValidClient(iHealer) ? GetClientUserId(iHealer) : iUserId);
	SetEventInt(hEvent, "amount", iHealth);
	
	FireEvent(hEvent);
	
	hEvent = CreateEvent("player_healonhit", true);
	
	SetEventBool(hEvent, "sourcemod", true);
	SetEventInt(hEvent, "amount", iHealth);
	SetEventInt(hEvent, "entindex", iPatient);
	
	//Adds to healing score if wanted
	if(bAddToScore)
	{
		Handle hGameConf;
		Handle hPlayerHealedOther;
		
		Address pGameStats;
		
		if((hGameConf = LoadGameConfigFile("playerhealedother")) != INVALID_HANDLE) // Needs the gamedata
		{
			StartPrepSDKCall(SDKCall_Raw);
		
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFGameStats::Event_PlayerHealedOther");
			
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			
			hPlayerHealedOther = EndPrepSDKCall();
			
			pGameStats = GameConfGetAddress(hGameConf, "CTFGameStats");
			
			SDKCall(hPlayerHealedOther, pGameStats, IsValidClient(iHealer) ? iHealer : iPatient, float(iHealth));
			
			delete hGameConf;
			delete hPlayerHealedOther;
		}
	}
	
	FireEvent(hEvent);
}