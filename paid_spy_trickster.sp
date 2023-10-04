#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Trickster"
#define ROBOT_ROLE "Spy"
#define ROBOT_CLASS "Spy"
#define ROBOT_SUBCLASS "Spy"
#define ROBOT_DESCRIPTION "BotZip Shrink Powers"
#define ROBOT_COST 1.5
#define ROBOT_TIPS "Infinite cloak\nStab enemies to gain shrink ability\nGain size back on kill"
#define ROBOT_ON_DEATH "Trickster disguises on stabs\nTrickster can shrink after getting 3 kills\nPyro's flames & airblast can shut down spies"

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
	robot.deathtip = ROBOT_ON_DEATH;
	robot.footstep = ROBOT_FOOTSTEP_NORMAL;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;
	robot.difficulty = ROBOT_DIFFICULTY_MEDIUM;
	AddRobot(robot, MakeSpy, PLUGIN_VERSION, restrictions);
	
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
float g_scale = 1.5;
float g_mini_scale = 0.9;
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsRobot(attacker, ROBOT_NAME) && !IsAnyRobot(victim) && g_souls < g_soul_required)
	{
		g_souls++;
		SetEntPropFloat(attacker, Prop_Send, "m_flModelScale", g_scale);
		UpdatePlayerHitbox(attacker, g_scale);
	}
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


	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.95);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);

	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	
	
	UpdatePlayerHitbox(client, g_scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client, ROBOT_TIPS);


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

#define BigTopper 30798
#define ShowStopper 30797

stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{

		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Revolver
	TF2_RemoveWeaponSlot(client, 2); // Gun
	TF2_RemoveWeaponSlot(client, 4);// inviswatch

	CreateRoboWeapon(client, "tf_weapon_knife", 574, 6, 1, 2, 0); //kunai
	CreateRoboWeapon(client, "tf_weapon_invis", 30, 6, 1, 4, 0); 
	CreateRoboWeapon(client, "tf_weapon_sapper", 735, 6, 1, 1, 0);//snack attack

	CreateRoboHat(client, BigTopper, 10, 6, 0.0, 1.0, -1.0); 
	CreateRoboHat(client, ShowStopper, 10, 6, 0.0, 1.0, -1.0); 

	int Knife = GetPlayerWeaponSlot(client, 2); //Knife
	int Cloak = GetPlayerWeaponSlot(client, 4); //Invis watch
	int Sapper = GetPlayerWeaponSlot(client, 1); //Sapper

	if(IsValidEntity(Knife)) //
		{

			TF2Attrib_SetByName(Knife, "dmg penalty vs players", 1.25);
			TF2Attrib_SetByName(Knife, "dmg penalty vs buildings", 0.5);
			TF2Attrib_SetByName(Knife, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Knife, "mod_disguise_consumes_cloak", 0.0);
										
		}
	if(IsValidEntity(Cloak)) //
		{
			TF2Attrib_RemoveAll(Cloak);
			TF2Attrib_SetByName(Cloak, "mult cloak meter consume rate", -100.0);
			TF2Attrib_SetByName(Cloak, "mult decloak rate", 0.3);
		}
	if(IsValidEntity(Sapper)) //
		{

			TF2Attrib_SetByName(Sapper, "sapper damage leaches health", 5.0);
			TF2Attrib_SetByName(Sapper, "robo sapper", 100.0);

		}	
	TF2_AddCondition(client, TFCond_Cloaked);
	}
}



//Spell code

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

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_mini_scale);
	UpdatePlayerHitbox(client, g_mini_scale);
	EmitSoundToAll(SHRINK,client);
}

// float g_hud_draw_delay = 0.1;
// float g_hud_post_time = 0.0;
bool isready;
void DrawHUD(int client)
{
	char sHUDText[128];
	int iCountDown = RoundToCeil(g_Recharge[client] - g_skill);

	Format(sHUDText, sizeof(sHUDText), "Shrink: %i/%i", g_souls, g_soul_required);
	
	if(g_souls >= g_soul_required)
	{

	Format(sHUDText, sizeof(sHUDText), "Shrink: %i/%i\nReady!",g_souls, g_soul_required);

	
	SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);


	} else {
	SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);

	}
	ShowHudText(client, -2, sHUDText);
	if (!isready && iCountDown <= 0)
	{
	TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
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
