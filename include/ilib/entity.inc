#include <sdktools>
#include "ilib/vector.inc"
#include "ilib/colors.inc"

#if defined _ilib_entity_included
 #endinput
#endif
#define _ilib_entity_included

/*
* Entity class type
*/
enum EClassType
{
	ClassType_Name,			// Entity's internal classname		i.e - tf_projectile_rocket
	ClassType_Networked		// Entity's networkable classname	i.e - CTFProjectile_Rocket
};

/*
* Struct for storing entity references.
* Can be used to perform most actions you would normally perform on entities.
*/
enum struct FObject
{
	int Reference;

	// Sets the given entity index as the reference for this object
	void Set(int ent)
	{
		if (ent >= 0)
			this.Reference = EntIndexToEntRef(ent);
	}

	// Converts the reference this object points to into its entity index.
	int Get()
	{
		return EntRefToEntIndex(this.Reference);
	}

	// Returns the entity reference of this object
	int GetReference()
	{
		return this.Reference;
	}

	void SetReference(int entityRef)
	{
		this.Reference = entityRef;
	}

	// Returns true if the reference this object points to is still valid
	bool Valid()
	{
		int ent = this.Get();
		return (ent > 0 && IsValidEntity(ent));
	}

	// Returns the parent this entity is attached to
	FObject GetParent()
	{
		FObject parent;
		parent.Set(GetEntPropEnt(this.Reference, Prop_Send, "m_hMoveParent"));
		
		return parent;
	}

	// Increments the referenced index by one
	void Next()
	{
		int current = this.Get();
		current++;
		
		this.Set(current);
	}

	/*
	* Returns true if the entity is of the given classname.
	* This is NOT a true cast as entities are always just integers.
	* 
	* Used as a substitute for getting the classname and then comparing the name to the desired name
	*
	* @param class classname to check for
	*/
	bool Cast(const char[] class)
	{
		char classname[256];
		this.GetClassname(classname, sizeof classname);

		return (StrContains(classname, class) != -1);
	}

	/*
	* Sets the render color of the entity this object points to
	*
	* @param color color struct to apply to this entity
	*/
	void SetColor(FLinearColor color)
	{
		SetEntityRenderColor(this.Reference, color.R, color.G, color.B, color.A);
	}

	// Gets the current render color of this entity
	FLinearColor GetColor()
	{
		FLinearColor color;

		GetEntityRenderColor(this.Reference, color.R, color.G, color.B, color.A);

		return color;
	}

	/*
	* Wrapper for CreateEntityByName()
	*
	* @param classname Entity type to create
	*
	* If successful, will automatically set the created entity as this object's reference
	*/
	void Create(const char[] classname)
	{
		int entity = CreateEntityByName(classname);

		this.Set(entity);
	}

	/*
	* Wrapper for GetEntityClassname()
	*
	* @param classname buffer to store the name into
	* @param size size of the buffer
	*/
	void GetClassname(char[] classname, int size)
	{
		GetEntityClassname(this.Reference, classname, size);
	}

	/*
	* Wrapper for GetEntityNetClass()
	*
	* @param netname		Buffer to store the class in
	* @param size			Size of the buffer
	*/
	void GetNetClass(char[] netname, int size)
	{
		GetEntityNetClass(this.Reference, netname, size);
	}
	
	/*
	* Gets this object's targetname and stores it in the buffer
	*
	* @param targetname buffer to store the name into
	* @param size size of the buffer
	*/
	void GetTargetName(char[] targetname, int size)
	{
		GetEntPropString(this.Reference, Prop_Data, "m_iName", targetname, size);
	}

	void SetTargetName(char[] targetname)
	{
		SetEntPropString(this.Reference, Prop_Data, "m_iName", targetname);
	}

	/*
	* Wrapper for AcceptEntityInput()
	*/
	void Input(const char[] input, int activator = -1, int caller = -1, int id = 0)
	{
		AcceptEntityInput(this.Reference, input, activator, caller, id);
	}

	// Wrapper for HookSingleEntityOutput()
	void HookOutput(const char[] output, EntityOutput callback, bool once = false)
	{
		HookSingleEntityOutput(this.Reference, output, callback, once);
	}

	// Wrapper for UnhookSingleEntityOutput()
	void UnhookOutput(const char[] output, EntityOutput callback)
	{
		UnhookSingleEntityOutput(this.Reference, output, callback);
	}

