#pragma semicolon 1
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
#include <sdkhooks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Buster Mini"
#define ROBOT_CLASS "Sentry"
#define ROBOT_ROLE "Sentry Buster"
#define ROBOT_SUBCLASS "Sentry Buster"
#define ROBOT_DESCRIPTION "Faster detonation, less range and damage"
#define ROBOT_TIPS "Hit enemies, touch sentries, or taunt to activate the explosion"
#define ROBOT_COST 2

#define GBUSTER		"models/bots/demo/bot_sentry_buster.mdl"
#define SPAWN	"#mvm/sentrybuster/mvm_sentrybuster_intro.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/sentrybuster/mvm_sentrybuster_loop.wav"

public Plugin myinfo =
{
	name = "[TF2] Be the Giant Sentry Buster",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Sentry Buster from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}


public void OnPluginStart()
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

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.Overall = ROBOT_COST;

	AddRobot(robot, MakeBuster, PLUGIN_VERSION, restrictions);
	HookEvent("post_inventory_application", Event_post_inventory_application, EventHookMode_Post);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeGiantDemoKnight_MakeBuster", Native_SetGiantDemoKnight);
	//	CreateNative("BeGiantDemoKnight_IsGiantDemoKnight", Native_IsGiantDemoKnight);
	return APLRes_Success;
}

public OnMapStart()
{
	// PrecacheModel(GBUSTER);




	// PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_01.wav");
	// PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_02.wav");
	// PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_03.wav");
	// PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_04.wav");
	// PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_spin.wav");

}

public Action Event_post_inventory_application(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	///Sets color back to normal
	if (IsValidClient(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 0);
	}
	return Plugin_Continue;
}

public Action SetModel(int client, const char[] model)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
	return Plugin_Continue;
}

void MakeBuster(client)
{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll))
		RemoveEntity(ragdoll);

	char weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	RequestFrame(ClientSwitch, client);
	SetModel(client, GBUSTER);
	int iHealth = 500;
	int MaxHealth = 175;
	int iAdditiveHP = iHealth - MaxHealth;
	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "damage force reduction", 0.0);
	TF2Attrib_SetByName(client, "move speed penalty", 1.5);
	// TF2Attrib_SetByName(client, "airblast vulnerability multiplier", -5.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);

	TF2Attrib_SetByName(client, "override footstep sound set", 7.0);
	// TF2Attrib_SetByName(client, "increased jump height", 2.0);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.5);
	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);

	UpdatePlayerHitbox(client, 0.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);


	PrintToChat(client, "1. You are now Giant Sentry Buster!");
	PrintHintText(client , "Touch sentries, taunt or hit enemies with the caber to explode");

	EmitGameSoundToAll("Announcer.MVM_Sentry_Buster_Alert");

			// int ent = -1;
			// while ((ent = FindEntityByClassname2(ent, "obj_sentrygun")) != -1)
			// {
			// 	int owner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
			// 	if (IsValidEntity(ent) && IsValidClient(owner))
			// 	{
			// 	//int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
				
				
			// 	TFTeam iBuildingTeam = TF2_GetClientTeam(owner);
			// 	TFTeam iClientTeam = TF2_GetClientTeam(client);

				
			// 	if(iClientTeam != iBuildingTeam)
			// 	{
			// 			SetEntPropEnt(ent, Prop_Send, "m_bGlowEnabled", 1);
			// 	}
	
			// 	}
			// }
}

stock void TF2_SetHealth(int client, int NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", NewHealth, 1);
}

void ClientSwitch(int client)
{
	if (IsValidClient(client))
		GiveGiantDemoKnight(client);
}

stock void GiveGiantDemoKnight(int client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		CreateRoboWeapon(client, "tf_weapon_stickbomb", 307, 6, 1, 2, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 0.0);
			TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=1.25 frequency=1.5 range=400.0");
			SetEntProp(Weapon1, Prop_Send, "m_iDetonated", 1);
			
			
			SetEntPropFloat(Weapon1, Prop_Send, "m_flModelScale", 0.01);
		}
		TF2CustAttr_SetString(client, "Sentry Buster", "damage=500.0 radius=150.0 lineofsight=1 timer=0.8");
		TF2CustAttr_SetString(client, "faster-respawn", "4.0");
	}
}