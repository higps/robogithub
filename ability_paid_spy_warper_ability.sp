#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
#include <tf_ontakedamage>
#include <tf2_isPlayerInSpawn>
//#include <tf2items_giveweapon>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Warper"

#define TELEPORTER_SPAWN		"weapons/teleporter_ready.wav"

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"

bool g_button_held_to_enemy[MAXPLAYERS + 1] = {false, ...};
bool g_button_held_to_previous[MAXPLAYERS + 1] = {false, ...};

float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 10.0;
float g_skill;
int g_target[MAXPLAYERS + 1] = {-1,...};
float g_target_coords[3] = {0.0, ...};
float g_past_coords[3] = {0.0, ...};
float g_scale = 1.5;

public Plugin:myinfo =
{
	name = "[TF2] Warper Ability",
	author = "HiGPS | Bmod.TF",
	description = "The Warper Spy Ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

void ResetTeleCoordinates()
{
    for(int client = 1 ; client <= MaxClients ; client++ )
    {
        g_target[client] = -1; 
    }
}

public void OnRoundStart()
{
    ResetTeleCoordinates();
}

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("post_inventory_application", Event_PlayerSpawn);
    HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client > 0)
    {
      g_target[client] = -1;
    }

    return Plugin_Continue;
}
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	//PrintToChatAll("Logname %s", weapon_logname);
	//int weaponID = GetEntPropEnt(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	//PrintToChatAll("Attacker %N , weaponID %i, logname: %s", attacker, weaponID, weapon_logname);

	if (IsRobot(attacker, ROBOT_NAME))
	{
		g_Recharge[attacker] = 0.0;
	}
}

public OnMapStart()
{
	PrecacheSound(TELEPORTER_SPAWN, true);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{

		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE) ) 
		{
            g_button_held_to_enemy[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE) ) 
		{
			g_button_held_to_enemy[client] = false;
            
		}

        if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_RELOAD) ) 
		{
            g_button_held_to_previous[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_RELOAD) ) 
		{
			g_button_held_to_previous[client] = false;
            
		} 

		g_skill = GetEngineTime();
		DrawHUD(client);
		
	}
}

bool isready;
void DrawHUD(int client)
{
	char sHUDText[128];


	int iCountDown = RoundToCeil(g_Recharge[client] - g_skill);
	
	Format(sHUDText, sizeof(sHUDText), "Warp: %i", iCountDown);
	
    if (IsCloaked(client)) 
    {
		Format(sHUDText, sizeof(sHUDText), "Warp Disabled!\nDecloak to Enable!");
			
		SetHudTextParams(1.0, 0.7, 0.5, 255, 0, 0, 255);

    }else if(iCountDown <= 0 && g_target[client] == -1)
	{

		Format(sHUDText, sizeof(sHUDText), "Warp Ready!\nNeeds Target!");
			
		SetHudTextParams(1.0, 0.7, 0.5, 255, 0, 0, 255);
		

		
	}else if(iCountDown <= 0 && g_target[client] != -1)
	{
		Format(sHUDText, sizeof(sHUDText), "Warp Ready!\nAttack3: To Enemy\nReload: To Self");
			
		SetHudTextParams(1.0, 0.7, 0.5, 0, 255, 0, 255);
	}else
	{
		SetHudTextParams(1.0, 0.7, 0.5, 255, 0, 0, 255);
	}

		 ShowHudText(client, -2, sHUDText);


		if (!isready && iCountDown <= 0)
		{
			TF2_AddCondition(client, TFCond_InHealRadius, 0.5);

			isready = true;	
		}

	if (g_button_held_to_enemy[client] && iCountDown <= 0 && g_target[client] != -1 && !IsCloaked(client))
	{
		RequestFrame(Teleport, client);
	}

    if (g_button_held_to_previous[client] && iCountDown <= 0 && g_target[client] != -1 && !IsCloaked(client))
	{
		RequestFrame(Teleport, client);
	}
}

