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
methodmap URocket < UBaseProjectile
{
	/*
	* Creates a rocket projectile
	*
	* @return 			Deferred rocket object.
	*/
	public URocket()
	{
		FObject rocket;
		rocket = FGameplayStatics.CreateObjectDeferred("tf_projectile_rocket");

		return view_as<URocket>(rocket.Reference);
	}
}

/*
* Returns an ARocket if the given object is a rocket
*
* @param entity		Entity to test
*/
stock URocket CastToRocket(UObject entity)
{
	URocket rocket;

	// Cast to a rocket
	if (entity.Cast("tf_projectile_rocket"))
		rocket = view_as<URocket>(entity.GetObject().Reference);

	return rocket;
}