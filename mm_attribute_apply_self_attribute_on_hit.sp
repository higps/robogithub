#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
#include <tf2_stocks>


// float g_dmg = 1.0;

float g_value;
float g_duration;
char g_AttrString[256];
bool ActiveHasStatWeapon(int iActiveWeapon)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "add-player-attribute-on-hit", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	// g_dmg = ReadFloatVar(stat_buffer, "damage", 1.0);
    // Use ReadStringVar function properly by passing the array directly
    if (!ReadStringVar(stat_buffer, "player_attribute_name", g_AttrString, sizeof(g_AttrString))) {
        return false;  // Handle the case where reading the string fails
    }
	g_value = ReadFloatVar(stat_buffer, "player_attribute_value", 1.0);
	g_duration = ReadFloatVar(stat_buffer, "player_attribute_duration", 1.0);
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
			if(ActiveHasStatWeapon(weapon))
			{

				TF2Attrib_AddCustomPlayerAttribute(attacker, g_AttrString, g_value, g_duration)
			}
		}
	}

	return Plugin_Continue;
}