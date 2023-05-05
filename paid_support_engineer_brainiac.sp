#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <berobot_constants>
#include <berobot>
//#include <sendproxy>
#include <dhooks>
#include <sdktools>
//#include <collisionhook>
#include <tf_custom_attributes>
#include <menus>
#pragma semicolon 1
//#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Brainiac"
#define ROBOT_ROLE "Builder"
#define ROBOT_CLASS "Engineer"
#define ROBOT_SUBCLASS ""
#define ROBOT_DESCRIPTION "MatePorter ability, Upgrading Rescue Ranger, Eureka Effect"
#define ROBOT_TIPS "Use +use or special attack to open MatePort menu to teleport to teammates"
#define ROBOT_COST 2.0

#define ChangeDane             "models/bots/engineer/bot_engineer.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"

int SelectedIndex[MAXPLAYERS + 1];

#define TELEPORTER_SPAWN		"weapons/teleporter_ready.wav"

public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Uncle Dane",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Uncle Dane Bot from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = ROBOT_CLASS;
	// robot.subclass = ROBOT_SUBCLASS;
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;

	RestrictionsDefinition restrictions = new RestrictionsDefinition();
    restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
    restrictions.RobotCoins.PerRobot = ROBOT_COST;

    AddRobot(robot, MakeUncleDane, PLUGIN_VERSION, restrictions);

}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

public OnMapStart()
{
	PrecacheSound(TELEPORTER_SPAWN, true);
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");



		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		
		
	}
}

MakeUncleDane(client)
{
	
	TF2_SetPlayerClass(client, TFClass_Engineer);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 2)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 2);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, ChangeDane);

	int iHealth = 2000;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;
	float OverHealRate = 1.5;

	float OverHeal = float(MaxHealth) * OverHealRate;
	float TotalHealthOverHeal = iHealth * OverHealRate;
	float OverHealPenaltyRate = OverHeal / TotalHealthOverHeal;
	float scale = 1.65;
	
	TF2_SetHealth(client, iHealth);
	TF2Attrib_SetByName(client, "patient overheal penalty", OverHealPenaltyRate);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "move speed penalty", 0.75);
	TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "maxammo metal increased", 2.5);
	TF2Attrib_SetByName(client, "metal regen", 200.0);

	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	// TF2Attrib_SetByName(client, "building cost reduction", 2.5);
	TF2Attrib_SetByName(client, "mod teleporter cost", 9.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "head scale", 0.85);

	UpdatePlayerHitbox(client, scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	
	PrintHintText(client, ROBOT_TIPS);
	//PrintCenterText(client, "Use !stuck if you get stuck in buildings");
	
	SetEntProp(client, Prop_Send, "m_iAmmo", 500, _, 3);
	
}


stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
SetEntProp(client, Prop_Data, "m_iMaxHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveBigRoboDane(client);
}

#define Brainiac 591
#define FlashOfInspiration 30871
#define Underminer 31334

stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		CreateRoboWeapon(client, "tf_weapon_shotgun_building_rescue", 997, 6, 1, 2, 0);
		CreateRoboWeapon(client, "tf_weapon_wrench", 589, 6, 1, 2, 0);


		//CreateWeapon(client, "tf_weapon_wrench", 7, 9, 69, 2, 0);


		CreateRoboHat(client, Brainiac, 10, 6, 0.0, 1.5, 2.0);
		CreateRoboHat(client, FlashOfInspiration, 10, 6, 0.0, 1.25, -1.0);
		CreateRoboHat(client, Underminer, 10, 6, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_SetByName(Weapon1, "damage bonus", 1.75);
			TF2Attrib_SetByName(Weapon1, "faster reload rate", 0.25);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 0.75);
			
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);

			TF2Attrib_SetByName(Weapon1, "engineer building teleporting pickup", 10.0);
			TF2CustAttr_SetString(Weapon1, "projectile upgrades buildings", "5");
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.35);		
		}

		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.25);
			TF2Attrib_SetByName(Weapon3, "Construction rate increased", 10.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.65);
			TF2Attrib_SetByName(Weapon3, "Repair rate increased", 3.0);
			
			TF2Attrib_SetByName(Weapon3, "mod wrench builds minisentry", 0.0);
			TF2Attrib_SetByName(Weapon3, "engineer building teleporting pickup", 10.0);
			// TF2Attrib_SetByName(Weapon3, "engy building health bonus", 2.32);
			// TF2Attrib_SetByName(Weapon3, "engy sentry radius increased", 100.0);
			TF2Attrib_SetByName(Weapon3, "engy dispenser radius increased", 3.0);
			// TF2Attrib_SetByName(Weapon3, "engy building health bonus", 1.1);
			TF2CustAttr_SetString(Weapon3, "mod building health", "teleporter=500");
			
			
			TF2Attrib_SetByName(Weapon3, "upgrade rate decrease", 4.0);

			TF2CustAttr_SetString(Weapon3, "owned building phasing", "sentry=1 dispenser=1");
			TF2CustAttr_SetString(Weapon3, "robot engineer", "sentry_scale=1.15 dispenser_scale=1.15 infinite_ammo=0 sentries=1 dispensers=2 remove_all_sappers=1 yeet=0");
			
		}
		
	}
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