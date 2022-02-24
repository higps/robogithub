/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdkhooks>

#pragma newdecls required

#include <tf2utils>
#include <tf2_stocks>
#include <tf2attributes>
#include <stocksoup/tf/entity_prop_stocks>
#include <tf_cattr_buff_override>
#include <tf_custom_attributes>
#include <tf_ontakedamage>

float g_flConchEndTime[MAXPLAYERS + 1];

public void OnCustomBuffHandlerAvailable() {
	TF2CustomAttrRageBuff_Register("mm-conch", OnConchBannerPulse);
}

public void OnConchBannerPulse(int owner, int target, const char[] name, int buffItem) {
	TFTeam buffTeam = TF2_GetClientTeam(owner);
	
	if (TF2_GetClientTeamFromClient(target, owner) != buffTeam
			|| TF2_IsPlayerInCondition(target, TFCond_Cloaked)
			|| TF2_IsPlayerInCondition(target, TFCond_Stealthed)) {
		return;
	}
	
	TF2_AddCondition(target, TFCond_InHealRadius, BUFF_PULSE_CONDITION_DURATION, owner);
	g_flConchEndTime[target] = GetGameTime() + BUFF_PULSE_CONDITION_DURATION;
}

public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "cattr-buff-override")) {
		OnCustomBuffHandlerAvailable();
	}
}

public void OnClientPutInServer(int client) {
	g_flConchEndTime[client] = 0.0;
	//SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}


public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{

		if (victim == attacker || attacker < 1 || attacker > MaxClients || GetGameTime() > g_flConchEndTime[attacker]) {
		//PrintToChatAll("Was returned");
		return;
	}
	
	int health = GetClientHealth(attacker);
	int maxhealth = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");

	//PrintToChatAll("Max health for %N is %i", attacker, maxhealth);

	int leeched = RoundToNearest(damage * 0.4);
	
	if(health < maxhealth)
		{
			SetEntityHealth(attacker, health + leeched);

			//ShowHealthGain(attacker, leeched, attacker);
			Handle healevent = CreateEvent("player_healed", true);
			SetEventInt(healevent, "patient", attacker);
			SetEventInt(healevent, "healer", attacker);
			SetEventInt(healevent, "amount", leeched);
			FireEvent(healevent);

			healevent = CreateEvent("player_healonhit", true);
			SetEventBool(healevent, "sourcemod", true);
			SetEventInt(healevent, "amount", leeched);
			SetEventInt(healevent, "entindex", attacker);
			FireEvent(healevent);
		}

}
