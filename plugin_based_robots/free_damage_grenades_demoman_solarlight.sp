#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Solarlight"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Demoman"
#define ROBOT_SUBCLASS "Grenades"
#define ROBOT_DESCRIPTION "Hybrid Knight"
#define ROBOT_TIPS "Be demoknight TF2"
#define ROBOT_ON_DEATH "Short Circuit and Airblast are good ways to deal with this robot"

#define GDEKNIGHT		"models/bots/demo/bot_demo.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_demoman/giant_demoman_loop.wav"

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Solar Demoknight",
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
	robot.difficulty = ROBOT_DIFFICULTY_HARD;
	AddRobot(robot, MakeSolar, PLUGIN_VERSION);

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
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

MakeSolar(client)
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

	RoboSetHealth(client,TFClass_DemoMan, 2000, 1.5);
	
	float OverHealRate = 1.5;

	

	

	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "move speed penalty", 0.75);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "charge impact damage increased", 1.5);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "self dmg push force increased", 2.0);
	TF2Attrib_SetByName(client, "charge time increased", 4.0);		
	TF2Attrib_SetByName(client, "head scale", 0.75);		
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);

}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveGiantDemoKnight(client);
}

#define TartanTyrolean 30334
#define DeadOfNight 30309
#define JuggernautJacket 30363

stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_grenadelauncher", 1151, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_wearable_demoshield", 1099, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_sword", 327, 6, 1, 2, 0);

		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));

		float TeamPaint = 0.0;

		if (iTeam == TFTeam_Blue){
			TeamPaint = 5801378.0;
		}
		if (iTeam == TFTeam_Red){
			TeamPaint = 12073019.0;
		}

		CreateRoboHat(client, TartanTyrolean, 10, 6, 0.0, 1.0, 1.0); 
		CreateRoboHat(client, DeadOfNight, 10, 6, TeamPaint, 1.0, -1.0); 
		CreateRoboHat(client, JuggernautJacket, 10, 6, 15132390.0, 1.0, -1.0); 

		
		int iEntity2 = -1;
		while ((iEntity2 = FindEntityByClassname(iEntity2, "tf_wearable_demoshield")) != -1)
		{
			if (client == GetEntPropEnt(iEntity2, Prop_Data, "m_hOwnerEntity"))
			{				
				// PrintToChatAll("Found demo shield");
				TF2Attrib_SetByName(iEntity2, "major increased jump height", 1.5);		
				TF2Attrib_SetByName(iEntity2, "lose demo charge on damage when charging", 0.0);		
				
				break;
			}
		}
		

		

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			// TF2Attrib_SetByName(Weapon1, "damage penalty", 0.8);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.85);
			TF2Attrib_SetByName(Weapon1, "clip size bonus", 1.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "is_festivized", 1.0);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 1.75);
			TF2Attrib_SetByName(Weapon1, "hidden primary max ammo bonus", 3.0);
			
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.6);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
			

		}
		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon3, "is_festivized", 1.0);		
			TF2Attrib_SetByName(Weapon3, "charge time increased", 5.0);	
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs players", 1.25);		
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.8);			
			
			
			
			
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
		if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Charging)
		{	
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 550.0);

		}
	
}
