#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Hacked Slasher"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Tank"
#define ROBOT_DESCRIPTION "Power-Walk Charge"
#define ROBOT_COST 1.0
#define ROBOT_TIPS "Extremely long but slow charge\nCharge refill on kill\nYou can't contest objectives"
#define ROBOT_ON_DEATH "Knockback can disrupt the charge\nTanks can be stunned by shields and stomps\nTanks take double melee damage"

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
	robot.difficulty = ROBOT_DIFFICULTY_MEDIUM;
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

	RoboSetHealth(client,TFClass_DemoMan, 10000, 1.5);
	
	
	float OverHealRate = 1.5;

	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "damage force reduction", 0.1);
	TF2Attrib_SetByName(client, "move speed penalty", 0.7);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "charge impact damage increased", 1.5);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.85);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.1);
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);
	//Tank stats
    TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
	
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
			TF2Attrib_SetByName(Weapon3, "charge time increased", 15.0);		
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.4);				
			TF2Attrib_SetByName(Weapon3, "charge impact damage increased", 5.0);	
			TF2Attrib_SetByName(Weapon3, "no charge impact range", 100.0);	
			TF2Attrib_SetByName(Weapon3, "mult charge turn control", 5.0);		
			TF2Attrib_SetByName(Weapon3, "kill refills meter", 1.0);		
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.8);	
			TF2Attrib_SetByName(Weapon3, "dmg taken increased", 1.0);
			TF2CustAttr_SetString(Weapon3, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			TF2CustAttr_SetString(Weapon3, "shake on hit", "amplitude=20.0 frequency=5.0 duration=1.0");	
		}
				CreateRoboHat(client, 111, 10, 6, 0.0, 1.0, 1.0); 
		TF2Attrib_SetByName(client, "attach particle effect", 35.0);
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
		if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Charging)
		{	
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 350.0);
			
		}
	
}
public void TF2_OnConditionRemoved(int client, TFCond condition)
{
		if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Charging)
		{	
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		}
	
}