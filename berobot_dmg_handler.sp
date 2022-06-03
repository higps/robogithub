#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
#include <tf2attributes>
#include <morecolors_newsyntax>
// #include <addplayerhealth>


// #include <berobot_constants>
// #include <berobot>
// #include <berobot_core_restrictions>
// #include <morecolors_newsyntax>
// #include <sdkhooks>
// #include <sdktools>
// #include <sm_logger>
// #include <sourcemod>
// #include <tf2>
// #include <tf2_stocks>
// #include <tf_ontakedamage>
// #include <tf2_isPlayerInSpawn>
// #include <particle>

char LOG_TAGS[][] =	 {"VERBOSE", "INFO", "ERROR"};
enum (<<= 1)
{
	SML_VERBOSE = 1,
	SML_INFO,
	SML_ERROR,
}
#include <berobot_core>
#pragma newdecls required
#pragma semicolon 1
enum //Convar names
{
    CV_flSpyBackStabModifier,
    CV_bDebugMode,
    CV_PluginVersion
}

ConVar g_cvCvarList[CV_PluginVersion + 1];

bool g_cv_bDebugMode;
float g_CV_flSpyBackStabModifier;

int Punch_Count[MAXPLAYERS + 1] = 0;
int Timer_Punch_Count[MAXPLAYERS + 1] = 0;
bool g_Timer[MAXPLAYERS + 1] = false;

int g_Eyelander_Counter[MAXPLAYERS + 1] = 0;

public Plugin myinfo =
{
	name = "berobot_dmg_handler",
	author = "HeavyIsGPS",
	description = "Handles the damage for against Giant Robots",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};



public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_dmg_handler started at %i", GetTime());

    g_cvCvarList[CV_bDebugMode] = CreateConVar("sm_mm_dmg_debug", "0", "Enable Damage Debugging for Manned Machines Mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCvarList[CV_flSpyBackStabModifier] = CreateConVar("sm_robo_backstab_damage", "83.3", "Backstab damage that will be multipled by crit multiplier");
   
    /* Convar global variables init */
    g_cv_bDebugMode = GetConVarBool(g_cvCvarList[CV_bDebugMode]);
    g_CV_flSpyBackStabModifier = GetConVarFloat(g_cvCvarList[CV_flSpyBackStabModifier]);

  /* Convar Change Hooks */
    g_cvCvarList[CV_bDebugMode].AddChangeHook(CvarChangeHook);

    HookEvent("post_inventory_application", Event_post_inventory_application, EventHookMode_Post);
}

public void CvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    if(convar == g_cvCvarList[CV_bDebugMode])
        g_cv_bDebugMode = view_as<bool>(StringToInt(sNewValue));
    if(convar == g_cvCvarList[CV_flSpyBackStabModifier])
        g_CV_flSpyBackStabModifier = StringToFloat(sNewValue);
}

