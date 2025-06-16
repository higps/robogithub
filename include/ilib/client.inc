#include <tf2_stocks>
#include "ilib/entity.inc"
#include "ilib/vector.inc"
#include "ilib/colors.inc"

#if defined _ilib_client_included
 #endinput
#endif
#define _ilib_client_included

/*
* Struct used to store information about a client
* Can be used to perform most actions normally used on client indexes
*/
enum struct FClient
{
	// Reference used for this client
	FObject Obj;

	/*
	* Sets the reference of this client as the given client index
	*
	* @param client Client index to set as this reference
	*/
	void Set(int client)
	{
		if (client > 0 && client <= MaxClients && IsClientInGame(client))
			this.Obj.Set(client);
	}

	// Gets this client's referenced index
	int Get()
	{
		return this.Obj.Get();
	}
	
	// Gets the EntRef of this client
	int GetReference()
	{
		return this.Obj.GetReference();
	}
	
	/*
	* Sets EntRef of this client
	*
	* @param clientRef EntRef of the client
	*/
	void SetReference(int clientRef)
	{
		this.Obj.Reference = clientRef;
	}

	// Increments the referenced index by one
	void Next()
	{
		this.Obj.Next();
	}

	// Resets this reference
	void Clear()
	{
		this.Obj.Reference = -1;
	}

	// Returns this client's FObject reference
	FObject GetObject()
	{
		return this.Obj;
	}

	// Returns true if this client is valid and in game
	bool Valid()
	{
		int client = this.Obj.Get();
		if (client > 0 && client <= MaxClients)
			return IsClientInGame(client);

		return false;
	}

	// Returns whether or not this client is alive
	bool Alive()
	{
		if (this.Valid())
			return IsPlayerAlive(this.Get());

		return false;
	}

	// Respawns the given client
	void Respawn()
	{
		TF2_RespawnPlayer(this.Get());
	}

	/*
	* Teleports the referenced client
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

		TeleportEntity(this.GetReference(), position, angles, velocity);
	}

	void SetPosition(FVector position)
	{
		TeleportEntity(this.GetReference(), position.ToFloat(), NULL_VECTOR, NULL_VECTOR);
	}
	void SetAngles(FRotator angles)
	{
		TeleportEntity(this.GetReference(), NULL_VECTOR, angles.ToFloat(), NULL_VECTOR);
	}
	
	/*
	* Sets the rotation and velocity of this client
	*
	* @param rot 	Rotation to set
	* @param vel 	Velocity to set
	*/
	void SetVelocityRotation(FRotator rot, FVector vel)
	{
		if (this.Valid())
		{
			TeleportEntity(this.GetReference(), NULL_VECTOR, rot.ToFloat(), vel.ToFloat());
		}
	}

	// Retrieves this client's team as an integer
	int GetTeam()
	{
		if (this.Valid())
			return GetClientTeam(this.Get());

		return -1;
	}

	// Retrieves this client's current health value as an integer
	int GetHealth()
	{
		if (this.Alive())
			return GetClientHealth(this.Get())

		return 0;
	}

	// Retrieves this client's maximum health value as an integer
	int GetMaxHealth()
	{
		if (this.Alive())
			return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, this.Get())

