#pragma semicolon 1
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
#include <sdkhooks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Buster"
#define ROBOT_CLASS "Sentry"
#define ROBOT_ROLE "Sentry Buster"
#define ROBOT_SUBCLASS "Sentry Buster"
#define ROBOT_DESCRIPTION "Touch sentries to blow up"
#define ROBOT_TIPS "Hit enemies, touch sentries, or taunt to activate the explosion"
#define ROBOT_COST 1.0
#define ROBOT_ON_DEATH "You can hide behind buildings to not get blown up by the explotion\nThe explosion is faster than regular mvm\nTouching the buster with a sentry will cause it to blow up"
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
	robot.deathtip = ROBOT_ON_DEATH;
	robot.difficulty = ROBOT_DIFFICULTY_EASY;
	//Must create include for this
	// robot.issentrybuster = true;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;

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




	PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_01.wav");
	PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_02.wav");
	PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_03.wav");
	PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_04.wav");
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_spin.wav");

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
	RoboSetHealth(client,TFClass_DemoMan, 2500, 1.5);

	TF2CustAttr_SetString(client, "faster-respawn", "respawn=4.0");

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "damage force reduction", 0.0);
	TF2Attrib_SetByName(client, "move speed penalty", 2.0);
	// TF2Attrib_SetByName(client, "airblast vulnerability multiplier", -5.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);

	TF2Attrib_SetByName(client, "override footstep sound set", 7.0);
	TF2Attrib_SetByName(client, "increased jump height", 2.0);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.5);
	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);

	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);



	PrintHintText(client , ROBOT_TIPS);

	EmitGameSoundToAll("Announcer.MVM_Sentry_Buster_Alert");

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
			TF2Attrib_SetByName(Weapon1, "gesture speed increase", 1.25);
			TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=1.25 frequency=1.5 range=400.0");
			SetEntProp(Weapon1, Prop_Send, "m_iDetonated", 1);
			
			
			SetEntPropFloat(Weapon1, Prop_Send, "m_flModelScale", 0.01);
		}
		TF2CustAttr_SetString(client, "Sentry Buster", "damage=2500.0 radius=250.0 lineofsight=1 timer=1.25");
		
		
	}
}