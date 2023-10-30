#pragma semicolon 1
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <tf2>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>

public Plugin myinfo =
{
	name = "[MM] Sentry Buster Attributes",
	author = "Manned Machines",
	description = "Attributes for sentry busters for Manned Machines",
	version = "1.0",
	url = "www.sourcemod.com"
}

int TracedTarget = INVALID_ENT_REFERENCE;

bool AboutToExplode[MAXPLAYERS + 1];

// struct for storing information about the last detonating sentry buster
enum struct FSentryBuster
{
	int ref;
	float Damage;
	float Radius;
	float Timer;

	float Pos[3];

	bool LineOfSight;

	void Set(int client)
	{
		if (client <= MaxClients && client != 0 && IsClientInGame(client))
			this.ref = EntIndexToEntRef(client);
	}

	int Get()
	{
		return EntRefToEntIndex(this.ref);
	}

	bool Valid()
	{
		int client = this.Get();

		return (client <= MaxClients && client != 0 && IsClientInGame(client));
	}
}
FSentryBuster LastBuster;

bool g_Taunt_clamp = false;
public void OnPluginStart()
{
	for(int client = 1 ; client <= MaxClients ; client++)
	{
		if(IsClientInGame(client))
			OnClientPostAdminCheck(client);
	}

	HookEvent("post_inventory_application", Event_post_inventory_application, EventHookMode_Post);
}


public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_Touch, OnTouch);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack); // hook for when someone joins in the middle of a round
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public void OnClientDisconnect_Post(int client)
{
	SDKUnhook(client, SDKHook_Touch, OnTouch);
}

Action Event_post_inventory_application(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	///Sets color back to normal
	if (IsValidClient(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 0);
	}
	return Plugin_Continue;
}

