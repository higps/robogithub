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

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


public Plugin MyInfo =
{
	name = "[TF2] Artillery Rocket Launcher",
	author = "IvoryPal",
	description = "Rocket launcher that fires volleys of rockets.",
	version = "1.0"
}


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

	//	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	AddNormalSoundHook(BossIcebear);

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;



	// RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	// restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION, null);
	//Artillery Code


	//HookEvent("post_inventory_application", Event_PlayerResupply);

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
	




	// PrecacheSound(GUNFIRE);
	// PrecacheSound(GUNFIRE_CRIT);
	// PrecacheSound(GUNFIRE_EXPLOSION);
	



	
	
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);
	
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
	
	int iHealth = 3800;
		
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
	// TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	
	// TF2Attrib_SetByName(client, "self dmg push force increased", 6.0);
	// TF2Attrib_SetByName(client, "boots falling stomp", 6.0);
	
	//
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	//TF2Attrib_SetByName(client, "head scale", 0.5);
	UpdatePlayerHitbox(client,scale);
	
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
		GiveGiantPyro(client);
}

// #define SergeantsDrillHat 183
// 
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

		CreateRoboWeapon(client, "tf_weapon_rocketlauncher", 1104, 6, 1, 2, 0);
		// CreateRoboWeapon(client, "tf_weapon_shotgun_soldier", 10, 6, 1, 2, 0);
		//CreateRoboWeapon(client, "tf_weapon_shovel", 416, 6, 1, 2, 0);
		
		CreateRoboHat(client, skullcap, 10, 6, 0.0, 0.8, -1.0);
		CreateRoboHat(client, KringleCollection, 10, 6, 0.0, 0.75, -1.0);
		CreateRoboHat(client, GRAYBANNS, 10, 6, 0.0, 0.8, -1.0);


		

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
	//0 = fireball
	//PrintToChat(client, "Throwing spell!");
	if( GetEntProp( client, Prop_Data, "m_afButtonPressed" ) & IN_ATTACK3 ) 
	{
	// PrintToChatAll("Press");
	g_button_held[client] = true;
	}



	if( GetEntProp( client, Prop_Data, "m_afButtonReleased" ) & IN_ATTACK3 ) 
	{
	// PrintToChatAll("Release");
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

		// TF2Attrib_SetByName(Weapon1, "faster reload rate", 0.5);			
		// TF2Attrib_SetByName(Weapon1, "rocket specialist", 1.0);
		TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.35);
		// TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 11.0);
		// TF2Attrib_SetByName(Weapon1, "projectile spread angle penalty", 1.0);
		TF2Attrib_SetByName(Weapon1, "major increased jump height", 0.0);		
	}
}

void ResetWeapon(int client)
{
	g_FireMode = false;
	//PrintCenterText(client, "Exiting Firing mode");
	TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 0.5);
	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	g_skill_time = g_skill + g_skill_cooldown;
	// PrintToChatAll("Gskill time: %f", g_skill_time);
	// PrintToChatAll("Gskill: %f", g_skill);

	int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon1))
	{

		TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.15);
		TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.85);
		TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
		TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
		TF2Attrib_SetByName(Weapon1, "faster reload rate", 1.5);			
		// TF2Attrib_SetByName(Weapon1, "rocket specialist", 1.0);
		TF2Attrib_SetByName(Weapon1, "Projectile speed increased", 0.85);
		TF2Attrib_SetByName(Weapon1, "clip size upgrade atomic", 4.0);
		TF2Attrib_SetByName(Weapon1, "major increased jump height", 1.0);		
		
		TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.25);		

		// TF2Attrib_SetByName(Weapon1, "projectile spread angle penalty", 0.0);
		TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
		
	}
}

// #define CHAR_FULL "■"
// #define CHAR_EMPTY "□"

void DrawHUD(int client)
{
	char sHUDText[128];
	// char sProgress[32];
	// int iPercents = RoundToCeil(g_skill / g_skill_time * 100.0);

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
	// b_hud_clamp[client] = false;
}