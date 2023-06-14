#include <tf2_stocks>
#include "ilib/entity.inc"
#include "ilib/vector.inc"

#if defined _ilib_particle_included
 #endinput
#endif
#define _ilib_particle_included

/*
* Optional struct for quickly creating particle systems
* 
*/

enum struct FParticleSystem
{
	FObject Reference; // Entity object reference of this particle

	char EffectName[256]; // Name of this particle system

	// Returns the object reference of this particle
	FObject GetObject()
	{
		return this.Reference;
	}

	// Returns the entity index this particle references
	int Get()
	{
		return this.GetObject().Get();
	}

	// Checks if the object reference is valid
	bool Valid()
	{
		return this.GetObject().Valid();
	}

	// Starts this particle system
	void StartSystem()
	{
		this.GetObject().Input("Start");
	}
	
	// Stops this particle system
	void StopSystem()
	{
		this.GetObject().Input("Stop");
	}
}

/*
* Creates and spawns a particle system with the given effect name
*
* @param name			Effect name to use
* @param position		World location to spawn this particle at
* @param rotation		World rotation to spawn particle with
* @param startActive	Should this particle immediately start
* @param weather		Whether or not this entity should be flagged as a weather system
*
* @return 				Particle system with the given properties
*/
stock FParticleSystem CreateParticleSystem(const char[] name, const FVector position, const FRotator rotation, bool startActive = false, bool weather = false)
{
	FObject reference;
	reference = CreateObjectDeferred("info_particle_system");
	
	FParticleSystem particle;
	FormatEx(particle.EffectName, sizeof FParticleSystem::EffectName, name);
	
	reference.SetKeyValue("effect_name", particle.EffectName);
	reference.SetKeyValue("start_active", startActive ? "1" : "0");
	reference.SetKeyValue("flag_as_weather", weather ? "1" : "0");
	
	FTransform spawn;
	spawn.position = position;
	spawn.rotation = rotation;
	
	FinishSpawn(reference, spawn);
	
	particle.Reference = reference;
	
	return particle;
}

/*
* Returns an FParticleSystem if the referenced entity is a particle
*
* @param entity		Entity to test
*/
stock FParticleSystem CastToParticle(FObject entity)
{
	FParticleSystem particle;

	// Makes sure the object is a particle system, then gets its properties 
	if (entity.Cast("info_particle_system"))
	{
		particle.Reference = entity;
		GetEntPropString(entity.Get(), Prop_Data, "m_iszEffectName", particle.EffectName, sizeof FParticleSystem::EffectName);
	}

	return particle;
}