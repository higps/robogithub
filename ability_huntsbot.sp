#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>

Handle g_SDKCallCreateArrow = INVALID_HANDLE;

float g_huntsman_arrow_speed = 2600.0;
float g_huntsman_arrow_gravity = 0.3;
int g_huntsman_arrow_projectile_type = 0;
#define ROBOT_NAME "Huntsbot"

void SpawnSplitArrowKillBurst(int attacker, int victim)
{
	float basePos[3];
	float vPos[3];
	float vAng[3];
	float vForward[3];
	float baseYaw;

	GetClientAbsOrigin(victim, basePos);
	basePos[2] += 80.0;
	GetClientEyeAngles(attacker, vAng);

	vAng[0] = 0.0;
	vAng[2] = 0.0;
	baseYaw = vAng[1];

	// vAng[1] = baseYaw;
	// GetAngleVectors(vAng, vForward, NULL_VECTOR, NULL_VECTOR);
	// ScaleVector(vForward, 16.0);
	// vPos = basePos;
	// AddVectors(vPos, vForward, vPos);
	// SpawnHuntsmanArrow(attacker, vPos, vAng, g_huntsman_arrow_speed);

	vAng[1] = baseYaw - 30.0;
	GetAngleVectors(vAng, vForward, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vForward, 16.0);
	vPos = basePos;
	AddVectors(vPos, vForward, vPos);
	SpawnHuntsmanArrow(attacker, vPos, vAng, g_huntsman_arrow_speed);

	vAng[1] = baseYaw + 30.0;
	GetAngleVectors(vAng, vForward, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vForward, 16.0);
	vPos = basePos;
	AddVectors(vPos, vForward, vPos);
	SpawnHuntsmanArrow(attacker, vPos, vAng, g_huntsman_arrow_speed);
}

bool IsHuntsmanLauncher(int weapon)
{
	if (weapon <= MaxClients || !IsValidEntity(weapon))
		return false;

	switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 56, 1005, 1092:
		{
			return true;
		}
	}

	return false;
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);

	Handle hGameConf = LoadGameConfigFile("huntsbot_arrow");
	if (hGameConf == INVALID_HANDLE)
	{
		LogError("Failed to load gamedata huntsbot_arrow. Falling back to manual arrow spawn.");
		return;
	}

	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFProjectile_Arrow::Create"))
	{
		LogError("Failed to find signature CTFProjectile_Arrow::Create. Falling back to manual arrow spawn.");
		CloseHandle(hGameConf);
		return;
	}

	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	g_SDKCallCreateArrow = EndPrepSDKCall();
	if (g_SDKCallCreateArrow == INVALID_HANDLE)
		LogError("Failed to prepare CTFProjectile_Arrow::Create SDKCall. Falling back to manual arrow spawn.");

	CloseHandle(hGameConf);
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (attacker == victim)
		return Plugin_Continue;
	if (!IsValidClient(attacker) || !IsValidClient(victim))
		return Plugin_Continue;
	if (!IsRobot(attacker, ROBOT_NAME))
		return Plugin_Continue;

	SpawnSplitArrowKillBurst(attacker, victim);
	return Plugin_Continue;
}

stock int GetArrowLauncher(int client)
{
	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (IsHuntsmanLauncher(weapon))
		return weapon;

	weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon > MaxClients && IsValidEntity(weapon))
		return weapon;

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (weapon > MaxClients && IsValidEntity(weapon))
		return weapon;

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (weapon > MaxClients && IsValidEntity(weapon))
		return weapon;

	return -1;
}

stock int SpawnHuntsmanArrow(int client, float vPos[3], float vAng[3], float flSpeed = 2600.0)
{
	int launcher = GetArrowLauncher(client);
	int arrow = -1;
	float vVelocity[3];
	GetAngleVectors(vAng, vVelocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vVelocity, flSpeed);
	int damageOffset = FindSendPropInfo("CTFProjectile_Arrow", "m_iDeflected");

	if (g_SDKCallCreateArrow != INVALID_HANDLE)
	{
		arrow = SDKCall(g_SDKCallCreateArrow, vPos, vAng, flSpeed, g_huntsman_arrow_gravity, g_huntsman_arrow_projectile_type, client, client);
		if (arrow > MaxClients && IsValidEntity(arrow))
		{
			if (launcher != -1 && HasEntProp(arrow, Prop_Send, "m_hLauncher"))
				SetEntPropEnt(arrow, Prop_Send, "m_hLauncher", launcher);
			if (launcher != -1 && HasEntProp(arrow, Prop_Send, "m_hOriginalLauncher"))
				SetEntPropEnt(arrow, Prop_Send, "m_hOriginalLauncher", launcher);
			if (damageOffset != -1)
				SetEntDataFloat(arrow, damageOffset + 4, 57.0, true);
			if (HasEntProp(arrow, Prop_Send, "m_flDamage"))
				SetEntPropFloat(arrow, Prop_Send, "m_flDamage", 57.0);
			if (HasEntProp(arrow, Prop_Send, "m_bCritical"))
				SetEntProp(arrow, Prop_Send, "m_bCritical", 0);
			return arrow;
		}
	}

	arrow = CreateEntityByName("tf_projectile_arrow");
	if (arrow == -1) return -1;

	int team = GetClientTeam(client);

	SetVariantInt(team);
	AcceptEntityInput(arrow, "TeamNum", -1, -1, 0);
	SetVariantInt(team);
	AcceptEntityInput(arrow, "SetTeam", -1, -1, 0);

	SetEntPropEnt(arrow, Prop_Data, "m_hOwnerEntity", client);
	SetEntPropEnt(arrow, Prop_Send, "m_hOwnerEntity", client);
	if (HasEntProp(arrow, Prop_Send, "m_hThrower"))
		SetEntPropEnt(arrow, Prop_Send, "m_hThrower", client);
	if (launcher != -1 && HasEntProp(arrow, Prop_Send, "m_hLauncher"))
		SetEntPropEnt(arrow, Prop_Send, "m_hLauncher", launcher);
	if (launcher != -1 && HasEntProp(arrow, Prop_Send, "m_hOriginalLauncher"))
		SetEntPropEnt(arrow, Prop_Send, "m_hOriginalLauncher", launcher);
	SetEntProp(arrow, Prop_Send, "m_iTeamNum", team);
	if (HasEntProp(arrow, Prop_Data, "m_iTeamNum"))
		SetEntProp(arrow, Prop_Data, "m_iTeamNum", team);
	if (HasEntProp(arrow, Prop_Send, "m_nSkin"))
		SetEntProp(arrow, Prop_Send, "m_nSkin", team - 2);
	if (HasEntProp(arrow, Prop_Send, "m_bCritical"))
		SetEntProp(arrow, Prop_Send, "m_bCritical", 0);
	if (HasEntProp(arrow, Prop_Send, "m_flCreationTime"))
		SetEntPropFloat(arrow, Prop_Send, "m_flCreationTime", GetGameTime());
	if (HasEntProp(arrow, Prop_Data, "m_flCreateTime"))
		SetEntPropFloat(arrow, Prop_Data, "m_flCreateTime", GetGameTime());

	if (damageOffset != -1)
		SetEntDataFloat(arrow, damageOffset + 4, 57.0, true);

	TeleportEntity(arrow, vPos, vAng, vVelocity);
	DispatchSpawn(arrow);
	return arrow;
}
