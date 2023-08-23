/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <tf2_stocks>
#include <stocksoup/tf/entity_prop_stocks>
#include <tf_cattr_buff_override>
#include <tf2attributes>

public void OnCustomBuffHandlerAvailable() {
	TF2CustomAttrRageBuff_Register("concho-banner", OnCritBannerPulse);
}

public void OnCritBannerPulse(int owner, int target, const char[] name, int buffItem) {
	TFTeam buffTeam = TF2_GetClientTeam(owner);
	
	// disallow enemies, allow disguised players, disallow cloaked
	if (TF2_GetClientTeamFromClient(target, owner) != buffTeam) 
	{
		return;
	}
	
	// the game internally does this
	// TF2_AddCondition(target, TFCond_SpeedBuffAlly, BUFF_PULSE_CONDITION_DURATION, owner);
	TF2_AddCondition(target, TFCond_RegenBuffed, BUFF_PULSE_CONDITION_DURATION, owner);
	// TF2_AddCondition(target, TFCond_RuneRegen, BUFF_PULSE_CONDITION_DURATION, owner);
	TF2Attrib_AddCustomPlayerAttribute(target, "health regen", 40.0, BUFF_PULSE_CONDITION_DURATION);

}

public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "cattr-buff-override")) {
		OnCustomBuffHandlerAvailable();
	}
}
