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

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Mr Paladin"
#define ROBOT_ROLE "Support"
#define ROBOT_DESCRIPTION "Turn invisible on backstab"

#define MODEL             "models/bots/spy/bot_spy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

#define SPY_SPAWN_SOUND1		"vo/mvm_spy_spawn01.mp3"
#define SPY_SPAWN_SOUND2		"vo/mvm_spy_spawn02.mp3"
#define SPY_SPAWN_SOUND3		"vo/mvm_spy_spawn03.mp3"
#define SPY_SPAWN_SOUND4		"vo/mvm_spy_spawn04.mp3"

// #define SPY_DEATH_SOUND1		"vo/mvm_spybot_death01.mp3"
// #define SPY_DEATH_SOUND2		"vo/mvm_spybot_death02.mp3"
// #define SPY_DEATH_SOUND3		"vo/mvm_spybot_death03.mp3"
// #define SPY_DEATH_SOUND4		"vo/mvm_spybot_death04.mp3"
// #define SPY_DEATH_SOUND5		"vo/mvm_spybot_death05.mp3"
// #define SPY_DEATH_SOUND6		"vo/mvm_spybot_death06.mp3"
// #define SPY_DEATH_SOUND7		"vo/mvm_spybot_death07.mp3"


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
    robot.class = "Spy";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
    restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
    restrictions.RobotCoins.PerRobot = 1;

    AddRobot(robot, MakeSpy, PLUGIN_VERSION, restrictions);

	PrecacheModel(MODEL);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);

	// PrecacheSound(SPY_SPAWN_SOUND1, true);
	// PrecacheSound(SPY_SPAWN_SOUND2, true);
	// PrecacheSound(SPY_SPAWN_SOUND3, true);
	// PrecacheSound(SPY_SPAWN_SOUND4, true);
	// PrecacheSound(SPY_DEATH_SOUND1, true);
	// PrecacheSound(SPY_DEATH_SOUND2, true);
	// PrecacheSound(SPY_DEATH_SOUND3, true);
	// PrecacheSound(SPY_DEATH_SOUND4, true);
	// PrecacheSound(SPY_DEATH_SOUND5, true);
	// PrecacheSound(SPY_DEATH_SOUND6, true);
	// PrecacheSound(SPY_DEATH_SOUND7, true);
	
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

// public OnMapStart()
// {
// 	PrecacheModel(MODEL);
// 	PrecacheSound(SPAWN);
// 	PrecacheSound(DEATH);
// 	PrecacheSound(LOOP);


// }

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


	int iHealth = 955;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;

	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.65);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	//TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	//TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	// TF2Attrib_SetByName(client, "maxammo metal increased", 2.5);
	// TF2Attrib_SetByName(client, "engy building health bonus", 2.0);
	// TF2Attrib_SetByName(client, "engy dispenser radius increased", 3.0);
	// TF2Attrib_SetByName(client, "metal regen", 50.0);
	
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	
	
	UpdatePlayerHitbox(client, 1.65);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	
	PrintToChat(client, "1. You are now Giant Mr Paladin robot!");
	PrintHintText(client, "Infinite Cloak\nStab enemies to gain buff to kill while stealthed!\nHeal from sapping buildings");

	if (IsPlayerAlive(client)){
	EmitGameSoundToAll("Announcer.MVM_Spy_Alert");
	} 


}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
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

	CreateRoboHat(client, Noir, 10, 6, WhitePaint, 1.0, -1.0); 
	CreateRoboHat(client, LadyKiller, 10, 6, 0.0, 1.0, -1.0);
	CreateRoboHat(client, Spek, 10, 6, 0.0, 1.0, -1.0);
	
		
	int Revolver = GetPlayerWeaponSlot(client, 0); //Revolver
	int Knife = GetPlayerWeaponSlot(client, 2); //Knife
	int Cloak = GetPlayerWeaponSlot(client, 4); //Invis watch
	int Sapper = GetPlayerWeaponSlot(client, 1); //Sapper

	if(IsValidEntity(Revolver)) //Revovler
		{
			TF2Attrib_RemoveAll(Revolver);
			
			TF2Attrib_SetByName(Revolver, "fire rate bonus", 2.5);
			TF2Attrib_SetByName(Revolver, "damage bonus", 2.0);
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
			TF2Attrib_SetByName(Cloak, "mult decloak rate", 0.4);

			
						
		}
	if(IsValidEntity(Sapper)) //
		{
			TF2Attrib_RemoveAll(Sapper);
			
		//	TF2Attrib_SetByName(Sapper, "mult cloak meter consume rate", 0.0);
			TF2Attrib_SetByName(Sapper, "sapper damage leaches health", 50.0);
			TF2Attrib_SetByName(Sapper, "robo sapper", 150.0);
			
			//TF2Attrib_SetByName(Sapper, "min_viewmodel_offset", 5 -2 -4);
		}	
	}
}