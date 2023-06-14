#include <tf2_stocks>
#include "ilib/entity.inc"
#include "ilib/vector.inc"

#if defined _ilib_weapon_included
 #endinput
#endif
#define _ilib_weapon_included

/*
* Optional struct for quickly creating weapons
* 
*/

enum struct FWeapon
{
	FObject Reference; // Entity object reference of this weapon

	char Classname[64]; // Weapon classname

	int DefIndex; // Weapon definition index

	// Returns the object reference of this weapon
	FObject GetObject()
	{
		return this.Reference;
	}

	// Returns the entity index this weapon references
	int Get()
	{
		return this.GetObject().Get();
	}

	// Checks if the object reference is valid
	bool Valid()
	{
		return this.GetObject().Valid();
	}

	/* Sets an attribute on this weapon by index
	* @param index		Attribute index to set
	* @param value		Value to set with the attribute
	*/
	void SetAttributeIndex(int index, float value)
	{
		if (this.Valid())
		{
			TF2Attrib_SetByDefIndex(this.Get(), index, value);
		}
	}

	/* Sets an attribute on this weapon by name
	* @param name		Attribute name to set, from "name" key in items_game
	* @param value		Value to set with the attribute
	*/
	void SetAttributeName(const char[] name, float value)
	{
		if (this.Valid())
		{
			TF2Attrib_SetByName(this.Get(), name, value);
		}
	}

	/* Applies a transformation to an attribute given the initial value
	* @param initialValue		Initial value to apply transformation to
	* @param attribClass		Class of the attribute, found in "attribute_class" from items_game
	*
	* @return Transformed initial value
	*/
	float HookAttributeFloat(float initialValue, const char[] attribClass)
	{
		if (this.Valid())
		{
			return TF2Attrib_HookValueFloat(initialValue, attribClass, this.Get());
		}

		return 0.0;
	}

	/* Applies a transformation to an attribute given the initial value
	* @param initialValue		Initial value to apply transformation to
	* @param attribClass		Class of the attribute, found in "attribute_class" from items_game
	*
	* @return Transformed initial value
	*/
	int HookAttributeInt(int initialValue, const char[] attribClass)
	{
		if (this.Valid())
		{
			return TF2Attrib_HookValueInt(initialValue, attribClass, this.Get());
		}

		return 0;
	}
}

/*
* Constructs a weapon from the given entity
*
* @param entity			Entity index to construct from
*
* @return FWeapon struct containing information on this weapon
*/
stock FWeapon ConstructWeapon(int entity)
{
	FObject weaponObj;
	FWeapon weapon;

	// Set definition index to -1 since 0 is the stock bat, and structs do not allow default values
	weapon.DefIndex = -1;

	weaponObj = ConstructObject(entity);
	if (weaponObj.Valid())
	{
		// Make sure this is a weapon entity
		char classname[64];
		weaponObj.GetClassname(classname, sizeof classname);
		if (!StrContains(classname, "tf_weapon_"))
		{
			weapon.Reference = weaponObj;

			// Now get our properties
			weapon.DefIndex = weaponObj.GetProp(Prop_Send, "m_iItemDefinitionIndex");

			weaponObj.GetClassname(weapon.Classname, sizeof FWeapon::Classname);
		}
	}

	return weapon;
}

/*
* Casts to an FWeapon if the given entity is a weapon
*
* @param entity		Entity to test
*/
stock FWeapon CastToWeapon(FObject entity)
{
	FWeapon weapon;

	weapon = ConstructWeapon(entity.Get());

	return weapon;
}
