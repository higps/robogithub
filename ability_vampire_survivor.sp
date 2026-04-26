#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Survivor"

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
	"tf_projectile_rocket", // 0
	"tf_projectile_pipe", // 1
	"tf_projectile_spellfireball", // 2
	"tf_projectile_cleaver", // 3
	"tf_projectile_sentryrocket", // 4
    "tf_projectile_ball_ornament", // 5
    "tf_projectile_jar", // 6
	"tf_projectile_stun_ball", // 7
    "tf_projectile_jar_milk", // 8
	"tf_projectile_energy_ball", // 9
	"tf_projectile_jar_gas", // 10
    "tf_projectile_spellbats", // 11

};

enum TFProjectile
{
    TFProjectile_Rocket = 0,
    TFProjectile_Pipe,
    TFProjectile_SpellFireball,
    TFProjectile_Cleaver,
    TFProjectile_SentryProjectile,
    TFProjectile_BallOrnament,
    TFProjectile_Jar,
    TFProjectile_StunBall,
    TFProjectile_JarMilk,
    TFProjectile_EnergyBall,
    TFProjectile_JarGas,
    TFProjectile_SpellBats
};
#define MAX_LEVEL 13
#define START_LEVEL 0
#define BASE_XP 100   // XP required to go from level 1 → 2

int g_level = 0;
int g_maxlevel = 11;
int g_exp = 0;
int g_expreq = BASE_XP;


public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{

		DrawHUD(client);

	}
	return Plugin_Continue;
}


void DrawHUD(int client)
{
	char sHUDText[128];
	Format(sHUDText, sizeof(sHUDText), "Level: %i/%i\nXP: %i/%i",g_level,g_maxlevel,g_exp,g_expreq);


	SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 0, 255);


	ShowHudText(client, -3, sHUDText);

}

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
	// return RoundToCeil(BASE_XP * Pow(1.3, float(level - 1)));
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
    g_exp += amount;
    CheckLevelUp(client);
}

void CheckLevelUp(int client)
{
    while (g_level < MAX_LEVEL)
    {
        int xpRequired = GetXPRequiredForLevel(g_level);
		g_expreq = xpRequired; 
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
	ResetPlayerProgress();
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

	if (attacker != 1)
	{
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

	if(TF2_IsPlayerInCondition(attacker, TFCond_CritCanteen) ||
		TF2_IsPlayerInCondition(attacker, TFCond_Kritzkrieged))
	{
		//
	}

	// int player_weapon = GetPlayerWeaponSlot(attacker, 0);
    // if (player_weapon != -1)
    // {
    //     SetEntPropEnt(projectile, Prop_Send, "m_hLauncher", player_weapon);
    // }
	SetEntPropEnt(projectile, Prop_Data, "m_hOwnerEntity", attacker);
	switch(projectile_id) 
	{
		case TFProjectile_Rocket: 
		{
			//Code
			SetEntDataFloat(projectile, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 80.0, true);
		}
		case TFProjectile_Pipe: 
		{
		//Code
			PrintToChatAll("Pipe");
			// SetEntPropEnt(projectile, Prop_Data, "m_hOwnerEntity", attacker);
			// float time = GetGameTime() - 1.0;
			// SetEntPropFloat(projectile, Prop_Send, "m_flCreationTime", time);
			SetEntProp(projectile, Prop_Send, "m_bTouched", 1);
			SetEntDataFloat(projectile, FindSendPropInfo("CTFGrenadePipebombProjectile", "m_iType") + 16, 100.0);
			SetEntPropFloat(projectile, Prop_Send, "m_flDamage", 80.0);
		}
		case TFProjectile_SpellFireball: 
		{
		// PrintToChatAll("Fireball");
		}
		case TFProjectile_Cleaver: 
		{
		PrintToChatAll("Cleaver");
		// Need to add attribute list
		int weapon = GivePlayerItem(attacker, "tf_weapon_cleaver");
		SetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity", attacker);
		SetEntPropEnt(projectile, Prop_Send, "m_hLauncher", weapon);
		SetEntPropEnt(projectile, Prop_Send, "m_hOriginalLauncher", weapon);
		}
		case TFProjectile_SentryProjectile: 
		{
		//Code
		PrintToChatAll("SentryProjectile");
		SetEntDataFloat(projectile, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 100.0, true);
		}
		case TFProjectile_BallOrnament: 
		{
		PrintToChatAll("TFProjectile_BallOrnament");
		}
		case TFProjectile_Jar: 
		{
		PrintToChatAll("TFProjectile_Jar");
		}
		case TFProjectile_JarMilk: 
		{
		PrintToChatAll("TFProjectile_JarMilk");
		}
		case TFProjectile_EnergyBall: 
		{
		PrintToChatAll("TFProjectile_EnergyBall");
		}
		case TFProjectile_JarGas: 
		{
		PrintToChatAll("TFProjectile_JarGas");
		}
		case TFProjectile_SpellBats: 
		{
		PrintToChatAll("TFProjectile_SpellBats");
		}
	}
	SetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity", attacker);
	SetVariantInt(team);
	AcceptEntityInput(projectile, "TeamNum");
	SetVariantInt(team);
	AcceptEntityInput(projectile, "SetTeam");
	// SetEntProp(projectile, Prop_Send, "m_iTeamNum", team);
	SetEntProp(projectile, Prop_Send, "m_bCritical", 0);
	DispatchSpawn(projectile);
	TeleportEntity(projectile, spawnPos, ang, vel);
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
