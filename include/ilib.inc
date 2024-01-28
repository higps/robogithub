#include <sdktools>
#include "ilib/vector.inc"
#include "ilib/trace_wrapper.inc"
#include "ilib/colors.inc"
#include "ilib/timer.inc"
#include "ilib/tempent.inc"
#include "ilib/entity.inc"
#include "ilib/client.inc"

#if defined _ilib_included
 #endinput
#endif
#define _ilib_included

methodmap FMath
{
	// Clamps an integer value between min and max
	public static int ClampInt(int value, int min, int max)
	{
		return (value < min) ? min : (value < max) ? value : max;
	}
	
	// Clamps a float value between min and max
	public static float ClampFloat(float value, float min, float max)
	{
		return (value < min) ? min : (value < max) ? value : max;
	}
	
	// From UE5 FMath::RInterpConstantTo
	/*
	* Interpolates from a starting angle to the given target angle in a smooth transition
	*
	* @param current		Starting angle
	* @param target			Angle to interpolate to
	* @param delta			Length of distance between starting and target angles (from 0.0 to 1.0)
	* @param speed			How fast the interpolation should be (value of 0.0 = no interpolation).
	*
	* @return 				Angle between the current and target rotators based on the delta given		
	*/
	public static FRotator InterpRotatorTo(FRotator current, FRotator target, float delta, float speed)
	{
		// if DeltaTime is 0, do not perform any interpolation (Location was already calculated for that frame)
		if (delta == 0.0 || current.IsEqual(target))
			return current;

		// If no interp speed, jump to target value
		if (speed <= 0.0)
		{
			return target;
		}

		float deltaSpeed = speed * delta;
		
		FRotator deltaRotation;
		deltaRotation = SubtractRotators(target, current).GetNormalized()

		FRotator result;
		result = current;

		result.Pitch += FMath.ClampFloat(deltaRotation.Pitch, -deltaSpeed, deltaSpeed);
		result.Yaw += FMath.ClampFloat(deltaRotation.Yaw, -deltaSpeed, deltaSpeed);
		result.Roll += FMath.ClampFloat(deltaRotation.Roll, -deltaSpeed, deltaSpeed);
		return result.GetNormalized();
	}
	
	/*
	* Gets the rotation between two locations in world space
	*
	* @param origin Origin position
	* @param destination Destination position
	*
	* @return FRotator containing the world angles from the origin to the destination
	*/
	public static FRotator CalcRotator(FVector origin, FVector destination)
	{
		FRotator angles;
		FVector buffer;
		Vector_Subtract(destination, origin, buffer);

		Vector_GetAngles(buffer, angles);

		return angles;
	}
	
	/*
	* Interpolates between two values making a smooth transition
	*
	* @param current 	Starting value
	* @param target 	Target value
	* @param time 		Time interval for interpolation speed
	*
	* @return 			Interpolated value between the current and target
	*/
	public static float InterpFloatTo(float current, float target, float time)
	{
		return (1.0 - time) * current + time * target;
	}

	/*
	* Gets an angle in degrees between two rotators
	* 
	* @param origin 	Origin angle
	*
	* @param target 	Target angle
	*
	* @return 			Float value of angle in degrees 
	*/
	public static float GetAngle(FRotator origin, FRotator target)
	{
		FVector aim, ang;

		aim = origin.GetForwardVector();
		ang = target.GetForwardVector();

		return RadToDeg(ArcCosine(Vector_DotProduct(aim, ang) / aim.Length(true)));
	}

	/*
	* Offsets the input vector by the given offset vector based on the given angle
	*
	* @param input		Original vector
	*
	* @param angle		Relative angle to use for offset
	*
	* @param offset		Vector to use as an offset
	*
	* @return			FVector offset from the given input vector relative to the given angle
	*/

	public static FVector OffsetVector(FVector input, FRotator angle, FVector offset)
	{
		FVector result;
		result = input;

		FVector interimVec;
		interimVec = angle.GetForwardVector();
		interimVec.Scale(offset.X);
		Vector_Add(interimVec, result, result);

		interimVec = angle.GetRightVector();
		interimVec.Negate();
		interimVec.Scale(offset.Y);
		Vector_Add(interimVec, result, result);

		interimVec = angle.GetUpVector();
		interimVec.Scale(offset.Z);
		Vector_Add(interimVec, result, result);

		return result;
	}
	
	public static FVector MirrorVector(FVector input, FVector normal)
	{
		FVector result;
		float dot = Vector_DotProduct(normal, input);
			
		normal.Scale(dot * 2.0);

		Vector_Subtract(input, normal, result);

		return result;
	}
}

