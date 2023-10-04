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
#define ROBOT_SUBCLASS "Tank"
#define ROBOT_DESCRIPTION "Taunt: Leap Ability"
#define ROBOT_TIPS "You can't contest objectives\nTaunt to leap!\nDeal stomp damage to make an explosion\nLong time crits on glove kills"
#define ROBOT_ON_DEATH "You can bodyblock Bearded's leap\nTanks can be stunned by shields and stomps\nTanks take double melee damage"
 
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

	HookEvent("player_death", Event_Death, EventHookMode_Post);
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
	robot.difficulty = ROBOT_DIFFICULTY_EASY;
	AddRobot(robot, MakeBearded, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheSound(sBoomNoise);
	PrecacheSound(ALARM);
	PrecacheSound(JUMP);

}
 
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsRobot(attacker, ROBOT_NAME))
	{

		
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
	float pos2[3];
	GetClientAbsOrigin(attacker, pos1); // hack: make the explosion actually come from the attacker, that way we only have to hook one client
	GetClientAbsOrigin(victim, pos22);

	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", "mvm_tank_destroy");
	AcceptEntityInput(particle, "Start");
	TeleportEntity(particle, pos22, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);
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
   
		
	int iHealth = 9000;
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);

	TF2Attrib_SetByName(client, "damage force reduction", 0.1);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.1);
	TF2Attrib_SetByName(client, "cancel falling damage", 0.0);
	
	TF2CustAttr_SetString(client, "fall-damage", "static-damage=1 static-damage-stomp=1 fall-damage=100.0 stomp-damage=125.0");
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);
	TF2Attrib_SetByName(client, "boots falling stomp", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);


	TF2Attrib_SetByName(client, "aiming movespeed increased", 2.5);
	UpdatePlayerHitbox(client, 1.75);

	//Tank stats
    TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 2.0);


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
			
				
			TF2Attrib_SetByName(Weapon3, "move speed bonus", 0.693);
			TF2Attrib_SetByName(Weapon3, "damage penalty", 1.5);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "speed_boost_on_kill", 10.0);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.5);
			TF2Attrib_SetByName(Weapon3, "dmg penalty vs buildings", 0.5);
			TF2Attrib_SetByName(Weapon3, "mod_maxhealth_drain_rate", 0.0);

			TF2CustAttr_SetString(Weapon3, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			TF2CustAttr_SetString(Weapon3, "shake on hit", "amplitude=20.0 frequency=5.0 duration=1.0");

		}


		CreateRoboHat(client, 111, 10, 6, 0.0, 1.0, 1.0); 
		TF2Attrib_SetByName(client, "attach particle effect", 35.0);
		
		
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");



	if (tauntid == -1)
	{

	TF2_AddCondition(client, 130, 6.0);





	int clients[1];
	clients[0] = client;


	EmitSoundToAll(ALARM, client);
	EmitSoundToAll(ALARM, client);


	CreateTimer(2.3, Timer_Taunt_Cancel, client);
	}

        if (tauntid == -1)
        {

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
	float flDistance = 380.0;
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

		}

	}
	return Plugin_Continue;
}
