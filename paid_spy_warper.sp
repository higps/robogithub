#pragma semicolon 1
#include <sourcemod>
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
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Warper"
#define ROBOT_ROLE "Spy"
#define ROBOT_CLASS "Spy"
#define ROBOT_SUBCLASS "Spy"
#define ROBOT_DESCRIPTION "Warp to last target hit"
#define ROBOT_COST 1.0
#define ROBOT_TIPS "Infinite cloak\nStore the location of a stabbed enemy to warp there later\nWarp with Special Attack key"
#define ROBOT_ON_DEATH "Keep track of the location of Warper's last kill to ambush him after he warps\nPyros & liquids counter spies"

#define MODEL             "models/bots/spy/bot_spy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"
#define SHRINK    "sound/ui/gmm_rank_up.wav"
#define SIZE_RESTORED    "sound/ui/gmm_rank_up.wav/mm_rank_up_achieved.wav"

#define SPY_SPAWN_SOUND1		"vo/mvm_spy_spawn01.mp3"
#define SPY_SPAWN_SOUND2		"vo/mvm_spy_spawn02.mp3"
#define SPY_SPAWN_SOUND3		"vo/mvm_spy_spawn03.mp3"
#define SPY_SPAWN_SOUND4		"vo/mvm_spy_spawn04.mp3"

#define TELEPORTER_SPAWN		"weapons/teleporter_ready.wav"

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"

bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
float g_RechargeCooldown = 10.0;
float g_skill;
int g_target = -1;
float g_target_coords[3] = {0.0, ...};
float g_scale = 1.75;
// #define SPY_DEATH_SOUND1		"vo/mvm_spybot_death01.mp3"
// #define SPY_DEATH_SOUND2		"vo/mvm_spybot_death02.mp3"
// #define SPY_DEATH_SOUND3		"vo/mvm_spybot_death03.mp3"
// #define SPY_DEATH_SOUND4		"vo/mvm_spybot_death04.mp3"
// #define SPY_DEATH_SOUND5		"vo/mvm_spybot_death05.mp3"
// #define SPY_DEATH_SOUND6		"vo/mvm_spybot_death06.mp3"
// #define SPY_DEATH_SOUND7		"vo/mvm_spybot_death07.mp3"


public Plugin:myinfo =
{
	name = "[TF2] Be Big Robot Spy",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Spy",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

//bool g_bisGSPY[MAXPLAYERS + 1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RobotDefinition robot;
	robot.name = ROBOT_NAME;
	robot.role = ROBOT_ROLE;
	robot.class = ROBOT_CLASS;
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.footstep = ROBOT_FOOTSTEP_NORMAL;
	RestrictionsDefinition restrictions = new RestrictionsDefinition();
	restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
	restrictions.RobotCoins.PerRobot = ROBOT_COST;

	// restrictions.TeamCoins = new RobotCoinRestrictionDefinition();
	// restrictions.TeamCoins.Overall = 2;


	AddRobot(robot, MakeSpy, PLUGIN_VERSION, restrictions);

	// PrecacheModel(MODEL);




	// PrecacheSound(SPY_SPAWN_SOUND1, true);
	// PrecacheSound(SPY_SPAWN_SOUND2, true);
	// PrecacheSound(SPY_SPAWN_SOUND3, true);
	// PrecacheSound(SPY_SPAWN_SOUND4, true);
	// PrecacheSound(SPY_DEATH_SOUND1, true);
	// PrecacheSound(SPY_DEATH_SOUND2, true);
	// PrecacheSound(SPY_DEATH_SOUND3, true);
	// PrecacheSound(SPY_DEATH_SOUND4, true);
	// PrecacheSound(SPY_DEATH_SOUND5, true);

	
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeSuperHeavyweightChamp_MakeSpy", Native_SetSuperHeavyweightChamp);
	//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
	return APLRes_Success;
}