void Teleport (int client)
{
	if(IsPlayerAlive(client) && !TF2Spawn_IsClientInSpawn(client))
	{




			float PreTeleOrigin[3];
			GetClientAbsOrigin(client, PreTeleOrigin);
			
			
			//Teleport
				int attach = CreateEntityByName("trigger_push");
				TeleportEntity(attach, PreTeleOrigin, NULL_VECTOR, NULL_VECTOR);
				TE_Particle("drg_wrenchmotron_teleport", PreTeleOrigin, _, _, attach, 1,0);
				int attach2 = CreateEntityByName("trigger_push");
				
                if(g_button_held_to_enemy[client])
                {
                TeleportEntity(attach2, g_target_coords, NULL_VECTOR, NULL_VECTOR);
				TE_Particle("drg_wrenchmotron_teleport", g_target_coords, _, _, attach2, 1,0);    
                }else
                {
                TeleportEntity(attach2, g_past_coords, NULL_VECTOR, NULL_VECTOR);
				TE_Particle("drg_wrenchmotron_teleport", g_past_coords, _, _, attach2, 1,0);
                }
                

				// FakeClientCommand(client, "eureka_teleport");
				TF2_AddCondition(client, TFCond_TeleportedGlow, 5.0);
				EmitSoundToAll(TELEPORTER_SPAWN, client);
				EmitSoundToAll(TELEPORTER_SPAWN, client);

                if (g_button_held_to_enemy[client])
                {
                    CreateTimer(0.5, Teleport_Player, client);
                    g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
                }else 
                {
                    CreateTimer(0.5, Teleport_Player_Past, client);
                    g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
                }
				isready = false;

			
		
	}
}

public Action Teleport_Player(Handle timer, int client)
{
	if(IsRobot(client, ROBOT_NAME) && IsPlayerAlive(client) && !IsCloaked(client))
    {
        TeleportEntity(client, g_target_coords, NULL_VECTOR, NULL_VECTOR);
        g_target[client] = -1;
    }
}

public Action Teleport_Player_Past(Handle timer, int client)
{
	if(IsRobot(client, ROBOT_NAME) && IsPlayerAlive(client) && !IsCloaked(client))TeleportEntity(client, g_past_coords, NULL_VECTOR, NULL_VECTOR);
}

void GetCoordinates (int client)
{
	GetClientAbsOrigin(client, g_target_coords);
}

void GetCoordinatesPast(int client)
{
	GetClientAbsOrigin(client, g_past_coords);
}
/* Plugin Exclusive Functions */
//Code that Gets the one to teleport to
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	// if (!g_Enable)
	//     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;
		

	if(IsRobot(attacker, ROBOT_NAME) && !TF2Spawn_IsClientInSpawn(victim))
	{
		g_target[attacker] = victim;

		RequestFrame(GetCoordinates, victim);
        RequestFrame(GetCoordinatesPast, attacker);
		
	}  

	return Plugin_Continue;
}

stock void TE_Particle(char[] Name, float origin[3] = NULL_VECTOR, float start[3] = NULL_VECTOR, float angles[3] = NULL_VECTOR, entindex=-1, attachtype=-1, attachpoint=-1, bool resetParticles=true, customcolors = 0, float color1[3] = NULL_VECTOR, float color2[3] = NULL_VECTOR, controlpoint = -1, controlpointattachment = -1, float controlpointoffset[3] = NULL_VECTOR)
{
    // find string table
    int tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx == INVALID_STRING_TABLE)
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    float delay = 3.0;
    // find particle index
    char tmp[256];
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;

    for (int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx == INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }

    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex !=- 1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype != -1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint != -1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);

    if(customcolors)
    {
        TE_WriteNum("m_bCustomColors", customcolors);
        TE_WriteVector("m_CustomColors.m_vecColor1", color1);
        if(customcolors == 2)
        {
            TE_WriteVector("m_CustomColors.m_vecColor2", color2);
        }
    }
    if(controlpoint != -1)
    {
        TE_WriteNum("m_bControlPoint1", controlpoint);
        if(controlpointattachment != -1)
        {
            TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", controlpointattachment);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", controlpointoffset[0]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", controlpointoffset[1]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", controlpointoffset[2]);
        }
    }
    TE_SendToAll(delay);
}
bool IsCloaked(client)
{
    if (TF2_IsPlayerInCondition(client, TFCond_Cloaked) ||
         TF2_IsPlayerInCondition(client, TFCond_CloakFlicker) || 
        TF2_IsPlayerInCondition(client, TFCond_Stealthed) ||
        TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade) ||
        TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
    {
        return true;
    }
    
    return false;
}