#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
#include <tf2_stocks>


float g_fall_damage_taken;
float g_stomp_damage_given;
int g_use_static_value_on_dmg;
int g_use_static_value_on_stomp_dmg;
// bool g_found_stat = false;

bool HasStat(int client)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(client == -1) return false;

	// g_found_stat = true;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "fall-damage", stat_buffer, sizeof(stat_buffer))) {
		// g_found_stat = false;
		return false;
	}

	// if (!g_found_stat && TF2_GetPlayerClass(client) == TFClass_Soldier)
	// {
	// 	int mantreads = FindTFWearable(client, 444);
	// 	if (IsValidEntity(mantreads))
	// 	{
	// 		if (!TF2CustAttr_GetString(mantreads, "fall-damage", stat_buffer, sizeof(stat_buffer))) {
	// 		g_found_stat = false;
	// 		PrintToChatAll("DID NOT FOUND ON BOOTS");
	// 		}
	// 	}
	// }

	// if (g_found_stat == false)
	// {
	// 	PrintToChatAll("DID NOT FIND STAT ANYWHERE");
	// 	return false;
	// }
	g_use_static_value_on_dmg = ReadIntVar(stat_buffer, "static-damage", 0);
	g_use_static_value_on_stomp_dmg = ReadIntVar(stat_buffer, "static-damage-stomp", 0);
	g_fall_damage_taken = ReadFloatVar(stat_buffer, "fall-damage", 1.0);
	g_stomp_damage_given = ReadFloatVar(stat_buffer, "stomp-damage", 1.0);
	// PrintToChatAll("%N HAS STATS, falldmg taken: %f, stomp_dmg_given, %f",client, g_fall_damage_taken, g_stomp_damage_given);
	return true;
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor,
		float &damage, int &damagetype, int &weapon, float damageForce[3],
		float damagePosition[3], int damagecustom, CritType &critType)
{
	
	if(IsValidClient(victim))
	{


		if (IsValidClient(attacker))
		{
				if(damagetype == DMG_FALL && damagecustom == TF_CUSTOM_BOOTS_STOMP)
				{
					if(HasStat(attacker)){
				
						// PrintToChatAll("attacker was %N damage was %f", victim, damage);
						// PrintToChatAll("attacker was %N, victim was %N, damagecustom was %i, inflictor was %i", attacker, victim, damagecustom, inflictor);
						if(g_use_static_value_on_stomp_dmg == 1)
						{
							// PrintToChatAll("1 dmg: %f g_stomp: %f", damage, g_stomp_damage_given);
							damage = g_stomp_damage_given;
							// PrintToChatAll("1: After dmg damage %f", damage);
						}else
						{
							// PrintToChatAll("2");
							damage *= g_stomp_damage_given;
						}
						return Plugin_Changed;
					}
			}

		}


		//Regular Fall damage, is applied to the victim
		
		if(damagetype == DMG_FALL && damagecustom != TF_CUSTOM_BOOTS_STOMP && damage != 0.0)
		{
			// PrintToChatAll("Victim was %N damage was %f", victim, damage);
			// PrintToChatAll("Taking regular fall damagecustom was %i attacker was %i, inflictor fall was %i", damagecustom, attacker, inflictor);
			if (HasStat(victim)){
				if(g_use_static_value_on_dmg == 1)
				{
					// PrintToChatAll("3 dmg: %f, falldmgstatic: %f", damage,g_fall_damage_taken);
					damage = g_fall_damage_taken;
					// PrintToChatAll("3: After dmg damage %f", damage);
				}else
				{
					// PrintToChatAll("4");
					damage *= g_fall_damage_taken;
				}
				
				return Plugin_Changed;
			}
		}


		

	// if (g_bool_change)return Plugin_Changed;

	}
	return Plugin_Continue;
}

public int FindTFWearable(int iClient, int item)
{
	int iWearableItem = -1;
	// PrintToServer("LOOKING HAT 1 !");
	while ((iWearableItem = FindEntityByClassname(iWearableItem, "tf_wearable*")) != -1) // Regular hats.
	{	
		// We check for the wearable's item def index and its owner.
		int iWearableIndex = GetEntProp(iWearableItem, Prop_Send, "m_iItemDefinitionIndex");
		int iWearableOwner = GetEntPropEnt(iWearableItem, Prop_Send, "m_hOwnerEntity");
		// PrintToServer("LOOKING HAT 2 !");
		// If the owners match.
		if (iWearableOwner == iClient)
		{
			// Going through all items. 4 = cosmetics
			for (int i = 0; i < 4; i++)
			{			
				// PrintToServer("LOOKING HAT 3 !");
				// If a weapon's definition index matches with the one stored...
				if (iWearableIndex == item)
				{
    				return iWearableItem;

				}
			}
		}
	}
	return -1;
}