public OnMapStart()
{
	// PrecacheModel(MODEL);
	PrecacheSound(SHRINK, true);
	PrecacheSound(SIZE_RESTORED, true);
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

MakeSpy(client)
{
	TF2_SetPlayerClass(client, TFClass_Spy);
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
	SetModel(client, MODEL);


	int iHealth = 2000;
	int MaxHealth = 125;
	int iAdditiveHP = iHealth - MaxHealth;

	TF2_SetHealth(client, iHealth);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	//TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	//TF2Attrib_SetByName(client, "damage force reduction", 0.3);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);

	
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);

	// TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
	
	TF2Attrib_SetByName(client, "major increased jump height", 1.25);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	
	
	UpdatePlayerHitbox(client, g_scale);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	
	// PrintToChat(client, "1. You are now Giant Mr Paladin robot!");
	PrintHintText(client, ROBOT_TIPS);

	// if (IsPlayerAlive(client)){
	// EmitGameSoundToAll("Announcer.MVM_Spy_Alert");
	// } 

	g_target = -1;

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

// public Action:Timer_Resize(Handle:timer, any:hat)
// {
	// if (IsValidClient(client))
	// GiveBigRoboDane(client);
// }

#define RoBro 733
#define Gawkers 31279
#define TacticalTurtleneck 31278
// #define Spek 343
// #define WhitePaint 15132390.0



stock GiveBigRoboDane(client)
{
	if (IsValidClient(client))
	{

		
	RoboRemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, 0); //Revolver
	TF2_RemoveWeaponSlot(client, 2); // Gun
	TF2_RemoveWeaponSlot(client, 4);// inviswatch

	
	CreateRoboWeapon(client, "tf_weapon_revolver", 525, 6, 1, 0, 0); //Diamondback
	CreateRoboWeapon(client, "tf_weapon_knife", 194, 6, 1, 2, 241); //kunai
	CreateRoboWeapon(client, "tf_weapon_invis", 30, 6, 1, 4, 0); 
	CreateRoboWeapon(client, "tf_weapon_sapper", 735, 6, 1, 1, 0);//snack attack

	CreateRoboHat(client, RoBro, 10, 6, 15132390.0, 1.0, -1.0); 
	CreateRoboHat(client, Gawkers, 10, 6, 15132390.0, 1.0, -1.0); 
	CreateRoboHat(client, TacticalTurtleneck, 10, 6, 15132390.0, 1.0, -1.0); 
	// CreateRoboHat(client, LadyKiller, 10, 6, 0.0, 1.0, -1.0);
	// CreateRoboHat(client, Spek, 10, 6, 0.0, 1.0, -1.0);
	
		
	int Revolver = GetPlayerWeaponSlot(client, 0); //Revolver
	int Knife = GetPlayerWeaponSlot(client, 2); //Knife
	int Cloak = GetPlayerWeaponSlot(client, 4); //Invis watch
	int Sapper = GetPlayerWeaponSlot(client, 1); //Sapper

	if(IsValidEntity(Revolver)) //Revovler
		{
			TF2Attrib_RemoveAll(Revolver);
			
			// TF2Attrib_SetByName(Revolver, "fire rate bonus", 2.5);
			// TF2Attrib_SetByName(Revolver, "damage bonus", 2.0);
			TF2Attrib_SetByName(Revolver, "killstreak tier", 1.0);
						
		}

	if(IsValidEntity(Knife)) //
		{
			// TF2Attrib_RemoveAll(Knife);
			
			//TF2Attrib_SetByName(Knife, "fire rate bonus", 0.8);
			TF2Attrib_SetByName(Knife, "damage bonus", 1.25);
			TF2Attrib_SetByName(Knife, "killstreak tier", 1.0);
			// TF2Attrib_SetByName(Knife, "mod_disguise_consumes_cloak", 0.0);
			// TF2Attrib_SetByName(Knife, "sanguisuge", 0.0);
			// TF2Attrib_SetByName(Knife, "restore health on kill", 10.0);
						
		}
	if(IsValidEntity(Cloak)) //
		{
			TF2Attrib_RemoveAll(Cloak);
			// TF2Attrib_SetByName(Cloak, "mod weapon blocks healing", 1.0);
			TF2Attrib_SetByName(Cloak, "mult cloak meter consume rate", -100.0);
			TF2Attrib_SetByName(Cloak, "mult decloak rate", 0.3);
		}
	if(IsValidEntity(Sapper)) //
		{
			//TF2Attrib_RemoveAll(Sapper);
			
		//	TF2Attrib_SetByName(Sapper, "mult cloak meter consume rate", 0.0);
			TF2Attrib_SetByName(Sapper, "sapper damage leaches health", 25.0);
			TF2Attrib_SetByName(Sapper, "robo sapper", 100.0);
			// TF2Attrib_SetByName(Sapper, "mod weapon blocks healing", 1.0);
			//TF2Attrib_SetByName(Sapper, "min_viewmodel_offset", 5 -2 -4);
		}	
	// }
	TF2_AddCondition(client, TFCond_Cloaked);
	}
}

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
	
	Format(sHUDText, sizeof(sHUDText), "Warp: %i", iCountDown);
	

	if(iCountDown <= 0 && g_target == -1)
	{

		Format(sHUDText, sizeof(sHUDText), "Warp Ready!\nNeeds Target!");
			
		SetHudTextParams(1.0, 0.8, 0.5, 255, 0, 0, 255);
		

		
	}else if(iCountDown <= 0 && g_target != -1)
	{
		Format(sHUDText, sizeof(sHUDText), "Warp Ready!");
			
		SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);
	}else
	{
		SetHudTextParams(1.0, 0.8, 0.5, 255, 0, 0, 255);
	}

		 ShowHudText(client, -2, sHUDText);


		if (!isready && iCountDown <= 0)
		{
			TF2_AddCondition(client, TFCond_InHealRadius, 0.5);

			isready = true;	
		}

	if (g_button_held[client] && iCountDown <= 0 && g_target != -1)
	{
		RequestFrame(Teleport, client);
		
		
	}
}

