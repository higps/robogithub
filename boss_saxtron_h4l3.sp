#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
#include <tf2_isPlayerInSpawn>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Saxtron"
#define ROBOT_ROLE "ZBOSS"
#define ROBOT_CLASS "Soldier"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Saxtron Hale: Gain +250 HP per human player"
#define ROBOT_TIPS "Crouch and look up to super jump\nCrouch and look down while jumping to weight drop"
#define ROBOT_ON_DEATH "Saxtron has great horizontal & vertical movement\nBeware of his AOE scare rage\nUse knockback to your advantage"

#define GSOLDIER		"models/bots/saxtron/bot_saxtron_v2.mdl"
#define SPAWN   "mvm/ambient_mp3/mvm_siren.mp3"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

// #define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
// #define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
// #define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"

/// Saxton Hale voicelines
#define HaleComicArmsFallSound	"saxtron_h413/saxtron_h413_responce_2.wav"
#define HaleLastB		"vo/announcer_am_lastmanalive"
#define HaleKSpree		"saxtron_h413/saxtron_h413_responce_3.wav"
#define HaleKSpree2		"saxtron_h413/saxtron_h413_responce_4.wav"		/// this line is broken and unused
#define HaleRoundStart		"saxtron_h413/saxtron_h413_responce_start"	/// 1-5
#define HaleJump		"saxtron_h413/saxtron_h413_responce_jump"			/// 1-2
#define HaleRageSound		"saxtron_h413/saxtron_h413_responce_rage"		/// 1-4
#define HaleKillMedic		"saxtron_h413/saxtron_h413_responce_kill_medic.wav"
#define HaleKillSniper1		"saxtron_h413/saxtron_h413_responce_kill_sniper1.wav"
#define HaleKillSniper2		"saxtron_h413/saxtron_h413_responce_kill_sniper2.wav"
#define HaleKillSpy1		"saxtron_h413/saxtron_h413_responce_kill_spy1.wav"
#define HaleKillSpy2		"saxtron_h413/saxtron_h413_responce_kill_spy2.wav"
#define HaleKillEngie1		"saxtron_h413/saxtron_h413_responce_kill_eggineer1.wav"
#define HaleKillEngie2		"saxtron_h413/saxtron_h413_responce_kill_eggineer2.wav"
#define HaleKSpreeNew		"saxtron_h413/saxtron_h413_responce_spree"  /// 1-5
#define HaleWin			"saxtron_h413/saxtron_h413_responce_win"		  /// 1-2
#define HaleLastMan		"saxtron_h413/saxtron_h413_responce_lastman"  /// 1-5
#define HaleFail		"saxtron_h413/saxtron_h413_responce_fail"			/// 1-3
#define HaleJump132		"saxtron_h413/saxtron_h413_132_jump_" //1-2
#define HaleStart132		"saxtron_h413/saxtron_h413_132_start_"   /// 1-5
#define HaleKillDemo132		"saxtron_h413/saxtron_h413_132_kill_demo.wav"
#define HaleKillEngie132	"saxtron_h413/saxtron_h413_132_kill_engie_" /// 1-2
#define HaleKillHeavy132	"saxtron_h413/saxtron_h413_132_kill_heavy.wav"
#define HaleKillScout132	"saxtron_h413/saxtron_h413_132_kill_scout.wav"
#define HaleKillSpy132		"saxtron_h413/saxtron_h413_132_kill_spie.wav"
#define HaleKillPyro132		"saxtron_h413/saxtron_h413_132_kill_w_and_m1.wav"
#define HaleSappinMahSentry132	"saxtron_h413/saxtron_h413_132_kill_toy.wav"
#define HaleKillKSpree132	"saxtron_h413/saxtron_h413_132_kspree_"	/// 1-2
#define HaleKillLast132		"saxtron_h413/saxtron_h413_132_last.wav"
#define HaleStubbed132		"saxtron_h413/saxtron_h413_132_stub_"  /// 1-4


#define HALESPEED		340.0

// #define HALE_JUMPCHARGE		(25*1.0)
// #define HALERAGEDIST		800.0
// #define HALE_WEIGHDOWN_TIME	3.0

