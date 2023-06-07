#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
//#include <tf_custom_attributes>
#include <sdktools>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Sentro"
#define ROBOT_ROLE "Healer"
#define ROBOT_CLASS "Medic"
#define ROBOT_SUBCLASS "Healer"
#define ROBOT_DESCRIPTION "AOE Heal uber + Fireball"
#define ROBOT_TIPS "Fireball gets stronger when kritze\nYour uber AOE heals all teammes in close proximity"
#define ROBOT_ON_DEATH "This robot's fireball gets stronger when kritzkrieged"

#define GMEDIC             "models/bots/medic/bot_medic.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_demoman/giant_demoman_loop.wav"
#define SOUND_HEAL_READY "player/recharged.wav"

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"
 


public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Sentror",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Medic from MvM",
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
	robot.deathtip = ROBOT_ON_DEATH;
	AddRobot(robot, MakeGiantMedic, PLUGIN_VERSION);
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
//



	PrecacheSound(SOUND_HEAL_READY);
   
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
   
		
	int iHealth = 1500;
	
	
	int MaxHealth = 150;
	int iAdditiveHP = iHealth - MaxHealth;
   
	TF2_SetHealth(client, iHealth);
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	TF2Attrib_SetByName(client, "health regen", 20.0);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);


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
 
#define Bytedbeak 30052
#define Grimhatte 383
#define Foppish 878

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 25.0;
float g_skill;

stock GiveGiantMedic(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_medigun", 29, 6, 1, 1, 0);
		CreateRoboWeapon(client, "tf_weapon_spellbook", 1132, 6, 1, 2, 0);

		
	//	CreateWeapon(client, "tf_weapon_syringegun_medic", 36, 6, 1, 2, 0);

		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		float paint = 0.0;
		
		if (iTeam == TFTeam_Red){
			paint = 8400928.0;
			
		}
		if (iTeam == TFTeam_Blue){
			paint = 2452877.0;
			
		}

		CreateRoboHat(client, Bytedbeak, 10, 6, paint, 1.0, -1.0); 
		CreateRoboHat(client, Grimhatte, 10, 6, paint, 1.0, -1.0); 
		CreateRoboHat(client, Foppish, 10, 6, paint, 1.0, -1.0); 

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

		g_Recharge[client] = GetEngineTime();
		
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			 //TF2Attrib_SetByName(Weapon2, "uber duration bonus", -0.9);
			//TF2Attrib_SetByName(Weapon2, "ubercharge rate penalty", 0.5);
			TF2Attrib_SetByName(Weapon2, "heal rate bonus", 2.0);
			TF2Attrib_SetByName(Weapon2, "overheal penalty", 0.01);
			TF2CustAttr_SetString(Weapon2,"medigun charge is group overheal", "range=600.0 heal_rate=75.0 overheal_ratio=1.05 overheal_duration_mult=0.25");
			TF2CustAttr_SetString(client, "Spell-Caster", "Spell=0 Cooldown=25.0 SpellOnCond=9 Cond=11");
			// 
			
			//  TF2Attrib_SetByName(Weapon2, "medigun charge is crit boost", 1.0);
			
			
			

			
		//	SetEntPropFloat(Weapon2, Prop_Send, "m_flChargeLevel", 1.0);
			
		}
		
		
	}
}

// //Fireball code


// #define PAGE_LENGTH 7

// public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
// {
// 	if (IsRobot(client, ROBOT_NAME))
// 	{

// 		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE) ) 
// 		{
// 			//  PrintToChatAll("Press");
//             g_button_held[client] = true;
// 		}



// 		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE) ) 
// 		{
// 			//  PrintToChatAll("Release");
// 			g_button_held[client] = false;
            
// 		}
// 		//0 = fireball
// 		//PrintToChat(client, "Throwing spell!");
// 		// UpdateCharge(client);
// 		g_skill = GetEngineTime();
// 		DrawHUD(client);
		
// 	}
// 	return Plugin_Continue;
// }

// bool isready;
// public void CastSpell(int client) {

// 	int index;
// 	if (IsKritzed(client))
// 	{
// 		//PrintToChatAll("Was kritzed");
// 		index = 9;
// 	}else
// 	{
// 		//PrintToChatAll("Was not kritzed");
// 		index = 0;
// 	}
	

// 	// float time = GetGameTime();
// 	// bool rare = (index >= PAGE_LENGTH);
// 	// float delay = 0.5;
// 	// if (rare) {
// 	// 	float actual = fTimeFiredRare[client] - time + fSpellDelay + fSpellDelayRare;
// 	// 	if (actual > 0)delay = actual;
// 	// }
// 	//if (delay > 0)ReplyToCommand(client, "[SM] Please wait %.2f seconds before casting the next spell.", delay);
// 	if (!IsPlayerAlive(client))ReplyToCommand(client, "[SM] You must be alive to use this command!");
// 	else {
// 		int ent = FindSpellbook(client);
// 		if (!ent) {
// 			ent = CreateEntityByName("tf_weapon_spellbook");
// 			if (ent != -1) {
// 				SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", 1132);
// 				SetEntProp(ent, Prop_Send, "m_bInitialized", 1);
// 				SetEntProp(ent, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
// 				DispatchSpawn(ent);
// 			}
// 			else {
// 				ReplyToCommand(client, "[SM] Could not create spellbook entity!");
// 				return;
// 			}
// 		}
		
