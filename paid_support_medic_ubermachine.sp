#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
#include <tf_custom_attributes>
#include <sdkhooks>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"UberMachine"
#define ROBOT_ROLE "Healer"
#define ROBOT_CLASS "Medic"
#define ROBOT_SUBCLASS "Healer"
#define ROBOT_DESCRIPTION "Uber-Saw Medic Healer"
#define ROBOT_TIPS "UBER!" 

#define GMEDIC             "models/bots/medic/bot_medic.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_demoman/giant_demoman_loop.wav"

#define DMG_TYPE_MELEE 134221952
#define DMG_TYPE_MELEE_CRIT 135270528
 
bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
int g_Heal_Bolts_Hits_Needed = 16;
int g_healcount = 0;
float g_duration = 8.0;
float g_organ_duration_bonus_modifier = 2.0;
float g_organ_bonus = 0.0;
public Plugin:myinfo =
{
	name = "[TF2] Be the Dr Livesey",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Be a chad bot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeGiantMedic, PLUGIN_VERSION);
	for(int client = 1 ; client <= MaxClients ; client++)
	{
		if(IsClientInGame(client))
		{
			SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
		}
	}
	// AddNormalSoundHook(BossIcebear);
}


public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack); // hook for when someone joins in the middle of a round
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantMedic_MakeGiantMedic", Native_SetGiantMedic);
//	CreateNative("BeGiantMedic_IsGiantMedic", Native_IsGiantMedic);
	return APLRes_Success;
}
 
public OnMapStart()
{
	PrecacheModel(GMEDIC);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
   
}
 
public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

	}
}

MakeGiantMedic(client)
{
	TF2_SetPlayerClass(client, TFClass_Medic);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GMEDIC);
   	
	int iHealth = 2210;
	int MaxHealth = 150;
	int iAdditiveHP = iHealth - MaxHealth;
   
	TF2_SetHealth(client, iHealth);
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	// TF2Attrib_SetByName(client, "move speed penalty", 0.75);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	TF2Attrib_SetByName(client, "health regen", 20.0);
	TF2Attrib_SetByName(client, "head scale", 0.75);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	// TF2_AddCondition(client, TFCond_RadiusHealOnDamage);
	PrintHintText(client, "%s", ROBOT_TIPS);

	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public TF2_OnConditionRemoved(int client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_RuneHaste)
    {
       TF2_AddCondition(client,TFCond_SpeedBuffAlly, 0.1);
	   //TF2_RemoveCondition(client, TFCond_Taunting);
//	   TF2_AddCondition(client,TFCond_Charging, 2.5);

	
	  // TF2_AddCondition(client,TFCond_HalloweenSpeedBoost, 15.0);
    }
}


 
stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", NewHealth, 1);
}
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
			GiveGiantMedic(client);
}


// #define FOPPISH 878
// #define POWDERED 30069

#define HeatOfWinter 30356
#define UberMench 30410
#define TeamCaptain 378

stock GiveGiantMedic(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_bonesaw", 37, 6, 1, 0, 0);
		// CreateRoboWeapon(client, "tf_weapon_medigun", 29, 6, 1, 1, 0);

		CreateRoboHat(client, HeatOfWinter, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, UberMench, 10, 6, 0.0, 1.0, 1.0);
		CreateRoboHat(client, TeamCaptain, 10, 6, 0.0, 1.0, -1.0);
		
		// CreateRoboHat(client, FOPPISH, 10, 6, 3100495.0, 1.0, -1.0); 
		// CreateRoboHat(client, POWDERED, 10, 6, 6901050.0, 1.0, -1.0); 
		// CreateRoboHat(client, 30149, 10, 6, 0.0, 1.0, -1.0);

		//int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		 int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		if(IsValidEntity(Weapon3))
		{
			//TF2Attrib_RemoveAll(Weapon3);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.3);
			TF2Attrib_SetByName(Weapon3, "fire rate bonus", 1.25);
			TF2Attrib_SetByName(Weapon3, "add uber charge on hit", 0.1);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.25);	
			// TF2CustAttr_SetString(Weapon3, "heal-teammate", "heal=40 allow-overheal=0");
			
		}
		g_healcount = 0;

		TF2_AddCondition(client, TFCond_RestrictToMelee);
		RequestFrame(MakeMediGun, client);
	}
}

stock MakeMediGun(client)
{
	CreateRoboWeapon(client, "tf_weapon_medigun", 29, 6, 1, 1, 0);

		// 	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		
		// if(IsValidEntity(Weapon2))
		// {
		// 	TF2Attrib_RemoveAll(Weapon2);
		// 	TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
		// 	TF2Attrib_SetByName(Weapon2, "heal rate bonus", 2.0);
		// 	TF2Attrib_SetByName(Weapon2, "overheal penalty", 0.01);
		// }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{

		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_RELOAD|IN_USE|IN_ATTACK2) ) 
		{
			//  PrintToChatAll("Press");
            g_button_held[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_RELOAD|IN_USE|IN_ATTACK2) ) 
		{
			//  PrintToChatAll("Release");
			g_button_held[client] = false;
            
		}
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		// UpdateCharge(client);
		DrawHUD(client);
		
	}
	return Plugin_Continue;
}

bool isready;
#define CHAR_FULL "■"
#define CHAR_EMPTY "□"

