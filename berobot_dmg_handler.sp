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
#include <morecolors>
#include <tf_custom_attributes>
#include <sdktools>
#include <stocksoup/tf/tempents_stocks>
#include <stocksoup/datapack>
#include <smlib>
// #include <addplayerhealth>


// #include <berobot_constants>
// #include <berobot>
// #include <berobot_core_restrictions>
// #include <morecolors>
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

int Punch_Count[MAXPLAYERS + 1] = {0, ...};
int Timer_Punch_Count[MAXPLAYERS + 1] = {0, ...};
bool g_Timer[MAXPLAYERS + 1] = {false, ...};

int g_Eyelander_Counter[MAXPLAYERS + 1] = {0, ...};

float g_AirStrikeDamage[MAXPLAYERS +1] = {0.0, ...};
float g_AirStrikeDMGRequirement = 250.0;
float g_ElectricStunDuration = 5.0;
float g_HealDebuff = 0.5;

float g_FrontierJusticeDamage[MAXPLAYERS + 1] = {0.0, ...};
float g_FrontierJusticeDMGRequirement = 250.0;
int g_EngineerRevengeCrits[MAXPLAYERS + 1] = {0, ...};

//bool g_Enabled;

float g_Attribute_Display_CollDown = 10.0;
float g_Attribute_Display[MAXPLAYERS + 1] = {0.0, ...};
bool b_Attribute_Display[MAXPLAYERS + 1] = {true, ...};

 float g_bleed_duration_bonus = 10.0;

float g_axtinguisherspeedboost = 5.0;
float g_axtinguisherbuffduration = 5.0;

int g_powerjackhealonhit = 50;
int g_powerjackhealonhitoverheal = 260;

float g_blutsauger_heal_reduction = 0.35;
float g_blutsauger_heal_reduction_duration = 1.0;

float g_spycicle_fire_speed_debuff = 0.7;
float g_spycicle_fire_Speed_debuff_duration = 6.0;

float g_market_gardner_dmg_bonus = 1.5;

int g_warriorspirit_heal_on_hit = 50;
int g_warriorspirit_max_overheal = 450;

float g_kgb_crit_combo_duration = 6.0;

float g_protection_rune_duration = 1.0;

float g_electric_rage_reduction = 5.0;

float g_HumanMiniGunDmGPenalty = 0.8;

float g_wrap_duration = 5.0;

float g_crit_a_cola_duration = 2.0;

#define SPY_ROBOT_STAB	"weapons/saxxy_impact_gen_01.wav"
// #define SPY_ROBOT_STAB	")mvm/giant_demoman/giant_demoman_grenade_shoot.wav"

int ParticleStorage[MAXPLAYERS + 1] = {0, ...};

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
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("crossbow_heal", Event_Crossbow_Heal, EventHookMode_Post);
    RegConsoleCmd("sm_mminfo", Command_ToggleMMHumanDisplay, "Toggle Manned Machines Stats Display for humans");
    
//     HookEvent("object_destroyed", Event_Object_Destroyed, EventHookMode_Post);
//     HookEvent("object_detonated", Event_Object_Detonated, EventHookMode_Post);


}

public Action Event_PlayerDeath(Event event, char[] name, bool dontBroadcast){

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client)){ 
		DeleteParticle(0.1, ParticleStorage[client]);
	}
	return Plugin_Continue;
}

public void OnMapStart()
{
    PrecacheSound(SPY_ROBOT_STAB);
}

public Action Command_ToggleMMHumanDisplay(int client, int args)
{
    if(b_Attribute_Display[client])
    {
        b_Attribute_Display[client] = false;
        MC_PrintToChatEx(client, client, "{orange}Chat Display of stats: off");
    }else
    {
        b_Attribute_Display[client] = true;
        MC_PrintToChatEx(client, client, "{orange}Chat Display of stats: on");
    }
    return Plugin_Continue;
}

public void CvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    if(convar == g_cvCvarList[CV_bDebugMode])
        g_cv_bDebugMode = view_as<bool>(StringToInt(sNewValue));
    if(convar == g_cvCvarList[CV_flSpyBackStabModifier])
        g_CV_flSpyBackStabModifier = StringToFloat(sNewValue);
}

// public void MM_OnEnabledChanged(int enabled)
// {
//     //PrintToChatAll("Enabled was %i", enabled);
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
        int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
        if (IsSunOnAStick(Weapon3))
        {
            TF2CustAttr_SetString(client, "Spell-Caster", "Spell=0 Cooldown=40.0");
        }else
        {
            TF2CustAttr_SetString(client, "Spell-Caster", "Spell=-1 Cooldown=40.0");
        }

        if(HasFrontierJustice(client))
        {
            g_FrontierJusticeDamage[client] = 0.0;
            
        }

        if(TF2_GetPlayerClass(client) == TFClass_Scout)
        {
            TF2CustAttr_SetString(client, "faster-respawn", "respawn=8.0");
        }
    }
}