methodmap FGameplayStatics
{
	/*
	* Creates a pseudo timer wrapped around a StringMap. Must be closed when finished using.
	*
	* @param duration 	Duration for this timer
	* @param paused		Should this timer start paused
	* @param loop 		Should this timer loop
	* @param singleUse	Should this timer clear after it first expires. Ignored if loop is true. Does not delete the handle and can still be re-used.
	* @param initialDelay	(default: 0.0) Initial delay passed to the timer
	*
	* @return - STimer containing this timer's information
	*/
	public static STimer CreatePersistentTimer(float duration, bool paused = true, bool loop = false, bool singleUse = false, float initialDelay = 0.0)
	{
		STimer timer = new STimer(duration, paused, loop, singleUse, initialDelay);
		return timer;
	}

	// Emits the given sound to all players locally
	public static void EmitSoundToPlayers(const char[] sample)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				EmitSoundToClient(i, sample);
		}
	}

	/*
	* Creates a tf_hud_text object and prepares a timer to display it for the given duration
	*
	* @param client		Client reference to display this message to
	* @param message 	Message to display
	* @param duration 	Duration to hold the message for
	* @param icon 		Icon to use for the message
	*/
	public static void DisplayTFMessage(FClient client, const char[] message, float duration, const char[] icon = "leaderboard_streak")
	{
		if (client.Valid())
		{
			float endTime = GetGameTime() + duration;

			DataPack data = CreateDataPack();
			data.WriteCell(client.Get());
			data.WriteString(message);
			data.WriteFloat(endTime);
			data.WriteString(icon);

			data.Reset();

			CreateTimer(0.1, DisplayTFMessageTimer, data, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	/*
	* Displays a tf_hud_text to the given client
	*
	* If the message needs to persist for a specific time, use DisplayTFMessage instead.
	*
	* @param client 	Client reference to display this text to
	* @param message 	Message to display
	* @param icon 		Icon used with this message
	*
	*/
	public static void WriteGameText(FClient client, const char[] message, const char[] icon = "leaderboard_streak")
	{
		if (client.Valid())
		{
			Handle GlobalText = StartMessageOne("HudNotifyCustom", client.Get());

			SetGlobalTransTarget(client.Get());
			BfWriteString(GlobalText, message);
			BfWriteString(GlobalText, icon);
			BfWriteByte(GlobalText, client.GetTeam());
			EndMessage();
		}
	}

	/*
	* Creates and spawns an object with the given classname. Use CreateObjectDeferred() if you need to set any properties before spawning.
	*
	* @param classname		Classname of the entity to spawn
	*/
	public static FObject CreateObject(const char[] classname)
	{
		FObject entity;

		entity.Create(classname);

		entity.Spawn();
		entity.Activate();

		return entity;
	}

	/*
	* Creates an object with the given classname, but does not spawn it. Call FGameplayStatics.FinishSpawn() when this object is ready to be spawned.
	*
	* @param classname		Classname of the entity to create
	*/
	public static FObject CreateObjectDeferred(const char[] classname)
	{
		FObject entity;

		entity.Create(classname);

		return entity;
	}

	/*
	* Finishes spawning this entity and activates it.
	*
	* @param entity		Object reference to spawn
	* @param spawn		Transform to spawn this object with
	*/
	public static void FinishSpawn(FObject entity, FTransform spawn)
	{
		entity.Spawn();
		entity.Activate();
		
		entity.Teleport(spawn.Position, spawn.Rotation, spawn.Velocity);
	}

	public static float GetDistanceBetweenObjects(FObject target, FObject destination)
	{
		return target.GetPosition().DistanceTo(destination.GetPosition());
	}
}


/*
* Creates an FClient struct from a given object reference
*
* @param entity		Entity object to check
*
* @return			FClient info containing the entity reference
*/

stock FClient CastToClient(FObject entity)
{
	FClient client;
	client.Obj = entity;

	return client;
}

// Timer function used with DiplayTFMessage
Action DisplayTFMessageTimer(Handle timer, DataPack data)
{
	data.Reset();

	FClient client;
	client.Set(data.ReadCell());

	if (client.Valid())
	{
		char message[256], icon[128];
		bool end;

		data.ReadString(message, sizeof message);

		float time = data.ReadFloat();
		end = time <= GetGameTime();

		//PrintToChat(client.Get(), "Timer on text: %.1f", time - GetGameTime());

		if (end)
		{
			delete data;
			return Plugin_Stop;
		}

		data.ReadString(icon, sizeof icon);

		FGameplayStatics.WriteGameText(client, message, icon);

		return Plugin_Continue;
	}

	delete data;
	return Plugin_Stop;
}
