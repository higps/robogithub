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
#include <tf_custom_attributes>
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

int Punch_Count[MAXPLAYERS + 1] = {0, ...};
int Timer_Punch_Count[MAXPLAYERS + 1] = {0, ...};
bool g_Timer[MAXPLAYERS + 1] = {false, ...};

int g_Eyelander_Counter[MAXPLAYERS + 1] = {0, ...};

float g_AirStrikeDamage[MAXPLAYERS +1] = {0.0, ...};
float g_AirStrikeDMGRequirement = 250.0;
float g_ElectricStunDuration = 1.0;
float g_HealDebuff = 0.5;

float g_FrontierJusticeDamage[MAXPLAYERS + 1] = {0.0, ...};
float g_FrontierJusticeDMGRequirement = 250.0;
int g_EngineerRevengeCrits[MAXPLAYERS + 1] = {0, ...};

//bool g_Enabled;

float g_Attribute_Display_CollDown = 10.0;
float g_Attribute_Display[MAXPLAYERS + 1] = {0.0, ...};
bool b_Attribute_Display[MAXPLAYERS + 1] = {true, ...};

 float g__bleed_duration_bonus = 10.0;

#define SPY_ROBOT_STAB	"weapons/saxxy_impact_gen_01.wav"
// #define SPY_ROBOT_STAB	")mvm/giant_demoman/giant_demoman_grenade_shoot.wav"

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
    RegConsoleCmd("sm_mminfo", Command_ToggleMMHumanDisplay, "Toggle Manned Machines Stats Display for humans");