float g_Razorback_Original_Recharge = -1.0;
float g_Razorback_Original_Recharge_Robot_Hit = 0.2;
//Damage Related functions
/* Plugin Exclusive Functions */
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{

    
    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
     return Plugin_Continue;   
    //     if(IsAnyRobot(victim) && damagetype == DMG_FALL && !IsBoss(victim))
    //     {
    //     damage *= 0.25;
    //     return Plugin_Changed;
    //     }
    //     return Plugin_Continue;
    // }

		if(damagecustom == TF_CUSTOM_RUNE_REFLECT)
		{
		// PrintToChatAll("damage before change %f", damage);	
		damage *= 0.4;
		// PrintToChatAll("damage after change %f", damage);	
		//critType = CritType_None;
		damageForce[0] == -10.0;
		damageForce[1] == -10.0;
		damageForce[2] == -10.0;
		return Plugin_Handled;
		}
	

        if (damagecustom == TF_CUSTOM_PLASMA)
        {
            // PrintToChatAll("PLASMA");
            if(TF2_GetPlayerClass(attacker) == TFClass_Heavy || TF2_GetPlayerClass(attacker) == TFClass_Medic){
                // PrintToChatAll("For heavy or medic TF_CUSTOM_PLASMA dmg was %f", damage);
                damage = 0.0;
                
                // PrintToChatAll("%f", GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter"));
                return Plugin_Changed;
                
                
            }
        }

        // if (IsElectric(weapon))
        // {
        //     PrintToChatAll("WAS ELECTRIC");
        // }

        if(IsAnyRobot(victim))
        {
            if (TF2_GetPlayerClass(attacker) == TFClass_DemoMan)
            {
                if (IsCaber(weapon))
                {
                    // int Detonated = GetEntProp(weapon, Prop_Send, "m_iDetonated");// PrintToChatAll("Removing Bonus"); //Removes the damage bonus from caber after use, in case of ubered players
                    // PrintToChatAll("Detonated %i", Detonated);
                    TF2Attrib_RemoveByName(weapon, "damage bonus");
                }
            }

            if (TF2_GetPlayerClass(attacker) == TFClass_Medic)
            {
                if (IsBlutsauger(weapon))
                {
                    // int Detonated = GetEntProp(weapon, Prop_Send, "m_iDetonated");// PrintToChatAll("Removing Bonus"); //Removes the damage bonus from caber after use, in case of ubered players
                    // PrintToChatAll("Detonated %i", Detonated);
                    SetHealingDebuff(victim, g_blutsauger_heal_reduction, g_blutsauger_heal_reduction_duration, attacker);

                    // TF2Attrib_AddCustomPlayerAttribute(victim, "reduced_healing_from_medics", g_blutsauger_heal_reduction, g_blutsauger_heal_reduction_duration);
                }
            }

            if(TF2_IsPlayerInCondition(victim, TFCond_Stealthed))
            {
                
                if (damagecustom == TF_CUSTOM_BLEEDING || IsElectric(weapon))
                {
                    TF2_RemoveCondition(victim, TFCond_Stealthed);
                }        //Code to remove stealthed from burning and bleeding

            }
        }

    
        if(!IsAnyRobot(victim))
        {

            //     //m_flItemChargeMeter
            // float data = GetEntPropFloat(victim, Prop_Send, "m_flItemChargeMeter");
            // PrintToChatAll("Data %f", data);
            // PrintToChatAll("Damagetype was %i\nWeapon was %i\n Damagecustom was %i", damagetype, weapon, damagecustom);
             switch (damagecustom)
                {
                    case TF_CUSTOM_BACKSTAB:
                    {
                        // PrintToChatAll("BACKSTAB 0!");
                        int razorback = FindTFWearable(victim, 57);
                        if(IsValidEntity(razorback))
                        {
                            // PrintToChatAll("%N had razorback when stabbed", victim);

                            // PrintToChatAll("Charge was before  %f", g_Razorback_Original_Recharge);
                            Address rstats;
                            if (g_Razorback_Original_Recharge == -1.0){
                            
                            // PrintToChatAll("Finding item_meter");

                            rstats = TF2Attrib_GetByName(razorback, "item_meter_charge_rate");
                            g_Razorback_Original_Recharge = TF2Attrib_GetValue(rstats);

                            }
                            // PrintToChatAll("Charge was after %f", g_Razorback_Original_Recharge);
                            if (IsAnyRobot(attacker) && !IsBoss(attacker))
                            {
                                TF2Attrib_SetByName(razorback, "item_meter_charge_rate", g_Razorback_Original_Recharge_Robot_Hit);
                                TF2_StunPlayer(attacker, 0.5, 0.0, TF_STUNFLAG_BONKSTUCK, attacker);
                                TF2_AddCondition(attacker, TFCond_Sapped, 0.5, attacker);
                            }else
                            {
                                if(g_Razorback_Original_Recharge != -1.0)TF2Attrib_SetByName(razorback, "item_meter_charge_rate", g_Razorback_Original_Recharge);
                            }
                            // TF2Attrib_AddCustomPlayerAttribute(victim, "item_meter_charge_rate", 0.1, 5.0);
                        }
                    }

                }
          }

    if(IsAnyRobot(victim) && !IsAnyRobot(attacker))
    {

        TFClassType iClassAttacker = TF2_GetPlayerClass(attacker);

            if (iClassAttacker == TFClass_Pyro)
            {
                if(IsAxtinguisher(weapon) && TF2_IsPlayerInCondition(victim, TFCond_OnFire))
                {
                 //   PrintToChatAll("Target on fire");
                    TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, g_axtinguisherspeedboost);
                    TF2_AddCondition(attacker, TFCond_DefenseBuffed, g_axtinguisherspeedboost);
                    // TF2_AddCondition(attacker, TFCond_CritCanteen, 3.0);
                    
                }

                if(IsPowerJack(weapon))
                {
                
                AddPlayerHealth(attacker, g_powerjackhealonhit, g_powerjackhealonhitoverheal, true, true);
                // ShowHealthGain(attacker, 50, attacker);
                }

                if(IsScorch(weapon) && damagecustom == 0)
                {
                    
                    // PrintToChatAll("Hit with Scorch %i",damagecustom);
                    RequestFrame(ChangeKnockBack,victim);

                }

            }

             if (iClassAttacker == TFClass_Heavy)
            {
                if(IsWarriorSpirit(weapon))
                {           

                    AddPlayerHealth(attacker, g_warriorspirit_heal_on_hit, g_warriorspirit_max_overheal, true, true);
                    // ShowHealthGain(attacker, 50, attacker);
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
			
			CreateTimer(2.0, Combo_Check_Timer, attacker);
			Timer_Punch_Count[attacker] = Punch_Count[attacker];
			
			g_Timer[attacker] = true;
			}
		
		
			
		//Combo_Stopper(attacker);
		
		if (Punch_Count[attacker] > 2)
		{
			Combo_Stopper(attacker);
            
            TF2_AddCondition(attacker, TFCond_CritCanteen, g_kgb_crit_combo_duration, attacker);
		}

		}
                    



            }

            // if (iClassAttacker == TFClass_Medic)
            // {
            //     int Weapon3 = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);

            //     if(IsSolemnVow(Weapon3))
            //     {
            //         damage = 0.0;
            //         return Plugin_Handled;
            //     }
                
            // }

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

            // if (iClassAttacker == TFClass_Sniper)
            // {
            //     if (IsSMG(weapon))
            //     {
            //         TF2_StunPlayer(victim, 0.1, 0.6, TF_STUNFLAG_SLOWDOWN, attacker);
            //         TF2_AddCondition(victim, TFCond_Sapped, 0.1, attacker);    
            //     }
            // }

            if (iClassAttacker == TFClass_DemoMan)
            {
                if (IsLooseCannon(weapon))
                {
                   RequestFrame(ChangeKnockBack, victim);
                }
            }

            if (iClassAttacker == TFClass_Engineer)
            {
                if (IsValidEntity(inflictor))
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
                        AddPlayerHealth(attacker, 120, 275, true);
                    }

                    if (HasDiamondback(attacker)) //Diamondback gives 2, has to be+2 for some reason crits on backstab
                    {
                    int iCrits = GetEntProp(attacker, Prop_Send, "m_iRevengeCrits");

                    SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", iCrits+2);
                        
                    }

                    if (IsBigEarner(weapon))
                    {
                        TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);
                    }

                    if(IsSpycicle(weapon))
                    {
                        TF2Attrib_AddCustomPlayerAttribute(victim, "damage penalty", g_spycicle_fire_speed_debuff, g_spycicle_fire_Speed_debuff_duration);
                        //TF2_StunPlayer(victim, 1.0, 0.85, TF_STUNFLAG_SLOWDOWN, attacker);
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

                    
                    



                    //Do backstab modifying
                    if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);

                    int victimHP = GetClientHealth(victim);
                    int victimMAXHP = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
                    int victimHPpercent = RoundToNearest(float(victimHP) / float(victimMAXHP) * 100);

                    // PrintToChatAll("victimHP %i, MAXHP %i", victimHP, victimMAXHP);
                    
                    
                    if (victimHPpercent >= 80){

                        //Code for dynamic damage, but doesn't work well with vulnerabilities
                        // PrintToChatAll("percent %i", victimHPpercent);
                        // damage = (float(victimMAXHP) / 4.0) / 3.0;

                        // if (damage > 1250.0)
                        // {
                        //     damage = 1250.0;
                        // }
                     damage = g_CV_flSpyBackStabModifier * 2.0;
                    }else{
                    
                    damage = g_CV_flSpyBackStabModifier;    


                    }
                    
                    //Bonus dmg vs heavies
                    if (TF2_GetPlayerClass(victim) == TFClass_Heavy)
                    {
                        damage *= 1.2;
                    }

                    critType = CritType_Crit;
                    if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                    TF2_AddCondition(attacker, TFCond_RuneResist, g_protection_rune_duration);
                    // EmitSoundToAll(SPY_ROBOT_STAB, victim);
                    // EmitSoundToClient(victim, SPY_ROBOT_STAB);
                    return Plugin_Changed;
                }

                switch (damagecustom)
                {
                    case TF_CUSTOM_TAUNT_HIGH_NOON, TF_CUSTOM_TAUNT_GRAND_SLAM, 
                    TF_CUSTOM_TAUNT_FENCING, TF_CUSTOM_TAUNT_ARROW_STAB, TF_CUSTOM_TELEFRAG,
                    TF_CUSTOM_TAUNT_BARBARIAN_SWING, TF_CUSTOM_TAUNT_UBERSLICE, 
                    TF_CUSTOM_TAUNT_ENGINEER_SMASH, TF_CUSTOM_TAUNT_ENGINEER_ARM, TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,
                    TF_CUSTOM_TAUNTATK_GASBLAST:
                    {
                        damage *= 2.5;
                        return Plugin_Changed;
                    }
                    case TF_CUSTOM_TAUNT_GRENADE:
                    {
                        damage *= 3.5;
                        return Plugin_Changed;
                    }
                    case TF_CUSTOM_TAUNT_HADOUKEN:
                    {
                        damage *= 3.0;
                        return Plugin_Changed;
                    }
                }

                if (!IsBoss(victim) && IsAnyRobot(victim))
                {
                    switch (damagecustom)
                    {
                        case TF_CUSTOM_CHARGE_IMPACT, TF_CUSTOM_BOOTS_STOMP:
                        {
                            damage *= 2.0;
                            if (IsTank(victim))
                            {
                                float stun_duration = 0.6;
                                TF2_StunPlayer(victim, stun_duration, 0.0, TF_STUNFLAG_NOSOUNDOREFFECT|TF_STUNFLAG_BONKSTUCK, attacker);
                                // TE_TFParticleEffectAttachment("bot_radio_waves", victim, PATTACH_POINT_FOLLOW, "head");
                                // SetHealingDebuff(victim, g_HealDebuff, 0.5, attacker);                                  
                                
                                // if (TF2_GetClientTeam(iBuilder) == TFTeam_Blue)
                                // {
                                
                                
                                
                                // int attachHead = LookupEntityAttachment(victim, "head");
                                
                                // if (attachHead) {
                                //     int particle = TE_SetupTFParticleEffect("bot_radio_waves", NULL_VECTOR, .entity = victim,
                                //     .attachType = PATTACH_POINT_FOLLOW, .attachPoint = attachHead);
                                //     TE_SendToAll();
                                    
                                    // PrintToChatAll("Particle Was %i", particle);
                                    
                                    CreateParticle(victim, "bot_radio_waves", stun_duration+0.4);
                                    // DataPack data;
                                    // CreateDataTimer(stun_duration, RemoveStunEffect, data, TIMER_FLAG_NO_MAPCHANGE);
                                    // data.WriteCell(particle);
                                    // data.WriteCell("bot_radio_waves");
                                    
                                 
                            }
                            DizzyTarget(victim);
                            return Plugin_Changed;
                        }
                        case TF_CUSTOM_BASEBALL:
                        {
                            if(IsSandman(weapon))
                            {
                                // SetHealingDebuff(victim, g_HealDebuff, 0.5, attacker);  
                                DizzyTarget(victim);

                            }

                            if(IsWrap(weapon)){
                                SetHealingDebuff(victim, g_HealDebuff, g_wrap_duration, attacker);  
                            }


                            
                            return Plugin_Changed;
                        }
                    }
                }
    }

    return Plugin_Continue;
}

stock void CreateParticle(int ent, char[] particleType, float time)
{

	//int iWeapon = GetPlayerWeaponSlot(ent, TFWeaponSlot_Secondary);
	int particle = CreateEntityByName("info_particle_system");

	char name[64];

	if (IsValidEdict(particle))
	{
	
		//Delete existing particle if it's already there
		//CreateTimer(0.0, DeleteParticle, particle);
		
		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		
		position[0] += 0.0;
		position[1] += 0.0;
		position[2] += 0.0; //z
		
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", name);
		DispatchKeyValue(particle, "effect_name", particleType);
		
		
		//DispatchKeyValue(particle, "angles", "90.0 90.0 0.0"); 
		DispatchSpawn(particle);
		// SetVariantString(name);
		
		// AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		//if team blue - use player_glowblue
		//if team red use - player_glowred
		
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		
		
		SetVariantString("head");
		AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
		
		DispatchKeyValue(particle, "targetname", "present");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticle, particle);
		ParticleStorage[ent] = particle;
	}
}

