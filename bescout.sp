#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Scout"

#define GSCOUT		"models/bots/scout_boss/bot_scout_boss.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/giant_scout/giant_scout_loop.wav"

#define LEFTFOOT        ")mvm/giant_scout/giant_scout_step_01.wav"
#define LEFTFOOT1       ")mvm/giant_scout/giant_scout_step_03.wav"
#define RIGHTFOOT       ")mvm/giant_scout/giant_scout_step_02.wav"
#define RIGHTFOOT1      ")mvm/giant_scout/giant_scout_step_04.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Giant <Someone> Scout",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Scout",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

new bool:g_bIsGSCOUT[MAXPLAYERS + 1];

public OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);

	LoadTranslations("common.phrases");

	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	AddNormalSoundHook(BossScout);

	RobotSounds sounds;
	sounds.spawn = SPAWN;
	sounds.loop = LOOP;
//	sounds.gunfire = SOUND_GUNFIRE;
//	sounds.windup = SOUND_WINDUP;
	sounds.death = DEATH;
	AddRobot(ROBOT_NAME, "Scout", MakeGiantscout, PLUGIN_VERSION, sounds);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGiantPyro_MakeGiantscout", Native_SetGiantPyro);
//	CreateNative("BeGiantPyro_IsGiantPyro", Native_IsGiantPyro);
	return APLRes_Success;
}

public OnClientPutInServer(client)
{
	OnClientDisconnect_Post(client);
}

public OnClientDisconnect_Post(client)
{
	if (g_bIsGSCOUT[client])
	{
		StopSound(client, SNDCHAN_AUTO, LOOP);
	//	StopSound(client, SNDCHAN_AUTO, SOUND_GUNFIRE);
//		StopSound(client, SNDCHAN_AUTO, SOUND_WINDUP);
		g_bIsGSCOUT[client] = false;
	}
}

public OnMapStart()
{
	PrecacheModel(GSCOUT);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	

	PrecacheSound("mvm/giant_scout/giant_scout_step_01.wav");
	PrecacheSound("mvm/giant_scout/giant_scout_step_03.wav");
	PrecacheSound("mvm/giant_scout/giant_scout_step_02.wav");
	PrecacheSound("mvm/giant_scout/giant_scout_step_04.wav");
	
	//PrecacheSound(SOUND_GUNFIRE);
	//PrecacheSound(SOUND_WINDUP);
	
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_bIsGSCOUT[client])
	{
		g_bIsGSCOUT[client] = false;
	}
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

public Action:BossScout(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
		if (!IsValidClient(entity)) return Plugin_Continue;
		if (!g_bIsGSCOUT[entity]) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_scout/giant_scout_step_01.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_scout/giant_scout_step_03.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_scout/giant_scout_step_02.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_scout/giant_scout_step_04.wav");
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;

	return Plugin_Continue;
}

MakeGiantscout(client)
{
	SMLogTag(SML_VERBOSE, "Createing ScoutName");
	TF2_SetPlayerClass(client, TFClass_Scout);
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
	SetModel(client, GSCOUT);
	
	int iHealth = 1500;
		
	int MaxHealth = 125;
	//PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	// PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "ammo regen", 100.0);
	TF2Attrib_SetByName(client, "move speed penalty", 1.5);
	TF2Attrib_SetByName(client, "damage force reduction", 2.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 2.0);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 1.0);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.0);
	TF2Attrib_SetByName(client, "mult_patient_overheal_penalty_active", 0.0);
	TF2Attrib_SetByName(client, "health from healers increased", 3.0);
	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	g_bIsGSCOUT[client] = true;
	
	PrintToChat(client, "1. You are now Icebear scout !");
	
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGiantPyro(client);
}

