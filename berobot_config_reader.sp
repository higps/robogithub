#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"HiGPS"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "LVL 1 Deflector"
#define ROBOT_TIPS "You have the level 1 deflector upgrade!\nShoot down rockets, grenades, and other projectiles"
#define ROBOT_ON_DEATH "HiGPS has the level 1 deflector perk\nShoot explosives at his feet to make destroying them harder"
 
#define ROBOTMODEL      "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

#define SOUND_GUNFIRE	")mvm/giant_heavy/giant_heavy_gunfire.wav"
#define SOUND_GUNSPIN	")mvm/giant_heavy/giant_heavy_gunspin.wav"
#define SOUND_WINDUP	")mvm/giant_heavy/giant_heavy_gunwindup.wav"
#define SOUND_WINDDOWN	")mvm/giant_heavy/giant_heavy_gunwinddown.wav"

float scale = 1.75;

public Plugin:myinfo =
{
	name = "[TF2] Config Robot Creator",
	author = "HiGPS",
	description = "Creates robots from a config file",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
 
public OnPluginStart()
{
	LoadTranslations("common.phrases");

	while(robots)
	{
		RobotDefinition robot;
		robot.name = ROBOT_NAME;
		robot.role = ROBOT_ROLE;
		robot.class = ROBOT_CLASS;
		robot.subclass = ROBOT_SUBCLASS;
		robot.shortDescription = ROBOT_DESCRIPTION;
		robot.sounds.spawn = SPAWN;
		robot.sounds.loop = LOOP;
		robot.sounds.gunfire = SOUND_GUNFIRE;
		robot.sounds.gunspin = SOUND_GUNSPIN;
		robot.sounds.windup = SOUND_WINDUP;
		robot.sounds.winddown = SOUND_WINDDOWN;
		robot.sounds.death = DEATH;
		robot.deathtip = ROBOT_ON_DEATH;
		robot.weaponsound = ROBOT_WEAPON_SOUND_MINIGUN;
		robot.difficulty = ROBOT_DIFFICULTY_EASY;
		AddRobot(robot, MakeRobot, PLUGIN_VERSION);
	}
}


public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}
 
public OnMapStart()
{

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

MakeRobot(client)
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

	SetModel(client, ROBOTMODEL);

	//Hard coded stuff
	int iHealth = RobotHealth;
	int MaxHealth = ClassHealth;
	int iAdditiveHP = iHealth - MaxHealth;
	float OverHealRate = 1.5;

	TF2_SetHealth(client, iHealth);
	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;

	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);

//Variable stuff

	while(Variables)
	{
		TF2Attrib_SetByName(client, attribute, value);
	}
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.1);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.0);
	
	
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	
	UpdatePlayerHitbox(client, scale);
   
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
		GiveEquipment(client);
}
 
stock GiveEquipment(client)
{
	if (IsValidClient(client))
	{
		//Remove items and hats
		RoboRemoveAllWearables(client);
		//TF2_RemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		//Cosmetic code
		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		float TeamPaint = 0.0;

		if (iTeam == TFTeam_Blue){
			TeamPaint = TeamPaintBlue;
			
		}
		if (iTeam == TFTeam_Red){
			
			TeamPaint = TeamPaintRed;
		}

		while(Hats)
		{
			CreateRoboHat(client, ROTATIONSENSATION, HatLevel, HatQuality, HatPaint, HatScale, HatStyle);//Rotation sensation

		}
		
		while(Weapons)
		{

		
		CreateRoboWeapon(client, "tf_weapon_minigun", 850, 6, 1, 0, 0);


		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon1))
		{
			if(b_removeattrib)TF2Attrib_RemoveAll(Weapon1);

			for(attributes)
			{
				StringAttribute = "Read From Somewhere";
				AttributeValue = ReadFromSomewhere
				TF2Attrib_SetByName(Weapon1, StringAttribute, AttributeValue);
			}			
		}

		}
	}
}
