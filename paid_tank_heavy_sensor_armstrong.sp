#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Sensor Armstrong"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Nanomachines"
#define ROBOT_TIPS "Deal or take 4000 damage to fill meter, once activated become slower, ubered and repair yourself"
#define ROBOT_COST 2.5

 
#define GDEFLECTORH      "models/bots/heavy/bot_heavy.mdl"
#define SPAWN	"mvm/mvm_tank_horn.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/mvm_tank_loop.wav"


#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

bool g_Nanomode = false;
float g_DamageDone = 0.0;

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Pancop",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	AddNormalSoundHook(BossGPS);

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
	// restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
	// restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;


	AddRobot(robot, MakePanCop, PLUGIN_VERSION, restrictions);
}

public Action:BossGPS(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT1);
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
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGDeflectorH_MakePanCop", Native_SetGDeflectorH);
//	CreateNative("BeGDeflectorH_IsGDeflectorH", Native_IsGDeflectorH);
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

MakePanCop(client)
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
	SetModel(client, GDEFLECTORH);
	int iHealth = 9500;
	
	
	int MaxHealth = 300;
	// PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	 // PrintToChatAll("iHealth %i", iHealth);
	
	 // PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	float scale = 1.85;
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 1.3);
	TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.75);

	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);

	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	TF2Attrib_SetByName(client, "jarate backstabber", 1.0);
	TF2Attrib_SetByName(client, "increase buff duration", 10.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	TF2Attrib_SetByName(client, "damage force reduction", 0.0);
	TF2Attrib_SetByName(client, "head scale", 0.8);



	UpdatePlayerHitbox(client, scale);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);


	PrintHintText(client, ROBOT_TIPS);

	//Tank stats
    // TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.75);
    TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
	// TF2_AddCondition(client,TFCond_DefenseBuffNoCritBlock);

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
		GiveGDeflectorH(client);
}

#define Minnesotaslick 30315
#define ReaderChoice 30831 
#define SiberianSophisticate 946 
 
stock GiveGDeflectorH(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);


		CreateRoboWeapon(client, "tf_weapon_fists", 5, 6, 2, 2, 0);
		// CreateRoboWeapon(client, "tf_weapon_lunchbox", 311, 6, 2, 1, 0);
		TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));

		float TeamPaint = 0.0;

		if (iTeam == TFTeam_Red){
			TeamPaint = 3874595.0;
			
		}
		if (iTeam == TFTeam_Blue){
			
			TeamPaint = 1581885.0;
		}


// set item tint RGB : 3874595
// set item tint RGB 2 : 1581885
		CreateRoboHat(client, Minnesotaslick, 10, 6, TeamPaint, 0.75, -1.0); 
		CreateRoboHat(client, ReaderChoice, 10, 6, 0.0, 0.75, -1.0); 
		CreateRoboHat(client, SiberianSophisticate, 10, 6, 0.0, 1.0, -1.0); 

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "damage bonus", 1.23076923076923077);
			TF2Attrib_SetByName(Weapon1, "fire rate penalty", 1.1);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);
			TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			TF2CustAttr_SetString(Weapon1, "shake on hit", "amplitude=10.0 frequency=2.0 duration=0.5");

		}

	}
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	// if(!IsValidClient(attacker))
	// return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME) || IsRobot(victim, ROBOT_NAME))
	{



			 if (IsRobot(victim, ROBOT_NAME))
			 {
				if (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) || (TF2_IsPlayerInCondition(victim, TFCond_UberchargedCanteen)))
				{
					return Plugin_Continue;
				}
			 }

			 if (IsRobot(attacker, ROBOT_NAME))
			 {
				if (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) || (TF2_IsPlayerInCondition(victim, TFCond_UberchargedCanteen)
				|| TF2_IsPlayerInCondition(attacker, TFCond_Ubercharged) || TF2_IsPlayerInCondition(attacker, TFCond_UberchargedCanteen) ))
				{
					return Plugin_Continue;
				}
			 }

			
			g_DamageDone += damage;
		
	}
	return Plugin_Continue;
}


bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_duration = 5.0;
float FireModeTimer = -1.0;
float g_skill; 
float g_skill_cooldown = 4000.0;
// float g_skill_time;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		if( GetEntProp( client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_RELOAD|IN_USE) ) 
		{
			// PrintToChatAll("Press");
            g_button_held[client] = true;
		}



		if( GetEntProp( client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_RELOAD|IN_USE) ) 
		{
			// PrintToChatAll("Release");
			g_button_held[client] = false;
            
		}




		g_skill = GetEngineTime();
		
		DrawHUD(client);

	}
	return Plugin_Continue;
}

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"
void DrawHUD(int client)
{
	char sHUDText[128];
	char sProgress[32];
	int iPercents = RoundToCeil(g_DamageDone / g_skill_cooldown * 100.0);

	for (int j = 1; j <= 10; j++)
	{
		if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
		else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}
	//PrintToChatAll("Damage: %f, skilltime %f", g_DamageDone, g_skill_cooldown);

	// int iCountDown = RoundToCeil(g_skill_time - g_skill);
	int iCountDownFiring = RoundToCeil(FireModeTimer - g_skill);
	
	Format(sHUDText, sizeof(sHUDText), "Nanobots: %i %%%%\n    %s",iPercents, sProgress);

	if(iPercents >= 100)
	{

			if (g_Nanomode){
				Format(sHUDText, sizeof(sHUDText), "Nanobots! %i", iCountDownFiring);
				SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 0, 255);
			}else{
				Format(sHUDText, sizeof(sHUDText), "Nanobots Ready!\nUse Special Attack to Activate!");
				SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);	
				}


			
	}else {

		SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 255, 255);
	}

	if (g_button_held[client] && iPercents >= 100 && !g_Nanomode)
		{
			if (FireModeTimer <= GetEngineTime() || FireModeTimer == -1.0)
			{
				TF2_AddCondition(client, TFCond_UberchargedCanteen, g_duration);
				TF2_AddCondition(client, TFCond_HalloweenQuickHeal, g_duration);
				TF2Attrib_AddCustomPlayerAttribute(client, "healing received bonus", 4.0, g_duration);
				TF2Attrib_AddCustomPlayerAttribute(client, "mod weapon blocks healing", 1.0, g_duration);
				TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 0.75);
				g_DamageDone = 0.0;
			}
		}

	if (FireModeTimer <= GetEngineTime() && g_Nanomode)
	{
		g_Nanomode = false;
		g_DamageDone = 0.0;
	}


	ShowHudText(client, -3, sHUDText);
	// b_hud_clamp[client] = false;
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	//PrintToChatAll("CONDITION REMOVED!");
	if (IsRobot(client, ROBOT_NAME)){

	
    if(condition == TFCond_UberchargedCanteen){
		TF2Attrib_RemoveCustomPlayerAttribute(client, "move speed penalty");
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		TF2Attrib_SetByName(client, "move speed penalty", 1.3);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	}
	// TF2_RemoveCondition(client, TFCond_Dazed);
	// TF2_RemoveCondition(client, TFCond_KnockedIntoAir);
	// PrintToChatAll("Condition was: %i", condition);
   }

}