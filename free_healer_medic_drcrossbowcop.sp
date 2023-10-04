#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Dr. Crossbow Cop"
#define ROBOT_ROLE "Healer"
#define ROBOT_CLASS "Medic"
#define ROBOT_SUBCLASS "Healer"
#define ROBOT_DESCRIPTION "Strength Buff Crossbow"
#define ROBOT_TIPS "Strong Heal Bolts\nActivate Strength Bolts with M2\nProvide special buffs to other Cop bots"
#define ROBOT_ON_DEATH "This robot is weak up close"
#define GMEDIC             "models/bots/medic/bot_medic.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_demoman/giant_demoman_loop.wav"
 
public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Dr. Crossbow Cop",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Medic from MvM",
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
	robot.subclass = ROBOT_SUBCLASS;
	robot.shortDescription = ROBOT_DESCRIPTION;
	robot.sounds.spawn = SPAWN;
	robot.sounds.loop = LOOP;
	robot.sounds.death = DEATH;
	robot.deathtip = ROBOT_ON_DEATH;
	robot.difficulty = ROBOT_DIFFICULTY_HARD;
	AddRobot(robot, MakeGiantMedic, PLUGIN_VERSION);

	HookEvent("crossbow_heal", Event_Crossbow_Heal, EventHookMode_Post);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantMedic_MakeGiantMedic", Native_SetGiantMedic);
//	CreateNative("BeGiantMedic_IsGiantMedic", Native_IsGiantMedic);
	return APLRes_Success;
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

MakeGiantMedic(client)
{
	TF2_SetPlayerClass(client, TFClass_Medic);
	TF2_RegeneratePlayer(client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GMEDIC);
   
	int iHealth = 1500;
   
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.9);
	TF2Attrib_SetByName(client, "damage force reduction", 0.8);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.75);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "health regen", 20.0);
	TF2Attrib_SetByName(client, "head scale", 0.8);
	TF2Attrib_SetByName(client, "maxammo primary increased", 2.5);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "move speed penalty", 0.8);
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client , ROBOT_TIPS);

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
			GiveGiantMedic(client);
}

#define MACHOMANN 30085
#define THELAW 30362
#define LICENSETOMAIM 296


bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_Recharge[MAXPLAYERS + 1] = {0.0, ...};
int g_Heal_Bolts_Hits_Needed = 12;
int g_healcount = 0;
float g_duration = 8.0;

stock GiveGiantMedic(client)
{
	if (IsValidClient(client))
	{
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
	
		RoboRemoveAllWearables(client);
		
		CreateRoboWeapon(client, "tf_weapon_crossbow", 305, 6, 1, 0, 0);
		// CreateRoboWeapon(client, "tf_weapon_bonesaw", 305, 6, 1, 2, 0);
		
		CreateRoboHat(client, MACHOMANN, 10, 6, 0.0, 1.0 , -1.0); //Macho mann
		CreateRoboHat(client, THELAW, 10, 6, 0.0, 1.0 , -1.0); //the law
		CreateRoboHat(client, LICENSETOMAIM, 10, 6, 0.0, 1.0 , -1.0);//License to maim
		
		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		g_healcount = 0;
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "fire rate penalty", 2.5);
			TF2Attrib_SetByName(Weapon1, "clip size bonus", 2.0);
			TF2Attrib_SetByName(Weapon1, "hidden primary max ammo bonus", 2.0);
			TF2Attrib_SetByName(Weapon1, "dmg bonus vs buildings", 0.5);
			TF2CustAttr_SetString(Weapon1, "reload full clip at once", "1.0");
		}

				
		
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{

		if( GetEntProp(client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE|IN_ATTACK2) ) 
		{
            g_button_held[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE|IN_ATTACK2) ) 
		{
			g_button_held[client] = false;
            
		}
		DrawHUD(client);
		
	}
	return Plugin_Continue;
}

bool isready;
#define CHAR_FULL "■"
#define CHAR_EMPTY "□"
void DrawHUD(int client)
{
	char sHUDText[128];
	char sProgress[32];
	// int iPercents = RoundToCeil((GetEngineTime() / g_Recharge[client])  * 100.0);
	int iCountDown = g_Heal_Bolts_Hits_Needed - g_healcount;

	int iCountDownActive = RoundToCeil(g_Recharge[client] - (GetEngineTime()));

	int iPercents = RoundToCeil(iCountDownActive / g_duration  * 100.0);
	for (int j = 1; j <= 10; j++)
	{
	if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
	else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}

	if (TF2_IsPlayerInCondition(client, TFCond_CritHype))
	{
	Format(sHUDText, sizeof(sHUDText), "Strength Bolts Active!\n               %s", sProgress);
	SetHudTextParams(1.0, 0.8, 0.5, 255, 69, 0, 255);
	}
	else if(iCountDown <= 0)
	{


	Format(sHUDText, sizeof(sHUDText), "Strength Bolts Ready!");
	SetHudTextParams(1.0, 0.8, 0.5, 0, 255, 0, 255);

	}else
	{
	Format(sHUDText, sizeof(sHUDText), "Strength Bolts: %i", iCountDown);
	SetHudTextParams(1.0, 0.8, 0.5, 255, 255, 255, 255);


	}

	ShowHudText(client, -2, sHUDText);

	if (!isready && iCountDown <= 0)
	{
	TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
	// PrintToChatAll("Ready!");
	isready = true;	
	}

	if (g_button_held[client] && iCountDown <= 0 || IsFakeClient(client))
	{
	isready = false;

	TF2_AddCondition(client, TFCond_CritHype, g_duration);
	TF2_AddCondition(client, TFCond_RuneStrength, g_duration);
	g_healcount = 0;
	g_Recharge[client] = GetEngineTime() + g_duration;
	}
}


public bool IsKritzed(int client){
	if (TF2_IsPlayerInCondition(client, (TFCond_Kritzkrieged)) || TF2_IsPlayerInCondition(client, (TFCond_Buffed)) || TF2_IsPlayerInCondition(client, (TFCond_CritCanteen)))
	{
		return true;
	}else
	{
		return false;
	}
}    

public Action Event_Crossbow_Heal(Event event, const char[] name, bool dontBroadcast)
{
	int healer = GetClientOfUserId(GetEventInt(event, "healer"));
	int target = GetClientOfUserId(GetEventInt(event, "target"));

	if (IsRobot(healer, ROBOT_NAME))
	{

	if(!TF2_IsPlayerInCondition(healer, TFCond_CritHype))g_healcount++;


	//PrintToChatAll("%N Healed %N, healcount was %i ", healer, target, g_healcount);

	if (TF2_IsPlayerInCondition(healer, TFCond_CritHype))
	{
	float reduced_duration = (g_duration / 2.0) + 1.0;



	if (IsRobot(target, "Pancop"))
	{
	TF2_AddCondition(target, TFCond_RuneHaste, reduced_duration);
	}else if (IsRobot(target, "Riotcop"))
	{
	TF2_AddCondition(target, TFCond_RuneHaste, reduced_duration);
	}else
	{
	TF2_AddCondition(target, TFCond_RuneStrength, reduced_duration);
	}




	if (IsKritzed(healer))
	{
	TF2_AddCondition(target, TFCond_CritCanteen, reduced_duration);
	}
	}

	}
	return Plugin_Continue;
}