stock GiveGiantPyro(client)
{
	if (IsValidClient(client))
	{
		g_bIsGSCOUT[client] = true;
		
		TF2_RemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		CreateWeapon(client, "tf_weapon_scattergun", 13, 6, 1, 2, 0);
		
		CreateWeapon(client, "tf_weapon_bat", 0, 6, 1, 2, 0);
		
		
//		CreateHat(client, 183, 10, 6, true); //Sergeant's Drill Hat
//		CreateHat(client, 647, 10, 6, true); //The All-Father
//		CreateHat(client, 343, 10, 6, true);//Professor speks

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		if(IsValidEntity(Weapon1))
		{
			//TF2Attrib_RemoveAll(Weapon1);
			
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 1.25);
			TF2Attrib_SetByName(Weapon1, "maxammo primary increased", 2.5);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 1.2);
			TF2Attrib_SetByName(Weapon1, "bullets per shot bonus", 1.2);
			TF2Attrib_SetByName(Weapon1, "spread penalty", 1.8);
			TF2Attrib_SetByName(Weapon1, "Reload time decreased", 0.5);
			
		
\			
		}
		
		if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "dmg penalty vs players", 2.0);
			TF2Attrib_SetByName(Weapon2, "single wep deploy time decreased", 0.5);
			TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);	

		}
	}
}
 
public player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if (g_bIsGSCOUT[client] && IsValidClient(client))
	{
		TF2_RemoveAllWearables(client);
		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		
		TF2Attrib_RemoveByName(Weapon1, "maxammo primary increased");
		TF2Attrib_RemoveByName(Weapon1, "killstreak tier");
	}
}

/* public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
{
	if (IsValidClient(iClient) && g_bIsGSCOUT[iClient]) 
	{	
		new weapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
		if(IsValidEntity(weapon))
		{
			new iWeaponState = GetEntProp(weapon, Prop_Send, "m_iWeaponState");
			if (iWeaponState == 1 && !Locked1[iClient])
			{
				EmitSoundToAll(SOUND_WINDUP, iClient);
			//	PrintToChatAll("WeaponState = Windup");
				
				Locked1[iClient] = true;
				Locked2[iClient] = false;
				Locked3[iClient] = false;
				CanWindDown[iClient] = true;
				
				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
			}
			else if (iWeaponState == 2 && !Locked2[iClient])
			{
				EmitSoundToAll(SOUND_GUNFIRE, iClient);
			//	PrintToChatAll("WeaponState = Firing");
				
				Locked2[iClient] = true;
				Locked1[iClient] = true;
				Locked3[iClient] = false;
				CanWindDown[iClient] = true;
				
				StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
			}
			else if (iWeaponState == 3 && !Locked3[iClient])
			{

			//	PrintToChatAll("WeaponState = Spun Up");
				
				Locked3[iClient] = true;
				Locked1[iClient] = true;
				Locked2[iClient] = false;
				CanWindDown[iClient] = true;
				
				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
				StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
			}
			else if (iWeaponState == 0)
			{
				if (CanWindDown[iClient])
				{
			//		PrintToChatAll("WeaponState = WindDown");

					CanWindDown[iClient] = false;
				}
				
				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
				
				Locked1[iClient] = false;
				Locked2[iClient] = false;
				Locked3[iClient] = false;
			}
		}
	}
} */

public Native_SetGiantPyro(Handle:plugin, args)
	MakeGiantscout(GetNativeCell(1));

public Native_IsGiantPyro(Handle:plugin, args)
	return g_bIsGSCOUT[GetNativeCell(1)];
	
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

bool CreateHat(int client, int itemindex, int level, int quality, bool scale)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);  	
	
	TFTeam iTeam = view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_iTeamNum"));
		
