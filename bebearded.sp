#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot>
 
#define PLUGIN_VERSION "1.0"
 
#define SHWC             "models/bots/heavy_boss/bot_heavy_boss.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"
#define SOUND_LEAP "TFPlayer.AirBlastImpact"
#define sBoomNoise "weapons/explode3.wav"
#define ALARM "mvm/mvm_cpoint_klaxon.wav"
#define JUMP "items/powerup_pickup_king.wav"
public Plugin:myinfo =
{
	name = "[TF2] Be the Juggernaut Bearded Expense",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Unused Juggernaut Bearded Expense Champ from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

new Handle:g_hEquipWearable;
new bool:g_bIsBearded[MAXPLAYERS + 1];
 
 bool g_IsBearded[MAXPLAYERS + 1] = false;
 
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("beshwc_version", PLUGIN_VERSION, "[TF2] Be the giant Bearded expense robot", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
   
	RegAdminCmd("sm_bebearded", Command_SuperHeavyweightChamp, ADMFLAG_ROOT, "It's a good time to run");
	AddNormalSoundHook(SuperHeavyweightChampSH);
   
	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	HookEvent("player_spawn", Event_Player_Spawned, EventHookMode_Post);
	
	
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamdata

	if (!hTF2)
	SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	if (!g_hEquipWearable)
	SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2; 

	AddRobot("Bearded Expense", "Heavy", CreateBearded);
}

public void OnPluginEnd()
{
	RemoveRobot("Bearded Expense");
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeSuperHeavyweightChamp_MakeBearded", Native_SetSuperHeavyweightChamp);
//	CreateNative("BeSuperHeavyweightChamp_IsSuperHeavyweightChamp", Native_IsSuperHeavyweightChamp);
	return APLRes_Success;
}



public Event_Player_Spawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_IsBearded[client]) CreateTimer(1.0, Timer_Locker, client);
}

public OnClientPutInServer(client)
{
    OnClientDisconnect_Post(client);
}
 
public OnClientDisconnect_Post(client)
{
	if (g_bIsBearded[client])
	{
		StopSound(client, SNDCHAN_AUTO, LOOP);
		g_bIsBearded[client] = false;
		g_IsBearded[client] = false;
	}
}
 
public OnMapStart()
{
	PrecacheModel(SHWC);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	PrecacheSound("^mvm/giant_common/giant_common_step_01.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_02.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_03.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_04.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_05.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_06.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_07.wav");
	PrecacheSound("^mvm/giant_common/giant_common_step_08.wav");
	PrecacheSound(sBoomNoise);
	PrecacheSound(ALARM);
	PrecacheSound(JUMP);
	PrecacheSound(SOUND_LEAP);
}
 
public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsBearded[client])
	{
		RemoveModel(client);
	   
		StopSound(client, SNDCHAN_AUTO, LOOP);
	   
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		TF2Attrib_RemoveAll(client);
			   
		g_bIsBearded[client] = false;
	}
}
 
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsBearded[client])
		{
			StopSound(client, SNDCHAN_AUTO, LOOP);
		   
			TF2Attrib_RemoveAll(client);
			EmitSoundToAll(DEATH);
		}
	}
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int weaponID = GetEventInt(event, "weapon_def_index");

	char weapon_logname[MAX_NAME_LENGTH];
	GetEventString(event, "weapon_logclassname", weapon_logname, sizeof(weapon_logname));

	
	
	//int weaponID = GetEntPropEnt(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	PrintToChatAll("Attacker %N , weaponID %i, logname: %s", attacker, weaponID, weapon_logname);

	if (g_IsBearded[attacker] && StrEqual(weapon_logname,"mantreads"))
	{
		//PrintToChatAll("Drop the bomb");
		
			Handle infokv = CreateKeyValues("infokv");
				KvSetNum(infokv, "attacker", attacker);
				KvSetNum(infokv, "victim", victim);
				CreateTimer(0.0, BeardedBoom, infokv);

		SDKHooks_TakeDamage(attacker, 0, attacker, 120.0, 0, -1);

	}

	if (g_IsBearded[attacker] && weaponID == 43)
	{
		//PrintToChatAll("Drop the bomb");
		
		TF2_AddCondition(attacker, TFCond_Slowed, 10.0);
	}
	
	

}

