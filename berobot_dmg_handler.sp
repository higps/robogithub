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

float g_AirStrikeDamage[MAXPLAYERS +1] = 0.0;
float g_AirStrikeDMGRequirement = 600.0;
float g_ElectricStunDuration = 0.6;

float g_FrontierJusticeDamage[MAXPLAYERS + 1] = 0.0;
float g_FrontierJusticeDMGRequirement = 600.0;
int g_EngineerRevengeCrits[MAXPLAYERS + 1] = 0;

//bool g_Enabled;

public Plugin myinfo =
{
	name = "berobot_dmg_handler",
	author = "HeavyIsGPS",
	description = "Handles the damage vs robots, attributes and onkill weapon stats",
	version = "1.0",
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
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
//     HookEvent("object_destroyed", Event_Object_Destroyed, EventHookMode_Post);
//     HookEvent("object_detonated", Event_Object_Detonated, EventHookMode_Post);
}

public void CvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    if(convar == g_cvCvarList[CV_bDebugMode])
        g_cv_bDebugMode = view_as<bool>(StringToInt(sNewValue));
    if(convar == g_cvCvarList[CV_flSpyBackStabModifier])
        g_CV_flSpyBackStabModifier = StringToFloat(sNewValue);
}

public void MM_OnEnabledChanged(int enabled)
{
    //PrintToChatAll("Enabled was %i", enabled);
}

// public Action Event_Object_Destroyed(Event event, const char[] name, bool dontBroadcast)
// {
//     int client = GetClientOfUserId(GetEventInt(event, "userid"));
//     //char objectype[256];
//     int building = GetEventInt(event, "index");
//     // PrintToChatAll("OBJECT DESTROYED FOR %N", client);
//     int objecttype = TF2_GetObjectType(building);
//     if (objecttype == TFObject_Sentry) {
//         // AwardFrontierCrits(client);
//     }
// }

// void AwardFrontierCrits(int client)
// {
//     if(HasFrontierJustice(client))
//     {
//             int iCrits = GetEntProp(client, Prop_Send, "m_iRevengeCrits");
//             // int Offset = FindSendPropInfo("CTFPlayer", "m_iRevengeCrits");
//             // SetEntData(client, Offset, iCrits+g_EngineerRevengeCrits[client]);
//             // SetEntProp(client, Prop_Send, "m_iRevengeCrits", iCrits+g_EngineerRevengeCrits[client]);
//             SetEntProp(client, Prop_Send, "m_iRevengeCrits", iCrits+g_EngineerRevengeCrits[client]);
            
//             // SDKCall("SetRevengeCrits", client, iCrits+g_EngineerRevengeCrits[client]);
//             int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
//             if (IsFrontierJustice(iActiveWeapon))
//             {
//                 TF2_AddCondition(client, TFCond_Kritzkrieged);
//             }


//             g_EngineerRevengeCrits[client] = 0;


//     }
// }

