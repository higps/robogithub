#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
#include <dhooks>
#include <sdktools>
#include <tf_custom_attributes>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Uncle Dane"
#define ROBOT_ROLE "Builder"
#define ROBOT_CLASS "Engineer"
#define ROBOT_SUBCLASS ""
#define ROBOT_DESCRIPTION "Widowmaker, Wrench"
#define ROBOT_TIPS "Buildings build and upgrade instantly when hit by a wrench\nBuild teamporters to easily teleport your team to the front lines\nPhase through buildings"
#define ROBOT_ON_DEATH "Harass buildings to keep engi bots busy\nDisrupt TeamPorters when possible"

#define ChangeDane             "models/bots/engineer/bot_engineer.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

#define MUSIC "uncle_dane_dispenser.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Uncle Dane",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Uncle Dane Bot from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    //g_offsCollisionGroup = FindSendPropInfo("DT_BaseEntity", "m_CollisionGroup");
    HookEvent("player_builtobject", ObjectBuilt, EventHookMode_Post);
	HookEvent("player_carryobject", ObjectCarry, EventHookMode_Post);
	HookEvent("player_upgradedobject", ObjectBuilt, EventHookMode_Post);

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = ROBOT_CLASS;
	// robot.subclass = ROBOT_SUBCLASS;
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeUncleDane, PLUGIN_VERSION);
	

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
	// PrecacheModel(ChangeDane);




	PrecacheSound(MUSIC);
	

}

//Custom code needed for Dane's theme
float g_disp_build_time = 0.0;
float g_disp_build_cool_down = 60.0;
public void ObjectBuilt(Event event, const char[] name, bool dontBroadcast)
{
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");

	
	if (IsValidClient(iBuilder) && IsRobot(iBuilder, ROBOT_NAME)){


		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser &&
		GetEngineTime() >= g_disp_build_time)
		{

			EmitSoundToAll(MUSIC, iObj);
			EmitSoundToAll(MUSIC, iObj);
			g_disp_build_time = GetEngineTime() + g_disp_build_cool_down;

		}


	}
}




public void ObjectCarry(Event event, const char[] name, bool dontBroadcast)
{
	
	int iBuilder = GetClientOfUserId(event.GetInt("userid"));
	int iObj = event.GetInt("index");
	
	if (IsValidClient(iBuilder) && IsRobot(iBuilder, ROBOT_NAME)){

		if (view_as<TFObjectType>(event.GetInt("object")) != TFObject_Teleporter)SetEntPropFloat(iObj, Prop_Send, "m_flModelScale", 1.0);

		if (view_as<TFObjectType>(event.GetInt("object")) == TFObject_Dispenser)
			{
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			StopSound(iObj, SNDCHAN_AUTO, MUSIC);
			//PrintToChatAll("Attempting music stop");
		}
	}
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
	TF2Attrib_SetByName(client, "metal regen", 200.0);
	// TF2Attrib_SetByName(client, "building cost reduction", 2.5);
	TF2Attrib_SetByName(client, "mod teleporter cost", 9.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client, ROBOT_TIPS);
	
	SetEntProp(client, Prop_Send, "m_iAmmo", 500, _, 3);
	
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


#define THEDANGER 30420
#define GOLDDIGGER 30172
#define INSULATOR 30539

stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_shotgun_primary", 527, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_wrench", 197, 9, 1, 2, 0);


		//CreateWeapon(client, "tf_weapon_wrench", 7, 9, 69, 2, 0);


		CreateRoboHat(client, THEDANGER, 10, 6, 15132390.0, 1.25, -1.0);
		CreateRoboHat(client, GOLDDIGGER, 10, 6, 15132390.0, 1.0, -1.0);
		CreateRoboHat(client, INSULATOR, 10, 6, 15132390.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		//SetEntData(Weapon3, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);

		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			//TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.7);
			TF2Attrib_SetByName(Weapon1, "damage bonus", 1.25);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "mod ammo per shot", 30.0);
			TF2Attrib_SetByName(Weapon1, "engineer building teleporting pickup", 10.0);
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
			TF2Attrib_SetByName(Weapon3, "single wep deploy time increased", 1.6);
			TF2Attrib_SetByName(Weapon3, "engineer building teleporting pickup", 10.0);
			// TF2Attrib_SetByName(Weapon3, "engy building health bonus", 2.32);
			TF2Attrib_SetByName(Weapon3, "engy dispenser radius increased", 6.0);
			TF2Attrib_SetByName(Weapon3, "engy building health bonus", 2.32);
			TF2CustAttr_SetString(Weapon3, "mod building health", "teleporter=500");
			TF2Attrib_SetByName(Weapon3, "upgrade rate decrease", 8.0);
			
			TF2CustAttr_SetString(Weapon3, "owned building phasing", "sentry=1 dispenser=1");
			TF2CustAttr_SetString(Weapon3, "robot engineer", "sentry_scale=1.45 dispenser_scale=1.45 sentry_count=1 dispenser_count=1 remove_all_sappers=0 yeet=0");	
		}
	}
}