bool b_SaxtonSaid[MAXPLAYERS + 1] = {false, ...};
float g_JumpTime = 0.0;
public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Saxtron",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Saxtron",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

public OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

	LoadTranslations("common.phrases");

	//	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	AddNormalSoundHook(SaxtronSoundHook);

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = "Soldier";
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.difficulty = ROBOT_DIFFICULTY_HARD;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.TeamCoins = new RobotCoinRestrictionDefinition();
	restrictions.TeamCoins.Overall = 2;
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = 4.0;

	AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION, restrictions, 2);

	HookEvent("player_death", Event_Death, EventHookMode_Post);
	HookEvent("object_destroyed",           ObjectDestroyed, EventHookMode_Pre);
	HookEvent("teamplay_round_win", Event_teamplay_round_win, EventHookMode_Post);
}

public Action Event_teamplay_round_win(Event event, const char[] name, bool dontBroadcast)
{

	int winteam = GetEventInt(event, "team");

	//  PrintToChatAll("Winning team was %i", winteam);
	CreateTimer(3.0, team_play_win_timer, winteam);


	//EmitGameSoundToAll("Announcer.mvm_spybot_death");
	return Plugin_Continue;
}

public Action team_play_win_timer (Handle timer, int winteam)
{

	// // HaleWin1-2 HaleFail1-3
	// int client;
	char szVO[PLATFORM_MAX_PATH];
	for(int i = 1; i <= MaxClients; i++)
	{	
	if (IsRobot(i,ROBOT_NAME) && IsPlayerAlive(i) && winteam == GetClientTeam(i))
	{

	Format(szVO, sizeof(szVO),"%s%i.wav",HaleWin, GetRandomInt(1,2));
	SaxtronSay(i, szVO);

	}else if (IsRobot(i,ROBOT_NAME) && IsPlayerAlive(i) && winteam != GetClientTeam(i))
	{

	Format(szVO, sizeof(szVO),"%s%i.wav", HaleFail, GetRandomInt(1,3));
	SaxtronSay(i, szVO);
	}

	}


	return Plugin_Continue;
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantSoldier", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheSound(HaleKSpree);

	char s[PLATFORM_MAX_PATH];
	int i;
	for( i=1; i <= 4; i++ ) {
	Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", HaleLastB, i);
	// (s, true);
	}

	PrecacheSound(HaleKillMedic);
	PrecacheSound(HaleKillSniper1);
	PrecacheSound(HaleKillSniper2);
	PrecacheSound(HaleKillSpy1);
	PrecacheSound(HaleKillSpy2);
	PrecacheSound(HaleKillEngie1);
	PrecacheSound(HaleKillEngie2);
	PrecacheSound(HaleKillDemo132);
	PrecacheSound(HaleKillHeavy132);
	PrecacheSound(HaleKillScout132);
	PrecacheSound(HaleKillSpy132);
	PrecacheSound(HaleKillPyro132);
	PrecacheSound(HaleKillDemo132);
	PrecacheSound(HaleKillDemo132);
	PrecacheSound(HaleKillDemo132);
	PrecacheSound(HaleKillDemo132);
	PrecacheSound(HaleKillDemo132);
	PrecacheSound(HaleSappinMahSentry132);
	PrecacheSound(HaleKillLast132);

	for( i=1; i <= 5; i++ ) {
	if( i <= 2 ) {
	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump, i);
	PrecacheSound(s);

	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleWin, i);
	PrecacheSound(s);

	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump132, i);
	PrecacheSound(s);

	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillEngie132, i);
	PrecacheSound(s);

	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, i);
	PrecacheSound(s);
	}
	if( i <= 3 ) {
	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleFail, i);
	PrecacheSound(s);
	}

	if( i <= 4 ) {
	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRageSound, i);
	PrecacheSound(s);

	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStubbed132, i);
	PrecacheSound(s);
	}

	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRoundStart, i);
	PrecacheSound(s);

	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, i);
	PrecacheSound(s);

	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleLastMan, i);
	PrecacheSound(s);

	Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStart132, i);
	PrecacheSound(s);
	}
	
}

