#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#include <tf2>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Carpet Bomber"

bool Mirv[MAXPLAYERS+1];
ConVar PipeCount;
ConVar PipeDamage;
ConVar PipeScale;
ConVar PipeModel;
ConVar PipeSpeed;

enum struct Pointer
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
	bool valid(bool client)
	{
		int entity = this.get();
		if (client && IsRobot(entity, ROBOT_NAME))
			return true;

		if (IsValidEntity(entity))
			return entity > MaxClients;

		return false;
	}
}

enum struct Pipe
{
	Pointer owner;

	//checks to make sure this pipe is being removed from detonating and not just deleted
	bool mirv;
	bool detonated;
	float timer;

	int current_deflections;
	int last_deflections;

	bool touched; //dont want to use m_bTouched as that will mess with player hit detection
}
Pipe Grenade[2049];



public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Demoknight",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Demoknight from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_clusterbombs", CmdMirv, ADMFLAG_BAN);

	PipeCount = CreateConVar("boss_clusterbomb_count", "4", "Number of child grenades to spawn from a clusterbomb");
	PipeDamage = CreateConVar("boss_clusterbomb_damage", "200", "Percentage of parent grenade's damage that child grenades should deal");
	PipeScale = CreateConVar("boss_clusterbomb_scale", "1.25", "Model scale for child grenades");
	PipeModel = CreateConVar("boss_clusterbomb_iron_bomber", "1", "Should child grenades use the iron bomber projectile or derive the model from the parent");
	PipeSpeed = CreateConVar("boss_clusterbomb_speed", "300", "Max speed child grenades can be launched at");

}



public void OnEntityDestroyed(int entity)
{
	char classname[128];
	GetEntityClassname(entity, classname, sizeof classname);
	if (StrEqual(classname, "tf_projectile_pipe"))
		TryMirv(entity, Grenade[entity]);
}

void TryMirv(int pipe, Pipe grenade)
{
	if (grenade.owner.valid(true) && grenade.mirv)
	{
		grenade.mirv = false;
		
		grenade.detonated = (grenade.timer - GetGameTime() <= 0.15); //allow for some variance since the fuse timer will not be exact
		
		// if (grenade.detonated)
		ForceCluster(pipe, grenade);
	}
}

void ForceCluster(int pipe, Pipe grenade)
{
	grenade.mirv = false;

	//Derive everything about the child grenades from the parent clusterbomb
	float pos[3], vel[3], ang[3];
	int children = PipeCount.IntValue;

	float damage = GetEntPropFloat(pipe, Prop_Send, "m_flDamage") * (PipeDamage.FloatValue / 100.0);
	float scale = PipeScale.FloatValue;
	float speed = PipeSpeed.FloatValue;

	bool crit = view_as<bool>(GetEntProp(pipe, Prop_Send, "m_bCritical"));
	bool iron = PipeModel.BoolValue;

	GetEntPropVector(pipe, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(pipe, Prop_Data, "m_vecVelocity", vel);
	int team = GetEntProp(pipe, Prop_Send, "m_iTeamNum");
	pos[2] += 20.0;

	//Spawn child grenades
	for (int i = 1; i <= children; i++)
	{
		int child = CreateEntityByName("tf_projectile_pipe");
		float child_vel[3];
		float child_ang[3];
		//Prevent child grenades from detonating on contact
		SetEntProp(child, Prop_Send, "m_bTouched", 1);

		//Set properties
		SetEntProp(child, Prop_Send, "m_bCritical", view_as<int>(crit));
		SetEntPropEnt(child, Prop_Data, "m_hOwnerEntity", grenade.owner.get());
		SetEntPropFloat(child, Prop_Send, "m_flDamage", damage);
		SetEntPropFloat(child, Prop_Send, "m_flModelScale", scale);

		// for (int axis = 0; axis < 3; axis++)
		// 	child_vel[axis] = vel[axis] + GetRandomFloat(speed * -1.0, speed);


		for (int axis = 0; axis < 3; axis++){

			child_vel[axis] = vel[axis] + GetRandomFloat(speed * -1.0, speed);
			child_ang[axis] = ang[axis] + GetRandomFloat(-360.0 , 360.0);
		}

		int Weapon1 = GetPlayerWeaponSlot(grenade.owner.get(), TFWeaponSlot_Primary);

		SetEntProp(child, Prop_Send, "m_iTeamNum", team);
		SetEntProp(child, Prop_Send, "m_bIsLive", 1);

		// PrintToChatAll("Grenade owner was %N",grenade.owner.get() );

		

		DispatchSpawn(child);
		SDKHook(child, SDKHook_Touch, OnMirvOverlap);
		TeleportEntity(child, pos, child_ang, child_vel);

		//force iron bomber projectile model
		if (iron)
		{
			PrecacheModel("models/weapons/w_models/w_cannonball.mdl");
			SetEntityModel(child, "models/weapons/w_models/w_cannonball.mdl");
		}
		else{
			SetModelFromWeapon(child, grenade);
		}

		DataPack info = new DataPack();
		info.Reset();
		info.WriteCell(child);
		info.WriteCell(Weapon1);
		
		RequestFrame(SetOwnerStats, info);
		// PrintToChatAll("Owner was before %N", grenade.owner.get());
	}
}


void SetOwnerStats(DataPack info)
{
	//Get our player indexes and free up the handle
	info.Reset();
	int child = info.ReadCell();
	int owner = info.ReadCell();
	delete info;
	// PrintToChatAll("Owner was %N", owner);
	//m_hLauncher or m_hThrower
	// SetEntPropEnt(child, Prop_Send, "m_hOriginalLauncher", owner);
	SetEntPropEnt(child, Prop_Send, "m_hLauncher", owner);
}

Action OnMirvOverlap(int mirv, int other) //Never detonate on impact
{
	return Plugin_Stop;
}

//Loose cannon will not work as it uses different projectiles... this isn't too useful but leaving it just in case
void SetModelFromWeapon(int pipe, Pipe grenade)
{
	if (grenade.owner.valid(true))
	{
		char modelname[256];
		int weapon = GetPlayerWeaponSlot(grenade.owner.get(), TFWeaponSlot_Primary);
		if (weapon > MaxClients)
		{
			int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch (index)
			{
				case 1151: FormatEx(modelname, sizeof modelname, "models/workshop/weapons/c_models/c_quadball/w_quadball_grenade.mdl"); //iron bomber
				default: return;
			}
			PrecacheModel(modelname);
			SetEntityModel(pipe, modelname);
		}
	}
}

///
/// Check if the grenade should act as a cluster bomb
///

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_pipe"))
		SDKHook(entity, SDKHook_SpawnPost, OnSpawn);
}