//		CreateHat(client, 183, 10, 6, true); //Sergeant's Drill Hat
		//CreateHat(client, 647, 10, 6, true); //The All-Father
		//CreateHat(client, 343, 10, 6, false);//Professor Speks

	switch (itemindex)
	{
	case 183://Sergeant's Drill Hat
		{
/* 			if (iTeam == TFTeam_Blue){
				TF2Attrib_SetByDefIndex(hat, 142, 12807213.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12807213.0);
			}
			if (iTeam == TFTeam_Red){
				TF2Attrib_SetByDefIndex(hat, 142, 12091445.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12091445.0);
			} */
		}
	case 647://The All-Father
		{
/* 			
			if (iTeam == TFTeam_Blue){
				TF2Attrib_SetByDefIndex(hat, 142, 12807213.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12807213.0);
			}
			if (iTeam == TFTeam_Red){
				TF2Attrib_SetByDefIndex(hat, 142, 12091445.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12091445.0);
			} */
		}
	case 343://Professor Speks
	{
		TF2Attrib_SetByDefIndex(hat, 542, 1.0);//item style
	}
	


	}
	
	if (scale == true){
		SetEntData(hat, FindSendPropInfo(entclass, "m_flModelScale"), 0.75);
	}

	DispatchSpawn(hat);
	EquipWearable(client, hat);
	return true;
}

stock void RemoveAllWearables(int client)
{
	int edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}

