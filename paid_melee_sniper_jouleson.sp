#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Jouleson"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Sniper"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Invisible Spell Sniper"
#define ROBOT_TIPS "Use your spell to go invisible\nYour Shiv has longer bleed\nSpeed on hit"
#define ROBOT_ON_DEATH "Jouleson has the invisibility spell\nUse fire and liquids to track him down"
#define ROBOT_COST 1.0

#define ChangeDane             "models/bots/Sniper/bot_Sniper.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Huntsbot",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Huntsbot",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	//HookEvent("player_death", Event_Death, EventHookMode_Post);

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
	restrictions.RobotCoins.PerRobot= ROBOT_COST;

	AddRobot(robot, MakeSniper, PLUGIN_VERSION, restrictions);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeSniper", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
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

MakeSniper(client)
{

	TF2_RemoveWeaponSlot(client, 0); //Huntsman
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri

	TF2_SetPlayerClass(client, TFClass_Sniper);
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
	SetModel(client, ChangeDane);


	int iHealth = 3500;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;
	float scale = 1.75;
	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 1.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 1.0);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "deploy time decreased", 0.05);
	TF2Attrib_SetByName(client, "move speed penalty", 0.85);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	// TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	// TF2Attrib_SetByName(client, "increase player capture value", -1.0);
TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	// TF2Attrib_SetByName(client, "health regen", 10.0);

	
	
	UpdatePlayerHitbox(client, scale);
	
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
	GiveBigRoboHuntsbot(client);
}

// public Action:Timer_Resize(Handle:timer, any:hat)
// {
	// if (IsValidClient(client))
	// GiveBigRoboHuntsbot(client);
// }

#define GoalKeeper 31217
#define WaggaWaggaWear  31055
#define TriggermansTacticals 30424
stock GiveBigRoboHuntsbot(client)
{
	if (IsValidClient(client))
	{

	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Huntsman
	TF2_RemoveWeaponSlot(client, 1); //Smg
	TF2_RemoveWeaponSlot(client, 2); // kukri



	CreateRoboWeapon(client, "tf_weapon_club", 171, 6, 1, 2, 0);//shiv

	CreateRoboHat(client, GoalKeeper, 10, 6, 2960676.0, 1.0, 1.0); 
	CreateRoboHat(client, WaggaWaggaWear, 10, 6, 2960676.0, 1.0, 1.0); 
	CreateRoboHat(client, TriggermansTacticals, 10, 6, 0.0, 1.0, 1.0); 
	


	int Kukri = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee); //Shahanshah
	int SMG = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary); //SMG

		if(IsValidEntity(SMG))
		{
		TF2Attrib_RemoveAll(SMG);

		TF2Attrib_SetByName(SMG, "provide on active", 1.0);
		// TF2Attrib_SetByName(SMG, "move speed penalty", 0.5);
		TF2Attrib_SetByName(SMG, "effect bar recharge rate increased", 0.25);
		}


		if(IsValidEntity(Kukri))
		{
			TF2Attrib_RemoveAll(Kukri);
			
			TF2Attrib_SetByName(Kukri, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Kukri, "fire rate bonus", 0.35);
			TF2Attrib_SetByName(Kukri, "damage penalty", 0.75);
			TF2Attrib_SetByName(Kukri, "bleeding duration", 12.0);

			
			TF2Attrib_SetByName(Kukri, "dmg penalty vs buildings", 0.25);
			TF2Attrib_SetByName(Kukri, "speed_boost_on_hit", 1.0);
			
			 
			// TF2Attrib_SetByName(Kukri, "heal on hit for rapidfire", 15.0);
			// TF2Attrib_SetByName(Kukri, "heal on kill", 150.0);
		}	
	}

	// SetTankStats(client);
	// TF2_AddCondition(client,TFCond_DefenseBuffNoCritBlock);
}

// public void OnEntityCreated(int iEntity, const char[] sClassName) 
// {
// 	if (StrContains(sClassName, "tf_projectile_arrow") == 0)
// 	{
// 		PrintToChatAll("Hooked arrow");
// 		SDKHook(iEntity, SDKHook_Spawn, Hook_OnProjectileSpawn);
// 	}
	
// }

// public void Hook_OnProjectileSpawn(iEntity) {
// 	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
// 	if (0 < iClient && iClient <= MaxClients && IsRobot(iClient, ROBOT_NAME)) {
// 		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 5.25);
// 	}
// }
#define PAGE_LENGTH 7
bool g_button_held[MAXPLAYERS + 1] = false;
float g_Recharge[MAXPLAYERS + 1] = 0.0;
float g_RechargeCooldown = 20.0;
float g_skill;

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


public void CastSpell(int client) {


	int	index = 5;

	if (!IsPlayerAlive(client))ReplyToCommand(client, "[SM] You must be alive to use this command!");
	else {
		int ent = FindSpellbook(client);
		if (!ent) {
			ent = CreateEntityByName("tf_weapon_spellbook");
			if (ent != -1) {
				SetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex", 1132);
				SetEntProp(ent, Prop_Send, "m_bInitialized", 1);
				SetEntProp(ent, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
				DispatchSpawn(ent);
			}
			else {
				ReplyToCommand(client, "[SM] Could not create spellbook entity!");
				return;
			}
		}
		
		int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (active != ent) {
			SetEntProp(ent, Prop_Send, "m_iSpellCharges", 1);
			SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", index);
			
			SetEntPropEnt(client, Prop_Send, "m_hLastWeapon", active);
			EquipPlayerWeapon(client, ent);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", ent);
			
			
			// if (rare)fTimeFiredRare[client] = time;
			// fTimeFired[client] = time;
		}
	}
}

public int FindSpellbook(int client) {
	int i = -1;
	while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1) {
		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWeapon"))return i;
	}
	return 0;
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

	Format(sHUDText, sizeof(sHUDText), "Invisibility: %i   ", iCountDown);
	

	if(iCountDown <= 0)
	{
		Format(sHUDText, sizeof(sHUDText), "Invisibility Ready!");
			
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
		RequestFrame(CastSpell, client);
		g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
		isready = false;
		
	}
}