/* public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_bIsGSoldier[client])
	{
		g_bIsGSoldier[client] = false;
	}
} */
int g_SuperJumpCharge = 0;
int g_SuperJumpChargeLimit = 125;
float g_rage[MAXPLAYERS + 1] = {0.0, ...};
float g_ragelimit = 2000.0;

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

public Action:SaxtronSoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
	if (StrContains(sample, "1.wav", false) != -1)
	{
	Format(sample, sizeof(sample), LEFTFOOT);
	EmitSoundToAll(sample, entity);
	}
	else if (StrContains(sample, "3.wav", false) != -1)
	{
	Format(sample, sizeof(sample), LEFTFOOT1);
	EmitSoundToAll(sample, entity);
	}
	else if (StrContains(sample, "2.wav", false) != -1)
	{
	Format(sample, sizeof(sample), RIGHTFOOT);
	EmitSoundToAll(sample, entity);
	}
	else if (StrContains(sample, "4.wav", false) != -1)
	{
	Format(sample, sizeof(sample), RIGHTFOOT1);
	EmitSoundToAll(sample, entity);
	}
	return Plugin_Changed;
	}
	// PrintToChatAll("sample %b", strncmp(sample, "vo/soldier", 10, false));

	//For laughing taunt
	if (strncmp(sample, "vo/soldier_LaughLong03.mp3", 26, false) == 0)
	{
	volume = 0.0;
	//SayLaughter(entity);
	SaxtronSay(entity,"saxtron_h413/saxtron_h413_responce_spree1.wav");
	return Plugin_Changed;
	}

	if (strncmp(sample, "vo/soldier_pain", 15, false) == 0)
	{

	//PrintToChatAll("Found pain");
	volume = 0.0;
	//SayLaughter(entity);
	//SaxtronSay(entity,"saxtron_h413/saxtron_h413_responce_spree1.wav");
	return Plugin_Changed;
	}


	if (strncmp(sample, "vo/", 3, false) == 0)
	{

	//PrintToChatAll("Sample was %s", sample);
	// ReplaceString(sample, sizeof(sample), ".wav", ".mp3", false);
	// char classname[10]; 
	// char classname_mvm[15];
	// Format(classname_mvm, sizeof(classname_mvm), "%snull_mvm", classname);
	//ReplaceString(sample, sizeof(sample), "null.wav", "null.wav", false);
	volume = 0.0;
	RequestFrame(SayVoiceLine, entity);
	return Plugin_Changed;
	}
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;

	return Plugin_Continue;
}
void SayVoiceLine(int client)
{

	if (!b_SaxtonSaid[client])
	{

		char szVO[PLATFORM_MAX_PATH];

		int see = GetRandomInt(0,1);
		
		if (see == 1)
		{
  		Format(szVO, sizeof(szVO),"%s%i.wav", HaleStart132, GetRandomInt(1,5));
		}else
		{
		Format(szVO, sizeof(szVO),"%s%i.wav", HaleLastMan, GetRandomInt(1,5));
		}

		see = GetRandomInt(0,3);
		// see = 0;
		if (see == 0)
		{
			Format(szVO, sizeof(szVO),"%s", HaleKillLast132);
			
		}
		SaxtronSay(client, szVO);
		//b_SaxtonSaid[client] = true;

	}

}

MakeGiantSoldier(client)
{
	SMLogTag(SML_VERBOSE, "Createing Heavy");
	TF2_SetPlayerClass(client, TFClass_Soldier);
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
	SetModel(client, GSOLDIER);
	
	int PlayerBonusHP = 0;
	int PlayerPerPlayerHP = 250;
	int PlayerCount = 0;

    for(int i = 0; i <= MAXPLAYERS; i++)
    {
		if(IsValidClient(i) && !IsAnyRobot(i))
		{
			PlayerBonusHP+=PlayerPerPlayerHP;
			PlayerCount++;
		}

    }

	// PrintToChatAll("Playercount was %i", PlayerCount);

	int iHealth = 2046+PlayerBonusHP;
	RoboSetHealth(client,TFClass_Soldier, iHealth, 1.5);
	
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	RoboSetHealth(client, TFClass_Soldier, iHealth);
	float OverHealRate = 1.5;



	float scale = 1.25;
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 1.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	//TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "healing received penalty", 0.0);
	
	TF2Attrib_SetByName(client, "self dmg push force increased", 6.0);
	TF2Attrib_SetByName(client, "boots falling stomp", 6.0);
	TF2Attrib_SetByName(client, "increased air control", 4.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	//TF2Attrib_SetByName(client, "head scale", 0.5);
	UpdatePlayerHitbox(client,scale);
	TF2CustAttr_SetString(client, "fall-damage", "static-damage=1 static-damage-stomp=1 fall-damage=1.0 stomp-damage=125.0");
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);
	//SetBossHealth(client);
	PlaySpawnClip(client);
}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

