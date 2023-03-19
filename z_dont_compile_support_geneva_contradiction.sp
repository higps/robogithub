#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Geneva Contradiction"
#define ROBOT_ROLE "Support"
#define ROBOT_DESCRIPTION "Syringe Gun AOE Heal"
 
#define GMEDIC             "models/bots/medic/bot_medic.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_demoman/giant_demoman_loop.wav"

#define BERLINER 303
#define PROCESSORMASK 30046
#define COLONELSCOAT 30361
 
public Plugin:myinfo =
{
	name = "[TF2] Be the Geneva Contradiction",
	author = "not made by gps",
	description = "commit war crimes",
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

	// AddNormalSoundHook(BossIcebear);
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
//



   
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
   	
	int iHealth = 1500;
	int MaxHealth = 150;
	int iAdditiveHP = iHealth - MaxHealth;
   
	TF2_SetHealth(client, iHealth);
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.75);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	
	TF2Attrib_SetByName(client, "health regen", 20.0);
	TF2Attrib_SetByName(client, "head scale", 0.75);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	TF2_AddCondition(client, TFCond_RadiusHealOnDamage);
	PrintHintText(client, "%s", ROBOT_DESCRIPTION);
}

// public TF2_OnConditionAdded(client, TFCond:condition)
// {
//     if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
//     {
//        TF2_AddCondition(client,TFCond_HalloweenQuickHeal, 2.5);
// 	   //TF2_RemoveCondition(client, TFCond_Taunting);
// //	   TF2_AddCondition(client,TFCond_Charging, 2.5);

	
// 	  // TF2_AddCondition(client,TFCond_HalloweenSpeedBoost, 15.0);
//     }
// }


 
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
 
stock GiveGiantMedic(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_syringegun_medic", 17, 6, 1, 0, 0);
		//CreateRoboWeapon(client, "tf_wearable_demoshield", 131, 6, 1, 1, 0);
		// CreateRoboWeapon(client, "tf_weapon_bonesaw", 8, 6, 1, 2, 0);

		CreateRoboHat(client, 30109, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, 30098, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, 30149, 10, 6, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		// int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "damage bonus", 1.25);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.5);
			TF2Attrib_SetByName(Weapon1, "clip size bonus upgrade", 2.0);
			TF2Attrib_SetByName(Weapon1, "mad milk syringes", 1.0);
			//TF2Attrib_SetByName(Weapon1, "clip size penalty", 0.5);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
			TF2Attrib_SetByName(Weapon1, "Reload time increased", 1.75);	
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.25);	
			
			
			//TF2Attrib_SetByName(Weapon1, "heal on kill", 200.0);
			//TF2Attrib_SetByName(Weapon1, "add uber charge on hit", 3.0);
			//TF2Attrib_SetByName(Weapon1, "bullets per shot bonus", 3.0);
			//TF2Attrib_SetByName(Weapon1, "projectile spread angle penalty", 0.5);
		}

		// if(IsValidEntity(Weapon3))
		// {
		// 	TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
		// 	TF2Attrib_SetByName(Weapon3, "damage bonus", 1.25);
		// 	TF2Attrib_SetByName(Weapon3, "heal on kill", 200.0);
		// }

		// int iEntity2 = -1;
		// while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_wearable_demoshield")) != -1)
		// {
		// 	if (client == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
		// 	{				
		// 		//PrintToChatAll("going through entity");
		// 		TF2Attrib_SetByName(iEntity2, "major increased jump height", 1.5);		
		// 		TF2Attrib_SetByName(iEntity2, "lose demo charge on damage when charging", 0.0);	
		// 		// TF2Attrib_SetByName(iEntity2, "is_passive_weapon", 1.0);
				
				
		// 		break;
		// 	}
		// }
	}
}
// bool g_SpellClamp = false;
// float g_chargetime = 5.0;

// public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
// {
// 	if (IsRobot(client, ROBOT_NAME) && buttons & (IN_ATTACK3|IN_USE))
// 	{
// 		//0 = fireball
// 		//PrintToChat(client, "Throwing spell!");
// 		if (!g_SpellClamp)
// 		{
// 			CreateTimer(1.0, SpellClamp_Timer);
// 			g_SpellClamp = true;
// 			//g_chargetime = GetEntPropFloat(client, Prop_Send, "m_flChargeLevel");
// 			PrintToChatAll("Charge was %f", g_chargetime);
// 			TF2_AddCondition(client, TFCond_Charging, g_chargetime);
// 			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 750.0);
// 			CreateTimer(0.1, Timer_TargeCharging, GetClientUserId(client), TIMER_REPEAT);
// 		}
		
// 	}
// }

// public Action SpellClamp_Timer(Handle hTimer)
// {
// 	g_SpellClamp = false;
// }

// public Action Timer_TargeCharging(Handle timer, any userid)
// {
// 	new client = GetClientOfUserId(userid);
// 	if (!IsValidClient(client) || !IsPlayerAlive(client) || !TF2_IsPlayerInCondition(client, TFCond_Charging))
// 	{
// 		if (IsValidClient(client)) SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 0);
// 		return Plugin_Stop;
// 	}
// 	float charge = g_chargetime;
// 	if (charge <= 0)
// 	{
// 		SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 0);
// 		return Plugin_Stop;
// 	}
// 	if (GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) == 8) charge -= (0.1 / 2.0 * 100.0);
// 	else charge -= (0.1 / 1.5 * 100.0);
// 	if (charge <= 0) charge = 0.0;
// 	if (charge <= 33) SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 2);	//Full crit
// 	else if (charge <= 75) SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 1);	//Mini-crit
// 	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", charge);
// 	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 750.0);
// 	return Plugin_Continue;
// }

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
if (IsValidClient(victim) && IsRobot(attacker, ROBOT_NAME))
	{
		if (IsSyringeGun(weapon))
		{
			TF2_AddCondition(attacker, TFCond_RadiusHealOnDamage);
			TF2_AddCondition(victim, TFCond_Milked, 15.0);
		}
	}
}

// bool IsBonesaw(int weapon)
// {
// 	if(weapon == -1 && weapon <= MaxClients) return false;
	
// 	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
// 	{
		
// 	case 8: //Bonesaw
// 		{
// 			return true;
// 		}
// 	}
// 	return false;
// }

bool IsSyringeGun(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		
	case 17: //SyringeGun
		{
			return true;
		}
	}
	return false;
}


// public Action:BossIcebear(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
// {
// 	if (!IsValidClient(entity)) return Plugin_Continue;
// 	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

// 	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
// 	{
// 		if (StrContains(sample, "1.wav", false) != -1)
// 		{
// 			Format(sample, sizeof(sample), LEFTFOOT);
// 			EmitSoundToAll(sample, entity);
// 		}
// 		else if (StrContains(sample, "3.wav", false) != -1)
// 		{
// 			Format(sample, sizeof(sample), LEFTFOOT1);
// 			EmitSoundToAll(sample, entity);
// 		}
// 		else if (StrContains(sample, "2.wav", false) != -1)
// 		{
// 			Format(sample, sizeof(sample), RIGHTFOOT);
// 			EmitSoundToAll(sample, entity);
// 		}
// 		else if (StrContains(sample, "4.wav", false) != -1)
// 		{
// 			Format(sample, sizeof(sample), RIGHTFOOT1);
// 			EmitSoundToAll(sample, entity);
// 		}
// 		return Plugin_Changed;
// 	}
// 	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
// }
