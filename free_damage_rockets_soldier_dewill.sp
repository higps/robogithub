#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Dewill"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Soldier"
#define ROBOT_SUBCLASS "Rockets"
#define ROBOT_DESCRIPTION "Ground Striker"
#define ROBOT_COST 2.5
#define ROBOT_TIPS "Rapid Airstrike\nPress Special Attack to enter stationary rapid fire mode\nReduced damage to buildings"
#define ROBOT_ON_DEATH "Dewill can't move while in rapid fire mode, leaving him open for damage"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"


#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


public Plugin:myinfo = 
{
	name = "[TF2] Be the DEWILL",
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
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

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
	robot.difficulty = ROBOT_DIFFICULTY_EASY;


	AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION, null);

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

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

MakeGiantSoldier(client)
{
	SMLogTag(SML_VERBOSE, "Createing Soldier");
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
	RoboSetHealth(client,TFClass_Soldier, 3800, 1.5);
	
	float OverHealRate = 1.5;



	float scale = 1.65;
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "self dmg push force increased", 2.0);

	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	UpdatePlayerHitbox(client,scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , ROBOT_TIPS);
	
}


public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

// #define SergeantsDrillHat 183

#define skullcap 30578
#define KringleCollection 650
#define GRAYBANNS 30104

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_rocketlauncher_airstrike", 1104, 6, 1, 2, 0);

		CreateRoboHat(client, skullcap, 10, 6, 0.0, 0.0, 0.75, -1.0);
		CreateRoboHat(client, KringleCollection, 10, 6, 0.0, 0.0, 0.75, -1.0);
		CreateRoboHat(client, GRAYBANNS, 10, 6, 0.0, 0.0, 0.75, -1.0);

		ResetWeapon(client);
				

	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));
	

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_duration = 6.0;
float FireModeTimer = -1.0;
// float g_currenttime;
bool g_FireMode = false;
float g_skill; 
float g_skill_cooldown = 12.0;
float g_skill_time;
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
	if( GetEntProp( client, Prop_Data, "m_afButtonPressed" ) & IN_ATTACK3 ) 
	{
	g_button_held[client] = true;
	}



	if( GetEntProp( client, Prop_Data, "m_afButtonReleased" ) & IN_ATTACK3 ) 
	{
	g_button_held[client] = false;

	}




	g_skill = GetEngineTime();

	DrawHUD(client);

	}
	return Plugin_Continue;
}

void EnterRapidFireMode(int client)
{

	g_skill_time = g_duration;
	PrintCenterText(client, "Entering Firing mode");
	g_FireMode = true;
	FireModeTimer = GetEngineTime() + g_duration;

	TF2_AddCondition(client, TFCond_RuneHaste, g_duration);

	TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 0.01);

	int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon1))
	{
		TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.35);
		TF2Attrib_SetByName(Weapon1, "major increased jump height", 0.0);		
	}
}

void ResetWeapon(int client)
{
	g_FireMode = false;
	TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 0.5);
	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	g_skill_time = g_skill + g_skill_cooldown;


	int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon1))
	{

		TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.15);
		TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.85);
		TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
		TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
		TF2Attrib_SetByName(Weapon1, "faster reload rate", 1.5);			

		TF2Attrib_SetByName(Weapon1, "Projectile speed increased", 0.85);
		TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 4.0);
		TF2Attrib_SetByName(Weapon1, "major increased jump height", 1.0);		
		
		TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.35);		

		TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
		
	}
}


void DrawHUD(int client)
{
	char sHUDText[128];

	int iCountDown = RoundToCeil(g_skill_time - g_skill);
	int iCountDownFiring = RoundToCeil(FireModeTimer - g_skill);

	Format(sHUDText, sizeof(sHUDText), "Rapid Fire: %i   ",iCountDown);

	if(iCountDown <= 0)
	{

	if (g_FireMode){
	Format(sHUDText, sizeof(sHUDText), "Rapid Fire! %i", iCountDownFiring);
	SetHudTextParams(0.85, 0.6, 0.1, 255, 69, 0, 255);
	}else{
	Format(sHUDText, sizeof(sHUDText), "Rapid Fire Ready!\nUse Special Attack to Activate!");
	SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);	
	}



	}else {

	SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 0, 255);
	}

	if (g_button_held[client] && iCountDown <= 0 && !g_FireMode)
	{
	if (FireModeTimer <= GetEngineTime() || FireModeTimer == -1.0)
	{
	EnterRapidFireMode(client);
	}
	}

	if (FireModeTimer <= GetEngineTime() && g_FireMode)
	{
	ResetWeapon(client);
	}


	ShowHudText(client, -3, sHUDText);

}