// public Action Event_Object_Detonated(Event event, const char[] name, bool dontBroadcast)
// {
//     int client = GetClientOfUserId(GetEventInt(event, "userid"));
//     // char objectype[64]
//     // objectype = GetEventString(event, "objecttype");
//     // PrintToChatAll("OBJECT Detonated FOR %N", client);
//     int building = GetEventInt(event, "index");
//     int objecttype = TF2_GetObjectType(building);
//     if (objecttype == TFObject_Sentry) {
//         AwardFrontierCrits(client);
//     }
// }

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (!IsAnyRobot(client))
    {
        if (HasAirStrike(client))
        {
            g_AirStrikeDamage[client] = 0.0; 

        }

        if(HasFrontierJustice(client))
        {
            g_FrontierJusticeDamage[client] = 0.0;
            
        }

    }
   // Requ
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


            if (iClassAttacker == TFClass_Soldier)
            {
                if (IsAirStrike(weapon))
                {
                    if (g_AirStrikeDamage[attacker] >= g_AirStrikeDMGRequirement)
                    {
                        IncrementHeadCount(attacker);
                        g_AirStrikeDamage[attacker] = 0.0;
                    }else
                    {
                        g_AirStrikeDamage[attacker] += damage;
                    }
                    
                }
            }

            if (iClassAttacker == TFClass_Engineer)
            {
                if (HasFrontierJustice(attacker) && IsValidEntity(inflictor))
                {

                    char AttackerObject[128];
                
                    GetEdictClassname(inflictor, AttackerObject, sizeof(AttackerObject));

                    if (StrEqual(AttackerObject, "obj_sentrygun")) {
                        //  fDamage *= 0.1;
                    
                   
                    // IncrementHeadCount(attacker);   

//                     Table: SentrygunLocalData (offset 0) (type DT_SentrygunLocalData)
//   Member: m_iKills (offset 2648) (type integer) (bits 32) (VarInt|ChangesOften)
//   Member: m_iAssists (offset 2652) (type integer) (bits 32) (VarInt|ChangesOften)

                    if (g_FrontierJusticeDamage[attacker] >= g_FrontierJusticeDMGRequirement)
                    {
                        g_EngineerRevengeCrits[attacker]++;


                        int iSentryAssists = GetEntProp(inflictor, Prop_Send, "m_iAssists");
                        
                        // PrintToChatAll("I assists %i", iSentryAssists);

                        if(iSentryAssists == -1)
                        {
                            iSentryAssists = 1;
                        }
                        // PrintToChatAll("I assists again %i", iSentryAssists+1);
                        SetEntProp(inflictor, Prop_Send, "m_iAssists", iSentryAssists+1);
                        g_FrontierJusticeDamage[attacker] = 0.0;

                    }else
                    {
                        g_FrontierJusticeDamage[attacker] += damage;
                    }

                        //PrintToChatAll("Sentry damage was %f", damage);

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
                    if(IsSandman(weapon))
                    {
                    TF2_StunPlayer(victim, 2.0, 0.85, TF_STUNFLAG_SLOWDOWN, attacker);
                    TF2_AddCondition(victim, TFCond_Sapped, 2.0, attacker);
                    }

                    if(IsWrap(weapon)){
                    TF2_StunPlayer(victim, 1.5, 0.7, TF_STUNFLAG_SLOWDOWN, attacker);
                    TF2_AddCondition(victim, TFCond_Sapped, 1.5, attacker);    
                    }
                    
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
                    TF2_StunPlayer(victim, g_ElectricStunDuration*2, 0.85, TF_STUNFLAG_SLOWDOWN, attacker);
                    TF2_AddCondition(victim, TFCond_Sapped, g_ElectricStunDuration*2, attacker);
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
                TF2_StunPlayer(victim, g_ElectricStunDuration, 0.75, TF_STUNFLAG_SLOWDOWN, attacker);
                TF2_AddCondition(victim, TFCond_Sapped, g_ElectricStunDuration, attacker);
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
                    
                //TF2_AddCondition(victim, TFCond_Sapped, 0.5, attacker);
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
                            SetEntProp(attacker, Prop_Send, "m_iDecapitations", 0);    
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
	case 528, 442, 588, 441: //Short Circuit, The Righteous Bison, Cow Mangler
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

        if (TF2_GetPlayerClass(client) == TFClass_Scout)
        {
            if (IsAllClassWeapon(Weapon3) || IsBat(Weapon3) && Weapon1 != -1 &&  Weapon2 != -1)
            {
                TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 1.5);
                TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 1.5);
                MC_PrintToChatEx(client, client, "{teamcolor}Your bat provides your other weapons with {orange}+50%% maxammo");
            }
        }
        
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

            MC_PrintToChatEx(client, client, "{teamcolor}Your rifle {orange}gains head{teamcolor} on headshot, but {orange}loses all heads{teamcolor} on bodyshot");
           
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
            MC_PrintToChatEx(client, client, "{teamcolor}Your electric weapons slow robots for {orange}-60%%% move speed{teamcolor} for %0.1f seconds on hit", g_ElectricStunDuration);
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
        if (IsAirStrike(Weapon1))
        {
            MC_PrintToChatEx(client, client, "{teamcolor}Your AirStrike {orange}gains additional clip{teamcolor} by doing %i damage to robots", RoundToNearest(g_AirStrikeDMGRequirement));
        }
        if (IsBlackBox(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "Blast radius increased", 1.25);
            MC_PrintToChatEx(client, client, "{teamcolor}Your Blackbox has {orange}+25%% larger explosion radius");
        }

        if (isBeggarsBazooka(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "mult_player_movespeed_active", 1.15);
            MC_PrintToChatEx(client, client, "{teamcolor}Your Beggars Bazooka provides {orange}+15%% faster move speed while active");
        }

        if (isLibertyLauncher(Weapon1))
        {
            if (IsAnyBanner(Weapon2))
            {
                TF2Attrib_SetByName(Weapon2, "increase buff duration", 1.25);
                MC_PrintToChatEx(client, client, "{teamcolor}Your Liberty Launcher provides your banners {orange}+25%% longer buff duration{teamcolor}");
            }else
            {
                MC_PrintToChatEx(client, client, "{teamcolor}Your Liberty Launcher provides your banners {orange}equip a banner to get the buff!");
            }
        }

        if (IsRocketLauncher(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "deploy time decreased", 0.75);
            MC_PrintToChatEx(client, client, "{teamcolor}Your Rocket Launcher provides you {orange}+25%% faster weapon switch speed{teamcolor}");
        }

        if (HasFrontierJustice(client))
        {
            MC_PrintToChatEx(client, client, "{teamcolor}Your Frontier Justice {orange}gains revenge crits{teamcolor} based on damage it deals. %i damage pr crit. Awarded upon sentry desctruction", RoundToNearest(g_FrontierJusticeDMGRequirement));
        }

        if (IsShotGun(Weapon1))
        {
            SetShotGunStats(Weapon1, client);
        }
        if (IsShotGun(Weapon2))
        {
            SetShotGunStats(Weapon2, client);
        }

        if(IsSandman(Weapon3))
        {
            MC_PrintToChatEx(client, client, "{teamcolor}Your Baseball {orange}reduces robots move speed by -85%{teamcolor} for 2 seconds on hit");
        }
        if(IsWrap(Weapon3))
        {
            MC_PrintToChatEx(client, client, "{teamcolor}Your Ornament {orange}reduces robots move speed by -70%{teamcolor} for 1.5 seconds on hit");
        }

    }

    

}
    
    

