#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Gotham Protector"
#define ROBOT_ROLE "Tank"
#define ROBOT_DESCRIPTION "Punish Criminals"
 
#define GDEFLECTORH      "models/bots/heavy/bot_heavy.mdl"
#define SPAWN   "#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH   "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP    "mvm/giant_heavy/giant_heavy_loop.wav"


#define LEFTFOOT        ")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1       ")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT       ")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1      ")mvm/giant_heavy/giant_heavy_step04.wav"

enum eRuneTypes
{
    Rune_Invalid = -1,
    Rune_Strength,
    Rune_Haste,
    Rune_Regen,
    Rune_Resist,
    Rune_Vampire,
    Rune_Reflect,
    Rune_Precision,
    Rune_Agility,
    Rune_Plague,
    Rune_King,
    Rune_Knockout,
    Rune_Supernova,

    Rune_LENGTH
}

#define RuneTypes                     eRuneTypes
#define RuneTypes_t                 eRuneTypes     // Cuz

#define BLINK_TIME                     10.0

#define RUNE_REPOSITION_TIME         60.0
// In freeforall mode, killed players drop enemy team colored powerups. These powerups reposition quicker
#define RUNE_REPOSITION_TIME_ANY    30.0

#define TF_RUNE_TEMP_RESPAWN_DELAY     90.0
#define TF_RUNE_TEMP_UBER_RESPAWN_DELAY     180.0

#define TF_RUNE_STRENGTH        "models/pickups/pickup_powerup_strength.mdl"
#define TF_RUNE_RESIST            "models/pickups/pickup_powerup_defense.mdl"
#define TF_RUNE_REGEN            "models/pickups/pickup_powerup_regen.mdl"
#define TF_RUNE_HASTE            "models/pickups/pickup_powerup_haste.mdl"
#define TF_RUNE_VAMPIRE            "models/pickups/pickup_powerup_vampire.mdl"
#define TF_RUNE_REFLECT         "models/pickups/pickup_powerup_reflect.mdl"
#define TF_RUNE_PRECISION         "models/pickups/pickup_powerup_precision.mdl"
#define TF_RUNE_AGILITY         "models/pickups/pickup_powerup_agility.mdl"
#define TF_RUNE_KNOCKOUT         "models/pickups/pickup_powerup_knockout.mdl"
#define TF_RUNE_KING            "models/pickups/pickup_powerup_king.mdl"
#define TF_RUNE_PLAGUE            "models/pickups/pickup_powerup_plague.mdl"
#define TF_RUNE_SUPERNOVA        "models/pickups/pickup_powerup_supernova.mdl"

#define TF_RUNE_TEMP_CRIT        "models/pickups/pickup_powerup_crit.mdl"
#define TF_RUNE_TEMP_UBER        "models/pickups/pickup_powerup_uber.mdl"

public Plugin:myinfo =
{
	name = "[TF2] Be the Gotham Protector",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Deflector Heavy from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    //HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
    HookEvent("player_death", Event_Death, EventHookMode_Post);
    
	AddNormalSoundHook(BossGPS);

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Heavy";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;

	

    // RestrictionsDefinition restrictions = new RestrictionsDefinition();
    // // restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
    // // restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
    // restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
    // restrictions.RobotCoins.PerRobot= 1;


    AddRobot(robot, MakePanCop, PLUGIN_VERSION);
}

public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsRobot(attacker, ROBOT_NAME))
	{
		PrintHintText(victim,"%s has 50% damage vulnerability to melee & critical attacks", ROBOT_NAME);

	}

		if (IsRobotWhenDead(victim, ROBOT_NAME))
	{
		//PrintToChatAll("Attempting to kill powerup");
		//Delte the powerup:
		KillRune();
	}
	
	
}

public void KillRune(){

			int iEnt = MaxClients + 1;
		while ((iEnt = FindEntityByClassname(iEnt, "item_powerup_rune")) != -1)
		{
			if (IsValidEntity(iEnt))
			{
					//DispatchKeyValue(iEnt, "rendermode", "0");
				
				//DispatchSpawn(iEnt);
				AcceptEntityInput(iEnt, "Kill");
				// float fPos[3];
				// fPos[0] = 15.0;
				// fPos[1] = 15.0;
				// fPos[2] = 15.0;
				// TeleportEntity(iEnt, fPos, NULL_VECTOR, NULL_VECTOR);
			}
		} 
}

