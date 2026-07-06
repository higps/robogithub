#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
 #include <sdktools>
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Survivor"
#define MAX_LEVEL 10
#define START_LEVEL 0
#define BASE_XP 75   // XP required to go from level 1 → 2

int g_iScheduledCount = 0;
int g_iScheduledProjectileId[MAX_LEVEL];
float g_fNextActionTime[MAX_LEVEL];
float g_fInterval[MAX_LEVEL];

public Plugin:myinfo =
{
	name = "[TF2] Vampire Survivor",
	author = "HiGPS | Bmod.TF",
	description = "Spawns projectiles and fires at closest enemy",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

char g_ProjectileList[][64] =
{
	"tf_projectile_rocket", // 0
	"tf_projectile_pipe", // 1
	//"tf_projectile_spellfireball", // 2
	"tf_projectile_cleaver", // 3
	"tf_projectile_sentryrocket", // 4
    "tf_projectile_ball_ornament", // 5
    "tf_projectile_jar", // 6
	"tf_projectile_stun_ball", // 7
    "tf_projectile_jar_milk", // 8
	//"tf_projectile_energy_ball", // 9
	"tf_projectile_jar_gas", // 10
    "tf_projectile_spellbats", // 11

};

enum TFProjectile
{
    TFProjectile_Rocket = 0,
    TFProjectile_Pipe,
    //TFProjectile_SpellFireball,
    TFProjectile_Cleaver,
    TFProjectile_SentryProjectile,
    TFProjectile_BallOrnament,
    TFProjectile_Jar,
    TFProjectile_StunBall,
    TFProjectile_JarMilk,
    //TFProjectile_EnergyBall,
    TFProjectile_JarGas,
    TFProjectile_SpellBats
};
#define MAX_LEVEL 10
#define START_LEVEL 0
#define BASE_XP 75   // XP required to go from level 1 → 2

int g_level = 0;
int g_exp = 0;
int g_expreq;


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
	Format(sHUDText, sizeof(sHUDText), "Level: %i/%i\nXP: %i/%i",g_level,MAX_LEVEL,g_exp,g_expreq);


	SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 0, 255);


	ShowHudText(client, -3, sHUDText);

}

void ResetPlayerProgress()
{
    g_level = START_LEVEL;
    g_exp = 0;
	g_expreq = GetXPRequiredForLevel(1);
    ResetScheduledProjectiles();
}
public void OnMapStart()
{
	ResetPlayerProgress();
}
public void OnMapEnd()
{
    ResetScheduledProjectiles();
}

int GetXPRequiredForLevel(int level)
{
    // XP needed to go FROM this level TO the next
    // Level 1 -> 100
    // Level 2 -> 200
    // Level 3 -> 400
    // return BASE_XP * (1 << (level - 1));
	return RoundToCeil(BASE_XP * Pow(1.4, float(level - 1)));
}
float GetProjectileInterval(int projectile_id)
{
	// Return the interval in seconds for this projectile.
	switch (projectile_id)
	{
		case TFProjectile_Rocket:
		{
			return 3.0;
		}
		case TFProjectile_Pipe:
		{
			return 2.0;
		}
		case TFProjectile_Cleaver:
		{
			return 1.5;
		}
		case TFProjectile_SentryProjectile:
		{
			return 4.0;
		}
		case TFProjectile_BallOrnament:
		{
			return 2.0;
		}
		case TFProjectile_Jar:
		{
			return 20.0;
		}
		case TFProjectile_StunBall:
		{
			return 2.5;
		}
		case TFProjectile_JarMilk:
		{
			return 20.0;
		}
		case TFProjectile_JarGas:
		{
			return 10.0;
		}
		case TFProjectile_SpellBats:
		{
			return 7.5;
		}
	}

	return 2.5;
}

void AddScheduledProjectile(int projectile_id)
{
    if (g_iScheduledCount >= MAX_LEVEL)
        return;

    g_iScheduledProjectileId[g_iScheduledCount] = projectile_id;
    g_fInterval[g_iScheduledCount] = GetProjectileInterval(projectile_id);
    g_fNextActionTime[g_iScheduledCount] = GetEngineTime() + g_fInterval[g_iScheduledCount];
    g_iScheduledCount++;
}

void ResetScheduledProjectiles()
{
    g_iScheduledCount = 0;
}

void AddExperience(int client, int amount)
{
    if (g_level >= MAX_LEVEL)
        return;
    g_exp += amount;
    CheckLevelUp(client);
}
bool heal_yap = true;
void CheckLevelUp(int client)
{

	if (g_level == 3)
	{
		// int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(heal_yap)
		{
		PrintToChat(client,"LVL3 Bonus: You got health regen!");
		TF2Attrib_SetByName(client, "health regen", 5.0);
		heal_yap = false;
		}

	}
    while (g_level < MAX_LEVEL)
    {
        int xpRequired = GetXPRequiredForLevel(g_level + 1);
		g_expreq = xpRequired; 
        if (g_exp < xpRequired)
            break;

        g_exp -= xpRequired;
        g_level++;
		
        OnPlayerLevelUp(client, g_level);
    }
}
#define LEVELUP_SOUND "misc/achievement_earned.wav"

