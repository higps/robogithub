#include "ilib/entity.inc"

#if defined _ilib_shared_included
 #endinput
#endif
#define _ilib_shared_included


methodmap AObject
{
	public AObject(int entity)
	{
        return view_as<AObject>(ConstructObject(entity).ref);
    }

	// Returns the object reference
	public FObject GetObject()
	{
		FObject entity;
		entity.ref = view_as<int>(this);

		return entity;
	}

	// Returns the entity index of this object
	public int Get()
	{
		return this.GetObject().Get();
	}

	// Checks if the object reference is valid
	public bool Valid()
	{
		return this.GetObject().Valid();
	}

	// Checks if this object is of a the given classname. NOT a true cast
    public bool Cast(char[] classname)
    {
        return this.GetObject().Cast(classname);
    }

	// Deletes this object reference
	public void Kill()
	{
		this.GetObject().Kill();
	}

	// Sets the owner of this object reference
	public void SetOwner(FObject value)
	{
		this.GetObject().SetOwner(value);
	}

	// Gets the owner of this object reference
	public FObject GetOwner()
	{
		return this.GetObject().GetOwner();
	}

	/*
	*	Gets the classname of this object
	*
	*	@param type		The type of classname to get, see EClassType
	*
	*	@return		String containing the desired classtype
	*/
	public char[] GetClassname(EClassType type = ClassType_Name)
	{
		char classname[64];
		if (this.Valid())
		{
			switch (type)
			{
				case ClassType_Name: this.GetObject().GetClassname(classname, sizeof classname);
				case ClassType_Networked: this.GetObject().GetNetClass(classname, sizeof classname);
			}
		}

		return classname;
	}
}