/* Plugin Exclusive Functions */
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
    {
        if(IsAnyRobot(victim) && damagetype == DMG_FALL)
        {
        damage *= 0.25;
        return Plugin_Changed;
        }
        return Plugin_Continue;
    }       
    if(IsAnyRobot(victim) && !IsAnyRobot(attacker))
    {

        TFClassType iClassAttacker = TF2_GetPlayerClass(attacker);

            if (iClassAttacker == TFClass_Pyro)
            {
                if(IsAxtinguisher(weapon) && TF2_IsPlayerInCondition(victim, TFCond_OnFire))
                {
                 //   PrintToChatAll("Target on fire");
                    TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 5.0);
                }

                if(IsPowerJack(weapon))
                {
                
                AddPlayerHealth(attacker, 25, 260, true);
                ShowHealthGain(attacker, 50, attacker);
                }
            }

                        if (iClassAttacker == TFClass_Heavy)
            {
                if(IsWarriorSpirit(weapon))
                {           
                AddPlayerHealth(attacker, 50, 450, true);
                ShowHealthGain(attacker, 50, attacker);
                }

                		if(IsKGB(weapon))
		{

		if(g_cv_bDebugMode) PrintToChatAll("Hit # %i", Punch_Count[attacker]);

		//Get the name of the player to use with the tauntem plugin
		int playerID = GetClientUserId(victim);
		
		if(g_cv_bDebugMode) PrintToChatAll("Victim name %s", playerID);
			
			
			//Count the punches
			Punch_Count[attacker]++;

            if(TF2_IsPlayerInCondition(attacker, TFCond_CritCanteen))
            {
                Punch_Count[attacker] = 0;
            }
			//PrintToChatAll("Punch count %i", Punch_Count[attacker]);
			
			// PrintToChatAll("========================");
	// PrintToChatAll("Before timer Punch_Count %i:", Punch_Count[attacker]);
	// PrintToChatAll("Beforetimer Timer_Punch_Count %i:", Timer_Punch_Count[attacker]);
			
			if(!g_Timer[attacker]){
			
			//PrintToChatAll("Creating timer");
			
			CreateTimer(1.0, Combo_Check_Timer, attacker);
			Timer_Punch_Count[attacker] = Punch_Count[attacker];
			
			g_Timer[attacker] = true;
			}
		
		
			
		//Combo_Stopper(attacker);
		
		if (Punch_Count[attacker] > 2)
		{
			Combo_Stopper(attacker);
            TF2_AddCondition(attacker, TFCond_CritCanteen, 6.0, attacker);
		}

		}
                    



            }


                if(damagecustom == TF_CUSTOM_BACKSTAB)
                {

                if(IsKunai(weapon))
                {
                    AddPlayerHealth(attacker, 60, 210, true);
                }

                if (IsBigEarner(weapon))
                {
                    TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);
                }

                if (IsYer(weapon))
                {
                    //PrintToChatAll("Was yer");
                    //int iteam = GetClientTeam(victim);
                    TFTeam iTeam = view_as<TFTeam>(GetEntProp(victim, Prop_Send, "m_iTeamNum"));
                    // int attackerID = GetClientUserId(attacker);
                    // int victimID = GetClientUserId(victim);
                    TFClassType iClassVictim = TF2_GetPlayerClass(victim);

                    //TF2_DisguisePlayer(attackerID, iTeam, iClassVictim, victimID);
                    DataPack info = new DataPack();
                        info.Reset();
                        info.WriteCell(GetClientUserId(attacker));
                        info.WriteCell(iTeam);
                        info.WriteCell(iClassVictim);
                        info.WriteCell(GetClientUserId(victim));

                    RequestFrame(Disguiseframe, info);                  
                }

                    
                    

                    if (HasDiamondback(attacker)) //Diamondback gives 1 crits on backstab
                    {
                        int iCrits = GetEntProp(attacker, Prop_Send, "m_iRevengeCrits");
                        SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", iCrits+1);
                    }

                    if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);
                    damage = g_CV_flSpyBackStabModifier;
                    critType = CritType_Crit;
                    if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                    return Plugin_Changed;
                }

                switch (damagecustom)
                {
                case TF_CUSTOM_TAUNT_HADOUKEN, TF_CUSTOM_TAUNT_HIGH_NOON, TF_CUSTOM_TAUNT_GRAND_SLAM, 
                TF_CUSTOM_TAUNT_FENCING, TF_CUSTOM_TAUNT_ARROW_STAB, TF_CUSTOM_TELEFRAG,
                 TF_CUSTOM_TAUNT_GRENADE, TF_CUSTOM_TAUNT_BARBARIAN_SWING, TF_CUSTOM_TAUNT_UBERSLICE, 
                 TF_CUSTOM_TAUNT_ENGINEER_SMASH, TF_CUSTOM_TAUNT_ENGINEER_ARM, TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,
                 TF_CUSTOM_TAUNTATK_GASBLAST:
                {
                    damage *= 2.5;
                    return Plugin_Changed;
                }
                }

                switch (damagecustom)
                {
                case TF_CUSTOM_CHARGE_IMPACT, TF_CUSTOM_BOOTS_STOMP:
                {
                    //damage *= 1.5;
                    if (IsTank(victim)){
                        TF2_StunPlayer(victim, 0.5, 0.0, TF_STUNFLAG_BONKSTUCK, attacker);
                        TF2_AddCondition(victim, TFCond_Sapped, 0.5, attacker);
                    }
                    return Plugin_Changed;
                }
                case TF_CUSTOM_BASEBALL:
                {
                    TF2_StunPlayer(victim, 2.5, 0.7, TF_STUNFLAG_SLOWDOWN, attacker);
                    TF2_AddCondition(victim, TFCond_Sapped, 2.5, attacker);
                    return Plugin_Changed;
                }
                //TF2_StunPlayer(victim, 10.0, 0.0, TF_STUNFLAG_BONKSTUCK, attacker);
                }
    }


    return Plugin_Continue;
}

