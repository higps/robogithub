#include <tf2_stocks>
#include "ilib/objects/shared.inc"
#include "ilib/vector.inc"

#if defined _ilib_rocket_included
 #endinput
#endif
#define _ilib_rocket_included

enum ERocketType
{
	Rocket_Default, // Default rocket from most rocket launchers
	Rocket_Plasma,  // Cow mangler rocket
	Rocket_Sentry   // Sentry salvo
}

/*
* Map for handling rockets
*/
methodmap ARocket < AObject
{
	/*
	* Creates a rocket projectile
	*
	* @param type		ERocketType that determines what this rocket should be
	*
	* @return 			Deferred rocket object of the given type.
	*/
	public ARocket(ERocketType type = Rocket_Default)
	{
		FObject rocket;
		char classname[64];

		switch (type)
		{
			case Rocket_Default: FormatEx(classname, sizeof classname, "tf_projectile_rocket");
			case Rocket_Plasma:	FormatEx(classname, sizeof classname, "tf_projectile_energy_ball");
			case Rocket_Sentry:	FormatEx(classname, sizeof classname, "tf_projectile_sentryrocket");
		}

		rocket = CreateObjectDeferred(classname);

		return view_as<ARocket>(rocket.ref);
	}

	// Damage this rocket will deal
	property float Damage
	{
		public set(float value)
		{
			if (this.Valid())
			{
				int offset = FindSendPropInfo(this.GetRocketType(), "m_iDeflected") + 4;
				SetEntDataFloat(this.Get(), offset, value);
			}
		}
		public get()
		{
			if (this.Valid())
			{
				int offset = FindSendPropInfo(this.GetRocketType(), "m_iDeflected") + 4;
				return GetEntDataFloat(this.Get(), offset);
			}
		}
	}

	// Used to get the rocket's speed from its velocity. Cannot be set, use ARocket::FireProjectile() to set velocity
	property float Speed
	{
		public get()
		{
			FVector vel;
			this.GetObject().GetPropVector(Prop_Data, "m_vecVelocity", vel);

			return vel.Length();
		}
	}

	// If an energy ball, whether or not it is charged
	property bool Charged
	{
		public set(bool value)
		{
			if (this.Cast("tf_projectile_energy_ball"))
				this.GetObject().SetProp(Prop_Send, "m_bChargedShot", view_as<int>(value));
		}
		public get()
		{
			if (this.Cast("tf_projectile_energy_ball"))
				return view_as<bool>(this.GetObject().GetProp(Prop_Send, "m_bChargedShot"));
			else
				return false;
		}
	}

	// Whether or not this rocket is a critical rocket
	property bool Critical
	{
		public set(bool value)
		{
			this.GetObject().SetProp(Prop_Send, "m_bCritical", view_as<int>(value));
		}
		public get()
		{
			return view_as<bool>(this.GetObject().GetProp(Prop_Send, "m_bCritical"));
		}
	}

	/*
	* Fires this projectile in the given direction. This can be used at any time during the projectile's life
	*
	* @param direction		Direction this projectile should fire at, as an angle
	* @param speed			Speed at which this rocket will fire at
	*/
	public void FireProjectile(FRotator direction, float speed)
	{
		if (this.Valid())
		{
			FVector uDir;
			uDir = direction.GetForwardVector(); // Get the unit direction
			uDir.Scale(speed);

			this.GetObject().SetVelocityRotation(direction, uDir); // Fire the rocket
		}
	}

	// Returns this rocket's networked class
	public char[] GetRocketType()
	{
		char classname[64];
		if (this.Valid())
			this.GetObject().GetNetClass(classname, sizeof classname);

		return classname;
	}
}

/*
* Returns an ARocket if the given object is a rocket
*
* @param entity		Entity to test
*/
stock ARocket CastToRocket(FObject entity)
{
	ARocket rocket;

	// Basically the same as FRocket::Valid(), we do this so we don't have to set the reference of the rocket until after we validate that it is a rocket.
	// Otherwise this entity will still be set as the rocket's reference, regardless, making this cast pointless
	if (entity.Cast("tf_projectile_rocket"))
		rocket = view_as<ARocket>(entity.ref);
	else if (entity.Cast("tf_projectile_energy_ball"))
		rocket = view_as<ARocket>(entity.ref);
	else if (entity.Cast("tf_projectile_sentryrocket"))
		rocket = view_as<ARocket>(entity.ref);

	return rocket;
}