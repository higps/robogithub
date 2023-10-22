#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Megaton"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Tank"
#define ROBOT_DESCRIPTION "Knockback Fists of Steel"
#define ROBOT_TIPS "Push enemies by punching them!\nYou have melee vulnerability\nYou can't contest objectives"
#define ROBOT_ON_DEATH "Tanks can be stunned by shields and stomps\nMegaton has severe melee damage vulnerability"
 
#define GDEFLECTORH      "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN	"mvm/mvm_tank_horn.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/mvm_tank_loop.wav"

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Deflector Heavy",
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
	AddRobot(robot, MakeGDeflectorH, PLUGIN_VERSION);


}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGDeflectorH_MakeGDeflectorH", Native_SetGDeflectorH);
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

MakeGDeflectorH(client)
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
	RoboSetHealth(client,TFClass_Heavy, 9000, 1.5);
	
	
	float OverHealRate = 1.5;



	
	float scale = 1.75;
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.1);
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "hand scale", 1.35);
	TF2Attrib_SetByName(client, "head scale", 0.8);

	TF2Attrib_SetByName(client, "damage force reduction", 0.0);


	UpdatePlayerHitbox(client, scale);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);


	PrintHintText(client , ROBOT_TIPS);
	//Tank stats

    TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);

}
 
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGDeflectorH(client);
}

#define EliminatorSafeguard 30369
#define Spooktacles 30801
#define AirborneAttire 30873

stock GiveGDeflectorH(client)
{
	if (IsValidClient(client))
	{
		//Remove items and hats
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);


		CreateRoboHat(client, EliminatorSafeguard, 10, 6, 15132390.0, 1.0, 1.0);
		CreateRoboHat(client, Spooktacles, 10, 6, 8289918.0, 1.0, -1.0);
		CreateRoboHat(client, AirborneAttire, 10, 6, 0.0, 1.0, -1.0);


		CreateRoboWeapon(client, "tf_weapon_fists", 331, 6, 1, 0, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{

			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.6);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.8);
			TF2Attrib_SetByName(Weapon1, "fire rate penalty", 1.3);
			TF2Attrib_SetByName(Weapon1, "reduced_healing_from_medics", 1.0);
			TF2Attrib_SetByName(Weapon1, "damage causes airblast", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg from ranged reduced", 0.9);
			TF2Attrib_SetByName(Weapon1, "dmg from melee increased", 1.1);
			TF2Attrib_SetByName(Weapon1, "melee range multiplier", 1.6);
			TF2Attrib_SetByName(Weapon1, "apply z velocity on damage", 350.0);
			TF2CustAttr_SetString(Weapon1, "knockback modifier", "20.0");
			

			TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			TF2CustAttr_SetString(Weapon1, "shake on hit", "amplitude=10.0 frequency=2.0 duration=0.5");
		}
		CreateRoboHat(client, 111, 10, 6, 0.0, 1.0, 1.0); 
		TF2Attrib_SetByName(client, "attach particle effect", 35.0);
	}
}