//     HookEvent("object_destroyed", Event_Object_Destroyed, EventHookMode_Post);
//     HookEvent("object_detonated", Event_Object_Detonated, EventHookMode_Post);


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

        if(TF2_GetPlayerClass(client) == TFClass_Scout)
        {
            TF2CustAttr_SetString(client, "faster-respawn", "4.0");
        }

        // if(TF2_GetPlayerClass(client) == TFClass_Engineer)
        // {
        //     int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

        //     if (IsGunSlinger(Weapon3))
        //     {
        //         TF2CustAttr_SetString(Weapon3, "robot engineer", "sentries=2");
        //     }
            
        // }

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
        }

    
        if(!IsAnyRobot(victim))
        {

            //     //m_flItemChargeMeter
            // float data = GetEntPropFloat(victim, Prop_Send, "m_flItemChargeMeter");
            // PrintToChatAll("Data %f", data);
              
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
                    TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 5.0);
                    TF2_AddCondition(attacker, TFCond_DefenseBuffed, 5.0);
                    // TF2_AddCondition(attacker, TFCond_CritCanteen, 3.0);
                    
                }

                if(IsPowerJack(weapon))
                {
                
                AddPlayerHealth(attacker, 50, 260, true, true);
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
                    AddPlayerHealth(attacker, 50, 450, true, true);
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
            TF2_AddCondition(attacker, TFCond_CritCanteen, 6.0, attacker);
		}

		}
                    



            }

            if (iClassAttacker == TFClass_Medic)
            {
                int Weapon3 = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);

                if(IsSolemnVow(Weapon3))
                {
                    damage = 0.0;
                    return Plugin_Handled;
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

                    if (IsBigEarner(weapon))
                    {
                        TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);
                    }

                    if(IsSpycicle(weapon))
                    {
                        TF2Attrib_AddCustomPlayerAttribute(victim, "damage penalty", 0.7, 3.0);
                        TF2Attrib_AddCustomPlayerAttribute(attacker, "damage penalty", 0.7, 3.0);
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

                    
                    

                    if (HasDiamondback(attacker)) //Diamondback gives 1 crits on backstab
                    {
                        int iCrits = GetEntProp(attacker, Prop_Send, "m_iRevengeCrits");
                        SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", iCrits+1);
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
                    TF2_AddCondition(attacker, TFCond_DefenseBuffNoCritBlock, 2.0);
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

                if (!IsBoss(victim))
                {
                    switch (damagecustom)
                    {
                        case TF_CUSTOM_CHARGE_IMPACT, TF_CUSTOM_BOOTS_STOMP:
                        {
                            //damage *= 1.5;
                            if (IsTank(victim))
                            {
                                TF2_StunPlayer(victim, 0.5, 0.0, TF_STUNFLAG_BONKSTUCK, attacker);
                                SetHealingDebuff(victim, g_HealDebuff, 0.5, attacker);  
                            }
                            return Plugin_Changed;
                        }
                        case TF_CUSTOM_BASEBALL:
                        {
                            if(IsSandman(weapon))
                            {
                                SetHealingDebuff(victim, g_HealDebuff, 0.5, attacker);  
                            }

                            if(IsWrap(weapon)){
                                SetHealingDebuff(victim, g_HealDebuff, 0.5, attacker);  
                            }
                            
                            return Plugin_Changed;
                        }
                    }
                }
    }




    return Plugin_Continue;
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
                    
                    float flDistanceVertical = 20.0;
                        
                    vVelocity[2] -= flDistanceVertical; // we always want to go a bit up
                    
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
	{

		if(IsAnyRobot(victim) && damagetype == DMG_FALL)
		{
			// PrintToChatAll("Taking regular fall damage %N", victim);
			damage *= 0.5;
			return Plugin_Changed;
		}
	}else
	{
		if(IsAnyRobot(attacker) && damagetype == DMG_FALL)
		{
			// PrintToChatAll("Else attacker was %N", attacker);
			// PrintToChatAll("Else vicitm was %N", victim);
			damage *= 0.25;
			return Plugin_Changed;
		}
	}

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
                    damage *= 0.80;
                    if(g_cv_bDebugMode)PrintToChatAll("Set damage to %f", damage);
                    return Plugin_Changed;
                    
                }
                    
                    
            }

            if (IsElectric(weapon) && IsAnyRobot(victim))
            {
                TF2_AddCondition(victim, TFCond_HealingDebuff, g_ElectricStunDuration, attacker);

                SetHealingDebuff(victim, g_HealDebuff, g_ElectricStunDuration, attacker);
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
                        if (decapitations == 0 || decapitations == 1)
                        {
                            SetEntProp(attacker, Prop_Send, "m_iDecapitations", 0);    
                        }else
                        {
                            SetEntProp(attacker, Prop_Send, "m_iDecapitations", decapitations - 2);    
                        }
                        
                    }
                    

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
                        condmodifier = 1.15;
                    }
                    case 3: 
                    {
                        condmodifier = 1.2;
                    }
                    case 4: 
                    {
                        condmodifier = 1.25;
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

// float g_Attribute_Display_CollDown[MAXPLAYERS + 1] = 10.0;
// float g_Attribute_Display [MAXPLAYERS + 1] = 0.0;

void DisplayMMStats(int client, char[] chat_display)
{
    if (g_Attribute_Display[client] < GetEngineTime() && b_Attribute_Display[client] && !strlen(chat_display) < 1)
    {
        MC_PrintToChatEx(client, client, "{teamcolor}Custom Buffs:%s",chat_display);
        MC_PrintToChatEx(client, client, "{teamcolor}Type {orange}/mminfo {teamcolor}to toggle this information on/off");
        g_Attribute_Display[client] = GetEngineTime() + g_Attribute_Display_CollDown;
    }
}
//Functions to handle attributes for humans
public Action Event_post_inventory_application(Event event, const char[] name, bool dontBroadcast)
{

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    //CreateTimer(0.8, AddAttributes, client);




    if (!IsAnyRobot(client) && IsValidClient(client) && IsPlayerAlive(client))
    {
        int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
        int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
        int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
        int Weapon4 = GetPlayerWeaponSlot(client, 3);
        char chat_display[512];

        if (TF2_GetPlayerClass(client) == TFClass_Pyro)
        {
            if(Weapon1 != -1)
            {
            TF2Attrib_SetByName(Weapon1, "dmg taken from fire reduced", 0.5);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Pyro: {orange}+50%%% fire resistance",chat_display);
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
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Axtinguisher: {orange}Provides 5 second speed boost{teamcolor}and{orange}5 seconds of Battalion Backup buff",chat_display);

            }


        }
        if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
        {
       
            if (IsDemoKnight(Weapon1, Weapon2))
            {
                
                TF2Attrib_SetByName(Weapon3, "dmg taken from bullets reduced", 0.75);
                TF2Attrib_SetByName(Weapon3, "dmg taken from crit reduced", 0.75);
                TF2Attrib_SetByName(Weapon3, "dmg from melee increased", 0.75);
                TF2Attrib_SetByName(Weapon3, "fire rate bonus", 0.75);

                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Demoknight: Melee weapon {orange}+25%%%% faster\n{teamcolor}Demoknight: {orange}+25%%% {teamcolor}bullet, melee and crit damage resistance",chat_display);
       


            }else
            {

                TF2Attrib_RemoveByName(Weapon3, "dmg taken from bullets reduced");
                TF2Attrib_RemoveByName(Weapon3, "dmg taken from crit reduced");
                TF2Attrib_RemoveByName(Weapon3, "dmg from melee increased");
                TF2Attrib_RemoveByName(Weapon3, "fire rate bonus");
                if (Weapon1 != -1)
                {
                    TF2Attrib_SetByName(Weapon1, "Reload time decreased", 0.75);
                    SetDemoDamageBuff(Weapon1);
                    
                }

                if (Weapon2 != -1)
                {
                    TF2Attrib_SetByName(Weapon2, "Reload time decreased", 0.75);
                    SetDemoDamageBuff(Weapon2);
                    
                }
                    Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Demoman: All of projectile weapons {orange}Reload 25%%% faster\n{teamcolor}All weapons deal {orange}more damage{teamcolor} the more damage you do",chat_display);
            }

            if (Weapon3 != -1)
            {
                SetDemoDamageBuff(Weapon3);
            }

            

            if (IsStockOrAllClassWeapon(Weapon3))
            {
                TF2Attrib_SetByName(Weapon3, "max health additive bonus", 20.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Melee: {orange}+20 max health",chat_display);
            }   
            if (IsCaber(Weapon3))
            {
                float dmgbonus = 2.0;
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Caber: {orange}%i0 %% increased damage bonus{teamcolor}",chat_display, RoundToNearest(dmgbonus));
                TF2Attrib_SetByName(Weapon3, "damage bonus", dmgbonus);
                TF2Attrib_SetByName(Weapon3, "crits_become_minicrits", 1.0);
                
                // TF2Attrib_SetByName(Weapon3, "blast dmg to self increased", 1000.0);
            }

            
        }

        if (TF2_GetPlayerClass(client) == TFClass_Heavy)
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Your minigun deals {orange}-20%%% damage{teamcolor} against robots",chat_display);

            if(IsNatascha(Weapon1))
            {
                
                TF2Attrib_SetByName(Weapon1, "speed_boost_on_hit", 3.0);
                TF2Attrib_SetByName(Weapon1, "aiming movespeed increased", 1.2);
                
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Heavy Natascha: {orange}+3 second speed boost on hit +20% faster movespeed while spun up{teamcolor}",chat_display);
            }

            if(IsTomiSlav(Weapon1))
            {
                
                TF2Attrib_SetByName(Weapon1, "minigun spinup time decreased", 0.4);
                TF2Attrib_SetByName(Weapon1, "closerange backattack minicrits", 1.0);
                
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Tomislav: {orange}+Mini-crits targets when fired at their back from close range. +60%% faster {teamcolor}rev up speed",chat_display);
                
            }

            if(IsStockOrAllClassWeapon(Weapon3))
            {
                TF2Attrib_SetByName(Weapon3, "maxammo primary increased", 1.5);
                TF2Attrib_SetByName(Weapon3, "maxammo secondary increased", 1.5);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Melee: {orange}+50%% maxammo on all weapons",chat_display);
            }

        }

        if (TF2_GetPlayerClass(client) == TFClass_Sniper)
        {
            if(IsStockOrAllClassWeapon(Weapon3))
            {
                
                TF2Attrib_SetByName(Weapon3, "mult_player_movespeed_active", 1.15);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Sniper Stock Melee: {orange}+15%% move speed{teamcolor} while active",chat_display);
            }

            if(IsShahanshah(Weapon3))
            {
                TF2Attrib_SetByName(Weapon3, "dmg bonus while half dead", 3.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Shahansah {orange}+200%% damage{teamcolor} while half dead",chat_display);
            }
            
        }

        if (TF2_GetPlayerClass(client) == TFClass_Scout)
        {

           
            
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Scout Power: {orange}Greatly reduced respawn time\nAll weapons {orange}penetrate robots",chat_display);
            TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
            TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
            if (IsStockOrAllClassWeapon(Weapon3) && Weapon1 != -1 &&  Weapon2 != -1)
            {
                // TF2Attrib_SetByName(client, "maxammo primary increased", 1.5);
                // // TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 1.5);
                TF2Attrib_AddCustomPlayerAttribute(client, "maxammo primary increased", 1.5);
                TF2Attrib_AddCustomPlayerAttribute(client, "maxammo secondary increased", 1.5);
                TF2Attrib_SetByName(Weapon1, "faster reload rate", 0.8);
                TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.8);

                // TF2Attrib_SetByName(Weapon1, "Reload time decreased", 0.6);

                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Bat: Provides all weapons with {orange}+50%% maxammo and +20%% faster reload",chat_display);
            }else if (!IsStockOrAllClassWeapon(Weapon3) && Weapon1 != -1 &&  Weapon2 != -1)
            {
                TF2Attrib_RemoveByName(Weapon1, "faster reload rate");
                TF2Attrib_RemoveByName(Weapon2, "faster reload rate");
            }

            if (IsAtomizer(Weapon3))
            {
                TF2Attrib_SetByName(Weapon3, "air dash count", 6.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Atomizer: {orange}6 Bonus Jumps",chat_display);
            }

            if (IsPistol(Weapon2))
            {
                    TF2Attrib_SetByName(Weapon2, "speed_boost_on_hit", 2.0);
                    Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Scout Pistol: {orange}On Hit: {teamcolor}Speed boost for 2.0 seconds",chat_display);
            }

            // if(IsMadMilk)
            // {
            //     TF2Attrib_SetByName(Weapon2, "applies snare effect", 0.65);
            //     Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Mad Milk: {orange}-35%%% move speed on targets upgrade",chat_display);
            // }
        }

        if(TF2_GetPlayerClass(client) == TFClass_Engineer)
        {
            if (IsPistol(Weapon2))
            {
                    TF2Attrib_SetByName(Weapon2, "clip size bonus", 2.0);
                    // TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.5);
                    Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Engineer Pistol: {orange}+100%% clip size",chat_display);
            }
        }

        if (TF2_GetPlayerClass(client) == TFClass_Spy)
        {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Spy Power: {orange}Use enemy teamporters by touching their spawn",chat_display);
        }

        if (TF2_GetPlayerClass(client) == TFClass_Medic)
        {
    //         	g_vita_saw_heal = ReadIntVar(stat_buffer, "heal", 0);
	// g_vita_saw_uber = ReadIntVar(stat_buffer, "uber-gain", 0);
	// g_vita_saw_cooldown = ReadIntVar(stat_buffer, "crit-heal-cooldown", 0);
	// g_vita_saw_allow_overheal = ReadIntVar(stat_buffer, "allow-overheal", 0);
            // if (IsVitaSaw(Weapon3))
            // {
            //     TF2CustAttr_SetString(Weapon3, "heal-teammate", "heal=40 uber-gain=0.015 crit-heal-cooldown=10 allow-overheal=0");
            // }

            //  if(IsSyringeGun(Weapon1))
            // {
            //     TF2CustAttr_SetString(Weapon1, "syringe-uber-gain", "combo_time=1.5 buff_duration=20.0 buff_max=20 buff_min=5");
                
            //     //Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Blutsauger: {orange}Mad milk syringes{teamcolor}",chat_display);
            // }
            if(IsBlutsauger(Weapon1))
            {
                TF2Attrib_SetByName(Weapon1, "max health additive bonus", 20.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Blutsauger: {orange}+20 max health{teamcolor}",chat_display);
            }

            if(IsOverdose(Weapon1) && Weapon2 != -1)
            {
                TF2Attrib_SetByName(Weapon2, "overheal decay disabled", 1000.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Overdose: Provides your medigun the {orange}overheal decay disabled upgrade",chat_display);
            }else
            {
                //Remove the attribute if overdose is not present, as it remains on loadout switch
                TF2Attrib_RemoveByName(Weapon2, "overheal decay disabled");
            }

            if(!IsOverdose(Weapon1) && Weapon2 != -1)
            {
                //Remove the attribute when changing loadout
                TF2Attrib_RemoveByName(Weapon2, "overheal decay disabled");
            }

            if(IsAmputator(Weapon3) && Weapon1 != -1)
            {
                TF2Attrib_SetByName(Weapon3, "dmg taken from crit reduced", 0.3);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Amputator: Provides {orange}+50%%% Passive critical resistance",chat_display);
            }

            if(IsSolemnVow(Weapon3))
            {
                TF2Attrib_SetByName(Weapon2, "healing mastery", 4.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Solemn Vow: All weapons deal {darkred}no damage!{teamcolor} But you have the{orange}Healing Mastery upgrade",chat_display);    
 
            }else
            {
                TF2Attrib_RemoveByName(Weapon2, "healing mastery");
            }

            if(IsSolemnVow(Weapon3) && IsCrossbow(Weapon1))
            {
                TF2Attrib_SetByName(Weapon1, "damage penalty", 1.4);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Solemn Vow: Crusaders Crossbow heals {orange}+40%%% more",chat_display);
            }else
            {
                TF2Attrib_RemoveByName(Weapon1, "damage penalty");
            }

            if(IsStockOrAllClassWeapon(Weapon3))
            {
                TF2Attrib_SetByName(Weapon3, "ubercharge rate bonus", 1.25);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Medic Stock Melee: Provides your medigun an additional {orange}25%%% faster build rate",chat_display);
            }

            if (IsQuickfix(Weapon2))
            {
                TF2Attrib_SetByName(Weapon2, "generate rage on heal", 1.0);
                TF2Attrib_SetByName(Weapon2, "increase buff duration", 0.8);
			    TF2CustAttr_SetString(Weapon2, "rage fill multiplier", "0.7");
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Quickfix: {orange}Medic MvM Shield",chat_display);
            }

            if(IsVaccinator(Weapon2))
            {
                TF2Attrib_SetByName(Weapon2, "medigun bullet resist passive", 0.2);
			    TF2Attrib_SetByName(Weapon2, "medigun bullet resist deployed", 0.85);
			    TF2Attrib_SetByName(Weapon2, "medigun blast resist passive", 0.2);
			    TF2Attrib_SetByName(Weapon2, "medigun blast resist deployed", 0.85);
			    TF2Attrib_SetByName(Weapon2, "medigun fire resist passive", 0.2);
			    TF2Attrib_SetByName(Weapon2, "medigun fire resist deployed", 0.85);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Vaccinator: {orange}+10%%% higher resistances",chat_display);
            }

            if(Weapon2 != -1)
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}All Medic Melee: Organs: {orange}Restore up to 50% uber on death",chat_display);
                TF2Attrib_SetByName(Weapon3, "ubercharge_preserved_on_spawn_max", 0.5);
            }
        }
        
        if (IsEyelander(Weapon3))
        {

            //attribute "add head on hit"//
            g_Eyelander_Counter[client] = 0;
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Eyelander: {orange}gains a head every hit{teamcolor} vs robots",chat_display);
        }

        if (IsZatoichi(Weapon3))
        {
            
            TF2Attrib_SetByName(Weapon3, "heal on hit for rapidfire", 15.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Half-Zatoichi: {orange}gains 35 HP on hit",chat_display);
        }

        if (IsSniperRifle(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "explosive sniper shot", 1.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Sniper Rifle: {orange}Explosive headshots {teamcolor}upgrade",chat_display);
           
        }

        if (IsBazaar(Weapon1))
        {

            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Bazaar Bragin: {orange}Gain head on headshot{teamcolor}, but {darkred}Lose 2 heads{teamcolor} on bodyshot",chat_display);
           
        }

        if (IsClassic(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "sniper no headshot without full charge", 0.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Classic: {orange}Headshot anytime",chat_display);
           
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
                TF2Attrib_SetByName(Weapon3, "mult_player_movespeed_active", 1.15);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Big Earner:{orange}Grants 15% movespeed while actove",chat_display);
            }

            if(IsSpycicle(Weapon3))
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Spycicle:{orange}On Backstab: Slows firing speed by 30% for 2 second",chat_display);
            }

            if (IsEnforcer(Weapon1))
            {
                TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
                TF2CustAttr_SetString(Weapon1, "dmg-bonus-vs-sapped-buildings", "damage=3.0");
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Gun: {orange}Projectile penetration {teamcolor}bonus & {orange}200%%% Damage bonus {teamcolor}vs sapped buildings",chat_display);
            }

            if (IsAmbassador(Weapon1))
            {
                TF2Attrib_SetByName(Weapon1, "crit_dmg_falloff", 0.0);
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Ambassador: {orange}No critical damage faloff {teamcolor}penalty",chat_display);
            }
        }

        if (IsHuntsMan(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
            TF2Attrib_SetByName(Weapon1, "bleeding duration", g__bleed_duration_bonus);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Huntsman: {orange}Projectile penetration {teamcolor}upgrade",chat_display);
        }

        if (IsCandyCane(Weapon3))
        {
            TF2Attrib_SetByName(Weapon3, "health from packs increased", 1.33);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Candy Cane:  {orange}+33%%% more health{teamcolor} from healthpacks",chat_display);
        }

        if (IsMarketGardner(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Market Gardner: {orange}+50%%% damage bonus while rocket jumping{teamcolor}",chat_display);
        }

        if (IsElectric(Weapon1) || IsElectric(Weapon2))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Your electric weapons {orange}reduce robot heal rate{teamcolor} for %0.1f seconds on hit",chat_display, g_ElectricStunDuration);
        }

        if (IsWarriorSpirit(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Warrior Spirit: {orange}+50 HP{teamcolor} on hit against robots",chat_display);
        }

        if (IsKGB(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}KGB: {orange}+7 seconds of critical hits{teamcolor} when landing a quick 3 hit combo vs robots",chat_display);
        }
        if (IsJetpack(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "falling_impact_radius_pushback", 0.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Jetpack: {darkred}Deals no knockback{teamcolor} when landing",chat_display);
        }
        if (IsAirStrike(Weapon1))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}AirStrike: {orange}Gains additional clip{teamcolor} by doing %i damage to robots", chat_display, RoundToNearest(g_AirStrikeDMGRequirement));
        }
        if (IsBlackBox(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "heal on hit for rapidfire", 30.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Blackbox: On Hit: Up to {orange}30 bonus health",chat_display);
        }

        if (isBeggarsBazooka(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 3.0);
            // TF2Attrib_SetByName(Weapon1, "fire rate bonus with reduced health", 0.4);
            // TF2Attrib_SetByName(Weapon1, "Reload time decreased", 0.8);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Beggars Bazooka: {orange}+3 clip size",chat_display);
        }

        if (isLibertyLauncher(Weapon1))
        {
            if (IsAnyBanner(Weapon2))
            {
                TF2Attrib_SetByName(Weapon2, "increase buff duration", 3.0);
                
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Liberty Launcher: Provides banner {orange}+200%%%% longer buff duration{teamcolor}",chat_display);
            }else
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Liberty Launcher: {orange}equip a banner to get the buff!",chat_display);
            }
        }

        if (IsAnyRocketLauncher(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "Reload time decreased", 0.8);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Primary {orange}+20%% faster reload",chat_display);
        }

        if (IsRocketLauncher(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "Blast radius increased", 1.5);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Rocket Launcher {orange}+50%% larger explosion radius",chat_display);
        }



        if (HasFrontierJustice(client))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Frontier Justice: {orange}Gains 1 revenge crit{teamcolor} every %i damage your sentry does to robots",chat_display, RoundToNearest(g_FrontierJusticeDMGRequirement));
        }

        if (IsShotGun(Weapon1))
        {
            TF2Attrib_SetByName(Weapon1, "projectile penetration", 1.0);
            TF2Attrib_SetByName(Weapon1, "Reload time decreased", 0.7);
            TF2Attrib_SetByName(Weapon2, "Reload time decreased", 0.8);
            TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.8);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Shotgun: {orange}Penetrates through enemies{teamcolor} and {orange}+20%%% faster firing and reload speed",chat_display);
        }
        if (IsShotGun(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
            TF2Attrib_SetByName(Weapon2, "Reload time decreased", 0.8);
            TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.8);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Shotgun: {orange}Penetrates through enemies{teamcolor} abd {orange}+20%%% faster firing and reload speed",chat_display);
        }

        if (IsReserveShooter(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "minicrits become crits", 1.0);
            TF2Attrib_SetByName(Weapon2, "single wep deploy time decreased", 0.6);
            TF2CustAttr_SetString(Weapon2, "dmg-crit-vs-jumping-robots", "damage=2.0 critType=0");
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Reserve Shooter: {orange}Minicrits become crits, {orange}+100%% damage bonus vs jumping robots.{orange}+40%% faster deploy speed",chat_display);
        }

        if(IsSandman(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Baseball: {orange}Reduce robots heal rate",chat_display);
        }
        if(IsWrap(Weapon3))
        {
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Ornament: {orange}Reduce robots heal rate",chat_display);
        }

        if(IsCleaver(Weapon2))
        {
            TF2Attrib_SetByName(Weapon2, "bleeding duration", g__bleed_duration_bonus);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Cleaver: {orange}On Hit: Bleed for 10 seconds",chat_display);
        }

        if(IsSMG(Weapon2))
        {
            // TF2Attrib_SetByName(Weapon2, "slow enemy on hit major", 1.0);
            // TF2Attrib_SetByName(Weapon2, "slow enemy on hit major", 1.0);
            TF2Attrib_SetByName(Weapon2, "speed_boost_on_hit", 2.0);
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}SMG: {orange}On Hit: {teamcolor}Speed boost for 2.0 seconds",chat_display);
        }

        if(IsShiv(Weapon3))
        {
            // TF2Attrib_SetByName(Weapon2, "slow enemy on hit major", 1.0);
            TF2Attrib_SetByName(Weapon3, "bleeding duration", 20.0);
            
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Tribalmans Shiv: {orange}Bleed lasts 20 seconds",chat_display);
        }

        if (IsWearable(Weapon2))
        {
            int razorback = FindTFWearable(client, 57);
            if (IsValidEntity(razorback) && Weapon1 != -1 && Weapon3 != -1)
            {
                Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Razorback: {orange}+50%% melee damage resistance. {teamcolor}Will instantly recharge and stun spy robot when triggered",chat_display);
                TF2Attrib_SetByName(Weapon1, "dmg from melee increased", 0.5);
                TF2Attrib_SetByName(Weapon3, "dmg from melee increased", 0.5);
            }else
            {
                TF2Attrib_RemoveByName(Weapon1, "dmg from melee increased");
                TF2Attrib_RemoveByName(Weapon3, "dmg from melee increased");
            }
        }

        if(IsGunSlinger(Weapon3))
        {
            // TF2Attrib_SetByName(Weapon2, "slow enemy on hit major", 1.0);
            TF2Attrib_SetByName(Weapon3, "mult_player_movespeed_active", 1.15);
            // TF2Attrib_SetByName(Weapon3, "engy disposable sentries", 2.0);
            // TF2Attrib_SetByName(client, "engy disposable sentries", 2.0);
            // TF2Attrib_SetByName(Weapon4, "engy disposable sentries", 2.0);
            
            // TF2CustAttr_SetString(Weapon3, "robot engineer", "sentries=2");
            Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Gunslinger: {orange}+15%% faster movement speed",chat_display);
            
        }
        // if (IsSapper(Weapon2))
        // {
        //     // Format(chat_display, sizeof(chat_display), "%s\n{teamcolor}Sapper: {orange}Stuns robots{teamcolor} or some shit",chat_display);
        //     // TF2Attrib_SetByName(Weapon2, "robo sapper", 4.0);
            
        // }
        DisplayMMStats(client, chat_display);

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

// bool IsBat(int weapon){
// 	if(weapon == -1 && weapon <= MaxClients) return false;
	
// 	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
// 	{
// 		//If other allclass are added, add here
// 	case 0, 190, 660, 30667: 
// 		{
// 			return true;
// 		}
// 	}
// 	return false;
// }

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
// bool IsVitaSaw(int weapon)
// {
//     if(weapon == -1 && weapon <= MaxClients) return false;
	
// 	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
// 	{
// 		//If others are added, add them here
// 	case 173: 
// 		{
// 			return true;
// 		}
// 	}
// 	return false;
// }

// bool IsSyringeGun(int weapon)
// {
//     if(weapon == -1 && weapon <= MaxClients) return false;
	
// 	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
// 	{
// 		//If others are added, add them here
// 	case 17,204: 
// 		{
// 			return true;
// 		}
// 	}
// 	return false;
// }

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

// bool IsWearable(int weapon)
// {

//     if(weapon == -1 && weapon <= MaxClients)
//     {
//         return true;
//     }else
//     {
//         return false;       
//     }
	

// }

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

// PrintToChatAll("Setting Debuff on %N", client);
    TF2_AddCondition(victim, TFCond_HealingDebuff, duration, attacker);
    TF2_AddCondition(victim, TFCond_Sapped, duration, attacker);
    TF2Attrib_AddCustomPlayerAttribute(victim, "mult_health_fromhealers_penalty_active", value, duration);

//         int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
//         int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
//         int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
// TF2Attrib_AddCustomPlayerAttribute()
//     if (Weapon1 != -1)
//     {
//         TF2Attrib_SetByName(Weapon1, "fire rate penalty", value);
//     }

//     if (Weapon2 != -1)
//     {
//         TF2Attrib_SetByName(Weapon2, "fire rate penalty", value);
//     }

//     if (Weapon3 != -1)
//     {
//         TF2Attrib_SetByName(Weapon3, "fire rate penalty", value);
//     }

}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
        //Code To Handle Sentry Vuln on spun up heavies
		if (IsAnyRobot(client) && condition == TFCond_Slowed && TF2_GetPlayerClass(client) == TFClass_Heavy)
		{	
            // PrintToChatAll("%N WAS SPUN UP", client);
            TF2Attrib_AddCustomPlayerAttribute(client, "SET BONUS: dmg from sentry reduced", 1.25);
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

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	
        //Code To Handle Sentry Vuln on spun up heavies
		if (IsAnyRobot(client) && condition == TFCond_Slowed && TF2_GetPlayerClass(client) == TFClass_Heavy)
		{	
            // PrintToChatAll("%N WAS DONE SPUN UP", client);
            TF2Attrib_AddCustomPlayerAttribute(client, "SET BONUS: dmg from sentry reduced", 1.0);
		}



	
}
