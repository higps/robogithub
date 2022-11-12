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
#define ROBOT_NAME	"Bearded Expense"
#define ROBOT_ROLE "Tank"
#define ROBOT_CLASS "Heavy"
#define ROBOT_SUBCLASS "Melee"
#define ROBOT_DESCRIPTION "Taunt: Leap Ability"
#define ROBOT_TIPS "You are a Tank!\nYou can't contest objectives\nUse taunt to leap. Land on players to kill everything!\nInfinite battalions backup buff!"
 
#define SHWC             "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN	"mvm/mvm_tank_horn.wav"
#define DEATH       "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/mvm_tank_loop.wav"
// #define SOUND_LEAP  "TFPlayer.AirBlastImpact"


#define sBoomNoise  "weapons/explode3.wav"
#define ALARM2      "mvm/mvm_cpoint_klaxon.wav"
#define JUMP2        "items/powerup_pickup_king.wav"

#define JUMP  "lunge.wav"
#define ALARM       "om_chant.wav"

#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

#define HOUNDDOG 145
#define ELDUDERINO 30645
#define THEHEAVYLIFTER 30342
#define WEIGHTROOMWARMER 30178

Handle g_hGameConf;
Handle g_hIsDeflectable;

public Plugin:myinfo =
{
	name = "[TF2] Be the Juggernaut Bearded Expense",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Unused Juggernaut Bearded Expense Champ from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	AddNormalSoundHook(BossBearded);

	HookEvent("player_death", Event_Death, EventHookMode_Post);

	g_hGameConf = LoadGameConfigFile("bm_charge_airblast_immunity_data");

	//IsDeflectable
	g_hIsDeflectable = DHookCreate(0, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, IsPlayerDeflectable);
	if(g_hIsDeflectable == null) SetFailState("Failed to setup hook for CTFPlayer::IsDeflectable!"); 

	if(!DHookSetFromConf(g_hIsDeflectable, g_hGameConf, SDKConf_Virtual, "CTFPlayer::IsDeflectable"))
	SetFailState("Failed to find CTFPlayer::IsDeflectable offset in the gamedata!");

	//Finds players to hook for IsDeflectable
	FindAndHookPlayers();

	delete g_hGameConf;

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	AddRobot(robot, MakeBearded, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

void FindAndHookPlayers()
{
	for(int i = 1; i <= MaxClients+1; i++)
	{
		if(IsValidClient(i))
		{
			DHookEntity(g_hIsDeflectable, false, i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	DHookEntity(g_hIsDeflectable, false, client);
}

public MRESReturn IsPlayerDeflectable(int pThis, Handle hReturn, Handle hParams)
{
	if(IsRobot(pThis, ROBOT_NAME))
	{
		//PrintToChatAll("Shouldn't airblast target %N", pThis);
		
		DHookSetReturn(hReturn, false);
		
		return MRES_Override;
	}
	return MRES_Ignored;
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheModel(SHWC);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	PrecacheSound("mvm/giant_heavy/giant_heavy_step01.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step03.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step02.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step04.wav");

	PrecacheSound(sBoomNoise);
	PrecacheSound(ALARM);
	PrecacheSound(JUMP);
	// PrecacheSound(SOUND_LEAP);
}

public Action:BossBearded(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
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
 
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	// int weaponID = GetEventInt(event, "weapon_def_index");

	// char weapon_logname[MAX_NAME_LENGTH];
	// GetEventString(event, "weapon_logclassname", weapon_logname, sizeof(weapon_logname));

	
	//int weaponID = GetEntPropEnt(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	//PrintToChatAll("Attacker %N , weaponID %i, logname: %s", attacker, weaponID, weapon_logname);

	// if (IsRobot(attacker, ROBOT_NAME) && StrEqual(weapon_logname,"mantreads"))
	// {
	// 	//PrintToChatAll("Drop the bomb");
		
	// 	Handle infokv = CreateKeyValues("infokv");
	// 	KvSetNum(infokv, "attacker", attacker);
	// 	KvSetNum(infokv, "victim", victim);
	// 	CreateTimer(0.0, BeardedBoom, infokv);

	// 	SDKHooks_TakeDamage(attacker, 0, attacker, 120.0, 0, -1);
	// }

	if (IsRobot(attacker, ROBOT_NAME))
	{
		//PrintToChatAll("applying slowed");
		
		TF2_AddCondition(attacker, TFCond_Slowed, 10.0);
		PrintHintText(victim,"Bearded Expense has weakness to melee damage");
	}
	
	
}

public Action BeardedBoom(Handle timer, any data)
{
	Handle infokv = data;
	int attacker = KvGetNum(infokv, "attacker");
	int victim = KvGetNum(infokv, "victim");
	float pos1[3];
	float pos22[3];
	GetClientAbsOrigin(attacker, pos1); // hack: make the explosion actually come from the attacker, that way we only have to hook one client
	GetClientAbsOrigin(victim, pos22);

	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", "mvm_tank_destroy");
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
			GetClientAbsOrigin(client, pos2);
			if(GetVectorDistance(pos1, pos2) <= 250.0 && TF2_GetClientTeam(attacker) != TF2_GetClientTeam(client))
			{
				SDKHooks_TakeDamage(client, 0, attacker, 1500.0, 0, -1);
				
				// ClientCommand(client, "playgamesound weapons/explode1.wav");
				//ClientCommand(client, "playgamesound %s", sound);
				EmitAmbientSound(sBoomNoise, pos22, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
				
				//return Plugin_Changed;

			}
		}
	}
	return Plugin_Continue;
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
 
MakeBearded(client)
{
	TF2_SetPlayerClass(client, TFClass_Heavy);
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
	SetModel(client, SHWC);
   
		
	int iHealth = 5000;
	TF2_SetHealth(client, iHealth);
	
	int MaxHealth = 300;
	int iAdditiveHP = iHealth - MaxHealth;
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);

	TF2Attrib_SetByName(client, "damage force reduction", 0.1);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.0);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 0.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
	TF2Attrib_SetByName(client, "boots falling stomp", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);

	TF2Attrib_SetByName(client, "increased air control", 5.0);
	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.5);
	// TF2Attrib_SetByName(client, "increased jump height", 0.5);

	UpdatePlayerHitbox(client, 1.75);
	
	//Tank Stats
	SetTankStats(client);
	TF2_AddCondition(client,TFCond_DefenseBuffNoCritBlock);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	

	PrintHintText(client, ROBOT_TIPS);

	
	
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
			GiveBearded(client);
}
 
stock GiveBearded(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		CreateRoboWeapon(client, "tf_weapon_fists", 239, 6, 1, 2, 0);



	// 	CreateHat(client, 145, 10, 6, 1315860.0, true);
	// //	CreateHat(client, 30178, 10, 6, 1315860);
	// 	CreateHat(client, 30645, 10, 6, 1315860.0, true);

		CreateRoboHat(client, HOUNDDOG, 10, 6, 1315860.0, 0.75, 0.0);
		CreateRoboHat(client, ELDUDERINO, 10, 6, 1315860.0, 0.75, 0.0);

		int iTeam = GetClientTeam(client);
		int suit = 0;
	
		switch(iTeam)
		{
			case 2://RED
			{
				//PrintToChatAll("Team was 2");
				suit = THEHEAVYLIFTER;// The Heavy Lifter
			}
			case 3://BLUE
			{
				//PrintToChatAll("Team was 3");
				suit = WEIGHTROOMWARMER;//weight room warmer
			}
		}
		CreateRoboHat(client, suit, 10, 6, 0.0, 0.0, 0.0);
		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

//		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

		if(IsValidEntity(Weapon3))
		{
			// TF2Attrib_RemoveAll(Weapon3);
			
				
			// TF2Attrib_SetByName(Weapon3, "fire rate bonus", 1.2);
			TF2Attrib_SetByName(Weapon3, "move speed bonus", 0.693);
			TF2Attrib_SetByName(Weapon3, "damage penalty", 1.5);
			TF2Attrib_SetByName(Weapon3, "critboost on kill", 10.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			// TF2Attrib_SetByName(Weapon3, "speed_boost_on_kill", 10.0);
			// TF2Attrib_SetByName(Weapon3, "speed_boost_on_hit", 10.0);
			TF2Attrib_SetByName(Weapon3, "heal on kill", 400.0);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.4);
			// TF2Attrib_SetByName(Weapon3, "dmg pierces resists absorbs", 1.0);
			// TF2Attrib_SetByName(Weapon3, "gesture speed increase", 0.8);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.5);
			

			
			TF2Attrib_SetByName(Weapon3, "mod_maxhealth_drain_rate", 0.0);
			//SetEntPropFloat(Weapon3, Prop_Send, "m_flModelScale", 2.75);

			TF2CustAttr_SetString(Weapon3, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			TF2CustAttr_SetString(Weapon3, "shake on hit", "amplitude=20.0 frequency=5.0 duration=1.0");

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
//	 TF2_AddCondition(client,TFCond_DefenseBuffed, 20.0);
	TF2_AddCondition(client, TFCond_MegaHeal);




	/* 	float pos[3];
	GetClientEyePosition(client, pos);
	int clients[64]; */
	//EmitGameSoundToClient(client, ALARM);
	int clients[1];
	clients[0] = client;

	
	//EmitSound(clients, 1, ALARM, client, SNDCHAN_AUTO, SNDLEVEL_WHISPER, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	//EmitGameSound(client, MaxClients, ALARM, client, SND_NOFLAGS, client, pos)
	//EmitGameSound(clients, numClients, sample, client, channel, SNDLEVEL_CONVO);
//	CreateTimer(1.1, Timer_Alarm, client, TIMER_REPEAT);
	// TF2_AddCondition(client, TFCond_GrapplingHookSafeFall, TFCondDuration_Infinite);
	   //TFCond_CritHype
	  // TF2_AddCondition(client,TFCond_HalloweenSpeedBoost, 15.0);

	EmitSoundToAll(ALARM, client);
	EmitSoundToAll(ALARM, client);

	//EmitSoundToAll("misc/bonzo_vomit01.wav", _, _, 5, _, 10.0);
	CreateTimer(2.3, Timer_Taunt_Cancel, client);
	}

        if (tauntid == -1)
        {
            //TF2_AddCondition(client,TFCond_DefenseBuffed, 120.0);
            

          //  CreateTimer(1.1, Timer_Alarm, client, TIMER_REPEAT);
            // TF2_AddCondition(client, TFCond_GrapplingHookSafeFall, TFCondDuration_Infinite);
            //TFCond_CritHype
            // TF2_AddCondition(client,TFCond_HalloweenSpeedBoost, 15.0);
            CreateTimer(2.3, Timer_Taunt_Cancel, client);
        }	  
    }
}


public Action:Timer_Alarm(Handle:timer, any:client)
{
    static int cap = 0;

    if(TF2_IsPlayerInCondition(client, TFCond_Taunting))EmitSoundToAll(ALARM);

    if (cap >= 1)
    {
        cap = 0;
        return Plugin_Stop;
    }
    cap++;
    return Plugin_Continue;
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){
		TF2_RemoveCondition(client, TFCond_Taunting);
		TF2_RemoveCondition(client, TFCond_MegaHeal);
	}
	

	
	float vOrigin[3], vAngles[3], vForward[3], vVelocity[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	// Get the direction we want to go
	GetAngleVectors(vAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	
	// make it usable
	float flDistance = 350.0;
		if (TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly))
	{
		flDistance *= 1.5;
	}

	ScaleVector(vForward, flDistance);	
	
	// add it to the current velocity to avoid just being able to do full 180s
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
	AddVectors(vVelocity, vForward, vVelocity);
	
	float flDistanceVertical = 150.0;
		
	vVelocity[2] += flDistanceVertical; // we always want to go a bit up
	
	// And set it


	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	//EmitGameSoundToAll(SOUND_LEAP,client);
	EmitSoundToAll(JUMP,client);
	EmitSoundToAll(JUMP,client);
	EmitSoundToAll(JUMP,client);
}       



public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		if (IsRobot(attacker, ROBOT_NAME) && damagecustom == TF_CUSTOM_BOOTS_STOMP)
		{
		Handle infokv = CreateKeyValues("infokv");
		KvSetNum(infokv, "attacker", attacker);
		KvSetNum(infokv, "victim", victim);
		CreateTimer(0.0, BeardedBoom, infokv);

		SDKHooks_TakeDamage(attacker, 0, attacker, 120.0, 0, -1);
		}

	}
	return Plugin_Continue;
}