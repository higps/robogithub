#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Shounic"

#define ROCKETMODEL "models/weapons/c_models/c_rocketlauncher/c_rocketlauncher.mdl"

public Plugin:myinfo = 
{
	name = "[TF2] Shounic Ability",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Shounic Ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

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
	bool critical;

	Reference particle;
	Reference particle_crit;
}
Rocket Launcher[2049]; // :)

bool RemoteRocket[2049];
bool OtherRocket[2049];

int RocketModel;

ConVar AutoAim;
ConVar AttackTime;



char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

public OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

	LoadTranslations("common.phrases");

	AutoAim = CreateConVar("shounic_rocket_launcher_auto_aim", "0", "Should a fired rocket launcher automatically target players", _, true, 0.0, true, 1.0);
	AttackTime = CreateConVar("shounic_rocket_launcher_fire_delay", "0.9", "Attack delay for fired rocket launchers");
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantSoldier", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnMapStart()
{
	RocketModel = PrecacheModel(ROCKETMODEL);
}

///ROCKET CODE

public void OnEntityDestroyed(int entity)
{
	if (entity > 1 && entity < 2049)
	{
		OtherRocket[entity] = false;
		if (Launcher[entity].particle.valid())
		{
			int particle = Launcher[entity].particle.get();
			RemoveEntity(particle);
		}
		if (Launcher[entity].particle_crit.valid())
		{
			int particle = Launcher[entity].particle_crit.get();
			RemoveEntity(particle);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity > 1 && entity < 2049) //exclude entity references...
	{
		RemoteRocket[entity] = false;
		if (StrContains(classname, "tf_projectile_rocket") != -1)
			SDKHook(entity, SDKHook_SpawnPost, OnRocketSpawned);
	}
}

void OnRocketSpawned(int entity)
{
	if (OtherRocket[entity])
		return;

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (IsRobot(owner, ROBOT_NAME))
	{
		SetModelOverride(entity, RocketModel); //Set model without altering collision bounds
		int particle = CreateParticle(entity, "rockettrail"); //critical_rocket_red/blue
		Launcher[entity].particle.set(particle);

		RemoteRocket[entity] = true;
		Launcher[entity].fire_delay = AttackTime.FloatValue;
		Launcher[entity].attack_time = GetGameTime() + AttackTime.FloatValue;
		RequestFrame(OnRocketSpawnedPost, entity);
	}
}

void OnRocketSpawnedPost(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	Launcher[entity].critical = view_as<bool>(GetEntProp(entity, Prop_Send, "m_bCritical"));
	if(Launcher[entity].critical)
	{
		int team = GetClientTeam(owner);
		int crit_particle;
		switch (team)
		{
			case 2: crit_particle = CreateParticle(entity, "critical_rocket_red");
			case 3: crit_particle = CreateParticle(entity, "critical_rocket_blue");
			default: crit_particle = CreateParticle(entity, "critical_rocket_blue");
		}
		Launcher[entity].particle_crit.set(crit_particle);
	}
}

void SetModelOverride(int rocket, int model)
{
	for (int i = 0; i < 4; i++)
		SetEntProp(rocket, Prop_Send, "m_nModelIndexOverrides", model, _, i);
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
			int weapon = GetEntPropEnt(rocket.get(), Prop_Send, "m_hOriginalLauncher");
			int proj = CreateEntityByName("tf_projectile_rocket");
			OtherRocket[proj] = true;

			PrecacheSound("weapons/rocket_shoot.wav");
			EmitSoundToAll("weapons/rocket_shoot.wav", proj, SNDCHAN_AUTO, 80);

			SetEntPropEnt(proj, Prop_Data, "m_hOwnerEntity", owner);
			int team = GetClientTeam(owner);

			SetVariantInt(team);
			AcceptEntityInput(proj, "TeamNum");

			SetVariantInt(team);
			AcceptEntityInput(proj, "SetTeam");

			SetEntProp(proj, Prop_Send, "m_bCritical", view_as<int>(launcher.critical));
			SetEntPropEnt(proj, Prop_Send, "m_hOriginalLauncher", weapon); //proper damage rampup and falloff values

			//Get forward position from launcher and offset by a few units to prevent collisions
			NormalizeVector(aim_vector, aim_vector);
			ScaleVector(aim_vector, 20.0);
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

	char classname[64];
	GetEntityClassname(entity, classname, sizeof classname);
	if (StrContains(classname, "tf_projectile_") != -1)
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


stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt))
	startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

int CreateParticle(int entity, char[] name)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
		pos[2] += 5.0;

		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", name);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", entity, particle, 0);

		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
	}
	return particle;
}