// #define SergeantsDrillHat 183
// 

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);


		CreateRoboWeapon(client, "tf_weapon_shovel", 5, 6, 1, 2, 0);

		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 2.0);
			// TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.25);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);		
			TF2Attrib_SetByName(Weapon3, "mod weapon blocks healing", 1.0);		
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.5);			
		}
		
	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));
	
//VSH CODE

// public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor,
// 		float &damage, int &damagetype, int &weapon, float damageForce[3],
// 		float damagePosition[3], int damagecustom, CritType &critType)
// {
// 	if(!IsValidClient(victim))
// 	return Plugin_Continue;    

// 	if(!IsValidClient(attacker))
// 	{

// 		if(IsRobot(victim, ROBOT_NAME) && damagetype == DMG_FALL)
// 		{
// 			// PrintToChatAll("Taking regular fall damage %N", victim);
// 			damage *= 0.0;
// 			return Plugin_Changed;
// 		}
// 	}else
// 	{
// 		if(IsRobot(attacker, ROBOT_NAME) && damagetype == DMG_FALL)
// 		{
// 			// PrintToChatAll("Else attacker was %N", attacker);
// 			// PrintToChatAll("Else vicitm was %N", victim);
// 			damage *= 0.25;
// 			return Plugin_Changed;
// 		}
// 	}
// }

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{

	if(!IsValidClient(victim))
	return Plugin_Continue;    

	// if(!IsValidClient(attacker))
	// {

	// 	if(IsRobot(victim, ROBOT_NAME) && damagetype == DMG_FALL)
	// 	{
	// 		PrintToChatAll("Taking regular fall damage %N", victim);
	// 		// damage *= 0.0;
	// 		// return Plugin_Changed;
	// 	}
	// }else
	// {
	// 	if(IsRobot(attacker, ROBOT_NAME) && damagetype == DMG_FALL)
	// 	{
	// 		PrintToChatAll("Else attacker was %N", attacker);
	// 		PrintToChatAll("Else vicitm was %N", victim);
	// 		damage *= 0.25;
	// 		return Plugin_Changed;
	// 	}
	// }








	if(IsValidClient(attacker) && IsRobot(victim, ROBOT_NAME))
	{

		if (IsRobot(victim, ROBOT_NAME))
		{
			if(damagecustom == TF_CUSTOM_BACKSTAB)
			{
			char stab_snd[PLATFORM_MAX_PATH];
			Format(stab_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleStubbed132, GetRandomInt(1, 4));
			SaxtronSay(victim, stab_snd);
			}
	}

	//PrintToChatAll("Damage was %f, g_rage before %f, g_rage limit was", damage, g_rage, g_ragelimit);

	SaxtronRageIncrease(victim, damage);
	// if(g_rage[victim] < g_ragelimit)
	// {
	// 	// PrintToChatAll("Damage was %f, g_rage before %f", damage, g_rage[victim]);
	// 	g_rage[victim] += damage;
	// 	// PrintToChatAll("g_rage after %f", g_rage[victim]);
	// }

	//	DrawRageHUD(victim);
	}

	if(IsValidClient(victim) && IsRobot(attacker, ROBOT_NAME))
	{
	//PrintToChatAll("Damage was %f, g_rage before %f, g_rage limit was", damage, g_rage, g_ragelimit);

	// if(g_rage[attacker] < g_ragelimit)
	// {
	// 	// PrintToChatAll("Damage was %f, g_rage before %f", damage, g_rage[attacker]);
	SaxtronRageIncrease(attacker, damage);
	// 	g_rage[attacker] += damage;
	// 	if(damage > 250.0)
	// 	{
	// 		g_rage[attacker] -= damage;
	// 		g_rage[attacker] += 250.0;
	// 	}
		
	// 	// PrintToChatAll("g_rage after %f", g_rage[attacker]);
	// }

	//	DrawRageHUD(attacker);
	}

	return Plugin_Continue;
}

