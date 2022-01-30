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
#define ROBOT_NAME	"Hoovy"
#define ROBOT_ROLE "Disruptor"
#define ROBOT_DESCRIPTION "Robot Hoovy"
 
#define GDEFLECTORH      "models/bots/heavy/bot_heavy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

#define SOUND_GUNFIRE	")mvm/giant_heavy/giant_heavy_gunfire.wav"
#define SOUND_GUNSPIN	")mvm/giant_heavy/giant_heavy_gunspin.wav"
#define SOUND_WINDUP	")mvm/giant_heavy/giant_heavy_gunwindup.wav"
#define SOUND_WINDDOWN	")mvm/giant_heavy/giant_heavy_gunwinddown.wav"

#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

#define sBoomNoise1  "weapons/tacky_grenadier_explode1.wav"
#define sBoomNoise2  "weapons/tacky_grenadier_explode2.wav"
#define sBoomNoise3  "weapons/tacky_grenadier_explode3.wav"

#define ALLFATHER 647
#define BMOC 97
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

	HookEvent("player_death", Event_Death, EventHookMode_Post);

    AddNormalSoundHook(BossGPS);

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

    AddRobot(robot, MakeGDeflectorH, PLUGIN_VERSION, null, 2);


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
	PrecacheModel(GDEFLECTORH);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	PrecacheSound(sBoomNoise1);
	PrecacheSound(sBoomNoise2);
	PrecacheSound(sBoomNoise3);

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
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.65);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 1.1);
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	//TF2Attrib_SetByName(client, "head scale", 0.75);
	TF2Attrib_SetByName(client, "hand scale", 1.25);
	
	UpdatePlayerHitbox(client, 1.65);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	TF2_AddCondition(client, TFCond_CritCanteen);

	PrintHintText(client , "Punch people\nMake them laugh\nTaunt kill them to create a massive boom!");

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
		
		float TeamPaint = -1.0;

		// if (iTeam == TFTeam_Blue){
		// 	TeamPaint = 5801378.0;
			
		// }
		// if (iTeam == TFTeam_Red){
			
		// 	TeamPaint = 12073019.0;
		// }


		//void  CreateRoboHat(int client, int itemindex, int level, int quality, float paint, float scale, float style);
		//Default robo head scale = 0.75
		CreateRoboHat(client, ALLFATHER, 10, 6, 16738740.0, 1.0, -1.0);//Rotation sensation
		CreateRoboHat(client, BMOC, 10, 6, 0.0, 0.0, -1.0);//Summer shades
	//	CreateRoboHat(client, GIFTBRINGER, 10, 6, 0.0, 1.0, -1.0);//Weightroom warmer
		//Weapon Code
		//CreateRoboWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, float style (-1.0 for none) );
		CreateRoboWeapon(client, "tf_weapon_fists", 656, 6, 1, 0, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);	
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.3);
		}
	}
}
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	
	char weapon_logname[MAX_NAME_LENGTH];
	GetEventString(event, "weapon_logclassname", weapon_logname, sizeof(weapon_logname));

	//PrintToChatAll("Logname %s", weapon_logname);
	//int weaponID = GetEntPropEnt(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	//PrintToChatAll("Attacker %N , weaponID %i, logname: %s", attacker, weaponID, weapon_logname);

	if (IsRobot(attacker, ROBOT_NAME) && StrEqual(weapon_logname,"taunt_heavy"))
	{
		//PrintToChatAll("Drop the bomb");	
	Handle infokv = CreateKeyValues("infokv");
	KvSetNum(infokv, "attacker", attacker);
	KvSetNum(infokv, "victim", victim);
	CreateTimer(0.0, HoovyBoom, infokv);
	}
}

public Action HoovyBoom(Handle timer, any data)
{
	Handle infokv = data;
	int attacker = KvGetNum(infokv, "attacker");
	int victim = KvGetNum(infokv, "victim");
	float pos1[3];
	float pos22[3];
	GetClientAbsOrigin(attacker, pos1); // hack: make the explosion actually come from the attacker, that way we only have to hook one client
	GetClientAbsOrigin(victim, pos22);

	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", "ExplosionCore_Wall");
	AcceptEntityInput(particle, "Start");
	TeleportEntity(particle, pos22, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	float pos2[3];
//	float ignitetime = GetConVarFloat(FindConVar("sharpened_volcano_fragment_firetime"));
	
	for(int client = 1 ; client <= MaxClients ; client++ )
	{
		if(IsClientInGame(client))
		{
			GetClientAbsOrigin(client, pos22);
			if(GetVectorDistance(pos1, pos22) <= 500.0 && TF2_GetClientTeam(attacker) != TF2_GetClientTeam(client))
			{
				SDKHooks_TakeDamage(client, 0, attacker, 650.0, 0, -1);
				
				// ClientCommand(client, "playgamesound weapons/explode1.wav");
				//ClientCommand(client, "playgamesound %s", sound);
				int soudswitch = GetRandomInt(1,3);


				switch(soudswitch)
				{
					case 1:
					{
						EmitAmbientSound(sBoomNoise1, pos22, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
					}
					case 2:
					{
						EmitAmbientSound(sBoomNoise2, pos22, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
					}
					case 3:
					{
						EmitAmbientSound(sBoomNoise3, pos22, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
					}
				}
				
				//return Plugin_Changed;

			}
		}
	}
}

// public TF2_OnConditionAdded(client, TFCond:condition)
// {
//     if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
//     {	
//         int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");

// 	PrintToChatAll("Taunt ID %i", tauntid);
	

//         if (tauntid == -1)
//         {
// 		//	TF2_AddCondition(client, TFCond_SpawnOutline, 10);
//            	 //CreateTimer(0.5, Timer_Taunt_Cancel, client);
//         }	  

// 	}
// }

// public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
// {
// 	if (IsValidClient(client)){
// 		TF2_RemoveCondition(client, TFCond_Taunting);
		
// 	}
// }
