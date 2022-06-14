#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
//#include <tf2items_giveweapon>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Big Iron"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Spy"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Taunt & Shoot your gun"

#define MODEL             "models/bots/spy/bot_spy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

#define SPY_SPAWN_SOUND1		"vo/mvm_spy_spawn01.mp3"
#define SPY_SPAWN_SOUND2		"vo/mvm_spy_spawn02.mp3"
#define SPY_SPAWN_SOUND3		"vo/mvm_spy_spawn03.mp3"
#define SPY_SPAWN_SOUND4		"vo/mvm_spy_spawn04.mp3"

// #define SPY_DEATH_SOUND1		"vo/mvm_spybot_death01.mp3"
// #define SPY_DEATH_SOUND2		"vo/mvm_spybot_death02.mp3"
// #define SPY_DEATH_SOUND3		"vo/mvm_spybot_death03.mp3"
// #define SPY_DEATH_SOUND4		"vo/mvm_spybot_death04.mp3"
// #define SPY_DEATH_SOUND5		"vo/mvm_spybot_death05.mp3"
// #define SPY_DEATH_SOUND6		"vo/mvm_spybot_death06.mp3"
// #define SPY_DEATH_SOUND7		"vo/mvm_spybot_death07.mp3"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Spy",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Spy",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

//bool g_bisGSPY[MAXPLAYERS + 1];

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

	// RestrictionsDefinition restrictions = new RestrictionsDefinition();
    // restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
    // restrictions.RobotCoins.Overall = 3; 

    AddRobot(robot, MakeSpy, PLUGIN_VERSION, null);

	PrecacheModel(MODEL);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);

	// PrecacheSound(SPY_SPAWN_SOUND1, true);
	// PrecacheSound(SPY_SPAWN_SOUND2, true);
	// PrecacheSound(SPY_SPAWN_SOUND3, true);
	// PrecacheSound(SPY_SPAWN_SOUND4, true);
	// PrecacheSound(SPY_DEATH_SOUND1, true);
	// PrecacheSound(SPY_DEATH_SOUND2, true);
	// PrecacheSound(SPY_DEATH_SOUND3, true);
	// PrecacheSound(SPY_DEATH_SOUND4, true);
	// PrecacheSound(SPY_DEATH_SOUND5, true);
	// PrecacheSound(SPY_DEATH_SOUND6, true);
	// PrecacheSound(SPY_DEATH_SOUND7, true);
	
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeSpy", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
	return APLRes_Success;
}

// public OnMapStart()
// {
// 	PrecacheModel(MODEL);
// 	PrecacheSound(SPAWN);
// 	PrecacheSound(DEATH);
// 	PrecacheSound(LOOP);


// }

// public Event_Death(Event event, const char[] name, bool dontBroadcast)
// {
// 	// int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
// 	// int weaponID = GetEventInt(event, "weapon_def_index");
// 	// int customkill = GetEventInt(event, "customkill");

// 	// if (IsRobot(attacker, ROBOT_NAME) && weaponID == 356 && customkill == 2)
// 	// {
// 	// 	TF2_AddCondition(attacker, TFCond_StealthedUserBuffFade, 5.0);
// 	// }

// }



public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		
		
	}
}

MakeSpy(client)
{
	TF2_SetPlayerClass(client, TFClass_Spy);
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
	SetModel(client, MODEL);


	int iHealth = 1250;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;

	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.65);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	//TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	
	// TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	
	
	
	UpdatePlayerHitbox(client, 1.65);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	

	PrintHintText(client, "Infinite Cloak\nNo Knife\nPowerful Enforcer that penetrates players\nThrowable sapper\nSapper Heals you when sapping");

	if (IsPlayerAlive(client)){
	EmitGameSoundToAll("Announcer.MVM_Spy_Alert");
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
	GiveBigRoboDane(client);
}

// public Action:Timer_Resize(Handle:timer, any:hat)
// {
	// if (IsValidClient(client))
	// GiveBigRoboDane(client);
// }

#define TheHamburg 30123
#define TheRoguesBrogues 30125
#define Bandana 30397



stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{

		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Revolver
	TF2_RemoveWeaponSlot(client, 1); // Sapper
	TF2_RemoveWeaponSlot(client, 2); // Knife
	TF2_RemoveWeaponSlot(client, 3);// Disguise kit
	TF2_RemoveWeaponSlot(client, 4);// inviswatch

	//big kill
	CreateRoboWeapon(client, "tf_weapon_revolver", 161, 6, 1, 0, 0);
	// CreateRoboWeapon(client, "tf_weapon_sapper", 810, 6, 1, 1, 0);
	
	
	 //CreateWeapon(client, "tf_weapon_sapper", 933, 6); //Ap-Sap
	//CreateRoboWeapon(client, "tf_weapon_knife", 356, 6, 1, 2, 0); //kunai
	 CreateRoboWeapon(client, "tf_weapon_invis", 30, 6, 1, 4, 0); 
		

	CreateRoboHat(client, TheHamburg, 10, 6, 15185211.0, 1.1, -1.0); 
	CreateRoboHat(client, TheRoguesBrogues, 10, 6, 15185211.0, 1.0, 1.0);
	CreateRoboHat(client, Bandana, 10, 6, 10843461.0, 1.0, 1.0);
	//CreateRoboHat(client, Spek, 10, 6, 0.0, 1.0, -1.0);
	
		
	int Revolver = GetPlayerWeaponSlot(client, 0); //Revolver
	// int Knife = GetPlayerWeaponSlot(client, 2); //Knife
	int Cloak = GetPlayerWeaponSlot(client, 4); //Invis watch
	// int Sapper = GetPlayerWeaponSlot(client, 1); //Sapper

	if(IsValidEntity(Revolver)) //Revovler
		{
			//TF2Attrib_RemoveAll(Revolver);
			
			TF2Attrib_SetByName(Revolver, "dmg penalty vs players", 1.3);
			TF2Attrib_SetByName(Revolver, "killstreak tier", 1.0);
			// TF2Attrib_SetByName(Revolver, "fire rate penalty", 1.3);
			TF2Attrib_SetByName(Revolver, "Reload time increased", 1.2);
			TF2Attrib_SetByName(Revolver, "crit_dmg_falloff", 1.0);
			
			//TF2Attrib_SetByName(Revolver, "damage bonus while disguised", 1.0);
			// TF2Attrib_SetByName(Revolver, "weapon spread bonus", 0.75);
	
		}

	if(IsValidEntity(Cloak))
		{
			TF2Attrib_SetByName(Cloak, "cloak consume rate increased", 1.5);
			TF2Attrib_SetByName(Cloak, "cloak regen rate increased", 1.2);
			TF2Attrib_SetByName(Cloak, "mult decloak rate", 1.2);
			
		}
	}
}
public void TF2_OnConditionAdded(int client, TFCond condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {
    int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");

	//PrintToChatAll("Taunt ID %i", tauntid);

		if (tauntid == -1)
		{
	//	 TF2_AddCondition(client,TFCond_DefenseBuffed, 20.0);
		TF2_AddCondition(client, TFCond_CritCanteen, 12.0);
		}
	}
}
