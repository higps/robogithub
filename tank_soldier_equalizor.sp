#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
//#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Equalizor"
#define ROBOT_ROLE "Tank"
#define ROBOT_DESCRIPTION "Equalizor"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
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
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

    LoadTranslations("common.phrases");

    //	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
    AddNormalSoundHook(BossIcebear);

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Soldier";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION, null, 2);

	HookEvent("player_death", Event_Death, EventHookMode_Post);
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
	PrecacheModel(GSOLDIER);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);

	// PrecacheSound(GUNFIRE);
	// PrecacheSound(GUNFIRE_CRIT);
	// PrecacheSound(GUNFIRE_EXPLOSION);
	

	PrecacheSound(LEFTFOOT);
	PrecacheSound(LEFTFOOT1);
	PrecacheSound(RIGHTFOOT);
	PrecacheSound(RIGHTFOOT1);
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);

	
	
}


public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
// 	int target = attacker;
// //	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

// TFTeam buffTeam = TF2_GetClientTeam(owner);
	
// // disallow enemies, allow disguised players, disallow cloaked
// if (TF2_GetClientTeamFromClient(target, owner) != buffTeam
// {
// 	return;
// }

// 	if (IsRobot(attacker, ROBOT_NAME))
// 	{
// 		//PrintToChatAll("applying slowed");
// 		//TF2_AddCondition(target, TFCond_MarkedForDeath, BUFF_PULSE_CONDITION_DURATION, owner);
// 		TF2_AddCondition(attacker, TFCond_DefenseBuffNoCritBlock, 10.0, attacker);
// 	}
	
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

public Action:BossIcebear(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}

	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
}

MakeGiantSoldier(client)
{
	//aSMLOGTag(SML_VERBOSE, "Createing Soldier");
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
	
	int iHealth = 5800;
		
	int MaxHealth = 200;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	float OverHealRate = 1.5;

	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;

	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;

	float scale = 1.65;
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.7);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(client, "increased air control", 2.0);
	
	//TF2Attrib_SetByName(client, "cancel falling damage", 1.0);

	//TF2Attrib_SetByName(client, "blast_dmg_to_self", 0.1);
	TF2Attrib_SetByName(client, "increase buff duration", 10.0);
	TF2Attrib_SetByName(client, "self dmg push force increased", 4.0);
	TF2Attrib_SetByName(client, "boots falling stomp", 6.0);
	
	//
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.75);
	UpdatePlayerHitbox(client,scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , "Kill All Humans");
	
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

#define LordCockswain 439
#define Pipe 440
// 

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

	//	CreateRoboWeapon(client, "tf_weapon_rocketlauncher", 18, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_buff_item", 226, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_shovel", 775, 6, 1, 2, 0);
		
		CreateRoboHat(client, LordCockswain, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, Pipe, 10, 6, 0.0, 1.0, -1.0);


	//	int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		// if(IsValidEntity(Weapon1))
		// {

		// 	TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.00);
		// 	TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
		// 	TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
		// 	TF2Attrib_SetByName(Weapon1, "faster reload rate", 1.75);				
		// 	TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
		// }
		if(IsValidEntity(Weapon2))
		{						
			TF2CustAttr_SetString(Weapon2, "custom buff type", "mvm-banner");
		}

		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);


			// TF2Attrib_SetByName(Weapon3, "mod shovel damage boost", 0.0);

			//TF2Attrib_SetByDefIndex(Weapon3, 115, 2.0);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.5);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.25);
			TF2Attrib_SetByName(Weapon3, "dmg bonus while half dead", 1.5);
			
			// TF2Attrib_SetByName(Weapon3, "mod shovel speed boost", 2.0);
			
			TF2Attrib_SetByName(Weapon3, "self mark for death", 0.0);
			TF2Attrib_SetByName(Weapon3, "mod weapon blocks healing", 1.0);

			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);							
		}


		CreateRoboHat(client, 1101, 10, 6, 0.0, 5.0, -1.0); //parachute

		int iEntity2 = -1;
		while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_weapon_parachute")) != -1)
		{
			if (client == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
			{				
				//PrintToChatAll("going through entity");
				TF2Attrib_SetByName(iEntity2, "major increased jump height", 1.75);		
				
				break;
			}
		}
		

	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));
	
