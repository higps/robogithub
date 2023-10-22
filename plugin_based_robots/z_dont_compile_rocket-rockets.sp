#include <tf2>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1

#define ROCKETMODEL "models/weapons/c_models/c_rocketlauncher/c_rocketlauncher.mdl"

public Plugin myinfo =
{
	name = "[TF2] Rocket Launcher Launcher",
	author = "IvoryPal",
	description = "Rocket Launcher-ception!",
	version = "1.0"
};

enum struct Reference
{
	int ref;
	void set(int entity)
	{
		this.ref = EntIndexToEntRef(entity);
	}
	int get()
	{
		return EntRefToEntIndex(this.ref);
	}
	bool valid()
	{
		int entity = this.get();
		if (IsValidEntity(entity) && entity > MaxClients)
			return true;

		return false;
	}
}

enum struct Rocket
{
	float fire_delay;
	float attack_time;
}
Rocket Launcher[2049]; // :)

bool Enabled[MAXPLAYERS+1];
bool RemoteRocket[2049];
bool OtherRocket[2049];

ConVar AutoAim;
ConVar AttackTime;

public void OnPluginStart()
{
	RegAdminCmd("sm_rocketlauncher", CmdRockets, ADMFLAG_KICK);

	AutoAim = CreateConVar("rocket_launcher_auto_aim", "0", "Should a fired rocket launcher automatically target players", _, true, 0.0, true, 1.0);
	AttackTime = CreateConVar("rocket_launcher_fire_delay", "0.8", "Attack delay for fired rocket launchers");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	Enabled[client] = false;
}

Action CmdRockets(int client, int args)
{
	Enabled[client] = !Enabled[client];
	PrintToChat(client, "[SM] Rocket Launcher Launcher %s!", Enabled[client] ? "Enabled" : "Disabled");
	return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
	OtherRocket[entity] = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity < 1) //exclude world and entity references
		return;

	RemoteRocket[entity] = false;
	if (StrContains(classname, "tf_projectile_rocket") != -1)
		SDKHook(entity, SDKHook_SpawnPost, OnRocketSpawned);
}

void OnRocketSpawned(int entity)
{
	if (OtherRocket[entity])
		return;

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (IsValidClient(owner) && Enabled[owner])
	{
		SetEntityModel(entity, ROCKETMODEL); //Might need a request frame..
		RemoteRocket[entity] = true;
		Launcher[entity].fire_delay = AttackTime.FloatValue;
		Launcher[entity].attack_time = GetGameTime() + AttackTime.FloatValue;
	}
}

public void OnGameFrame()
{
	int rocket = MaxClients + 1;
	while ((rocket = FindEntityByClassname2(rocket, "tf_projectile_rocket")) != -1)
	{
		if (RemoteRocket[rocket] && !OtherRocket[rocket])
		{
			bool auto = AutoAim.BoolValue;
			Reference reference;
			reference.set(rocket);
			SimulateLauncher(reference, Launcher[rocket], auto);
		}
	}
}

void SimulateLauncher(Reference rocket, Rocket launcher, bool auto)
{
	if (rocket.valid())
	{
		//Determine how this launcher should aim
		float angles[3], aim[3], pos[3], rocket_pos[3];
		float aim_vector[3], aim_angles[3];

		int owner = GetEntPropEnt(rocket.get(), Prop_Data, "m_hOwnerEntity");
		if (!IsValidClient(owner))
			return;

		if (!auto)
		{
			GetClientEyePosition(owner, pos);
			GetClientEyeAngles(owner, angles);
			GetAimPosition(owner, pos, angles, aim);
		}
		else
		{
			int target = FindBestTarget(rocket.get(), owner, GetClientTeam(owner));
			if (IsValidClient(target))
				GetClientAbsOrigin(target, aim); //target's position will be the aim position
			else
				return;
		}
		//Aim rocket towards our aim position
		GetEntPropVector(rocket.get(), Prop_Data, "m_vecOrigin", rocket_pos);
		MakeVectorFromPoints(rocket_pos, aim, aim_vector);
		GetVectorAngles(aim_vector, aim_angles);
		TeleportEntity(rocket.get(), NULL_VECTOR, aim_angles, NULL_VECTOR);

		//Fire the launcher on the given interval
		if (launcher.attack_time <= GetGameTime())
		{
			launcher.attack_time = GetGameTime() + launcher.fire_delay;
			int proj = CreateEntityByName("tf_projectile_rocket");
			OtherRocket[proj] = true;

			SetEntPropEnt(proj, Prop_Data, "m_hOwnerEntity", owner);
			int team = GetClientTeam(owner);

			SetVariantInt(team);
			AcceptEntityInput(proj, "TeamNum");

			SetVariantInt(team);
			AcceptEntityInput(proj, "SetTeam");

			//Get forward position from launcher and offset by a few units to prevent collisions
			NormalizeVector(aim_vector, aim_vector);
			ScaleVector(aim_vector, 50.0);
			AddVectors(rocket_pos, aim_vector, rocket_pos);

			//Set velocity of rocket
			float vel[3];
			vel = aim_vector;
			NormalizeVector(vel, vel);
			ScaleVector(vel, 1100.0);

			TeleportEntity(proj, rocket_pos, aim_angles, vel);
			DispatchSpawn(proj);

			SetEntDataFloat(proj, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 90.0); //90 damage for stock rockets
		}
	}
}

///
/// Get aim position from player view angles
///

void GetAimPosition(int client, float pos[3], float angles[3], float buffer[3])
{
	Handle trace = TR_TraceRayFilterEx(pos, angles, MASK_SHOT, RayType_Infinite, FilterSelf, client);
	if (TR_DidHit(trace))
		TR_GetEndPosition(buffer, trace);

	CloseHandle(trace);
}

bool FilterSelf(int entity, int mask, int exclude)
{
	if (entity == exclude)
		return false;

	return true;
}

///
/// Automatically aquire aim position from nearby targets
///

int FindBestTarget(int rocket, int owner, int team)
{
	float closest = 8192.0;
	float pos[3], rocket_pos[3];
	int best;

	GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", rocket_pos);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == owner)
			continue;

		if (!IsValidClient(i))
			continue;

		if (GetClientTeam(i) == team)
			continue;

		if (!IsPlayerAlive(i))
			continue;

		GetClientAbsOrigin(i, pos);
		pos[2] += 40.0;

		float distance = GetVectorDistance(pos, rocket_pos);
		if (distance < closest)
		{
			Handle trace = TR_TraceRayFilterEx(rocket_pos, pos, MASK_SHOT, RayType_EndPoint, FilterSelf, rocket);
			if (TR_DidHit(trace))
			{
				int entity = TR_GetEntityIndex(trace);
				if (entity != i) //not visible, ignore this player
				{
					CloseHandle(trace);
					continue;
				}
				CloseHandle(trace);

				//Player is visible and closer than the last, set them as the new best target
				closest = distance;
				best = i;
			}
			else //cant find the player for whatever reason, move on to the next
			{
				CloseHandle(trace);
				continue;
			}
		}
	}
	return best;
}

bool IsValidClient(int client)
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
        return false;

    return true;
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt))
	startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
