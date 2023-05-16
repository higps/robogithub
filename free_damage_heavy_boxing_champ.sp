#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <dhooks>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Boxing Champ"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Killing Gloves of Boxing"
#define ROBOT_TIPS "Kill enemies to get long time crits!\nYou have melee resist"
#define ROBOT_ON_DEATH "Boxing Champ is extremely resistant to melee damage\nBoxing Champ is crit boosted while crouch sliding\nKeep your distance"
 
#define GDEFLECTORH      "models/bots/heavy/bot_heavy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

//#define GIFTBRINGER 30747

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Deflector Heavy",
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

	AddRobot(robot, MakeGDeflectorH, PLUGIN_VERSION);


}

public Action:BossGPS(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step01.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step03.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step02.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step04.wav");
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGDeflectorH_MakeGDeflectorH", Native_SetGDeflectorH);
//	CreateNative("BeGDeflectorH_IsGDeflectorH", Native_IsGDeflectorH);
	return APLRes_Success;
}
 
public OnMapStart()
{

	

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

MakeGDeflectorH(client)
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
	int iHealth = 3000;
	
	
	int MaxHealth = 300;
	int iAdditiveHP = iHealth - MaxHealth;
	float OverHealRate = 1.5;


	TF2_SetHealth(client, iHealth);
		// PrintToChatAll("MaxHealth %i", MaxHealth);
	 // PrintToChatAll("iHealth %i", iHealth);
	
	 // PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;

	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 1.3);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	// TF2Attrib_SetByName(client, "increased jump height", 0.0);
	
	//TF2Attrib_SetByName(client, "head scale", 0.75);
	// TF2Attrib_SetByName(client, "hand scale", 1.25);
	
	UpdatePlayerHitbox(client, 1.5);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	// TF2_AddCondition(client, TFCond_CritCanteen);

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
		GiveGDeflectorH(client);
}

#define Pugilist 246
#define HeacyChamp 30080
#define TitaniumTowel 30012

stock GiveGDeflectorH(client)
{
	if (IsValidClient(client))
	{
		//Remove items and hats
		RoboRemoveAllWearables(client);
		//TF2_RemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		//void  CreateRoboHat(int client, int itemindex, int level, int quality, float paint, float scale, float style);
		CreateRoboHat(client, Pugilist, 10, 6, 0.0, 1.0, -1.0);//Rotation sensation
		CreateRoboHat(client, HeacyChamp, 10, 6, 0.0, 1.0, -1.0);//Summer shades


		CreateRoboWeapon(client, "tf_weapon_fists", 43, 6, 1, 0, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.3);
			TF2Attrib_SetByName(Weapon1, "critboost on kill", 6.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.25);
			TF2Attrib_SetByName(Weapon1, "dmg from melee increased", 0.25);
		}
	}
}

// float g_cooldown = 1.5;
// float g_crouch_time = 0.0;

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 5.0;
float g_skill;

bool isready;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		// if(GetEntProp(client, Prop_Data, "m_bDucking")) 
		// {
		// 	// PrintToChatAll("Press");
        //     // g_button_held[client] = true;
		// 	GetEntProp(client, Prop_Data, "m_bDucking")) 
		// }


		if(buttons & IN_DUCK) 
		{
			buttons &= ~IN_JUMP;

			// if(GetEntProp( client, Prop_Data, "m_afButtonPressed" ) & IN_JUMP){
			// 	return Plugin_Changed;
			// }
			// PrintToChatAll("Release");
			// // g_button_held[client] = tr;
			// if(GetEntProp(client, Prop_Data, "m_flDucktime")) 
			// PrintToChatAll("Ducktime %f", GetEntPropFloat(client, Prop_Data, "m_flDucktime"));
// && !GetEntProp(client, Prop_Send, "m_bJumping")
			// int IsJumping = GetEntProp(client, Prop_Send, "m_bJumping");

			if (g_Recharge[client] <= GetEngineTime() && isready) 
			{
			SetSpeed(client);
			g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
			
			}
			
		}
			

		if( GetEntProp( client, Prop_Data, "m_afButtonReleased" )  & IN_DUCK) 
		{
			// PrintToChatAll("Release");
			// g_button_held[client] = false;
			ResetSpeed(client);
            
		}
		g_skill = GetEngineTime();
		DrawHUD(client);
	}
	return Plugin_Continue;
}

void SetSpeed(int client)
{
	// TF2Attrib_AddCustomPlayerAttribute(client, "increased jump height", 0.01, 1.0);
	TF2_AddCondition(client, TFCond_CritCanteen, 1.0);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 520.0);
}

void ResetSpeed(int client)
{
	TF2_StunPlayer(client, 0.0, 0.0, TF_STUNFLAG_SLOWDOWN);
}


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

	Format(sHUDText, sizeof(sHUDText), "Crouch Dash: %i   ", iCountDown);
	

	if(iCountDown <= 0)
	{
		Format(sHUDText, sizeof(sHUDText), "Crouch Dash Ready!");
			
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
		g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
		isready = false;
		
	}
}
