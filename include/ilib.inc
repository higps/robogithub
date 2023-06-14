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
	client.reference = entity;

	return client;
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
stock float InterpolateFloat(float current, float target, float time)
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
stock float GetAngle(FRotator origin, FRotator target)
{
	FVector aim, ang;

	aim = origin.GetForwardVector();
	ang = target.GetForwardVector();

	return RadToDeg(ArcCosine(Vector_DotProduct(aim, ang) / aim.Length(true)));
}

stock FVector operator+(FVector vec1, FVector vec2)
{
	FVector result;
	result.x = vec1.x + vec2.x;
	result.y = vec1.y + vec2.y;
	result.z = vec1.z + vec2.z;

	return result;
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

stock FVector OffsetVector(FVector input, FRotator angle, FVector offset)
{
	FVector result;
	result = input;

	FVector interimVec;
	interimVec = angle.GetForwardVector();
	interimVec.Scale(offset.x);
	Vector_Add(interimVec, result, result);

	interimVec = angle.GetRightVector();
	interimVec.Negate();
	interimVec.Scale(offset.y);
	Vector_Add(interimVec, result, result);

	interimVec = angle.GetUpVector();
	interimVec.Scale(offset.z);
	Vector_Add(interimVec, result, result);

	return result;
}

/*
* Gets the rotation between two locations in world space
*
* @param origin Origin position
* @param destination Destination position
*
* @return FRotator containing the world angles from the origin to the destination
*/
stock FRotator CalcAngle(FVector origin, FVector destination)
{
	FRotator angles;
	FVector buffer;
	Vector_Subtract(destination, origin, buffer);

	Vector_GetAngles(buffer, angles);

	return angles;
}

// Emits the given sound to all players
stock void EmitSoundToPlayers(const char[] sample)
{
	FClient client;
	for (int i = 1; i <= MaxClients; i++)
	{
		client.Set(i);
		if (client.Valid())
			EmitSoundToClient(client.Get(), sample);
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
stock void DisplayTFMessage(FClient client, const char[] message, float duration, const char[] icon = "leaderboard_streak")
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

		WriteGameText(client, message, icon);

		return Plugin_Continue;
	}

	delete data;
	return Plugin_Stop;
}

/*
* Displays a tf_hud_text to the given client
*
* If the message needs to persist for a specific time, use DisplayTFMessage instead.
* The Handle created from this message is closed on its own
*
* @param client 	Client reference to display this text to
*
* @param message 	Message to display
*
* @param icon 		Icon used with this message
*
*/
stock void WriteGameText(FClient client, const char[] message, const char[] icon = "leaderboard_streak")
{
	Handle GlobalText = StartMessageOne("HudNotifyCustom", client.Get()); // This handle seems to be invalid after the message disappears?

	SetGlobalTransTarget(client.Get());
	BfWriteString(GlobalText, message);
	BfWriteString(GlobalText, icon);
	BfWriteByte(GlobalText, client.GetTeam());
	EndMessage();
}

// Interpolating angles - The following has been ported from UE5's FMath class

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
stock FRotator InterpRotation(FRotator current, FRotator target, float delta, float speed)
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

	result.pitch += ClampFloat(deltaRotation.pitch, -deltaSpeed, deltaSpeed);
	result.yaw += ClampFloat(deltaRotation.yaw, -deltaSpeed, deltaSpeed);
	result.roll += ClampFloat(deltaRotation.roll, -deltaSpeed, deltaSpeed);
	return result.GetNormalized();
}

// Clamps the float value between min and max
stock float ClampFloat(const float value, const float min, const float max)
{
	return (value < min) ? min : (value < max) ? value : max;
}