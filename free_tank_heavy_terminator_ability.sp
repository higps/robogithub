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

#define TARGET_SEARCH "ui/quest_decode.wav"
#define TARGET_LOST "ui/cyoa_node_absent.wav"
#define TARGET_FOUND "ui/cyoa_objective_panel_expand.wav"
#define TARGET_TERMINATED "ui/cyoa_map_open.wav.wav"
#define TARGET_CANCEL "ui/cyoa_map_close.wav"
float scale = 1.15;

enum
{
target_valid,
target_in_spawn,
target_no_valid_target,
target_lost,
target_terminated,
target_cancelled
}
public OnMapStart()
{
	PrecacheSound(TARGET_SEARCH);
	PrecacheSound(TARGET_LOST);
	PrecacheSound(TARGET_FOUND);
	PrecacheSound(TARGET_TERMINATED);
	PrecacheSound(TARGET_CANCEL);
}

float g_flTagEndTime[MAXPLAYERS + 1];
int g_iGlowEnt[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };
float flDuration = 5.0;
float g_dottime = 0.0;
float g_dot_interval = 0.25;
int g_previous_state = -2;

float g_retarget_timer = 25.0;

int g_loadingDots = 1;
int g_targetstatus;

public Plugin:myinfo =
{
	name = "[TF2] Be the Terminator",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Rage Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}


public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public void OnPluginEnd()
{
		for (int i; i < sizeof(g_iGlowEnt); i++) {
		if (IsValidEntity(g_iGlowEnt[i])) {
			RemoveEntity(g_iGlowEnt[i]);
		}
	}
}

int validPlayers[MAXPLAYERS + 1];
int g_target = -1;
int g_previous_target = -2;
bool g_isTerminator = false;
float gametime = -1.0;
float gametime_retarget = -1.0;
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
		for (int i; i < sizeof(g_iGlowEnt); i++) {
		if (IsValidEntity(g_iGlowEnt[i])) {
			RemoveEntity(g_iGlowEnt[i]);
			g_target = -1;
		}
		}
		
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

			if(IsValidClient(i) && IsClientInGame(i) && IsPlayerAlive(i) && !TF2Spawn_IsClientInSpawn(i))
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
		// PrintToChatAll("No terminator, removing glow");
				for (int i = 1; i <= MaxClients; i++) {
			if(!IsAnyRobot(i))
			{
				if (IsValidEntity(g_iGlowEnt[i]))
				{
				RemoveEntity(g_iGlowEnt[i]);
				g_target = -1;
				}
			}
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
			TerminatorHeal(attacker);

		}else if(IsRobot(assister, ROBOT_NAME))
		{
			TerminatorHeal(assister);

		}

	}


	FindTerminator();
}

void TerminatorHeal(int client)
{
	AddPlayerHealth(client, GetCurrentHumanCount()*166, 0, false, true);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.0);
}

Action OnGlowShouldTransmit(int glow, int client) {
	int glowTarget = GetEntPropEnt(glow, Prop_Data, "m_hParent");
	if (!g_isTerminator || g_targetstatus != target_valid) return Plugin_Stop;

	if (!IsValidEntity(glowTarget)) {
		return Plugin_Stop;
	}

	
	if (!TF2_IsEnemyTeam(TF2_GetClientTeam(glowTarget), TF2_GetClientTeam(client))) {
		// prevent showing outline on teammates
		// TODO make this more robust for teamcounts larger than 2 --
		// we'd need to track the attacker
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}



public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME) /* && IsPlayerAlive(client) */)
	{
		DrawHUD(client);	
		int aimtarget = GetClientAimTarget(client);
		if (IsValidClient(aimtarget) && aimtarget == g_target)
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.33);
		}

		//Manually Finding New Target
		if(g_targetstatus == target_valid && GetEngineTime() > gametime_retarget && buttons & (IN_ATTACK2|IN_ATTACK3|IN_USE)) 
		{
			g_targetstatus = target_cancelled;
			g_target = -1;
			SetGameTime();
			SetGameTimeReTarget();
			// PrintToChatAll("Did the button");
			// FindTerminationTarget();
		}

		// g_switch_available = (gametime_retarget - GetEngineTime() == 0.0) ? true : false;
	}
}


public void OnClientDisconnect(int client)
{
	if(g_target == client)
	{
		g_targetstatus = target_lost;
		SetGameTime();
		// FindTerminationTarget();
	}
}

float g_search = 4.0;
void SetGameTime()
{
	if (gametime < 0.0){
		gametime = GetEngineTime() + g_search;
		// PrintToChatAll("Setting gametime to %f", gametime);
	} 
}


void SetGameTimeReTarget()
{

		gametime_retarget = GetEngineTime() + g_retarget_timer;
		// PrintToChatAll("Setting gametime to %f", gametime);
	
}

bool abort_state = false;