public Action BeardedBoom(Handle timer, any data)
{
	Handle infokv = data;
	int attacker = KvGetNum(infokv, "attacker");
	int victim = KvGetNum(infokv, "victim");
	float pos1[3];
	float pos22[3];
	GetClientAbsOrigin(attacker, pos1); // hack: make the explosion actually come from the attacker, that way we only have to hook one client
	GetClientAbsOrigin(victim, pos22);

	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", "mvm_tank_destroy");
	AcceptEntityInput(particle, "Start");
	TeleportEntity(particle, pos22, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	float pos2[3];
//	float ignitetime = GetConVarFloat(FindConVar("sharpened_volcano_fragment_firetime"));
	
	for(int client = 1 ; client <= MaxClients ; client++ )
	{
		if(IsClientInGame(client))
		{
			GetClientAbsOrigin(client, pos2);
			if(GetVectorDistance(pos1, pos2) <= 250.0 && TF2_GetClientTeam(attacker) != TF2_GetClientTeam(client))
			{
				SDKHooks_TakeDamage(client, 0, attacker, 1500.0, 0, -1);
				
				// ClientCommand(client, "playgamesound weapons/explode1.wav");
				//ClientCommand(client, "playgamesound %s", sound);
				EmitAmbientSound(sBoomNoise, pos22, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
				
				//return Plugin_Changed;

			}
		}
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
 
public Action:RemoveModel(client)
{
	if (IsValidClient(client))
	{
	   
		TF2Attrib_RemoveAll(client);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:false);
		UpdatePlayerHitbox(client, 1.0);

		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
}

public Action:Command_SuperHeavyweightChamp(client, args)
{
	decl String:arg1[32];
	if (args < 1)
	{
		arg1[0] = '\0';
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	
	CreateBearded(client, arg1);
	return Plugin_Handled;
}

public void CreateBearded(int client, char target[32])
{
	int targetFilter = 0;
	if (target[0] == '\0')
	{
		target = "@me";
		targetFilter = COMMAND_FILTER_NO_IMMUNITY;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
					target,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|targetFilter,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
			ReplyToTargetError(client, target_count);
			return;
	}
	for (new i = 0; i < target_count; i++)
	{	
		if(!g_IsBearded[target_list[i]]){		
			g_IsBearded[target_list[i]] = true;
			MakeBearded(target_list[i]);
			
		}else
		{
			g_IsBearded[target_list[i]] = false;
			PrintToChat(target_list[i], "1. You are no longer Giant Bearded Expense!");
			PrintToChat(target_list[i], "2. You will turn back by changing class or dying!");
			TF2_RegeneratePlayer(target_list[i]);
		}
		
		
	}
	if (g_IsBearded[client])EmitSoundToAll(SPAWN);
}
 
MakeBearded(client)
{
	TF2_SetPlayerClass(client, TFClass_Heavy);
	TF2_RegeneratePlayer(client);
	EmitSoundToAll(LOOP, client);

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
	SetModel(client, SHWC);
   
		
   int iHealth = 6500;
	TF2_SetHealth(client, iHealth);
	
	int MaxHealth = 300;
	int iAdditiveHP = iHealth - MaxHealth;
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	TF2Attrib_SetByName(client, "move speed penalty", 0.7);
	TF2Attrib_SetByName(client, "damage force reduction", 0.1);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	//TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 0.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.0);
	TF2Attrib_SetByName(client, "mult_patient_overheal_penalty_active", 0.0);
	TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
	TF2Attrib_SetByName(client, "health from healers increased", 5.0);
	TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.3);
	//TF2Attrib_SetByName(client, "mult charge turn control", 10.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 1.5);
	TF2Attrib_SetByName(client, "boots falling stomp", 1.0);
	
	


	UpdatePlayerHitbox(client, 1.75);
	
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	

	g_bIsBearded[client] = true;
	
	g_IsBearded[client] = true;
		PrintToChat(client, "1. You are now Giant Bearded Expense bot !");
		PrintToChat(client, "2. You are a juggernaut!");
		
}
 
stock UpdatePlayerHitbox(const client, const Float:fScale)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
   
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
   
	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);
   
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}
 
stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
			GiveBearded(client);
}

public Action:Timer_Locker(Handle:timer, any:client)
{
	if (IsValidClient(client))
	StopSound(client, SNDCHAN_AUTO, LOOP);
		MakeBearded(client);
}
 
stock GiveBearded(client)
{
	if (IsValidClient(client))
	{
		g_bIsBearded[client] = true;
		
		TF2_RemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		CreateWeapon(client, "tf_weapon_fists", 43, 6, 1, 2, 0);

	//	CreateWeapon(client, "tf_weapon_lunchbox", 863, 6, 1, 1, 0);
	//	CreateWeapon(client, "tf_weapon_rocketpack", 1179, 6, 1, 1, 0);

		CreateHat(client, 145, 10, 6, 1315860.0, true);
	//	CreateHat(client, 30178, 10, 6, 1315860);
		CreateHat(client, 30645, 10, 6, 1315860.0, true);
		CreateHat(client, 30342, 10, 6, 0.0, false);
		
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

//		int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
				
			TF2Attrib_SetByName(Weapon3, "fire rate bonus", 1.2);
			TF2Attrib_SetByName(Weapon3, "damage bonus", 1.5);
			TF2Attrib_SetByName(Weapon3, "critboost on kill", 10.0);
			TF2Attrib_SetByName(Weapon3, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon3, "speed_boost_on_kill", 10.0);
			TF2Attrib_SetByName(Weapon3, "speed_boost_on_hit", 2.0);
			TF2Attrib_SetByName(Weapon3, "heal on kill", 800.0);
			TF2Attrib_SetByName(Weapon3, "melee range multiplier", 1.4);
			TF2Attrib_SetByName(Weapon3, "dmg pierces resists absorbs", 1.0);
			TF2Attrib_SetByName(Weapon3, "aiming movespeed increased", 2.0);
			TF2Attrib_SetByName(Weapon3, "gesture speed increase", 0.8);
			
			


				if (TF2_GetClientTeam(client) == TFTeam_Red)TF2Attrib_SetByName(Weapon3, "increase player capture value", -1.0);
				//Add additonal logic to detect if it's attack/defend mode

			//	if (TF2_GetClientTeam(client) == TFTeam_Blue)TF2Attrib_SetByName(Weapon3, "increase player capture value", 0.0);
	
			//TF2Attrib_SetByName(Weapon3, "crit forces victim to laugh", 1.0);
		}

/* 				if(IsValidEntity(Weapon2))
		{
			TF2Attrib_RemoveAll(Weapon2);
			TF2Attrib_SetByName(Weapon2, "lunchbox healing decreased", 10.0);
			TF2Attrib_SetByName(Weapon2, "item_meter_charge_rate", 50.0);
		} */
		
		
		
		
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (g_IsBearded[client] && condition == TFCond_Taunting)
    {
	
	int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");

	//PrintToChatAll("Taunt ID %i", tauntid);

	if (tauntid == -1)
	{
	 TF2_AddCondition(client,TFCond_DefenseBuffed, 20.0);
	 EmitSoundToAll(ALARM);

	 CreateTimer(1.1, Timer_Alarm, client, TIMER_REPEAT);
	// TF2_AddCondition(client, TFCond_GrapplingHookSafeFall, TFCondDuration_Infinite);
	   //TFCond_CritHype
	  // TF2_AddCondition(client,TFCond_HalloweenSpeedBoost, 15.0);
	  CreateTimer(3.35, Timer_Taunt_Cancel, client);
	}


	  
    }
}
public Action:Timer_Alarm(Handle:timer, any:client)
{
	static int cap = 0;

if(TF2_IsPlayerInCondition(client, TFCond_Taunting))EmitSoundToAll(ALARM);

	if (cap >= 1)
	{
		cap = 0;
		return Plugin_Stop;
	}
	cap++;
	return Plugin_Continue;
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){
		TF2_RemoveCondition(client, TFCond_Taunting);
	}
	

	
	float vOrigin[3], vAngles[3], vForward[3], vVelocity[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	// Get the direction we want to go
	GetAngleVectors(vAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	
	// make it usable
	float flDistance = 650.0;

	ScaleVector(vForward, flDistance);	
	
	// add it to the current velocity to avoid just being able to do full 180s
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
	AddVectors(vVelocity, vForward, vVelocity);
	
	float flDistanceVertical = 300.0;
	
		
	
	vVelocity[2] += flDistanceVertical; // we always want to go a bit up
	
	// And set it
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	EmitGameSoundToAll(SOUND_LEAP,client);
	EmitSoundToAll(JUMP,client);
}
 
public player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if (g_bIsBearded[client] && IsValidClient(client))
	{
		TF2_RemoveAllWearables(client);
		int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		TF2Attrib_RemoveByName(Weapon3, "fire rate bonus");
		TF2Attrib_RemoveByName(Weapon3, "damage bonus");
		TF2Attrib_RemoveByName(Weapon3, "critboost on kill");
		TF2Attrib_RemoveByName(Weapon3, "killstreak tier");
	}
}
 
public Action:SuperHeavyweightChampSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!g_bIsBearded[entity]) return Plugin_Continue;

	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
	if (!IsValidClient(entity)) return Plugin_Continue;
	new TFClassType:class = TF2_GetPlayerClass(entity);

	if (StrContains(sample, "vo/", false) == -1) return Plugin_Continue;
	if (StrContains(sample, "announcer", false) != -1) return Plugin_Continue;
	if (volume == 0.99997) return Plugin_Continue;
	ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/mght/", false);
	ReplaceString(sample, sizeof(sample), "_", "_m_", false);
	ReplaceString(sample, sizeof(sample), ".wav", ".mp3", false);
	new String:classname[10], String:classname_mvm[15];
	TF2_GetNameOfClass(class, classname, sizeof(classname));
	Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
	ReplaceString(sample, sizeof(sample), classname, classname_mvm, false);
	new String:soundchk[PLATFORM_MAX_PATH];
	Format(soundchk, sizeof(soundchk), "sound/%s", sample);
	PrecacheSound(sample);
	return Plugin_Changed;
}

