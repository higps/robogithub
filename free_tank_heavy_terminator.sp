#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>
#include <stocksoup/tf/entity_prefabs>
#include <stocksoup/tf/teams>
#include <tf_ontakedamage>
#include <tf2_isPlayerInSpawn>
#include <tf2utils>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Terminator"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Terminate specific target for buffs"
#define ROBOT_COST 2.0
#define ROBOT_TIPS "HiNet: Terminate your target"
#define ROBOT_ON_DEATH "Terminator has 90% resistance to bullets and 50% to explosives."
 
#define GRageH      "models/bots/heavy/bot_heavy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

	
#define SOUND_GUNFIRE	")mvm/giant_heavy/giant_heavy_gunfire.wav"
#define SOUND_GUNSPIN	")mvm/giant_heavy/giant_heavy_gunspin.wav"
#define SOUND_WINDUP	")mvm/giant_heavy/giant_heavy_gunwindup.wav"
#define SOUND_WINDDOWN	")mvm/giant_heavy/giant_heavy_gunwinddown.wav"

#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

#define TARGET_SEARCH "ui/quest_decode.wav"
#define TARGET_LOST "ui/cyoa_node_absent.wav"
#define TARGET_FOUND "ui/cyoa_objective_panel_expand.wav"
#define TARGET_TERMINATED "ui/cyoa_map_open.wav.wav"

float scale = 1.15;

enum
{
target_in_spawn,
target_no_valid_target,
target_lost,
target_valid,
target_terminated,
}
public OnMapStart()
{
	PrecacheSound(TARGET_SEARCH);
	PrecacheSound(TARGET_LOST);
	PrecacheSound(TARGET_FOUND);
	PrecacheSound(TARGET_TERMINATED);
}
float g_flTagEndTime[MAXPLAYERS + 1];
int g_iGlowEnt[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };
float flDuration = 5.0;

public Plugin:myinfo =
{
	name = "[TF2] Be the Terminator",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Rage Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

// new bool:Locked1[MAXPLAYERS+1];
// new bool:Locked2[MAXPLAYERS+1];
// new bool:Locked3[MAXPLAYERS+1];
// new bool:CanWindDown[MAXPLAYERS+1];
 
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
	robot.sounds.gunfire = SOUND_GUNFIRE;
	robot.sounds.gunspin = SOUND_GUNSPIN;
	robot.sounds.windup = SOUND_WINDUP;
	robot.sounds.winddown = SOUND_WINDDOWN;
	robot.weaponsound = ROBOT_WEAPON_SOUND_MINIGUN;
	robot.deathtip = ROBOT_ON_DEATH;

	// RestrictionsDefinition restrictions = new RestrictionsDefinition();
	// restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	// restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeGRageH, PLUGIN_VERSION, null);

	    HookEvent("player_death", Event_Death, EventHookMode_Post);

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);

		for (int i; i < sizeof(g_iGlowEnt); i++) {
		if (IsValidEntity(g_iGlowEnt[i])) {
			RemoveEntity(g_iGlowEnt[i]);
		}
	}
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGRageH_MakeGRageH", Native_SetGRageH);
//	CreateNative("BeGRageH_IsGRageH", Native_IsGRageH);
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
int iHealth = 3000;
MakeGRageH(client)
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
	SetModel(client, GRageH);
	
	
	
	int MaxHealth = 300;
	// PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	 // PrintToChatAll("iHealth %i", iHealth);
	
	 // PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.2);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	// TF2Attrib_SetByName(client, "head scale", 0.75);

	TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.25);
	TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.25);
	TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.5);
	


	UpdatePlayerHitbox(client, scale);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	TF2Attrib_SetByName(client, "attach particle effect", 35.0);
	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
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
		GiveGRageH(client);
}

int validPlayers[MAXPLAYERS + 1];
int g_target = -1;
int g_previous_target = -2;
bool g_isTerminator = false;
float gametime = -1.0;
public FindTerminator()
{
	
		for (int i = 1; i <= MaxClients; i++) {
			if(IsRobot(i, ROBOT_NAME))
			{
				// PrintToChatAll("Terminator was %N", i);
				g_isTerminator = true;
				return i;
			}
		}
		g_isTerminator = false;
}