	/*
	* Wrapper for DispatchKeyValue()
	*
	* @param key Name of the key to set the value of
	* @param value Value to set on the key, as a string
	*/
	void SetKeyValue(const char[] key, const char[] value)
	{
		DispatchKeyValue(this.Reference, key, value);
	}

	/*
	* Wrapper for DispatchKeyValueInt()
	*
	* @param key Name of the key to set the value of
	* @param value Value to set on the key, as an integer
	*/
	void SetKeyValueInt(const char[] key, int value)
	{
		DispatchKeyValueInt(this.Reference, key, value);
	}

	/*
	* Wrapper for DispatchKeyValueFloat()
	*
	* @param key Name of the key to set the value of
	* @param value Value to set on the key, as a float
	*/
	void SetKeyValueFloat(const char[] key, float value)
	{
		DispatchKeyValueFloat(this.Reference, key, value);
	}

	/*
	* Wrapper for DispatchKeyValueInt()
	*
	* @param key Name of the key to set the value of
	* @param value Value to set on the key, as an FVector
	*/
	void SetKeyValueVector(const char[] key, FVector value)
	{
		DispatchKeyValueVector(this.Reference, key, value.ToFloat());
	}

	/*
	* Wrapper for SetEntityModel()
	*
	* @param model path of the model to set on this entity
	*/
	void SetModel(const char[] model)
	{
		SetEntityModel(this.Get(), model);
	}

	/*
	* Spawns the entity this object is referencing
	*/
	void Spawn()
	{
		DispatchSpawn(this.Get());
	}

	// Activates the entity this object is referencing
	void Activate()
	{
		ActivateEntity(this.Get());
	}

	// Marks this object to be removed
	void Kill()
	{
		RemoveEntity(this.Reference);
	}

	// Marks this object to be removed on a delay
	void KillOnDelay(float duration)
	{
		char output[64];
		FormatEx(output, sizeof output, "OnUser1 !self:kill::%.1f:1", duration);
		SetVariantString(output);
		this.Input("AddOutput");
		this.Input("FireUser1");
	}

	/*
	* Teleports this object's referenced entity
	*
	* @param pos Location to teleport to
	* @param rot Rotation to set
	* @param vel Velocity to set
	*/
	void Teleport(FVector pos, FRotator rot, FVector vel)
	{
		float position[3], angles[3], velocity[3];

		position = Vector_MakeFloat(pos);
		angles = Rotator_MakeFloat(rot);
		velocity = Vector_MakeFloat(vel);

		TeleportEntity(this.Reference, position, angles, velocity);
	}

	void SetPosition(FVector position)
	{
		TeleportEntity(this.Reference, position.ToFloat(), NULL_VECTOR, NULL_VECTOR);
	}

	void SetAngles(FRotator angles)
	{
		TeleportEntity(this.Reference, NULL_VECTOR, angles.ToFloat(), NULL_VECTOR);
	}

	/*
	* Sets the rotation and velocity of the entity referenced by this object
	*
	* @param rot 	Rotation to set
	* @param vel 	Velocity to set
	*/
	void SetVelocityRotation(FRotator rot, FVector vel)
	{
		TeleportEntity(this.Reference, NULL_VECTOR, rot.ToFloat(), vel.ToFloat());
	}

	/*
	* Wrapper for SetEntPropVector()
	*
	* @param type 		PropType of the given property
	* @param property 	Name of the property to set
	* @param vector 	FVector value to set on this property
	* @param element 	Element in the array to set, if applicable
	*/
	void SetPropVector(PropType type, const char[] property, FVector vector, int element = 0)
	{
		Vector_SetProperty(this.Get(), type, property, vector, element);
	}

	/*
	* Wrapper for SetEntPropVector() used for setting rotations
	*
	* @param type 		PropType of the given property
	* @param property 	Name of the property to set
	* @param rotator 	FRotator value to set on this property
	* @param element 	Element in the array to set, if applicable
	*/
	void SetPropRotator(PropType type, const char[] property, FRotator rotator, int element = 0)
	{
		Rotator_SetProperty(this.Get(), type, property, rotator, element);
	}

	void SetPropString(PropType type, const char[] property, const char[] value, int element = 0)
	{
		SetEntPropString(this.Reference, type, property, value, element);
	}