public Action DeleteParticle(Handle timer, any particle)
{
	if (IsValidEntity(particle))
	{
		char classN[64];
		GetEdictClassname(particle, classN, sizeof(classN));
		if (StrEqual(classN, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
}



void DizzyTarget (int victim)
{
     float angles[3];
                            GetClientEyeAngles(victim, angles);

    // Generate a random value
    float randomAngleSideways = GetRandomFloat(20.0, 30.0);
    float randomAngleUpDown = GetRandomFloat(10.0,20.0);

    // Make the value either positive or negative
    if (GetRandomInt(0,1) == 1)
    {
        randomAngleSideways *= -1.0;
    }

    if (GetRandomInt(0,1) == 1)
    {
        randomAngleUpDown *= -1.0;
    }
    
    // Apply the random adjustment to the yaw angle
    angles[1] += randomAngleSideways;
    angles[0] += randomAngleUpDown;

    // Ensure the yaw angle stays within the valid range
    // while (angles[1] >= 360.0)
    // {
    // angles[1] -= 360.0;
    // }
    // while (angles[1] < 0.0)
    // {
    // angles[1] += 360.0;
    // }

    // while (angles[0] >= 360.0)
    // {
    // angles[0] -= 360.0;
    // }
    // while (angles[0] < 0.0)
    // {
    // angles[0] += 360.0;
    // }


    TeleportEntity(victim, NULL_VECTOR, angles, NULL_VECTOR);
}

void ChangeKnockBack (int victim)
{
                        // PrintToChatAll("WAS LOOSE CANNON %");
                    float vOrigin[3], vAngles[3], vForward[3], vVelocity[3];
                    GetClientEyePosition(victim, vOrigin);
                    GetClientEyeAngles(victim, vAngles);
                    
                    // Get the direction we want to go
                    GetAngleVectors(vAngles, vForward, NULL_VECTOR, NULL_VECTOR);
                    
                    // make it usable
                    float flDistance = 50.0;

                    ScaleVector(vForward, flDistance);	
                    
                    // add it to the current velocity to avoid just being able to do full 180s
                    GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vVelocity);
                    AddVectors(vVelocity, vForward, vVelocity);
                    
                    // float flDistanceVertical = 10.0;
                        
                    // vVelocity[2] -= flDistanceVertical; // we always want to go a bit up
                    
                    // And set it
                   TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vVelocity);
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
    // SetEntProp(iClient, Prop_Send, "m_iDisguiseTargetIndex", iTarget);

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
    
       

    if(IsAnyRobot(victim))
    {
    TFClassType iClassAttacker = TF2_GetPlayerClass(attacker);
            switch(damagecustom){
                case TF_CUSTOM_PLASMA_CHARGED: 
                {
                    damage *= 1.5;
                    // TF2_StunPlayer(victim, g_ElectricStunDuration*2, 0.85, TF_STUNFLAG_SLOWDOWN, attacker);
                    TF2_AddCondition(victim, TFCond_HealingDebuff, g_ElectricStunDuration*2, attacker);
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
                    damage *= g_HumanMiniGunDmGPenalty;
                    if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                    return Plugin_Changed;
                    
                }
                    
                    
            }

            if (IsElectric(weapon))
            {
                TF2_AddCondition(victim, TFCond_HealingDebuff, g_ElectricStunDuration, attacker);

                SetHealingDebuff(victim, g_HealDebuff, g_ElectricStunDuration, attacker);

                if(TF2_GetPlayerClass(victim) == TFClass_Heavy || TF2_GetPlayerClass(victim) == TFClass_Medic)
                {
                    // PrintToChatAll("WAS HEAVY OR MEDIC");
                    if(HasEntProp(victim, Prop_Send, "m_flRageMeter"))
                    {
                        

                        float currentrage = GetEntPropFloat(victim, Prop_Send, "m_flRageMeter");
                        
                        if (GetEntProp(victim, Prop_Send, "m_bRageDraining"))
                        {
                            // PrintToChatAll("RAGE %f: Draining %i", rage, ragedraining);

                            SetEntPropFloat(victim, Prop_Send, "m_flRageMeter", currentrage - g_electric_rage_reduction);
                        }
                        
                    }
                }
            }
            
            if (iClassAttacker == TFClass_DemoMan && !IsAnyRobot(attacker))
            {

                if(IsEyelander(weapon)) IncrementHeadCount(attacker);


                // if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);
                // damage *= 1.25;
                // if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                // return Plugin_Changed;
                
                    
            }


            if (iClassAttacker == TFClass_Soldier && TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping))
            {
                //int iWeapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);

                    
                if (IsMarketGardner(weapon))
                {
                    
                    if(g_cv_bDebugMode)PrintToChatAll("Damage before change %f", damage);
                    damage *= g_market_gardner_dmg_bonus;
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
                        if (decapitations == 0 || decapitations == 1)
                        {
                            SetEntProp(attacker, Prop_Send, "m_iDecapitations", 0);    
                        }else
                        {
                            SetEntProp(attacker, Prop_Send, "m_iDecapitations", decapitations - 2);    
                        }
                        
                    }
                    decapitations = GetEntProp(attacker, Prop_Send, "m_iDecapitations");
                    TF2Attrib_SetByName(weapon, "faster reload rate", calculateReloadSpeed(decapitations));

                }

                if (IsHeatmaker(weapon))
                {
                    float chargelevel = GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage");
                    float add = 35 + (chargelevel / 10);
                    float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");

                    if (TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
                    {
                        add /= 4;
                        RequestFrame(HeatmakerRage, attacker);
                    }
                    SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage + add > 100) ? 100.0 : rage + add);
                    // float nextragetime = GetEntPropFloat(attacker, Prop_Send, "m_flNextRageEarnTime");
                    
                }
            }

        //Check for crit conditions to add more damage on minicrit conditions stacked against robots
        int condcount = 0;
        
        if(TF2_IsPlayerInCondition(victim, TFCond_Jarated)) condcount++;
        if(TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeath)) condcount++;
        if(TF2_IsPlayerInCondition(attacker, TFCond_Buffed)) condcount++;
        if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola)) condcount++;
        

            if (condcount >= 2)
            {
            float condmodifier = 1.0;
                switch(condcount)
                {
                    case 2: 
                    {
                        condmodifier = 1.05;
                    }
                    case 3: 
                    {
                        condmodifier = 1.1;
                    }
                    case 4: 
                    {
                        condmodifier = 1.15;
                    }
                }

            // PrintToChatAll("Condcount was %i with %N and %N", condcount, victim, attacker);
            /* if (critType != CritType_Crit) */ damage = damage*condmodifier;
            return Plugin_Changed; 
            }

        
    }
    return Plugin_Continue;
}
//Code to handle Heatmaker running out of juice while still having more meter
public void HeatmakerRage(int attacker)
{
    float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");

    if (TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
    {
        TF2_AddCondition(attacker, TFCond_FocusBuff, rage / 10.0);
    }
}

float calculateReloadSpeed(int heads) {
    float baseReloadSpeed = 1.0;
    float a = 0.025; // Adjust this value based on your preference
    
    float reloadSpeed = 1.0 / (1.0 + a * heads * heads);
    return baseReloadSpeed * reloadSpeed;
}
// float g_Attribute_Display_CollDown[MAXPLAYERS + 1] = 10.0;
// float g_Attribute_Display [MAXPLAYERS + 1] = 0.0;

void DisplayMMStats(int client, char[] chat_display)
{
    if (g_Attribute_Display[client] < GetEngineTime() && b_Attribute_Display[client] && !strlen(chat_display) < 1)
    {
        MC_PrintToChatEx(client, client, "{teamcolor}Custom Buffs: Type {orange}!mystats to see your stats");
        MC_PrintToChatEx(client, client, chat_display);
        MC_PrintToChatEx(client, client, "{teamcolor}Type {orange}/mminfo {teamcolor}to toggle this information on/off");
        g_Attribute_Display[client] = GetEngineTime() + g_Attribute_Display_CollDown;
    }
}

// void AddBonusCrit(int attacker)
// {
 
// }
//Functions to handle attributes for humans
public Action Event_post_inventory_application(Event event, const char[] name, bool dontBroadcast)
{

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    //CreateTimer(0.8, AddAttributes, client);




    if (!IsAnyRobot(client) && IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) != GetRobotTeam())
    {
        int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
        int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
        int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
        //Temporary Stats to be used in displaying in the text
        float stat1;
        float stat2;
        float stat3;
        char chat_display[512];

        if (TF2_GetPlayerClass(client) == TFClass_Pyro)
        {
            if(Weapon1 != -1)
            {
            stat1 = 0.85;
            TF2Attrib_SetByName(Weapon1, "dmg taken from fire reduced", stat1);
            
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Pyro: {orange}+%0.0f%%%% fire resistance",chat_display, LessIsMore(stat1));
            }
            
            if(IsThirdDegree(Weapon3))
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Third Degree: {orange}Crits players who are healed. Hits all players connected to the same heal source",chat_display);
                
                TF2CustAttr_SetString(Weapon3,"third-degree", "critType=2 hitGroup=1");
                // TF2CustAttr_GetAttributeKeyValues();
                // TF2CustAttr_SetInt(Weapon3, "critType", 2);
                // TF2CustAttr_SetInt(Weapon3, "hitGroup", 1);
                // TF2CustAttr_SetString(Weapon3, "third-degree", "critType=2 hitGroup=1")
            }
            if (IsAxtinguisher(Weapon3))
            {
                
                // TF2Attrib_SetByName(Weapon3, "crit vs burning players", 1.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Axtinguisher: {orange}Provides %0.0f second speed boost{teamcolor} and {orange}%0.0f seconds of Battalion Backup buff",chat_display, g_axtinguisherspeedboost, g_axtinguisherbuffduration);

            }

            if (IsPowerJack(Weapon3))
            {
                
                // TF2Attrib_SetByName(Weapon3, "crit vs burning players", 1.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Powerjack: {orange}Provides %i heal on hit {teamcolor}that overheals",chat_display, g_powerjackhealonhit);

            }


        }
        if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
        {
       
            if (IsDemoKnight(Weapon1, Weapon2))
            {
                stat1 = 0.75;

                TF2Attrib_SetByName(Weapon3, "dmg taken from bullets reduced",stat1);
                TF2Attrib_SetByName(Weapon3, "dmg taken from crit reduced", stat1);
                TF2Attrib_SetByName(Weapon3, "dmg from melee increased", stat1);
                TF2Attrib_SetByName(Weapon3, "fire rate bonus", stat1);
                //Math to fix the correct display from ratio
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Demoknight: Melee weapon {orange}+%0.0f%%%% bullet, melee, crit damage resistance and attack speed bonus",chat_display, OneIs100(stat1));
       


            }else
            {
                
                TF2Attrib_RemoveByName(Weapon3, "dmg taken from bullets reduced");
                TF2Attrib_RemoveByName(Weapon3, "dmg taken from crit reduced");
                TF2Attrib_RemoveByName(Weapon3, "dmg from melee increased");
                TF2Attrib_RemoveByName(Weapon3, "fire rate bonus");

                stat1 = 0.70;
                if (Weapon1 != -1)
                {
                    TF2Attrib_SetByName(Weapon1, "Reload time decreased", stat1);
                 //   SetDemoDamageBuff(Weapon1);
                    
                }

                if (Weapon2 != -1)
                {
                    TF2Attrib_SetByName(Weapon2, "Reload time decreased", stat1);
                   // SetDemoDamageBuff(Weapon2);
                    
                }
                stat1 = 1.0-stat1;
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Demoman: All of projectile weapons {orange}Reload %0.0f%%%% faster\n{teamcolor}Melee weapons {orange}more damage{teamcolor} the more damage you do",chat_display, OneIs100(stat1));
            }

            if (Weapon3 != -1)
            {
                SetDemoDamageBuff(Weapon3);
            }

            if (IsQuickieBombLauncher(Weapon2))
            {
                stat1 = 1.65;
                TF2Attrib_SetByName(Weapon2, "stickybomb_charge_damage_increase", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}QuickeBomb: {orange}+%0.0f%%%% {teamcolor}charge damage increase",chat_display, MoreIsMore(stat1));
            }

            if(IsIronBomber(Weapon1))
            {
                stat1 = 5.0;
                stat2 = 5.0;
                stat3 = 3.0;
                TF2Attrib_SetByName(Weapon1, "auto fires full clip all at once", 1.0);
                TF2Attrib_SetByName(Weapon1, "projectile spread angle penalty", stat1);
                TF2Attrib_SetByName(Weapon1, "Reload time increased", stat2);
                TF2Attrib_SetByName(Weapon1, "single wep deploy time increased", stat3);
                
                TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
                
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}IronBomber: {orange}Fires full clip at once, {teamcolor}& {orange}+%0.0f%%%% {teamcolor}slower reload rate, {orange}%0.0f%%%% degrees less accurate and deploys %0.0f%%%% slower",chat_display, MoreIsMore(stat2), MoreIsMore(stat1), MoreIsMore(stat3));
            }
            
            if (IsClaid(Weapon3))
            {
                stat1 = 2.0;
                TF2Attrib_SetByName(Weapon3, "speed_boost_on_hit", stat1);
                TF2Attrib_SetByName(Weapon3, "charge time increased", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Claid: {orange}+%0.0f%%%% {teamcolor}charge time increase, {orange}+%0.0f second speed boost {teamcolor}on hit",chat_display, stat1, stat1);
            }
            if (IsStockOrAllClassWeapon(Weapon3))
            {
                stat1 = 20.0;
                TF2Attrib_SetByName(Weapon3, "max health additive bonus", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Melee: {orange}+%0.0f max health",chat_display, stat1);
            }   
            if (IsCaber(Weapon3))
            {
                stat1 = 2.0;
                
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Caber: {orange}%0.0f% increased damage bonus{teamcolor}",chat_display, OneIs100(stat1));
                TF2Attrib_SetByName(Weapon3, "damage bonus", stat1);
                TF2Attrib_SetByName(Weapon3, "crits_become_minicrits", 1.0);
                
                // TF2Attrib_SetByName(Weapon3, "blast dmg to self increased", 1000.0);
            }

            if (IsSkullCutter(Weapon3))
            {
                stat1 = 1.35;
                
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Skullcutter: {orange}%0.0f%%%% increased damage bonus{teamcolor}",chat_display, MoreIsMore(stat1));
                TF2Attrib_SetByName(Weapon3, "damage bonus", stat1);
            }

            if (IsEyelander(Weapon3))
            {

                //attribute "add head on hit"//
                g_Eyelander_Counter[client] = 0;
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Eyelander: {orange}Gain a head every hit{teamcolor} vs robots",chat_display);
            }

            
        }

        if (TF2_GetPlayerClass(client) == TFClass_Heavy)
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Your minigun deals {orange}-%0.00f %%%% damage{teamcolor} vs robots",chat_display, LessIsMore(g_HumanMiniGunDmGPenalty));

            if(IsNatascha(Weapon1))
            {
                stat1 = 3.0;
                stat2 = 1.2;
                TF2Attrib_SetByName(Weapon1, "speed_boost_on_hit", stat1);
                TF2Attrib_SetByName(Weapon1, "aiming movespeed increased", stat2);
                
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Heavy Natascha: {orange}+%0.0f second speed boost on hit +%0.0f %%%% faster movespeed while spun up{teamcolor}",chat_display, stat1, MoreIsMore(stat2));
            }

            if(IsTomiSlav(Weapon1))
            {
                stat1 = 0.4;
                stat2 = 1.0;
                TF2Attrib_SetByName(Weapon1, "minigun spinup time decreased", stat1);
                TF2Attrib_SetByName(Weapon1, "closerange backattack minicrits", stat2);
                
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Tomislav: {orange}Mini-crits from behind. +%0.0f%%%% faster {teamcolor}rev up speed",chat_display, OneIs100(stat1));
                
            }

            if(IsStockOrAllClassWeapon(Weapon3))
            {
                stat1 = 1.5;
                TF2Attrib_SetByName(Weapon3, "maxammo primary increased", stat1);
                TF2Attrib_SetByName(Weapon3, "maxammo secondary increased", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Melee: {orange}+%0.00f%% maxammo on all weapons",chat_display, MoreIsMore(stat1));
            }

        }

        if (TF2_GetPlayerClass(client) == TFClass_Sniper)
        {

        if (Weapon1 != -1)
        {
            TF2Attrib_RemoveByName(Weapon1, "maxammo primary reduced");
            
        }

        if (IsWearable(Weapon2))
        {
            int razorback = FindTFWearable(client, 57);
            if (IsValidEntity(razorback) && Weapon1 != -1 && Weapon3 != -1)
            {
                stat1 = 0.5;
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Razorback: {orange}+%0.0f%% melee damage resistance. {teamcolor}Instantly recharge, {orange}stuns spy robots.",chat_display, OneIs100(stat1));
                TF2Attrib_SetByName(Weapon1, "dmg from melee increased", stat1);
                TF2Attrib_SetByName(Weapon3, "dmg from melee increased", stat1);
            }else
            {
                TF2Attrib_RemoveByName(Weapon1, "dmg from melee increased");
                TF2Attrib_RemoveByName(Weapon3, "dmg from melee increased");
            }

            int cozycamper = FindTFWearable(client, 642);
            if (IsValidEntity(cozycamper) && Weapon1 != -1 && Weapon3 != -1)
            {
                stat1 = 3.0;
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Cozy Camper: {orange}+%0.0f%% {teamcolor}Max Ammo",chat_display, MoreIsMore(stat1));
                TF2Attrib_SetByName(cozycamper, "maxammo primary increased", stat1);
                
            }
        }
        
        if (IsHuntsMan(Weapon1))
        {
            stat1 = 1.93;
            stat2 = 0.8;
            TF2Attrib_SetByName(Weapon1, "maxammo primary increased", stat1);
            TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
            TF2Attrib_SetByName(Weapon1, "faster reload rate", stat2);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Huntsman: {orange}Projectile penetration {teamcolor}upgrade, +%0.0f%% {teamcolor}max ammo.{orange}+20%%%% {teamcolor}fire rate bonus",chat_display, MoreIsMore(stat1), LessIsMore(stat2));
        }

        if (IsSniperRifle(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "explosive sniper shot", 1.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Sniper Rifle: {orange}Explosive headshots {teamcolor}upgrade",chat_display);
           
        }

        if (IsBazaar(Weapon1))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Bazaar Bargin: {orange}On Headshot: +1 head{teamcolor}, {darkred}On Bodyshot: -2 heads{teamcolor}. {orange}Heads: Gives faster reload speed bonus",chat_display);  
        }

        if (IsClassic(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "sniper no headshot without full charge", 0.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Classic: {orange}Headshot anytime",chat_display);
           
        }


            if(IsStockOrAllClassWeapon(Weapon3))
            {
                stat1 = 1.15;
                TF2Attrib_SetByName(Weapon3, "mult_player_movespeed_active", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Sniper Stock Melee: {orange}+%0.0f%% move speed{teamcolor} while active",chat_display, MoreIsMore(stat1));
            }

            if(IsShahanshah(Weapon3))
            {
                // stat1 = 3.0;
                // TF2Attrib_SetByName(Weapon3, "dmg bonus while half dead", stat1);
                TF2CustAttr_SetString(Weapon3, "pushforce-on-hit", "cond=-1 flDist=-500.0 flDistVert=400");
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Shahansah: {orange}On Hit:{teamcolor} Self Knockback",chat_display, MoreIsMore(stat1));
            }
            
        }

        if (TF2_GetPlayerClass(client) == TFClass_Scout)
        {

            // PrintToChatAll("Setting respawn stat");
            TF2CustAttr_SetString(client, "faster-respawn", "respawn=8.0");

            stat1 = 0.80;
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Scout Power: {orange}Greatly reduced respawn time\nAll weapons {orange}penetrate robots, +%0.f%%% faster reload",chat_display, LessIsMore(stat1));

            
            if (IsValidEntity(Weapon1))
            {
                TF2Attrib_SetByName(Weapon1, "Reload time increased", stat1);
                TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
            }
            
            if (IsValidEntity(Weapon2))
            {
            TF2Attrib_SetByName(Weapon2, "Reload time increased", stat1);
            TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
            }
            

            if (IsStockOrAllClassWeapon(Weapon3) && Weapon1 != -1 &&  Weapon2 != -1)
            {
                stat1 = 1.5;
                stat2 = 0.8;
                // TF2Attrib_SetByName(client, "maxammo primary increased", 1.5);
                // // TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 1.5);
                TF2Attrib_AddCustomPlayerAttribute(client, "maxammo primary increased", stat1);
                TF2Attrib_AddCustomPlayerAttribute(client, "maxammo secondary increased", stat1);
                stat3 = 20.0;
                TF2Attrib_SetByName(Weapon3, "max health additive bonus", stat3);

                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Bat: All weapons gain {orange}+%0.0f%% maxammo and +%0.0f%%% faster reload",chat_display, MoreIsMore(stat1), LessIsMore(stat2));
            }

            if (IsAtomizer(Weapon3))
            {
                stat1 = 3.0;
                TF2Attrib_SetByName(Weapon3, "air dash count", stat1);
                TF2Attrib_SetByName(Weapon3, "minicrits become crits", 1.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Atomizer: {orange}%0.0f% Bonus Jumps. {orange}Crits when it would mini-crit",chat_display, stat1);
            }

            if (IsPistol(Weapon2))
            {
                stat1 = 2.0;
                TF2Attrib_SetByName(Weapon2, "speed_boost_on_hit", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Scout Pistol: {orange}On Hit: {teamcolor}Speed boost for {orange}%0.0f seconds",chat_display, stat1);
            }

            if (IsSunOnAStick(Weapon3))
            {
                TF2CustAttr_SetString(client, "Spell-Caster", "Spell=0 Cooldown=40.0");
                // TF2_RegeneratePlayer(client);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Sun-on-a-Stick:{orange} Fire ball spell",chat_display, MoreIsMore(stat1), stat2);
            }else
            {
                TF2CustAttr_SetString(client, "Spell-Caster", "Spell=-1 Cooldown=40.0");
            }

            if (IsCandyCane(Weapon3))
            {   
                stat1 = 1.33;
                stat2 = 4.0;
                TF2Attrib_SetByName(Weapon3, "health from packs increased", stat1);
                TF2Attrib_SetByName(Weapon3, "health regen", stat2);
                // TF2CustAttr_SetString(Weapon3, "spawn-healthpack-on-dmg", "damage=500 levels=3");
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Candy Cane: {orange}+%0.0f%%%% more health{teamcolor} from healthpacks. {orange}+%0.0f health{teamcolor} regenerated per second",chat_display, MoreIsMore(stat1), stat2);
            }

            if (IsMadMilk(Weapon2))
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Milk: {orange}Mad milk has less duration vs robots",chat_display);
            }

            if (IsCritACola(Weapon2))
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Crit-a-Cola: {orange}Applies %0.f second crits when used",chat_display, g_crit_a_cola_duration);
            }

        }

        if(TF2_GetPlayerClass(client) == TFClass_Engineer)
        {
            if (IsPistol(Weapon2))
            {
                stat1 = 2.0;
                TF2Attrib_SetByName(Weapon2, "clip size bonus", 2.0);
                // TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.5);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Engineer Pistol: {orange}+%0.0f%%%% clip size",chat_display, MoreIsMore(stat1));
            }
            if (IsSouthernHospitality(Weapon3))
            {
                TF2Attrib_RemoveByName(Weapon3, "upgrade rate decrease");
                // TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.5);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Southern Hospitality: No upgrade penalty",chat_display);
            }
        }

        if (TF2_GetPlayerClass(client) == TFClass_Spy)
        {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Spy Power: {orange}Use enemy teamporters by touching their spawn",chat_display);
        }

        if (TF2_GetPlayerClass(client) == TFClass_Medic)
        {
            //  if(IsSyringeGun(Weapon1))
            // {
            //     //TF2CustAttr_SetString(Weapon1, "syringe-uber-gain", "combo_time=1.5 buff_duration=20.0 buff_max=20 buff_min=5");
            //     stat1 = 1.051;
            //     TF2Attrib_SetByName(Weapon1, "ubercharge rate bonus", stat1);
            //     Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Syringe Gun: {orange}%0.00f%%%% faster uber build rate{teamcolor}",chat_display, MoreIsMore(stat1));
            // }
            if(IsBlutsauger(Weapon1))
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Blutsauger: On Hit: {orange}Reduce Enemy healing by -%0.0f%%%%{teamcolor} for %0.0f second.",chat_display, LessIsMore(g_blutsauger_heal_reduction), g_blutsauger_heal_reduction_duration);
            }

            if(IsOverdose(Weapon1) && Weapon2 != -1)
            {
                TF2Attrib_SetByName(Weapon2, "overheal decay disabled", 1000.0);
                stat1 = 1.6;
                TF2Attrib_SetByName(Weapon1, "increased jump height from weapon", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Overdose: {orange}No Overheal decay. {teamcolor}While Active: {orange}+%0.0f%%%% {teamcolor}greater jump height bonus",chat_display, MoreIsMore(stat1));
            }else
            {
                //Remove the attribute if overdose is not present, as it remains on loadout switch
                TF2Attrib_RemoveByName(Weapon2, "overheal decay disabled");
                TF2Attrib_RemoveByName(Weapon1, "increased jump height");
            }

            if(!IsOverdose(Weapon1) && Weapon2 != -1)
            {
                //Remove the attribute when changing loadout
                TF2Attrib_RemoveByName(Weapon2, "overheal decay disabled");
            }

            if(IsAmputator(Weapon3) && Weapon1 != -1)
            {
                stat1 = 0.4;
                TF2Attrib_SetByName(Weapon3, "dmg taken from crit reduced", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Amputator: Provides {orange}+%0.0f%%%% Passive critical resistance",chat_display, LessIsMore(stat1));
            }

            if(IsSolemnVow(Weapon3))
            {
                stat1 = 1.0;
                TF2Attrib_SetByName(Weapon2, "healing mastery", stat1);
                TF2Attrib_SetByName(Weapon3, "mod see enemy health", 1.0);
                
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Solemn Vow: {orange}Healing Mastery %i",chat_display, RoundToNearest(stat1));    
 
            }else
            {
                TF2Attrib_RemoveByName(Weapon2, "healing mastery");
                TF2Attrib_RemoveByName(Weapon3, "mod see enemy health");
            }

            if(IsVitaSaw(Weapon3) && Weapon2 != -1)
            {
                stat1 = 0.4;
                TF2Attrib_SetByName(Weapon3, "dmg from melee increased", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Vita-Saw: {orange}While Active: {orange}+%0.0f%%%% {teamcolor}Passive melee resistance",chat_display, LessIsMore(stat1));    
            }else
            {
                TF2Attrib_RemoveByName(Weapon3, "dmg from melee increased");
            }

            if(IsCrossbow(Weapon1))
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Crossbow: {orange}Protection Rune{teamcolor}teammate for %0.0f seconds",chat_display, g_protection_rune_duration);
            }

            if(IsStockOrAllClassWeapon(Weapon3))
            {
                stat1 = 1.0;
                TF2Attrib_SetByName(Weapon3, "uber duration bonus", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Melee: {orange}+%0.0f {teamcolor}second longer uber duration.",chat_display,stat1);
            }

            if (IsQuickfix(Weapon2))
            {
                TF2Attrib_SetByName(Weapon2, "generate rage on heal", 1.0);
                TF2Attrib_SetByName(Weapon2, "increase buff duration", 0.8);
			    TF2CustAttr_SetString(Weapon2, "rage fill multiplier", "0.5");
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Quickfix: {orange}Medic MvM Shield",chat_display);
            }

            if(IsVaccinator(Weapon2))
            {
			    TF2Attrib_SetByName(Weapon2, "medigun bullet resist deployed", 0.85);
			    TF2Attrib_SetByName(Weapon2, "medigun blast resist deployed", 0.85);
			    TF2Attrib_SetByName(Weapon2, "medigun fire resist deployed", 0.85);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Vaccinator: {orange}+10%%%% higher deployed resistances",chat_display);
            }

            // if(Weapon2 != -1)
            // {
            //     stat1 = 0.5;
            //     TF2Attrib_SetByName(Weapon3, "ubercharge_preserved_on_spawn_max", stat1);
            //     Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Organs: {orange}Up to %0.0f%%%% uber saved on death",chat_display, OneIs100(stat1));
                
            // }
        }
        

        if (IsZatoichi(Weapon3))
        {
            stat1 = 25.0;
            TF2Attrib_SetByName(Weapon3, "heal on hit for rapidfire", stat1);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Half-Zatoichi: {orange}gains %0.0f HP on hit",chat_display, stat1);

            if(TF2_GetPlayerClass(client) == TFClass_Soldier)
            {
                TF2Attrib_RemoveByName(Weapon3, "fire rate bonus");
            }
        }

        if (TF2_GetPlayerClass(client) == TFClass_Spy)
        {

            if (IsRevolver(Weapon1))
            {
                TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
                TF2CustAttr_SetString(Weapon1, "tag last enemy hit", "8.0");
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Revolver: {orange}Projectile penetration {teamcolor}bonus & {orange}Tags robots on hit{teamcolor} for 8 seconds",chat_display);
            }

            
            if (IsStockKnife(Weapon3))
            {
                TF2CustAttr_SetString(Weapon3, "tag last enemy hit", "8.0");
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Knife:{orange}Tags robots on hit{teamcolor} for 8 seconds",chat_display);
            }


            if (IsBigEarner(Weapon3))
            {
                stat1 = 1.15;
                TF2Attrib_SetByName(Weapon3, "mult_player_movespeed_active", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Big Earner:{orange}Grants %0.0f%%%% movespeed while actove",chat_display, MoreIsMore(stat1));
            }

            if(IsSpycicle(Weapon3))
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Spycicle:{orange}On Backstab: Slows enemy attack speed by -%0.0f%%%% for %0.0f seconds",chat_display, LessIsMore(g_spycicle_fire_speed_debuff), g_spycicle_fire_Speed_debuff_duration);
            }

            if (IsEnforcer(Weapon1))
            {
                TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
                TF2CustAttr_SetString(Weapon1, "dmg-bonus-vs-sapped-buildings", "damage=3.0");
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Gun: {orange}Projectile penetration {teamcolor}bonus & {orange}200%%%% Damage bonus {teamcolor}vs sapped buildings",chat_display);
            }

            if (IsAmbassador(Weapon1))
            {
                TF2Attrib_SetByName(Weapon1, "crit_dmg_falloff", 0.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Ambassador: {orange}No critical damage falloff",chat_display);
            }
        }

        if (IsMarketGardner(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Market Gardner: {orange}+%0.0f%%%% damage bonus while rocket jumping{teamcolor}",chat_display, MoreIsMore(g_market_gardner_dmg_bonus));
        }

        if (IsElectric(Weapon1) || IsElectric(Weapon2))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Your electric weapons {orange}reduce robot heal rate{teamcolor} for %0.1f seconds on hit. Shortens Enemy MvM shield duration",chat_display, g_ElectricStunDuration);
        }

        if (IsWarriorSpirit(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Warrior Spirit: {orange}+%i HP{teamcolor} on hit against robots",chat_display, g_warriorspirit_heal_on_hit);
        }

        if (IsKGB(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}KGB: {orange}+%0.0f seconds of critical hits{teamcolor} when landing a quick 3 hit combo vs robots",chat_display, g_kgb_crit_combo_duration);
        }
        if (IsJetpack(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "falling_impact_radius_pushback", 0.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Jetpack: {darkred}Deals no knockback{teamcolor} when landing",chat_display);
        }

        if (TF2_GetPlayerClass(client) == TFClass_Soldier)
        {
            if (IsAirStrike(Weapon1))
            {
                TF2Attrib_SetByName(Weapon1, "clipsize increase on kill", 8.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}AirStrike: {orange}Gains additional clip{teamcolor} by doing %i damage to robots, {orange}+4 extra bonus clip", chat_display, RoundToNearest(g_AirStrikeDMGRequirement));
            }
            if (IsBlackBox(Weapon1))
            {
                stat1 = 30.0;
                TF2Attrib_SetByName(Weapon1, "heal on hit for rapidfire", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Blackbox: On Hit: Up to {orange}%0.0f bonus health",chat_display, stat1);
            }

            if (isBeggarsBazooka(Weapon1))
            {
                stat1 = 3.0;
                TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Beggars Bazooka: {orange}+%0.0f clip size",chat_display, stat1);
            }

            if (isLibertyLauncher(Weapon1))
            {

                stat1 = 1.6;
                TF2Attrib_SetByName(Weapon1, "clip size bonus", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Liberty Launcher: {orange}+%0.0f%%%% clip{teamcolor}",chat_display, MoreIsMore(stat1));
                
                if (Weapon2 != -1)
                {
                    if (IsAnyBanner(Weapon2))
                    {
                        stat1 = 2.0;
                        TF2Attrib_SetByName(Weapon2, "increase buff duration", stat1);
                        
                        Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Liberty Launcher: Provides banner {orange}+%0.0f%%%% longer buff duration{teamcolor}",chat_display, MoreIsMore(stat1));
                    }else
                    {
                        stat1 = 1.5;
                        TF2Attrib_SetByName(Weapon2, "clip size bonus", stat1);
                        Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Liberty Launcher: {orange}+%0.0f%% Bonus Clip on Shotgun",chat_display, MoreIsMore(stat1));
                    }

                    if(IsBison(Weapon2))
                   {
                        stat1 = 0.65;
                        TF2Attrib_SetByName(Weapon2, "faster reload rate", stat1);
                        Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Bison: {orange}+%0.0f%% faster reload",chat_display, LessIsMore(stat1));
                   }
                   if(IsBaseJumper(Weapon2))
                   {
                        stat1 = 25.0;
                        TF2Attrib_SetByName(Weapon2, "max health additive bonus", stat1);
                        Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Base Jumper: {orange}+%0.0f%% max hp",chat_display, stat1);
                   }
                }else
                {
    
                }
            }else
            {
                //To avoid keeping the buff when switching weapons
                if(Weapon2 != -1)
                {
                    if (IsAnyBanner(Weapon2))
                    {
                        
                        TF2Attrib_RemoveByName(Weapon2, "increase buff duration");
                        
                    }else
                    {
                        TF2Attrib_RemoveByName(Weapon2, "clip size bonus");
                    }
                }
            }

            if (IsAnyRocketLauncher(Weapon1))
            {
                stat1 = 0.8;
                TF2Attrib_SetByName(Weapon1, "Reload time decreased", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Primary {orange}+%0.0f%%%% faster reload",chat_display, LessIsMore(stat1));
            }

            if (IsRocketLauncher(Weapon1))
            {
                stat1 = 1.5;
                TF2Attrib_SetByName(Weapon1, "Blast radius increased", stat1);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Rocket Launcher {orange}+%0.0f%%%% larger explosion radius",chat_display, MoreIsMore(stat1));
            }

            if (IsWearable(Weapon2))
            {

                int SoldierShoes = FindTFWearable(client, 133);
                if(IsValidEntity(SoldierShoes))
                {

                    TF2Attrib_SetByName(SoldierShoes, "cancel falling damage", 1.0);
                    Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Gunboats:{orange} No fall damage",chat_display);
                    if(isLibertyLauncher(Weapon1))
                    {
                        stat1 = 0.1;
                        Format(chat_display, sizeof(chat_display), "%s{orange}Liberty Launcher: -%0.0f%%%% {teamcolor}rocket jump damage reduction",chat_display, LessIsMore(stat1));
                        TF2Attrib_SetByName(SoldierShoes, "rocket jump damage reduction", stat1);
                    }
                }

                SoldierShoes = FindTFWearable(client, 444);
                if (IsValidEntity(SoldierShoes))
                {
                    Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Mantreads:{orange} Stomp: Stun tanks, Dizzy Robots",chat_display);

                    if(isLibertyLauncher(Weapon1))
                    {
                        stat1 = 1.3;
                        Format(chat_display, sizeof(chat_display), "%s{orange}\nLiberty Launcher: -%0.0f%%%% {teamcolor}faster move speed",chat_display, MoreIsMore(stat1));
                        TF2Attrib_SetByName(SoldierShoes, "move speed bonus", stat1);
                    }
                }
            }

            if (isEqualizer(Weapon3))
            {
                stat1 = 20.0;
                Format(chat_display, sizeof(chat_display), "%s{orange}\nEqualizer: %0.0f%%%% {teamcolor}increased rage build",chat_display, MoreIsMore(stat1));
                TF2Attrib_SetByName(Weapon3, "mod rage on hit bonus", stat1);
            }
        }

        if (HasFrontierJustice(client))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Frontier Justice: {orange}Gains 1 revenge crit{teamcolor} every %i damage your sentry does to robots",chat_display, RoundToNearest(g_FrontierJusticeDMGRequirement));
        }

        if (IsShotGun(Weapon1))
        {
            stat1 = 0.8;
            TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
            TF2Attrib_SetByName(Weapon1, "Reload time decreased", stat1);
            TF2Attrib_SetByName(Weapon1, "fire rate bonus", stat1);
            TF2CustAttr_SetString(Weapon2, "dmg-crit-vs-jumping-robots", "damage=1.25");
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Shotgun: {orange}Penetrates {teamcolor} & {orange}+%0.0f%%%% faster firing and reload speed, +25%%%% dmg bonus vs jumping robots",chat_display, LessIsMore(stat1));
        }
        if (IsShotGun(Weapon2))
        {
            stat1 = 0.8;
            TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
            TF2Attrib_SetByName(Weapon2, "Reload time decreased", stat1);
            TF2Attrib_SetByName(Weapon2, "fire rate bonus", stat1);
            TF2CustAttr_SetString(Weapon2, "dmg-crit-vs-jumping-robots", "damage=1.25");
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Shotgun: {orange}Penetrates {teamcolor} & {orange}+%0.0f%%%% faster firing and reload speed, +25%%%% dmg bonus vs jumping robots",chat_display, LessIsMore(stat1));
        }

        if (IsReserveShooter(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "single wep deploy time decreased", stat1 = 0.6);
            TF2CustAttr_SetString(Weapon2, "dmg-crit-vs-jumping-robots", "damage=1.75 critType=2");
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Reserve Shooter:{orange}+25%% damage bonus vs jumping robots. {orange}+%0.0f%%%% faster deploy speed",chat_display, LessIsMore(stat1));
        }

        if(IsSandman(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Baseball: {orange}Knock robots dizzy",chat_display);
        }
        if(IsWrap(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Ornament: {orange}Reduce robots heal rate for %0.0f seconds",chat_display, g_wrap_duration);
        }

        if(IsCleaver(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "bleeding duration", g_bleed_duration_bonus);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Cleaver: {orange}On Hit: Bleed for %0.0f seconds",chat_display, g_bleed_duration_bonus);
        }

        if(IsSMG(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "speed_boost_on_hit", stat1 = 2.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}SMG: {orange}On Hit: {teamcolor}Speed boost for %0.0f seconds",chat_display, stat1);
        }

        if(IsCarbine(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "minicrit_boost_when_charged", stat1 = 16.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Carbine: {orange}Increased duration to %0.0f seconds",chat_display, stat1);
        }

        if(IsShiv(Weapon3))
        {
            // TF2Attrib_SetByName(Weapon2, "slow enemy on hit major", 1.0);
            TF2Attrib_SetByName(Weapon3, "bleeding duration", stat1 = 20.0);
            
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Tribalmans Shiv: {orange}Bleed lasts %0.0f seconds",chat_display, stat1);
        }
        if(IsGunSlinger(Weapon3))
        {
            TF2Attrib_SetByName(Weapon3, "engineer sentry build rate multiplier", stat1 = 8.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Gunslinger: {orange}+%0.0f%%%% faster sentry build",chat_display, MoreIsMore(stat1));
            
        }
        if (IsBackScratcher(Weapon3))
        {
            TF2Attrib_SetByName(Weapon3, "bleeding duration", stat1 = 20.0);
            TF2Attrib_SetByName(Weapon3, "health from healers reduced", 1.0);
            
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Backscratcher: On Hit: {orange}Bleed for %0.0f seconds, {orange}No healing penalty",chat_display, stat1);
        }
        // if (IsSapper(Weapon2))
        // {
        //     // Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Sapper: {orange}Stuns robots{teamcolor} or some shit",chat_display);
        //     // TF2Attrib_SetByName(Weapon2, "robo sapper", 4.0);
            
        // }                        
        // DataPack info = new DataPack();
        // info.Reset();
        // info.WriteCell(client);
        // info.WriteCell(chat_display);
        
        RemoveJingle(client);
        // RequestFrame(FrameDelayedStatDisplay, info);        
        if(!IsAnyRobot(client))DisplayMMStats(client, chat_display);

    }
    //Jingle Sounds sometimes causes crash with the soundhooks somehow
    
}
    
// void FrameDelayedStatDisplay (DataPack info)
// {
//     info.Reset();

// 	int client = info.ReadCell();
//     char chat_display[512] = info.ReadCell();
// 	delete info;
//     if(!IsAnyRobot(client))DisplayMMStats(client, chat_display);
// }

void RemoveJingle(int iClient)
{
	int iWearableItem = -1;
	// PrintToServer("LOOKING HAT 1 !");
	while ((iWearableItem = FindEntityByClassname(iWearableItem, "tf_wearable*")) != -1) // Regular hats.
	{	
		// We check for the wearable's item def index and its owner.
		// int iWearableIndex = GetEntProp(iWearableItem, Prop_Send, "m_iItemDefinitionIndex");
		int iWearableOwner = GetEntPropEnt(iWearableItem, Prop_Send, "m_hOwnerEntity");

		if (iWearableOwner == iClient)
		{
            TF2Attrib_SetByName(iWearableItem, "add jingle to footsteps", 0.0);
		}
	}
}

void SetDemoDamageBuff(int weapon)
{
    TF2CustAttr_SetString(weapon, "damage increase mult on hit", "amount=0.1 max=0.4 decay_start=0.5 decay_per_second=0.025 reset_on_kill=0 show_on_hud=1");
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

bool IsSniperRifle(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Sniper Rifles and Reskins
	case 14, 201, 664, 792, 801, 851, 881, 890, 899, 908, 957, 966, 15000, 15007, 15019, 15023, 15033, 15059, 15070, 15071, 15072, 15111, 15112, 15135, 15136, 15154: //Short Circuit, The Righteous Bison, Cow Mangler
		{
			return true;
		}
	}
	return false;
}

bool IsSMG(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Sniper Rifles and Reskins
	case 16, 203, 1149, 15001, 15022, 15032, 15037, 15058, 15076, 15110, 15134, 15153:
		{
			return true;
		}
	}
	return false;
}

bool IsCarbine(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Sniper Rifles and Reskins
	case 751:
		{
			return true;
		}
	}
	return false;
}

bool IsShiv(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Sniper Rifles and Reskins
	case 171:
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

bool IsClassic(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		
	case 1098: 
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
		//If other eyelander skins
	case 132, 266, 482, 1082: //Short Circuit, The Righteous Bison, Cow Mangler
		{
			return true;
		}
	}
	return false;
}

bool IsZatoichi(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other half-zatoichi
	case 357: 
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

// bool IsFrontierJustice(int weapon)
// {
// 	if(weapon == -1 && weapon <= MaxClients) return false;
	
// 	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
// 	{
// 		//If other Frontier are added add here
// 	case 141, 1004: 
// 		{
// 			return true;
// 		}
// 	}
// 	return false;
// }

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

bool IsRevolver(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Revolver and Enforcer
	case 24, 210, 1142,  161, 15011, 15027, 15042, 15051, 15062, 15063, 15064, 15103, 15128, 15127, 15149: //Holiday_Punch
		{
			return true;
		}
	}
	return false;
}

bool IsEnforcer(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Revolver and Enforcer
	case 460:
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
bool IsSunOnAStick(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Sun-on-a-stick
	case 349: 
		{
			return true;
		}
	}
	return false;
}

bool IsSkullCutter(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{

	case 172: 
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

bool isEqualizer(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other Equalizer are added, add here
	case 128: 
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

bool IsBison(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
	case 442: 
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

bool IsAnyRocketLauncher(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other Beggarbazooka are added, add here
	case 18,205,127,228,237,414,441,513,658,730,800,809,889,898,907,916,965,974,1085,1104,15006,15014,15028,15043,15052,15057,15081,15104,15105,15129,15130,15150: 
		{
			return true;
		}
	}
	return false;
}

bool IsStockOrAllClassWeapon(int weapon){
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other allclass are added, add here
        
	case 0,1,3,5,8,190,191,193,195,198,154,609,264,423,474,880,939,954,1013,1071,1123,1127,30758,660,30667: 
		{
			return true;
		}
	}
	return false;
}

bool IsCaber(int weapon)
{
    	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other bottles
        
	case 307:
		{
			return true;
		}
	}
	return false;
    
}

bool IsQuickieBombLauncher(int weapon)
{
    	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other bottles
        
	case 1150:
		{
			return true;
		}
	}
	return false;
    
}

bool IsClaid(int weapon)
{
    	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other bottles
        
	case 327:
		{
			return true;
		}
	}
	return false;
    
}

bool IsThirdDegree(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Third Degree
	case 593: 
		{
			return true;
		}
	}
	return false;
}

bool IsCritACola(int weapon){
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other allclass are added, add here
	case 163: 
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
	case 9,10,11,12,199,425,1141,1153,15003,15016,15044,15047,15085,15109,15132,15133,15152: 
		{
			return true;
		}
	}
	return false;
}

bool IsReserveShooter(int weapon){
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other shotguns are added, add here
	case 415: 
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

bool IsScorch(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other scorch
	case 740: 
		{
			return true;
		}
	}
	return false;
}

bool IsLooseCannon(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If other loose cannon
	case 996: 
		{
			return true;
		}
	}
	return false;
}

bool IsDemoKnight(int weapon1, int weapon2)
{
    //Demoknights don't have weapons in slot1 or 2
    // PrintToChatAll("Weapon1 was %i", weapon1);
    // PrintToChatAll("Weapon2 was %i", weapon2);
    if(weapon2 == -1)
    {
        if(weapon1 == -1 || IsBaseJumper(weapon1))
        return true;
    }
    return false;
}

bool IsIronBomber(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 1151: 
		{
			return true;
		}
	}
	return false;
}


bool IsBlutsauger(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 36: 
		{
			return true;
		}
	}
	return false;
}

bool IsCleaver(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Candy Cane
	case 812, 833: 
		{
			return true;
		}
	}

	return false;
}

bool IsBaseJumper(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Candy Cane
	case 1101: 
		{
			return true;
		}
	}
	return false;
}

bool IsGunSlinger(int weapon)

{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Gunslinger
	case 142: 
		{
			return true;
		}
	}
	return false;
}

bool IsBackScratcher(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Back scratcher
	case 326: 
		{
			return true;
		}
	}
	return false;
}

bool IsNatascha(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Gunslinger
	case 41: 
		{
			return true;
		}
	}
	return false;
}

