/*
	Rockets which orbit their flight path

	Attribute name = "rockets-orbit-path"

	variables:
		orbit-radius - Radius of the orbit
		orbit-type - How the rockets are configured to orbit. 0 = no orbit, 1 = single rocket orbiting horizontally, 2 = multiple rockets orbiting a core rocket
		orbit-hide-core - If orbit-type is set to 2, the core rocket will be hidden
		orbit-speed - How fast the child rocket orbit around the center
		orbit-count - How many child rockets to spawn
		delay-spawn - If non-zero, delays the spawn of the orbiting rockets by this value
		acceleration - Scales speed of rocket by this value every 0.1s
		max-rocket-speed - If acceleration is non-zero, speed will not scale above or below this value (if acceleration is negative)
*/

#pragma semicolon 1

#include <sdkhooks>
#include <ilib>
#include <ilib_objects>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>

public Plugin MyInfo =
{
	name = "Orbiting Rockets",
	author = "IvoryPal",
	description = "Fired rockets will orbit their path"
};

enum struct FProjectile
{
	ArrayList Rockets;
	FObject Rotator;
}
FProjectile Projectile[2049];

float OrbitRadius[MAXPLAYERS+1] = {100.0, ...};
float OrbitSpeed[MAXPLAYERS+1] = {250.0, ...};
float RotSpeed[MAXPLAYERS+1] = {0.0, ...};
bool ClientHasOrbit[MAXPLAYERS+1] = {false, ...};
bool ChildRocket[2049] = {false, ...};
int OrbitType[MAXPLAYERS+1] = {0, ...};
int OrbitCount[MAXPLAYERS+1] = {1, ...};
bool HideCore[MAXPLAYERS+1] = {false, ...};
float DelaySpawn[MAXPLAYERS+1] = {0.1, ...};
float Acceleration[MAXPLAYERS+1] = {1.0, ...};
float MaxSpeed[MAXPLAYERS+1] = {1100.0, ...};

bool HasStat(int client, int weapon)
{
	if (weapon == -1)
	{
		return false;
	}

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(weapon, "rockets-orbit-path", stat_buffer, sizeof(stat_buffer)))
	{
		return false;
	}

	OrbitRadius[client] = ReadFloatVar(stat_buffer, "orbit-radius", 100.0);
	OrbitType[client] = ReadIntVar(stat_buffer, "orbit-type", 1);
	if (OrbitType[client] > 2)
	{
		OrbitType[client] = 2;
	}
	HideCore[client] = view_as<bool>(ReadIntVar(stat_buffer, "orbit-hide-core"));
	OrbitSpeed[client] = ReadFloatVar(stat_buffer, "orbit-speed", 250.0);
	OrbitCount[client] = ReadIntVar(stat_buffer, "orbit-count", 1);
	DelaySpawn[client] = ReadFloatVar(stat_buffer, "spawn-delay", 0.0);
	Acceleration[client] = ReadFloatVar(stat_buffer, "acceleration", 0.0);
	MaxSpeed[client] = ReadFloatVar(stat_buffer, "max-rocket-speed", 1100.0);

	if (OrbitType[client] < 1)
	{
		return false;
	}

	if (OrbitCount[client] < 1)
	{
		return false;
	}

	return true;
}

public void OnPluginStart()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPostAdminCheck(client);
		}
	}

	RegAdminCmd("sm_orbitrockets", CmdOrbitRockets, ADMFLAG_BAN);
}


Action CmdOrbitRockets(int client, int args)
{
	ClientHasOrbit[client] = !ClientHasOrbit[client];

	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	OrbitRadius[client] = 50.0; // Reset to default
	OrbitSpeed[client] = 250.0;
	ClientHasOrbit[client] = false;
	OrbitType[client] = 2;
	OrbitCount[client] = 3;
	HideCore[client] = true;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!(StrContains(classname, "tf_projectile_rocket"))) // Only rockets
	{
		RequestFrame(ProjectileSpawned, ConstructObject(entity).Reference);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || entity > 2048) return; //prevent ent refs being used
	if (IsValidEntity(entity))
	{
		if (Projectile[entity].Rockets)
		{
			delete Projectile[entity].Rockets;
		}
		Projectile[entity].Rotator.Reference = INVALID_ENT_REFERENCE;
		ChildRocket[entity] = false;
	}
}

void ProjectileSpawned(int projRef)
{
	// If our projectile is somehow removed by this time, abort the function
	FObject proj;
	proj.Reference = projRef;
	if (!proj.Valid())
		return;

	FClient owner;
	FObject launcher;
	int projId = proj.Get();
	if (ChildRocket[projId])
	{
		return;
	}

	owner = CastToClient(proj.GetOwner());
	launcher = proj.GetPropEnt(Prop_Send, "m_hLauncher");

	if (owner.Valid())
	{
		if (ValidLauncher(proj) && (HasStat(owner.Get(), launcher.Get()) || ClientHasOrbit[owner.Get()]))
		{
			SetupProjectile(proj, owner);
		}
	}
}

