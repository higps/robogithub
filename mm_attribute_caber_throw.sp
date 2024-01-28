/*
	Caber throw ability

	Attribute name = "caber-throw"

	variables:
		damage = "caber_blast_damage" - float
		speed = "caber_grenade_speed" - float
		blast radius = "caber_blast_radius" - float
		regen time = "caber_regen_time"	- float
		det on impact = "caber_det_impact" - integer [0, 1]
*/

#pragma semicolon 1

#include <sdkhooks>
#include <ilib>
#include <ilib_objects>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_custom_attributes>
//#include <stocksoup/var_strings>

public Plugin MyInfo =
{
	name = "Caber Throw",
	author = "IvoryPal",
	description = "Demoman can throw cabers!"
};

enum struct FCaber
{
	float Damage;
	float Speed;
	float Radius;
	bool DetOnImpact;
	bool OnCooldown;
	float RegenDuration;

	FTimer RegenTimer;
}
FCaber CaberGrenade[2049];

bool ThrownCaber[2049] = {false, ...}; // is this entity a thrown caber
FTimer HudTimer[MAXPLAYERS+1];

const float HudRefreshRate = 0.2;
Handle HudSync;

Handle SDKCallInitGrenade;

bool HasStat(int weapon, FCaber caber)
{
	if (weapon == -1)
	{
		return false;
	}

	FWeapon melee;
	melee = ConstructWeapon(weapon);

	if (melee.DefIndex != 307) // this is only valid for the caber
	{
		return false;
	}

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(weapon, "caber-throw", stat_buffer, sizeof(stat_buffer)))
	{
		return false;
	}

	caber.Damage = ReadFloatVar(stat_buffer, "caber_blast_damage", 100.0);
	caber.Radius = ReadFloatVar(stat_buffer, "caber_blast_radius", 176.0);
	caber.DetOnImpact = view_as<bool>(ReadIntVar(stat_buffer, "caber_det_impact", 0));
	caber.RegenDuration = ReadFloatVar(stat_buffer, "caber_regen_time", 20.0);
	caber.Speed = ReadFloatVar(stat_buffer, "caber_grenade_speed", 1600.0);

	return true;
}

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("tf2.cattr_starterpack");
	if (!hGameConf)
	{
		SetFailState("Failed to load gamedata (tf2.cattr_starterpack).");
	} 
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFWeaponBaseGrenadeProj::InitGrenade(int float)");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	SDKCallInitGrenade = EndPrepSDKCall();

	HudSync = CreateHudSynchronizer();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	HudTimer[client] = ConstructTimer(HudRefreshRate, false, true, false, HudRefreshRate * -1.0);
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || entity > 2048) return; //prevent ent refs being used
	if (IsValidEntity(entity))
	{
		ThrownCaber[entity] = false;
	}
}

public void OnPlayerRunCmdPost(int clientId, int buttons)
{
	FClient client;
	client = ConstructClient(clientId);

	if (client.Alive() && client.GetClass() == TFClass_DemoMan)
	{
		int weaponId = client.GetSlot(TFWeaponSlot_Melee);
		if (weaponId == -1)
			return;

		if (HasStat(weaponId, CaberGrenade[weaponId]))
		{
			if (CaberGrenade[weaponId].OnCooldown)
			{
				if (HudTimer[clientId].Expired())
				{
					float timeLeft = CaberGrenade[weaponId].RegenTimer.GetTimeRemaining();
					SetHudTextParams(-1.0, 0.65, HudRefreshRate, 255, 255, 255, 255);

					ShowSyncHudText(clientId, HudSync, "Caber Cooldown: %.0fs", timeLeft);
				}

				if (CaberGrenade[weaponId].RegenTimer.Expired())
				{
					CaberGrenade[weaponId].OnCooldown = false; // Ready to throw again
				}

				return;
			}

			if (buttons & IN_ATTACK2 && !CaberGrenade[weaponId].OnCooldown)
			{
				if (GetEntProp(weaponId, Prop_Send, "m_bBroken")) // Can't throw a broken grenade..
					return;
				
				if (GetEntProp(weaponId, Prop_Send, "m_iDetonated"))
					return;

				ThrowCaber(client, weaponId, CaberGrenade[weaponId]);
			}
		}
	}
}

void ThrowCaber(FClient client, int weaponId, FCaber caber)
{
	caber.OnCooldown = true;
	caber.RegenTimer = ConstructTimer(caber.RegenDuration, false, false, true);

	PrecacheModel("models/weapons/c_models/c_caber/c_caber.mdl");

	FVector position;
	position = FMath.OffsetVector(client.GetEyePosition(), client.GetEyeAngles(), ConstructVector(0.0, -6.5, -15.25));
	
	// Now create the actual grenade
	FObject grenade;
	grenade = FGameplayStatics.CreateObjectDeferred("tf_projectile_pipe");

	SetVariantInt(client.GetTeam());
	grenade.Input("SetTeam");

	SetVariantInt(client.GetTeam());
	grenade.Input("TeamNum");

	SetProjectileLauncher(ConstructObject(weaponId), grenade);

	grenade.SetOwner(client.GetObject());

	FTransform transform;
	transform.Position = position;

	transform.Rotation = client.GetEyeAngles();
	transform.Rotation.Pitch -= 10.0;

	FGameplayStatics.FinishSpawn(grenade, transform);

	FVector velocity, angVelocity;
	velocity = transform.Rotation.GetForwardVector();
	velocity.Scale(caber.Speed);

	angVelocity = ConstructVector(0.0, 500.0, 0.0);

	SDKCall(SDKCallInitGrenade, grenade.Get(), velocity.ToFloat(), angVelocity.ToFloat(), client.Get(), RoundFloat(caber.Damage), caber.Radius);

	grenade.SetModel("models/weapons/c_models/c_caber/c_caber.mdl");
	grenade.SetPropFloat(Prop_Send, "m_flModelScale", 1.75);

	PrecacheSound("weapons/cleaver_throw.wav");
	EmitSoundToAll("weapons/cleaver_throw.wav", client.Get(), SNDCHAN_AUTO, SNDLEVEL_NORMAL);

	if (!caber.DetOnImpact)
	{
		grenade.SetProp(Prop_Send, "m_bTouched", 1); // Do not detonate on impact
	}

	ThrownCaber[grenade.Get()] = true;

	SetProjectileProperties(UBaseProjectile(grenade), caber);
}

void SetProjectileProperties(UBaseProjectile grenade, FCaber caber)
{
	// If invalid, stop here
	if (!grenade.Valid())
		return;

	// Set our properties for the newly spawned projectile
	grenade.Damage = caber.Damage;

	if (caber.DetOnImpact) // Pipes need m_flFullDamage set for impact damage 
		SetFullDamage(grenade, caber.Damage);
}

void SetFullDamage(UBaseProjectile grenade, float damage)
{
	// not a networked property so we need to get its offset
	int damageOffset = FindSendPropInfo("CTFGrenadePipebombProjectile", "m_bDefensiveBomb") - 4; // 4 bytes before m_bDefensiveBomb

	if (damageOffset > 0)
	{
		SetEntDataFloat(grenade.Get(), damageOffset, damage);
	}
}

void SetProjectileLauncher(FObject entity, FObject child)
{
	child.SetPropEnt(Prop_Send, "m_hOriginalLauncher", entity);
	child.SetPropEnt(Prop_Send, "m_hLauncher", entity);
}
