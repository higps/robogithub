#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
#include <dhooks>
#include <sdktools>
#include <tf_custom_attributes>
#include <menus>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Brainiac"

int SelectedIndex[MAXPLAYERS + 1];

#define TELEPORTER_SPAWN		"weapons/teleporter_ready.wav"

public Plugin:myinfo =
{
	name = "[TF2] Brainiac Ability",
	author = "HiGPS | Bmod.TF",
	description = "Brainiac Ability",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}


public OnMapStart()
{
	PrecacheSound(TELEPORTER_SPAWN, true);
}

bool g_button_held[MAXPLAYERS + 1] = false;
float g_Recharge[MAXPLAYERS + 1] = 0.0;
float g_RechargeCooldown = 20.0;
float g_skill;



public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
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
}





bool isready;
void DrawHUD(int client)
{
	char sHUDText[128];


	int iCountDown = RoundToCeil(g_Recharge[client] - g_skill);
	
	Format(sHUDText, sizeof(sHUDText), "MatePort: %i   ", iCountDown);
	

	if(iCountDown <= 0)
	{
		Format(sHUDText, sizeof(sHUDText), "MatePort Ready!");
			
		SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);

		
	} else {
		SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);
		

	}

		 ShowHudText(client, -2, sHUDText);


		if (!isready && iCountDown <= 0)
		{
			TF2_AddCondition(client, TFCond_InHealRadius, 0.5);

			isready = true;	
		}

	if (g_button_held[client] && iCountDown <= 0)
	{
		RequestFrame(CreatePlayerMenu, client);

		
	}
}

// Creates a menu with all active teleporters
void CreatePlayerMenu(int client)
{

	Menu selection = new Menu(SelectionCallback);
	selection.SetTitle("Choose Teammate to Teleport to");

	// selection.AddItem("-1", "Farthest");
	int iTeam = TF2_GetClientTeam(client);

	// float distance = 0.0;
	float origin[3], destination[3];
	// int index = 0;
	for (int i = 0; i < MAXPLAYERS+1; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == iTeam && client != i && IsAnyRobot(i))
		{


			char playerName[256]; 
			char index[8];
			IntToString(i, index, sizeof index);

			// Get the name of the teleporter's owner, otherwise set the teleporter's index as the name as a fallback
			if (IsClientInGame(client)){
				

				GetClientAbsOrigin(client, origin);
				GetClientAbsOrigin(i, destination);
				float PlayerDistance = GetVectorDistance(origin, destination);

				FormatEx(playerName, sizeof playerName, "Distance: %i: %N" , RoundToNearest(PlayerDistance), i);
				selection.AddItem(index, playerName);
			}
		}
	}

	selection.Display(client, 3);
}

int SelectionCallback(Menu menu, MenuAction action, int client, int selection)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char value[8];
			menu.GetItem(selection, value, sizeof value);

			SelectedIndex[client] = StringToInt(value);
			// PrintToChat(client, "You selected %i which was %N", SelectedIndex[client], SelectedIndex[client]);
			float PlayerOrigin[3];
			float TeleportOrigin[3];
			float PreTeleOrigin[3];
			GetClientAbsOrigin(SelectedIndex[client], PlayerOrigin);
			GetClientAbsOrigin(client, PreTeleOrigin);
			
			//Math
			TeleportOrigin[0] = PlayerOrigin[0];
			TeleportOrigin[1] = PlayerOrigin[1];
			TeleportOrigin[2] = (PlayerOrigin[2] + 30.0);
			
			//Teleport
			if (IsPlayerAlive(SelectedIndex[client]))
			{
				int attach = CreateEntityByName("trigger_push");
				TeleportEntity(attach, PreTeleOrigin, NULL_VECTOR, NULL_VECTOR);
				TE_Particle("drg_wrenchmotron_teleport", PreTeleOrigin, _, _, attach, 1,0);
				int attach2 = CreateEntityByName("trigger_push");
				TeleportEntity(attach2, PlayerOrigin, NULL_VECTOR, NULL_VECTOR);
				TE_Particle("drg_wrenchmotron_teleport", PlayerOrigin, _, _, attach2, 1,0);

				// FakeClientCommand(client, "eureka_teleport");
				TF2_AddCondition(client, TFCond_TeleportedGlow, 5.0);
				EmitSoundToAll(TELEPORTER_SPAWN, client);
				EmitSoundToAll(TELEPORTER_SPAWN, client);

					DataPack info = new DataPack();
				info.Reset();
				info.WriteCell(client);
				info.WriteCell(TeleportOrigin[0]);
				info.WriteCell(TeleportOrigin[1]);
				info.WriteCell(TeleportOrigin[2]);
				CreateTimer(0.5, Teleport_Player, info);

				g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
				isready = false;
				// EmitSoundToAll(TELEPORTER_SPAWN, client);
			} 

		}
	}
	return 0;
}



public Action Teleport_Player(Handle timer, DataPack info)
{
	info.Reset();
	int client = info.ReadCell();
	float TeleportOrigin[3];
	TeleportOrigin[0] = info.ReadCell();
	TeleportOrigin[1] = info.ReadCell();
	TeleportOrigin[2] = info.ReadCell();
	delete info;

	TeleportEntity(client, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
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
