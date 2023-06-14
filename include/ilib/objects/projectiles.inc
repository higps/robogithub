#include "ilib/objects/shared.inc"
#include "ilib/entity.inc"

#if defined _ilib_projectiles_included
 #endinput
#endif
#define _ilib_projectiles_included

/*
* Map for handling projectiles. This can be used on any projectile already existing in the world
*/
methodmap ABaseProjectile < AObject
{
	/*
	* Used as a cast to check if an object is a projectile. If needing to spawn a specific projectile, use the appropriate methodmap
	*
	* @return 			ABaseProjectile wrapping the entity reference.
	*/
	public ABaseProjectile(FObject entity)
	{
		if (entity.Cast("tf_projectile_"))
			return view_as<ABaseProjectile>(entity.ref);

		return view_as<ABaseProjectile>(0);
	}

	// Damage this projectile will deal. Note: not all projectiles handle damage in the same way, this may not work for all
	property float Damage
	{
		public set(float value)
		{
			// Most projectiles use m_flDamage
			if (this.GetObject().HasProp(Prop_Send, "m_flDamage"))
			{
				this.GetObject().SetPropFloat(Prop_Send, "m_flDamage", value);
			}
			// However, projectiles based on rockets do NOT have a named damage property so we must use an offset
			else
			{
				// This should work for most other projectiles
				int offset = FindSendPropInfo(this.GetClassname(ClassType_Networked), "m_iDeflected") + 4;
				SetEntDataFloat(this.Get(), offset, value);
			}
		}
		public get()
		{
			// Same as before
			if (this.GetObject().HasProp(Prop_Send, "m_flDamage"))
			{
				return this.GetObject().GetPropFloat(Prop_Send, "m_flDamage");
			}
			else
			{
				// This should work for most other projectiles
				int offset = FindSendPropInfo(this.GetClassname(ClassType_Networked), "m_iDeflected") + 4;
				GetEntDataFloat(this.Get(), offset);
			}
		}
	}

	property int Team
	{
		public set(int value)
		{
			if (this.Valid())
			{
				this.GetObject().SetProp(Prop_Send, "m_iTeamNum", value);
			}
		}
		public get()
		{
			if (this.Valid())
			{
				return this.GetObject().GetProp(Prop_Send, "m_iTeamNum");
			}
		}
	}

	// Used to get the projectile's speed from its velocity. Cannot be set, use ABaseProjectile::FireProjectile() to set velocity
	property float Speed
	{
		public get()
		{
			FVector vel;
			this.GetObject().GetPropVector(Prop_Data, "m_vecVelocity", vel);

			return vel.Length();
		}
	}

	// Whether or not this rocket is critical. Note: Not all projectiles can be critical
	property bool Critical
	{
		public set(bool value)
		{
			if (this.GetObject().HasProp(Prop_Send, "m_bCritical"))
				this.GetObject().SetProp(Prop_Send, "m_bCritical", view_as<int>(value));
		}
		public get()
		{
			if (this.GetObject().HasProp(Prop_Send, "m_bCritical"))
				return view_as<bool>(this.GetObject().GetProp(Prop_Send, "m_bCritical"));

			return false;
		}
	}

	/*
	* Fires this projectile in the given direction. This can be used at any time during the projectile's life
	*
	* @param direction		Direction this projectile should fire at, as an angle
	* @param speed			Speed at which this projectile will fire at
	*/
	public void FireProjectile(FRotator direction, float speed)
	{
		if (this.Valid())
		{
			FVector uDir;
			uDir = direction.GetForwardVector(); // Get the unit direction
			uDir.Scale(speed);

			this.GetObject().SetVelocityRotation(direction, uDir); // Fire the projectile
		}
	}
}
