#pragma semicolon 1
#include <sdkhooks>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <dhooks>
#include <tf_ontakedamage>

#define PLUGIN_VERSION "1.0"

// #define SOUND_LEAP  "TFPlayer.AirBlastImpact"
float jump_timer = 2.0;
public Plugin:myinfo =
{
	name = "[TF2] Sniper AOE Buff",
	author = "HeavyIsGPS",
	description = "Ability for sniper",
	version = PLUGIN_VERSION,
	url = "www.bmod.tf"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

int g_iBeam;
int g_iHalo;

int iREDTeamColor[4] = {255,104,104,255};
int iBLUTeamColor[4] = {113,175,255,255};
int iSpecTeamColor[4] = {255,228,151,255}; //int iSpecTeamColor[4] = {170,170,170,255}; //Alt color

public void OnMapStart()
{
	//Precache
	g_iBeam = PrecacheModel("materials/sprites/laser.vmt");
	g_iHalo = PrecacheModel("materials/sprites/halo01.vmt");
	
}

float startradius = 240.0;
float endradius = 250.0;
float lifetime = 2.0;
float width = 5.0;
float height = 75.0;
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	float pos1[3];
	float pos22[3];
	float pos2[3];
	GetClientAbsOrigin(attacker, pos1); // hack: make the explosion actually come from the attacker, that way we only have to hook one client


	TE_SetupBeamRingPoint(pos1, float startradius, float endradius, int g_iBeam, int g_iHalo, int StartFrame, int FrameRate, float Life, float Width, float Amplitude, const int Color[4], int Speed, int Flags)
	
	if (IsAnyRobot(attacker))
	{
		switch(TF2_GetClientTeam(attacker))
		{
			case TFTeam_Red:
			{

				CreateBeamRing(attacker, TFTeam_Red, startradius, endradius, lifetime, width, height);
				

			}
			case TFTeam_Blue:
			{

				CreateBeamRing(attacker, TFTeam_Blue, startradius, endradius, lifetime, width, height);
				
			}
		}
		
	}

	for(int client = 1 ; client <= MaxClients ; client++ )
	{
		if(IsClientInGame(client))
		{
			GetClientAbsOrigin(client, pos2);
			if(GetVectorDistance(pos1, pos2) <= endradius/0.8 && TF2_GetClientTeam(attacker) == TF2_GetClientTeam(client))
			{
				PrintToChatAll("%N", client);
				TF2_AddCondition(client, TFCond_CritCola, 5.0);
				
				//return Plugin_Changed;

			}
		}
	}

}

stock bool CreateBeamRing(int client, 
							TFTeam iTeam = TFTeam_Spectator,
							float fStartRadius = 0.0, 
							float fEndRadius = 96.0, 
							float fLifeTime = 0.5,
							float fWidth = 5.0,
							float fRaiseRing = 0.0,
							bool bShowOnlyToClient = false)
{
	if(!IsValidClient(client)) return false;
	

	
	int iStartFrame = 0;
	int iFrameRate = 30;
	int iSpeed = 0;
	
	float fOrigin[3];
	float fAmplitude = 0.0;
	
	if(client == -1) return false; 
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", fOrigin);
	if(fRaiseRing > 0.0) fOrigin[2] += fRaiseRing; //Raises the ring from the floor
	
	switch(iTeam)
	{
		case TFTeam_Red:
		{
			TE_SetupBeamRingPoint(fOrigin, 
			fStartRadius, 
			fEndRadius, 
			g_iBeam, 
			g_iHalo, 
			iStartFrame, 
			iFrameRate, 
			fLifeTime, 
			fWidth, 
			fAmplitude, 
			iREDTeamColor, 
			iSpeed, FBEAM_HALOBEAM);
			
			TE_SendToAll();

			
			return true;
		}
		case TFTeam_Blue:
		{
			TE_SetupBeamRingPoint(fOrigin, 
			fStartRadius, 
			fEndRadius, 
			g_iBeam, 
			g_iHalo, 
			iStartFrame, 
			iFrameRate, 
			fLifeTime, 
			fWidth, 
			fAmplitude, 
			iBLUTeamColor, 
			iSpeed, FBEAM_HALOBEAM);
			
	
			TE_SendToAll();
			
			
			return true;
		}
		default:
		{
			TE_SetupBeamRingPoint(fOrigin, 
			fStartRadius, 
			fEndRadius, 
			g_iBeam, 
			g_iHalo, 
			iStartFrame, 
			iFrameRate, 
			fLifeTime, 
			fWidth, 
			fAmplitude, 
			iSpecTeamColor, 
			iSpeed, FBEAM_HALOBEAM);
			

				TE_SendToAll();
			
		}
	}
	return false;
}