	/*
	* Wrapper for SetEntProp()
	*
	* @param type		PropType of the given property
	* @param property	Name of the property to set
	* @param value		Value to set on this property
	* @param element	Element in the array to set, if applicable
	*/
	void SetProp(PropType type, const char[] property, any value, int element = 0)
	{
		SetEntProp(this.Reference, type, property, value, _, element);
	}

	/*
	* Wrapper for SetEntPropEnt()
	*
	* @param type 		PropType of the given property
	* @param property 	Name of the property to set
	* @param reference 	FObject to set for this property
	* @param element 	Element in the array to set, if applicable
	*/
	void SetPropEnt(PropType type, const char[] property, FObject reference, int element = 0)
	{
		SetEntPropEnt(this.Reference, type, property, reference.Get(), element);
	}

	/*
	* Wrapper for SetEntPropFloat()
	*
	* @param type 		PropType of the given property
	* @param property	Name of the property to set
	* @param value 		float value to set on this property
	* @param element	Element in the array to set, if applicable
	*/
	void SetPropFloat(PropType type, const char[] property, float value, int element = 0)
	{
		SetEntPropFloat(this.Reference, type, property, value, element);
	}

	/*
	* Wrapper for GetEntProp()
	*
	* @param type		PropType of the given property
	* @param property	Name of the property to get
	* @param element	Element in the array to set, if applicable
	*
	* @return - Integer value of the property, 0 if not an integer value
	*/
	int GetProp(PropType type, const char[] property, int element = 0)
	{
		return GetEntProp(this.Reference, type, property, _, element);
	}

	/*
	* Wrapper for GetEntPropEnt()
	*
	* @param type		PropType of the given property
	* @param property	Name of the property to get
	* @param element	Element in the array to set, if applicable 
	*
	*/
	FObject GetPropEnt(PropType type, const char[] property, int element = 0)
	{
		FObject reference;
		reference.Set(GetEntPropEnt(this.Reference, type, property, element));

		return reference;
	}

	/*
	* Wrapper for GetEntPropFloat()
	*
	* @param type		PropType of the given property
	* @param property	Name of the property to get
	* @param element	Element in the array to set, if applicable
	*
	* @return - float value of the property
	*/
	float GetPropFloat(PropType type, const char[] property, int element = 0)
	{
		return GetEntPropFloat(this.Reference, type, property, element);
	}

	/*
	* Wrapper for GetEntPropVector()
	*
	* @param type		PropType of the given property
	* @param property	Name of the property to get
	* @param vector		FVector to use as a buffer for the value
	* @param element	Element in the array to set, if applicable 
	*
	*/
	void GetPropVector(PropType type, const char[] property, FVector vector, int element = 0)
	{
		Vector_GetProperty(this.Get(), type, property, vector, element);
	}

	/*
	* Wrapper for GetEntPropVector(). Used for getting rotation values
	*
	* @param type		PropType of the given property
	* @param property	Name of the property to get
	* @param rotator	FRotator to use as a buffer for the value
	* @param element	Element in the array to set, if applicable 
	*
	*/
	void GetPropRotator(PropType type, const char[] property, FRotator rotator, int element = 0)
	{
		Rotator_GetProperty(this.Get(), type, property, rotator, element);
	}

	/*
	* Wrapper for GetEntPropString()
	*
	* @param type		PropType of the given property
	* @param property	Name of the property to get
	* @param buffer		Buffer to store the string in
	* @param size		Size of the buffer
	* @param element	Element in the array to set, if applicable 
	*
	*/
	void GetPropString(PropType type, const char[] property, char[] buffer, int size, int element = 0)
	{
		GetEntPropString(this.Reference, type, property, buffer, size, element);
	}

	/*
	* Wrapper for HasEntProp()
	*
	* @param type		PropType of the given property
	* @param property	Name of the property to get
	*
	* @return - True if the property is found; false if the entity is invalid or the property does not exist
	*/
	bool HasProp(PropType type, const char[] property)
	{
		return HasEntProp(this.Reference, type, property);
	}

	/*
	* Gets the world position of this object
	*
	* @return		FVector containing the position
	*/
	FVector GetPosition()
	{
		FVector pos;
		this.GetPropVector(Prop_Data, "m_vecAbsOrigin", pos);

		return pos;
	}
	
