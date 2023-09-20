#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
#include <tf2_stocks>

float g_dmg;
int g_critType;

#define NOCRIT 538968064
#define IS_CRIT 540016640


bool ActiveHasStatWeapon(int iActiveWeapon)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "dmg-crit-vs-jumping-robots", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_dmg = ReadFloatVar(stat_buffer, "damage", 1.15);
	g_critType = ReadIntVar(stat_buffer, "critType", 0);
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

				// PrintToChatAll("critype: %i g_crittype: %i damagetype: %i", critType, view_as<CritType>(g_critType), damagetype);
				if (IsJumping || TF2_IsPlayerInCondition(victim, TFCond_BlastJumping))
				{
					damage *= g_dmg;
					if (g_critType > 0)
					{
					switch(damagetype)
						{
							case NOCRIT:
							{
								critType = view_as<CritType>(g_critType);
							}
							case IS_CRIT:
							{
								critType = CritType_Crit;
							}

						}
					}				
					return Plugin_Changed;
				}
			}
		}
	}

	return Plugin_Continue;
}