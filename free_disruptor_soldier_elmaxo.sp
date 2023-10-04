#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
//#include <tf_ontakedamage>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Elmaxo"
#define ROBOT_ROLE "Disruptor"
#define ROBOT_CLASS "Soldier"
#define ROBOT_SUBCLASS "Disruptor"
#define ROBOT_DESCRIPTION "The Original, Market Gardner"
#define ROBOT_ON_DEATH "Blast jumpers can be countered heavily by the Reserve Shooter"

#define GSOLDIER		"models/bots/soldier/bot_soldier.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

// #define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
// #define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
// #define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Basic Soldier",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Icebear from Frankfurt",
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

	//	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);


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
	AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION, null);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantSoldier", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
	




	// PrecacheSound(GUNFIRE);
	// PrecacheSound(GUNFIRE_CRIT);
	// PrecacheSound(GUNFIRE_EXPLOSION);
	



	
	
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);
	
}

/* public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_bIsGSoldier[client])
	{
		g_bIsGSoldier[client] = false;
	}
} */

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

MakeGiantSoldier(client)
{
	SMLogTag(SML_VERBOSE, "Createing Soldier");
	TF2_SetPlayerClass(client, TFClass_Soldier);
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
	SetModel(client, GSOLDIER);
	
	RoboSetHealth(client, TFClass_, 2000, 1.5);
		
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	
	float OverHealRate = 1.5;



	float scale = 1.65;
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.85);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.5);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 1.25);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	//TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2CustAttr_SetString(client, "fall-damage", "static-damage=1 static-damage-stomp=1 fall-damage=100.0 stomp-damage=125.0");
	
	TF2Attrib_SetByName(client, "self dmg push force increased", 8.0);
	TF2Attrib_SetByName(client, "boots falling stomp", 1.0);
	//TF2Attrib_SetByName(client, "rocket jump damage reduction", 0.2);
	
	
	//
	TF2Attrib_SetByName(client, "deploy time decreased", 0.6);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.65);
	UpdatePlayerHitbox(client,scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , "You generate addotional resources on death for your team\nYou can rocket jump");
	
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


#define TyrantHelm 99
#define MistakenMovember 30554
#define Gunboats 133

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_rocketlauncher", 513, 6, 1, 2, 0);
		// CreateRoboWeapon(client, "tf_weapon_shotgun_soldier", 10, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_shovel", 416, 6, 1, 2, 0);

		//CreateRoboHat(client, 1101, 10, 6, 0.0, 5.0, -1.0); //parachute

		


		CreateRoboHat(client, TyrantHelm, 10, 6, 1315860.0, 1.2, -1.0);
		CreateRoboHat(client, MistakenMovember, 10, 6, 0.0, 1.265, -1.0);
		CreateRoboHat(client, Gunboats, 10, 6, 0.0, 0.75, -1.0);


		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 1.35);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.75);	
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 0.75);		
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.35);	
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
		}
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.25);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);	
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.25);							
		}
		

	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));
	
// public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
// {

// 		if (!IsRobot(victim, ROBOT_NAME))
// 		{
// 			if (damagecustom == TF_CUSTOM_BOOTS_STOMP)
// 			{
				
// 				PrintToChatAll("Damage was %f, type was %i on %N", damage, damagetype, victim);
// 				return Plugin_Changed;

// 			}
// 		}
// //if (StrEqual(robot.role,"ZBOSS"))
// 		if (IsRobot(victim, ROBOT_NAME) && attacker == 0)
// 		{
// 			if (damagetype == 32){
// 				damage = 0.0;
// 				PrintToChatAll("Was victim %N, attacker was %N", victim, attacker);
// 				//return Plugin_Changed;
// 			}

// 		}

// 		// if (IsRobot(attacker, ROBOT_NAME))
// 		// {
// 		// 	if (damagetype == 32){
// 		// 		//damage = 0.0;
// 		// 		PrintToChatAll("%N was attacker", attacker);
// 		// 		//return Plugin_Changed;
// 		// 	}

// 		// }

	

// }
