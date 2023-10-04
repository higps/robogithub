#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Huntsbot"
#define ROBOT_ROLE "Sniper"
#define ROBOT_CLASS "Sniper"
#define ROBOT_SUBCLASS "Sniper"
#define ROBOT_DESCRIPTION "Penetrating Huntsman"
#define ROBOT_TIPS "Arrows penetrate enemies!\nArrows reload faster\nDefend yourself with your Kukri"
#define ROBOT_ON_DEATH "Huntsbot's arrows penetrate multiple targets\nCounter-snipe or backstab sniper bots while they are distracted"

#define ChangeDane             "models/bots/Sniper/bot_Sniper.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Huntsbot",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Huntsbot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	//HookEvent("player_death", Event_Death, EventHookMode_Post);

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
	robot.difficulty = ROBOT_DIFFICULTY_HARD;

	AddRobot(robot, MakeSniper, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeSniper", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
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

MakeSniper(client)
{

	TF2_RemoveWeaponSlot(client, 0); //Huntsman
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri

	TF2_SetPlayerClass(client, TFClass_Sniper);
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
	SetModel(client, ChangeDane);


	RoboSetHealth(client,TFClass_Sniper, 1500, 1.5);
	float scale = 1.5;


	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);

	TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 1.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	
	
	
	
	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);
	
}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveBigRoboHuntsbot(client);
}

// public Action:Timer_Resize(Handle:timer, any:hat)
// {
	// if (IsValidClient(client))
	// GiveBigRoboHuntsbot(client);
// }

#define ArcherSterling 30874
#define GuiltenGuardian 30857

stock GiveBigRoboHuntsbot(client)
{
	if (IsValidClient(client))
	{
		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Huntsman
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri


	CreateRoboWeapon(client, "tf_weapon_compound_bow", 56, 6, 1, 0, 0);
	CreateRoboWeapon(client, "tf_weapon_club", 3, 6, 1, 2, 0); //shahansah

	CreateRoboHat(client, ArcherSterling, 10, 6, 0.0, 0.75, -1.0); 
	CreateRoboHat(client, GuiltenGuardian, 10, 6, 0.0, 1.0, -1.0); 		
	int Huntsman = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	int Kukri = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);




	if(IsValidEntity(Huntsman))
		{
			TF2Attrib_RemoveAll(Huntsman);
			
			TF2Attrib_SetByName(Huntsman, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Huntsman, "dmg penalty vs buildings", 0.3);
			TF2Attrib_SetByName(Huntsman, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Huntsman, "gesture speed increase", 1.95);
			TF2Attrib_SetByName(Huntsman, "fire rate bonus", 0.4);
			TF2Attrib_SetByName(Huntsman, "heal on kill", 50.0);		
			
		}

		if(IsValidEntity(Kukri))
		{
			TF2Attrib_RemoveAll(Kukri);
			
			TF2Attrib_SetByName(Kukri, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Kukri, "dmg penalty vs buildings", 0.5);

		}
	}


}