#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>


float g_dmg = 1.0;
int g_critType = 2;

bool ActiveHasStatWeapon(int iActiveWeapon)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "dmg-crit-vs-jumping-robots", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_dmg = ReadFloatVar(stat_buffer, "damage", 1.0);
	g_critType = ReadIntVar(stat_buffer, "critType", 1);
	// PrintToChatAll("HAS STATS");
	return true;
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
int damagecustom, CritType &critType)
{

	if(IsValidClient(victim))
	{
		if(IsValidClient(attacker))
		{
			if(ActiveHasStatWeapon(weapon) && IsAnyRobot(victim))
			{
				int IsJumping = GetEntProp(victim, Prop_Send, "m_bJumping");

				if (IsJumping)
				{
				// PrintToChatAll("CORRECT WEP");
				damage *= g_dmg;
				if(g_critType != 0)critType = g_critType;
				return Plugin_Changed;
				}
			}
		}
	}

	return Plugin_Continue;
}