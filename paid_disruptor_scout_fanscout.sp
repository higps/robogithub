#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Fan Scout"
#define ROBOT_ROLE "Disruptor"
#define ROBOT_CLASS "Scout"
#define ROBOT_SUBCLASS "Disruptor"
#define ROBOT_DESCRIPTION "High Pushback"
#define ROBOT_COST 1.0
#define ROBOT_COIN_GENERATION 1
#define ROBOT_ON_DEATH "Focus fire this robot before he causes too much disruption"
#define GSCOUT		"models/bots/scout_boss/bot_scout_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_scout/giant_scout_loop.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant <Someone> Scout",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Scout",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

public OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

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

	AddRobot(robot, MakeGiantscout, PLUGIN_VERSION, restrictions, ROBOT_COIN_GENERATION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantscout", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
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

MakeGiantscout(client)
{
	SMLogTag(SML_VERBOSE, "Createing ScoutName");
	TF2_SetPlayerClass(client, TFClass_Scout);
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
	SetModel(client, GSCOUT);
	
	RoboSetHealth(client, TFClass_, 2150, 1.5);	
	
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 1.3);
	TF2Attrib_SetByName(client, "damage force reduction", 2.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 2.0);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 1.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	
	TF2Attrib_SetByName(client, "increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , "Force'A'Nature: Extreme knockback");
	
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
		GiveGiantPyro(client);
}
#define TheFedFightinFedora 780
#define TheBoltBoy 30027
stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_scattergun", 45, 6, 1, 2, 0);
		
		CreateRoboHat(client, TheFedFightinFedora, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, TheBoltBoy, 10, 6, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "bullets per shot bonus", 2.0);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.5);
			TF2Attrib_SetByName(Weapon1, "reload time increased", 0.5);
			TF2Attrib_SetByName(Weapon1, "scattergun knockback mult", 6.0);
			TF2Attrib_SetByName(Weapon1, "damage penalty", 0.5);
			TF2Attrib_SetByName(Weapon1, "weapon spread bonus", 0.3);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);	
		}
	}
}
 


public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantscout(GetNativeCell(1));