		return 0;
	}

	/*
	* Adds health to this client
	*
	* @param amount amount of health to add
	* @param overheal As a multiplier, how much this healing can overheal the player by
	*/
	void AddHealth(int amount, float overheal = 1.0)
	{
		if (this.Valid())
		{
			int health = GetClientHealth(this.Get());

			int max = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, this.Get());
			if (health > max * overheal)
				return;

			health += amount;
			if (health > max * overheal)
				health = RoundFloat(max * overheal);

			SetEntityHealth(this.GetReference(), health);
		}
	}

	// Retrieves this client's class as a TFClassType
	TFClassType GetClass()
	{
		if (this.Valid())
			return TF2_GetPlayerClass(this.Get());

		return TFClass_Unknown;
	}

	/*
	* Sets a condition on this client
	*
	* @param cond TFCond condition value to set
	* @param duration Duration for the condition
	* @param inflictor Who inflicted this condition
	*/
	void AddCondition(TFCond cond, float duration, int inflictor = 0)
	{
		if (this.Valid())
			TF2_AddCondition(this.Get(), cond, duration, inflictor);
	}

	/*
	* Removes the condition given from this client
	*
	* @param cond TFCond condition to remove
	*/
	void RemoveCondition(TFCond cond)
	{
		if (this.Valid())
			TF2_RemoveCondition(this.Get(), cond);
	}

	/*
	* Checks whether this client is in the given condition
	*
	* @param cond Condition to check for
	*
	* @return - True if the client is in the condition
	*/
	bool InCondition(TFCond cond)
	{
		if (this.Valid())
			return TF2_IsPlayerInCondition(this.Get(), cond);

		return false;
	}

	// Wrapper for EmitSoundToClient()
	void EmitSound(const char[] sound, int entity = 0, int channel = SNDCHAN_AUTO, int level = 200, int flags = 0, float vol = 1.0, int pitch = 100)
	{
		if (this.Valid())
			EmitSoundToClient(this.Get(), sound, entity, channel, level, flags, vol, pitch);
	}

	/*
	* Prints a center message to this client
	*
	* @param message Text to display to this client
	*/
	void PrintCenterText(const char[] message)
	{
		if (this.Valid())
			PrintCenterText(this.Get(), message);
	}

	// Gets the max speed of this client
	float GetMaxSpeed()
	{
		if (this.Valid())
			return GetEntPropFloat(this.GetReference(), Prop_Data, "m_flMaxspeed");

		else return 0.0;
	}

	/*
	* Gets the absolute origin of this client
	*
	* @return FVector containing this client's position
	*/
	FVector GetPosition()
	{
		FVector position;
		if (this.Valid())
			Vector_GetClientPosition(this.Get(), position);
		
		return position;
	}

	/*
	* Gets the eye position of this client
	*
	* @return FVector containing this client's eye position
	*/
	FVector GetEyePosition()
	{
		FVector position;
		if (this.Valid())
			Vector_GetClientEyePosition(this.Get(), position);

		return position;
	}

	/*
	* Gets the eye angles of this client
	*
	* @return FRotator containign this client's eye angles
	*/
	FRotator GetEyeAngles()
	{
		FRotator rot;
		if (this.Valid())
			Rotator_GetClientEyeAngles(this.Get(), rot);

		return rot;
	}

	/*
	* Gets the absolute angles of this client
	*
	* @return - FRotator containing this client's absolute angles
	*/
	FRotator GetAngles()
	{
		FRotator rot;
		if (this.Valid())
			Rotator_GetClientAbsAngles(this.Get(), rot);

		return rot;
	}

	/*
	* Gets the velocity of this client
	*
	* @return - FVector containing this client's velocity
	*/
	FVector GetVelocity()
	{
		FVector vel;
		if (this.Valid())
			Vector_GetProperty(this.Get(), Prop_Data, "m_vecVelocity", vel);

		return vel;
	}

	/*
	* Ignites this client with a duration and attacker
	*
	* @param attacker Object reference pointing to the attacker
	* @param duration Duration of burn
	*/
	void Ignite(FObject attacker, float duration)
	{
		if (this.Valid())
			TF2_IgnitePlayer(this.Get(), attacker.Get(), duration);
	}

	/*
	* Executes a client command on this client
	*
	* @param command Command to execute
	*/
	void ExecuteCommand(const char[] command)
	{
		if (this.Valid())
			ClientCommand(this.Get(), command);
	}

	/*
	* Returns the entity index of the weapon using the given slot
	*
	* @param slot Slot to check for
	*
	* @return - Entity index of the weapon equipped in this slot
	*/
	int GetSlot(int slot)
	{
		if (this.Valid())
			return GetPlayerWeaponSlot(this.Get(), slot);

		return -1;
	}
}

/*
* Constructs an FClient with the given client as its reference
*
* @param index Client index to use as a reference
* @param userid Is the given index a userid
*
* @return - FClient containing a reference to the given index
*/
stock FClient ConstructClient(int index, bool userid = false)
{
	FClient client;
	
	if (userid)
	{
		int clientId = GetClientOfUserId(index);
		client.Set(clientId);
	}
	else
		client.Set(index);

	return client;
}


// Returns a reference to the world, or client 0
stock FClient GetWorld()
{
	FClient world;
	world.Obj.Reference = 0;

	return world;
}

// Returns true if this referenced client is the world (client index of 0)
stock bool IsWorld(FClient client)
{
	return client.Get() == 0;
}