bool ValidLauncher(FObject entity)
{
	FWeapon weapon;
	weapon = CastToWeapon(entity.GetPropEnt(Prop_Send, "m_hLauncher"));

	return weapon.Valid();
}

void SetupProjectile(FObject entity, FClient owner)
{
	int ownerId = owner.Get();
	int projId = entity.Get();

	URocket original = CastToRocket(UObject(projId));
	if (DelaySpawn[ownerId] < 0.1 && (OrbitType[ownerId] == 1 || HideCore[ownerId]))
	{
		SetEntityModel(original.Get(), "models/empty.mdl");
	}
	else
	{
		entity.SetPropFloat(Prop_Send, "m_flModelScale", 1.25);
	}

	SDKHook(projId, SDKHook_Touch, OnRocketOverlap);

	if (DelaySpawn[ownerId] >= 0.1)
	{
		DataPack pack = new DataPack();
		pack.WriteCellArray(entity, sizeof FObject);
		pack.WriteCell(original);
		pack.WriteCellArray(owner, sizeof FClient);
		CreateTimer(DelaySpawn[ownerId], DelayedSpawn, pack, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		CreateProjectileRing(entity, original, Projectile[projId], owner);
	}
}

Action DelayedSpawn(Handle timer, DataPack pack)
{
	pack.Reset();
	FObject entity;
	FClient owner;
	pack.ReadCellArray(entity, sizeof FObject);
	URocket rocket = pack.ReadCell();
	pack.ReadCellArray(owner, sizeof FClient);
	delete pack;

	if (rocket.Valid())
	{
		SetEntityModel(rocket.Get(), "models/empty.mdl");
		CreateParticleSystem("ExplosionCore_MidAir", entity.GetPosition(), entity.GetAngles(), 1.0);
		EmitAmbientGameSound("BaseExplosionEffect.Sound", entity.GetPosition().ToFloat(), entity.Get());
	}

	if (entity.Valid() && owner.Valid())
	{
		CreateProjectileRing(entity, rocket, Projectile[entity.Get()], owner);
	}

	return Plugin_Stop;
}

void CreateProjectileRing(FObject entity, URocket original, FProjectile proj, FClient owner)
{
	int ownerId = owner.Get();

	FTransform spawn;
	spawn.Position = entity.GetPosition();
	spawn.Rotation = entity.GetAngles();
	spawn.Rotation.Pitch = 0.0;

	FObject rotator;
	rotator = FGameplayStatics.CreateObjectDeferred("func_rotating");
	switch (OrbitType[ownerId])
	{
		case 1: rotator.SetKeyValue("spawnflags", "0"); // rotate on Z-axis
		case 2:
		{
			rotator.SetKeyValue("spawnflags", "8"); // rotate on Y-axis
			spawn.Rotation.Yaw += 90.0;
		}
	}
	rotator.SetKeyValueFloat("maxspeed", OrbitSpeed[ownerId]);
	FGameplayStatics.FinishSpawn(rotator, spawn);
	SetEntityCollisionGroup(rotator.Get(), 23);
	rotator.SetProp(Prop_Data, "m_usSolidFlags", 4);
	rotator.SetParent(entity);
	rotator.Input("Start");

	proj.Rotator = rotator;

	float rotspeed = 1.0;
	if (Acceleration[ownerId] > 1.0)
	{
		rotspeed = 0.5;
	}

	SetVariantFloat(rotspeed);
	RotSpeed[ownerId] = rotspeed;
	rotator.Input("SetSpeed");

	//PrintToChatAll("Position: %.1f, %.1f, %.1f", spawn.Position.X, spawn.Position.Y, spawn.Position.Z);
	if (original.Valid())
	{
		int rockets = OrbitCount[ownerId];
		float theta = ((FLOAT_PI * 2) / rockets);
		float radius = OrbitRadius[ownerId];
		FVector offset, origin;
		FRotator offsetAngle;
		offsetAngle = Vector_GetAngles(entity.GetAngles().GetUpVector()); // offset vertically
		origin = entity.GetPosition();
		proj.Rockets = new ArrayList(32);
		for (int i = 0; i < rockets; i++)
		{
			float angle = theta * i;

			offset.X = (radius * Cosine(angle));
			offset.Y = (radius * Sine(angle));
			offset.Z = 0.0;

			offset = FMath.OffsetVector(origin, offsetAngle, offset);

			URocket rocket = URocket();
			rocket.Damage = original.Damage;
			rocket.GetObject().SetOwner(owner.GetObject());
			rocket.Critical = original.Critical;

			SetVariantInt(owner.GetTeam());
			rocket.GetObject().Input("SetTeam");
			SetVariantInt(owner.GetTeam());
			rocket.GetObject().Input("TeamNum");

			spawn.Position = offset;
			spawn.Rotation = entity.GetAngles();
			FGameplayStatics.FinishSpawn(rocket.GetObject(), spawn);
			//rocket.FireProjectile(spawn.Rotation, 0.0);

			rocket.GetObject().SetParent(rotator);
			rocket.GetObject().SetPropEnt(Prop_Send, "m_hOriginalLauncher", entity.GetPropEnt(Prop_Send, "m_hOriginalLauncher"));
			rocket.GetObject().SetPropEnt(Prop_Send, "m_hLauncher", entity.GetPropEnt(Prop_Send, "m_hLauncher"));

			ChildRocket[rocket.Get()] = true;

			proj.Rockets.Push(rocket.GetObject().Reference);
		}

		if (Acceleration[ownerId] > 1.001 || Acceleration[ownerId] < 0.999)
		{
			DataPack pack = new DataPack();
			pack.WriteCell(owner.GetReference());
			pack.WriteCell(original);
			pack.WriteCellArray(rotator, sizeof FObject);
			CreateTimer(0.1, RocketUpdateSpeed, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action RocketUpdateSpeed(Handle timer, DataPack pack)
{
	if (pack)
	{
		pack.Reset();
		FClient owner;
		owner.SetReference(pack.ReadCell());
		URocket rocket = pack.ReadCell();
		FObject rotator;
		pack.ReadCellArray(rotator, sizeof FObject);

		float accel = Acceleration[owner.Get()];

		if (owner.Valid() && rocket.Valid())
		{
			Action result = Plugin_Continue;
			float speed = rocket.Speed * accel;
			float max = MaxSpeed[owner.Get()];
			RotSpeed[owner.Get()] *= accel;

			if (accel > 1.001)
			{
				if (speed >= max)
				{
					speed = max;
					delete pack;
					result = Plugin_Stop;
				}
			}
			else if (accel < 0.999)
			{
				if (RotSpeed[owner.Get()] <= 0.2)
				{
					RotSpeed[owner.Get()] = 0.2;
				}
				if (speed <= max)
				{
					speed = max;
					delete pack;
					result = Plugin_Stop;
				}
			}
			rocket.FireProjectile(rocket.GetObject().GetAngles(), speed);
			SetVariantFloat(RotSpeed[owner.Get()]);
			rotator.Input("SetSpeed");
			UpdateChildSpeed(rocket);

			return result;
		}

		delete pack;
		return Plugin_Stop;
	}

	return Plugin_Stop;
}

void UpdateChildSpeed(URocket rocket)
{
	ArrayList children = Projectile[rocket.Get()].Rockets;
	if (children)
	{
		FObject child;
		for (int i = 0; i < children.Length; i++)
		{
			child.SetReference(children.Get(i));
			if (child.Valid())
			{
				//float speed = rocket.Speed;

				FVector velocity;
				velocity = rocket.GetObject().GetAngles().GetForwardVector();
				velocity.Scale(0.0);
				TeleportEntity(child.Get(), NULL_VECTOR, NULL_VECTOR, velocity.ToFloat());
			}
		}
	}
}

Action OnRocketOverlap(int rocketId, int otherId)
{
	URocket rocket = CastToRocket(UObject(rocketId));
	if (rocket.Valid())
	{
		bool solid = false;
		FObject hit;
		hit = ConstructObject(otherId);
		if (hit.Valid())
		{
			if (IsObjectSolid(hit)) // Object is solid, free our children
			{
				solid = true;
			}
		}

		if (otherId == 0) // worldspawn
		{
			solid = true;
		}

		if (solid)
		{
			ArrayList children = Projectile[rocketId].Rockets;
			if (children)
			{
				FObject child;
				for (int i = 0; i < children.Length; i++)
				{
					child.SetReference(children.Get(i));
					if (child.Valid())
					{
						child.Input("ClearParent");
						float speed = rocket.Speed;

						FVector velocity;
						velocity = child.GetAngles().GetForwardVector();
						velocity.Scale(speed);
						TeleportEntity(child.Get(), NULL_VECTOR, NULL_VECTOR, velocity.ToFloat());
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

bool IsObjectSolid(FObject entity)
{
	return ((entity.GetProp(Prop_Send, "m_nSolidType") != 0) && !(entity.GetProp(Prop_Send, "m_usSolidFlags") & 4));
}
