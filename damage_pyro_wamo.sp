#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
//#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Wamo"
#define ROBOT_ROLE "Damage"
#define ROBOT_DESCRIPTION "Plhogistinator, Flaregun"

#define GPYRO		"models/bots/pyro_boss/bot_pyro_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_pyro/giant_pyro_loop.wav"

#define SOUND_GUNFIRE	")mvm/giant_pyro/giant_pyro_flamethrower_loop.wav"
#define SOUND_WINDUP	")mvm/giant_pyro/giant_pyro_flamethrower_start.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant Wamo Pyro",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Wamo Pyro from Kritzkast",
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

new bool:Locked1[MAXPLAYERS+1];
new bool:Locked2[MAXPLAYERS+1];
new bool:Locked3[MAXPLAYERS+1];
new bool:CanWindDown[MAXPLAYERS+1];

public OnPluginStart()
{
    //aSMLOGgerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

    LoadTranslations("common.phrases");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Pyro";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.gunfire = SOUND_GUNFIRE;
    robot.sounds.windup = SOUND_WINDUP;
    robot.sounds.death = DEATH;
    AddRobot(robot, MakeGiantPyro, PLUGIN_VERSION);
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
	PrecacheModel(GPYRO);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	PrecacheSound("^mvm/giant_common/giant_common_step_01.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_02.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_03.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_04.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_05.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_06.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_07.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_08.wav");
	
	PrecacheSound(SOUND_GUNFIRE);
	PrecacheSound(SOUND_WINDUP);
	
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
	//aSMLOGTag(SML_VERBOSE, "Createing Wamo");
	TF2_SetPlayerClass(client, TFClass_Pyro);
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
	TF2Attrib_SetByName(client, "move speed penalty", 0.6);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.8);
float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 6.0);
	
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client , "Flaregun homes in on targets on fire");
	
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

#define FlameboyantFlamenco 627
#define LastBreath 570
#define SubzeroSuit 30305

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_flamethrower", 594, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_flaregun_revenge", 595, 6, 1, 2, 0);

		CreateRoboHat(client, FlameboyantFlamenco, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, LastBreath, 10, 6, 0.0, 1.0, -1.0); 
		CreateRoboHat(client, SubzeroSuit, 10, 6, 0.0, 1.0, -1.0); 

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 2.00);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			//TF2Attrib_SetByName(Weapon1, "mod flamethrower back crit", 1.0);		
			
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);			
			TF2Attrib_SetByName(Weapon1, "flame_spread_degree", 8.0);			
			TF2Attrib_SetByName(Weapon1, "flame size bonus", 1.3);
			
			TF2Attrib_SetByName(Weapon1, "weapon burn dmg reduced", 1.0);
			TF2Attrib_SetByName(Weapon1, "mult airblast refire time", 1.2);
			
		}
		
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 1.5);
			TF2Attrib_SetByName(Weapon2, "mod projectile heat seek power", 360.0);
			
		//	TF2Attrib_SetByName(Weapon2, "Projectile speed decreased", 0.75);
		}
	}
}
public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
{
	if (IsValidClient(iClient) && IsRobot(iClient, ROBOT_NAME) && IsPlayerAlive(iClient)) 
	{	
		new weapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
		int iWeapon = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");



		// if(IsValidEntity(weapon))
		// {
			
			if (HasEntProp(weapon, Prop_Send, "m_iWeaponState"))
			{
		// 		if (iWeapon == 594)//594 == phlogistinator
		// 		{

				if(IsValidEntity(weapon) && iWeapon == 594)//215 == flamethrower
				{


				new iWeaponState = GetEntProp(weapon, Prop_Send, "m_iWeaponState");
				if (iWeaponState == 1 && !Locked1[iClient])
				{
					EmitSoundToAll(SOUND_WINDUP, iClient);
				//	PrintToChatAll("WeaponState = Windup");
					
					Locked1[iClient] = true;
					Locked2[iClient] = false;
					Locked3[iClient] = false;
					CanWindDown[iClient] = true;
					
					StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
				}
				else if (iWeaponState == 2 && !Locked2[iClient])
				{
					EmitSoundToAll(SOUND_GUNFIRE, iClient);
				//	PrintToChatAll("WeaponState = Firing");
					
					Locked2[iClient] = true;
					Locked1[iClient] = true;
					Locked3[iClient] = false;
					CanWindDown[iClient] = true;
					
					StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
				}
				else if (iWeaponState == 3 && !Locked3[iClient])
				{

				//	PrintToChatAll("WeaponState = Spun Up");
					
					Locked3[iClient] = true;
					Locked1[iClient] = true;
					Locked2[iClient] = false;
					CanWindDown[iClient] = true;
					
					StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
					StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
				}
				else if (iWeaponState == 0)
				{
					if (CanWindDown[iClient])
					{
				//		PrintToChatAll("WeaponState = WindDown");

						CanWindDown[iClient] = false;
					}
					
					StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
					
					Locked1[iClient] = false;
					Locked2[iClient] = false;
					Locked3[iClient] = false;

				}
			}
		}
	}
}

