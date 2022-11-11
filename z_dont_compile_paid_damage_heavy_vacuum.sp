#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
 


#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Vacuum"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Pull Enemies"
#define ROBOT_COST 3.0
#define ROBOT_TIPS "Your minigun pulls enemies towards you"
 
#define GRageH      "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

// #define SOUND_GUNFIRE	")mvm/giant_heavy/giant_heavy_gunfire.wav"
// #define SOUND_GUNSPIN	")mvm/giant_heavy/giant_heavy_gunspin.wav"
// #define SOUND_WINDUP	")mvm/giant_heavy/giant_heavy_gunwindup.wav"
// #define SOUND_WINDDOWN	")mvm/giant_heavy/giant_heavy_gunwinddown.wav"

#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

float scale = 1.75;

// int iREDTeamColor[4] = {255,104,104,255};
// int iBLUTeamColor[4] = {113,175,255,255};
// int iSpecTeamColor[4] = {255,228,151,255}; //int iSpecTeamColor[4] = {170,170,170,255}; //Alt color

// int g_iBeam;
// int g_iHalo;

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Rage Heavy",
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
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST; 

	AddRobot(robot, MakeGRageH, PLUGIN_VERSION, restrictions);
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
//	CreateNative("BeGRageH_MakeGRageH", Native_SetGRageH);
//	CreateNative("BeGRageH_IsGRageH", Native_IsGRageH);
	return APLRes_Success;
}
 
public OnMapStart()
{
	PrecacheModel(GRageH);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	PrecacheSound("mvm/giant_heavy/giant_heavy_step01.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step03.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step02.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step04.wav");

	// PrecacheSound(SOUND_GUNFIRE);
	// PrecacheSound(SOUND_GUNSPIN);
	// PrecacheSound(SOUND_WINDUP);
	// PrecacheSound(SOUND_WINDDOWN);
	// g_iBeam = PrecacheModel("materials/sprites/laser.vmt");
	// g_iHalo = PrecacheModel("materials/sprites/halo01.vmt");
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
	int iHealth = 5000;
	
	
	int MaxHealth = 300;
	// PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	 // PrintToChatAll("iHealth %i", iHealth);
	
	 // PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
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

	UpdatePlayerHitbox(client, scale);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	PrintHintText(client , "You are %s\n %s,", ROBOT_NAME, ROBOT_DESCRIPTION);

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

// #define Hat1 30397
#define OutDoorMan 603
#define Apparel 777

//War Goggles 30368
float g_vacuumrange = 750.0;

stock GiveGRageH(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_minigun", 202, 6, 1, 2, 120);

		// CreateRoboHat(client, Hat1, 10, 6, 0.75, 1.0, -1.0); 
		CreateRoboHat(client, OutDoorMan, 10, 6, 0.75, 1.0, -1.0); 
		CreateRoboHat(client, Apparel, 10, 6, 0.0, 1.0, -1.0); 

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon1))
		{
			// TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.3);			
			// TF2Attrib_SetByName(Weapon1, "fire rate penalty", 1.5);
			// TF2Attrib_SetByName(Weapon1, "has team color paintkit", 1.0);
			// TF2Attrib_SetByName(Weapon1, "paintkit_proto_def_index", 31.0);

								
				
			//TF2CustAttr_SetString(Weapon1, "rage fill multiplier", "2.5");
			// TF2Attrib_SetByName(Weapon1, "spread penalty", scale);

			// TF2CustAttr_SetString(Weapon1, "minigun vacuum", "interval=0.1 vacuum_range=600.0 vacuum_pull_factor=5000.0 damage_range=250.0 damage=25.0 effect_cone_deg=75.0");
			TF2CustAttr_SetString(Weapon1, "pull target on hit", "250.0");

		}
		
		PrintHintText(client, ROBOT_TIPS);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");

        if (tauntid == -1)
        {
           	 CreateTimer(1.2, Timer_Taunt_Cancel, client);
        }	  

	}
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){
		TF2_RemoveCondition(client, TFCond_Taunting);
		
	}
}