void DrawHUD(int client)
{
	

	//Sets the status of targets
	// PrintCenterTextAll("Target Status %i", g_targetstatus);

	// if (g_targetstatus == target_cancelled && GetEngineTime() > gametime)
	// {
	
	//Write some code to properly exit the cancelled state after SetGameTime();

	if (GetEngineTime() > gametime)
	{
		if(IsValidClient(g_target) && !IsPlayerAlive(g_target) && g_targetstatus != target_terminated)
		{
			// PrintToChatAll("Target Terminated!");
			SetGameTime();
			g_targetstatus = target_terminated;
			

		}else if(IsValidClient(g_target) && TF2Spawn_IsClientInSpawn(g_target) && g_targetstatus != target_in_spawn)
		{
			SetGameTime();
			g_targetstatus = target_in_spawn;
			

		}else if (!IsValidClient(g_target) || TF2_IsPlayerInCondition(g_target, TFCond_Cloaked) || !IsClientInGame(g_target) && g_targetstatus != target_lost)
		{
			SetGameTime();
			g_targetstatus = target_lost;
			

		}else if (IsValidClient(g_target) && IsPlayerAlive(g_target) && !TF2Spawn_IsClientInSpawn(g_target) && g_targetstatus != target_valid)
		{
			// SetGameTime();
			g_targetstatus = target_valid;
			SetGameTimeReTarget();
		}
	}


	char sHUDText[128];
	//Changes the HUD depending on status


	if(GameRules_GetProp("m_bInSetup"))
	{
		Format(sHUDText, sizeof(sHUDText), "HiNet Offline\nConnecting%s", GenerateDots());
	}else
	{

		switch(g_targetstatus)
		{
			case target_cancelled:
			{
				Format(sHUDText, sizeof(sHUDText), "Target aborted\nRecalibrating%s",GenerateDots());
			}
			case target_terminated:
			{
				Format(sHUDText, sizeof(sHUDText), "Target terminated\nAquiring target%s", GenerateDots());
			}
			case target_in_spawn:
			{
				Format(sHUDText, sizeof(sHUDText), "Target unreachable\nRerouting%s",GenerateDots());
				
			}
			case target_no_valid_target:
			{
				Format(sHUDText, sizeof(sHUDText), "No target found\nSearching%s",GenerateDots());
				
			}
			case target_lost:
			{
				Format(sHUDText, sizeof(sHUDText), "Target lost\nScanning%s",GenerateDots());
				
			}
			case target_valid:
			{
				Format(sHUDText, sizeof(sHUDText), "Action:Terminate\nID: %N\nLife:%i\nClass:%s\nThreat level: %s\nOptional:Abort in %0.f", g_target, GetClientHealth(g_target), ClassString(g_target),AssessThreatLevel(g_target), gametime_retarget - GetEngineTime() + 1.0);
				if(gametime_retarget - GetEngineTime() < 0.0)
				{
					Format(sHUDText, sizeof(sHUDText), "Action:Terminate\nID: %N\nLife:%i\nClass:%s\nThreat level: %s\nOptional:Abort ID (M2)", g_target, GetClientHealth(g_target), ClassString(g_target),AssessThreatLevel(g_target));
					abort_state = true;
				}else
				{
					abort_state = false;
				}
			}

		}
	}


	//Code for the loading dots
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

	//Search for new target after cool down period is over
	// PrintToChatAll("Enginetime %f, gametime %f", GetEngineTime(), gametime);
	// PrintCenterTextAll("Time %0.0f", GetEngineTime() - gametime);

	if(g_targetstatus != target_cancelled)
	{
		if(GetEngineTime() > gametime && g_targetstatus != target_valid /* || g_targetstatus == target_cancelled && GetEngineTime() > gametime */) 
		{
			// PrintToChatAll("B");
			FindTerminationTarget();
			// SetGameTimeReTarget();
			// SetGameTime();
			
		}
	}



	EmitHudSound(client);
	
	// 	 g_hud_post_time = GetEngineTime();
}


float g_sound_time = 0.0;
float g_sound_duration = 2.0;
bool g_previous_abort_state = false;
void EmitHudSound(int client)
{

	if (g_sound_time < GetEngineTime() && (g_previous_state != g_targetstatus))
	{
		switch(g_targetstatus)
		{
			case target_cancelled:
			{
				
				EmitSoundToClient(client, TARGET_CANCEL, client, SNDCHAN_AUTO);
				EmitSoundToClient(client, TARGET_CANCEL, client, SNDCHAN_AUTO);
				EmitSoundToClient(client, TARGET_CANCEL, client, SNDCHAN_AUTO);
				g_sound_time = GetEngineTime() + g_sound_duration;
			}
			case target_valid:
			{
				EmitSoundToClient(client, TARGET_FOUND, client, SNDCHAN_AUTO);
				EmitSoundToClient(client, TARGET_FOUND, client, SNDCHAN_AUTO);
				EmitSoundToClient(client, TARGET_FOUND, client, SNDCHAN_AUTO);
				g_sound_time = GetEngineTime() + g_sound_duration;
			}
			default:
			{
				StopSound(client, SNDCHAN_AUTO, TARGET_FOUND);
				StopSound(client, SNDCHAN_AUTO, TARGET_FOUND);
				StopSound(client, SNDCHAN_AUTO, TARGET_FOUND);

				EmitSoundToClient(client, TARGET_SEARCH);
				EmitSoundToClient(client, TARGET_SEARCH);
				EmitSoundToClient(client, TARGET_SEARCH);
				g_sound_time = GetEngineTime() + g_sound_duration;
			}

		}


	}

	if (abort_state && abort_state != g_previous_abort_state && g_sound_time < GetEngineTime())
	{
		EmitSoundToClient(client, TARGET_FOUND, client, SNDCHAN_AUTO);
		EmitSoundToClient(client, TARGET_FOUND, client, SNDCHAN_AUTO);
		EmitSoundToClient(client, TARGET_FOUND, client, SNDCHAN_AUTO);
		// g_sound_time = GetEngineTime() + g_sound_duration;
	}

	g_previous_abort_state = abort_state;
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
	
		if(!g_isTerminator)
		{
			FindTerminator();
		}

		if(IsRobot(attacker, ROBOT_NAME) && victim == g_target)
		{
			TF2_AddCondition(attacker, TFCond_CritCola, 0.33);
		}
}

