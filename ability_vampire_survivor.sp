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
#define BANANA_MODEL "models/items/banana/banana.mdl"
#define BananaHat 30643

public Plugin:myinfo =
{
	name = "[TF2] Vampire Survivor",
	author = "HiGPS | Bmod.TF",
	description = "Spawns projectiles and fires at closest enemy",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
Handle g_hRepeatingTimer = null;

char g_ProjectileList[][64] =
{
	"tf_projectile_rocket",
	"tf_projectile_pipe",
	"tf_projectile_spellfireball",
	"tf_projectile_cleaver",
	"tf_projectile_sentryprojectile",
    "tf_projectile_ball_ornament",
    "tf_projectile_healing_bolt",
    "tf_projectile_jar",
	"tf_projectile_stun_ball",
    "tf_projectile_jar_milk",
	"tf_projectile_energy_ball",
	"tf_projectile_jar_gas",
    "tf_projectile_spellbats",

};
#define MAX_LEVEL 13
#define START_LEVEL 0
#define BASE_XP 100   // XP required to go from level 1 → 2

int g_level = 0;
int g_maxlevel = 10;
int g_exp = 0;



void ResetPlayerProgress()
{
    g_level = START_LEVEL;
    g_exp = 0;
}

public void OnMapStart()
{
	ResetPlayerProgress();
}
public void OnMapEnd()
{
    StopRepeatingTimer();
}

int GetXPRequiredForLevel(int level)
{
    // XP needed to go FROM this level TO the next
    // Level 1 -> 100
    // Level 2 -> 200
    // Level 3 -> 400
    return BASE_XP * (1 << (level - 1));
}
void StopRepeatingTimer()
{
    if (g_hRepeatingTimer != null)
    {
        KillTimer(g_hRepeatingTimer);
        g_hRepeatingTimer = null;
    }
}

void AddExperience(int client, int amount)
{
    if (g_level >= MAX_LEVEL)
        return;
	PrintToChatAll("Current Exp %i", g_exp);
	PrintToChatAll("Amount %i", amount);
    g_exp += amount;
    CheckLevelUp(client);
}

void CheckLevelUp(int client)
{
    while (g_level < MAX_LEVEL)
    {
        int xpRequired = GetXPRequiredForLevel(g_level);

        if (g_exp < xpRequired)
            break;

        g_exp -= xpRequired;
        g_level++;

        OnPlayerLevelUp(client, g_level);
    }
}

void OnPlayerLevelUp(int client, int newLevel)
{
    PrintToChat(client, "[LEVEL UP] You reached level %d!", newLevel);

    if (newLevel == MAX_LEVEL)
    {
        PrintToChat(client, "[LEVEL UP] MAX LEVEL REACHED!");
    }
    g_hRepeatingTimer = CreateTimer(
        2.0,
        Timer_DoSomething,
        newLevel-1,
        TIMER_REPEAT
    );
    // Apply perks, stats, unlocks, etc here
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
		return Plugin_Continue;
}

public void OnPluginStart()
{

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    // Start a repeating timer every 10 seconds
    if (g_hRepeatingTimer != null)
    {
        return; // timer already running
    }
	// int projectile_id = 1;

}

public Action Timer_DoSomething(Handle timer, int projectile_id)
{
    DoMyFunction(projectile_id);
    return Plugin_Continue; // keep repeating
}


// Your custom function
void DoMyFunction(int projectile_id)
{
	//Find the client
	int attacker = -1;
    for(int i = 1; i <= MaxClients; i++)
	{	
		if (IsRobot(i, "Survivor"))
		{
			attacker = i;
		}
	}
	int closestVictim = -1;
	float closestDist = 0.0;

	float attackerPos[3];
	GetClientAbsOrigin(attacker, attackerPos);

	int attackerTeam = GetClientTeam(attacker);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == attacker)
			continue;

		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (GetClientTeam(i) == attackerTeam)
			continue; // skip teammates

		float victimPos[3];
		GetClientAbsOrigin(i, victimPos);

		float dist = GetVectorDistance(attackerPos, victimPos);

		if (closestVictim == -1 || dist < closestDist)
		{
			closestVictim = i;
			closestDist = dist;
		}
	}	

	SpawnBombs(closestVictim, attacker, projectile_id);
}


public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;

	if (IsRobot(attacker, "Survivor"))
	{

		AddExperience(attacker, RoundToFloor(damage/4.0));

	}
	return Plugin_Continue;
}

// void GetRandomProjectile(int attacker)
// {
// 	int size = sizeof g_ProjectileList;
// 	for (int i = 0; i < size; i++)
// 		PrintToChatAll(g_ProjectileList[i]);
// 	}
// }

