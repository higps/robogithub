#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
#include <tf2_stocks>
#include <tf2attributes>

float g_hp_ratio;
int g_only_bots;

bool ActiveHasStatWeapon(int iActiveWeapon)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "reduce-max-hp", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_hp_ratio = ReadFloatVar(stat_buffer, "damage_ratio", 1.0);
	g_only_bots = ReadIntVar(stat_buffer, "only-bots", 0);
	// PrintToChatAll("HAS STATS");
	return true;
}
int bonus_hp_damage;
public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage,
int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
int damagecustom, CritType &critType)
{

	if(IsValidClient(victim))
	{
		if(IsValidClient(attacker))
		{
			if(ActiveHasStatWeapon(weapon) && ConfirmVictim(victim))
			{
				
				

				ReduceMaxHP(victim, damage * g_hp_ratio);
			}
		}
	}

	return Plugin_Continue;
}

bool ConfirmVictim(int client)
{
	if (!g_only_bots)
	{
		return true;
	}

	if (g_only_bots && IsAnyRobot(client))
	{
		return true;
	}
	return false;
}

void ReduceMaxHP(int client, float damage)
{
    // Check if the client is valid and connected
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
	int iHealth = GetClientHealth(client);
	int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	
	float new_maxHealth = float(maxHealth) - damage;
	
	// PrintToChatAll("current health: %i imaxHealth %i damage: %f new_maxhealth: %f", iHealth, maxHealth, damage, new_maxHealth);
	// // PrintToChatAll("damage stack %f", damage_stack[client] );
	// SetEntProp(client, Prop_Send, "m_iHealth", iHealth, 1);
	// SetEntProp(client, Prop_Data, "m_iHealth", iHealth, 1);
	// // SetEntProp(client, Prop_Data, "m_iMaxHealth", iHealth, 1);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", RoundToFloor(new_maxHealth), 1);
	// float value = TF2Attrib_GetByName(client, "max health additive penalty");
	// PrintToChatAll("%f value");
	
	TF2Attrib_SetByName(client, "max health additive bonus", new_maxHealth);
}