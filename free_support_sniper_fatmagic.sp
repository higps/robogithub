#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Fat Magic"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Sniper"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Bushwacka Piss Bot"
#define ROBOT_TIPS "Rapid swing Bushwacka, become ubered whenever jarated"


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

	// RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	// restrictions.RobotCoins.Overall = 1;

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

public OnMapStart()
{
	PrecacheModel(ChangeDane);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	PrecacheSound("^mvm/giant_common/giant_common_step_01.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_02.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_03.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_04.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_05.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_06.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_07.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_08.wav");


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


	int iHealth = 2250;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;

	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.65);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	// TF2Attrib_SetByName(client, "move speed penalty", 1.1);
	TF2Attrib_SetByName(client, "damage force reduction", 1.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "deploy time decreased", 0.05);
	TF2Attrib_SetByName(client, "move speed penalty", 0.85);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "major increased jump height", 0.8);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "health regen", 10.0);
	
	
	
	UpdatePlayerHitbox(client, 1.65);
	
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
	GiveBigRoboHuntsbot(client);
}

// public Action:Timer_Resize(Handle:timer, any:hat)
// {
	// if (IsValidClient(client))
	// GiveBigRoboHuntsbot(client);
// }


#define KingTavish 342

stock GiveBigRoboHuntsbot(client)
{
	if (IsValidClient(client))
	{

	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Huntsman
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri


	CreateRoboWeapon(client, "tf_weapon_jar", 58, 6, 1, 1, 0);

	CreateRoboWeapon(client, "tf_weapon_club", 232, 6, 1, 2, 0); //shahansah

	CreateRoboHat(client, KingTavish, 10, 6, 0.0, 1.25, 1.0); 
	CreateRoboHat(client, 31037, 10, 6, 0.0, 1.25, 1.0); 


	int Kukri = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee); //Shahanshah
	int SMG = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary); //SMG

	// int iEnt = -1;
	// while ((iEnt = FindEntityByClassname(iEnt, "tf_wearable")) != -1)
	//  {
	//     if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == client && GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex") == 31037) 
	// 	{
	//         // PrintToChatAll("ENT %i", iEnt);
	// 		// SetEntityRenderFx(iEnt, 0);
	// 		SetEntityRenderColor(iEnt, 128, 128, 128, 0);
			
    //     }
   	//  }
		if(IsValidEntity(SMG))
		{
			TF2Attrib_RemoveAll(SMG);
			
		TF2Attrib_SetByName(SMG, "provide on active", 1.0);
		// TF2Attrib_SetByName(SMG, "move speed penalty", 0.5);
		TF2Attrib_SetByName(SMG, "effect bar recharge rate increased", 0.25);
		
			

	}


	if(IsValidEntity(Kukri))
	{
	TF2Attrib_RemoveAll(Kukri);

	TF2Attrib_SetByName(Kukri, "killstreak tier", 1.0);
	TF2Attrib_SetByName(Kukri, "fire rate bonus", 0.8);
	TF2Attrib_SetByName(Kukri, "dmg penalty vs players", 1.75);
	TF2Attrib_SetByName(Kukri, "dmg penalty vs buildings", 0.25);
	TF2Attrib_SetByName(Kukri, "speed_boost_on_kill", 2.0);
	// TF2Attrib_SetByName(Kukri, "speed boost when active", 0.8);
	TF2Attrib_SetByName(Kukri, "heal on kill", 125.0);



	}
	}


}
		
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
	if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Jarated)
	{	
		TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.0);
		// TF2_AddCondition(client, TFCond_SpeedBuffAlly, 3.0);
		
	}
	
}


// public void OnEntityCreated(int iEntity, const char[] sClassName) 
// {
// 	if (StrContains(sClassName, "tf_projectile_arrow") == 0)
// 	{
// 		PrintToChatAll("Hooked arrow");
// 		SDKHook(iEntity, SDKHook_Spawn, Hook_OnProjectileSpawn);
// 	}
	
// }

// public void Hook_OnProjectileSpawn(iEntity) {
// 	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
// 	if (0 < iClient && iClient <= MaxClients && IsRobot(iClient, ROBOT_NAME)) {
// 		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 5.25);
// 	}
// }
