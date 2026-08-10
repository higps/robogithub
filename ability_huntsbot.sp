#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>

Handle g_SDKCallCreateArrow = INVALID_HANDLE;

bool  g_button_held[MAXPLAYERS + 1] = { false, ... };
float g_arrow_angles[MAXPLAYERS + 1][3];
// float g_currenttime;
bool  g_FireMode					= false;
float g_skill;
float g_skill_cooldown = 1.0;
float g_skill_time;
float g_f_duration = 8.0;
bool  b_alerted	   = false;
float g_fired_cooldown;
float g_huntsman_arrow_speed = 2600.0;
float g_huntsman_arrow_gravity = 0.3;
int g_huntsman_arrow_projectile_type = 0;
#define ROBOT_NAME "Huntsbot"

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

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		if (GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_ATTACK3)
		{
			g_button_held[client] = true;
		}

		if (GetEntProp(client, Prop_Data, "m_afButtonReleased") & IN_ATTACK3)
		{
			g_button_held[client] = false;
		}

		g_skill = GetEngineTime();
		g_arrow_angles[client][0] = angles[0];
		g_arrow_angles[client][1] = angles[1];
		g_arrow_angles[client][2] = angles[2];

		DrawHUD(client);
	}
	return Plugin_Continue;
}

void DrawHUD(int client)
{
	char sHUDText[128];

	int	 iCountDown = RoundToCeil(g_skill_time - g_skill);
	int iFireDuration = RoundToCeil(g_f_duration - g_f_duration);
	Format(sHUDText, sizeof(sHUDText), "Rapid Fire in %i", iCountDown);

	if (iCountDown <= 0)
	{
		if (g_FireMode)
		{
			Format(sHUDText, sizeof(sHUDText), "Cooldown! %i", iCountDown);
			SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 0, 0);
		}
		else {
			if (!b_alerted)
			{
				TF2_AddCondition(client, TFCond_InHealRadius, 0.5);

				b_alerted = true;
			}

			Format(sHUDText, sizeof(sHUDText), "Rapid Fire Ready!\nUse Special Attack to Activate!");
			SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);
		}
	}
	else {
		SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 0, 255);
	}

	if (g_button_held[client] && iCountDown <= 0)
	{
		float vPos[3];
		float vForward[3];
		GetClientEyePosition(client, vPos);
		GetAngleVectors(g_arrow_angles[client], vForward, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vForward, 32.0);
		AddVectors(vPos, vForward, vPos);
		SpawnHuntsmanArrow(client, vPos, g_arrow_angles[client], g_huntsman_arrow_speed);

		// TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		// TF2_AddCondition(client, TFCond_RuneHaste, g_f_duration);
		g_skill_time = GetEngineTime() + g_skill_cooldown;
		b_alerted	 = false;
		g_fired_cooldown = GetEngineTime() + g_f_duration;
	}

	// if (FireModeTimer <= GetEngineTime() && g_FireMode)
	// {
	// ResetWeapon(client);
	// }
	// if (TF2_IsPlayerInCondition(TFCond_RuneHaste, client))
	// {
	// 	Format(sHUDText, sizeof(sHUDText), "Rapid Fire! %i", iFireDuration);
	// 	// SetHudTextParams(0.85, 0.6, 0.1, 255, 69, 0, 255);
	// }

	ShowHudText(client, -3, sHUDText);
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
