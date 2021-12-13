#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Heavy"
#define ROBOT_ROLE "Basic"
#define ROBOT_DESCRIPTION "Minigun"
 
#define GDEFLECTORH      "models/bots/heavy_boss/bot_heavy_boss.mdl"
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

// #define ROTATIONSENSATION 30623
// #define SUMMERSHADES 486
// #define WEIGHTROOMWARMER 30178

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Deflector Heavy",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
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
    robot.class = "Heavy";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    // robot.sounds.gunfire = SOUND_GUNFIRE;
    // robot.sounds.gunspin = SOUND_GUNSPIN;
    // robot.sounds.windup = SOUND_WINDUP;
    // robot.sounds.winddown = SOUND_WINDDOWN;
    robot.sounds.death = DEATH;

    AddRobot(robot, MakeGHeavy, PLUGIN_VERSION, null, 2);
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
//	CreateNative("BeGDeflectorH_MakeGHeavy", Native_SetGDeflectorH);
//	CreateNative("BeGDeflectorH_IsGDeflectorH", Native_IsGDeflectorH);
	return APLRes_Success;
}
 
public OnMapStart()
{
	PrecacheModel(GDEFLECTORH);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	// PrecacheSound("^mvm/giant_common/giant_common_step_01.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_02.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_03.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_04.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_05.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_06.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_07.wav");
	// PrecacheSound("^mvm/giant_common/giant_common_step_08.wav");
	
	PrecacheSound("mvm/giant_heavy/giant_heavy_step01.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step03.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step02.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step04.wav");

	// PrecacheSound(SOUND_GUNFIRE);
	// PrecacheSound(SOUND_GUNSPIN);
	// PrecacheSound(SOUND_WINDUP);
	// PrecacheSound(SOUND_WINDDOWN);
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

MakeGHeavy(client)
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
	int iHealth = 5000;
	
	
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

	
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	
	/* 
	5000 = 300
	5000 = 150
	5000 = 60
	 */

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth)
	//TF2Attrib_SetByName(client, "aiming movespeed increased", 1.5);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	
	
	UpdatePlayerHitbox(client, 1.75);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client , "+50 percent damage done");

}
 
stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGDeflectorH(client);
}
 
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

		//Cosmetic code
		// TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		// float TeamPaint = 0.0;

		// if (iTeam == TFTeam_Blue){
		// 	TeamPaint = 5801378.0;
			
		// }
		// if (iTeam == TFTeam_Red){
			
		// 	TeamPaint = 12073019.0;
		// }


		//void  CreateRoboHat(int client, int itemindex, int level, int quality, float paint, float scale, float style);
		//Default robo head scale = 0.75
		// CreateRoboHat(client, ROTATIONSENSATION, 10, 6, TeamPaint, 0.75, -1.0);//Rotation sensation
		// CreateRoboHat(client, SUMMERSHADES, 10, 6, 1315860.0, 0.75, -1.0);//Summer shades
		// CreateRoboHat(client, WEIGHTROOMWARMER, 10, 6, 0.0, 1.0, -1.0);//Weightroom warmer
		//Weapon Code
		//CreateRoboWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, float style (-1.0 for none) );
		CreateRoboWeapon(client, "tf_weapon_minigun", 15, 6, 1, 0, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.65);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.5);
		}
	}
}

// public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
// {
// 	if (IsValidClient(iClient) && IsRobot(iClient, ROBOT_NAME))
// 	{	
// 		new weapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
// 		int iWeapon = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

// 		if(IsValidEntity(weapon) && iWeapon == 850)//850 == deflector
// 		{
// 			new iWeaponState = GetEntProp(weapon, Prop_Send, "m_iWeaponState");
// 			if (iWeaponState == 1 && !Locked1[iClient])
// 			{
// 				EmitSoundToAll(SOUND_WINDUP, iClient);
// 			//	PrintToChatAll("WeaponState = Windup");
				
// 				Locked1[iClient] = true;
// 				Locked2[iClient] = false;
// 				Locked3[iClient] = false;
// 				CanWindDown[iClient] = true;
				
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNSPIN);
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
// 			}
// 			else if (iWeaponState == 2 && !Locked2[iClient])
// 			{
// 				EmitSoundToAll(SOUND_GUNFIRE, iClient);
// 			//	PrintToChatAll("WeaponState = Firing");
				
// 				Locked2[iClient] = true;
// 				Locked1[iClient] = true;
// 				Locked3[iClient] = false;
// 				CanWindDown[iClient] = true;
				
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNSPIN);
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
// 			}
// 			else if (iWeaponState == 3 && !Locked3[iClient])
// 			{
// 				EmitSoundToAll(SOUND_GUNSPIN, iClient);
// 			//	PrintToChatAll("WeaponState = Spun Up");
				
// 				Locked3[iClient] = true;
// 				Locked1[iClient] = true;
// 				Locked2[iClient] = false;
// 				CanWindDown[iClient] = true;
				
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
// 			}
// 			else if (iWeaponState == 0)
// 			{
// 				if (CanWindDown[iClient])
// 				{
// 			//		PrintToChatAll("WeaponState = WindDown");
// 					EmitSoundToAll(SOUND_WINDDOWN, iClient);
// 					CanWindDown[iClient] = false;
// 				}
				
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNSPIN);
// 				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
				
// 				Locked1[iClient] = false;
// 				Locked2[iClient] = false;
// 				Locked3[iClient] = false;
// 			}
// 		}
// 	}
// }

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");

	//PrintToChatAll("Taunt ID %i", tauntid);
	

        if (tauntid == -1)
        {
		//	TF2_AddCondition(client, TFCond_SpawnOutline, 10);
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


// - Regular paints -
//set item tint RGB
// A Color Similar to Slate					3100495
// A Deep Commitment to Purple					8208497
// A Distinctive Lack of Hue					1315860
// A Mann's Mint								12377523
// After Eight									2960676
// Aged Moustache Grey							8289918
// An Extraordinary Abundance of Tinge			15132390
// Australium Gold								15185211	
// Color No. 216-190-216						14204632
// Dark Salmon Injustice						15308410
// Drably Olive								8421376
// Indubitably Green							7511618
// Mann Co. Orange								13595446
// Muskelmannbraun								10843461
// Noble Hatter's Violet						5322826
// Peculiarly Drab Tincture					12955537
// Pink as Hell								16738740
// Radigan Conagher Brown						6901050
// The Bitter Taste of Defeat and Lime			3329330
// The Color of a Gentlemann's Business Pants	15787660
// Ye Olde Rustic Colour						8154199
// Zepheniah's Greed							4345659

// - Team colors -

// An Air of Debonair:
// set item tint RGB : 6637376
// set item tint RGB 2 : 2636109

// Balaclavas Are Forever
// set item tint RGB : 3874595
// set item tint RGB 2 : 1581885

// Cream Spirit
// set item tint RGB : 12807213
// set item tint RGB 2 : 12091445

// Operator's Overalls
// set item tint RGB : 4732984
// set item tint RGB 2 : 3686984

// Team Spirit
// set item tint RGB : 12073019
// set item tint RGB 2 : 5801378

// The Value of Teamwork
// set item tint RGB : 8400928
// set item tint RGB 2 : 2452877

// Waterlogged Lab Coat
// set item tint RGB : 11049612
// set item tint RGB 2 : 8626083