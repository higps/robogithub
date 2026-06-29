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

#define PLAYER_ATTR_NAME_KEY "player_attribute_name="

bool ParseAttrNameFromBuffer(const char[] statBuffer, char[] output, int outputLen)
{
	int start = StrContains(statBuffer, PLAYER_ATTR_NAME_KEY);
	if (start == -1)
	{
		return false;
	}

	start += strlen(PLAYER_ATTR_NAME_KEY);

	char remainder[256];
	strcopy(remainder, sizeof(remainder), statBuffer[start]);

	int end = StrContains(remainder, " player_attribute_value=");
	if (end == -1)
	{
		end = StrContains(remainder, " player_attribute_duration=");
	}

	if (end != -1)
	{
		remainder[end] = '\0';
	}

	TrimString(remainder);

	int len = strlen(remainder);
	if (len >= 2)
	{
		if ((remainder[0] == '"' && remainder[len - 1] == '"') || (remainder[0] == '\'' && remainder[len - 1] == '\''))
		{
			remainder[len - 1] = '\0';
			strcopy(output, outputLen, remainder[1]);
			return true;
		}
	}

	strcopy(output, outputLen, remainder);
	return true;
}

bool ActiveHasStatWeapon(int iActiveWeapon)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "add-player-attribute-on-hit", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	if (!ParseAttrNameFromBuffer(stat_buffer, g_AttrString, sizeof(g_AttrString))) {
		return false;
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

				TF2Attrib_AddCustomPlayerAttribute(attacker, g_AttrString, g_value, g_duration);
			}
		}
	}

	return Plugin_Continue;
}