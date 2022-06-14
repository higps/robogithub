#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Dr. Crossbow Cop"
#define ROBOT_ROLE "Healer"
#define ROBOT_DESCRIPTION "Rapid fire Crossbow"
 
#define GMEDIC             "models/bots/medic/bot_medic.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_demoman/giant_demoman_loop.wav"
 
public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Dr. Crossbow Cop",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Medic from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Medic";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeGiantMedic, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantMedic_MakeGiantMedic", Native_SetGiantMedic);
//	CreateNative("BeGiantMedic_IsGiantMedic", Native_IsGiantMedic);
	return APLRes_Success;
}
 
public OnMapStart()
{
	PrecacheModel(GMEDIC);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
   
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

MakeGiantMedic(client)
{
	TF2_SetPlayerClass(client, TFClass_Medic);
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
	SetModel(client, GMEDIC);
   
	int iHealth = 2500;
	int MaxHealth = 150;
	int iAdditiveHP = iHealth - MaxHealth;
   
	TF2_SetHealth(client, iHealth);
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.6);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "health regen", 20.0);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "maxammo primary increased", 2.5);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintToChat(client, "1. You are now Giant Dr. Crossbow Cop !");
	PrintHintText(client , "Primary: Rapid Fire Heal Crossbow\nMelee: Hit enemies with your Crossbow");

}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {
       TF2_AddCondition(client,TFCond_HalloweenQuickHeal, 2.5);
	  // TF2_AddCondition(client,TFCond_HalloweenSpeedBoost, 15.0);
    }
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
			GiveGiantMedic(client);
}

#define MACHOMANN 30085
#define THELAW 30362
#define LICENSETOMAIM 296

stock GiveGiantMedic(client)
{
	if (IsValidClient(client))
	{
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
	
		RoboRemoveAllWearables(client);
		
		CreateRoboWeapon(client, "tf_weapon_crossbow", 305, 6, 1, 0, 0);
		CreateRoboWeapon(client, "tf_weapon_bonesaw", 305, 6, 1, 2, 0);
		
		CreateRoboHat(client, MACHOMANN, 10, 6, 0.0, 1.0 , -1.0); //Macho mann
		CreateRoboHat(client, THELAW, 10, 6, 0.0, 1.0 , -1.0); //the law
		CreateRoboHat(client, LICENSETOMAIM, 10, 6, 0.0, 1.0 , -1.0);//License to maim
		
		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "damage bonus", 0.5);
			//TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.25);
			//TF2Attrib_SetByName(Weapon1, "heal on hit for slowfire", 50.0);

			TF2Attrib_SetByName(Weapon1, "clip size bonus", 6.0);
			TF2Attrib_SetByName(Weapon1, "Reload time decreased", 1.5);
			TF2Attrib_SetByName(Weapon1, "hidden primary max ammo bonus", 2.0);
			TF2Attrib_SetByName(Weapon1, "dmg bonus vs buildings", 0.25);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
		}

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 1.25);
			TF2Attrib_SetByName(Weapon2, "heal on hit for slowfire", 50.0);
		}
		
	}
}
       