bool IsTomiSlav(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//Gunslinger
	case 424: 
		{
			return true;
		}
	}
	return false;
}
bool IsVitaSaw(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 173: 
		{
			return true;
		}
	}
	return false;
}

bool IsSyringeGun(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 17,204: 
		{
			return true;
		}
	}
	return false;
}

bool IsOverdose(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 412: 
		{
			return true;
		}
	}
	return false;
}

bool IsAmputator(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 304: 
		{
			return true;
		}
	}
	return false;
}

bool IsSolemnVow(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 413: 
		{
			return true;
		}
	}
	return false;
}

bool IsCrossbow(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 305, 1079: 
		{
			return true;
		}
	}
	return false;
}

bool IsQuickfix(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 411: 
		{
			return true;
		}
	}
	return false;
}

bool IsVaccinator(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 998: 
		{
			return true;
		}
	}
	return false;
}

bool IsMadMilk(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 222: 
		{
			return true;
		}
	}
	return false;
}

bool IsShahanshah(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 401:
		{
			return true;
		}
	}
	return false;
}

bool IsAtomizer(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 450:
		{
			return true;
		}
	}
	return false;
}

bool IsPistol(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 22, 23, 209, 160, 294, 15013, 15018, 15035, 15041, 15046, 15056, 15060, 15061, 15100, 15101, 15102, 15126, 15148, 30666:
		{
			return true;
		}
	}
	return false;
}

