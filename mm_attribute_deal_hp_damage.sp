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
int g_missing_hp;
bool ActiveHasStatWeapon(int iActiveWeapon)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "hp-damage", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_hp_ratio = ReadFloatVar(stat_buffer, "damage", 3.0);
	g_only_bots = ReadIntVar(stat_buffer, "only-bots", 0);
	g_missing_hp = ReadIntVar(stat_buffer, "missing-hp", 1);
	// PrintToChatAll("HAS STATS");
	return true;
}
float bonus_hp_damage;
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
				if (g_missing_hp)
				{
					int maxHealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, victim);
					int currentHealth = (GetClientHealth(victim));
					int missingHealth = maxHealth - currentHealth;
					// g_hp_ratio = g_hp_ratio / 100.0;
					// PrintToChatAll("ratio: %f",g_hp_ratio);
					bonus_hp_damage = float(missingHealth) * g_hp_ratio;
					// PrintToChatAll("BonusHP dmg: %f \n, dmg: %f\n, hp %i/%i\n, missing hp: %i", bonus_hp_damage, damage, currentHealth,maxHealth, missingHealth);
					damage = damage + bonus_hp_damage;			
					return Plugin_Changed;
				}
				else
				{
					bonus_hp_damage = RoundToNearest(float(GetClientHealth(victim)) / g_hp_ratio) ;
					// PrintToChatAll("BonusHP dmg: %i\ndmg: %f\nhp %i", bonus_hp_damage, damage, GetClientHealth(victim));
					// PrintToChatAll("Damage should be1: %f", damage);
					damage = damage + float(bonus_hp_damage);			
					return Plugin_Changed;
					// PrintToChatAll("Damage should be2: %f", damage);
					

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