public Action:BossGPS(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!IsRobot(entity, ROBOT_NAME)) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), LEFTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), RIGHTFOOT1);
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
//	CreateNative("BeGDeflectorH_MakePanCop", Native_SetGDeflectorH);
//	CreateNative("BeGDeflectorH_IsGDeflectorH", Native_IsGDeflectorH);
	return APLRes_Success;
}
 
public OnMapStart()
{
	PrecacheModel(GDEFLECTORH);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	PrecacheSound(LEFTFOOT);
	PrecacheSound(LEFTFOOT1);
	PrecacheSound(RIGHTFOOT);
	PrecacheSound(RIGHTFOOT1);
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

MakePanCop(client)
{	
	TF2_SetPlayerClass(client, TFClass_Heavy);
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
	SetModel(client, GDEFLECTORH);
	int iHealth = 5000;
	
	
	int MaxHealth = 300;
	// PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
	 // PrintToChatAll("iHealth %i", iHealth);
	
	 // PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	
   
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
	
	TF2Attrib_SetByName(client, "damage force reduction", 0.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.15);

	float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
	TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);

	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	//TF2Attrib_SetByName(client, "aiming movespeed increased", 2.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	//TF2Attrib_SetByName(client, "jarate backstabber", 1.0);
	TF2Attrib_SetByName(client, "increase buff duration", 10.0);
	TF2Attrib_SetByName(client, "dmg from melee increased", 1.5);
	TF2Attrib_SetByName(client, "dmg taken from crit increased", 1.5);
	TF2Attrib_SetByName(client, "rage giving scale", 0.85);
	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	TF2Attrib_SetByName(client, "head scale", 0.95);
	 

	UpdatePlayerHitbox(client, 1.75);
   
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	PrintHintText(client, "You are a Tank!\nYou can't contest objectives\nOn Hit: Gain a 1.5 second buff depending on class");
	

	if(IsPlayerAlive(client)) EmitGameSoundToAll("Announcer.MVM_Tank_Alert_Spawn");
	// SetEntityRenderColor(client, 0, 0, 0, 0);

}
 
stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}
 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveGDeflectorH(client);
}

#define BattersBracers 30722
#define CapedCrusader 30727
#define TeufortKnight 30733
 