void Disguiseframe (DataPack info)
{
    
	info.Reset();
	int attacker = GetClientOfUserId(info.ReadCell());
	int iTeam = info.ReadCell();
    int iClassVictim = info.ReadCell();
    int victim = GetClientOfUserId(info.ReadCell());
	delete info;

    FastDisguise(attacker, iTeam, iClassVictim, victim);
}

void FastDisguise(int iClient, TFTeam iTeam, TFClassType iClass, int iTarget)
{
    TF2_DisguisePlayer(iClient, iTeam, iClass, iTarget); // SetEntProp(iClient, Prop_Send, "m_hDisguiseWeapon", iWeapon);

    SetEntProp(iClient, Prop_Send, "m_nDisguiseTeam", _:iTeam);
    SetEntProp(iClient, Prop_Send, "m_nMaskClass", _:iClass);
    SetEntProp(iClient, Prop_Send, "m_nDisguiseClass", _:iClass);
    SetEntProp(iClient, Prop_Send, "m_nDesiredDisguiseClass", _:iClass);
    SetEntProp(iClient, Prop_Send, "m_iDisguiseTargetIndex", iTarget);

   SetEntProp(iClient, Prop_Send, "m_iDisguiseHealth", IsPlayerAlive(iTarget) ? GetClientHealth(iTarget) : GetClassBaseHP(iTarget));

    TF2_AddCondition(iClient, TFCond_Disguised);
}

public Action GetClassBaseHP(int iClient)
{
    switch (TF2_GetPlayerClass(iClient))
    {
        case TFClass_Scout:     return 125;
        case TFClass_Soldier:   return 200;
        case TFClass_Pyro:      return 175;
        case TFClass_DemoMan:   return 175;
        case TFClass_Heavy:     return 300;
        case TFClass_Engineer:  return 125;
        case TFClass_Medic:     return 150;
        case TFClass_Sniper:    return 125;
        case TFClass_Spy:       return 125;
    }
    return 125;
} 

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
        return Plugin_Continue;

    TFClassType iClassAttacker = TF2_GetPlayerClass(attacker);

    
    if(IsAnyRobot(victim))
    {

            switch(damagecustom){
                case TF_CUSTOM_PLASMA_CHARGED: 
                {
                    damage *= 1.5;
                    TF2_StunPlayer(victim, 2.5, 0.7, TF_STUNFLAG_SLOWDOWN, attacker);
                    TF2_AddCondition(victim, TFCond_Sapped, 2.5, attacker);
                    critType = CritType_Crit;
                    return Plugin_Changed;

                }   
            }
            /*Damage code for Heavy*/
            if (iClassAttacker == TFClass_Heavy)
            {
                int iWeapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
                    
                if (weapon == iWeapon)
                {
                    if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);
                    damage *= 0.8;
                    if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                    return Plugin_Changed;
                    
                }
                    
                    
            }

            if (IsElectric(weapon) && IsAnyRobot(victim))
            {
                TF2_StunPlayer(victim, 0.5, 0.4, TF_STUNFLAG_SLOWDOWN, attacker);
                TF2_AddCondition(victim, TFCond_Sapped, 0.5, attacker);
            }
            
            if (iClassAttacker == TFClass_DemoMan && !IsAnyRobot(attacker))
            {

                if(IsEyelander(weapon)) IncrementHeadCount(attacker);


                if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);
                damage *= 1.25;
                if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                return Plugin_Changed;
                
                    
            }
            if (iClassAttacker == TFClass_Soldier && TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping))
            {
                //int iWeapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);

                    
                if (IsMarketGardner(weapon))
                {
                    if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);
                    damage *= 1.5;
                    if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                    return Plugin_Changed;
                    
                }
                    
                TF2_AddCondition(victim, TFCond_Sapped, 0.5, attacker);
            }
            if (iClassAttacker == TFClass_Sniper)
            {
                if(IsBazaar(weapon)) {
                    int decapitations = GetEntProp(attacker, Prop_Send, "m_iDecapitations");

                    if(damagecustom == TF_CUSTOM_HEADSHOT)
                    {
                        SetEntProp(attacker, Prop_Send, "m_iDecapitations", decapitations + 1);
                    }else
                    {
                        if (decapitations == 0)
                        {
                            SetEntProp(attacker, Prop_Send, "m_iDecapitations", 0);    
                        }else
                        {
                            SetEntProp(attacker, Prop_Send, "m_iDecapitations", decapitations - 1);    
                        }
                        
                    }
                    

                }

                if (IsHeatmaker(weapon))
                {
                    float chargelevel = GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage");
                    float add = 35 + (chargelevel / 10);
                    if (TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff)) add /= 3;
                    float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
                    SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage + add > 100) ? 100.0 : rage + add);
                }
            }




    }
    return Plugin_Continue;
}

