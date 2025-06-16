#include <sdktools>

#if defined _ilib_vector_included
 #endinput
#endif
#define _ilib_vector_included

/*
* Wrapper for traditional float arrays
*/
enum struct FVector
{
	float X;
	float Y;
	float Z;

	// Converts a float array into a vector
	void Set(float vec[3])
	{
		this.X = vec[0];
		this.Y = vec[1];
		this.Z = vec[2];
	}

	// Converts this vector into a float array
	float[] ToFloat()
	{
		float vec[3];
		vec[0] = this.X;
		vec[1] = this.Y;
		vec[2] = this.Z;

		return vec;
	}

	// Gets the length of this vector
	float Length(bool squared = false)
	{
		float vector[3];
		vector = this.ToFloat();

		return GetVectorLength(vector, squared);
	}

	// Adds this vector with another vector
	void Add(FVector vec)
	{
		this.X += vec.X;
		this.Y += vec.Y;
		this.Z += vec.Z;
	}

	void Subtract(FVector vec)
	{
		this.X -= vec.X;
		this.Y -= vec.Y;
		this.Z -= vec.Z;
	}

	// Returns the distance between this vector and another given vector
	float DistanceTo(FVector vec, bool squared = false)
	{
		return GetVectorDistance(vec.ToFloat(), this.ToFloat(), squared);
	}

	// Scales this vector by the given value
	void Scale(float value)
	{
		this.X *= value;
		this.Y *= value;
		this.Z *= value;
	}

	// Normalizes this vector
	void Normalize()
	{
		float vector[3];
		vector = this.ToFloat();

		NormalizeVector(vector, vector);

		this.Set(vector);
	}

	// Negatives this vector
	void Negate()
	{
		this.X = this.X * -1.0;
		this.Y = this.Y * -1.0;
		this.Z = this.Z * -1.0;
	}
}

// Used for null vector inputs
//public FVector NULL_FVector;

/*
* Wrappers for float arrays intended to be used for angles
*
* At its core, this is identical to FVector and can be used interchangeably if converted to a float array.
* However, FRotator and FVector cannot be used interchangeably as structs, they are purely for organizational preferences
*/
enum struct FRotator
{
	float Pitch;
	float Yaw;
	float Roll;

	// Sets this rotator from a float array
	void Set(float angle[3])
	{
		this.Pitch = angle[0];
		this.Yaw = angle[1];
		this.Roll = angle[2];
	}

	// Converts this rotator into a float array
	float[] ToFloat()
	{
		float angle[3];

		angle[0] = this.Pitch;
		angle[1] = this.Yaw;
		angle[2] = this.Roll;

		return angle;
	}

	// Retrieves the forward vector of this rotator as an FVector
	FVector GetForwardVector()
	{
		FVector vector;

		float rot[3], vec[3];
		rot = this.ToFloat();

		GetAngleVectors(rot, vec, NULL_VECTOR, NULL_VECTOR);

		vector.Set(vec);

		return vector;
	}

	// Retrieves the right vector of this rotator as a FVector
	FVector GetRightVector()
	{
		FVector vector;

		float rot[3], vec[3];
		rot = this.ToFloat();

		GetAngleVectors(rot, NULL_VECTOR, vec, NULL_VECTOR);
		
		vector.Set(vec);

		return vector;
	}

	// Retrieves the up vector of this rotator as a FVector
	FVector GetUpVector()
	{
		FVector vector;

		float rot[3], vec[3];
		rot = this.ToFloat();

		GetAngleVectors(rot, NULL_VECTOR, NULL_VECTOR, vec);
		
		vector.Set(vec);

		return vector;
	}

	// Normalizes this rotation's axes and returns as a value
	FRotator GetNormalized()
	{
		while (this.Pitch > 180.0) this.Pitch -= 360.0;
		while (this.Pitch < -180.0) this.Pitch += 360.0;
		while (this.Yaw > 180.0) this.Yaw -= 360.0;
		while (this.Yaw < -180.0) this.Yaw += 360.0;
		while (this.Roll > 180.0) this.Roll -= 360.0;
		while (this.Roll < -180.0) this.Roll += 360.0;
		
		return this;
	}
	
	// Checks if this rotator is equal to another - precision makes this inaccurate
	bool IsEqual(FRotator rotation, float error = 0.001)
	{
		if (rotation.Pitch - error <= this.Pitch <= rotation.Pitch + error)
		{
			if (rotation.Yaw - error <= this.Yaw <= rotation.Yaw + error)
			{
				if (rotation.Roll - error <= this.Roll <= rotation.Roll + error)
				{
					return true;
				}
			}
		}
			
		return false;
	}
}

// Used for null rotator inputs
//public FRotator NULL_ROTATOR;

