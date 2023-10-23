#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Samwiz"
#define ROBOT_ROLE "Damage"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Hitscan"
#define ROBOT_DESCRIPTION "Banana Brass Beast"
#define ROBOT_TIPS "Can't move while spun up\nFast spin up time\nBanana Powers"
#define ROBOT_ON_DEATH "Samwiz can't move while revved\nSamwiz's Banana mode spawns banana bombs above you on hit"
 
#define GDEFLECTORH      "models/bots/heavy/bot_heavy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"
#define BANANA_MODEL "models/items/banana/banana.mdl"

#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"



public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Samwiz",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Samwiz from youtube",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.difficulty = ROBOT_DIFFICULTY_EASY;

	AddRobot(robot, MakeGHeavy, PLUGIN_VERSION, null);
}

public void OnMapStart()
{
	PrecacheModel(BANANA_MODEL);
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
	RoboSetHealth(client, TFClass_Heavy, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.65);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.2);

	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	UpdatePlayerHitbox(client, 1.75);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client , "+75 percent damage done\nCan't move while shooting\n50% dmg resist while spun up undher half HP");

}
 
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGDeflectorH(client);
}

#define Tsarboosh 30081
#define DeadofNight 30309
#define WildWestWhiskers 30960
#define BananaHat 30643

bool g_BananaMode = false;
float g_DamageDone = 0.0;

stock GiveGDeflectorH(client)
{
	if (IsValidClient(client))
	{
		//Remove items and hats
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		g_DamageDone = 0.0;

		CreateRoboHat(client, Tsarboosh, 10, 6, 15185211, 15185211, 1.0, -1.0);
		CreateRoboHat(client, DeadofNight, 10, 6, 15185211, 15185211, 1.0, -1.0);
		CreateRoboHat(client, WildWestWhiskers, 10, 6, 0.0, 0.0, 1.0, -1.0);
		CreateRoboHat(client, BananaHat, 10, 6, 0.0, 0.0, 1.0, -1.0);
		RequestFrame(FindHat, client);
	
		CreateRoboWeapon(client, "tf_weapon_minigun", 312, 6, 1, 0, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.5);
			TF2Attrib_SetByName(Weapon1, "damage bonus", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.75);
			TF2Attrib_SetByName(Weapon1, "minigun spinup time increased", 0.1);
			TF2Attrib_SetByName(Weapon1, "aiming movespeed decreased", 0.01);
			TF2Attrib_SetByName(Weapon1, "spunup_damage_resistance", 0.75);
		}
	}
}
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



public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME))
	{

	if (g_BananaMode)
	{
		SpawnBombs(victim, attacker);
	}else
	{
		g_DamageDone += damage;
	}
	}
	return Plugin_Continue;
}

void SetProjectileModel (int iEntity)
{
	SetEntityModel(iEntity, BANANA_MODEL);
}

void SpawnBombs(int client, int attacker)
{
	
	int team = GetClientTeam(attacker);
	float pos[3], vel[3], ang[3];
	int children = 1;
	float speed = 250.0;


	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	

	pos[2] += 120.0;
	for (int i = 1; i <= children; i++)
	{
		int child = CreateEntityByName("tf_projectile_pipe");
		
		
		float child_vel[3];
		float child_ang[3];

		//Prevent child grenades from detonating on contact
		SetEntProp(child, Prop_Send, "m_bTouched", 1);

		//Set properties
		//SetEntProp(child, Prop_Send, "m_bCritical", view_as<int>(crit));
		SetEntPropEnt(child, Prop_Data, "m_hOwnerEntity", attacker);
		SetEntPropFloat(child, Prop_Send, "m_flDamage", 100.0);
		SetEntPropFloat(child, Prop_Send, "m_flModelScale", 1.2);

		for (int axis = 0; axis < 3; axis++){

			child_vel[axis] = vel[axis] + GetRandomFloat(speed * -1.0, speed);
			child_ang[axis] = ang[axis] + GetRandomFloat(0.0 , 360.0);
		}
		child_vel[2] = FloatAbs(child_vel[2]);

		SetEntProp(child, Prop_Send, "m_iTeamNum", team);
		SetEntProp(child, Prop_Send, "m_bIsLive", 1);

		DispatchSpawn(child);
		//SDKHook(child, SDKHook_Touch, OnMirvOverlap);
		TeleportEntity(child, pos, child_ang, child_vel);
		RequestFrame(SetProjectileModel, child);
	}
}


bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_duration = 12.0;
float FireModeTimer = -1.0;
float g_skill; 
float g_skill_cooldown = 600.0;
// float g_skill_time;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		if( GetEntProp(client, Prop_Data, "m_afButtonPressed") & (IN_ATTACK3|IN_USE)) 
		{
			// PrintToChatAll("Press");
            g_button_held[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased") & (IN_ATTACK3|IN_USE)) 
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
	
	Format(sHUDText, sizeof(sHUDText), "Banana Mode: %i %%%%\n    %s",iPercents, sProgress);

	if(iPercents >= 100)
	{

			if (g_BananaMode){
				Format(sHUDText, sizeof(sHUDText), "Banana Mode! %i", iCountDownFiring);
				SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 0, 255);
			}else{
				Format(sHUDText, sizeof(sHUDText), "Banana Mode Ready!\nUse Special Attack to Activate!");
				SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);	
				}


			
	}else {

		SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 255, 255);
	}

	if (g_button_held[client] && iPercents >= 100 && !g_BananaMode)
		{
			if (FireModeTimer <= GetEngineTime() || FireModeTimer == -1.0)
			{
				
				EnterBananaMode(client);
			
			}
		}

	if (FireModeTimer <= GetEngineTime() && g_BananaMode)
	{
		g_BananaMode = false;
		g_DamageDone = 0.0;
		FindHat(client);
	}


	ShowHudText(client, -3, sHUDText);
	// b_hud_clamp[client] = false;
}

void EnterBananaMode(int client)
{

	// g_skill_time = g_duration;
	g_BananaMode = true;
	FireModeTimer = GetEngineTime() + g_duration;
	FindHat(client);


}

public FindHat(int iClient)
{
	int iWearableItem = -1;
	// PrintToServer("LOOKING HAT 1 !");
	while ((iWearableItem = FindEntityByClassname(iWearableItem, "tf_wearable*")) != -1) // Regular hats.
	{	
		// We check for the wearable's item def index and its owner.
		int iWearableIndex = GetEntProp(iWearableItem, Prop_Send, "m_iItemDefinitionIndex");
		int iWearableOwner = GetEntPropEnt(iWearableItem, Prop_Send, "m_hOwnerEntity");
		// PrintToServer("LOOKING HAT 2 !");
		// If the owners match.
		if (iWearableOwner == iClient)
		{
			// Going through all items. 4 = cosmetics
			for (int i = 0; i < 4; i++)
			{			
				// PrintToServer("LOOKING HAT 3 !");
				// If a weapon's definition index matches with the one stored...
				if (iWearableIndex == BananaHat)
				{
					// PrintToServer("FOUND HAT! %i", iWearableItem);
					if (g_BananaMode){
						SetEntityRenderMode(iWearableItem, RENDER_NORMAL);
					}else
					{
						SetEntityRenderMode(iWearableItem, RENDER_NONE);
					}
					//SetEntityRenderFx(iWearableItem, RENDER_TRANSALPHA);
					// return true;
				}
			}
		}
	}
	// return false;
}
