#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
#include <tf2_stocks>

float g_dmg_needed[MAXPLAYERS + 1];
int g_levels[MAXPLAYERS + 1];

// Handle g_hGameConf;
// Handle g_hIsDeflectable;

    //Loading code where robots can't use resupply lockers
    // g_hGameConf = LoadGameConfigFile("mm_spawn_health_packs");

    // g_hGameConf = LoadGameConfigFile("bm_charge_airblast_immunity_data");

    // IsDeflectable
    // g_hIsDeflectable = DHookCreate(0, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, IsPlayerDeflectable);
    // if(g_hIsDeflectable == null) SetFailState("Failed to setup hook for CTFPowerup::DropSingleInstance()!"); 

    // if(!DHookSetFromConf(g_hIsDeflectable, g_hGameConf, SDKConf_Virtual, "CTFPowerup::DropSingleInstance()"))
    // SetFailState("Failed to find CTFPowerup::DropSingleInstance() offset in the gamedata!");

    // // //Finds players to hook for IsDeflectable
    // // // FindAndHookPlayers();

    // delete g_hGameConf;

bool HasStat(int attacker)
{
	int Weapon3 = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);
	if(Weapon3 == -1) return false;

	char stat_buffer[256];
	if (!TF2CustAttr_GetString(Weapon3, "spawn-healthpack-on-dmg", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}
	g_dmg_needed[attacker] = ReadFloatVar(stat_buffer, "damage", 500.0);
	g_levels[attacker] = ReadIntVar(stat_buffer, "levels", 3);
	// PrintToChatAll("HAS STATS");
	return true;
}

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_skill; 
float g_damagedone[MAXPLAYERS + 1] = {0.0,...};

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (HasStat(client))
	{

		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE) ) 
		{
			//  PrintToChatAll("Press");
            g_button_held[client] = true;
		}

		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE) ) 
		{
			//  PrintToChatAll("Release");
			g_button_held[client] = false;
            
		}

		g_skill = GetEngineTime();
		DrawHUD(client);
		
	}
	return Plugin_Continue;
}

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"
#define LVL1 "item_healthkit_small"
#define LVL2 "item_healthkit_medium"
#define LVL3 "item_healthkit_small"

void DrawHUD(int client)
{
	char sHUDText[128];
	char sProgress[32];
	int iPercents = RoundToCeil(g_damagedone[client] / g_dmg_needed[client] * 100.0);

	for (int j = 1; j <= 10; j++)
	{
		if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
		else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}
	
	Format(sHUDText, sizeof(sHUDText), "Healthpack Mode: %i %%%%\n    %s",iPercents, sProgress);

	if(iPercents >= 100)
	{

	Format(sHUDText, sizeof(sHUDText), "Healthpack Ready!\nUse Special Attack to spawn!");
	SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);	
			
	}else {

		SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 255, 255);
	}


	ShowHudText(client, -3, sHUDText);


	if (iPercents >= 10 && g_button_held[client])
	{
		int team = GetClientTeam(client);
		float pos[3], vel[3];// ang[3];
		int children = 1;
		float speed = 250.0;


    GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
		pos[2] += 10.0;
		for (int i = 1; i <= children; i++)
		{
			// CBaseEntity@ healthPackEntity = CTFPowerup::DropSingleInstance(client, PowerupType::Health);
			int child = CreateEntityByName("item_healthkit_small");
			
			
			float child_vel[3];
			float child_ang[3];

			//Prevent child grenades from detonating on contact
			// SetEntProp(child, Prop_Send, "m_bTouched", 1);

			//Set properties
			//SetEntProp(child, Prop_Send, "m_bCritical", view_as<int>(crit));
			SetEntPropEnt(child, Prop_Data, "m_hOwnerEntity", client);
			// SetEntPropEnt(child, Prop_Data, "m_hThrower", client);

			
			// SetEntPropFloat(child, Prop_Send, "m_flDamage", 100.0);
			// SetEntPropFloat(child, Prop_Send, "m_flModelScale", 1.2);
			
			GetClientEyeAngles(client, child_ang);
			
			GetAngleVectors(child_ang, child_vel, NULL_VECTOR, NULL_VECTOR);
			
			ScaleVector(child_vel, speed);
				
			//child_vel[2] = FloatAbs(child_vel[2]);

			SetEntProp(child, Prop_Send, "m_iTeamNum", 0, 4);
			// SetEntProp(child, Prop_Send, "m_bIsLive", 1);
			//SetEntProp(Medipack, Prop_Send, "m_iTeamNum", 0, 4);

			TeleportEntity(child, pos, child_ang, child_vel);
			DispatchKeyValue(child, "OnPlayerTouch", "!self,Kill,,0,-1");
			SetEntityMoveType(child, MOVETYPE_VPHYSICS);
			DispatchSpawn(child);
			ActivateEntity(child);

			//SDKHook(child, SDKHook_Touch, OnMirvOverlap);
			g_damagedone[client] = 0.0;
		}
	}


	// b_hud_clamp[client] = false;
}


public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
int damagecustom, CritType &critType)
{

	if(IsValidClient(victim))
	{
		if(IsValidClient(attacker))
		{
			
			if(HasStat(attacker))
			{
				g_damagedone[attacker] += damage;
				
			}
		}
	}

	return Plugin_Continue;
}

// stock TF_SpawnMedipack(client, String:name[], bool:cmd)
// {
//     new Float:PlayerPosition[3];
//     if (cmd)
// 	{
//         GetClientAbsOrigin(client, PlayerPosition);
// 	}
//     else
// 	{
//         //PlayerPosition = g_MedicPosition[client];
// 	}

//     if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
//     {
//         PlayerPosition[2] += 4;
//         g_FilteredEntity = client;
//         if (cmd)
//         {
//             new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
//             GetClientEyeAngles(client, PlayerAngle);
//             PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
//             PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
//             PlayerPosEx[2] = 0.0;
//             ScaleVector(PlayerPosEx, 75.0);
//             AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

//             new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);
//             TR_GetEndPosition(PlayerPosition, TraceEx);
//             CloseHandle(TraceEx);
//         }

//         new Float:Direction[3];
//         Direction[0] = PlayerPosition[0];
//         Direction[1] = PlayerPosition[1];
//         Direction[2] = PlayerPosition[2]-1024;
//         new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);

//         new Float:MediPos[3];
//         TR_GetEndPosition(MediPos, Trace);
//         CloseHandle(Trace);
//         MediPos[2] += 4;

//         new Medipack = CreateEntityByName(name);
//         DispatchKeyValue(Medipack, "OnPlayerTouch", "!self,Kill,,0,-1");
//         if (DispatchSpawn(Medipack))
//         {
//             SetEntProp(Medipack, Prop_Send, "m_iTeamNum", 0, 4);
//             TeleportEntity(Medipack, MediPos, NULL_VECTOR, NULL_VECTOR);
//             EmitSoundToAll("items/spawn_item.wav", Medipack, _, _, _, 0.75);
//             //SetArrayCell(g_MedipacksTime, Medipack, GetTime());
//         }
//     }
// }