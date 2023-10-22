#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"MrPaladin2"
#define ROBOT_ROLE "Spy"
#define ROBOT_CLASS "Spy"
#define ROBOT_SUBCLASS "Spy"
#define ROBOT_DESCRIPTION "Turn invis on backstab"
#define ROBOT_ON_DEATH "MrPaladin becomes invisible on backstab\nPyro's flames & airblast can shut down spies"
#define ROBOT_COST 1.5
#define ROBOT_TIPS "Become invisible on backstab and attack while invisible!\nInfinite cloak"
#define MODEL             "models/bots/spy/bot_spy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

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
	robot.difficulty = ROBOT_DIFFICULTY_MEDIUM;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;

	AddRobot(robot, MakeSpy, PLUGIN_VERSION, restrictions);

	
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeSpy", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
	return APLRes_Success;
}




// }

public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int weaponID = GetEventInt(event, "weapon_def_index");
	int customkill = GetEventInt(event, "customkill");

	if (IsRobot(attacker, ROBOT_NAME) && weaponID == 356 && customkill == 2)
	{
		TF2_AddCondition(attacker, TFCond_Stealthed, 5.0);
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


	RoboSetHealth(client,TFClass_Spy, 1200, 1.5);
	float scale = 1.5;

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.95);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "voice pitch scale", 0.9);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	
	UpdatePlayerHitbox(client, scale);
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	Addcond(client);
	PrintHintText(client, ROBOT_TIPS);

	RequestFrame(Addcond, client);


}

void Addcond(int client)
{
	
}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveBigRoboDane(client);
}

// public Action:Timer_Resize(Handle:timer, any:hat)
// {
	// if (IsValidClient(client))
	// GiveBigRoboDane(client);
// }

#define Noir 319
#define LadyKiller 30476
#define Spek 343
#define WhitePaint 15132390.0



stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{

		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Revolver
	TF2_RemoveWeaponSlot(client, 2); // Gun
	TF2_RemoveWeaponSlot(client, 4);// inviswatch

	
	CreateRoboWeapon(client, "tf_weapon_revolver", 224, 6, 1, 0, 0);
	CreateRoboWeapon(client, "tf_weapon_knife", 356, 6, 1, 2, 0); //kunai
	CreateRoboWeapon(client, "tf_weapon_invis", 30, 6, 1, 4, 0); 
	CreateRoboWeapon(client, "tf_weapon_sapper", 1102, 6, 1, 1, 0);//snack attack

	// CreateRoboHat(client, Noir, 10, 6, WhitePaint, 1.0, -1.0); 
	// CreateRoboHat(client, LadyKiller, 10, 6, 0.0, 1.0, -1.0);
	// CreateRoboHat(client, Spek, 10, 6, 0.0, 1.0, -1.0);
	
		
	int Revolver = GetPlayerWeaponSlot(client, 0); //Revolver
	int Knife = GetPlayerWeaponSlot(client, 2); //Knife
	int Cloak = GetPlayerWeaponSlot(client, 4); //Invis watch
	int Sapper = GetPlayerWeaponSlot(client, 1); //Sapper

	if(IsValidEntity(Revolver)) //Revovler
		{
			TF2Attrib_RemoveAll(Revolver);
			
			// TF2Attrib_SetByName(Revolver, "fire rate bonus", 2.5);
			// TF2Attrib_SetByName(Revolver, "damage bonus", 2.0);
			TF2Attrib_SetByName(Revolver, "dmg penalty vs buildings", 0.25);	
			TF2Attrib_SetByName(Revolver, "killstreak tier", 1.0);
						
		}

	if(IsValidEntity(Knife)) //
		{
			TF2Attrib_RemoveAll(Knife);
			
			//TF2Attrib_SetByName(Knife, "fire rate bonus", 0.8);
			//TF2Attrib_SetByName(Knife, "damage bonus", 1.5);
			TF2Attrib_SetByName(Knife, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Knife, "sanguisuge", 0.0);
			TF2Attrib_SetByName(Knife, "restore health on kill", 10.0);
			
						
		}
	if(IsValidEntity(Cloak)) //
		{
			TF2Attrib_RemoveAll(Cloak);
			
			TF2Attrib_SetByName(Cloak, "mult cloak meter consume rate", -100.0);
			TF2Attrib_SetByName(Cloak, "mult decloak rate", 0.3);

			
						
		}
	if(IsValidEntity(Sapper)) //
		{
			TF2Attrib_RemoveAll(Sapper);
			
		//	TF2Attrib_SetByName(Sapper, "mult cloak meter consume rate", 0.0);
			TF2Attrib_SetByName(Sapper, "sapper damage leaches health", 5.0);
			TF2Attrib_SetByName(Sapper, "robo sapper", 100.0);
			
			//TF2Attrib_SetByName(Sapper, "min_viewmodel_offset", 5 -2 -4);
		}	
	}

	TF2_AddCondition(client, TFCond_Cloaked);
}