void SetShotGunStats(int weapon, int client)
{
    TF2Attrib_SetByName(weapon, "projectile penetration", 1.0);
    MC_PrintToChatEx(client, client, "{teamcolor}Your Shotgun {orange}penetrates through enemies{teamcolor}");
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

bool IsFrontierJustice(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other Frontier are added add here
	case 141, 1004: 
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

bool HasAirStrike(int client)
{

    int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other airstrikes are added, add here
	case 1104: 
		{
			return true;
		}
	}
	return false;
}

bool HasFrontierJustice(int client)
{

    int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other Frontier are added add here
	case 141, 1004: 
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

bool IsAirStrike(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other airstrikes are added, add here
	case 1104: 
		{
			return true;
		}
	}
	return false;
}

bool IsBlackBox(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other blackbox are added, add here
	case 1085, 228: 
		{
			return true;
		}
	}
	return false;
}

bool isBeggarsBazooka(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other Beggarbazooka are added, add here
	case 730: 
		{
			return true;
		}
	}
	return false;
}


bool isLibertyLauncher(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other Beggarbazooka are added, add here
	case 414: 
		{
			return true;
		}
	}
	return false;
}

bool IsAnyBanner(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other Beggarbazooka are added, add here
	case 1001, 226, 129, 354: 
		{
			return true;
		}
	}
	return false;
}

bool IsRocketLauncher(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other Beggarbazooka are added, add here
	case 18,205,237,513,658,800,809,889,898,907,916,965,974,108,110,1500,1501,1502,1504,1505,1508,1510,1512,1513,1515: 
		{
			return true;
		}
	}
	return false;
}

bool IsAllClassWeapon(int weapon){
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other allclass are added, add here
	case 264,423,474,880,939,954,1013,1071,1123,1127,30758: 
		{
			return true;
		}
	}
	return false;
}

bool IsBat(int weapon){
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other allclass are added, add here
	case 0, 190, 660, 30667: 
		{
			return true;
		}
	}
	return false;
}

bool IsShotGun(int weapon){
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other shotguns are added, add here
	case 9,10,11,12,199,415,425,1141,1153,15003,15016,15044,15047,15085,15109,15132,15133,15152: 
		{
			return true;
		}
	}
	return false;
}

bool IsSandman(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other sandman are added, add here
	case 44: 
		{
			return true;
		}
	}
	return false;
}

bool IsWrap(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other wrap are added, add here
	case 648: 
		{
			return true;
		}
	}
	return false;
}

// 



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

// 