	/*
	* Gets the relative position of this object. If no valid parent, returns the world position.
	*
	* @return		FVector containing the position
	*/
	FVector GetRelativePosition()
	{
		FVector pos;
		this.GetPropVector(Prop_Data, "m_vecOrigin", pos);

		return pos;
	}

	/*
	* Stores the angles of this object in an FRotator
	*
	* @return - FRotator containing this object's angles
	*/
	FRotator GetAngles()
	{
		FRotator rot;
		this.GetPropRotator(Prop_Send, "m_angRotation", rot);

		return rot;
	}

	/*
	* Gets the owner of this object
	*
	* @return - The object reference of the owner or itself if no owner is found
	*/
	FObject GetOwner()
	{
		FObject owner;
		if (this.HasProp(Prop_Send, "m_hOwnerEntity")) // Not ideal to check all of these at once but it's safer
			owner = this.GetPropEnt(Prop_Send, "m_hOwnerEntity");

		// Some projectiles use m_hThrower instead of m_hOwnerEntity
		if (!owner.Valid() && this.HasProp(Prop_Send, "m_hThrower"))
			owner = this.GetPropEnt(Prop_Send, "m_hThrower");
			
		// Buildings!
		if (!owner.Valid() && this.HasProp(Prop_Send, "m_hBuilder"))
			owner = this.GetPropEnt(Prop_Send, "m_hBuilder");

		// If no owner is found, return itself
		if (!owner.Valid())
			owner = this;
		
		return owner;
	}

	/*
	* Sets the owner of this object
	*
	* @param owner 	Object reference of the owner to set
	*/
	void SetOwner(FObject owner)
	{
		if (this.HasProp(Prop_Send, "m_hOwnerEntity"))
			this.SetPropEnt(Prop_Send, "m_hOwnerEntity", owner);

		if (this.HasProp(Prop_Send, "m_hThrower"))
			this.SetPropEnt(Prop_Send, "m_hThrower", owner);

		if (this.HasProp(Prop_Send, "m_hBuilder"))
			this.SetPropEnt(Prop_Send, "m_hBuilder", owner);
	}

	/*
	* Attaches this object to the given entity
	*
	* @param parent 	Parent object to attach to
	*/
	void SetParent(FObject parent)
	{
		if (!parent.Valid())
			LogError("FObject::SetParent recieved an invalid object reference for the parent attachment!");

		SetVariantString("!activator");
		AcceptEntityInput(this.Get(), "SetParent", parent.Get(), this.Get());
	}

	// Returns the current health value of this entity
	int GetHealth()
	{
		return GetEntProp(this.Get(), Prop_Data, "m_iHealth");
	}
	
	/*
	* Gets the velocity of this entity
	*
	* @return - FVector containing this client's velocity
	*/
	FVector GetVelocity()
	{
		FVector vel;
		Vector_GetProperty(this.Get(), Prop_Data, "m_vecVelocity", vel);

		return vel;
	}

	/*
	* Creates and attaches a particle to this object
	*
	* @param name 		Name of the particle to spawn
	* @param offset 	Optional offset to apply to the particle
	*
	* @return - Entity index of the particle on success
	*/
	FObject AttachParticle(const char[] name, FVector offset)
	{
		FObject particle;
		particle.Create("info_particle_system");

		FVector pos;
		pos = this.GetPosition();

		pos.Add(offset);

		particle.Teleport(pos, ConstructRotator(), ConstructVector());
		particle.SetKeyValue("effect_name", name);

		particle.Spawn();
		particle.Activate();
		particle.Input("Start");

		SetVariantString("!activator");
		particle.SetParent(this);
		
		return particle;
	}

	/*
	* Finds the first instance of the given entity classname and sets it as this object's reference
	*
	* @param classname		Entity classname to search for
	*
	* @return - True if the entity was found, false if not
	*/
	bool FindEntity(const char[] classname)
	{
		int entity;
		bool result;
		while ((entity = FindEntityByClassname(MaxClients + 1, classname)) != -1)
		{
			this.Set(entity);
			result = true;
			break;
		}
		return result;
	}
}

/*
* Constructs an FObject with the given entity index as its reference
*
* @param1 index - Entity index to use as a reference
*/
stock FObject ConstructObject(int index)
{
	FObject entity;
	entity.Set(index);

	return entity;
}
