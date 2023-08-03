#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>


float g_fall_damage_taken;
float g_stomp_damage_given;
int g_use_static_value_on_dmg;
int g_use_static_value_on_stomp_dmg;

bool HasStat(int client)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(client == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "fall-damage", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_use_static_value_on_dmg = ReadIntVar(stat_buffer, "static-damage", 0);
	g_use_static_value_on_stomp_dmg = ReadIntVar(stat_buffer, "static-damage-stomp", 0);
	g_fall_damage_taken = ReadFloatVar(stat_buffer, "fall-damage", 1.0);
	g_stomp_damage_given = ReadFloatVar(stat_buffer, "stomp-damage", 1.0);
	// PrintToChatAll("HAS STATS");
	return true;
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor,
		float &damage, int &damagetype, int &weapon, float damageForce[3],
		float damagePosition[3], int damagecustom, CritType &critType)
{
	if(!IsValidClient(victim))
	return Plugin_Continue;    

	if(!IsValidClient(attacker))
	{

		if(HasStat(victim) && damagetype == DMG_FALL)
		{
			// PrintToChatAll("Taking regular fall damage %N", victim);
			if(g_use_static_value_on_dmg == 1)
			{
				damage = g_fall_damage_taken;
			}else
			{
				damage *= g_fall_damage_taken;
			}
			
			return Plugin_Changed;
		}
	}else
	{
		if(HasStat(attacker) && damagetype == DMG_FALL)
		{

			if(g_use_static_value_on_stomp_dmg == 1)
			{
				damage = g_stomp_damage_given;
			}else
			{
				damage *= g_stomp_damage_given;
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}