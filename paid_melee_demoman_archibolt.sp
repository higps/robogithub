#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Archibolt"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Shadowleap Spell"
#define ROBOT_TIPS "Use shadow leap to get close to enemies"
#define ROBOT_COST 1.0
#define ROBOT_ON_DEATH "Airblast counters this robot"
#define GDEKNIGHT		"models/bots/demo_boss/bot_demo_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"

#define ENEMY_HIT   "archibald.wav"

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
	robot.difficulty = ROBOT_DIFFICULTY_HARD;

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeDemoKnight, PLUGIN_VERSION, restrictions);
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
	PrecacheSound(ENEMY_HIT);
	
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

	RoboSetHealth(client, TFClass_, 3500, 1.5);
	
	
	float OverHealRate = 1.5;

	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "charge impact damage increased", 1.5);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);


	UpdatePlayerHitbox(client, 1.75);

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
	GiveGiantDemoKnight(client);
}

#define Dictator 30306
#define GrayBans 30104
#define BankRoll 31342

	
stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_sword", 327, 6, 1, 2, 0);

		CreateRoboHat(client, Dictator, 10, 6, 1315860.0, 2.0, 1.0); 
		CreateRoboHat(client, GrayBans, 10, 6, 0.0, 0.85, 2.0); 
		CreateRoboHat(client, BankRoll, 10, 6, 0.0, 1.0, 1.0); 

		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);						
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.4);			
			TF2Attrib_SetByName(Weapon3, "speed_boost_on_hit", 10.0);		
			TF2Attrib_SetByName(Weapon3, "dmg taken increased", 1.0);		
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.25);	
			TF2Attrib_SetByName(Weapon3, "single wep deploy time decreased", 0.01);
			TF2CustAttr_SetString(client, "Spell-Caster", "Spell=6 Cooldown=2.0");
		}
	}


}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
	//PrintToChatAll("CONDITION WAS: %i for %N", condition, client);
		if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Charging)
		{	
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 750.0);

		}
	
}

public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsRobot(attacker, ROBOT_NAME))
	{
	StopSound(attacker, SNDCHAN_AUTO, ENEMY_HIT);
	StopSound(attacker, SNDCHAN_AUTO, ENEMY_HIT);
	StopSound(attacker, SNDCHAN_AUTO, ENEMY_HIT);
	StopSound(attacker, SNDCHAN_AUTO, ENEMY_HIT);
	EmitSoundToAll(ENEMY_HIT, attacker, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	EmitSoundToAll(ENEMY_HIT, attacker, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	EmitSoundToAll(ENEMY_HIT, attacker, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	EmitSoundToAll(ENEMY_HIT, attacker, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	}
}