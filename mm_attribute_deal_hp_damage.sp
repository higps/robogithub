#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
#include <tf2_stocks>

float g_hp_ratio;
int g_only_bots;

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
				
					int hp = GetClientHealth(victim);
					bonus_hp_damage = RoundToNearest(float(GetClientHealth(victim)) / g_hp_ratio) ;
					// PrintToChatAll("BonusHP dmg: %i , dmg: %f, hp %i", bonus_hp_damage, damage, hp);
					damage += float(bonus_hp_damage);			
					
					return Plugin_Changed;

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