void FindTerminationTarget(){

		int client = FindTerminator();
		//Finding the terminator robot


		//Only do this check if there is a terminator
	if (g_isTerminator)
		{
			//Find the Terminator target
		TFTeam clientTeam = TF2_GetClientTeam(client);
		int numValidPlayers = 0;
		for (int i = 1; i <= MaxClients; i++) {

			if(IsValidClient(i) && IsClientInGame(i) && IsPlayerAlive(i))
			{
				TFTeam iTeam = TF2_GetClientTeam(i);
				if (clientTeam != iTeam && iTeam != TFTeam_Spectator && iTeam != TFTeam_Unassigned && i != g_previous_target)
				{
				validPlayers[numValidPlayers] = i;
				numValidPlayers++;
				}
			}
		}



		if (numValidPlayers > 0) 
		{
			int randomIndex = GetRandomInt(0, numValidPlayers - 1);
			int randomPlayer = validPlayers[randomIndex];



			if (IsValidEntity(g_iGlowEnt[client])) {
			RemoveEntity(g_iGlowEnt[client]);
		}

			g_iGlowEnt[client] = EntIndexToEntRef(TF2_AttachBasicGlow(randomPlayer));
			g_target = randomPlayer;
			SDKHook(g_iGlowEnt[client], SDKHook_SetTransmit, OnGlowShouldTransmit);
			g_flTagEndTime[client] = GetGameTime() + flDuration;
			gametime = -1.0;
		}

		//All players are dead	
		if (numValidPlayers == 0){
			g_target = -1;
		}
	}

	//Remove Outline if no terminator
	if(!g_isTerminator)
	{
		PrintToChatAll("No terminator, removing glow");
			if (IsValidEntity(g_iGlowEnt[g_target]))
			{
			RemoveEntity(g_iGlowEnt[g_target]);
			g_target = -1;
			}
	}
}


public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int assister = GetClientOfUserId(GetEventInt(event, "assister"));

	if(victim == g_target)
	{
		if(IsRobot(attacker, ROBOT_NAME))
		{
			PrintToChatAll("Target killed correctly");
			TF2_SetHealth(attacker, iHealth);
			TF2_AddCondition(attacker, TFCond_UberchargedCanteen, 1.0);
			SetGameTime();

		}else if(IsRobot(assister, ROBOT_NAME))
		{PrintToChatAll("Target killed assist correctly");
			TF2_SetHealth(assister, iHealth);
			TF2_AddCondition(assister, TFCond_UberchargedCanteen, 1.0);
			SetGameTime();

		}else
		{
			PrintToChatAll("You failed to kill your target");
			SetGameTime();

			int Terminator = FindTerminator();
			TF2_StunPlayer(Terminator, 3.0, 0.0, TF_STUNFLAGS_BIGBONK, Terminator);
		}
	}
	FindTerminator();
}
#define HeavyMetal 31369
#define Nuke 30885
#define GRAYBANNS 30104

stock GiveGRageH(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_shotgun_hwg", 199, 6, 1, 0, 304);
		
		// CreateRoboHat(client, Hat1, 10, 6, 0.75, 1.0, -1.0); 
		CreateRoboHat(client, HeavyMetal, 10, 6, 0.0, 0.75, -1.0); 
		CreateRoboHat(client, Nuke, 10, 6, 1315860.0, 0.75, -1.0); 
		CreateRoboHat(client, GRAYBANNS, 10, 6, 1315860.0, 1.0, 0.0);//gray banns

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon2))
		{

			TF2Attrib_SetByName(Weapon2, "attack projectiles", 2.0);
			TF2Attrib_SetByName(Weapon2, "maxammo primary increased", 2.5);	
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs buildings", 0.10);
		}
		
		PrintHintText(client, ROBOT_TIPS);
		// RequestFrame(FindTerminationTarget, client);
	}
}