bool IsStockKnife(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 4, 194, 423, 638, 665, 727, 794, 803, 883, 892, 901, 910, 959, 968, 1071, 15062, 15094, 15095, 15096, 15118, 15119, 15143, 15144, 30758:
		{
			return true;
		}
	}
	return false;
}

bool IsSpycicle(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 649:
		{
			return true;
		}
	}
	return false;
}

bool IsSouthernHospitality(int weapon)
{
    if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If others are added, add them here
	case 155:
		{
			return true;
		}
	}
	return false;
}

bool IsWearable(int weapon)
{

    if(weapon == -1 && weapon <= MaxClients)
    {
        return true;
    }else
    {
        return false;       
    }
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

// bool IsSapper(int weapon)
// {
//     if(weapon == -1 && weapon <= MaxClients) return false;
	
// 	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
// 	{
// 		//If others are added, add them here
// 	case 735, 736: 
// 		{
// 			return true;
// 		}
// 	}
// 	return false;
// }


//Functions to deal with different on kill to on hit stuff

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

// void AddPlayerHealth(int iClient, int iAdd, int iOverheal = 0, bool bStaticMax = false)
// {
//     int iHealth = GetClientHealth(iClient);

    
//     int iNewHealth = iHealth + iAdd;
//     int iMax = bStaticMax ? iOverheal : GetEntProp(iClient, Prop_Data, "m_iMaxHealth") + iOverheal;

//     // PrintToChatAll("Ihealth was: %i iAdd was: %i, iMax was: %i", iHealth, iAdd, iMax);
//     if (iNewHealth <= iMax)
//     {
//         //iNewHealth = min(iNewHealth, iMax);
//         SetEntityHealth(iClient, iNewHealth);
//     }else
//     {
//         SetEntityHealth(iClient, iMax);
//     }
// }

// void ShowHealthGain(int iPatient, int iHealth, int iHealer = -1)
// {
//     int iUserId = GetClientUserId(iPatient);
//     Handle hEvent = CreateEvent("player_healed", true);
//     SetEventBool(hEvent, "sourcemod", true);
//     SetEventInt(hEvent, "patient", iUserId);
//     SetEventInt(hEvent, "healer", IsValidClient(iHealer) ? GetClientUserId(iHealer) : iUserId);
//     SetEventInt(hEvent, "amount", iHealth);
//     FireEvent(hEvent);

//     hEvent = CreateEvent("player_healonhit", true);
//     SetEventBool(hEvent, "sourcemod", true);
//     SetEventInt(hEvent, "amount", iHealth);
//     SetEventInt(hEvent, "entindex", iPatient);
//     FireEvent(hEvent);
// }

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

public Action Combo_Stopper (int client)
{

    Punch_Count[client] = 0;
    Timer_Punch_Count[client] = 0;
    // PrintToChatAll("========================");
    // PrintToChatAll("Resetting combo");
    // PrintToChatAll("Inside timer Punch_Count %i:", Punch_Count[client]);
    // PrintToChatAll("Inside timer Timer_Punch_Count %i:", Timer_Punch_Count[client]);
    //g_Timer[attacker] = false;
    return Plugin_Continue;

}

void SetHealingDebuff(int victim, float value, float duration, int attacker)
{

    TF2_AddCondition(victim, TFCond_HealingDebuff, duration, attacker);
    TF2_AddCondition(victim, TFCond_Sapped, duration, attacker);
    TF2Attrib_AddCustomPlayerAttribute(victim, "reduced_healing_from_medics", value, duration);

}
// int g_attacker[MAXPLAYERS + 1];
float milk_time[MAXPLAYERS + 1] = {0.0,...};

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
        //Code To Handle Sentry Vuln on spun up heavies
		if (IsAnyRobot(client))
		{	
            // PrintToChatAll("%N WAS SPUN UP", client);
            if (condition == TFCond_Slowed && TF2_GetPlayerClass(client) == TFClass_Heavy)TF2Attrib_AddCustomPlayerAttribute(client, "SET BONUS: dmg from sentry reduced", 1.25);

            if (condition == TFCond_Milked && milk_time[client] < GetEngineTime())
            {
                // PrintToChatAll("%N was milked", client);
                TF2_RemoveCondition(client, TFCond_Milked);
                TF2_AddCondition(client, TFCond_Milked, 4.0);
                TF2_AddCondition(client, 71, 4.0);
                milk_time[client] = GetEngineTime() + 0.2;

                // RequestFrame(RemoveMilk, client);
            }
            
            if (condition == TFCond_MarkedForDeath && milk_time[client] < GetEngineTime())
            {
                // PrintToChatAll("%N was marked", client);
                TF2_RemoveCondition(client, TFCond_MarkedForDeath);
                TF2_AddCondition(client, TFCond_MarkedForDeath, 4.0);

                milk_time[client] = GetEngineTime() + 0.2;

                // RequestFrame(RemoveMilk, client);
            }
		}

        if (!IsAnyRobot(client))
        {
            if (condition == TFCond_CritCola && TF2_GetPlayerClass(client) == TFClass_Scout)
            {
                TF2_AddCondition(client, TFCond_CritCanteen, g_crit_a_cola_duration);
            }
        }


        // if(!IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_DemoMan && condition == TFCond_Taunting)
        // {
             
        //      int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        //      if (IsStockOrAllClassWeapon(iActiveWeapon))
        //      {
		// 	int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
            
		// 	if (tauntid == -1){
		// 	TF2_AddCondition(client, TFCond_Buffed, g_bottle_crit_duration * 1.25);
		// 	}
        //      }
        // }
	
}

