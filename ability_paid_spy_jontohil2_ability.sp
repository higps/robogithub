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
 
#define ROBOT_NAME	"Jontohil2"
#define sBoomNoise1  "weapons/tacky_grenadier_explode1.wav"
#define sBoomNoise2  "weapons/tacky_grenadier_explode2.wav"
#define sBoomNoise3  "weapons/tacky_grenadier_explode3.wav"
#define PLUGIN_VERSION "1.0"
//#define GIFTBRINGER 30747

public Plugin:myinfo =
{
	name = "[TF2] Hoovy explosion skill",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
} 

public OnMapStart()
{
	PrecacheSound(sBoomNoise1);
	PrecacheSound(sBoomNoise2);
	PrecacheSound(sBoomNoise3);
}

public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

		//int weaponID = GetEntPropEnt(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	//PrintToChatAll("Attacker %N , weaponID %i, logname: %s", attacker, weaponID, weapon_logname);
    int customkill = event.GetInt("customkill");

    // Assuming 2 is the custom kill ID for backstab (you might need to confirm this)
    if (IsRobot(attacker, ROBOT_NAME) && customkill == 2)
    {
        // PrintToChatAll("Player %d was backstabbed by player %d!", victim, attacker);
		Handle infokv = CreateKeyValues("infokv");
		KvSetNum(infokv, "attacker", attacker);
		KvSetNum(infokv, "victim", victim);
		CreateTimer(0.0, HoovyBoom, infokv);
    }

    return Plugin_Continue;

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
//	float pos2[3];
//	float ignitetime = GetConVarFloat(FindConVar("sharpened_volcano_fragment_firetime"));
	
	for(int client = 1 ; client <= MaxClients ; client++ )
	{
		if(IsClientInGame(client))
		{
			GetClientAbsOrigin(client, pos22);
			if(GetVectorDistance(pos1, pos22) <= 300.0 && TF2_GetClientTeam(attacker) != TF2_GetClientTeam(client))
			{
				SDKHooks_TakeDamage(client, 0, attacker, 120.0, 0, -1);
				
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
	return Plugin_Continue;
}

/* Plugin Exclusive Functions */
//Code that stuns players
// public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
// {
// 	// if (!g_Enable)
// 	//     return Plugin_Continue;
// 	if(!IsValidClient(victim))
// 	return Plugin_Continue;    
// 	if(!IsValidClient(attacker))
// 	return Plugin_Continue;


// 	if(IsRobot(attacker, ROBOT_NAME))
// 	{
		
// 	if(TF2_IsPlayerInCondition(victim, TFCond_Taunting) && !IsAnyRobot(victim))
// 	{
// 		int tauntid = GetEntProp(victim, Prop_Send, "m_iTauntItemDefIndex");
// 		// PrintToChatAll("Taunt ID %i", tauntid);
// 		if (tauntid != -1)SendVictimToSpace(victim);
// 	}

// 	}  

// 	return Plugin_Continue;
// }