Action OnGlowShouldTransmit(int glow, int client) {
	int glowTarget = GetEntPropEnt(glow, Prop_Data, "m_hParent");
	if (!g_isTerminator) return Plugin_Stop;

	if (!IsValidEntity(glowTarget)) {
		return Plugin_Stop;
	}
	
	// if (TF2_IsPlayerInCondition(glowTarget, TFCond_Cloaked)
	// 		|| TF2_IsPlayerInCondition(glowTarget, TFCond_Disguised)) {
	// 	return Plugin_Stop;
	// }
	
	if (!TF2_IsEnemyTeam(TF2_GetClientTeam(glowTarget), TF2_GetClientTeam(client))) {
		// prevent showing outline on teammates
		// TODO make this more robust for teamcounts larger than 2 --
		// we'd need to track the attacker
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

float g_search = 2.2;
float g_skill;
int g_loadingDots = 1;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		DrawHUD(client);	
		int aimtarget = GetClientAimTarget(client);
		if (IsValidClient(aimtarget) && aimtarget == g_target)
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.33);
		}
	}
}
int g_targetstatus;
public void OnClientDisconnect(int client)
{
	if(g_target == client)
	{
		g_targetstatus = target_lost;
		FindTerminationTarget();
	}
}


void SetGameTime()
{
	if (gametime < 0.0){
		gametime = GetEngineTime() + g_search;
		
	} 
}
float g_dottime = 0.0;
float g_dot_interval = 0.25;
float g_sound_alert_clamp = 0.0;
bool g_found_target_clamp = false;

void DrawHUD(int client)
{
	char sHUDText[128];

	//	if(IsValidClient(g_target))if(!IsPlayerAlive(g_target))PrintToChatAll("Target alive %i",IsPlayerAlive(g_target));



	
	if(IsValidClient(g_target) && !IsPlayerAlive(g_target))
	{
		// PrintToChatAll("Target Terminated!");
		g_targetstatus = target_terminated;
		SetGameTime();

	}else if(IsValidClient(g_target) && TF2Spawn_IsClientInSpawn(g_target))
	{
		g_targetstatus = target_in_spawn;
		SetGameTime();

	}else if (!IsValidClient(g_target) || TF2_IsPlayerInCondition(g_target, TFCond_Cloaked) || !IsClientInGame(g_target))
	{
		g_targetstatus = target_lost;
		SetGameTime();

	}else if (IsValidClient(g_target) && IsPlayerAlive(g_target) && !TF2Spawn_IsClientInSpawn(g_target))
	{
		g_targetstatus = target_valid;
		SetGameTime();
	}


	switch(g_targetstatus)
	{
		case target_terminated:
		{
			Format(sHUDText, sizeof(sHUDText), "Target terminated\nAquiring new target%s", GenerateDots());
			g_found_target_clamp = false;
		}
		case target_in_spawn:
		{
			Format(sHUDText, sizeof(sHUDText), "Target in spawn\nLocating new target%s",GenerateDots());
			g_found_target_clamp = false;
		}
		case target_no_valid_target:
		{
			Format(sHUDText, sizeof(sHUDText), "No target found\nSearching%s",GenerateDots());
			g_found_target_clamp = false;
		}
		case target_lost:
		{
			Format(sHUDText, sizeof(sHUDText), "Target lost\nFinding new target%s",GenerateDots());
			g_found_target_clamp = false;
		}
		case target_valid:
		{
			Format(sHUDText, sizeof(sHUDText), "Action:Terminate\nID: %N\nLife:%i\nClass:%s\nThreat level: %s", g_target, GetClientHealth(g_target), ClassString(g_target),AssessThreatLevel(g_target));
			
		}

	}
	EmitHudSound(client);

	if(GetEngineTime() > g_dottime)
	{
		g_dottime = GetEngineTime() + g_dot_interval;
		g_loadingDots++;
	}
	
	if(g_loadingDots >= 4)
	{
		g_loadingDots = 1;
	}

	SetHudTextParams(0.35, 0.40, 0.5, 255, 0, 0, 255);
	ShowHudText(client, -2, sHUDText);

	if(g_targetstatus != target_valid && GetEngineTime() > gametime)
	{
		// PrintToChatAll("Finding new termination target");
		if(GetEngineTime() > gametime + g_search)FindTerminationTarget();
	}
			
	// 	 g_hud_post_time = GetEngineTime();
}
int g_previous_state = -2;