// void RemoveMilk (int client)
// {
    
//     // TF2_AddCondition(client, TFCond_Milked, 1.0 , g_attacker);
// }

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	
        //Code To Handle Sentry Vuln on spun up heavies
		// if (IsAnyRobot(client) && condition == TFCond_Slowed && TF2_GetPlayerClass(client) == TFClass_Heavy)
		// {	
        //     // PrintToChatAll("%N WAS DONE SPUN UP", client);
        //     TF2Attrib_AddCustomPlayerAttribute(client, "SET BONUS: dmg from sentry reduced", 1.0);
		// }

        if(condition == TFCond_RuneHaste)
        {
            // PrintToChatAll("RUNE HASTE ENDED ON %N, FIXING SPEED", client);
            TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
        }
}

public Action Event_Crossbow_Heal(Event event, const char[] name, bool dontBroadcast)
{
	int healer = GetClientOfUserId(GetEventInt(event, "healer"));
	int target = GetClientOfUserId(GetEventInt(event, "target"));

	if (!IsAnyRobot(healer))
	{
        TF2_AddCondition(target, TFCond_RuneResist, g_protection_rune_duration);
	}
	return Plugin_Continue;
}

//Values where modifiers of 0.8 is 20% more
public float LessIsMore(float value)
{
    return (100.0-value*100.0)+0.01;
}

