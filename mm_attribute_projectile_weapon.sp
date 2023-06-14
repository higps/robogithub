/*
	Projectiles that fire copies of themsevles

	Attribute name = "projectile-fire-self"

	variables:
		Model = "projectile-model" - string
		Fire rate = "projectile-firedelay" - float
		Projectile speed = "projectile-speed" - float
*/

#pragma semicolon 1

#include <sdkhooks>
#include <ilib>
#include <ilib_objects>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>

public Plugin MyInfo =
{
	name = "Projectile Launchers",
	author = "IvoryPal",
	description = "Fired projectiles will fire themselves"
};

enum struct FProjectile
{
	float Speed;
	char Classname[64];

	FTimer NextFireTimer; // Timer for firing this projectile
	//FProjectileLauncher Launcher;
}
FProjectile Projectile[2049];

bool ProjectileLauncher[2049]; // Tags projectile as one that should fire more projectiles
char ProjectileModel[MAXPLAYERS+1][128]; // Model to use for the projectile which will fire itself

float FireDelay[MAXPLAYERS+1]; // Actual delay for the timer
float ProjSpeed[MAXPLAYERS+1]; // Speed that projectiles should be fired at


bool HasStat(int client, int weapon)
{
	if (weapon == -1)
	{
		return false;
	}

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(weapon, "projectile-fire-self", stat_buffer, sizeof(stat_buffer)))
	{
		return false;
	}

	ReadStringVar(stat_buffer, "projectile-model", ProjectileModel[client], sizeof ProjectileModel[]);
	FireDelay[client] = ReadFloatVar(stat_buffer, "projectile-firedelay");
	ProjSpeed[client] = ReadFloatVar(stat_buffer, "projectile-speed");

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
}

public void OnClientPostAdminCheck(int client)
{
	//clear variables
	FormatEx(ProjectileModel[client], sizeof ProjectileModel[], ""); // reset
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!(StrContains(classname, "tf_projectile_"))) // Any spawned projectile
	{
		RequestFrame(ProjectileSpawned, entity);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || entity > 2048) return; //prevent ent refs being used
	if (IsValidEntity(entity))
	{
		ProjectileLauncher[entity] = false;
	}
}

void ProjectileSpawned(int projId)
{
	FClient owner;
	FObject proj, launcher;
	proj = ConstructObject(projId);
	owner = CastToClient(proj.GetOwner());
	launcher = proj.GetPropEnt(Prop_Send, "m_hLauncher");

	// Let's check if this was launched by a launcher
	//FProjectileLauncher launcher;
	//if (ProjectileLaunched(proj, launcher))
	//	SetProjectileProperties(proj, launcher);

	if (owner.Valid())
	{
		if (ValidLauncher(proj) && HasStat(owner.Get(), launcher.Get()))
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
	int ownerId = owner.Get(); // client index
	int projId = entity.Get(); // entity index

	ProjectileLauncher[projId] = true;
	proj.NextFireTimer.Set(FireDelay[ownerId], false, true);

	// Spawn our launcher to fire grenades from
	/* Can't seem to get projectiles launched by a weapon mimic, so this won't work
	proj.Launcher = FProjectileLauncher();
	if (proj.Launcher.Valid())
	{
		// Set our parameters
		proj.Launcher.Type = WeaponType_Grenade;
		proj.Launcher.BaseSpeed = 1600.0;
		proj.Launcher.Damage = 100.0;

		// Let's setup the spawn parameters so it follows this grenade
		FTransform spawn;

		spawn.rotation = entity.GetAngles();
		spawn.position = entity.GetPosition();

		spawn.position.z += 5.0; // Shift slightly upwards

		FinishSpawn(proj.Launcher.GetObject(), spawn);

		// Now attach to this grenade
		proj.Launcher.GetObject().SetParent(entity);

		// Set the owner
		proj.Launcher.GetObject().SetOwner(owner.GetObject());
		proj.Launcher.GetObject().SetProp(Prop_Data, "m_iTeamNum", owner.GetTeam());
	}
	*/

	// Cache the classname here so we don't have to call this every time we fire the projectiles
	char classname[64];
	entity.GetClassname(classname, sizeof classname);
	FormatEx(proj.Classname, sizeof FProjectile::Classname, classname);

	proj.Speed = ProjSpeed[ownerId]; // Speed for child projectiles

	if (strlen(ProjectileModel[ownerId]))
	{
		SetEntityModel(projId, ProjectileModel[ownerId]); // This will likely change physics of the projectile
	}
}

// Now let's actually control the projectile
public void OnGameFrame()
{
	// Find any active projectiles that are tagged as projectile launchers
	int entityId = -1;
	while ((entityId = FindEntityByClassname(entityId, "tf_projectile*")) != -1)
	{
		if (ProjectileLauncher[entityId])
			OnProjectileTick(ConstructObject(entityId), Projectile[entityId]);
	}
}

void OnProjectileTick(FObject entity, FProjectile proj)
{
	if (entity.Valid() && proj.NextFireTimer.Expired())
	{
		FTransform spawn;

		spawn.rotation = entity.GetAngles();
		spawn.position = entity.GetPosition();

		FObject child;
		char classname[64];
		entity.GetClassname(classname, sizeof classname);

		child = CreateObjectDeferred(classname);

		// Shift upwards a bit to prevent collisions
		spawn.position.z += 2.0;

		// We can now spawn the projectile and set the velocity
		spawn.velocity = spawn.rotation.GetForwardVector();
		spawn.velocity.Scale(proj.Speed);
		FinishSpawn(child, spawn);

		FObject launcher;
		launcher = entity.GetPropEnt(Prop_Send, "m_hLauncher");
		child.SetPropEnt(Prop_Send, "m_hLauncher", launcher);

		child.SetProp(Prop_Send, "m_bCritical", entity.GetProp(Prop_Send, "m_bCritical"));

		if (child.Cast("tf_projectile_pipe")) // Settings for pipes
		{
			child.SetProp(Prop_Send, "m_bTouched", 1); // Don't detonate on impact
			child.SetPropFloat(Prop_Send, "m_flDamage", entity.GetPropFloat(Prop_Send, "m_flDamage"));
			child.SetPropFloat(Prop_Send, "m_DmgRadius", entity.GetPropFloat(Prop_Send, "m_DmgRadius"));
		}
		else if (child.Cast("tf_projectile_rocket") || child.Cast("tf_projectile_energy_ball"))
		{
			// Damage on rockets is an unnamed property
			int offset = FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4;
			SetEntDataFloat(child.Get(), offset, GetEntDataFloat(entity.Get(), offset));
		}

		// Now let's set our owner, we do this after spawning to ensure we don't end up spawning an infinite amount of projectiles
		DataPack pack = new DataPack();

		pack.WriteCellArray(entity, sizeof FObject);
		pack.WriteCellArray(child, sizeof FObject);
		RequestFrame(OnChildPost, pack);
	}
}

void OnChildPost(DataPack pack)
{
	FObject child, entity;

	pack.Reset();
	pack.ReadCellArray(entity, sizeof FObject);
	pack.ReadCellArray(child, sizeof FObject);

	child.SetOwner(entity.GetOwner());

	delete pack;
}