void SaxtronRageIncrease(int client, float damage)
{

	if(g_rage[client] <= g_ragelimit)
	{
	if(damage > 250.0)
	{
	g_rage[client] -= damage;
	g_rage[client] += 250.0;
	}
	// else
	// {
	g_rage[client] += damage;
	// }
	}
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	//EmitSoundToAll(HaleKillDemo132, attacker);

	if (IsRobot(attacker, ROBOT_NAME) && IsValidClient(victim)){
	KilledPlayer(attacker, victim);

	}

	if (IsRobot(victim, ROBOT_NAME)){
	//	PrintToChatAll("DEAD AS SAXTRON");
	char szVO[PLATFORM_MAX_PATH];
	Format(szVO, sizeof(szVO),"%s%i.wav", HaleFail, GetRandomInt(1,3));
	SaxtronSay(victim, szVO);

	}
	// if (IsRobot(victim, ROBOT_NAME)){
	// 	PrintToChatAll("HALE DIED!");
	// 	EmitSoundToAll("saxtron_h413/saxtron_h413_responce_fail2.wav");
	// 	EmitSoundToAll("saxtron_h413/saxtron_h413_responce_fail2.wav");
	// }
	return Plugin_Continue;
}

public void KilledPlayer(int attacker, int victim)
{
	//event.SetString("weapon", "fists");
	// if( !GetRandomInt(0, 2) ) {
	char kill_snd[PLATFORM_MAX_PATH];
	// TFClassType playerclass = TF2_GetPlayerClass(victim);
	switch(TF2_GetPlayerClass(victim)) {
	case TFClass_Scout: strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillScout132);
	case TFClass_Pyro: strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillPyro132);
	case TFClass_DemoMan: strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillDemo132);
	case TFClass_Heavy: strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillHeavy132);
	case TFClass_Medic: strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillMedic);
	case TFClass_Sniper: strcopy(kill_snd, PLATFORM_MAX_PATH, GetRandomInt(0, 1) ? HaleKillSniper1 : HaleKillSniper2);

	case TFClass_Spy: {
		int see = GetRandomInt(0, 2);
		if( see )
			strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillSpy1);
		else if( see == 1 )
			strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillSpy2);
		else strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillSpy132);
	}
	case TFClass_Engineer: {
		int see = GetRandomInt(0, 3);
		if( !see )
			strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillEngie1);
		else if( see == 1 )
			strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillEngie2);
		else Format(kill_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillEngie132, GetRandomInt(1, 2));
	}
	case TFClass_Soldier:
	{
	int see = GetRandomInt(0, 1);
	if (see == 0){
	strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKSpreeNew);
	Format(kill_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, GetRandomInt(1, 5));
	}else if (see == 1)
	{
	strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillKSpree132);
	Format(kill_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, GetRandomInt(1, 2));
	}
	}
	}

	if( kill_snd[0] != '\0' ){

	int see;
	if (TF2_GetPlayerClass(victim) == TFClass_Soldier)
	{
	see = GetRandomInt(0,1);
	}else
	{
	see = GetRandomInt(0, 5);
	}
	if (see == 0){
	strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKSpreeNew);
	Format(kill_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, GetRandomInt(1, 5));
	}else if (see == 1)
	{
	strcopy(kill_snd, PLATFORM_MAX_PATH, HaleKillKSpree132);
	Format(kill_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, GetRandomInt(1, 2));
	}
	SaxtronSay(attacker, kill_snd);
	}
	// SaxtronSay(attacker, kill_snd);
	// SaxtronSay(attacker, kill_snd);
	// SaxtronSay(attacker, kill_snd);
	// SaxtronSay(attacker, kill_snd);
	// EmitSoundToAll(kill_snd, attacker);
	// EmitSoundToAll(kill_snd, attacker);
	// }
	// int iKills = 0;
	// float curtime = GetGameTime();
	// if( curtime <= flKillSpree )
	// 	iKills++;
	// else iKills = 0;

	// if( this.iKills == 3 && GetLivingPlayers(VSH2Team_Red) != 1 ) {
	// 	char spree_snd[PLATFORM_MAX_PATH];
	// 	int randsound = GetRandomInt(0, 7);
	// 	if( !randsound || randsound == 1 )
	// 		strcopy(spree_snd, PLATFORM_MAX_PATH, HaleKSpree);
	// 	else if( randsound < 5 && randsound > 1 )
	// 		Format(spree_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, GetRandomInt(1, 5));
	// 	else Format(spree_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, GetRandomInt(1, 2));

	// 	EmitSoundToAll(spree_snd, attacker);
	// 	EmitSoundToAll(spree_snd, attacker);
	// 	iKills = 0;
	// }
	// else flKillSpree = curtime+5;
	}
	