// PrintToChatAll("Loadingdots %i",g_loadingDots);
// #define TARGET_SEARCH "ui/cyoa_objective_panel_collapse.wav"
// #define TARGET_LOST "ui/cyoa_node_absent.wav"
// #define TARGET_FOUND "ui/cyoa_objective_panel_expand.wav"
// #define TARGET_TERMINATED "ui/cyoa_map_open.wav.wav"
bool b_clamp_sound = false;
float g_soundclamp = 0.0;
void EmitHudSound(int client)
{

	if (g_previous_state != g_targetstatus)
	{
		switch(g_targetstatus)
		{
			// case target_terminated:
			// {
			// 	EmitSoundToClient(client, TARGET_TERMINATED);
			// 	EmitSoundToClient(client, TARGET_TERMINATED);
			// 	EmitSoundToClient(client, TARGET_TERMINATED);
			// }
			// case target_in_spawn:
			// {
			// 	EmitSoundToClient(client, TARGET_SEARCH);
			// 	EmitSoundToClient(client, TARGET_SEARCH);
			// 	EmitSoundToClient(client, TARGET_SEARCH);
			// }
			// case target_no_valid_target:
			// {		
			// 	EmitSoundToClient(client, TARGET_SEARCH);
			// 	EmitSoundToClient(client, TARGET_SEARCH);
			// 	EmitSoundToClient(client, TARGET_SEARCH);
			// }
			case target_valid:
			{
				EmitSoundToClient(client, TARGET_FOUND);
				EmitSoundToClient(client, TARGET_FOUND);
				EmitSoundToClient(client, TARGET_FOUND);
			}
			default:
			{
				StopSound(client, SNDCHAN_AUTO, TARGET_FOUND);

				EmitSoundToClient(client, TARGET_SEARCH);
				EmitSoundToClient(client, TARGET_SEARCH);
				EmitSoundToClient(client, TARGET_SEARCH);
			}

		}
	}
	
	g_previous_state = g_targetstatus;
}

public char ClassString(int client)
{
	char AString[10] = "";

	if(IsValidClient(client))
	{
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:
			{
				Format(AString, sizeof(AString), "%s", "Scout");

			}

			case TFClass_Soldier:
			{
				Format(AString, sizeof(AString), "%s", "Soldier");

			}

			case TFClass_Pyro:
			{
				Format(AString, sizeof(AString), "%s", "Pyro");

			}

			case TFClass_DemoMan:
			{
				Format(AString, sizeof(AString), "%s", "Demoman");

			}

			case TFClass_Heavy:
			{
				Format(AString, sizeof(AString), "%s", "Heavy");

			}

			case TFClass_Engineer:
			{
				Format(AString, sizeof(AString), "%s", "Engineer");

			}

			case TFClass_Medic:
			{
				Format(AString, sizeof(AString), "%s", "Medic");

			}

			case TFClass_Sniper:
			{
				Format(AString, sizeof(AString), "%s", "Sniper");

			}

			case TFClass_Spy:
			{
				Format(AString, sizeof(AString), "%s", "Spy");

			}

		}
	}
	return AString;
}
public char GenerateDots()
{
	char AString[256] = "";
    for (int i = 0; i < g_loadingDots; i++)
    {
        Format(AString, sizeof(AString), "%s.", AString);
    }
    return AString;
}