enum struct FTransform
{
	FVector Position;
	FRotator Rotation;
	FVector Velocity;
}

/*
* Constructor for FVector types.
* Can be left blank to create a zero vector.
*/
stock FVector ConstructVector(float x = 0.0, float y = 0.0, float z = 0.0)
{
	FVector vector;
	vector.X = x;
	vector.Y = y;
	vector.Z = z;

	return vector;
}

/*
* Stores an FVector object from GetEntPropVector()
*/
stock void Vector_GetProperty(int entity, PropType type, const char[] property, FVector vector, int element = 0)
{
	float result[3];
	GetEntPropVector(entity, type, property, result, element);

	Vector_MakeFromFloat(vector, result);
}

stock void Vector_SetProperty(int entity, PropType type, const char[] property, FVector vector, int element = 0)
{
	SetEntPropVector(entity, type, property, Vector_MakeFloat(vector), element);
}

// Calculates the dot product between two FVectors
stock float Vector_DotProduct(FVector vector1, FVector vector2)
{
	return GetVectorDotProduct(Vector_MakeFloat(vector1), Vector_MakeFloat(vector2));
}

// Calculates the distance between two FVector objects
stock float Vector_GetDistance(FVector vector1, FVector vector2, bool squared = false)
{
	return GetVectorDistance(Vector_MakeFloat(vector1), Vector_MakeFloat(vector2), squared);
}

// Calculates the cross product between two FVectors. Either inputs may be used as the buffer
stock FVector Vector_CrossProduct(FVector vector1, FVector vector2)
{
	float result[3];

	GetVectorCrossProduct(Vector_MakeFloat(vector1), Vector_MakeFloat(vector2), result);

	FVector buffer;
	Vector_MakeFromFloat(buffer, result);

	return buffer;
}

// Converts a float array into a FVector object
stock void Vector_MakeFromFloat(FVector vector, float vec[3])
{
	vector.X = vec[0];
	vector.Y = vec[1];
	vector.Z = vec[2];
}

// Converts back to a float array
stock float[] Vector_MakeFloat(FVector vector)
{
	return vector.ToFloat();
}


// Adds two FVectors. Either inputs may be used as the buffer
stock FVector Vector_Add(FVector vector1, FVector vector2)
{
	FVector buffer;

	buffer.X = vector1.X + vector2.X;
	buffer.Y = vector1.Y + vector2.Y;
	buffer.Z = vector1.Z + vector2.Z;

	return buffer;
}


// Subtracts FVectors vector1 - vector2. Either inputs may be used as the buffer
stock FVector Vector_Subtract(FVector vector1, FVector vector2)
{
	FVector buffer;

	buffer.X = vector1.X - vector2.X;
	buffer.Y = vector1.Y - vector2.Y;
	buffer.Z = vector1.Z - vector2.Z;

	return buffer;
}


// Creates an FVector from two points by subtracting the two points
stock FVector Vector_MakeFromPoints(FVector origin, FVector destination)
{
	FVector buffer;

	buffer.X = destination.X - origin.X;
	buffer.Y = destination.Y - origin.Y;
	buffer.Z = destination.Z - origin.Z;

	return buffer;
}


// Stores the angles of an FVector as a Rotator
stock FRotator Vector_GetAngles(FVector vector)
{
	float angles[3];

	GetVectorAngles(Vector_MakeFloat(vector), angles);

	FRotator rot;
	Rotator_MakeFromFloat(rot, angles);

	return rot;
}


// Stores the client's position as a FVector
stock void Vector_GetClientPosition(int client, FVector vector)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);

	Vector_MakeFromFloat(vector, pos);
}


// Stores the client's eye position as a FVector
stock void Vector_GetClientEyePosition(int client, FVector vector)
{
	float pos[3];
	GetClientEyePosition(client, pos);

	Vector_MakeFromFloat(vector, pos);
}

/**
 * Wrapper for kv::GetVector() compatible with FVector
 * 
 * @param kv      KeyValues tree to pull from
 * @param key     Key name to search for
 * @return        Return FVector containing vector
 */
stock FVector Vector_GetFromKV(KeyValues kv, const char[] key)
{
	FVector vector;

	float vec[3];
	kv.GetVector(key, vec);

	vector.Set(vec);

	return vector;
}

/* Constructor for FRotator types
* Can be left blank to create a zero vector
* Unlike FVector, values here will not be auto filled
*/
stock FRotator ConstructRotator(float pitch = 0.0, float yaw = 0.0, float roll = 0.0)
{
	FRotator rot;
	rot.Pitch = pitch;
	rot.Yaw = yaw;
	rot.Roll = roll;

	return rot;
}


