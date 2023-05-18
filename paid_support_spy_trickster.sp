#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
//#include <tf2items_giveweapon>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Trickster"
#define ROBOT_ROLE "Support"
#define ROBOT_CLASS "Spy"
#define ROBOT_SUBCLASS "Support"
#define ROBOT_DESCRIPTION "BotZip Shrink Powers"
#define ROBOT_COST 1.5
#define ROBOT_TIPS "Infinite cloak\nStab enemies to gain shrink ability\nGain size back on kill"
#define ROBOT_ON_DEATH "Trickster instantly disguises on stabs\nTrickster can shrink after getting 3 kills\nPyro's flames & airblast can shut down spies"

#define MODEL             "models/bots/spy/bot_spy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"
#define SHRINK    "sound/ui/gmm_rank_up.wav"
#define SIZE_RESTORED    "sound/ui/gmm_rank_up.wav/mm_rank_up_achieved.wav"

#define SPY_SPAWN_SOUND1		"vo/mvm_spy_spawn01.mp3"
#define SPY_SPAWN_SOUND2		"vo/mvm_spy_spawn02.mp3"
#define SPY_SPAWN_SOUND3		"vo/mvm_spy_spawn03.mp3"
#define SPY_SPAWN_SOUND4		"vo/mvm_spy_spawn04.mp3"

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 25.0;
float g_skill;
// #define SPY_DEATH_SOUND1		"vo/mvm_spybot_death01.mp3"
// #define SPY_DEATH_SOUND2		"vo/mvm_spybot_death02.mp3"
// #define SPY_DEATH_SOUND3		"vo/mvm_spybot_death03.mp3"
// #define SPY_DEATH_SOUND4		"vo/mvm_spybot_death04.mp3"
// #define SPY_DEATH_SOUND5		"vo/mvm_spybot_death05.mp3"
// #define SPY_DEATH_SOUND6		"vo/mvm_spybot_death06.mp3"
// #define SPY_DEATH_SOUND7		"vo/mvm_spybot_death07.mp3"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Spy",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Spy",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

//bool g_bisGSPY[MAXPLAYERS + 1];

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

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;

	// restrictions.TeamCoins = new RobotCoinRestrictionDefinition();
	// restrictions.TeamCoins.Overall = 2;


	AddRobot(robot, MakeSpy, PLUGIN_VERSION, restrictions);

	// PrecacheModel(MODEL);




	// PrecacheSound(SPY_SPAWN_SOUND1, true);
	// PrecacheSound(SPY_SPAWN_SOUND2, true);
	// PrecacheSound(SPY_SPAWN_SOUND3, true);
	// PrecacheSound(SPY_SPAWN_SOUND4, true);
	// PrecacheSound(SPY_DEATH_SOUND1, true);
	// PrecacheSound(SPY_DEATH_SOUND2, true);
	// PrecacheSound(SPY_DEATH_SOUND3, true);
	// PrecacheSound(SPY_DEATH_SOUND4, true);
	// PrecacheSound(SPY_DEATH_SOUND5, true);

	
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeSpy", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
	return APLRes_Success;
}

public OnMapStart()
{
	// PrecacheModel(MODEL);
	PrecacheSound(SHRINK, true);
	PrecacheSound(SIZE_RESTORED, true);

}
int g_souls = 0;
int g_soul_required = 3;
float g_scale = 1.75;
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsRobot(attacker, ROBOT_NAME) && !IsAnyRobot(victim) && g_souls < g_soul_required)
	{
		g_souls++;
		SetEntPropFloat(attacker, Prop_Send, "m_flModelScale", g_scale);
		UpdatePlayerHitbox(attacker, g_scale);
		// EmitGameSoundToAll(SHRINK,attacker);
		// PrintToChatAll("Souls needed: %i/%i", g_souls, g_soul_required);
	}

	// if (IsRobot(attacker, ROBOT_NAME))
	// {
		
	// }
	// return Plugin_Continue;
}

void SetSpeed(int client)
{
	
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
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

MakeSpy(client)
{
	TF2_SetPlayerClass(client, TFClass_Spy);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 2)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 2);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, MODEL);


	int iHealth = 2000;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;

	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	//TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	//TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);

	// TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	
	
	UpdatePlayerHitbox(client, g_scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	
	// PrintToChat(client, "1. You are now Giant Mr Paladin robot!");
	PrintHintText(client, ROBOT_TIPS);

	if (IsPlayerAlive(client)){
	EmitGameSoundToAll("Announcer.MVM_Spy_Alert");
	} 


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
	GiveBigRoboDane(client);
}

// public Action:Timer_Resize(Handle:timer, any:hat)
// {
	// if (IsValidClient(client))
	// GiveBigRoboDane(client);
// }

#define BigTopper 30798
// #define VoodoVizier 31072
#define ShowStopper 30797
// #define Spek 343
// #define WhitePaint 15132390.0



stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{

		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Revolver
	TF2_RemoveWeaponSlot(client, 2); // Gun
	TF2_RemoveWeaponSlot(client, 4);// inviswatch

	
	// CreateRoboWeapon(client, "tf_weapon_revolver", 224, 6, 1, 0, 0);
	CreateRoboWeapon(client, "tf_weapon_knife", 574, 6, 1, 2, 0); //kunai
	CreateRoboWeapon(client, "tf_weapon_invis", 30, 6, 1, 4, 0); 
	CreateRoboWeapon(client, "tf_weapon_sapper", 735, 6, 1, 1, 0);//snack attack

	CreateRoboHat(client, BigTopper, 10, 6, 0.0, 1.0, -1.0); 
	// CreateRoboHat(client, VoodoVizier, 10, 6, 8208497.0, 1.0, -1.0); 
	CreateRoboHat(client, ShowStopper, 10, 6, 0.0, 1.0, -1.0); 
	// CreateRoboHat(client, LadyKiller, 10, 6, 0.0, 1.0, -1.0);
	// CreateRoboHat(client, Spek, 10, 6, 0.0, 1.0, -1.0);
	
		
	// int Revolver = GetPlayerWeaponSlot(client, 0); //Revolver
	int Knife = GetPlayerWeaponSlot(client, 2); //Knife
	int Cloak = GetPlayerWeaponSlot(client, 4); //Invis watch
	int Sapper = GetPlayerWeaponSlot(client, 1); //Sapper

	// if(IsValidEntity(Revolver)) //Revovler
	// 	{
	// 		TF2Attrib_RemoveAll(Revolver);
			
	// 		TF2Attrib_SetByName(Revolver, "fire rate bonus", 2.5);
	// 		TF2Attrib_SetByName(Revolver, "damage bonus", 2.0);
	// 		TF2Attrib_SetByName(Revolver, "killstreak tier", 1.0);
						
	// 	}

	if(IsValidEntity(Knife)) //
		{
			// TF2Attrib_RemoveAll(Knife);
			
			//TF2Attrib_SetByName(Knife, "fire rate bonus", 0.8);
			TF2Attrib_SetByName(Knife, "damage bonus", 1.25);
			TF2Attrib_SetByName(Knife, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Knife, "mod_disguise_consumes_cloak", 0.0);
			// TF2Attrib_SetByName(Knife, "sanguisuge", 0.0);
			// TF2Attrib_SetByName(Knife, "restore health on kill", 10.0);
			
						
		}
	if(IsValidEntity(Cloak)) //
		{
			TF2Attrib_RemoveAll(Cloak);
			// TF2Attrib_SetByName(Cloak, "mod weapon blocks healing", 1.0);
			TF2Attrib_SetByName(Cloak, "mult cloak meter consume rate", -100.0);
			TF2Attrib_SetByName(Cloak, "mult decloak rate", 0.01);
		}
	if(IsValidEntity(Sapper)) //
		{
			//TF2Attrib_RemoveAll(Sapper);
			
		//	TF2Attrib_SetByName(Sapper, "mult cloak meter consume rate", 0.0);
			TF2Attrib_SetByName(Sapper, "sapper damage leaches health", 50.0);
			TF2Attrib_SetByName(Sapper, "robo sapper", 150.0);
			// TF2Attrib_SetByName(Sapper, "mod weapon blocks healing", 1.0);
			//TF2Attrib_SetByName(Sapper, "min_viewmodel_offset", 5 -2 -4);
		}	
	// }
	// TF2_AddCondition(client, TFCond_CritCanteen);
	}
}

//Fireball code


#define PAGE_LENGTH 7

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		SetSpeed(client);

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
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		// UpdateCharge(client);
		g_skill = GetEngineTime();
		DrawHUD(client);
		
	}
	return Plugin_Continue;
}

public void CastSpell(int client) {

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.15);
	UpdatePlayerHitbox(client, 1.15);
	EmitSoundToAll(SHRINK,client);
}

// float g_hud_draw_delay = 0.1;
// float g_hud_post_time = 0.0;
bool isready;
void DrawHUD(int client)
{
	char sHUDText[128];
	// char sProgress[32];
	//int iPercents = RoundToCeil(float(g_Recharge[client]) / float(g_RechargeCooldown) * 100.0);
	int iCountDown = RoundToCeil(g_Recharge[client] - g_skill);

	// for (int j = 1; j <= 10; j++)
	// {
	// 	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	// 	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	// }


	Format(sHUDText, sizeof(sHUDText), "Shrink: %i/%i", g_souls, g_soul_required);
	

	if(g_souls >= g_soul_required)
	{

	Format(sHUDText, sizeof(sHUDText), "Shrink: %i/%i\nReady!",g_souls, g_soul_required);

	
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

	if (g_button_held[client] && g_souls >= 3 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_CloakFlicker))
	{

	RequestFrame(CastSpell, client);
	g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
	isready = false;
	g_souls = 0;

	}
}