//Values where 1.2 is 20%  more
public float MoreIsMore(float value)
{
    return (value*100.0)-100.0;
}

//Values where 2.0 is 100% more
// public float OffBy100(float value)
// {
//     return (value*100.0)-100.0;
// }

// Where 1.0 is 100%
public float OneIs100(float value)
{
    return value*100.0;
}

stock void TE_Particle(const char[] Name, float origin[3] = NULL_VECTOR, float start[3] = NULL_VECTOR, float angles[3] = NULL_VECTOR, int entindex = -1, int attachtype = -1, int attachpoint = -1, bool resetParticles = true, int customcolors = 0, float color1[3] = NULL_VECTOR, float color2[3] = NULL_VECTOR, int controlpoint = -1, int controlpointattachment = -1, float controlpointoffset[3] = NULL_VECTOR)
{
    // Function implementation goes here
    // find string table
    int tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx == INVALID_STRING_TABLE)
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    float delay = 3.0;
    // find particle index
    char tmp[256];
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;

    for (int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx == INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }

    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex !=- 1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype != -1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint != -1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);

    if(customcolors)
    {
        TE_WriteNum("m_bCustomColors", customcolors);
        TE_WriteVector("m_CustomColors.m_vecColor1", color1);
        if(customcolors == 2)
        {
            TE_WriteVector("m_CustomColors.m_vecColor2", color2);
        }
    }
    if(controlpoint != -1)
    {
        TE_WriteNum("m_bControlPoint1", controlpoint);
        if(controlpointattachment != -1)
        {
            TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", controlpointattachment);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", controlpointoffset[0]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", controlpointoffset[1]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", controlpointoffset[2]);
        }
    }
    TE_SendToAll(delay);
}