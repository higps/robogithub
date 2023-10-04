#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Kommisar Krit"
#define ROBOT_ROLE "ZBOSS"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Slow Crit Minigun"
#define ROBOT_TIPS "Crit Minign"
#define ROBOT_ON_DEATH "Kommisar Krit's walk speed is very slow, so use corners and range to your advantage"


//#define MODEL "models/weapons/shells/shell_minigun.mdl"

//#define TF_THROWABLE_BREAD_ENTITY "tf_projectile_throwable_breadmonster"

#define GDEFLECTORH      "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN   "mvm/ambient_mp3/mvm_siren.mp3"
#define DEATH   "mvm/mvm_tank_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"
#define DEATHBOOM "fireSmokeExplosion2"

#define SOUND_GUNFIRE	")mvm/giant_heavy/giant_heavy_gunfire.wav"
#define SOUND_GUNSPIN	")mvm/giant_heavy/giant_heavy_gunspin.wav"
#define SOUND_WINDUP	")mvm/giant_heavy/giant_heavy_gunwindup.wav"
#define SOUND_WINDDOWN	")mvm/giant_heavy/giant_heavy_gunwinddown.wav"

#define Uclanka 840
#define CommisarsCoat 30633
#define TheLittleBear 1097

float scale = 1.85;

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Kommisar Krit Heavy",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

new bool:Locked1[MAXPLAYERS+1];
new bool:Locked2[MAXPLAYERS+1];
new bool:Locked3[MAXPLAYERS+1];
new bool:CanWindDown[MAXPLAYERS+1];
 
public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = "Heavy";
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.gunfire = SOUND_GUNFIRE;
	robot.sounds.gunspin = SOUND_GUNSPIN;
	robot.sounds.windup = SOUND_WINDUP;
	robot.sounds.winddown = SOUND_WINDDOWN;
	robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.difficulty = ROBOT_DIFFICULTY_EASY;
	//robot.deatheffect = DEATHBOOM;

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
    // restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
    // restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
    restrictions.TeamCoins = new RobotCoinRestrictionDefinition();
    restrictions.TeamCoins.Overall = 2;

	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = 4.0;

	AddRobot(robot, MakeBigBigJoey, PLUGIN_VERSION, restrictions);

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGDeflectorH_MakeBigBigJoey", Native_SetGDeflectorH);
//	CreateNative("BeGDeflectorH_IsGDeflectorH", Native_IsGDeflectorH);
	return APLRes_Success;
}
 
public OnMapStart()
{
//






	
	


	PrecacheSound(SOUND_GUNFIRE);
	PrecacheSound(SOUND_GUNSPIN);
	PrecacheSound(SOUND_WINDUP);
	PrecacheSound(SOUND_WINDDOWN);
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

MakeBigBigJoey(client)
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
	RoboSetHealth(client,TFClass_Heavy, 7500, 1.5);
	
	
	// PrintToChatAll("MaxHealth %i", MaxHealth);
	
	
	 // PrintToChatAll("iHealth %i", iHealth);
	
	 // PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.7);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.1);

	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);

	TF2Attrib_SetByName(client, "health from healers reduced", 0.0);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	
	TF2Attrib_SetByName(client, "hand scale", 1.3);

	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	//TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "healing received penalty", 0.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	//TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	UpdatePlayerHitbox(client, scale);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	TF2_AddCondition(client, TFCond_CritCanteen);
	
	PrintHintText(client, ROBOT_TIPS);

	//int clientId = GetClientUserId(client);
	//SetBossHealth(client);
//	ServerCommand("sm_setbosshud #%i",clientId);
	//g_IsGPS[client] = true;
	
/* 		PrintToChat(client, "1. You are now Giant Deflector GPS!");
		PrintToChat(client, "2. Your Minigun deals 50 percent more damage and can destroy Rockets and Pipes !");
		PrintToChat(client, "3. You will lose this status when you touch a locker");	 */
	
	//}
	// else{
	// PrintToChat(client, "You have to be heavy to become Deflector GPS");
	// g_IsGPS[client] = false;
	// }
}
 
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveBigJoey(client);
}
 
stock GiveBigJoey(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);


//bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot)

		//424 tomislav
		CreateRoboWeapon(client, "tf_weapon_minigun", 298, 9, 1, 0, 0);
	//	CreateRoboWeapon(client, "tf_weapon_shotgun_hwg", 863, 9, 1, 1, 0);

		CreateRoboHat(client, Uclanka, 10, 6, 0.0, 0.75, -1.0); 
		CreateRoboHat(client, CommisarsCoat, 10, 6, 0.75, 1.0, -1.0); 
		//CreateRoboHat(client, TheLittleBear, 10, 6, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	//	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weapon1))
		{
			//TF2Attrib_SetByName(Weapon1, "fire rate bonus", 2.0);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);
			//TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 0.65);
			TF2Attrib_SetByName(Weapon1, "minigun spinup time decreased", 1.25);
			TF2Attrib_SetByName(Weapon1, "mod weapon blocks healing", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.0);
			
			
		}
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");

        if (tauntid == -1)
        {
		// //	TF2_AddCondition(client, TFCond_SpawnOutline, 10);
        	CreateTimer(1.5, Timer_Taunt_Cancel, client);
        }	  
	}
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){
		TF2_RemoveCondition(client, TFCond_Taunting);
		
	}
}
