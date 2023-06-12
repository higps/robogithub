#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
// #include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <tf_custom_attributes>
#include <tf_ontakedamage>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Crocotron"
#define ROBOT_ROLE "Support"
#define ROBOT_CLASS "Sniper"
#define ROBOT_SUBCLASS "Sniper"
#define ROBOT_DESCRIPTION "Sydney Sleeper, Danger Shield"
#define ROBOT_TIPS "Immune to afterburn\nUse blast jump to get to high ground"
#define ROBOT_ON_DEATH "Crocotron is immune to afterburn\nCounter-snipe or backstab sniper bots while they are distracted"

#define ChangeDane             "models/bots/Sniper/bot_Sniper.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Jbird",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Jbird",
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
	// PrecacheModel(ChangeDane);




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


	int iHealth = 1500;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;

	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.65);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);

	TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 1.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);

	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	// TF2Attrib_SetByName(client, "major increased jump height", 1.9);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "afterburn immunity", 10.0);
	TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.5);

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
	GiveBigRoboJbird(client);
}


#define Snaggle 229
#define DangerShield 231
#define CrocodileDandy 31193

stock GiveBigRoboJbird(client)
{
	if (IsValidClient(client))
	{
		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //SniperRifle
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri

	CreateRoboWeapon(client, "tf_weapon_sniperrifle", 230, 6, 1, 0, 0);
	// CreateRoboWeapon(client, "tf_weapon_jar", 58, 6, 1, 1, 0);
	// CreateRoboWeapon(client, "tf_weapon_club", 401, 6, 1, 2, 0); //shahansah


	CreateRoboHat(client, Snaggle, 10, 6, 0.0, 1.25, -1.0); 
	CreateRoboHat(client, DangerShield, 10, 6, 0.0, 1.0, -1.0); 
	CreateRoboHat(client, CrocodileDandy, 10, 6, 0.0, 1.0, -1.0);
	


		
	int SniperRifle = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary); //SniperRifle
	// int Kukri = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee); //Shahanshah
	// int SMG = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary); //SMG



	if(IsValidEntity(SniperRifle))
		{	
			TF2Attrib_SetByName(SniperRifle, "killstreak tier", 1.0);
			TF2Attrib_SetByName(SniperRifle, "dmg penalty vs buildings", 0.65);
		
			TF2Attrib_SetByName(SniperRifle, "aiming no flinch", 1.0);
			TF2Attrib_SetByName(SniperRifle, "sniper aiming movespeed decreased", 0.01);
			TF2Attrib_SetByName(SniperRifle, "sniper charge per sec", 3.0);
			TF2Attrib_SetByName(SniperRifle, "sniper no headshots", 3.0);
			TF2Attrib_SetByName(SniperRifle, "headshot damage increase", 0.666);
			TF2Attrib_SetByName(SniperRifle, "sniper fires tracer HIDDEN", 1.0);


			
			
			TF2CustAttr_SetString(client, "Spell-Caster", "Spell=4 Cooldown=50.0");
		}

	// if(IsValidEntity(SMG))
	// 	{
	// 		// TF2Attrib_RemoveAll(SMG);
	// 		TF2Attrib_SetByName(SMG, "killstreak tier", 1.0);
	// 		TF2Attrib_SetByName(SMG, "effect bar recharge rate increased", 0.25);
			
			
	// 	}
	}
}
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	// if (!g_Enable)
	//     return Plugin_Continue;
	if(!IsValidClient(victim))
		return Plugin_Continue;    
	if(!IsValidClient(attacker))
		return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME))
	{

		SpawnBombs(victim, attacker);
		// BreadBoom(attacker, victim);


	}


	return Plugin_Continue;
}

void SpawnBombs(int client, int attacker)
{
    
    int team = GetClientTeam(attacker);
    float pos[3], vel[3];// ang[3];
    int children = 1;
    float speed = 250.0;


    GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
    

    pos[2] += 80.0;
    for (int i = 1; i <= children; i++)
    {
        int child = CreateEntityByName("tf_projectile_jar");
        
        
        float child_vel[3];
        float child_ang[3];

        //Prevent child grenades from detonating on contact
        SetEntProp(child, Prop_Send, "m_bTouched", 1);

        //Set properties
        //SetEntProp(child, Prop_Send, "m_bCritical", view_as<int>(crit));
        SetEntPropEnt(child, Prop_Data, "m_hOwnerEntity", attacker);
        SetEntPropEnt(child, Prop_Data, "m_hThrower", attacker);

        
        // SetEntPropFloat(child, Prop_Send, "m_flDamage", 100.0);
        // SetEntPropFloat(child, Prop_Send, "m_flModelScale", 1.2);
        
        GetClientEyeAngles(client, child_ang);
        
        GetAngleVectors(child_ang, child_vel, NULL_VECTOR, NULL_VECTOR);
        
        ScaleVector(child_vel, speed);
            
        //child_vel[2] = FloatAbs(child_vel[2]);

        SetEntProp(child, Prop_Send, "m_iTeamNum", team);
        SetEntProp(child, Prop_Send, "m_bIsLive", 1);

        TeleportEntity(child, pos, child_ang, child_vel);
        DispatchSpawn(child);
        //SDKHook(child, SDKHook_Touch, OnMirvOverlap);
    }
}