#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_ontakedamage>
#include <berobot_constants>
#include <berobot>

#define ROBOT_NAME	"RoboVich"
#define PLUGIN_VERSION "1.0"
#define SOUND "player/recharged.wav"
public Plugin:myinfo =
{
	name = "[TF2] Robovich Ability",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Ability for Big Chief Bot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
public void OnMapStart()
{
	PrecacheSound(SOUND);
}
float g_damage_count = 0.0;
float g_damage_cap = 75.0;
int g_max_cap = 30;
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;


	if(IsRobot(attacker, ROBOT_NAME))
	{
		
		g_damage_count += damage;
		// PrintToChatAll("Damage count %f", g_damage_count);

		if (g_damage_count >= g_damage_cap)
		{
			g_damage_count = 0.0;

			AddSandVichCount(attacker);
		}
	}

}

void AddSandVichCount(int client)
{
	int iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (iWeapon != -1)
	{
		// float charge = GetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter");
		// PrintToChatAll("Charge meter %f", charge);
		
		int iOffset = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		int iAmmo = GetEntData(client, iAmmoTable + iOffset, 4);
		// SetEntPropFloat(client, Prop_Send, "m_flEffectBarProgress", 10.0);
		if (iAmmo < g_max_cap)
		{
			SetEntData(client, iAmmoTable + iOffset, iAmmo+1, 4, true);
			PrintCenterText(client, "+1 Sandvich\n%i / %i", iAmmo+1, g_max_cap);
			EmitSoundToAll(SOUND,client);
		}
		else
		{
			PrintCenterText(client, "Full Sandvich\n%i / %i", iAmmo, g_max_cap);
		}
		
	}
}
