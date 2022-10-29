#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>


float g_dmg = 1.0;


bool ActiveHasStatWeapon(int iActiveWeapon)
{
	//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(iActiveWeapon, "dmg-bonus-vs-sapped-buildings", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_dmg = ReadFloatVar(stat_buffer, "damage", 1.0);
	// PrintToChatAll("HAS STATS");
	return true;
}

public void OnEntityCreated(int iEntity, const char[] strClassname)
{
    if (!IsValidEntity(iEntity)) return;
    
    if (StrContains(strClassname, "obj_") != -1)
    {
        SDKHook(iEntity, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
    }
}

public Action Hook_OnTakeDamage(int iVictim, int& iAttacker, int& iInflictor, float& fDamage, int& iDamageType, int& iWeapon, const float fDamageForce[3], const float fDamagePosition[3], int iDamageCustom)
{
    // Valid victim check
	
    // char strClassname[32];
    // GetEntityClassname(iVictim, strClassname, sizeof(strClassname));
    // if (!StrContains(strClassname, "obj_") != -1) return Plugin_Handled;

    // Ok we're good, it's a building
	// if(!IsValidEntity(iVictim)){
	// 	PrintToChatAll("Return Handled");
	// 	return Plugin_Handled;
	// } 
    bool bHasSapper = GetEntProp(iVictim, Prop_Send, "m_bHasSapper") ? true : false;


    if (bHasSapper && ActiveHasStatWeapon(iWeapon))
    {
		// PrintToChatAll("Sapper!");
        fDamage *= g_dmg;
		// PrintToChatAll("Damage: %f", fDamage);
        return Plugin_Changed; // We return Plugin_Changed because we modified an output (fDamage).
	}
		return Plugin_Continue;
}