#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Firewall"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Overheating Heavy"
#define ROBOT_COST 3.0
#define ROBOT_TIPS "Overheat % = damage bonus\nDon't let it fully overheat!"
#define ROBOT_ON_DEATH "Firewall deals more damage the longer he has been firing"
 
#define GRageH      "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

float scale = 1.75;

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Rage Heavy",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Rage Heavy from MvM",
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
	robot.difficulty = ROBOT_DIFFICULTY_MEDIUM;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeGRageH, PLUGIN_VERSION, restrictions);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{

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

MakeGRageH(client)
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
	SetModel(client, GRageH);
	RoboSetHealth(client,TFClass_Heavy, 6000, 1.5);
	
	
	
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.2);
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	UpdatePlayerHitbox(client, scale);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

}
 
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGRageH(client);
}

// #define Hat1 30397
#define KapitanKaftan 31053
#define LuchaDor 585
#define Aztec 30914
//War Goggles 30368

stock GiveGRageH(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_minigun", 811, 6, 15, 0, 204);
		
		CreateRoboHat(client, KapitanKaftan, 10, 6, 13595446.0, 1.0, -1.0); 
		CreateRoboHat(client, LuchaDor, 10, 6, 135954460.0, 1.0, -1.0); 

		CreateRoboHat(client, Aztec, 10, 6, 13595446.0, 0.75, -1.0); 

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);
			TF2Attrib_SetByName(Weapon1, "ring of fire while aiming", 45.0);
			TF2Attrib_SetByName(Weapon1, "damage bonus vs burning", 0.5);
			TF2Attrib_SetByName(Weapon1, "crit vs burning players", 1.0);
			TF2Attrib_SetByName(Weapon1, "minigun spinup time increased", 1.8);


			TF2CustAttr_SetString(Weapon1, "weapon overheat", "heat_rate=0.0035 heat_rate_alt=0.0015 cooldown=3.0 decay_time=0.1 decay_rate=0.2 overheat_dmg_scale=3.0");
			TF2CustAttr_SetString(Weapon1, "weapon overheat sound", "weapons/bumper_car_decelerate.wav");

		}
		
		PrintHintText(client, ROBOT_TIPS);
	}
}