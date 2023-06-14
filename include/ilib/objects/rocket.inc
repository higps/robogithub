#include <tf2_stocks>
#include "ilib/objects/shared.inc"
#include "ilib/objects/projectiles.inc"
#include "ilib/vector.inc"

#if defined _ilib_rocket_included
 #endinput
#endif
#define _ilib_rocket_included

/*
* Map for handling rockets
*/
methodmap ARocket < ABaseProjectile
{
	/*
	* Creates a rocket projectile
	*
	* @return 			Deferred rocket object.
	*/
	public ARocket()
	{
		FObject rocket;
		rocket = CreateObjectDeferred("tf_projectile_rocket");

		return view_as<ARocket>(rocket.ref);
	}
}

/*
* Returns an ARocket if the given object is a rocket
*
* @param entity		Entity to test
*/
stock ARocket CastToRocket(AObject entity)
{
	ARocket rocket;

	// Cast to a rocket
	if (entity.Cast("tf_projectile_rocket"))
		rocket = view_as<ARocket>(entity.GetObject().ref);

	return rocket;
}