// Stores a Rotator from GetEntPropVector()
stock void Rotator_GetProperty(int entity, PropType type, const char[] property, FRotator rot, int element = 0)
{
	float result[3];
	GetEntPropVector(entity, type, property, result, element);

	Rotator_MakeFromFloat(rot, result);
}

stock void Rotator_SetProperty(int entity, PropType type, const char[] property, FRotator rotator, int element = 0)
{
	SetEntPropVector(entity, type, property, Rotator_MakeFloat(rotator), element);
}


// Converts a float array into a Rotator object
stock void Rotator_MakeFromFloat(FRotator rot, float vec[3])
{
	rot.Pitch = vec[0];
	rot.Yaw = vec[1];
	rot.Roll = vec[2];
}

// Converts back to a float array
stock float[] Rotator_MakeFloat(FRotator rotation)
{
	float rot[3];

	rot[0] = rotation.Pitch;
	rot[1] = rotation.Yaw;
	rot[2] = rotation.Roll;

	return rot;
}

/**
 * Wrapper for kv::GetVector() compatible with FRotator
 * 
 * @param kv      KeyValues tree to pull from
 * @param key     Key name to search for
 * @return        Return FRotator containing angles
 */
stock FRotator Rotator_GetFromKV(KeyValues kv, const char[] key)
{
	FRotator rot;

	float vec[3];
	kv.GetVector(key, vec);

	rot.Set(vec);

	return rot;
}

// Stores the client's view angles as a Rotator
stock void Rotator_GetClientEyeAngles(int client, FRotator rot)
{
	float angle[3];
	GetClientEyeAngles(client, angle);

	Rotator_MakeFromFloat(rot, angle);
}

// Stores the client's absolute angles as a rotator
stock void Rotator_GetClientAbsAngles(int client, FRotator rot)
{
	float angle[3];
	GetClientAbsAngles(client, angle);

	Rotator_MakeFromFloat(rot, angle);
}

// Clamps the given angles to acceptable values
stock void NormalizeAngles(FRotator angle)
{
 	while (angle.Pitch > 89.0) angle.Pitch -= 180.0;
	while (angle.Pitch < -89.0) angle.Pitch += 180.0;
	while (angle.Yaw > 180.0) angle.Yaw -= 360.0;
	while (angle.Yaw < -180.0) angle.Yaw += 360.0;
}

/*
*	Constructor for FTransform types
*/
stock FTransform ConstructTransform(FVector pos, FRotator rot, FVector vel = {0.0, 0.0, 0.0})
{
	FTransform result;
	result.Position = pos;
	result.Rotation = rot;
	result.Velocity = vel;

	return result;
}

/*
* Interpolates between two vectors to give a smooth transition
* 
* @param origin			Starting vector
* @param destination	Destination vector
* @param time			Time interval for transition, such as GetGameTime()
* @param buffer			Buffer to store the transition
*/
stock void InterpVector(FVector origin, FVector destination, float time, FVector buffer)
{
	FVector result;

	result.X = (1.0 - time) * origin.X + time * destination.X;
	result.Y = (1.0 - time) * origin.Y + time * destination.Y;
	result.Z = (1.0 - time) * origin.Z + time * destination.Z;

	buffer = result;
}

/*
* Gets the transform of an attachment based on the attachment ID
*
* @param entity			Entity to look up attachment on
* @param id				Attachment ID to look up
* @param buffer			Buffer to store transform in
* 
* @return 				True on success
*/

stock bool Vector_GetEntityAttachment(FObject entity, int id, FTransform buffer)
{
	if (entity.Valid())
	{
		float pos[3], angle[3];

		if (GetEntityAttachment(entity.Get(), id, pos, angle))
		{
			FVector position;
			FRotator rot;

			position.Set(pos);

			rot.Set(angle);

			buffer = ConstructTransform(position, rot);
			return true;
		}
	}
	return false;
}

/*
* Subtracts two rotators
*
* @param1 rot1		First rotator
* @param2 rot2		Rotator to subtract from the first
*
* @return 			Result of operation
*/

stock FRotator SubtractRotators(FRotator rot1, FRotator rot2)
{
	float result[3];
	
	SubtractVectors(rot1.ToFloat(), rot2.ToFloat(), result);
	
	FRotator rotation;
	Rotator_MakeFromFloat(rotation, result);
	
	return rotation;
}

/*
* Gets the attachment position on an entity
*
* @param entity		Entity to get attachment from
* @param name		Name of the attachment
* @param buffer		Buffer to store the position in
*
* @return			True if the attachment was found, false if not
*/

stock bool GetAttachmentTransform(FObject entity, const char[] name, FTransform buffer)
{
	if (entity.Valid())
	{
		int id = LookupEntityAttachment(entity.Get(), name);

		if (Vector_GetEntityAttachment(entity, id, buffer))
			return true;
	}

	return false;
}
