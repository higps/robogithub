#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Backscatter"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Scout"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Rapid Fire Backscatter"
#define ROBOT_DETAILS "Faster firing & reload speed, 200 heal on kill"
#define ROBOT_COST 1.5
#define ROBOT_COIN_GENERATION 1
#define ROBOT_ON_DEATH "Vaccinator and Battalions Backup counters this robot"
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
	
	RoboSetHealth(client,TFClass_Scout, 2000, 1.5);	

	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 1.3);
	//TF2Attrib_SetByName(client, "damage force increase", 10.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.85);
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_DETAILS);
	
}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

#define BedouinBandana 30768
#define GoalKeeper 31217
#define Rippedrider 31281

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_scattergun", 1103, 6, 1, 2, 217);

		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		float TeamPaint = 0.0;

		if (iTeam == TFTeam_Blue){
			TeamPaint = 5801378.0;
			
		}
		if (iTeam == TFTeam_Red){
			
			TeamPaint = 12073019.0;
		}

		CreateRoboHat(client, BedouinBandana, 10, 6, TeamPaint, 1.0, -1.0); 
		CreateRoboHat(client, GoalKeeper, 10, 6, TeamPaint, 1.0, 1.0); 
		CreateRoboHat(client, Rippedrider, 10, 6, 0.0, 1.0, -1.0); 
		

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "reload time increased hidden", 0.75);
			TF2Attrib_SetByName(Weapon2, "weapon spread bonus", 0.7);

			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "heal on kill", 200.0);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs buildings", 0.5);
			TF2Attrib_SetByName(Weapon2, "closerange backattack minicrits", 1.0);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 1.25);
			
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.8);

			
		}

		
	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantscout(GetNativeCell(1));
