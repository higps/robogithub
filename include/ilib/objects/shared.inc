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

    public bool Cast(char[] classname)
    {
        return this.GetObject().Cast(classname);
    }

	public void Kill()
	{
		this.GetObject().Kill();
	}

	public void SetOwner(FObject value)
	{
		this.GetObject().SetOwner(value);
	}
	public FObject GetOwner()
	{
		return this.GetObject().GetOwner();
	}
}