// 		int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
// 		if (active != ent) {
// 			SetEntProp(ent, Prop_Send, "m_iSpellCharges", 1);
// 			SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", index);
			
// 			SetEntPropEnt(client, Prop_Send, "m_hLastWeapon", active);
// 			EquipPlayerWeapon(client, ent);
// 			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", ent);
			
			
// 			// if (rare)fTimeFiredRare[client] = time;
// 			// fTimeFired[client] = time;
// 		}
// 	}
// 	g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
// 	isready = false;
// }

// public int FindSpellbook(int client) {
// 	int i = -1;
// 	while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1) {
// 		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWeapon"))return i;
// 	}
// 	return 0;
// }

// // float g_hud_draw_delay = 0.1;
// // float g_hud_post_time = 0.0;

// void DrawHUD(int client)
// {
// 	char sHUDText[128];
// 	// char sProgress[32];
// 	//int iPercents = RoundToCeil(float(g_Recharge[client]) / float(g_RechargeCooldown) * 100.0);
// 	int iCountDown = RoundToCeil(g_Recharge[client] - g_skill);

// 	// for (int j = 1; j <= 10; j++)
// 	// {
// 	// 	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
// 	// 	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
// 	// }

// 	if (IsKritzed(client))
// 	{
// 	Format(sHUDText, sizeof(sHUDText), "Meteor: %i   ", iCountDown);
// 	}else
// 	{
// 	Format(sHUDText, sizeof(sHUDText), "Fireball: %i   ", iCountDown);
// 	}

// 	if(iCountDown <= 0)
// 	{
// 	if (IsKritzed(client))
// 	{
// 	Format(sHUDText, sizeof(sHUDText), "Meteor Ready!");	
// 	}else
// 	{
// 	Format(sHUDText, sizeof(sHUDText), "Fireball Ready!");

// 	}
// 	SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);


// 	} else {
// 	SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);

// 	// PrintToChatAll("Not Ready!");
// 	}
// 	// if (g_hud_post_time + g_hud_draw_delay <= GetEngineTime() || g_hud_post_time == 0.0)
// 	// {
// 	ShowHudText(client, -2, sHUDText);
// 	// 	 g_hud_post_time = GetEngineTime();
// 	// }

// 	if (!isready && iCountDown <= 0)
// 	{
// 	TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
// 	// PrintToChatAll("Ready!");
// 	isready = true;	
// 	}

// 	if (g_button_held[client] && iCountDown <= 0)
// 	{
// 	RequestFrame(CastSpell, client);


// 	}
// }

// public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
// {

// 	if(!IsValidClient(victim))
// 	return Plugin_Continue;    

// 	if (IsRobot(attacker, ROBOT_NAME))
// 	{
// 	if (!IsAnyRobot(victim) && damagecustom == TF_CUSTOM_SPELL_FIREBALL)
// 	{
// 	g_Recharge[attacker] -= 1.0;
// 	}

// 	}

// 	return Plugin_Continue;
// }

// public bool IsKritzed(int client){
// 	if (TF2_IsPlayerInCondition(client, (TFCond_Kritzkrieged)) || TF2_IsPlayerInCondition(client, (TFCond_Buffed)) || TF2_IsPlayerInCondition(client, (TFCond_CritCanteen)))
// 	{
// 		return true;
// 	}else
// 	{
// 		return false;
// 	}
// }
// void UpdateCharge(int client)
// {
// 	// if we are already at max charge, no need to check anything
// 	if(g_Recharge[client] >= g_RechargeCooldown)
// 	{
// 		g_Recharge[client] = g_RechargeCooldown;
// 		return;
// 	}
	
// 	if(IsRobot(client, ROBOT_NAME))//only add charge if you are sentro
// 	{ 
// 		g_Recharge[client] += 2;
// 	}
// 	//m_iLastHealingAmount[client] = iActualHealingAmount;
	
// 	// if we reached the cap after healing, play the voicelines and such
// 	if(g_Recharge[client] >=g_RechargeCooldown)
// 	{
// 		g_Recharge[client] = g_RechargeCooldown;
// 		EmitSoundToClient(client, SOUND_HEAL_READY);
// 		//EmitSoundToAll(SOUND_HEAL_READY_VO, client);
// 	}
// 	//UpdatePoseParameter(client, GetWeaponWithAttribute(client));
// }