// stock bool CreateBeamRing(int client, 
// 							TFTeam iTeam = TFTeam_Spectator,
// 							float fStartRadius = 0.0, 
// 							float fEndRadius = 1000.0, 
// 							float fLifeTime = 0.2,
// 							float fWidth = 5.0,
// 							float fRaiseRing = 0.0,
// 							bool bShowOnlyToClient = false)
// {
// 	if(!IsValidClient(client)) return false;
	
	
// 	int iStartFrame = 0;
// 	int iFrameRate = 30;
// 	int iSpeed = 5;
	
// 	float fOrigin[3];
// 	float fAmplitude = 0.0;
	
// 	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", fOrigin);
// 	if(fRaiseRing > 0.0) fOrigin[2] += fRaiseRing; //Raises the ring from the floor
	
// 	switch(iTeam)
// 	{
// 		case TFTeam_Red:
// 		{
// 			TE_SetupBeamRingPoint(fOrigin, 
// 			fStartRadius, 
// 			fEndRadius, 
// 			g_iBeam, 
// 			g_iHalo, 
// 			iStartFrame, 
// 			iFrameRate, 
// 			fLifeTime, 
// 			fWidth, 
// 			fAmplitude, 
// 			iREDTeamColor, 
// 			iSpeed, FBEAM_HALOBEAM);
			
// 			if(bShowOnlyToClient)
// 			{
// 				TE_SendToClient(client);
// 			}
// 			else
// 			{
// 				TE_SendToAll();
// 			}
			
// 			return true;
// 		}
// 		case TFTeam_Blue:
// 		{
// 			TE_SetupBeamRingPoint(fOrigin, 
// 			fStartRadius, 
// 			fEndRadius, 
// 			g_iBeam, 
// 			g_iHalo, 
// 			iStartFrame, 
// 			iFrameRate, 
// 			fLifeTime, 
// 			fWidth, 
// 			fAmplitude, 
// 			iBLUTeamColor, 
// 			iSpeed, FBEAM_HALOBEAM);
			
// 			if(bShowOnlyToClient)
// 			{
// 				TE_SendToClient(client);
// 			}
// 			else
// 			{
// 				TE_SendToAll();
// 			}
			
// 			return true;
// 		}
// 		default:
// 		{
// 			TE_SetupBeamRingPoint(fOrigin, 
// 			fStartRadius, 
// 			fEndRadius, 
// 			g_iBeam, 
// 			g_iHalo, 
// 			iStartFrame, 
// 			iFrameRate, 
// 			fLifeTime, 
// 			fWidth, 
// 			fAmplitude, 
// 			iSpecTeamColor, 
// 			iSpeed, FBEAM_HALOBEAM);
			
// 			if(bShowOnlyToClient)
// 			{
// 				TE_SendToClient(client);
// 			}
// 			else
// 			{
// 				TE_SendToAll();
// 			}
// 		}
// 	}
// 	return false;
// }
// float g_lastbeam = 0.0;
// float g_beamcooldown = 0.5;
// public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
// {
// 	if (IsValidClient(iClient) && IsRobot(iClient, ROBOT_NAME) && IsPlayerAlive(iClient))
// 	{	

// 	new weapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
// 	if (HasEntProp(weapon, Prop_Send, "m_iWeaponState"))
// 	{
// 	if(IsValidEntity(weapon))//850 == deflector
// 	{
// 		new iWeaponState = GetEntProp(weapon, Prop_Send, "m_iWeaponState");
// 		if (iWeaponState == 1)
// 		{
			
// 		}
// 		else if (iWeaponState == 2 )
// 		{
// 			if (g_lastbeam < GetEngineTime())
// 			{
// 				CreateBeamRing(iClient);
// 				g_lastbeam = GetEngineTime() + g_beamcooldown;
// 			}
// 		}
// 		else if (iWeaponState == 3)
// 		{

// 		}
// 		else if (iWeaponState == 0)
// 		{

// 		}
		
// 	}
// 	}

// 	}
// 	return Plugin_Continue;
// }