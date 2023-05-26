#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Dr GrordBot"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Soldier"
#define ROBOT_SUBCLASS "Rockets"
#define ROBOT_DESCRIPTION "Electro Ball, Cow Mangler"
#define ROBOT_TIPS "You have rapid reload Cow Mangler & Electroball"
#define ROBOT_ON_DEATH "Look out for GrordBot's Electroball\nElectroball has a long cooldown"

#define GSOLDIER		"models/bots/soldier_boss/bot_soldier_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/giant_soldier/giant_soldier_explode.wav"
#define LOOP	"mvm/giant_soldier/giant_soldier_loop.wav"

#define LEFTFOOT        ")mvm/giant_soldier/giant_soldier_step01.wav"
#define LEFTFOOT1       ")mvm/giant_soldier/giant_soldier_step03.wav"
#define RIGHTFOOT       ")mvm/giant_soldier/giant_soldier_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_soldier/giant_soldier_step04.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Icebear Soldier",
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
	robot.deathtip = ROBOT_ON_DEATH;
	AddRobot(robot, MakeGiantSoldier, PLUGIN_VERSION);
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
	SMLogTag(SML_VERBOSE, "Createing Icebear");
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
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.4);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.1);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	
	//TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
	TF2Attrib_SetByName(client, "head scale", 0.75);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
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

#define LordCockswain 439
#define Pipe 440

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		CreateRoboWeapon(client, "tf_weapon_particle_cannon", 441, 6, 1, 2, 0);
		// CreateRoboWeapon(client, "tf_weapon_raygun", 442, 6, 1, 2, 0);
//		CreateWeapon(client, "tf_weapon_shovel", 447, 6, 1, 2, 0);
		
		CreateRoboHat(client, LordCockswain, 10, 6, 0.0, 1.0, -1.0);
		CreateRoboHat(client, Pipe, 10, 6, 0.0, 1.0, -1.0);
		// CreateRoboHat(client, Professorspeks, 10, 6, 0.0, 0.75, 1.0);
		
		// CreateHat(client, 183, 10, 6, true); //Sergeant's Drill Hat
		// CreateHat(client, 647, 10, 6, true); //The All-Father
		// CreateHat(client, 343, 10, 6, true);//Professor speks

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		//int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		// TF2Attrib_SetByName(client, "gesture speed increase", 10.0);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 0.8);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "Projectile speed decreased", 0.85);
			TF2Attrib_SetByName(Weapon1, "clip size bonus upgrade", 1.5);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.7);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 0.25);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);					
			TF2CustAttr_SetString(client, "Spell-Caster", "Spell=7 Cooldown=50.0");
		}

		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		//int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		// if(IsValidEntity(Weapon2))
		// {
		// 	TF2Attrib_RemoveAll(Weapon2);
			
		// 	TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 3.0);
		// 	TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
		// 	TF2Attrib_SetByName(Weapon2, "Projectile speed increased", 2.0);
		// 	TF2Attrib_SetByName(Weapon2, "clip size bonus upgrade", 3.0);
		// 	TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.4);
		// 	TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
		// 	TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);			
		// 	// TF2Attrib_SetByName(Weapon2, "auto fires full clip all at once", 1.0);			

			
		// }
		

	}
}

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantSoldier(GetNativeCell(1));
	
// 

#define PAGE_LENGTH 7
bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 45.0;
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


	int	index = 7;

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

	Format(sHUDText, sizeof(sHUDText), "Energy Ball: %i   ", iCountDown);
	

	if(iCountDown <= 0)
	{
		Format(sHUDText, sizeof(sHUDText), "Energy Ball!");
			
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