// public void Stabbed(int victim) {

// 	EmitSoundToAll(stab_snd, victim);
// 	EmitSoundToAll(stab_snd, victim);
// 	EmitSoundToAll(stab_snd, victim);
	
// }

public void PlaySpawnClip(int client) {
	char start_snd[PLATFORM_MAX_PATH];
	// if( !GetRandomInt(0, 1) )
	Format(start_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleRoundStart, GetRandomInt(1, 5));
	// else 
	//Format(start_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleStart132, GetRandomInt(1, 5));
	SaxtronSay(client , start_snd);	
}

public Action ObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{

	
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsRobot(attacker, ROBOT_NAME))
	{
		SaxtronSay(attacker, HaleSappinMahSentry132);

	}
	return Plugin_Continue;
}

bool g_JumpCoolDown = false;
int g_AirTime = 0;
bool g_CanWeighDown = false;

//////////SAXTON HALE CODE FROM CHDATA

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsRobot(client, ROBOT_NAME) && (client))
	{
	int IsJumping = GetEntProp(client, Prop_Send, "m_bJumping");


	if (IsJumping == 1)
	{
	g_AirTime++;

	}else
	{
	g_AirTime = 0;
	}


	if(g_AirTime >= 85)
	{
	g_CanWeighDown = true;
	}else
	{
	g_CanWeighDown = false;
	}



	float currenttime = GetEngineTime();
	//PrintToChatAll("%f", currenttime);
	if (g_JumpTime <= currenttime && g_JumpCoolDown)
	{
	g_JumpCoolDown = false;
	}




	float ang[3];
	GetClientEyeAngles(client, ang);
	if (!TF2Spawn_IsClientInSpawn(client)){
	DrawHaleHUD(client);
	}

	if (buttons & IN_ATTACK2)
	{



	if (IsJumping == 0)
	{
		if 
		(g_SuperJumpCharge+1 >= g_SuperJumpChargeLimit)
		{
			g_SuperJumpCharge = g_SuperJumpChargeLimit;	
		}
		else
		{
			if(!g_JumpCoolDown) g_SuperJumpCharge++;
		}
	}

	}

	if (buttons & IN_DUCK)
	{
	if(IsJumping == 1)
	{
	// SetEntityGravity(client, 1.0);
	if (g_CanWeighDown && (ang[0] > 60.0))
	{
		WeighDown(client, -2000.0, true);
		return Plugin_Changed;
	}

	}





	}


	if (buttons & IN_RELOAD || buttons & IN_ATTACK3)
	{


			int IsJumping = GetEntProp(client, Prop_Send, "m_bJumping");
			
			//TF2_RemoveCondition(client, condition);
			
			if (!IsJumping && g_rage[client] >= g_ragelimit)
			{
		
			PerformStun(client);
			SaxtronSay(client,"saxtron_h413/saxtron_h413_responce_spree1.wav");
			g_rage[client] = 0.0;
		
			}
		
	}

	// if (buttons & IN_ATTACK2 && !IsJumping && g_rage[client] >= g_ragelimit)
	// {
	// 	PerformStun(client);
	// 	g_rage[client] = 0.0;
	// }(


	if(IsJumping == 0 && ang[0] < -33.0 && !g_JumpCoolDown && (GetEntProp( client, Prop_Data, "m_afButtonReleased" ) & IN_ATTACK2)) 
	{
	// PrintToChatAll("Button released g_Sumperjumpcharge was %i", g_SuperJumpCharge);
	SuperJump(client, float(g_SuperJumpCharge), true);

	}


	if ((GetEntProp( client, Prop_Data, "m_afButtonReleased" ) & IN_ATTACK2) && ang[0] > -40.0)
	{
	g_SuperJumpCharge = 0;
	}
	}

	return Plugin_Continue;
}

