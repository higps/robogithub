#include <sdktools>
#include "ilib/client.inc"

#if defined _ilib_tempents_included
 #endinput
#endif
#define _ilib_tempents_included

/*
* Struct used to store information for most tempents
*/
enum struct FTempentProperties
{
	float Radius;
	float EndRadius;

	float Scale;

	int Model;
	int Halo;

	int StartFrame;
	int FrameRate;

	float Lifetime;
	float Width;
	float Amplitude;

	int Magnitude;
	int Brightness;

	int Color[4];

	int Speed;

	int Flags;
}

// General tempent constructor - most common tempents will use these properties
stock FTempentProperties ConstructTempent(float scale = 1.0, float radius = 0.0, float end_radius = 0.0, int model = -1, int halo = -1, float life = 0.0, float width = 0.0, int rate = 1)
{
	FTempentProperties info;

	info.Scale = scale;
	info.Radius = radius;
	info.EndRadius = end_radius;
	info.Model = model;
	info.Halo = halo;
	info.Lifetime = life;
	info.Width = width;

	info.FrameRate = rate;

	return info;
}

/*
* Methodmap for creating tempents
*/
methodmap FTempEnt
{
	/*
	* Wrapper for TE_SetupBeamRingPoint()
	*
	* @param client		Client to send this tempent to, a reference to the world will send to all
	* @param origin		Position to spawn this tempent at
	* @param info		Struct containing the information for this tempent
	*/
	public static void CreateRing(FClient client, FVector origin, FTempentProperties info)
	{
		float pos[3];
		pos = Vector_MakeFloat(origin);

		TE_SetupBeamRingPoint(pos, info.Radius, info.EndRadius, info.Model, info.Halo, info.StartFrame, info.FrameRate, info.Lifetime, info.Width, info.Amplitude, info.Color, info.Speed, info.Flags);

		if (IsWorld(client))
			TE_SendToAll();
		else if (client.Valid())
			TE_SendToClient(client.Get());
	}

	/*
	* Wrapper for TE_SetupSmoke()
	*
	* @param client		Client to send this tempent to, a reference to the world will send to all
	* @param origin		Position to spawn this tempent at
	* @param info		Struct containing the information for this tempent
	*/
	public static void CreateSmoke(FClient client, FVector origin, FTempentProperties info)
	{
		float pos[3];
		pos = Vector_MakeFloat(origin);

		TE_SetupSmoke(pos, info.Model, info.Scale, info.FrameRate);

		if (IsWorld(client))
			TE_SendToAll();
		else if (client.Valid())
			TE_SendToClient(client.Get());
	}

	/*
	* Wrapper for TE_SetupExplosion()
	*
	* @param client		Client to send this tempent to, a reference to the world will send to all
	* @param origin		Position to spawn this tempent at
	* @param info		Struct containing the information for this tempent
	*/
	public static void CreateExplosion(FClient client, FVector origin, FTempentProperties info)
	{
		float pos[3];
		pos = Vector_MakeFloat(origin);

		TE_SetupExplosion(pos, info.Model, info.Scale, info.FrameRate, info.Flags, RoundFloat(info.Radius), info.Magnitude);
		
		if (IsWorld(client))
			TE_SendToAll();
		else if (client.Valid())
			TE_SendToClient(client.Get());
	}

	/*
	* Wrapper for TE_SetupBeamPoints()
	*
	* @param client			Client to send this tempent to, a reference to the world will send to all
	* @param origin			Position to spawn this tempent at
	* @param destination	Position to connect beam to
	* @param info			Struct containing the information for this tempent
	*/
	public static void CreateBeam(FClient client, FVector origin, FVector destination, FTempentProperties info)
	{
		TE_SetupBeamPoints(origin.ToFloat(), destination.ToFloat(), info.Model, info.Halo, info.StartFrame, info.FrameRate, info.Lifetime, info.Width, info.Width, info.Magnitude, info.Amplitude, info.Color, info.Speed);
		
		if (IsWorld(client))
			TE_SendToAll();
		else if (client.Valid())
			TE_SendToClient(client.Get());
	}

	/*
	* Wrapper for TE_SetupGlowSprite()
	*
	* @param client			Client to send this tempent to, a reference to the world will send to all
	* @param origin			Position to spawn this tempent at
	* @param info			Struct containing the information for this tempent
	*/
	public static void CreateGlowSprite(FClient client, FVector origin, FTempentProperties info)
	{
		TE_SetupGlowSprite(origin.ToFloat(), info.Model, info.Lifetime, info.Scale, info.Brightness);

		if (IsWorld(client))
			TE_SendToAll();
		else if (client.Valid())
			TE_SendToClient(client.Get());
	}
}

/*
* Creates a box from beams and displays it to all
*
* @param pos	World position to spawn the box
* @param size	Size of mins and maxs of the box
*/
stock void Tempent_DrawBox(FVector pos, float size, float duration = 0.1)
{
	FVector min, max;
	max = ConstructVector(size, size, size);
	min = ConstructVector(size * -1.0, size * -1.0, size * -1.0);

	Vector_Add(max, pos, max);
	Vector_Add(min, pos, min);

	FVector pos1, pos2, pos3, pos4, pos5, pos6;
	pos1 = max;
	pos1.X = min.X;

	pos2 = max;
	pos2.Y = min.Y;

	pos3 = max;
	pos3.Z = min.Z;

	pos4 = min;
	pos4.X = max.X;

	pos5 = min;
	pos5.Y = max.Y;

	pos6 = min;
	pos6.Z = max.Z;

	FTempentProperties info;
	info.Model = PrecacheModel("materials/sprites/laser.vmt");
	info.Halo = info.Model;
	info.Lifetime = duration;
	info.Width = 1.0;
	info.Color = {255, 255, 255, 255};

	FClient world;
	world = GetWorld();

	FTempEnt.CreateBeam(world, max, pos1, info);
	FTempEnt.CreateBeam(world, max, pos2, info);
	FTempEnt.CreateBeam(world, max, pos3, info);

	FTempEnt.CreateBeam(world, pos6, pos1, info);
	FTempEnt.CreateBeam(world, pos6, pos2, info);
	FTempEnt.CreateBeam(world, pos6, min, info);

	FTempEnt.CreateBeam(world, pos4, min, info);
	FTempEnt.CreateBeam(world, pos4, pos3, info);
	FTempEnt.CreateBeam(world, pos4, pos2, info);

	FTempEnt.CreateBeam(world, pos5, min, info);
	FTempEnt.CreateBeam(world, pos5, pos1, info);
	FTempEnt.CreateBeam(world, pos5, pos3, info);
}