void SpawnBombs(int client, int attacker, int projectile_id)
{
	int team = GetClientTeam(attacker);

	float spawnPos[3];
	float targetPos[3];
	float dir[3];
	float vel[3];
	float ang[3];

	float speed = 1100.0;

	// Spawn above attacker's head
	GetClientEyePosition(attacker, spawnPos);
	spawnPos[2] += 40.0;

	// Target position
	GetClientEyePosition(client, targetPos);

	// Direction vector
	MakeVectorFromPoints(spawnPos, targetPos, dir);
	NormalizeVector(dir, dir);

	// Velocity
	ScaleVector(dir, speed);
	vel = dir;

	// Angles
	GetVectorAngles(dir, ang);

	// int size = sizeof g_ProjectileList;
	// int projectile_id = GetRandomInt(0, size-1);


	int projectile = CreateEntityByName(g_ProjectileList[projectile_id]);
	if (projectile == -1)
		return;

	PrintToChatAll("Firing %s", g_ProjectileList[projectile_id]);

	// 🔴 THESE MUST BE SET BEFORE DispatchSpawn
	SetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity", attacker);
	SetVariantInt(team);
	AcceptEntityInput(projectile, "TeamNum");
	SetVariantInt(team);
	AcceptEntityInput(projectile, "SetTeam");
	// SetEntProp(projectile, Prop_Send, "m_iTeamNum", team);
	SetEntProp(projectile, Prop_Send, "m_bCritical", 0);
	
	DispatchSpawn(projectile);
	// int offset = FindSendPropInfo("CTFProjectileProjectile", "m_iDeflected") + 4;
	// float damage = 100.0;
	// SetEntPropFloat(projectile, Prop_Send, "m_flDamage", 100.0);
	// GetEntPropFloat(projectile, Prop_Data, "m_flDamage", 100.0);
	// SetEntDataFloat(projectile, offset, damage);
	TeleportEntity(projectile, spawnPos, ang, vel);
	// SetEntPropFloat(projectile, Prop_Send, "m_flDamage", 100.0);
}




// GPT generated 
// void SpawnBombs(int client, int attacker)
// {
// 	int team = GetClientTeam(attacker);

// 	float spawnPos[3];
// 	float targetPos[3];
// 	float dir[3];
// 	float vel[3];
// 	float ang[3];

// 	float speed = 1200.0; // projectile speed

// 	// Get attacker position (spawn above head)
// 	GetClientEyePosition(attacker, spawnPos);
// 	spawnPos[2] += 40.0;

// 	// Get target (client) position
// 	GetClientEyePosition(client, targetPos);

// 	// Direction = target - spawn
// 	MakeVectorFromPoints(spawnPos, targetPos, dir);
// 	NormalizeVector(dir, dir);

// 	// Velocity = direction * speed
// 	ScaleVector(dir, speed);
// 	vel = dir;

// 	// Convert direction to angles so projectile faces target
// 	GetVectorAngles(dir, ang);

// 	int child = CreateEntityByName("tf_projectile_pipe");
// 	if (child == -1)
// 		return;

// 	// Prevent contact detonation
// 	SetEntProp(child, Prop_Send, "m_bTouched", 1);

// 	// Ownership & damage
// 	SetEntPropEnt(child, Prop_Data, "m_hOwnerEntity", attacker);
// 	SetEntPropFloat(child, Prop_Send, "m_flDamage", 100.0);
// 	SetEntPropFloat(child, Prop_Send, "m_flModelScale", 1.2);

// 	SetEntProp(child, Prop_Send, "m_iTeamNum", team);
// 	SetEntProp(child, Prop_Send, "m_bIsLive", 1);

// 	DispatchSpawn(child);
// 	TeleportEntity(child, spawnPos, ang, vel);
// }


// void SpawnBombs(int client, int attacker)
// {
	
// 	int team = GetClientTeam(attacker);
// 	float pos[3], vel[3], ang[3];
// 	int children = 1;
// 	float speed = 250.0;


// 	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
// 	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	

// 	pos[2] += 120.0;
// 	for (int i = 1; i <= children; i++)
// 	{
// 		int child = CreateEntityByName("tf_projectile_pipe");
		
		
// 		float child_vel[3];
// 		float child_ang[3];

// 		//Prevent child grenades from detonating on contact
// 		SetEntProp(child, Prop_Send, "m_bTouched", 1);

// 		//Set properties
// 		//SetEntProp(child, Prop_Send, "m_bCritical", view_as<int>(crit));
// 		SetEntPropEnt(child, Prop_Data, "m_hOwnerEntity", attacker);
// 		SetEntPropFloat(child, Prop_Send, "m_flDamage", 100.0);
// 		SetEntPropFloat(child, Prop_Send, "m_flModelScale", 1.2);

// 		for (int axis = 0; axis < 3; axis++){

// 			child_vel[axis] = vel[axis] + GetRandomFloat(speed * -1.0, speed);
// 			child_ang[axis] = ang[axis] + GetRandomFloat(0.0 , 360.0);
// 		}
// 		child_vel[2] = FloatAbs(child_vel[2]);

// 		SetEntProp(child, Prop_Send, "m_iTeamNum", team);
// 		SetEntProp(child, Prop_Send, "m_bIsLive", 1);

// 		DispatchSpawn(child);
// 		//SDKHook(child, SDKHook_Touch, OnMirvOverlap);
// 		TeleportEntity(child, pos, child_ang, child_vel);

// 	}
// }