public void SuperJump(int client, float power, bool reset) 
{

		g_SuperJumpCharge = 0;
		
		float vel[3]; GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
		vel[2] = 750 + power * 13.0;
		// if( g_bSuperCharge ) {
		// 	vel[2] += 2000.0;
		// 	g_bSuperCharge = false;
		// }
		SetEntProp(client, Prop_Send, "m_bJumping", 1);
		vel[0] *= (1+Sine(power * FLOAT_PI / 50));
		vel[1] *= (1+Sine(power * FLOAT_PI / 50));
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);

		int random = GetRandomInt(0,1);
		char kill_snd[PLATFORM_MAX_PATH];
		if(random == 0){

		
		strcopy(kill_snd, PLATFORM_MAX_PATH, HaleJump132);
		Format(kill_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump132, GetRandomInt(1, 2));
		}else
		{

		strcopy(kill_snd, PLATFORM_MAX_PATH, HaleJump);
		Format(kill_snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump, GetRandomInt(1, 2));		
		}


		SaxtronSay(client,kill_snd);
		
		// CreateTimer(7.0, JumpCoolDown);
		g_JumpTime = GetEngineTime() + 7.0;
		g_JumpCoolDown = true;
		//PrintToChatAll("%f", g_JumpTime);

}

// public Action JumpCoolDown(Handle timer)
// {
// 	g_JumpCoolDown = false;
// }

public void WeighDown(int client, float power, bool reset) 
{
		// SetEntityGravity(client, 1.0);
		float fVelocity[3]; GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		fVelocity[2] = power;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		// SetEntityGravity(client, 6.0);		
}
//////////////////// END SAXTON HALE CODE CHDATA

public void PerformStun(int client)
{
	//Get our hero variables
	float duration = 5.0;
	bool fullStun = false;
	float radius = 400.0;
	int iTeam = GetClientTeam(client);

	ApplyRadialStun(client, GetOpposingTeam(iTeam), duration, radius, fullStun);
	// FakeClientCommandEx(client, "taunt");
	// TF2_AddCondition(client, TFCond_DefenseBuffed, 15.0);
	// TF2_AddCondition(client, TFCond_FreezeInput, 4.0);
	int random = GetRandomInt(1,4);


	//HaleRageSound		"saxtron_h413/saxtron_h413_responce_rage"	
	char szVO[PLATFORM_MAX_PATH];
	Format(szVO, sizeof(szVO),"%s%i.wav",HaleRageSound, random);
	// PrintToChatAll("%s",szVO);
	b_SaxtonSaid[client] = false;
	SaxtronSay(client, szVO);
}

public void ApplyRadialStun(int hero, int team, float flDuration, float flRadius, bool full)
{
	//positions
	float heroPos[3];
	float playerPos[3];
	
	//Get our hero's position
	GetClientAbsOrigin(hero, heroPos);
	int stunflag = TF_STUNFLAGS_SMALLBONK;
	if (full)
		stunflag = TF_STUNFLAGS_BIGBONK;
	
	//loop through players
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			int cteam = GetClientTeam(client);
			if (cteam != team) continue;
			
			GetClientAbsOrigin(client, playerPos);
			if (GetVectorDistance(playerPos, heroPos) <= flRadius)
			{
				if (full)
					TF2_StunPlayer(client, flDuration, 0.0, stunflag);
				else
					TF2_StunPlayer(client, flDuration, 0.0, stunflag);
			}
		}
	}
}