void OnSpawn(int pipe)
{
	int owner = GetEntPropEnt(pipe, Prop_Send, "m_hOwnerEntity");
	if (IsRobot(owner, ROBOT_NAME))
	{
	//	PrintToChatAll("Setting scale");

		

		Grenade[pipe].owner.set(owner);
		Grenade[pipe].touched = false;
		RequestFrame(OnSpawnPost, EntIndexToEntRef(pipe)); //Not everything initializes right away so we will wait another frame before doing anything else
	}
}

void OnSpawnPost(any ref)
{
	int pipe = EntRefToEntIndex(ref);
	if (IsValidEntity(pipe) && pipe > MaxClients)
	{
		
		int launcher = GetEntPropEnt(pipe, Prop_Send, "m_hLauncher");
		if (launcher == -1)
			return;
		// PrintToChatAll("OnSpawnPost");
		float fuse = TF2Attrib_HookValueFloat(2.3, "fuse_mult", launcher); //roughly 2.3 seconds for normal pipe detonation time
		Grenade[pipe].timer = GetGameTime() + fuse;

		
		Grenade[pipe].detonated = false;
		Grenade[pipe].mirv = true;
		//PrintToChatAll("Setting scale");
		SetEntPropFloat(pipe, Prop_Send, "m_flModelScale", 1.6);
		// SDKHook(pipe, SDKHook_Touch, OnPipeTouch);
		SDKHook(pipe, SDKHook_VPhysicsUpdate, OnPipeUpdate);
	}
}

Action OnPipeUpdate(int pipe)
{
	if (Grenade[pipe].mirv)
	{
		Grenade[pipe].current_deflections = GetEntProp(pipe, Prop_Send, "m_iDeflected");
		if (Grenade[pipe].current_deflections > Grenade[pipe].last_deflections)
		{
			Grenade[pipe].last_deflections = Grenade[pipe].current_deflections;
			Grenade[pipe].owner.set(GetEntPropEnt(pipe, Prop_Data, "m_hThrower")); //after spawning, owner becomes invalid and thrower is valid
		}
	}
	return Plugin_Continue;
}

// Action OnPipeTouch(int pipe, int other)
// {
// 	if ((IsValidClient(other) || IsBuilding(other)) && Grenade[pipe].mirv)
// 	{
// 		if (GetEntProp(other, Prop_Send, "m_iTeamNum") != GetEntProp(pipe, Prop_Send, "m_iTeamNum"))
// 		{
// 			if (!GetEntProp(pipe, Prop_Send, "m_bTouched") && !Grenade[pipe].touched && Grenade[pipe].owner.valid(true))
// 			{
// 				Grenade[pipe].touched = true;
// 				ForceCluster(pipe, Grenade[pipe]);
// 			}
// 		}
// 	}
// 	return Plugin_Continue;
// }

Action CmdMirv(int client, int args)
{
	Mirv[client] = !Mirv[client];

	PrintToChat(client, "[SM] Clusterbombs: %s", Mirv[client] ? "Enabled" : "Disabled");
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	Mirv[client] = false;
}

// bool IsValidClient(int client)
// {
//     if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
//         return false;

//     return true;
// }

//Just a simple check to see if we hit a building
// bool IsBuilding(int entity)
// {
// 	char classname[64];
// 	GetEntityClassname(entity, classname, sizeof classname);
// 	if (StrContains(classname, "obj_") != -1)
// 		return true;

// 	return false;
// }
