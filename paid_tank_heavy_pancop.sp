#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Pancop"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Tank"
#define ROBOT_DESCRIPTION "Rapid Heal on hit."
#define ROBOT_TIPS "You are a Tank!\nYou can't contest objectives\nEat steak to heal and run fast and deal minicrits!"
#define ROBOT_ON_DEATH "Pancop heals each time he hits someone\nTanks can be stunned by shields and stomps\nTanks take double melee damage"
#define ROBOT_COST 2.5

 
#define GDEFLECTORH      "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN	"mvm/mvm_tank_horn.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/mvm_tank_loop.wav"


#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Pancop",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
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
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;


	AddRobot(robot, MakePanCop, PLUGIN_VERSION, restrictions);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGDeflectorH_MakePanCop", Native_SetGDeflectorH);
//	CreateNative("BeGDeflectorH_IsGDeflectorH", Native_IsGDeflectorH);
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

MakePanCop(client)
{	
	TF2_SetPlayerClass(client, TFClass_Heavy);
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
	SetModel(client, GDEFLECTORH);
	RoboSetHealth(client,TFClass_Heavy, 10450, 1.5);
	
	
	// PrintToChatAll("MaxHealth %i", MaxHealth);
	
	
	 // PrintToChatAll("iHealth %i", iHealth);
	
	 // PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.55);
	TF2Attrib_SetByName(client, "damage force reduction", 0.3);



	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "increase buff duration", 10.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	TF2Attrib_SetByName(client, "damage force reduction", 0.0);
	// TF2Attrib_SetByName(client, "increased jump height", 0.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.1);


	UpdatePlayerHitbox(client, 1.75);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	TF2_AddCondition(client, TFCond_CritCola);


	PrintHintText(client, ROBOT_TIPS);
	//Tank stats
    // TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.75);
    TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
	// TF2_AddCondition(client,TFCond_DefenseBuffNoCritBlock);
	

}
 
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGDeflectorH(client);
}

#define Machomann 30085
#define TheLaw 30362 
#define SiberianSophisticate 946 
 
stock GiveGDeflectorH(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);


		CreateRoboWeapon(client, "tf_weapon_club", 264, 6, 2, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_lunchbox", 311, 6, 2, 1, 0);

		CreateRoboHat(client, Machomann, 10, 6, 0.0, 0.75, -1.0); 
		CreateRoboHat(client, TheLaw, 10, 6, 0.0, 0.75, -1.0); 
		CreateRoboHat(client, SiberianSophisticate, 10, 6, 0.0, 1.0, -1.0); 

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.30);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.8);
			TF2Attrib_SetByName(Weapon1, "ragdolls plasma effect", 1.0);
			// TF2Attrib_SetByName(Weapon1, "heal on hit for slowfire", 109.0);
			TF2Attrib_SetByName(Weapon1, "melee range multiplier", 1.35);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.25);	
			TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			TF2CustAttr_SetString(Weapon1, "shake on hit", "amplitude=10.0 frequency=2.0 duration=0.5");

		}
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "lunchbox adds minicrits", 7.0);
			TF2Attrib_SetByName(Weapon2, "lunchbox healing decreased", 40.0);
			


		}

				CreateRoboHat(client, 111, 10, 6, 0.0, 1.0, 1.0); 
		TF2Attrib_SetByName(client, "attach particle effect", 35.0);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
        if (tauntid == -1)
        {
		TF2_AddCondition(client, TFCond_CritCola, 30.0);
		TF2_AddCondition(client, TFCond_RegenBuffed, 30.0);
		TF2_AddCondition(client, TFCond_RestrictToMelee, 30.0);
		CreateTimer(2.5, Timer_Taunt_Cancel, client);
        }	  
	}
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){

		TF2_RemoveCondition(client, TFCond_Taunting);

		int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon); 
	}
}