public int GetOpposingTeam(int team)
{
	switch (team)
	{
		case 2: return 3;
		case 3: return 2;
	}
	return -1;
}


public void SaxtronSay(int client, const char[] voiceline)
{
	if (!b_SaxtonSaid[client]){

	// float pos[3];
	// GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);

	// EmitSoundToAll(voiceline, client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
	// EmitSoundToAll(voiceline, client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
	// EmitSoundToAll(voiceline, client, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
  //  EmitSoundToAll(voiceline, client, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
	// EmitSoundToAll(voiceline, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100);
	// EmitSoundToAll(voiceline, client, SNDCHAN_VOICE, SNDLEVEL_GUNFIRE);
	// EmitSoundToAll(voiceline, client, SNDCHAN_VOICE, SNDLEVEL_GUNFIRE);

	EmitSoundToAll(voiceline, client);
	EmitSoundToAll(voiceline, client);
	EmitSoundToAll(voiceline, client);
	b_SaxtonSaid[client] = true;
	CreateTimer(3.5, Timer_SaxtonSaid, client);
	}
}

public Action Timer_SaxtonSaid(Handle timer, int client)
{
	b_SaxtonSaid[client] = false;
	return Plugin_Continue;
}

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"
// bool b_hud_clamp[MAXPLAYERS + 1] = false;



void DrawHaleHUD(int client)
{
	DrawRageHUD(client);
	DrawJumpHUD(client);
}

void DrawJumpHUD(int client)

{
	char sHUDText[128];
	char sProgress[32];
	int iPercents = RoundToCeil(float(g_SuperJumpCharge) / float(g_SuperJumpChargeLimit)* 100.0);

	for (int j = 1; j <= 10; j++)
	{
	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}

	// int team = GetClientTeam(client);

	// float angles[3], pos[3];
	if (g_JumpCoolDown){

	Format(sHUDText, sizeof(sHUDText), "Jump %i(cooldown) : %d%%%%   \n%s   ", RoundToNearest((g_JumpTime+1.0) - GetEngineTime()), iPercents, sProgress);
	SetHudTextParams(0.85, -0.4, 0.1, 255, 0, 0, 255);
	}else
	{

	Format(sHUDText, sizeof(sHUDText), "Jump: %d%%%%   \n%s   ", iPercents, sProgress);

	if(iPercents >= 100)
	{


	SetHudTextParams(0.85, -0.4, 0.1, 0, 255, 0, 255);
	}else {

	SetHudTextParams(0.85, -0.4, 0.1, 255, 255, 255, 255);
	}
	}
	//SetHudTextParams(0.85, -0.4, 0.1, 255, 255, 255, 255);

	ShowHudText(client, -2, sHUDText);
	// b_hud_clamp[client] = false;
}

void DrawRageHUD(int client)
{
	char sHUDText[128];
	char sProgress[32];
	int iPercents = RoundToCeil(g_rage[client] / g_ragelimit * 100.0);

	for (int j = 1; j <= 10; j++)
	{
		if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
		else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}

	// int team = GetClientTeam(client);

	// float angles[3], pos[3];
	Format(sHUDText, sizeof(sHUDText), "Rage: %d%%%%   \n%s   ", iPercents, sProgress);

	if(iPercents >= 100)
	{

			Format(sHUDText, sizeof(sHUDText), "Rage Ready!\nReload to activate!");
			SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);
	}else {

		SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 255, 255);
	}
	ShowHudText(client, -3, sHUDText);
	// b_hud_clamp[client] = false;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
	//PrintToChatAll("CONDITION WAS: %i for %N", condition, client);
   

		if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting )
		{	

			int IsJumping = GetEntProp(client, Prop_Send, "m_bJumping");
			int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
			
			if (tauntid == 463){
			SaxtronSay(client,"saxtron_h413/saxtron_h413_responce_spree1.wav");
			//TF2_RemoveCondition(client, condition);
			}
			if (tauntid == -1 && !IsJumping && g_rage[client] >= g_ragelimit)
			{
		
			PerformStun(client);
			g_rage[client] = 0.0;
		
			}
		}
	
}