stock GiveGDeflectorH(client)
{
	if (IsValidClient(client))
	{		
		RoboRemoveAllWearables(client);

		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);


		CreateRoboWeapon(client, "tf_weapon_fists", 5, 6, 2, 2, 0);
		//CreateRoboWeapon(client, "tf_weapon_lunchbox", 311, 6, 2, 1, 0);


	CreateRoboHat(client, BattersBracers, 10, 6, 0.0, 1.0, -1.0); 
	CreateRoboHat(client, CapedCrusader, 10, 6, 0.0, 1.0, 1.0);
	CreateRoboHat(client, TeufortKnight, 10, 6, 0.0, 1.0, -1.0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);
			TF2Attrib_SetByName(Weapon1, "damage bonus", 1.3);
			TF2Attrib_SetByName(Weapon1, "fire rate bonus", 1.2);
			//TF2Attrib_SetByName(Weapon1, "ragdolls become ash", 1.0);
			//TF2Attrib_SetByName(Weapon1, "heal on hit for slowfire", 109.0);
			TF2Attrib_SetByName(Weapon1, "melee range multiplier", 1.35);
			TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=2.5 frequency=1.0 range=400.0");
			TF2CustAttr_SetString(Weapon1, "shake on hit", "amplitude=10.0 frequency=2.0 duration=0.5");
			TF2Attrib_SetByName(Weapon1, "move speed penalty", 0.8);
			
			
			//TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.7);
			// TF2Attrib_SetByName(Weapon1, "increased air control", 1000.0);
			
		}
		// int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		// if(IsValidEntity(Weapon2))
		// {
		// 	TF2Attrib_RemoveAll(Weapon2);
		// 	TF2Attrib_SetByName(Weapon2, "killstreak tier", 1.0);
		// 	TF2Attrib_SetByName(Weapon2, "lunchbox adds minicrits", 7.0);
		// 	TF2Attrib_SetByName(Weapon2, "lunchbox healing decreased", 40.0);
			


		// }
	}
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
    if(!IsValidClient(victim))
        return Plugin_Continue;    
    if(!IsValidClient(attacker))
        return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME))
	{
		float duration = 4.0;
		TF2_AddCondition(attacker, TFCond_RuneHaste, duration);
		TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, duration+0.5);
		//TF2_AddCondition(attacker, TFCond_RuneResist, duration);
		// float pos[3];
		
		// GetClientAbsAngles(attacker, pos);

		// MakeRune(Rune_Regen, pos, NULL_VECTOR, NULL_VECTOR);
	// switch(TF2_GetPlayerClass(victim)) {
	// 		case TFClass_Scout: PrintToChatAll("");
	// 		case TFClass_Pyro: PrintToChatAll("");
	
		switch (TF2_GetPlayerClass(victim))
		{
			
			case TFClass_Soldier, TFClass_DemoMan:{
				//TF2_AddCondition(attacker, TFCond_SmallBlastResist, duration);
				TF2_AddCondition(attacker, TFCond_UberBlastResist, duration, attacker);
				TF2Attrib_AddCustomPlayerAttribute(attacker, "dmg taken from blast reduced", 0.35, duration);
			}
			case TFClass_Pyro:{
			//TF2_AddCondition(attacker, TFCond_SmallFireResist, duration);
			TF2_AddCondition(attacker, TFCond_UberFireResist, duration, attacker);
			TF2Attrib_AddCustomPlayerAttribute(attacker, "dmg taken from fire reduced", 0.35, duration);
			
			}
			case TFClass_Heavy, TFClass_Engineer, TFClass_Sniper, TFClass_Scout:{ 
				
				TF2_AddCondition(attacker, TFCond_UberBulletResist, duration);
				TF2Attrib_AddCustomPlayerAttribute(attacker, "dmg taken from bullets reduced", 0.35, duration);
				//TF2_AddCondition(attacker, TFCond_BulletImmune, duration);
				
			}
			case TFClass_Medic:{
				TF2_AddCondition(attacker, TFCond_RadiusHealOnDamage, duration);
				
			}
			case TFClass_Spy:{
				TF2_AddCondition(attacker, TFCond_Stealthed, duration);
			}
		
			
		}
		//TF2_RemoveCondition(attacker, TFCond_RuneHaste);


		//TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 1.0);
		KillRune();
	}

}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	
	//PrintToChatAll("CONDITION WAS: %i for %N", condition, client);
   if (IsValidClient(client) && !IsRobot(client, ROBOT_NAME)){

    if(condition == TFCond_RuneVampire || condition == TFCond_RuneHaste){

		TF2_RemoveCondition(client, condition);

	}
   }
}

public Action RemoveHaste_Timer (Handle timer, int client)
{
	//PrintToChatAll("REMOVING HAST");
 	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
}




// stock int MakeRune(RuneTypes type, float pos[3], float ang[3] = NULL_VECTOR, float vel[3] = NULL_VECTOR)
// {
//     int ent = CreateEntityByName("item_powerup_rune");
//     TeleportEntity(ent, pos, ang, vel);
//     DispatchSpawn(ent);
//     SetRuneType(ent, type);
//     return ent;
// }

// stock void SetRuneType(int rune, RuneTypes type)
// {
//     SetEntData(rune, FindDataMapInfo(rune, "m_iszModel") + 24, view_as< int >(type));
// }

// stock RuneTypes GetRuneType(int rune)
// {
//     return view_as< RuneTypes >(GetEntData(rune, FindDataMapInfo(rune, "m_iszModel") + 24));
// }

