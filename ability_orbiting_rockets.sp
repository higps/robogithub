/*
	Rockets which orbit their flight path

	Attribute name = "rockets-orbit-path"

	variables:
		orbit-radius - Radius of the orbit
		orbit-type - How the rockets are configured to orbit. 0 = no orbit, 1 = single rocket orbiting horizontally, 2 = multiple rockets orbiting a core rocket
		orbit-hide-core - If orbit-type is set to 2, the core rocket will be hidden
		orbit-speed - How fast the child rocket orbit around the center
		orbit-count - How many child rockets to spawn
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
	description = "Fired will orbit their path"
};

enum struct FProjectile
{
	ArrayList Rockets;
	FObject Rotator;
}
FProjectile Projectile[2049];

float OrbitRadius[MAXPLAYERS+1] = {100.0, ...};
float OrbitSpeed[MAXPLAYERS+1] = {250.0, ...};
bool ClientHasOrbit[MAXPLAYERS+1] = {false, ...};
bool ChildRocket[2049] = {false, ...};
int OrbitType[MAXPLAYERS+1] = {0, ...};
int OrbitCount[MAXPLAYERS+1] = {1, ...};
bool HideCore[MAXPLAYERS+1] = {false, ...};

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

	//RegAdminCmd("sm_orbitrockets", CmdOrbitRockets, ADMFLAG_BAN);
}

/*
Action CmdOrbitRockets(int client, int args)
{
	ClientHasOrbit[client] = !ClientHasOrbit[client];

	return Plugin_Handled;
}
*/

public void OnClientPostAdminCheck(int client)
{
	OrbitRadius[client] = 50.0; // Reset to default
	ClientHasOrbit[client] = false;
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
			SetupProjectile(proj, Projectile[projId], owner);
		}
	}
}

bool ValidLauncher(FObject entity)
{
	FWeapon weapon;
	weapon = CastToWeapon(entity.GetPropEnt(Prop_Send, "m_hLauncher"));

	return weapon.Valid();
}

void SetupProjectile(FObject entity, FProjectile proj, FClient owner)
{
	int ownerId = owner.Get();
	int projId = entity.Get();

	URocket original = CastToRocket(UObject(projId));
	//SetEntityModel(projId, "models/empty.mdl");
	entity.SetPropFloat(Prop_Send, "m_flModelScale", 1.25);

	SDKHook(projId, SDKHook_Touch, OnRocketOverlap);

	FTransform spawn;
	spawn.Position = entity.GetPosition();
	spawn.Rotation = entity.GetAngles();

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
	//rotator.Teleport(spawn.Position, spawn.Rotation, ConstructVector());
	rotator.SetParent(entity);
	rotator.Input("Start");

	proj.Rotator = rotator;

	SetVariantFloat(1.0);
	rotator.Input("SetSpeed");

	//PrintToChatAll("Position: %.1f, %.1f, %.1f", spawn.Position.X, spawn.Position.Y, spawn.Position.Z);
	if (original.Valid())
	{
		if (OrbitType[ownerId] == 1 || HideCore[ownerId])
		{
			SetEntityRenderMode(original.Get(), RENDER_NONE);
		}
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
			rocket.Damage = original.Damage / float(rockets);
			rocket.GetObject().SetOwner(owner.GetObject());
			
			SetVariantInt(owner.GetTeam());
			rocket.GetObject().Input("SetTeam");
			SetVariantInt(owner.GetTeam());
			rocket.GetObject().Input("TeamNum");

			spawn.Position = offset;
			spawn.Rotation = entity.GetAngles();
			FGameplayStatics.FinishSpawn(rocket.GetObject(), spawn);

			rocket.GetObject().SetParent(rotator);
			rocket.GetObject().SetPropEnt(Prop_Send, "m_hOriginalLauncher", entity.GetPropEnt(Prop_Send, "m_hOriginalLauncher"));
			rocket.GetObject().SetPropEnt(Prop_Send, "m_hLauncher", entity.GetPropEnt(Prop_Send, "m_hLauncher"));

			ChildRocket[rocket.Get()] = true;

			proj.Rockets.Push(rocket.GetObject().Reference);
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
