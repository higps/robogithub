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
// #define SOUND_LEAP  "TFPlayer.AirBlastImpact"


#define sBoomNoise  "weapons/explode3.wav"
#define ALARM2      "mvm/mvm_cpoint_klaxon.wav"
#define JUMP2        "items/powerup_pickup_king.wav"

#define JUMP  "lunge.wav"
#define ALARM  "om_chant.wav"



Handle g_hGameConf;
Handle g_hIsDeflectable;

public Plugin:myinfo =
{
	name = "[TF2] Be the Bearded Expense Leap Ability and boom bullshit",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Unused Juggernaut Bearded Expense Champ from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
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

	if (IsRobot(attacker, ROBOT_NAME))
	{
		TF2_AddCondition(attacker, TFCond_Slowed, 10.0);
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