void OnPlayerLevelUp(int client, int newLevel)
{
	PrecacheSound(LEVELUP_SOUND, true);
	EmitSoundToClient(client, LEVELUP_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
    PrintToChat(client, "[LEVEL UP] You reached level %d!", newLevel);

    if (newLevel == MAX_LEVEL)
    {
        PrintToChat(client, "[LEVEL UP] MAX LEVEL REACHED!");

    }
	
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 0.5);
    AddScheduledProjectile(newLevel - 1);
}

void KillAllTimers()
{
    ResetScheduledProjectiles();
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    	int client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsRobot(client, ROBOT_NAME))
		{
			g_expreq = GetXPRequiredForLevel(1);
			ResetPlayerProgress();
		}
		return Plugin_Continue;
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    heal_yap = true;
	ResetScheduledProjectiles();
	ResetPlayerProgress();
	g_expreq = GetXPRequiredForLevel(1);
}

void ExecuteRoutine(int projectile_id)
{
    DoMyFunction(projectile_id);
}

public void OnGameFrame()
{
    float fCurrentTime = GetEngineTime();

    for (int i = 0; i < g_iScheduledCount; i++)
    {
        if (fCurrentTime >= g_fNextActionTime[i])
        {
            ExecuteRoutine(g_iScheduledProjectileId[i]);
            g_fNextActionTime[i] = fCurrentTime + g_fInterval[i];
        }
    }
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

	if (attacker != -1)
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
		// Ignore disguised or cloaked spies
		if (TF2_GetPlayerClass(i) == TFClass_Spy)
		{
			if (TF2_IsPlayerInCondition(i, TFCond_Disguised) ||
				TF2_IsPlayerInCondition(i, TFCond_Cloaked))
			{
				continue;
			}
		}


		float victimPos[3];
		GetClientAbsOrigin(i, victimPos);

		float dist = GetVectorDistance(attackerPos, victimPos);

		if (closestVictim == -1 || dist < closestDist)
		{
			closestVictim = i;
			closestDist = dist;
		}
	}	

	if (closestVictim != -1)SpawnBombs(closestVictim, attacker, projectile_id);
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

		if (attacker != victim)
		{
			int Weapon3 = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);
			if (weapon == Weapon3) AddExperience(attacker, RoundToFloor(damage/2.0));
		}
		
		// if (victim == attacker){
		// damage = 0.0;
		// return Plugin_Changed;
		// } 
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

	// PrintToChatAll("Firing %s", g_ProjectileList[projectile_id]);

	// 🔴 THESE MUST BE SET BEFORE DispatchSpawn

	// if(TF2_IsPlayerInCondition(attacker, TFCond_CritCanteen) ||
	// 	TF2_IsPlayerInCondition(attacker, TFCond_Kritzkrieged))
	// {
	// 	//
	// }

	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
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
			// PrintToChatAll("Pipe");
			// SetEntPropEnt(projectile, Prop_Data, "m_hOwnerEntity", attacker);
			// float time = GetGameTime() - 1.0;
			// SetEntPropFloat(projectile, Prop_Send, "m_flCreationTime", time);
			SetEntProp(projectile, Prop_Send, "m_bTouched", 1);
			SetEntDataFloat(projectile, FindSendPropInfo("CTFGrenadePipebombProjectile", "m_iType") + 16, 100.0);
			SetEntPropFloat(projectile, Prop_Send, "m_flDamage", 80.0);
		}
		// case TFProjectile_SpellFireball: 
		// {
		// // PrintToChatAll("Fireball");
		// }
		case TFProjectile_Cleaver: 
		{
			// int cleaver = CreateEntityByName("tf_projectile_cleaver");
			// RequestFrame(ChangeModel,cleaver);
			// it is important that teleporting happens before dispatch otherwise spawn angles are wrong
			//TeleportEntity(cleaver, vecEyePosition, angEyes, NULL_VECTOR);
			//DispatchSpawn(cleaver);
			
			// use for physics logic
			// SDKCall(g_SDKCallInitGrenade, projectile, vecVelocity, vecAngImpulse, attacker, 0, 5.0);
			
			SetEntPropEnt(projectile, Prop_Send, "m_hThrower", attacker);
			SetEntPropEnt(projectile, Prop_Send, "m_hLauncher", weapon);
			SetEntPropEnt(projectile, Prop_Send, "m_hOriginalLauncher", weapon);
		}
		case TFProjectile_SentryProjectile: 
		{
		//Code
		// PrintToChatAll("SentryProjectile");
		SetEntDataFloat(projectile, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 100.0, true);
		}
		case TFProjectile_BallOrnament: 
		{
		// PrintToChatAll("TFProjectile_BallOrnament");
		}
		case TFProjectile_Jar: 
		{
		// PrintToChatAll("TFProjectile_Jar");
		}
		case TFProjectile_JarMilk: 
		{
		// PrintToChatAll("TFProjectile_JarMilk");
		}
		// case TFProjectile_EnergyBall: 
		// {
		// PrintToChatAll("TFProjectile_EnergyBall");
		// }
		case TFProjectile_JarGas: 
		{
		// PrintToChatAll("TFProjectile_JarGas");
		}
		case TFProjectile_SpellBats: 
		{
		// PrintToChatAll("TFProjectile_SpellBats");
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

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsRobotWhenDead(client, ROBOT_NAME))
	{
		// PrintToChatAll("DED");
		ResetPlayerProgress();
		KillAllTimers();
		heal_yap = true;
		//return Plugin_Stop; // stops THIS instance
	}
		    
}