#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <berobot_constants>
#include <berobot>

#include <tf_ontakedamage>

#define ROBOT_NAME "Wrangler Bill"
#define PLUGIN_VERSION "1.0"

float g_self_sentry_push_force_mult = 15.0;

void ApplySelfSentryKnockbackImpulse(int victim, int sentry, float damageForce[3])
{
	float pushDir[3];
	float pushVel[3];
	float curVel[3];

	pushDir[0] = damageForce[0];
	pushDir[1] = damageForce[1];
	pushDir[2] = damageForce[2];

	if (GetVectorLength(pushDir) < 1.0)
	{
		float sentryPos[3];
		float victimPos[3];
		GetEntPropVector(sentry, Prop_Data, "m_vecOrigin", sentryPos);
		GetEntPropVector(victim, Prop_Data, "m_vecOrigin", victimPos);
		MakeVectorFromPoints(sentryPos, victimPos, pushDir);
		pushDir[2] += 24.0;
	}

	NormalizeVector(pushDir, pushDir);

	// Apply extra velocity directly so wrangled self-knockback is guaranteed to change.
	ScaleVector(pushDir, 35.0 * g_self_sentry_push_force_mult);
	pushVel = pushDir;

	GetEntPropVector(victim, Prop_Data, "m_vecVelocity", curVel);
	AddVectors(curVel, pushVel, curVel);
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, curVel);
}

public Plugin:myinfo =
{
	name = "[TF2] Wrangler Bill Ability",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Increase self push force from own wrangled sentry",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
};

bool IsSentryEntity(int entity)
{
	if (!IsValidEntity(entity))
		return false;

	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrEqual(classname, "obj_sentrygun");
}

bool IsSentryRocketEntity(int entity)
{
	if (!IsValidEntity(entity))
		return false;

	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrEqual(classname, "tf_projectile_sentryrocket");
}

int ResolveOwningSentryFromInflictor(int inflictor)
{
	if (!IsValidEntity(inflictor))
		return -1;

	if (IsSentryEntity(inflictor))
		return inflictor;

	if (!IsSentryRocketEntity(inflictor))
		return -1;

	int owner = GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity");
	if (IsSentryEntity(owner))
		return owner;

	int launcher = GetEntPropEnt(inflictor, Prop_Send, "m_hLauncher");
	if (IsSentryEntity(launcher))
		return launcher;

	return -1;
}

bool IsWrangledSentry(int sentry)
{
	if (!IsSentryEntity(sentry))
		return false;

	if (!HasEntProp(sentry, Prop_Send, "m_bPlayerControlled"))
		return false;

	return GetEntProp(sentry, Prop_Send, "m_bPlayerControlled") != 0;
}

bool IsOwnSentryForVictim(int victim, int sentry)
{
	if (!IsValidClient(victim) || !IsSentryEntity(sentry))
		return false;

	if (!HasEntProp(sentry, Prop_Send, "m_hBuilder"))
		return false;

	int builder = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
	return builder == victim;
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
	int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
	int damagecustom, CritType &critType)
{
	if (!IsValidClient(victim))
		return Plugin_Continue;

	if (!IsRobot(victim, ROBOT_NAME))
		return Plugin_Continue;

	int sentry = ResolveOwningSentryFromInflictor(inflictor);
	if (sentry == -1)
		return Plugin_Continue;

	if (!IsOwnSentryForVictim(victim, sentry))
		return Plugin_Continue;

	if (!IsWrangledSentry(sentry))
		return Plugin_Continue;

	// PrintToChatAll("ALTERING PUSH");
	damageForce[0] *= g_self_sentry_push_force_mult;
	damageForce[1] *= g_self_sentry_push_force_mult;
	damageForce[2] *= g_self_sentry_push_force_mult;
	ApplySelfSentryKnockbackImpulse(victim, sentry, damageForce);

	return Plugin_Changed;
}
