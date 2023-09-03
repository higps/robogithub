#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
//#include <tf2items_giveweapon>
#include <tf_ontakedamage.inc>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Black Shiv"
#define ROBOT_ROLE "Spy"
#define ROBOT_CLASS "Spy"
#define ROBOT_SUBCLASS "Spy"
#define ROBOT_DESCRIPTION "Grappling hook, Silent Killer"
#define ROBOT_TIPS "Sharp Dresser\nDead Ringer\nUse grappling hook with reload or specialattack!"
#define ROBOT_COST 1.0
#define ROBOT_COIN_GENERATION 1
#define ROBOT_ON_DEATH "Keeping this robot on fire is key to getting it destroyed\nReserve Shooter crits grappling targets"
#define MODEL             "models/bots/spy/bot_spy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

bool g_PressedButton[MAXPLAYERS + 1] = {false, ...};

public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Spy",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Spy",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

//bool g_bisGSPY[MAXPLAYERS + 1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	HookEvent("player_death", Event_Death, EventHookMode_Post);

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
	robot.footstep = ROBOT_FOOTSTEP_NORMAL;

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeSpy, PLUGIN_VERSION, restrictions, ROBOT_COIN_GENERATION);
	PrecacheModel(MODEL);


	
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}


public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int weaponID = GetEventInt(event, "weapon_def_index");
	int customkill = GetEventInt(event, "customkill");

	if (IsRobot(attacker, ROBOT_NAME) && weaponID == 356 && customkill == 2)
	{
		TF2_AddCondition(attacker, TFCond_StealthedUserBuffFade, 5.0);
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

MakeSpy(client)
{
	TF2_SetPlayerClass(client, TFClass_Spy);
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
	SetModel(client, MODEL);


	int iHealth = 2250;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;
	float scale = 1.5;
	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.95);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	
	TF2Attrib_SetByName(client, "maxammo metal increased", 2.5);
	
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	
	
	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	
	PrintHintText(client, ROBOT_TIPS);
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

#define DashinHashshashin 637
#define TheRogueRobe 30389 

stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{

		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Revolver
	TF2_RemoveWeaponSlot(client, 1); // Sapper
	TF2_RemoveWeaponSlot(client, 2); // Knife
	TF2_RemoveWeaponSlot(client, 3);// Disguise kit
	TF2_RemoveWeaponSlot(client, 4);// inviswatch


	
	// CreateRoboWeapon(client, "tf_weapon_revolver", 224, 6, 1, 0, 0);
	CreateRoboWeapon(client, "tf_weapon_knife", 638, 6, 1, 2, 0); //sharp dresser
	CreateRoboWeapon(client, "tf_weapon_grapplinghook", 1152, 6, 1, 3, 0);
	CreateRoboWeapon(client, "tf_weapon_sapper", 735, 6, 1, 1, 0); 
	CreateRoboWeapon(client, "tf_weapon_invis", 59, 6, 1, 4, 0); 
		

	CreateRoboHat(client, DashinHashshashin, 10, 6, 0.0, 1.0, -1.0); 
	CreateRoboHat(client, TheRogueRobe, 10, 6, 0.0, 1.0, 1.0);
	// CreateRoboHat(client, ArkhamCowl, 10, 6, 0.0, 1.25, -1.0);
	
		
//	int Revolver = GetPlayerWeaponSlot(client, 0); //Revolver
	int Knife = GetPlayerWeaponSlot(client, 2); //Knife
	int Cloak = GetPlayerWeaponSlot(client, 4); //Invis watch
	int Sapper = GetPlayerWeaponSlot(client, 1); //Sapper

	if(IsValidEntity(Cloak)) //
		{
			// TF2Attrib_RemoveAll(Cloak);
			
			TF2Attrib_SetByName(Cloak, "mult cloak meter consume rate", -100.0);
			TF2Attrib_SetByName(Cloak, "mult decloak rate", 0.36);
		}

	if(IsValidEntity(Knife)) //
		{
			TF2Attrib_RemoveAll(Knife);
			
			//TF2Attrib_SetByName(Sapper, "robo sapper", 150.0);
			
			
			TF2Attrib_SetByName(Knife, "silent killer", 1.0);
			TF2Attrib_SetByName(Knife, "damage penalty", 0.75);
			TF2Attrib_SetByName(Knife, "fire rate bonus", 0.55);
			TF2Attrib_SetByName(Knife, "dmg penalty vs buildings", 0.0);
		}

	if(IsValidEntity(Sapper)) //
		{
			TF2Attrib_RemoveAll(Sapper);
			
		//	TF2Attrib_SetByName(Sapper, "mult cloak meter consume rate", 0.0);
			TF2Attrib_SetByName(Sapper, "sapper damage leaches health", 50.0);
			TF2Attrib_SetByName(Sapper, "robo sapper", 150.0);
			
			//TF2Attrib_SetByName(Sapper, "min_viewmodel_offset", 5 -2 -4);
		}	
		TF2_AddCondition(client, TFCond_Cloaked);
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME) && buttons & (IN_ATTACK3|IN_USE))
	{
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		if (!g_PressedButton[client])
		{
		FakeClientCommand(client, "use tf_weapon_grapplinghook");
		CreateTimer(1.0, Timer_Button, client);
		}
		g_PressedButton[client] = true;
		//SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tf_weapon_grapplinghook");
	}
	return Plugin_Continue;
}

public Action Timer_Button(Handle timer, any client)
{
	g_PressedButton[client] = false;
	return Plugin_Continue;
}