public char AssessThreatLevel(int client)
{
	char AString[256] = "";

	if(IsValidClient(client))
	{
		int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(iActiveWeapon))
		{
			int WeaponCode = TF2Util_GetWeaponID(iActiveWeapon);

			switch (WeaponCode)
			{
				case TF_WEAPON_BAT:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_BAT_WOOD:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_BOTTLE:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_FIREAXE:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_CLUB:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_CROWBAR:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_KNIFE:
					Format(AString, sizeof(AString), "%s", "Very High");
				case TF_WEAPON_FISTS:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_SHOVEL:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_WRENCH:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_BONESAW:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_SHOTGUN_PRIMARY:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SHOTGUN_SOLDIER:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SHOTGUN_HWG:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SHOTGUN_PYRO:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SCATTERGUN:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SNIPERRIFLE:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_MINIGUN:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SMG:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SYRINGEGUN_MEDIC:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_TRANQ:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_ROCKETLAUNCHER:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADELAUNCHER:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_PIPEBOMBLAUNCHER:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_FLAMETHROWER:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_GRENADE_NORMAL:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_CONCUSSION:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_GRENADE_NAIL:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_MIRV:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_MIRV_DEMOMAN:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_NAPALM:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_GAS:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_GRENADE_EMP:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_CALTROP:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_PIPEBOMB:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_SMOKE_BOMB:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_GRENADE_HEAL:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_GRENADE_STUNBALL:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_GRENADE_JAR:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_GRENADE_JAR_MILK:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_PISTOL:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_PISTOL_SCOUT:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_REVOLVER:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_NAILGUN:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_PDA:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_PDA_ENGINEER_BUILD:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_PDA_ENGINEER_DESTROY:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_PDA_SPY:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_BUILDER:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_MEDIGUN:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_GRENADE_MIRVBOMB:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_FLAMETHROWER_ROCKET:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_GRENADE_DEMOMAN:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_SENTRY_BULLET:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SENTRY_ROCKET:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_DISPENSER:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_INVIS:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_FLAREGUN:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_LUNCHBOX:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_JAR:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_COMPOUND_BOW:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_BUFF_ITEM:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_PUMPKIN_BOMB:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_SWORD:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_DIRECTHIT:
				Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_LIFELINE:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_LASER_POINTER:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_DISPENSER_GUN:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SENTRY_REVENGE:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_JAR_MILK:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_HANDGUN_SCOUT_PRIMARY:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_BAT_FISH:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_CROSSBOW:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_STICKBOMB:
				Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_HANDGUN_SCOUT_SEC:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SODA_POPPER:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_SNIPERRIFLE_DECAP:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_RAYGUN:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_PARTICLE_CANNON:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_MECHANICAL_ARM:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_DRG_POMSON:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_BAT_GIFTWRAP:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_ORNAMENT:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_RAYGUN_REVENGE:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_PEP_BRAWLER_BLASTER:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_CLEAVER:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_CLEAVER:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_STICKY_BALL_LAUNCHER:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_STICKY_BALL:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_SHOTGUN_BUILDING_RESCUE:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_CANNON:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_THROWABLE:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_GRENADE_THROWABLE:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_PDA_SPY_BUILD:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_GRENADE_WATERBALLOON:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_HARVESTER_SAW:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_SPELLBOOK:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_SPELLBOOK_PROJECTILE:
					Format(AString, sizeof(AString), "%s", "Medium");
				case TF_WEAPON_SNIPERRIFLE_CLASSIC:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_PARACHUTE:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_GRAPPLINGHOOK:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_PASSTIME_GUN:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_CHARGED_SMG:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_BREAKABLE_SIGN:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_ROCKETPACK:
					Format(AString, sizeof(AString), "%s", "None");
				case TF_WEAPON_SLAP:
					Format(AString, sizeof(AString), "%s", "High");
				case TF_WEAPON_JAR_GAS:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_GRENADE_JAR_GAS:
					Format(AString, sizeof(AString), "%s", "Low");
				case TF_WEAPON_FLAME_BALL:
					Format(AString, sizeof(AString), "%s", "High");
				default:
					Format(AString, sizeof(AString), "%s", "Unknown");
			}
		}
	}
	return AString;
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{

    
    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
     return Plugin_Continue;   
	
	if(IsRobot(attacker, ROBOT_NAME) && victim == g_target)
	{
		TF2_AddCondition(attacker, TFCond_CritCola, 0.33);
	}
}

