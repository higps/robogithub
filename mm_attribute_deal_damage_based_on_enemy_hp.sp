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
float g_damage_bonus;

bool ActiveHasStatWeapon(int iActiveWeapon)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "damage-based-on-remaining-hp", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_hp_ratio = ReadFloatVar(stat_buffer, "target_hp_ratio", 0.35);
	g_damage_bonus = ReadFloatVar(stat_buffer, "damage_modifier", 1.5);
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
					int iHealth = GetClientHealth(victim);
					int maxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
					float percent = float(iHealth) / float(maxHealth);
					// PrintToChatAll("current health: %i imaxHealth %i damage: %f", iHealth, maxHealth, damage);
					// PrintToChatAll("percent %f", percent);
					bonus_hp_damage = RoundToNearest(float(GetClientHealth(victim)) / g_hp_ratio) ;
					// PrintToChatAll("BonusHP dmg: %i , dmg: %f, hp %i", bonus_hp_damage, damage, hp);
					
					if (percent <= g_hp_ratio)
					{
						damage *= g_damage_bonus;			
						return Plugin_Changed;
					}
					
					

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