bool IsMarketGardner(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If Market gardner gets skins in future with different indices, add them here
	case 416: //Market Gardner
		{
			return true;
		}
	}
	return false;
}

bool IsElectric(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other electric weapons are added, add here
	case 528, 442, 588: //Short Circuit, The Righteous Bison, Cow Mangler
		{
			return true;
		}
	}
	return false;
}


//Stats to be applied on human weapons
public Action Event_post_inventory_application(Event event, const char[] name, bool dontBroadcast)
{

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    //CreateTimer(0.8, AddAttributes, client);



// public Action AddAttributes(Handle timer, int client)
// {

    // if (IsValidClient(client)){    
    // if (IsPlayerAlive(client))
    // {
    if (!IsAnyRobot(client) && IsValidClient(client) && IsPlayerAlive(client))
    {

        
        if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
        {
            MC_PrintToChatEx(client, client, "{teamcolor}All of your weapons {orange}+25%%% damage{teamcolor} against robots");
        }

        if (TF2_GetPlayerClass(client) == TFClass_Heavy)
        {
            MC_PrintToChatEx(client, client, "{teamcolor}Your miniguns all deal {orange}-20%%% damage{teamcolor} against robots");
        }

        int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
        int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
        int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
        
        if (IsEyelander(Weapon3))
        {
            g_Eyelander_Counter[client] = 0;
            MC_PrintToChatEx(client, client, "{teamcolor}Your eyelander {orange}gains a head every hit{teamcolor} against robots");
        }

        if (IsSniperRifle(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "explosive sniper shot", 1.0);
            MC_PrintToChatEx(client, client, "{teamcolor}Your rifle has {orange}explosive headshots {teamcolor}bonus");
           
        }

        if (IsBazaar(Weapon1))
        {

            MC_PrintToChatEx(client, client, "{teamcolor}Your rifle {orange}gains head{teamcolor} on headshot, but {orange}loses a head{teamcolor} on bodyshots");
           
        }

        if (IsRevolverOrEnforcer(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
            MC_PrintToChatEx(client, client, "{teamcolor}Your gun has {orange}projectile penetration {teamcolor}bonus");
        }

        if (IsAmbassador(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "crit_dmg_falloff", 0.0);
            MC_PrintToChatEx(client, client, "{teamcolor}Your gun has {orange}no critical damage faloff {teamcolor}penalty");
        }

        if (IsHuntsMan(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
            MC_PrintToChatEx(client, client, "{teamcolor}Your bow has {orange}projectile penetration {teamcolor}bonus");
        }

        if (IsCandyCane(Weapon3))
        {
            TF2Attrib_SetByName(Weapon3, "health from packs increased", 1.33);
            MC_PrintToChatEx(client, client, "{teamcolor}Your candy cane gives {orange}+33%%% more heal{teamcolor} from healthpacks");
        }

        if (IsMarketGardner(Weapon3))
        {
            MC_PrintToChatEx(client, client, "{teamcolor}Your Market Gardner {orange}+50%%% more damage{teamcolor}");
        }

        if (IsElectric(Weapon1) || IsElectric(Weapon2))
        {
            MC_PrintToChatEx(client, client, "{teamcolor}Your electric weapons slow robots for {orange}-60%%% move speed{teamcolor} for 0.5 seconds on hit");
        }

        if (IsWarriorSpirit(Weapon3))
        {
            MC_PrintToChatEx(client, client, "{teamcolor}Your warrior spirits gives {orange}+50 HP{teamcolor} on hit against robots");
        }

        if (IsKGB(Weapon3))
        {
            MC_PrintToChatEx(client, client, "{teamcolor}Your KGB grants you {orange}+7 seconds of critical hits{teamcolor} when landing a quick 3 hit combo");
        }
        if (IsJetpack(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "falling_impact_radius_pushback", 0.0);
            MC_PrintToChatEx(client, client, "{teamcolor}Your Jetpack {orange}deals no knockback{teamcolor} when landing");
        }

    }

    

}
    
    




bool IsSniperRifle(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Sniper Rifles and Reskins
	case 14, 201, 230, 664, 792, 801, 851, 881, 890, 899, 908, 957, 966, 15000, 15007, 15019, 15023, 15033, 15059, 15070, 15071, 15072, 15111, 15112, 15135, 15136, 15154: //Short Circuit, The Righteous Bison, Cow Mangler
		{
			return true;
		}
	}
	return false;
}

bool IsHuntsMan(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other electric weapons are added, add here
	case 56, 1005, 1092: //Short Circuit, The Righteous Bison, Cow Mangler
		{
			return true;
		}
	}
	return false;
}

