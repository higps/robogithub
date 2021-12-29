#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Demoman"
#define ROBOT_ROLE "Basic"
#define ROBOT_DESCRIPTION "Rapid Grenade Launcher"

#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Toofty",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Demoknight from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Demoman";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeToofty, PLUGIN_VERSION, null, 2);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeGiantDemoKnight_MakeToofty", Native_SetGiantDemoKnight);
	//	CreateNative("BeGiantDemoKnight_IsGiantDemoKnight", Native_IsGiantDemoKnight);
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheModel(GDEKNIGHT);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);

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

MakeToofty(client)
{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GDEKNIGHT);

	int iHealth = 3300;
	
	
	int MaxHealth = 175;
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.3);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	//TF2Attrib_SetByName(client, "increased jump height", 0.3);
	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client, "25 precent faster firing speed\nReloads full cip at once");
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveGiantToofty(client);
}

stock GiveGiantToofty(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		
		CreateRoboWeapon(client, "tf_weapon_grenadelauncher", 19, 8, 1, 0, 213);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon1))
		{
			//TF2Attrib_SetByName(Weapon1, "Projectile speed increased", 1.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.75);
			TF2Attrib_SetByName(Weapon1, "Reload time increased", 0.75);
			TF2Attrib_SetByName(Weapon1, "hidden primary max ammo bonus", 2.0);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
		}

	}
}