stock TF2_GetNameOfClass(TFClassType:class, String:name[], maxlen)
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}
 /*
public Native_SetSuperHeavyweightChamp(Handle:plugin, args)
        MakeBearded(GetNativeCell(1));
 
public Native_IsSuperHeavyweightChamp(Handle:plugin, args)
        return g_bIsBearded[GetNativeCell(1)];*/
       
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

bool CreateHat(int client, int itemindex, int level, int quality, float paint, bool scale)
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
	
	if (paint != 0.0){
	
	TF2Attrib_SetByDefIndex(hat, 142, paint);
	TF2Attrib_SetByDefIndex(hat, 261, paint);
	}
	
	if (scale == true){
	SetEntData(hat, FindSendPropInfo(entclass, "m_flModelScale"), 0.75);
	}



	DispatchSpawn(hat);
	SDKCall(g_hEquipWearable, client, hat);
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
		SDKCall(g_hEquipWearable, client, weapon);
	}

	else
	{
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon);
	}
	
	if (quality !=9)
	{
		if (itemindex == 13
				|| itemindex == 200
				|| itemindex == 23
				|| itemindex == 209
				|| itemindex == 18
				|| itemindex == 205
				|| itemindex == 10
				|| itemindex == 199
				|| itemindex == 21
				|| itemindex == 208
				|| itemindex == 12
				|| itemindex == 19
				|| itemindex == 206
				|| itemindex == 20
				|| itemindex == 207
				|| itemindex == 15
				|| itemindex == 202
				|| itemindex == 11
				|| itemindex == 9
				|| itemindex == 22
				|| itemindex == 29
				|| itemindex == 211
				|| itemindex == 14
				|| itemindex == 201
				|| itemindex == 16
				|| itemindex == 203
				|| itemindex == 24
				|| itemindex == 210)	
		{
			if (GetRandomInt(1,2) < 3)
			{
				TF2_SwitchtoSlot(client, slot);
				int iRand = GetRandomInt(1,4);
				if (iRand == 1)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
				}
				else if (iRand == 2)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
				}	
				else if (iRand == 3)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
				}
				else if (iRand == 4)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
				}
			}
		}
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