Action OnTouch(int client, int ent)
{
	if (IsValidClient(client) && IsValidEntity(ent))
	{
		//char stats[256];
		if (IsSentryBuster(client)) // Make sure this player is a robot and is a sentry buster
		{
			char entname[MAX_NAME_LENGTH];
			GetEntityClassname(ent, entname, sizeof(entname));

			if (StrEqual(entname, "obj_sentrygun"))
			{
				
				//int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
				int iBuildingTeam = GetEntPropEnt(ent, Prop_Send, "m_iTeamNum");
				int iClientTeam = GetClientTeam(client);

				if(iClientTeam != iBuildingTeam && !g_Taunt_clamp)
				{
					SetEntPropEnt(ent, Prop_Send, "m_bGlowEnabled", 1);
					//PrintToChatAll("not the same team");
					GetReadyToExplode(client);
					FakeClientCommand(client, "taunt");
					TF2_AddCondition(client, TFCond_FreezeInput, 7.0);
					g_Taunt_clamp = true;
					CreateTimer(2.5, FakeCommand_Clamp);
				}
			}
			if (StrEqual(entname, "player"))
			{
				int iCarried = GetEntPropEnt(ent, Prop_Send, "m_hCarriedObject");

				if (iCarried > MaxClients)
				{
					// char entname[MAX_NAME_LENGTH];
					GetEdictClassname(iCarried, entname, sizeof(entname));
					//	PrintToChatAll("%s Object carried", entname);
					if (StrEqual(entname, "obj_sentrygun") && !AboutToExplode[client])
					{
						GetReadyToExplode(client);
						TF2_AddCondition(client, TFCond_FreezeInput);
						FakeClientCommand(client, "taunt");
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void GetReadyToExplode(int client)
{
	TF2_AddCondition(client, 130);
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_spin.wav", client);
	StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
	
	char stats[256];
	TF2CustAttr_GetString(client, "Sentry Buster", stats, sizeof stats);
	LastBuster.Set(client);
	LastBuster.Timer = ReadFloatVar(stats, "timer", 4.0);

	CreateTimer(LastBuster.Timer, Bewm, GetClientUserId(client));
	AboutToExplode[client] = true;
}

void DoDamage(int client, int target, int amount) // from Goomba Stomp.
{
	int pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt > MaxClients) //this shouldn't ever fail
	{
		DispatchKeyValue(target, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		char dmg[15];
		Format(dmg, 15, "%i", amount);
		DispatchKeyValue(pointHurt, "Damage", dmg);
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", client);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(target, "targetname", "");
		RemoveEdict(pointHurt);
	}
}

Action FakeCommand_Clamp(Handle timer)
{
	g_Taunt_clamp = false;
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (IsSentryBuster(client) && condition == TFCond_Taunting)
	{
		int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
		if (tauntid == -1)
		{
			GetReadyToExplode(client);
			TF2_AddCondition(client, TFCond_FreezeInput, 7.0);
		}
	}
}

Action Bewm(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!IsPlayerAlive(client))
		return Plugin_Handled;

	AboutToExplode[client] = false;

	int explosion = CreateEntityByName("env_explosion");
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	if (explosion)
	{
		DispatchSpawn(explosion);
		TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode", -1, -1, 0);
		RemoveEdict(explosion);
	}
	//bool FF = false;

	char stats[256];
	TF2CustAttr_GetString(client, "Sentry Buster", stats, sizeof stats);

	LastBuster.Set(client);
	LastBuster.Damage = ReadFloatVar(stats, "damage", 2500.0);
	// PrintToChatAll("Damage: %.1f", LastBuster.Damage);
	LastBuster.Radius = ReadFloatVar(stats, "radius", 500.0);
	
	LastBuster.LineOfSight = view_as<bool>(ReadIntVar(stats, "lineofsight", 0));

	LastBuster.Pos = clientPos;

	CreateExplosion(clientPos, LastBuster.Radius, LastBuster.Get());

	// This will include everything in one go, no need to loop through all clients and then also entities
	// TR_EnumerateEntitiesSphere(clientPos, LastBuster.Radius, MASK_SHOT, FindEntitiesInSphere, LastBuster.Get());
	
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_explode.wav", client);
	AttachParticle(client, "fluidSmokeExpl_ring_mvm");
	DoDamage(client, client, 2500);
	FakeClientCommand(client, "kill");

	return Plugin_Handled;
}

void CreateExplosion(float position[3], float radius, int client)
{
	int bomb = CreateEntityByName("tf_generic_bomb");

	DispatchKeyValueFloat(bomb, "damage", LastBuster.Damage);
	DispatchKeyValueFloat(bomb, "radius", radius);
	DispatchKeyValue(bomb, "health", "1");

	SetEntPropEnt(bomb, Prop_Data, "m_hOwnerEntity", client);

	DispatchSpawn(bomb);
	ActivateEntity(bomb);

	TeleportEntity(bomb, position, NULL_VECTOR, NULL_VECTOR);

	SDKHooks_TakeDamage(bomb, client, client, 2.0);
}

/*
bool FindEntitiesInSphere(int entity, int exclude)
{
	// Ignore entities that we can't or shouldn't damage
	bool damage = false;
	
	if (exclude == entity)
		return true; // continue, do nothing
		
	if (entity == 0)
		return true; // Ignore the world
		
	//PrintToChatAll("Found entity");
		
	float endPos[3];
	
	// Check if this is a client.. we shouldn't have to check for team relations since we can't damage teammates regardless
	if (entity <= MaxClients)
	{
		//PrintToChatAll("Entity is a client");
		if (IsClientInGame(entity) && IsPlayerAlive(entity)) // This really shouldn't ever error... but if it for some reason does, just add an additional check for IsClientInGame()
		{
			damage = true;
			
			GetClientAbsOrigin(entity, endPos);
			endPos[2] += 40.0; // Center mass
		}
	}
	else if (IsValidEntity(entity)) // Probably not needed? If it's not a client it should always be a valid entity, regardless..
	{
		char classname[64];
		GetEntityClassname(entity, classname, sizeof classname);

		//PrintToChatAll("Entity is a building: %s", classname);
		
		// All building types
		if (StrContains(classname, "obj_") != -1)
		{
			damage = true;
			
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", endPos);
			endPos[2] += 20.0;
		}
	}
	
	if (damage)
	{
		//TracedTarget = INVALID_ENT_REFERENCE;
		if (LastBuster.LineOfSight) // Line of sight check
		{
			if (CanSeeTarget(LastBuster.Pos, endPos, entity, LastBuster.Get()))
			{
				//PrintToChatAll("Target is visible");
				// Damage the entity
				SDKHooks_TakeDamage(entity, LastBuster.Get(), LastBuster.Get(), LastBuster.Damage, DMG_BLAST);
			}
		}
		else // If no line of sight check is required, just damage the entity
			SDKHooks_TakeDamage(entity, LastBuster.Get(), LastBuster.Get(), LastBuster.Damage, DMG_BLAST);
	}
	
	return true; // We want to keep iterating until we run out of overlapped entities.. nothing should really need to stop this
}

bool CanSeeTarget(float start[3], float end[3], int target, int source)
{
	bool result = false;
	//end[2] += 50.0; //Raise the position to be roughly the center of the target player
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
*/

stock bool AttachParticle(int Ent, char[] particleType, bool cache = false) // from L4D Achievement Trophy
{
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) return false;
	new String:tName[128];
	new Float:f_pos[3];
	if (cache) f_pos[2] -= 3000;
	else
	{
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", f_pos);
		f_pos[2] += 60;
	}
	TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);
	Format(tName, sizeof(tName), "target%i", Ent);
	DispatchKeyValue(Ent, "targetname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(10.0, DeleteParticle, particle);
	return true;
}
public Action DeleteParticle(Handle timer, any Ent)
{
	if (!IsValidEntity(Ent)) return Plugin_Continue;
	char cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) RemoveEntity(Ent);
	return Plugin_Continue;
}

public Action OnTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	if(IsValidClient(attacker))
	{
		if (IsSentryBuster(attacker) && IsValidClient(victim))
		{
			if(TF2_GetClientTeam(attacker) != (TF2_GetClientTeam(victim)))
			{
				FakeClientCommand(attacker, "taunt");
			}
		}
	}
	return Plugin_Continue;
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsValidClient(victim))
	{
		if (!IsSentryBuster(victim) || victim == attacker)
			return Plugin_Continue;

		if (AboutToExplode[victim])
		{
			damage = 0.0;

			FakeClientCommand(victim, "taunt");
			return Plugin_Changed;
		}
		else if (damage+10.0 > GetClientHealth(victim))
		{
			damage = 0.0;

			GetReadyToExplode(victim);
			FakeClientCommand(victim, "taunt");
			return Plugin_Changed;
		}
	}
	// if (IsValidClient(attacker)) // This is a Sentry.
	// {
	// 	if (!AboutToExplode[attacker])
	// 	{
	// 		PrintToChatAll("State 3");
	// 		damage = 0.0;
	// 		return Plugin_Changed;
	// 	}
	// }

	return Plugin_Continue;
}

bool IsSentryBuster(int client)
{
	char stats[256];

	return view_as<bool>(TF2CustAttr_GetString(client, "Sentry Buster", stats, sizeof stats));
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if(client <= 0 || client > MaxClients)
		return false;
	if(!IsClientInGame(client))
		return false;
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;
	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}
