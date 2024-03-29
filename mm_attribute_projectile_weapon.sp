/*
	Projectiles that fire copies of themsevles

	Attribute name = "projectile-fire-self"

	variables:
		Model = "projectile-model" - string
		Fire rate = "projectile-firedelay" - float
		Projectile speed = "projectile-speed" - float
		Fire Sound - "projectile-firesound" - string
		Bomber - "projectile-bomber" - integer [0, 1]
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
	bool Bomber;

	FTimer NextFireTimer; // Timer for firing this projectile
	//FProjectileLauncher Launcher;
}
FProjectile Projectile[2049];

bool ChildBomb[2049] = {false, ...}; // Projectiles fired from projectile launchers, ignore these when spawned.

bool ProjectileLauncher[2049]; // Tags projectile as one that should fire more projectiles
char ProjectileModel[MAXPLAYERS+1][128]; // Model to use for the projectile which will fire itself
char ProjectileFireSound[MAXPLAYERS+1][128]; // Sound to use for projectiles being fired

float FireDelay[MAXPLAYERS+1]; // Actual delay for the timer
float ProjSpeed[MAXPLAYERS+1]; // Speed that projectiles should be fired at

bool Bombing[MAXPLAYERS+1] = {false, ...}; // If true, the projecile launcher will fire directly downwards in a boming fashion


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
	ReadStringVar(stat_buffer, "projectile-firesound", ProjectileFireSound[client], sizeof ProjectileFireSound[]);
	FireDelay[client] = ReadFloatVar(stat_buffer, "projectile-firedelay", 1.0);
	ProjSpeed[client] = ReadFloatVar(stat_buffer, "projectile-speed", 1100.0);
	Bombing[client] = view_as<bool>(ReadIntVar(stat_buffer, "projectile-bomber", 0));

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
	FormatEx(ProjectileFireSound[client], sizeof ProjectileFireSound[], "");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!(StrContains(classname, "tf_projectile_"))) // Any spawned projectile
	{
		RequestFrame(ProjectileSpawned, ConstructObject(entity).Reference);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || entity > 2048) return; //prevent ent refs being used
	if (IsValidEntity(entity))
	{
		ProjectileLauncher[entity] = false;

		ChildBomb[entity] = false;
	}
}

void ProjectileSpawned(int projRef)
{
	// If our projectile is somehow removed by this time, abort the function
	FObject proj;
	proj.Reference = projRef;
	if (!proj.Valid())
		return;

	// Ignore projectiles spawned from a launcher already
	if (ChildBomb[proj.Get()])
		return;

	FClient owner;
	FObject launcher;
	int projId = proj.Get();
	owner = CastToClient(proj.GetOwner());
	launcher = proj.GetPropEnt(Prop_Send, "m_hLauncher");

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

	// Cache the classname here so we don't have to call this every time we fire the projectiles
	char classname[64];
	entity.GetClassname(classname, sizeof classname);
	FormatEx(proj.Classname, sizeof FProjectile::Classname, classname);

	proj.Speed = ProjSpeed[ownerId]; // Speed for child projectiles
	proj.Bomber = Bombing[ownerId];

	if (strlen(ProjectileModel[ownerId]) > 3)
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
			OnProjectileTick(ConstructObject(entityId), Projectile[entityId], CastToClient(ConstructObject(entityId).GetOwner()));
	}
}

void OnProjectileTick(FObject entity, FProjectile proj, FClient owner)
{
	if (entity.Valid() && proj.NextFireTimer.Expired())
	{
		FTransform spawn;

		spawn.Rotation = entity.GetAngles();
		spawn.Position = entity.GetPosition();

		FObject child;
		char classname[64];
		entity.GetClassname(classname, sizeof classname);

		child = FGameplayStatics.CreateObjectDeferred(classname);

		// Sets the launcher for this child projectile
		SetProjectileLauncher(entity, child);

		ChildBomb[child.Get()] = true;

		child.SetOwner(entity.GetOwner());

		// Shift upwards a bit to prevent collisions
		spawn.Position.Z += 2.0;
		if (proj.Bomber)
		{
			spawn.Rotation.Pitch += 90.0;
		}
		// We can now spawn the projectile and set the velocity
		spawn.Velocity = spawn.Rotation.GetForwardVector();
		spawn.Velocity.Scale(proj.Speed);
		FGameplayStatics.FinishSpawn(child, spawn);

		// Play our fire sound
		if (owner.Valid())
		{
			if (strlen(ProjectileFireSound[owner.Get()]) > 3)
			{
				PrecacheSound(ProjectileFireSound[owner.Get()]);
				EmitSoundToAll(ProjectileFireSound[owner.Get()], entity.Get());
			}
		}

		// Using safer methods for setting properties, also much cleaner than before
		SetProjectileProperties(UBaseProjectile(entity), UBaseProjectile(child));
	}
}

void SetProjectileProperties(UBaseProjectile parent, UBaseProjectile child)
{
	// If one of these casts fail, abort
	if (!parent.Valid() || !child.Valid())
		return;

	// Set our properties for the newly spawned projectile
	child.Critical = parent.Critical;
	child.Damage = parent.Damage;
	child.Team = parent.Team;

	if (parent.Cast("tf_projectile_pipe")) // Pipes need m_flFullDamage set for impact damage 
		SetFullDamage(parent, child);
}

void SetFullDamage(UBaseProjectile parent, UBaseProjectile child)
{
	// not a networked property so we need to get its offset
	int damageOffset = FindSendPropInfo("CTFGrenadePipebombProjectile", "m_bDefensiveBomb") - 4; // 4 bytes before m_bDefensiveBomb

	if (damageOffset > 0)
	{
		float fullDamage = GetEntDataFloat(parent.Get(), damageOffset);
		SetEntDataFloat(child.Get(), damageOffset, fullDamage);
	}
}

void SetProjectileLauncher(FObject entity, FObject child)
{
	FObject launcher;
	launcher = entity.GetPropEnt(Prop_Send, "m_hLauncher");
	// If this is invalid, try checking the original launcher in case of an airblast
	if (!launcher.Valid())
	{
		launcher = entity.GetPropEnt(Prop_Send, "m_hOriginalLauncher");
		child.SetPropEnt(Prop_Send, "m_hOriginalLauncher", launcher);
	}
	else // otherwise set our launcher
		child.SetPropEnt(Prop_Send, "m_hLauncher", launcher);
}
