#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Fat Magic"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Sniper"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Bushwacka, Jarate"
#define ROBOT_TIPS "Rapid swing Bushwacka\nBecome briefly ubered when jarate'd\nYou regenerate health over time!"
#define ROBOT_ON_DEATH "Fatmagic becomes briefly Ubered when covered in Jarate\nFatmagic can Uber himself with his own Jarate"

#define ChangeDane             "models/bots/Sniper/bot_Sniper.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Huntsbot",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Huntsbot",
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
	robot.difficulty = ROBOT_DIFFICULTY_EASY;

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

	TF2_RemoveWeaponSlot(client, 0); //Huntsman
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri

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


	RoboSetHealth(client, TFClass_, 2250, 1.5);


	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.65);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 1.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "deploy time decreased", 0.05);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "health regen", 10.0);
	
	
	
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
	GiveBigRoboHuntsbot(client);
}

#define KingTavish 342

stock GiveBigRoboHuntsbot(client)
{
	if (IsValidClient(client))
	{

	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Huntsman
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri


	CreateRoboWeapon(client, "tf_weapon_jar", 58, 6, 1, 1, 0);
	CreateRoboWeapon(client, "tf_weapon_club", 232, 6, 1, 2, 0); //shahansah

	CreateRoboHat(client, KingTavish, 10, 6, 0.0, 1.25, 1.0); 
	CreateRoboHat(client, 31037, 10, 6, 0.0, 1.25, 1.0); 


	int Kukri = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee); //Shahanshah
	int SMG = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary); //SMG

		if(IsValidEntity(SMG))
		{
		TF2Attrib_RemoveAll(SMG);
		TF2Attrib_SetByName(SMG, "provide on active", 1.0);
		TF2Attrib_SetByName(SMG, "effect bar recharge rate increased", 0.4);
		}


		if(IsValidEntity(Kukri))
		{
			TF2Attrib_RemoveAll(Kukri);
			TF2Attrib_SetByName(Kukri, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Kukri, "fire rate bonus", 0.8);
			TF2Attrib_SetByName(Kukri, "dmg penalty vs buildings", 0.25);
			TF2Attrib_SetByName(Kukri, "dmg taken increased", 1.0);
		}	
	}
}
		
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Jarated)
	{	
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 4.0);
	}	
}