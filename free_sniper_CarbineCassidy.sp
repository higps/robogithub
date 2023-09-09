#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
// #include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Carbine Cassidy"
#define ROBOT_ROLE "Sniper"
#define ROBOT_CLASS "Sniper"
#define ROBOT_SUBCLASS "Sniper"
#define ROBOT_DESCRIPTION "Headshotting Carbine, Cloak on Crickey"
#define ROBOT_TIPS "Carbine crits on headshot\nUse Crikey cloak to sneak around"
#define ROBOT_ON_DEATH "Carbine Cassidy is weak to any kind of flinching\nCassidy's Crikey grants him cloak"

#define ChangeDane             "models/bots/Sniper/bot_Sniper.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Jbird",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Jbird",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	//HookEvent("player_death", Event_Death, EventHookMode_Post);

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
	robot.difficulty = ROBOT_DIFFICULTY_HARD;
	AddRobot(robot, MakeSniper, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeSniper", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
	return APLRes_Success;
}

public OnMapStart()
{
	// PrecacheModel(ChangeDane);




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

MakeSniper(client)
{

	TF2_SetPlayerClass(client, TFClass_Sniper);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 2)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 2);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, ChangeDane);


	int iHealth = 1500;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;

	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.65);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);

	TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 1.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);

	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	// TF2Attrib_SetByName(client, "major increased jump height", 1.9);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	// TF2Attrib_SetByName(client, "health regen", 10.0);

	UpdatePlayerHitbox(client, 1.65);

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
	GiveBigRoboJbird(client);
}


#define LED 30002
#define Huntingcloak 31314
#define Hunter 30858
stock GiveBigRoboJbird(client)
{
	if (IsValidClient(client))
	{
		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //SniperRifle
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri

	CreateRoboWeapon(client, "tf_weapon_charged_smg", 751, 6, 1, 1, 0);

	CreateRoboHat(client, LED, 10, 6, 0.0, 1.25, 1.0); 
	CreateRoboHat(client, Huntingcloak, 10, 6, 0.0, 1.25, 1.0); 
	CreateRoboHat(client, Hunter, 10, 6, 0.0, 1.25, 1.0); 

	int SMG = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary); //Carbine

	if(IsValidEntity(SMG))
		{
			TF2Attrib_RemoveAll(SMG);
			TF2Attrib_SetByName(SMG, "killstreak tier", 1.0);
			TF2Attrib_SetByName(SMG, "fire rate bonus", 0.65);
			TF2Attrib_SetByName(SMG, "clip size bonus", 0.2);
			TF2Attrib_SetByName(SMG, "lunchbox adds minicrits", 1.0);
			TF2Attrib_SetByName(SMG, "hidden secondary max ammo penalty", 2.0);
			TF2Attrib_SetByName(SMG, "dmg penalty vs buildings", 0.5);
			TF2Attrib_SetByName(SMG, "weapon spread bonus", 0.0);
			TF2Attrib_SetByName(SMG, "headshot damage increase", 2.0);
			TF2Attrib_SetByName(SMG, "minicrits become crits", 1.0);
			TF2Attrib_SetByName(SMG, "crit_dmg_falloff", 0.0);
			TF2Attrib_SetByName(SMG, "dmg penalty vs players", 2.025);
			
			TF2CustAttr_SetString(client, "OnCondAdd-addcond", "oncond=19 duration=8.0 addcond=66");

			RoboCorrectClipSize(SMG);
		}
	}
	
}
// public TF2_OnConditionAdded(client, TFCond:condition)
// {
// 	PrintToChatAll("Cond %i", condition);
// }
