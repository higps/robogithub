#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
#include <sdktools>
//#include <collisionhook>
#include <tf_custom_attributes>

#pragma semicolon 1
//#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Zonical"
#define ROBOT_ROLE "Builder"
#define ROBOT_CLASS "Engineer"
#define ROBOT_SUBCLASS ""
#define ROBOT_DESCRIPTION "Quick-draw Pistol, Gunslinger"
#define ROBOT_TIPS "Gain Minicrits by switching to your pistol\nBuild teamporters to easily teleport your team to the front lines"
#define ROBOT_ON_DEATH "Zonical's pistol mini-crits when pulled out\nUse explosive weapons to damage both engineers and their buildings at once"

#define ChangeDane             "models/bots/engineer/bot_engineer.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

// #define ENGIE_SPAWN_SOUND		"vo/announcer_mvm_engbot_arrive02.mp3"
// #define ENGIE_SPAWN_SOUND2		"vo/announcer_mvm_engbot_arrive03.mp3"

// #define TELEPORTER_ACTIVATE1	"vo/announcer_mvm_eng_tele_activated01.mp3"
// #define TELEPORTER_ACTIVATE2	"vo/announcer_mvm_eng_tele_activated02.mp3"
// #define TELEPORTER_ACTIVATE3	"vo/announcer_mvm_eng_tele_activated03.mp3"
// #define TELEPORTER_ACTIVATE4	"vo/announcer_mvm_eng_tele_activated04.mp3"
// #define TELEPORTER_ACTIVATE5	"vo/announcer_mvm_eng_tele_activated05.mp3"

// #define TELEPORTER_SPAWN		"mvm/mvm_tele_deliver.wav"

#define TF_OBJECT_TELEPORTER	1
#define TF_TELEPORTER_ENTR	0

//new g_offsCollisionGroup;

// bool engibotactive;
// bool teleportercheck;
// bool AnnouncerQuiet;



public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Zonical",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Play as the Giant Zonical",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
bool b_Hooked[MAXPLAYERS + 1] = false;
public OnPluginStart()
{
    LoadTranslations("common.phrases");



    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = ROBOT_CLASS;
	// robot.subclass = ROBOT_SUBCLASS;
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;
    AddRobot(robot, MakeUncleDane, PLUGIN_VERSION);
	

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}



public void OnClientPutInServer(int client)
{


	// Hook weapon switching for this client here:
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	b_Hooked[client] = true;
}

public void OnClientDisconnect(int client)
{


	// Unhook our weapon switching:
	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public void OnWeaponSwitch(int client, int weapon)
{
	// When we switch weapons, we're going to grant a damage bonus
	// based off of the "half second damage bonus" attribute.

	// We'll do the damage calculation in another function. Here we'll see
	// when until we can have this bonus.

	// Do we have "half second damage bonus"?
	if (IsRobot(client, ROBOT_NAME))
	{
		
		//PrintToChatAll("Weapon was %i", weapon);
		if (IsPistol(weapon))
		{
			TF2_AddCondition(client, TFCond_Buffed, 1.5);
			TF2Attrib_AddCustomPlayerAttribute(client, "faster reload rate", 0.5, 1.5);
		}
	}
}

bool IsPistol(int weapon){
	if(weapon == -1 && weapon <= MaxClients) return false;
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
	case 22: 
		{
			return true;
		}
	}
	return false;
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{

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

MakeUncleDane(client)
{
	
	TF2_SetPlayerClass(client, TFClass_Engineer);
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

	int iHealth = 1250;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;
	float OverHealRate = 1.5;

	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;
	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	float scale = 1.65;
	
	TF2_SetHealth(client, iHealth);
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.75);
	TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "maxammo metal increased", 2.5);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "metal regen", 200.0);
	// TF2Attrib_SetByName(client, "building cost reduction", 2.5);
	TF2Attrib_SetByName(client, "mod teleporter cost", 9.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	
	TF2CustAttr_SetString(client, "robot engineer", "sentry_scale=1.35 dispenser_scale=1.5 infinite_ammo=0 sentries=1 dispensers=1 remove_all_sappers=0 yeet=0");
	
	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client, ROBOT_TIPS);
	
	
	SetEntProp(client, Prop_Send, "m_iAmmo", 500, _, 3);

	if (!b_Hooked[client]){

		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
		b_Hooked[client] = true;
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

// #define THEDANGER 30420
#define GOLDDIGGER 30172
#define ENDOTHERMIC 30412

stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_pistol", 22, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_robot_arm", 142, 6, 1, 2, 0);

//15126
		//CreateWeapon(client, "tf_weapon_wrench", 7, 9, 69, 2, 0);


		// CreateRoboHat(client, THEDANGER, 10, 6, 15132390.0, 1.25, -1.0);
		CreateRoboHat(client, GOLDDIGGER, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, ENDOTHERMIC, 10, 6, 0.0, 1.0, -1.0);

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		//SetEntData(Weapon3, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);

		if(IsValidEntity(Weapon2))
		{
			//TF2Attrib_RemoveAll(Weapon1);
			//TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.7);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "single wep deploy time decreased", 0.5);
			TF2Attrib_SetByName(Weapon2, "damage bonus", 1.5);			
			// TF2Attrib_SetByName(Weapon2, "clip size penalty", 0.5);
			TF2Attrib_SetByName(Weapon2, "fire rate penalty", 1.5);
			TF2Attrib_SetByName(Weapon2, "weapon spread bonus",	0.25);
			TF2Attrib_SetByName(Weapon2, "engineer building teleporting pickup", 10.0);
			// TF2Attrib_SetByName(Weapon1, "damage bonus bullet vs sentry target", 2.5);
			
		}
		if(IsValidEntity(Weapon3))
		{
			//TF2Attrib_RemoveAll(Weapon3);
			// TF2Attrib_SetByName(Weapon1, "is australium item", 1.0);
			// TF2Attrib_SetByName(Weapon1, "item style override", 1.0);
			//TF2Attrib_SetByName(Weapon3, "fire rate bonus", 1.0);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.25);
			TF2Attrib_SetByName(Weapon3, "Construction rate increased", 10.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.65);
			TF2Attrib_SetByName(Weapon3, "Repair rate increased", 3.0);
			// TF2Attrib_SetByName(Weapon3, "single wep deploy time increased", 1.6);
			TF2Attrib_SetByName(Weapon3, "engineer building teleporting pickup", 10.0);
			// TF2Attrib_SetByName(Weapon3, "engy building health bonus", 2.32);
			TF2Attrib_SetByName(Weapon3, "engy dispenser radius increased", 6.0);
			TF2Attrib_SetByName(Weapon3, "engy building health bonus", 2.32);
			TF2CustAttr_SetString(Weapon3, "mod building health", "teleporter=500");
			TF2Attrib_SetByName(Weapon3, "upgrade rate decrease", 8.0);

			TF2CustAttr_SetString(Weapon3, "owned building phasing", "sentry=1 dispenser=1");
			
		}
		
	}
}
