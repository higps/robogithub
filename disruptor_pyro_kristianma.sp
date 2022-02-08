#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
//#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Kristianma"
#define ROBOT_ROLE "Disruptor"
#define ROBOT_DESCRIPTION "Detonator, Axtinguisher"

#define GPYRO		"models/bots/pyro/bot_pyro.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_pyro/giant_pyro_loop.wav"

#define SOUND_GUNFIRE	")mvm/giant_pyro/giant_pyro_flamethrower_loop.wav"
#define SOUND_WINDUP	")mvm/giant_pyro/giant_pyro_flamethrower_start.wav"



public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Agro Pyro",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Agro Pyro from Kritzkast",
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

new bool:Locked1[MAXPLAYERS+1];
new bool:Locked2[MAXPLAYERS+1];
new bool:Locked3[MAXPLAYERS+1];
new bool:CanWindDown[MAXPLAYERS+1];

public OnPluginStart()
{
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

    LoadTranslations("common.phrases");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Pyro";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.gunfire = SOUND_GUNFIRE;
    robot.sounds.windup = SOUND_WINDUP;
    robot.sounds.death = DEATH;

    AddRobot(robot, MakeGiantPyro, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantPyro", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheModel(GPYRO);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	PrecacheSound(SOUND_GUNFIRE);
	PrecacheSound(SOUND_WINDUP);
	
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

MakeGiantPyro(client)
{
	//aSMLOGTag(SML_VERBOSE, "Createing Kristianma");
	TF2_SetPlayerClass(client, TFClass_Pyro);
	//TF2_RespawnPlayer(client);
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
	SetModel(client, GPYRO);
	
	int iHealth = 2000;
		
	int MaxHealth = 175;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	// PrintToChatAll("iHealth %i", iHealth);
	float scale = 1.65;
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.75);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 6.0);
	TF2Attrib_SetByName(client, "deploy time decreased", 0.25);
	
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.75);

	
	
	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	
	PrintHintText(client , "Jump in with detonator and whack enemis with axtinguisher");
	
	
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}


#define HEADWARMER 644
#define CUTESUIT 30367
#define FLASHDANCEFOOTIES 30551

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{		
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		//CreateRoboWeapon(client, "tf_weapon_flamethrower", 215, 6, 1, 2, 0);	
		CreateRoboWeapon(client, "tf_weapon_flaregun", 351, 6, 1, 2, 390);
		CreateRoboWeapon(client, "tf_weapon_fireaxe", 38, 6, 1, 2, 0);

		//CreateRoboWeapon(client, "tf_weapon_grenadelauncher", 1151, 8, 1, 0, 213);
		
		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		
		float TeamPaint = 0.0;

		// Team Spirit
		// set item tint RGB : 12073019
		// set item tint RGB 2 : 5801378

		if (iTeam == TFTeam_Blue){
			TeamPaint = 12073019.0;
		}
		if (iTeam == TFTeam_Red){
			TeamPaint = 5801378.0;
		}

		CreateRoboHat(client, HEADWARMER, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, CUTESUIT, 10, 6, TeamPaint, 0.75, -1.0);
		CreateRoboHat(client, FLASHDANCEFOOTIES, 10, 6, 0.0, 0.75, -1.0);

	//	int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		// if(IsValidEntity(Weapon1))
		// {
		// 	TF2Attrib_RemoveAll(Weapon1);
		// 	TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.5);
		// 	TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
		// 	TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
		// 	TF2Attrib_SetByName(Weapon1, "airblast pushback scale", 0.6);		
		// 	TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.8);			
		// 	TF2Attrib_SetByName(Weapon1, "flame_spread_degree", 5.0);			
		// 	TF2Attrib_SetByName(Weapon1, "flame size bonus", 1.6);
		// 	TF2Attrib_SetByName(Weapon1, "flame_speed", 3600.0);
		// 	TF2Attrib_SetByName(Weapon1, "single wep deploy time decreased", 0.4);
		// 	TF2Attrib_SetByName(Weapon1, "switch from wep deploy time decreased", 0.7);
		// 	TF2Attrib_SetByName(Weapon1, "weapon burn dmg reduced", 1.0);

		// }
		
		if(IsValidEntity(Weapon2))
		{
			//TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 1.75);
			// TF2Attrib_SetByName(Weapon2, "Projectile speed decreased", 0.6);
			// TF2Attrib_SetByName(Weapon2, "damage causes airblast", 1.0);
			// TF2Attrib_SetByName(Weapon2, "mod projectile heat seek power", 3600.0);
			//TF2Attrib_SetByName(Weapon2, "apply look velocity on damage", 1500.0);
			TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 2.5);
			TF2Attrib_SetByName(Weapon2, "self dmg push force increased", 10.0);
			TF2Attrib_SetByName(Weapon2, "Blast radius increased", 1.75);
			TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.7);
			
			
			
			
		}

		if(IsValidEntity(Weapon3))
		{
			//TF2Attrib_RemoveAll(Weapon3);
			TF2Attrib_SetByName(Weapon3, "is australium item", 1.0);
			TF2Attrib_SetByName(Weapon3, "item style override", 1.0);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.5);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.4);
			TF2Attrib_SetByName(Weapon3, "fire rate penalty", 1.2);
			TF2Attrib_SetByName(Weapon3, "heal on kill", 175.0);
			
			//TF2Attrib_SetByName(Weapon2, "apply look velocity on damage", 1500.0);
		}
	}
}