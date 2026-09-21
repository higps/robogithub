#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <tf_ontakedamage>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME "Flak"
#define RESERVE_SHOOTER_INDEX 415

#define BoomNoise "vo/taunts/demo/taunt_demo_nuke_8_explosion.mp3"
#define sBoomNoise "weapons/explode3.wav"

// Configurable damage bonus applied when the victim is jumping / rocket-jumping
float JumpDamageBonus = 1.15;

// Configurable damage/radius for the mini-crit boom (this file's explosion)
float MiniCritBoomDamage = 30.0;
float MiniCritBoomRadius = 250.0;
float MiniCritBoomIgnite = 2.0;

// Configurable damage/radius for the crit boom (bearded expense style explosion)
float CritBoomDamage = 90.0;
float CritBoomRadius = 450.0;
float CritBoomZOffset = 0.0;

int TracedTarget;

public Plugin myinfo =
{
	name = "[TF2] FLAK Boom Ability",
	author = "Erofix",
	description = "FLAK triggers a boom on mini-crit or critical hits, with bonus damage against jumping victims",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public void OnMapStart()
{
	PrecacheSound(BoomNoise);
	PrecacheSound(sBoomNoise);
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if (!IsValidClient(attacker) || !IsValidClient(victim) || attacker == victim)
		return Plugin_Continue;
	
	if (weapon <= MaxClients) //ignore our own explosion damage (weapon -1) so it can't re-trigger another boom
		return Plugin_Continue;
	
	if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") != RESERVE_SHOOTER_INDEX)
		return Plugin_Continue;
	
	if (!IsRobot(attacker, ROBOT_NAME))
		return Plugin_Continue;
	
	bool changed = false;
	
	bool isJumping = view_as<bool>(GetEntProp(victim, Prop_Send, "m_bJumping")) || TF2_IsPlayerInCondition(victim, TFCond_BlastJumping) || TF2_IsPlayerInCondition(victim, TFCond_KnockedIntoAir);
	if (isJumping && TF2_IsPlayerInCondition(victim, TFCond_OnFire))
	{
		damage *= JumpDamageBonus;
		changed = true;

		//guaranteed crits (Kritzkrieg, crit boost, etc.) don't always populate critType, so check conditions too
		if (IsForcedCrit(attacker))
			critType = CritType_Crit;

		if (critType == CritType_MiniCrit || critType == CritType_Crit)
		{
			DataPack info = new DataPack();
			info.WriteCell(GetClientUserId(attacker));
			info.WriteCell(GetClientUserId(victim));
			info.WriteCell(view_as<int>(critType));
			RequestFrame(TriggerBoom, info); //wait a frame so the triggering hit isn't killed twice by our explosion
		}
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

bool IsForcedCrit(int client)
{
	return TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged)
		|| TF2_IsPlayerInCondition(client, TFCond_Buffed)
		|| TF2_IsPlayerInCondition(client, TFCond_CritCanteen)
		|| TF2_IsPlayerInCondition(client, TFCond_CritOnWin)
		|| TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy)
		|| TF2_IsPlayerInCondition(client, TFCond_CritMmmph);
}

void TriggerBoom(DataPack info)
{
	info.Reset();
	int attacker = GetClientOfUserId(info.ReadCell());
	int victim = GetClientOfUserId(info.ReadCell());
	CritType critType = view_as<CritType>(info.ReadCell());
	delete info;

	if (!IsValidClient(attacker) || !IsValidClient(victim))
		return;

	if (critType == CritType_MiniCrit)
		MiniCritBoom(attacker, victim);
	else if (critType == CritType_Crit)
		CritBoom(attacker, victim);
}

void MiniCritBoom(int attacker, int victim)
{
	float pos[3];
	GetClientAbsOrigin(victim, pos);
	pos[2] += 50.0; //Set the position to be about center of the player

	//Create our explosion
	//Both env_explosion and tf_generic_bomb do not at all like to be spawned onto player entities so making a custom explosion instead
	float radius = MiniCritBoomRadius;
	float damage = MiniCritBoomDamage;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && i != attacker && GetClientTeam(i) == GetClientTeam(victim))
		{
			if (i == victim)
			{
				SDKHooks_TakeDamage(victim, attacker, attacker, damage, DMG_GENERIC, -1, NULL_VECTOR, pos);
				TF2_IgnitePlayer(i, attacker, MiniCritBoomIgnite);
				continue; //don't also apply the falloff damage below to the same victim
			}
			float playerpos[3];
			GetClientAbsOrigin(i, playerpos);
			float distance = GetVectorDistance(playerpos, pos);
			if (distance < 1.0) distance = 1.0;
			if (distance > radius) continue;
			if (i != victim && !CanSeeTarget(pos, playerpos, i, victim)) //Only hit players that are visible to the explosion
					continue;

			TF2_IgnitePlayer(i, attacker, MiniCritBoomIgnite);
			float appliedDamage = ((radius - distance) / radius) * damage;
			if (appliedDamage < damage * 0.5)
				appliedDamage = damage * 0.5; //Dont allow our damage to drop below half our base damage

			SDKHooks_TakeDamage(i, attacker, attacker, appliedDamage);
		}
	}
	EmitSoundToAll(BoomNoise, victim);
	CreateParticle("ExplosionCore_MidAir_Flare", pos);
	// CreateParticle("mvm_pow_bam", pos);
	
	TracedTarget = INVALID_ENT_REFERENCE;
}

void CritBoom(int attacker, int victim)
{
	float pos1[3];
	float pos22[3];
	float pos2[3];
	GetClientAbsOrigin(attacker, pos1); //hack: make the explosion actually come from the attacker, that way we only have to hook one client
	GetClientAbsOrigin(victim, pos22);
	pos22[2] += CritBoomZOffset; //raise the particle so it spawns roughly at the victim's center instead of their feet

	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", "rd_robot_explosion");
	AcceptEntityInput(particle, "Start");
	TeleportEntity(particle, pos22, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			GetClientAbsOrigin(client, pos2);
			if (GetVectorDistance(pos1, pos2) <= CritBoomRadius && TF2_GetClientTeam(attacker) != TF2_GetClientTeam(client))
			{
				SDKHooks_TakeDamage(client, 0, attacker, CritBoomDamage, 0, -1, NULL_VECTOR, pos22);
				EmitAmbientSound(sBoomNoise, pos22, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
			}
		}
	}
}

bool CanSeeTarget(float start[3], float end[3], int target, int source)
{
	bool result = false;
	end[2] += 50.0; //Raise the position to be roughly the center of the target player
	TracedTarget = target;
	Handle trace = TR_TraceRayFilterEx(start, end, MASK_SHOT, RayType_EndPoint, CheckTrace, source);
	if (TR_DidHit(trace))
	{
		if (TR_GetEntityIndex(trace) == target)
			result = true;
	}
	CloseHandle(trace);
	return result;
}

bool CheckTrace(int entity, int mask, int ignore)
{
	if (entity == ignore)
		return false;

	//Prevent other players from blocking line of sight
	if (IsValidClient(entity) && entity != TracedTarget)
		return false;

	return true;
}

int CreateParticle(char[] sParticle, float pos[3])
{
	int particle = CreateEntityByName("info_particle_system");
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(particle, "effect_name", sParticle);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");
	DelayEntityRemove(particle, 10.0);

	return particle;
}

void DelayEntityRemove(int entity, float duration)
{
	char output[64];
	Format(output, sizeof output, "OnUser1 !self:kill::%.1f:1", duration);
	SetVariantString(output);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}
