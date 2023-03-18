#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Laugh Extractor"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Pyro"
#define ROBOT_SUBCLASS "Flames"
#define ROBOT_DESCRIPTION "Extract the funnies"
#define ROBOT_TIPS "Kill 5 enemies to scare them later"

#define GPYRO		"models/bots/pyro_boss/bot_pyro_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_pyro/giant_pyro_loop.wav"

#define SCREAM	"ambient/halloween/male_scream_10.wav"


public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Agro Pyro",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Agro Pyro from Kritzkast",
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

// new bool:Locked1[MAXPLAYERS+1];
// new bool:Locked2[MAXPLAYERS+1];
// new bool:Locked3[MAXPLAYERS+1];
// new bool:CanWindDown[MAXPLAYERS+1];

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
	// robot.sounds.gunfire = SOUND_GUNFIRE;
	// robot.sounds.windup = SOUND_WINDUP;
	robot.sounds.death = DEATH;

	AddRobot(robot, MakeGiantPyro, PLUGIN_VERSION);

	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantPyro", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
//



	PrecacheSound(SCREAM);
	
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

MakeGiantPyro(client)
{
	SMLogTag(SML_VERBOSE, "Createing Agro");
	TF2_SetPlayerClass(client, TFClass_Pyro);
	//TF2_RespawnPlayer(client);
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
	SetModel(client, GPYRO);
	
	int iHealth = 3000;
		
	int MaxHealth = 175;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 0.65);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 6.0);
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.75);

	
	
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
		GiveGiantPyro(client);
}
#define Grim 949 
#define FireTooth  31144 
#define FlavorfulBaggies  31145 

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{		
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		
		CreateRoboWeapon(client, "tf_weapon_flamethrower", 21, 6, 1, 2, 0);	

		CreateRoboHat(client, Grim, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, FireTooth, 10, 6, 0.0, 0.75, -1.0);
		CreateRoboHat(client, FlavorfulBaggies, 10, 6, 0.0, 0.75, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

		
		if(IsValidEntity(Weapon1))
		{
			//TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.35);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			// TF2Attrib_SetByName(Weapon1, "airblast pushback scale", 1.6);		
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.35);			
			TF2Attrib_SetByName(Weapon1, "flame_spread_degree", 5.0);			
			TF2Attrib_SetByName(Weapon1, "flame size bonus", 1.6);
			TF2Attrib_SetByName(Weapon1, "flame_speed", 3600.0);
			TF2Attrib_SetByName(Weapon1, "mult airblast refire time", 1.5);

			
			
			// TF2Attrib_SetByName(Weapon1, "airblast vertical pushback scale", 1.5);
			
			// charged airblast


		}
	}
}


bool g_button_held[MAXPLAYERS + 1] = false;
float g_Recharge[MAXPLAYERS + 1] = 0.0;
float g_RechargeCooldown = 5.0;
float g_skill;
int g_KillCount = 0;
int g_KillsNeeded = 5;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{

		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE) ) 
		{
			//  PrintToChatAll("Press");
            g_button_held[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE) ) 
		{
			//  PrintToChatAll("Release");
			g_button_held[client] = false;
            
		}
		//0 = Shadow Leap
		//PrintToChat(client, "Throwing spell!");
		// UpdateCharge(client);
		g_skill = GetEngineTime();
		DrawHUD(client);
		
	}
}

// float g_hud_draw_delay = 0.1;
// float g_hud_post_time = 0.0;
bool isready;
void DrawHUD(int client)
{
	char sHUDText[128];
	// char sProgress[32];
	//int iPercents = RoundToCeil(float(g_Recharge[client]) / float(g_RechargeCooldown) * 100.0);
	int iCountDown = g_KillsNeeded- g_KillCount;
	
	// for (int j = 1; j <= 10; j++)
	// {
	// 	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	// 	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	// }

	Format(sHUDText, sizeof(sHUDText), "Laugh Extraction: %i   ", iCountDown);
	

	if(iCountDown <= 0)
	{
		Format(sHUDText, sizeof(sHUDText), "Laugh Extraction Ready!\nReload to use!");
			
		SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);

		
	} else {
		SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);
		
		// PrintToChatAll("Not Ready!");
	}
	// if (g_hud_post_time + g_hud_draw_delay <= GetEngineTime() || g_hud_post_time == 0.0)
	// {
		 ShowHudText(client, -2, sHUDText);
	// 	 g_hud_post_time = GetEngineTime();
	// }

		if (!isready && iCountDown <= 0)
		{
			TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
			// PrintToChatAll("Ready!");
			isready = true;	
		}

	if (g_button_held[client] && iCountDown <= 0)
	{
		ApplyRadialStun(client, 3.0, 500.0);
		g_KillCount = 0;
		// g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
		isready = false;
		
	}
}

void LaughExtract(int client)
{

	// TFTeam iTeam = TF2_GetClientTeam(client);
	
	
}

public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsAnyRobot(victim) && IsRobot(attacker, ROBOT_NAME))
	{
		if(g_KillCount <= g_KillsNeeded)
		{
			g_KillCount++;
		}

		
		

	}
}

public void ApplyRadialStun(int hero, float flDuration, float flRadius)
{
	//positions
	float heroPos[3];
	float playerPos[3];
	int team = GetClientTeam(hero);
	//Get our hero's position
	GetClientAbsOrigin(hero, heroPos);
	int stunflag = TF_STUNFLAGS_GHOSTSCARE;
		
	//loop through players
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			int cteam = GetClientTeam(client);
			if (cteam == team) continue;
			
			GetClientAbsOrigin(client, playerPos);
			if (GetVectorDistance(playerPos, heroPos) <= flRadius)
			{
				
				TF2_StunPlayer(client, flDuration, 0.0, stunflag);
			}
		}
	}
	EmitSoundToAll(SCREAM, hero, SNDCHAN_ITEM, SNDLEVEL_GUNFIRE);
	EmitSoundToAll(SCREAM, hero, SNDCHAN_ITEM, SNDLEVEL_GUNFIRE);
	EmitSoundToAll(SCREAM, hero, SNDCHAN_ITEM, SNDLEVEL_GUNFIRE);
}