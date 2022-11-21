#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Hacked Slasher"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Power-Walk Charge"
#define ROBOT_COST 1.0
#define ROBOT_TIPS "Very Long & Slow Charge\nHeal + Charge refill on kill\n3 second speed boost on hit"

#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/mvm_tank_horn.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/mvm_tank_loop.wav"

#define LEFTFOOT        ")mvm/giant_demoman/giant_demoman_step_01.wav"
#define LEFTFOOT1       ")mvm/giant_demoman/giant_demoman_step_03.wav"
#define RIGHTFOOT       ")mvm/giant_demoman/giant_demoman_step_02.wav"
#define RIGHTFOOT1      ")mvm/giant_demoman/giant_demoman_step_04.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Demoknight",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Demoknight from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	AddNormalSoundHook(BossMortar);

	// HookEvent("player_death", Event_Death, EventHookMode_Post);

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;
	
	AddRobot(robot, MakeDemoKnight, PLUGIN_VERSION, restrictions);
}

public Action:BossMortar(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			EmitSoundToAll(LEFTFOOT, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			EmitSoundToAll(LEFTFOOT1, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			EmitSoundToAll(RIGHTFOOT, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			EmitSoundToAll(RIGHTFOOT1, entity);
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
	//	CreateNative("BeGiantDemoKnight_MakeDemoKnight", Native_SetGiantDemoKnight);
	//	CreateNative("BeGiantDemoKnight_IsGiantDemoKnight", Native_IsGiantDemoKnight);
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheModel(GDEKNIGHT);
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

MakeDemoKnight(client)
{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GDEKNIGHT);

	int iHealth = 7000;
	
	
	int MaxHealth = 175;
	float OverHealRate = 1.5;
//	PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
//	 PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;

	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "damage force reduction", 0.1);
	TF2Attrib_SetByName(client, "move speed penalty", 0.7);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	//TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
	TF2Attrib_SetByName(client, "charge impact damage increased", 1.5);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.85);

	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);
	SetTankStats(client);
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
	GiveGiantDemoKnight(client);
}

#define NightbaneBrim 31308
#define Goalkeeper 31217
#define ToothKicker 734

stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_wearable_demoshield", 1099, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_sword", 327, 6, 1, 2, 0);
		
		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		float TeamPaint = 0.0;
		
		if (iTeam == TFTeam_Red){
			TeamPaint = 3874595.0;
			
		}
		if (iTeam == TFTeam_Blue){
			
			TeamPaint = 1581885.0;
		}

		CreateRoboHat(client, NightbaneBrim, 10, 6, 0.0, 0.9, -1.0); 
		CreateRoboHat(client, Goalkeeper, 10, 6, TeamPaint, 0.85, 1.0); 
		CreateRoboHat(client, ToothKicker, 10, 6, TeamPaint, 1.0, -1.0); 

		
		int iEntity2 = -1;
		while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_wearable_demoshield")) != -1)
		{
			if (client == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
			{				
				//PrintToChatAll("going through entity");
				TF2Attrib_SetByName(iEntity2, "major increased jump height", 1.0);		
				TF2Attrib_SetByName(iEntity2, "lose demo charge on damage when charging", 0.1);			
				TF2Attrib_SetByName(iEntity2, "dmg taken from fire reduced", 1.0);			
				TF2Attrib_SetByName(iEntity2, "dmg taken from blast reduced", 1.0);			
						
				

				break;
			}
		}
		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			//TF2Attrib_RemoveAll(Weapon3);
			
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);				
			//TF2Attrib_SetByName(Weapon3, "charge meter on hit", 0.25);		
			TF2Attrib_SetByName(Weapon3, "charge time increased", 15.0);		
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.4);			
			// TF2Attrib_SetByName(Weapon3, "fire rate bonus", 0.75);			
			TF2Attrib_SetByName(Weapon3, "charge impact damage increased", 5.0);	
			TF2Attrib_SetByName(Weapon3, "no charge impact range", 100.0);	
			
			// TF2Attrib_SetByName(Weapon3, "minicrits become crits", 1.0);		
			TF2Attrib_SetByName(Weapon3, "mult charge turn control", 5.0);		
			TF2Attrib_SetByName(Weapon3, "kill refills meter", 1.0);		
			// TF2Attrib_SetByName(Weapon3, "heal on kill", 400.0);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.75);	
			// TF2Attrib_SetByName(Weapon3, "speed_boost_on_hit", 3.0);
			TF2Attrib_SetByName(Weapon3, "dmg taken increased", 1.0);
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
	//PrintToChatAll("CONDITION WAS: %i for %N", condition, client);
		if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Charging)
		{	
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 350.0);
			// TF2_AddCondition(client, TFCond_CritCanteen, 3.0);
		}
	
}

// public Event_Death(Event event, const char[] name, bool dontBroadcast)
// {
// 	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
// 	//int victim = GetClientOfUserId(GetEventInt(event, "userid"));

// 	if(IsRobot(attacker, ROBOT_NAME))
// 	{

// 			//PrintToChatAll("HP WAS %i , MAXHP was %i", HP, MAXHP);

// 			RequestFrame(SetHP, attacker);

// 			// SetEntProp(attacker, Prop_Send, "m_iHealth", HP, 1);
// 			// SetEntProp(attacker, Prop_Data, "m_iHealth", HP, 1);


// 	}
// }

// void SetHP(int attacker)
// {
// 			// int HP = GetEntProp(attacker, Prop_Send, "m_iHealth");
// 			// int MAXHP = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
// 			// SetEntProp(attacker, Prop_Send, "m_iMaxHealth", MAXHP+115, 1);
// 			// SetEntProp(attacker, Prop_Data, "m_iMaxHealth", MAXHP+115, 1);
// }