void Teleport (int client)
{
	if(IsPlayerAlive(client) && !TF2Spawn_IsClientInSpawn(client))
	{


			// PrintToChat(client, "You selected %i which was %N", SelectedIndex[client], SelectedIndex[client]);

			float PreTeleOrigin[3];
			GetClientAbsOrigin(client, PreTeleOrigin);
			
			
			//Teleport
				int attach = CreateEntityByName("trigger_push");
				TeleportEntity(attach, PreTeleOrigin, NULL_VECTOR, NULL_VECTOR);
				TE_Particle("drg_wrenchmotron_teleport", PreTeleOrigin, _, _, attach, 1,0);
				int attach2 = CreateEntityByName("trigger_push");
				TeleportEntity(attach2, g_target_coords, NULL_VECTOR, NULL_VECTOR);
				TE_Particle("drg_wrenchmotron_teleport", g_target_coords, _, _, attach2, 1,0);

				// FakeClientCommand(client, "eureka_teleport");
				TF2_AddCondition(client, TFCond_TeleportedGlow, 5.0);
				EmitSoundToAll(TELEPORTER_SPAWN, client);
				EmitSoundToAll(TELEPORTER_SPAWN, client);


				CreateTimer(0.5, Teleport_Player, client);

				g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
				isready = false;
				g_target = -1;
			

		// TeleportEntity(client, g_target_coords, NULL_VECTOR, NULL_VECTOR);
		// g_Recharge[client] = GetEngineTime() + g_RechargeCooldown;
		// isready= false;
		
	}
}

public Action Teleport_Player(Handle timer, int client)
{
	if(IsRobot(client, ROBOT_NAME) && IsPlayerAlive(client))TeleportEntity(client, g_target_coords, NULL_VECTOR, NULL_VECTOR);
}



void GetCoordinates (int victim)
{
	GetClientAbsOrigin(victim, g_target_coords);
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
		g_target = victim;
		RequestFrame(GetCoordinates, victim);	
		
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