void DrawHUD(int client)
{
	char sHUDText[128];
	char sProgress[32];
	// int iPercents = RoundToCeil((GetEngineTime() / g_Recharge[client])  * 100.0);
	int iCountDown = g_Heal_Bolts_Hits_Needed - g_healcount;

	int iCountDownActive = RoundToCeil(g_Recharge[client] + g_organ_bonus - (GetEngineTime()));

	int iPercents = RoundToCeil(iCountDownActive / g_duration + g_organ_bonus * 100.0);
	for (int j = 1; j <= 10; j++)
	{
	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}

	if (TF2_IsPlayerInCondition(client, TFCond_CritHype))
	{
	Format(sHUDText, sizeof(sHUDText), "Uber Injection! %i", iCountDownActive);
	//Format(sHUDText, sizeof(sHUDText), "Speed Injection Active!\n               %s", sProgress);
	SetHudTextParams(1.0, 0.8, 0.5, 255, 69, 0, 255);
	}
	else if(iCountDown <= 0)
	{


	Format(sHUDText, sizeof(sHUDText), "Uber Injection: Ready!");
	SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);

	}else
	{
	Format(sHUDText, sizeof(sHUDText), "Uber Injection: %i", iCountDown);
	SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);


	}

	ShowHudText(client, -2, sHUDText);

	if (!isready && iCountDown <= 0)
	{
	TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
	// PrintToChatAll("Ready!");
	isready = true;	
	}

	if (g_button_held[client] && iCountDown <= 0 || IsFakeClient(client))
	{
	isready = false;

	TF2_AddCondition(client, TFCond_CritHype, g_duration + g_organ_bonus);
	TF2_AddCondition(client, TFCond_Buffed, g_duration + g_organ_bonus);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, g_duration + g_organ_bonus);
	TF2_AddCondition(client, TFCond_RuneHaste, g_duration + g_organ_bonus);
	// PrintToChatAll("SELF BUFF DURATION %f", GetOrganBonus(client)); 
	g_healcount = 0;
	SetEntProp(client, Prop_Send, "m_iDecapitations", 0);
	g_Recharge[client] = GetEngineTime() + g_duration;
	}
}

float GetOrganBonus(int client)
{

	int organs = GetEntProp(client, Prop_Send, "m_iDecapitations");
	// PrintToChatAll("Organs %i", organs);
	if (organs == 0)
	{
		return 0.0;
	}else
	{
		return (float(organs) / g_organ_duration_bonus_modifier);	
	}
	
}


public bool IsKritzed(int client){
	if (TF2_IsPlayerInCondition(client, (TFCond_Kritzkrieged)) || TF2_IsPlayerInCondition(client, (TFCond_Buffed)) || TF2_IsPlayerInCondition(client, (TFCond_CritCanteen)))
	{
		return true;
	}else
	{
		return false;
	}
}    



public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if (IsValidClient(victim) && IsRobot(attacker, ROBOT_NAME))
	{
		if(!TF2_IsPlayerInCondition(attacker, TFCond_CritHype))
		{
			g_healcount++;
			g_organ_bonus = GetOrganBonus(attacker);
		}
	}
	return Plugin_Continue;
}

public Action OnTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	//TraceAttack fires everytime hitscan is used and in some cases, for syringes and Dragon's fury fireballs etc.	
	//Vita-saw code - start
	
	// PrintToChatAll("Tracking! 1");
	if((IsValidEntity(victim) && IsValidEntity(attacker) && IsValidEntity(inflictor)) &&
	(victim <= MaxClients && victim > 0) &&
	(attacker <= MaxClients && attacker > 0) &&
	(inflictor <= MaxClients && inflictor > 0)) //Validity checks
	{

	// PrintToChatAll("Tracking!2");
	/*
	Checks if: The weapon is the vita-saw, the medic is hitting a teammate, 
	the inflictor is the medic and actually playing the class, 
	damagetype is also checked to determine if the trace came from a melee weapon.
	*/

	// char stat_buffer[256];
	// if (!TF2CustAttr_GetString(attacker, "vita-saw-heal", stat_buffer, sizeof(stat_buffer))) {
	// 	return;
	// }
		if((IsClientInGame(victim) && IsClientInGame(attacker) && IsClientInGame(inflictor)) &&
		(TF2_GetClientTeam(attacker) == TF2_GetClientTeam(victim))
		&& IsRobot(attacker, ROBOT_NAME)
		&& (inflictor == attacker) 
		&& (damagetype == DMG_TYPE_MELEE || damagetype == DMG_TYPE_MELEE_CRIT))
		{

			int healer = attacker;
			int target = victim;

			if(!TF2_IsPlayerInCondition(healer, TFCond_CritHype))
			{
				g_healcount++;
				g_organ_bonus = GetOrganBonus(attacker);
			}


			//PrintToChatAll("%N Healed %N, healcount was %i ", healer, target, g_healcount);

			if (TF2_IsPlayerInCondition(healer, TFCond_CritHype))
			{
			float team_duration = g_duration  + g_organ_bonus;
			//PrintToChatAll("Target Duration %f", team_duration);
			TF2_AddCondition(target, TFCond_SpeedBuffAlly, team_duration);
			TF2_AddCondition(target, TFCond_Buffed, team_duration);
			
			}


			// g_healcount++;
			// int decap = GetEntProp(attacker, Prop_Send, "m_iDecapitations");
			// PrintToChatAll("Decap: %i", decap);
			 //SetEntProp(iClient, Prop_Send, "m_iDecapitations", GetEntProp(iClient, Prop_Send, "m_iDecapitations") + 1);
		}
	}
	return Plugin_Continue;
}

