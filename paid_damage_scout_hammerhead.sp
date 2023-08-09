#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Hammerhead"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Scout"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Long Range Shortstop"
#define ROBOT_DETAILS "Your shortstop has long range"
#define ROBOT_COST 1.5
#define ROBOT_COIN_GENERATION 2
#define ROBOT_ON_DEATH "Vaccinator and Battalions Backup counters this robot"
#define GSCOUT		"models/bots/scout_boss/bot_scout_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_scout/giant_scout_loop.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant <Someone> Scout",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Scout",
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

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeGiantscout, PLUGIN_VERSION, restrictions, ROBOT_COIN_GENERATION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantscout", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
	



	

	PrecacheSound("mvm/giant_scout/giant_scout_step_01.wav");
	PrecacheSound("mvm/giant_scout/giant_scout_step_03.wav");
	PrecacheSound("mvm/giant_scout/giant_scout_step_02.wav");
	PrecacheSound("mvm/giant_scout/giant_scout_step_04.wav");
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);
	
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

MakeGiantscout(client)
{
	SMLogTag(SML_VERBOSE, "Createing ScoutName");
	TF2_SetPlayerClass(client, TFClass_Scout);
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
	SetModel(client, GSCOUT);
	
	int iHealth = 2000;
		
	int MaxHealth = 125;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	//TF2Attrib_SetByName(client, "damage force increase", 10.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.5);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_DETAILS);
	
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
		GiveGiantPyro(client);
}

#define FortunateSon 30636
#define ImpImprint 31302
#define ForestFootWear 30890

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_handgun_scout_primary", 220, 6, 1, 2, 217);
		// CreateRoboWeapon(client, "tf_weapon_bat_wood", 44, 6, 1, 2, 0);
		
		CreateRoboHat(client, FortunateSon, 10, 6, 7511618.0, 1.0, -1.0); 
		CreateRoboHat(client, ImpImprint, 10, 6, 7511618.0, 1.0, -1.0); 
		CreateRoboHat(client, ForestFootWear, 10, 6, 7511618.0, 1.0, -1.0); 

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "reload time increased hidden", 0.75);
			TF2Attrib_SetByName(Weapon2, "weapon spread bonus", 0.6);

			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "bullets per shot bonus", 2.0);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs buildings", 0.5);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 0.8);

			
		}

		
	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantscout(GetNativeCell(1));


stock void TF2_SetWeaponAmmo(int weapon, int amount) {
	int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
	
	if (client > 0 && client <= MaxClients && ammoType != -1) {
		SetEntProp(client, Prop_Send, "m_iAmmo", amount, 4, ammoType);
	}
}