bool IsBazaar(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other electric weapons are added, add here
	case 402: //Short Circuit, The Righteous Bison, Cow Mangler
		{
			return true;
		}
	}
	return false;
}

bool IsHeatmaker(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other electric weapons are added, add here
	case 752: //Short Circuit, The Righteous Bison, Cow Mangler
		{
			return true;
		}
	}
	return false;
}

bool IsEyelander(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other electric weapons are added, add here
	case 132, 266, 482: //Short Circuit, The Righteous Bison, Cow Mangler
		{
			return true;
		}
	}
	return false;
}

bool IsKunai(int weapon)
{
  	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other kunais are added, add here
	case 356: 
		{
			return true;
		}
	}
	return false;
}

bool HasDiamondback(int client)
{
    int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
    
    if(weapon == -1 && weapon <= MaxClients) return false;

	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other kunais are added, add here
	case 525: 
		{
			return true;
		}
	}
	return false;
}

bool IsBigEarner(int weapon)
{
  	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other YER are added, add here
	case 461:
		{
			return true;
		}
	}
	return false;
}

bool IsYer(int weapon)
{
  	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other YER are added, add here
	case 225, 574:
		{
			return true;
		}
	}
	return false;
}

bool IsAxtinguisher(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Axtinguisher
	case 38, 1000, 457: 
		{
			return true;
		}
	}
	return false;
}

bool IsPowerJack(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Powerjack
	case 214: 
		{
			return true;
		}
	}
	return false;
}

bool IsWarriorSpirit(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Warrior's Spirit
	case 310: 
		{
			return true;
		}
	}
	return false;
}


bool IsKGB(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If Holiday_Punch gets skins in future with different indices, add them here
	case 43: //Holiday_Punch
		{
			return true;
		}
	}
	return false;
}

