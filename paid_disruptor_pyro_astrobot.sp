#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Astrobot"
#define ROBOT_ROLE "Disruptor"
#define ROBOT_CLASS "Pyro"
#define ROBOT_SUBCLASS "Disruptor"
#define ROBOT_DESCRIPTION "Low Gravity Pyro"
#define ROBOT_TIPS "25%%%% Faster Airblast\nAirblasts propel you backwards while airborne\nHeal 175 on extinguish"
#define ROBOT_ON_DEATH "Low gravity robots are open for fire while jumping\nForce them away with knockback"
#define ROBOT_COST 0.75
#define ROBOT_COIN_GENERATION 2

#define GPYRO		"models/bots/pyro_boss/bot_pyro_boss.mdl"
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
	robot.footstep = ROBOT_FOOTSTEP_GIANTCOMMON;
	robot.difficulty = ROBOT_DIFFICULTY_HARD;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeGiantPyro, PLUGIN_VERSION, restrictions, ROBOT_COIN_GENERATION);
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
//



	
	// PrecacheSound(SOUND_GUNFIRE);
	// PrecacheSound(SOUND_WINDUP);
	
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
	SMLogTag(SML_VERBOSE, "Createing Agro");
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
	
	int iHealth = 3000;
		
	int MaxHealth = 175;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.65);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	// TF2Attrib_SetByName(client, "override footstep sound set", 6.0);
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.75);

	
	
	UpdatePlayerHitbox(client, 1.75);
	
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
		GiveGiantPyro(client);
}
#define MoonmanBackpack  596 
#define MK50  30473 
#define SpaceDiver   30664 

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{		
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_flamethrower", 30474, 6, 1, 2, 0);	

		
		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		
		float TeamPaint = 0.0;

		if (iTeam == TFTeam_Blue){
			TeamPaint = 12807213.0;
		}
		if (iTeam == TFTeam_Red){
			TeamPaint = 12091445.0;
		}

		CreateRoboHat(client, MoonmanBackpack, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, MK50, 10, 6, TeamPaint, 0.75, -1.0);
		CreateRoboHat(client, SpaceDiver, 10, 6, 0.0, 0.75, -1.0);
		// CreateRoboHat(client, Pyrotechnic, 10, 6, 5322826.0, 0.75, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

		
		if(IsValidEntity(Weapon1))
		{
			//TF2Attrib_RemoveAll(Weapon1);
			// TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.25);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			// TF2Attrib_SetByName(Weapon1, "airblast pushback scale", 1.6);		
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.15);			
			// TF2Attrib_SetByName(Weapon1, "flame_spread_degree", 5.0);			
			// TF2Attrib_SetByName(Weapon1, "flame size bonus", 1.6);
			// TF2Attrib_SetByName(Weapon1, "flame_speed", 3600.0);
			TF2Attrib_SetByName(Weapon1, "extinguish restores health", 175.0);
			
			TF2CustAttr_SetString(client, "Player-Gravity", "amount=0.16");	
			// TF2Attrib_SetByName(Weapon1, "airblast vertical pushback scale", 1.5);
			
			// charged airblast


		}
	}
}


float fl_NextSecondaryAttack[MAXPLAYERS+1] = {0.0,...};
float AirblastPower = 175.0;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(IsRobot(client, ROBOT_NAME) && IsPlayerAlive(client))
	{

			// Class Check
				new String:weaponname[64], wep, Float:fl_EyeAngles[3], Float:fl_vel[3];
				GetClientEyeAngles(client, fl_EyeAngles);
				fl_EyeAngles[0] = DegToRad(-1.0 * fl_EyeAngles[0]);
				fl_EyeAngles[1] = DegToRad(fl_EyeAngles[1]);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", fl_vel);
				wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				GetEntityClassname(wep, weaponname, sizeof(weaponname));

				if(buttons & IN_ATTACK2 &&
				(GetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack") - fl_NextSecondaryAttack[client]) > 0.0)
				{
					fl_NextSecondaryAttack[client] = GetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack");
					fl_vel[0] -= AirblastPower * Cosine(fl_EyeAngles[0]) * Cosine(fl_EyeAngles[1]);
					fl_vel[1] -= AirblastPower * Cosine(fl_EyeAngles[0]) * Sine(fl_EyeAngles[1]);
					fl_vel[2] -= AirblastPower * Sine(fl_EyeAngles[0]);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fl_vel);
				}
				
				// // Flamethrower Jetpack
				// if(buttons & IN_ATTACK && RadToDeg(-fl_EyeAngles[0]) >= 60.0)
				// {
				// 	fl_vel[0] -= GetConVarFloat(mobp_JetpackPower) * Cosine(fl_EyeAngles[0]) * Cosine(fl_EyeAngles[1]);
				// 	fl_vel[1] -= GetConVarFloat(mobp_JetpackPower) * Cosine(fl_EyeAngles[0]) * Sine(fl_EyeAngles[1]);
				// 	fl_vel[2] -= GetConVarFloat(mobp_JetpackPower) * Sine(fl_EyeAngles[0]);
				// 	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fl_vel);
				// }
	
					}
				

	
}
