#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
// #include <dhooks>
#include <tf_ontakedamage>
// #include <tf_custom_attributes>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Bread Virus"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Applies Mad Milk to enemies in a radius"
#define ROBOT_TIPS "Hitting enemies will cover them in mad milk for 5"
 
#define GDEFLECTORH      "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN	"mvm/mvm_tank_horn.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/mvm_tank_loop.wav"

#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"


//#define GIFTBRINGER 30747

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Deflector Heavy",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
 
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	AddNormalSoundHook(BossGPS);

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;

	AddRobot(robot, MakeGDeflectorH, PLUGIN_VERSION);


}

public Action:BossGPS(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step01.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step03.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step02.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step04.wav");
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGDeflectorH_MakeGDeflectorH", Native_SetGDeflectorH);
//	CreateNative("BeGDeflectorH_IsGDeflectorH", Native_IsGDeflectorH);
	return APLRes_Success;
}
 
public OnMapStart()
{
	PrecacheModel(GDEFLECTORH);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	// PrecacheSound(sBoomNoise1);
	// PrecacheSound(sBoomNoise2);
	// PrecacheSound(sBoomNoise3);

	// PrecacheSound("^mvm/giant_common/giant_common_step_01.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_02.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_03.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_04.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_05.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_06.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_07.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_08.wav");
	
	PrecacheSound("mvm/giant_heavy/giant_heavy_step01.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step03.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step02.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step04.wav");
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

MakeGDeflectorH(client)
{	
	TF2_SetPlayerClass(client, TFClass_Heavy);
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
	SetModel(client, GDEFLECTORH);
	int iHealth = 7000;
	
	
	int MaxHealth = 300;
	int iAdditiveHP = iHealth - MaxHealth;
	float OverHealRate = 1.5;


	TF2_SetHealth(client, iHealth);
		// PrintToChatAll("MaxHealth %i", MaxHealth);
	 // PrintToChatAll("iHealth %i", iHealth);
	
	 // PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;

	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	
	float scale = 1.8;
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "hand scale", 1.35);
	TF2Attrib_SetByName(client, "head scale", 0.8);

	TF2Attrib_SetByName(client, "damage force reduction", 0.0);

	UpdatePlayerHitbox(client, scale);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);


	PrintHintText(client , ROBOT_TIPS);

		//Tank stats
    TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.75);
    TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
	TF2_AddCondition(client,TFCond_DefenseBuffNoCritBlock);

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
		GiveGDeflectorH(client);
}

#define EliminatorSafeguard 31020
#define Spooktacles 31062
#define AirborneAttire 31060
// Cosmetics: Bread Heads(31020), Bread Biter(31062), BINOCULUS(31060)
stock GiveGDeflectorH(client)
{
	if (IsValidClient(client))
	{
		//Remove items and hats
		RoboRemoveAllWearables(client);
		//TF2_RemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		//void  CreateRoboHat(int client, int itemindex, int level, int quality, float paint, float scale, float style);
		CreateRoboHat(client, EliminatorSafeguard, 10, 6, 15132390.0, 1.0, 1.0);//Rotation sensation
		CreateRoboHat(client, Spooktacles, 10, 6, 8289918.0, 1.0, -1.0);//Summer shades
		CreateRoboHat(client, AirborneAttire, 10, 6, 0.0, 1.0, -1.0);


		CreateRoboWeapon(client, "tf_weapon_fists", 1100, 6, 1, 0, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{
			// TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.1);
			//TF2Attrib_SetByName(Weapon1, "critboost on kill", 180.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);
			// TF2Attrib_SetByName(Weapon1, "fire rate penalty", 0.75);
			TF2Attrib_SetByName(Weapon1, "reduced_healing_from_medics", 1.0);
			// TF2Attrib_SetByName(Weapon1, "move speed bonus", 0.693);
			TF2Attrib_SetByName(Weapon1, "mod_maxhealth_drain_rate", 0.0);
			// TF2Attrib_SetByName(Weapon1, "heal on kill", 200.0);
			TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			TF2CustAttr_SetString(Weapon1, "shake on hit", "amplitude=10.0 frequency=2.0 duration=0.5");
			// TF2CustAttr_SetString(Weapon1, "on-hit-addcond", "TFCond=27 duration=10.0 apply-to-self=0 apply-to-enemy=1");
			// TF2CustAttr_SetString(Weapon1, "on-hit-addcond", "TFCond=128 duration=5.0 apply-to-self=1 apply-to-enemy=0");
			// TFCond_HalloweenHellHeal
			//TF2Attrib_SetByName(Weapon1, "dmg from melee increased", 0.25);
		}
	}
}



public Action BreadBoom(int attacker, int victim)
{

	float pos1[3];
	float pos22[3];
	GetClientAbsOrigin(attacker, pos1); // hack: make the explosion actually come from the attacker, that way we only have to hook one client
	GetClientAbsOrigin(victim, pos22);

	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", "peejar_impact_milk");
	AcceptEntityInput(particle, "Start");
	TeleportEntity(particle, pos22, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	float pos2[3];
//	float ignitetime = GetConVarFloat(FindConVar("sharpened_volcano_fragment_firetime"));
	
	for(int client = 1 ; client <= MaxClients ; client++ )
	{
		if(IsClientInGame(client))
		{
			GetClientAbsOrigin(client, pos2);
			if(GetVectorDistance(pos1, pos2) <= 350.0 && TF2_GetClientTeam(attacker) != TF2_GetClientTeam(client))
			{
				//SDKHooks_TakeDamage(client, 0, attacker, 1500.0, 0, -1);
				TF2_AddCondition(client, TFCond_Milked, 3.0);
				// ClientCommand(client, "playgamesound weapons/explode1.wav");
				//ClientCommand(client, "playgamesound %s", sound);
				//EmitAmbientSound(sBoomNoise, pos22, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
				
				//return Plugin_Changed;

			}
		}
	}
	return Plugin_Continue;
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
    

    pos[2] += 120.0;
    for (int i = 1; i <= children; i++)
    {
        int child = CreateEntityByName("tf_projectile_jar_milk");
        
        
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