bool IsRevolverOrEnforcer(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Revolver and Enforcer
	case 24, 210, 1142, 460, 161, 15011, 15027, 15042, 15051, 15062, 15063, 15064, 15103, 15128, 15127, 15149: //Holiday_Punch
		{
			return true;
		}
	}
	return false;
}

bool IsAmbassador(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Revolver and Enforcer
	case 61, 1006: 
		{
			return true;
		}
	}
	return false;
}

bool IsCandyCane(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Candy Cane
	case 317: 
		{
			return true;
		}
	}
	return false;
}

bool IsJetpack(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Candy Cane
	case 1179: 
		{
			return true;
		}
	}
	return false;
}

void IncrementHeadCount(int iClient)
{

    g_Eyelander_Counter[iClient]++;
    // if (g_Eyelander_Counter[iClient] == 3)
    // {
    TF2_AddCondition(iClient, TFCond_DemoBuff);
    SetEntProp(iClient, Prop_Send, "m_iDecapitations", GetEntProp(iClient, Prop_Send, "m_iDecapitations") + 1);
   // AddPlayerHealth(iClient, 15, 300, true);             //  The old version of this allowed infinite health gain... so ;v
    TF2_AddCondition(iClient, TFCond_SpeedBuffAlly, 0.01);  //  Recalculate their speed
    // g_Eyelander_Counter[iClient] = 0;
    // }
}

void AddPlayerHealth(int iClient, int iAdd, int iOverheal = 0, bool bStaticMax = false)
{
    int iHealth = GetClientHealth(iClient);

    
    int iNewHealth = iHealth + iAdd;
    int iMax = bStaticMax ? iOverheal : GetEntProp(iClient, Prop_Data, "m_iMaxHealth") + iOverheal;

    // PrintToChatAll("Ihealth was: %i iAdd was: %i, iMax was: %i", iHealth, iAdd, iMax);
    if (iNewHealth <= iMax)
    {
        //iNewHealth = min(iNewHealth, iMax);
        SetEntityHealth(iClient, iNewHealth);
    }else
    {
        SetEntityHealth(iClient, iMax);
    }
}

void ShowHealthGain(int iPatient, int iHealth, int iHealer = -1)
{
    int iUserId = GetClientUserId(iPatient);
    Handle hEvent = CreateEvent("player_healed", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "patient", iUserId);
    SetEventInt(hEvent, "healer", IsValidClient(iHealer) ? GetClientUserId(iHealer) : iUserId);
    SetEventInt(hEvent, "amount", iHealth);
    FireEvent(hEvent);

    hEvent = CreateEvent("player_healonhit", true);
    SetEventBool(hEvent, "sourcemod", true);
    SetEventInt(hEvent, "amount", iHealth);
    SetEventInt(hEvent, "entindex", iPatient);
    FireEvent(hEvent);
}

public Action Combo_Check_Timer (Handle timer, int client)
{	
// PrintToChatAll("========================");
	// PrintToChatAll("Inside timer Punch_Count %i:", Punch_Count[client]);
	// PrintToChatAll("Inside timer Timer_Punch_Count %i:", Timer_Punch_Count[client]);
	
	if (Punch_Count[client] > Timer_Punch_Count[client]){
		//PrintToChatAll("Combo still going");
		Timer_Punch_Count[client] = Punch_Count[client];
		CreateTimer(1.0, Combo_Check_Timer, client);
}	else
{	
//	PrintToChatAll("Timer Expired");
	Combo_Stopper(client);
	g_Timer[client] = false;
	}
}

public Action Combo_Stopper (int client){

			Punch_Count[client] = 0;
			Timer_Punch_Count[client] = 0;
			// PrintToChatAll("========================");
			// PrintToChatAll("Resetting combo");
				// PrintToChatAll("Inside timer Punch_Count %i:", Punch_Count[client]);
	// PrintToChatAll("Inside timer Timer_Punch_Count %i:", Timer_Punch_Count[client]);
		//g_Timer[attacker] = false;

}