stock Action RemoveWearable(int client, char[] classname, char[] networkclass)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		int edict = MaxClients+1;
		while((edict = FindEntityByClassname(edict, classname)) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, networkclass))
			{
				if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
				{
					AcceptEntityInput(edict, "Kill"); 
				}
			}
		}
	}
}

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, int paint)
{
	TF2_RemoveWeaponSlot(client, slot);
	
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1); 
	
	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomInt(1,99));
	}

	TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	
	switch (itemindex)
	{
	case 810, 736, 933, 1080, 1102:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3);
		}
	case 998:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(weapon, "item style override", 0.0);
			TF2Attrib_SetByName(weapon, "loot rarity", 1.0);		
			TF2Attrib_SetByName(weapon, "turn to gold", 1.0);

			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon);
			
			return true; 
		}		
	}

	if(quality == 9)
	{
		TF2Attrib_SetByName(weapon, "is australium item", 1.0);
		TF2Attrib_SetByName(weapon, "item style override", 1.0);
	}

	if(itemindex == 200 || itemindex == 220 || itemindex == 448 || itemindex == 15002 || itemindex == 15015 || itemindex == 15021 || itemindex == 15029 || itemindex == 15036 || itemindex == 15053 || itemindex == 15065 || itemindex == 15069 || itemindex == 15106 || itemindex == 15107 || itemindex == 15108 || itemindex == 15131 || itemindex == 15151 || itemindex == 15157 || itemindex == 449 || itemindex == 15013 || itemindex == 15018 || itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101
			|| itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 44 || itemindex == 221 || itemindex == 205 || itemindex == 228 || itemindex == 1104 || itemindex == 15006 || itemindex == 15014 || itemindex == 15028 || itemindex == 15043 || itemindex == 15052 || itemindex == 15057 || itemindex == 15081 || itemindex == 15104 || itemindex == 15105 || itemindex == 15129 || itemindex == 15130 || itemindex == 15150 || itemindex == 196 || itemindex == 447 || itemindex == 208 || itemindex == 215 || itemindex == 1178 || itemindex == 15005 || itemindex == 15017 || itemindex == 15030 || itemindex == 15034
			|| itemindex == 15049 || itemindex == 15054 || itemindex == 15066 || itemindex == 15067 || itemindex == 15068 || itemindex == 15089 || itemindex == 15090 || itemindex == 15115 || itemindex == 15141 || itemindex == 351 || itemindex == 740 || itemindex == 192 || itemindex == 214 || itemindex == 326 || itemindex == 206 || itemindex == 308 || itemindex == 996 || itemindex == 1151 || itemindex == 15077 || itemindex == 15079 || itemindex == 15091 || itemindex == 15092 || itemindex == 15116 || itemindex == 15117 || itemindex == 15142 || itemindex == 15158 || itemindex == 207 || itemindex == 130 || itemindex == 15009
			|| itemindex == 15012 || itemindex == 15024 || itemindex == 15038 || itemindex == 15045 || itemindex == 15048 || itemindex == 15082 || itemindex == 15083 || itemindex == 15084 || itemindex == 15113 || itemindex == 15137 || itemindex == 15138 || itemindex == 15155 || itemindex == 172 || itemindex == 327 || itemindex == 404 || itemindex == 202 || itemindex == 41 || itemindex == 312 || itemindex == 424 || itemindex == 15004 || itemindex == 15020 || itemindex == 15026 || itemindex == 15031 || itemindex == 15040 || itemindex == 15055 || itemindex == 15086 || itemindex == 15087 || itemindex == 15088 || itemindex == 15098
			|| itemindex == 15099 || itemindex == 15123 || itemindex == 15124 || itemindex == 15125 || itemindex == 15147 || itemindex == 425 || itemindex == 997 || itemindex == 197 || itemindex == 329 || itemindex == 15073 || itemindex == 15074 || itemindex == 15075 || itemindex == 15139 || itemindex == 15140 || itemindex == 15114 || itemindex == 15156 || itemindex == 305 || itemindex == 211 || itemindex == 15008 || itemindex == 15010 || itemindex == 15025 || itemindex == 15039 || itemindex == 15050 || itemindex == 15078 || itemindex == 15097 || itemindex == 15121 || itemindex == 15122 || itemindex == 15123 || itemindex == 15145
			|| itemindex == 15146 || itemindex == 35 || itemindex == 411 || itemindex == 37 || itemindex == 304 || itemindex == 201 || itemindex == 402 || itemindex == 15000 || itemindex == 15007 || itemindex == 15019 || itemindex == 15023 || itemindex == 15033 || itemindex == 15059 || itemindex == 15070 || itemindex == 15071 || itemindex == 15072 || itemindex == 15111 || itemindex == 15112 || itemindex == 15135 || itemindex == 15136 || itemindex == 15154 || itemindex == 203 || itemindex == 15001 || itemindex == 15022 || itemindex == 15032 || itemindex == 15037 || itemindex == 15058 || itemindex == 15076 || itemindex == 15110
			|| itemindex == 15134 || itemindex == 15153 || itemindex == 193 || itemindex == 401 || itemindex == 210 || itemindex == 15011 || itemindex == 15027 || itemindex == 15042 || itemindex == 15051 || itemindex == 15062 || itemindex == 15063 || itemindex == 15064 || itemindex == 15103 || itemindex == 15128 || itemindex == 15129 || itemindex == 15149 || itemindex == 194 || itemindex == 649 || itemindex == 15062 || itemindex == 15094 || itemindex == 15095 || itemindex == 15096 || itemindex == 15118 || itemindex == 15119 || itemindex == 15143 || itemindex == 15144 || itemindex == 209 || itemindex == 15013 || itemindex == 15018
			|| itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101 || itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 415 || itemindex == 15003 || itemindex == 15016 || itemindex == 15044 || itemindex == 15047 || itemindex == 15085 || itemindex == 15109 || itemindex == 15132 || itemindex == 15133 || itemindex == 15152 || itemindex == 1153)
	{
		if(GetRandomInt(1,15) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
		}
	}
	
	if(quality == 11)
	{
		if (GetRandomInt(1,10) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);
		}
		else if (GetRandomInt(1,10) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,10) == 3)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));
	}
	
	if (quality == 15)
	{
		switch(itemindex)
		{
		case 30666, 30667, 30668, 30665:
			{
				TF2Attrib_RemoveByDefIndex(weapon, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}

	if (itemindex == 405 || itemindex == 608 || itemindex == 1101 || itemindex == 133 || itemindex == 444 || itemindex == 57 || itemindex == 231 || itemindex == 642 || itemindex == 131 || itemindex == 406 || itemindex == 1099 || itemindex == 1144)
	{
		DispatchSpawn(weapon);
		EquipWearable(client, weapon);
	}
	else
	{
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon);
	}

	return true;
}

stock void TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char wepclassname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

stock void TF2_RemoveAllWearables(int client)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}