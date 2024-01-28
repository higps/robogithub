#include <tf2_stocks>
#include "ilib/entity.inc"
#include "ilib/vector.inc"

#if defined _ilib_projlauncher_included
 #endinput
#endif
#define _ilib_projlauncher_included

// Enum for setting the type of a weapon mimic
enum ELauncherType
{
	Launcher_Rocket = 0,
	Launcher_Grenade,
	Launcher_Arrow,
	Launcher_Sticky
};

/*
* Map used to wrap around tf_point_weapon_mimic
* 
*/

methodmap UProjectileLauncher < UObject
{
	/*
	* Creates a projectile launcher with the given type and properties
	*
	* @param entity			If casting, test this entity
	* @param cast			Use this constructor as a cast
	* 
	* @return Wrapper for a deferred FObject. Use FinishSpawn() to activate
	*/
	public UProjectileLauncher(FObject entity = {}, bool cast = false)
	{
		// Cast to the given entity first
		if (entity.Valid() && cast)
		{
			if (entity.Cast("tf_point_weapon_mimic"))
				return view_as<UProjectileLauncher>(entity.Reference);
			else return view_as<UProjectileLauncher>(0);

		}

		// If we are not given an entity and we aren't casting, create a new launcher
		else if (!entity.Valid() && !cast)
		{
			FObject launcher;
			launcher = FGameplayStatics.CreateObjectDeferred("tf_point_weapon_mimic");

			// Setup default values
			ELauncherType type = Launcher_Rocket;
			int damage = 90;
			float speed = 1100.0;
			float blastradius = 146.0;
			float scale = 1.0;
			
			launcher.SetProp(Prop_Data, "m_nWeaponType", view_as<int>(type));

			// Speeds
			launcher.SetPropFloat(Prop_Data, "m_flSpeedMin", speed);
			launcher.SetPropFloat(Prop_Data, "m_flSpeedMax", speed);

			// Damage and radius
			launcher.SetKeyValueInt("Damage", damage);
			launcher.SetPropFloat(Prop_Data, "m_flSplashRadius", blastradius);

			// Set the scale
			launcher.SetPropFloat(Prop_Data, "m_flModelScale", scale);

			return view_as<UProjectileLauncher>(launcher.Reference);
		}
		else // Otherwise don't create anything
		{
			return view_as<UProjectileLauncher>(0);
		}
	}

	// Type of weapon this launcher will mimic
	property ELauncherType Type
	{
		public set(ELauncherType value)
		{
			this.GetObject().SetProp(Prop_Data, "m_nWeaponType", view_as<int>(value));
		}
		public get()
		{
			return view_as<ELauncherType>(this.GetObject().GetProp(Prop_Data, "m_nWeaponType"));
		}
	}

	// Sets both min and max speed on this launcher
	property float BaseSpeed
	{
		public set(float value)
		{
			this.GetObject().SetPropFloat(Prop_Data, "m_flSpeedMax", value);
			this.GetObject().SetPropFloat(Prop_Data, "m_flSpeedMin", value);
		}
	}

	// Maximum speed for projectiles
	property float MaxSpeed
	{
		public set(float value)
		{
			this.GetObject().SetPropFloat(Prop_Data, "m_flSpeedMax", value);
		}
		public get()
		{
			return this.GetObject().GetPropFloat(Prop_Data, "m_flSpeedMax");
		}
	}

	// Minimum speed for projectiles
	property float MinSpeed
	{
		public set(float value)
		{
			this.GetObject().SetPropFloat(Prop_Data, "m_flSpeedMin", value);
		}
		public get()
		{
			return this.GetObject().GetPropFloat(Prop_Data, "m_flSpeedMin");
		}
	}

	// Damage for projectiles
	property float Damage
	{
		public set(float value)
		{
			this.GetObject().SetPropFloat(Prop_Data, "m_flDamage", value);
		}
		public get()
		{
			return this.GetObject().GetPropFloat(Prop_Data, "m_flDamage");
		}
	}

	// Splash radius
	property float BlastRadius
	{
		public set(float value)
		{
			this.GetObject().SetPropFloat(Prop_Data, "m_flSplashRadius", value);
		}
		public get()
		{
			return this.GetObject().GetPropFloat(Prop_Data, "m_flSplashRadius");
		}
	}

	// Spread angle for this launcher
	property float Inaccuracy
	{
		public set(float value)
		{
			this.GetObject().SetPropFloat(Prop_Data, "m_flSpreadAngle", value);
		}
		public get()
		{
			return this.GetObject().GetPropFloat(Prop_Data, "m_flSpreadAngle");
		}
	}

	public void Fire()
	{
		if (this.Valid())
			this.GetObject().Input("FireOnce");
	}

	// Fires several projectiles from this launcher
	public void FireMultiple(int count)
	{
		if (this.Valid())
		{
			SetVariantInt(count);
			this.GetObject().Input("FireMultiple");
		}
	}

	// Detonates all stickies owned by this launcher
	public void DetonateStickies()
	{
		if (this.Valid())
			this.GetObject().Input("DetonateStickies");
	}
}

/** Does not work - can't seem to get projectiles fire by a mimic
 * Checks if a projectile was launched by a projectile launcher
 * 
 * @param entity     Projectile to test
 * @param launcher	 Buffer to store launcher if found
 * @return           True if the projectile was launched by a projectile launcher. False if no launcher or invalid entity type
 
stock bool ProjectileLaunched(FObject entity, FProjectileLauncher& launcher)
{
	if (entity.Cast("tf_projectile_"))
	{
		FObject launcherEnt;
		launcherEnt = entity.GetPropEnt(Prop_Send, "m_hOwnerEntity");

		char classname[64];
		launcherEnt.GetClassname(classname, sizeof classname);
		PrintToChatAll("[CHECK LAUNCHER] Launcher Index = %d | %s\n------------", launcher.Get(), classname);

		launcher = FProjectileLauncher(launcherEnt, true);

		return launcher.Valid();
	}

	return false;
}
*/

/** Does not work - can't seem to get projectiles fire by a mimic
 * Sets team and owner properties on projectiles launched by a tf_point_weapon_mimic
 * 
 * @param projectile     Spawned projectile
 *
stock void SetProjectileProperties(FObject projectile, FProjectileLauncher launcher)
{
	// Check if we have an owner
	FClient owner;
	owner = CastToClient(launcher.GetObject().GetOwner());

	if (owner.Valid())
	{
		projectile.SetOwner(owner.GetObject());
		projectile.SetProp(Prop_Send, "m_iTeamNum", owner.GetTeam());
	}
}
*/
