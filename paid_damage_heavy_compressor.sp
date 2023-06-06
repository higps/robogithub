#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Compressor"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Resistance Piercing + Penetrating Bullets"
#define ROBOT_COST 0.75
#define ROBOT_TIPS "Bullets pierce resistances and Penetrate through targets\nTaunt to minicrit"
#define ROBOT_ON_DEATH "Compressor's shotgun pierces damage resistances\nThis includes Battalion's Backup and cloak resistances"
 
#define GRageH      "models/bots/heavy/bot_heavy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

// #define SOUND_GUNFIRE	")mvm/giant_heavy/giant_heavy_gunfire.wav"
// #define SOUND_GUNSPIN	")mvm/giant_heavy/giant_heavy_gunspin.wav"
// #define SOUND_WINDUP	")mvm/giant_heavy/giant_heavy_gunwindup.wav"
// #define SOUND_WINDDOWN	")mvm/giant_heavy/giant_heavy_gunwinddown.wav"

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

// new bool:Locked1[MAXPLAYERS+1];
// new bool:Locked2[MAXPLAYERS+1];
// new bool:Locked3[MAXPLAYERS+1];
// new bool:CanWindDown[MAXPLAYERS+1];
 
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
//	CreateNative("BeGRageH_MakeGRageH", Native_SetGRageH);
//	CreateNative("BeGRageH_IsGRageH", Native_IsGRageH);
	return APLRes_Success;
}
 
public OnMapStart()
{
	



	
	PrecacheSound("mvm/giant_heavy/giant_heavy_step01.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step03.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step02.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step04.wav");

	// PrecacheSound(SOUND_GUNFIRE);
	// PrecacheSound(SOUND_GUNSPIN);
	// PrecacheSound(SOUND_WINDUP);
	// PrecacheSound(SOUND_WINDDOWN);
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
	int iHealth = 3500;
	
	
	int MaxHealth = 300;
	// PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	 // PrintToChatAll("iHealth %i", iHealth);
	
	 // PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.95);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.2);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.75);

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
		GiveGDeflectorH(client);
}

#define Reliable 31345
// #define HeavyHarness 30910
#define HeavyHeating 31346
// #define Flatliner 30913
//#define Flatliner 31121		
stock GiveGDeflectorH(client)
{
	if (IsValidClient(client))
	{

		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		CreateRoboWeapon(client, "tf_weapon_shotgun_hwg", 199, 6, 2, 2, 402);

		// CreateRoboHat(client, HeavyHarness, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, Reliable, 10, 6, 1315860.0, 0.75, 1.0); 
		CreateRoboHat(client, HeavyHeating, 10, 6, 1315860.0, 0.60, -1.0); 


		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{
			// TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 1.3);
			// TF2Attrib_SetByName(Weapon2, "bullets per shot bonus", 20.0);
			TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapon2, "faster reload rate", 1.25);
			TF2Attrib_SetByName(Weapon2, "dmg pierces resists absorbs", 1.0);
			TF2Attrib_SetByName(Weapon2, "clip size penalty", 2.0);
			
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 2.5);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs buildings", 0.35);
			// TF2Attrib_SetByName(Weapon2, "mult_spread_scales_consecutive", 0.0);
			// TF2Attrib_SetByName(Weapon2, "spread penalty", 2.5);
			// TF2Attrib_SetByName(Weapon2, "fixed_shot_pattern", 0.0);
			
			 
			// TF2CustAttr_SetString(Weapon2, "reload full clip at once", "1.0");
			
		}
		RoboCorrectClipSize(Weapon2);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
        if (tauntid == -1)
        {
        CreateTimer(3.2, Timer_Taunt_Cancel, client);
        }	  

	}
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){

		if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
		{
		TF2_RemoveCondition(client, TFCond_Taunting);
		TF2_AddCondition(client, TFCond_Buffed, 4.0);
		}
	}
}