// // Runes will not die if there are no info_powerup_spawn s!!
// // It's better to set this to a gargantuan amount
// stock void SetRuneKillTime(int rune, float time)
// {
//     SetEntDataFloat(rune, FindDataMapInfo(rune, "m_iszModel") + 32, time);
// }

// stock float GetRuneKillTime(int rune)
// {
//     return GetEntDataFloat(rune, FindDataMapInfo(rune, "m_iszModel") + 32);
// }

// // Alternatively, you can perpetually set this to 0 and it won' blink like it's 
// // gonna be deleted
// stock void SetRuneBlinkCount(int rune, int count)
// {
//     SetEntData(rune, FindDataMapInfo(rune, "m_iszModel") + 28, count);
// }

// stock int GetRuneBlinkCount(int rune)
// {
//     return GetEntData(rune, FindDataMapInfo(rune, "m_iszModel") + 28);
// }

// stock RuneTypes GetCarryingRuneType(int client)
// {
//     static TFCond runeconds[] = {
//         TFCond_RuneStrength,
//         TFCond_RuneHaste,
//         TFCond_RuneRegen,
//         TFCond_RuneResist,
//         TFCond_RuneVampire,
//         TFCond_RuneWarlock,
//         TFCond_RunePrecision,
//         TFCond_RuneAgility,
//         TFCond_PlagueRune,
//         TFCond_KingRune,
//         TFCond_RuneKnockout,
//         TFCond_SupernovaRune
//     }

//     int count;
//     do    
//         if (TF2_IsPlayerInCondition(client, runeconds[count]))
//             return view_as< RuneTypes >(count);
//         while ++count < view_as< int >(Rune_LENGTH);        // This tagging makes me want to scream

//     return Rune_Invalid;
// } 

// public TF2_OnConditionAdded(client, TFCond:condition)
// {
//     if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
//     {	
//         int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
//         if (tauntid == -1)
//         {
// 		TF2_AddCondition(client, TFCond_CritCola, 30.0);
// 		TF2_AddCondition(client, TFCond_RegenBuffed, 30.0);
// 		TF2_AddCondition(client, TFCond_RestrictToMelee, 30.0);
// 		CreateTimer(2.5, Timer_Taunt_Cancel, client);
//         }	  
// 	}
// }

// public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
// {
// 	if (IsValidClient(client)){

// 		TF2_RemoveCondition(client, TFCond_Taunting);

// 		int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

// 		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon); 
// 	}
// }


// - Regular paints -
//set item tint RGB
// A Color Similar to Slate					3100495
// A Deep Commitment to Purple					8208497
// A Distinctive Lack of Hue					1315860
// A Mann's Mint								12377523
// After Eight									2960676
// Aged Moustache Grey							8289918
// An Extraordinary Abundance of Tinge			15132390
// Australium Gold								15185211	
// Color No. 216-190-216						14204632
// Dark Salmon Injustice						15308410
// Drably Olive								8421376
// Indubitably Green							7511618
// Mann Co. Orange								13595446
// Muskelmannbraun								10843461
// Noble Hatter's Violet						5322826
// Peculiarly Drab Tincture					12955537
// Pink as Hell								16738740
// Radigan Conagher Brown						6901050
// The Bitter Taste of Defeat and Lime			3329330
// The Color of a Gentlemann's Business Pants	15787660
// Ye Olde Rustic Colour						8154199
// Zepheniah's Greed							4345659

// - Team colors -

// An Air of Debonair:
// set item tint RGB : 6637376
// set item tint RGB 2 : 2636109

// Balaclavas Are Forever
// set item tint RGB : 3874595
// set item tint RGB 2 : 1581885

// Cream Spirit
// set item tint RGB : 12807213
// set item tint RGB 2 : 12091445

// Operator's Overalls
// set item tint RGB : 4732984
// set item tint RGB 2 : 3686984

// Team Spirit
// set item tint RGB : 12073019
// set item tint RGB 2 : 5801378

// The Value of Teamwork
// set item tint RGB : 8400928
// set item tint RGB 2 : 2452877

// Waterlogged Lab Coat
// set item tint RGB : 11049612
// set item tint RGB 2 : 8626083