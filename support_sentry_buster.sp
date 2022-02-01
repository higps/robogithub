#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
#include <sdkhooks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Buster"
#define ROBOT_ROLE "Support"
#define ROBOT_DESCRIPTION "Explode by taunting"

#define GBUSTER		"models/bots/demo/bot_sentry_buster.mdl"
#define SPAWN	"#mvm/sentrybuster/mvm_sentrybuster_intro.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/sentrybuster/mvm_sentrybuster_loop.wav"



bool AboutToExplode[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Sentry Buster",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Sentry Buster from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

//new bool:g_bIsGBUSTER[MAXPLAYERS + 1];

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RobotDefinition robot;
    robot.name = ROBOT_NAME;
    robot.role = ROBOT_ROLE;
    robot.class = "Sentry";
    robot.shortDescription = ROBOT_DESCRIPTION;
    robot.sounds.spawn = SPAWN;
    robot.sounds.loop = LOOP;
    robot.sounds.death = DEATH;
	
    RestrictionsDefinition restrictions = new RestrictionsDefinition();
    // restrictions.TimeLeft = new TimeLeftRestrictionDefinition();
    // restrictions.TimeLeft.SecondsBeforeEndOfRound = 300;
    restrictions.RobotCoins = new RobotCoinRestrictionDefinition();
    restrictions.RobotCoins.Overall = 3;

	AddRobot(robot, MakeBuster, PLUGIN_VERSION, restrictions);

    for(int client = 1 ; client <= MaxClients ; client++)
    {
        if(IsClientInGame(client))
        {
            SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
            SDKHook(client, SDKHook_Touch, OnTouch);
        }
    }

    HookEvent("post_inventory_application", Event_post_inventory_application, EventHookMode_Post);
    HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public void OnPluginEnd()
{
	RemoveRobot(ROBOT_NAME);
}
public Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsRobotWhenDead(victim, ROBOT_NAME))
	{
		AboutToExplode[victim] = false;
		CreateTimer(4.0, Timer_Respawn, victim);
		//PrintToChat(victim,"Creating timer");
	}


}

public Action Timer_Respawn(Handle timer, any client)
{
    //PrintToChatAll("Timebomb: %i", g_TimeBombTime[client]);
	if (IsValidClient(client) && !IsPlayerAlive(client))
    {
        TF2_RespawnPlayer(client);
        //PrintToChat(client,"You have instant respawn as scout");
    }
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeGiantDemoKnight_MakeBuster", Native_SetGiantDemoKnight);
	//	CreateNative("BeGiantDemoKnight_IsGiantDemoKnight", Native_IsGiantDemoKnight);
	return APLRes_Success;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, OnTouch);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack); // hook for when someone joins in the middle of a round
}

public OnClientDisconnect_Post(client)
{
	SDKUnhook(client, SDKHook_Touch, OnTouch);
}

public OnMapStart()
{
	PrecacheModel(GBUSTER);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);

	PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_01.wav");
	PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_02.wav");
	PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_03.wav");
	PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_04.wav");
	PrecacheSound("mvm/sentrybuster/mvm_sentrybuster_spin.wav");
	
}

public Action Event_post_inventory_application(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	///Sets color back to normal
	if (IsValidClient(client))
	{
	SetEntityRenderColor(client, 255, 255, 255, 0);
	}
/* 	if (g_bIsGBUSTER[client]){
			AddNormalSoundHook(SoundHook);
	} */
		//RemoveNormalSoundHook(SoundHook);
}
public Action OnTouch(int client, int ent)
{

    //PrintToChatAll("Got Here");


    if (IsValidClient(client) && IsValidEntity(ent))
    {
    //		char class[MAX_NAME_LENGTH];
    //		GetEdictClassname(ent, class, sizeof(class));
	
        //PrintToChatAll("ent was %i", ent);
			if (IsRobot(client, ROBOT_NAME))
			 {
        char entname[MAX_NAME_LENGTH];
        GetEdictClassname(ent, entname, sizeof(entname));

  //  PrintToChatAll("before ent name was %s", entname);
 //|| StrEqual(entname, "obj_dispenser")
        if (StrEqual(entname, "obj_sentrygun"))
        {
			SetEntPropEnt(ent, Prop_Send, "m_bGlowEnabled", 1);
            int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
			int iBuildingTeam = GetEntPropEnt(ent, Prop_Send, "m_iTeamNum");
			int iClientTeam = TF2_GetClientTeam(client);
			
		//	PrintToChatAll("iBuildingTeam: %i || Client teamL %i", iBuildingTeam, iClientTeam);


			if(iClientTeam != iBuildingTeam){
				//PrintToChatAll("not the same team");
				FakeClientCommand(client, "taunt");
			}
        //	PrintToChatAll("after ent name was %s", entname);
         
                
				//GetReadyToExplode(client);
				
               // PrintToChatAll("Builder was %N", iBuilder);

                //SetEntProp(ent, Prop_Send, "m_CollisionGroup", 18);
                
                //return Plugin_Stop;
            //	SDKHook(client, SDKHook_ShouldCollide, ShouldCollide);
                
            
        }

		if (StrEqual(entname, "player"))
		{
			int iCarried = GetEntPropEnt(ent, Prop_Send, "m_hCarriedObject");

			if (iCarried != -1)
			{
				char entname[MAX_NAME_LENGTH];
        		GetEdictClassname(iCarried, entname, sizeof(entname));
			//	PrintToChatAll("%s Object carried", entname);
					if (StrEqual(entname, "obj_sentrygun") && !AboutToExplode[client])
        			{
						GetReadyToExplode(client);
						FakeClientCommand(client, "taunt");
					}
		}
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

MakeBuster(client)
{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);

	//Sets color to red if team is red
	/* 		if(GetClientTeam(client) == 2){
            SetEntityRenderColor(client, 255, 0, 0, 255);
			} */
	

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, GBUSTER);

	int iHealth = 2500;
	
	
	int MaxHealth = 175;
//	PrintToChatAll("MaxHealth %i", MaxHealth);
	
	int iAdditiveHP = iHealth - MaxHealth;
	
	TF2_SetHealth(client, iHealth);
//	 PrintToChatAll("iHealth %i", iHealth);
	
	// PrintToChatAll("iAdditiveHP %i", iAdditiveHP);
	
	

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
float HealthPackPickUpRate =  float(MaxHealth) / float(iHealth);
TF2Attrib_SetByName(client, "health from packs decreased", HealthPackPickUpRate);
	TF2Attrib_SetByName(client, "max health additive bonus", float(iAdditiveHP));
	TF2Attrib_SetByName(client, "damage force reduction", 0.0);
	TF2Attrib_SetByName(client, "move speed penalty", 2.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", -5.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2Attrib_SetByName(client, "patient overheal penalty", 0.15);
	
	TF2Attrib_SetByName(client, "override footstep sound set", 7.0);
	TF2Attrib_SetByName(client, "increased jump height", 2.0);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "rage giving scale", 0.5);
	TF2Attrib_SetByName(client, "increase player capture value", -1.0);
	
	UpdatePlayerHitbox(client, 1.75);

	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	
	PrintToChat(client, "1. You are now Giant Sentry Buster!");
	PrintHintText(client , "Touch sentries, taunt or hit enemies with the caber to explode");

	EmitGameSoundToAll("Announcer.MVM_Sentry_Buster_Alert");
}



stock GetReadyToExplode(client)
{
	TF2_AddCondition(client, TFCond_MegaHeal);
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_spin.wav", client);
	StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
//	PrintToChatAll("EXPLODING!");
	CreateTimer(2.0, Bewm, GetClientUserId(client));
	AboutToExplode[client] = true;
}
stock DoDamage(client, target, amount) // from Goomba Stomp.
{
	new pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt)
	{
		DispatchKeyValue(target, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		new String:dmg[15];
		Format(dmg, 15, "%i", amount);
		DispatchKeyValue(pointHurt, "Damage", dmg);
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", client);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(target, "targetname", "");
		RemoveEdict(pointHurt);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {	
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");

	//PrintToChatAll("Taunt ID %i", tauntid);
	

	if (IsRobot(client, ROBOT_NAME) && tauntid == -1)
	{
	//	if (AboutToExplode[client]) return Plugin_Continue;
//		if (GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1) return Plugin_Continue;
		GetReadyToExplode(client);
	}	  

	}
}

public Action:Bewm(Handle:timer, any:userid)
{

	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	if (!TF2_IsPlayerInCondition(client, TFCond_Taunting))return Plugin_Handled;
	AboutToExplode[client] = false;
	new explosion = CreateEntityByName("env_explosion");
	new Float:clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	if (explosion)
	{
		DispatchSpawn(explosion);
		TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode", -1, -1, 0);
		RemoveEdict(explosion);
	}
	new bool:FF = false;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) == GetClientTeam(client) && !FF) continue;
		new Float:zPos[3];
		GetClientAbsOrigin(i, zPos);
		new Float:Dist = GetVectorDistance(clientPos, zPos);
		if (Dist > 300.0) continue;
		DoDamage(client, i, 2500);
	}
	for (new i = MaxClients + 1; i <= 2048; i++)
	{
		if (!IsValidEntity(i)) continue;
		decl String:cls[20];
		GetEntityClassname(i, cls, sizeof(cls));
		if (!StrEqual(cls, "obj_sentrygun", false) &&
		!StrEqual(cls, "obj_dispenser", false) &&
		!StrEqual(cls, "obj_teleporter", false)) continue;
		new Float:zPos[3];
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", zPos);
		new Float:Dist = GetVectorDistance(clientPos, zPos);
		if (Dist > 300.0) continue;
		SetVariantInt(2500);
		AcceptEntityInput(i, "RemoveHealth");
	}
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_explode.wav", client);
	AttachParticle(client, "fluidSmokeExpl_ring_mvm");
	DoDamage(client, client, 2500);
	FakeClientCommand(client, "kill");
	CreateTimer(0.0, Timer_RemoveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}


stock bool:AttachParticle(Ent, String:particleType[], bool:cache=false) // from L4D Achievement Trophy
{
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) return false;
	new String:tName[128];
	new Float:f_pos[3];
	if (cache) f_pos[2] -= 3000;
	else
	{
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", f_pos);
		f_pos[2] += 60;
	}
	TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);
	Format(tName, sizeof(tName), "target%i", Ent);
	DispatchKeyValue(Ent, "targetname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(10.0, DeleteParticle, particle);
	return true;
}
public Action:DeleteParticle(Handle:timer, any:Ent)
{
	if (!IsValidEntity(Ent)) return;
	new String:cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) AcceptEntityInput(Ent, "Kill");
	return;
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return;
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!IsValidEntity(ragdoll) || ragdoll <= MaxClients) return;
	AcceptEntityInput(ragdoll, "Kill");
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
	GiveGiantDemoKnight(client);
}

stock GiveGiantDemoKnight(client)
{
	if (IsValidClient(client))
	{

		
		RoboRemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);
		CreateRoboWeapon(client, "tf_weapon_stickbomb", 307, 6, 1, 2, 0);

		int Weapon1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weapon1))
		{
			TF2Attrib_RemoveAll(Weapon1);
			TF2Attrib_SetByName(Weapon1, "killstreak tier", 1.0);			
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs buildings", 0.0);
			TF2Attrib_SetByName(Weapon1, "dmg penalty vs players", 0.0);
			TF2CustAttr_SetString(Weapon1, "shake on step", "amplitude=1.25 frequency=1.5 range=400.0");
			SetEntProp(Weapon1, Prop_Send, "m_iDetonated", 1);
			

		}
		

	}
}

public Action OnTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
		if(IsValidClient(attacker))
		{

			
		//	PrintCenterTextAll("hit1");
			if (IsRobot(attacker, ROBOT_NAME) && IsValidClient(victim))
		{
		//	PrintCenterTextAll("hit2");
			//GetReadyToExplode(attacker);
			if(TF2_GetClientTeam(attacker) != (TF2_GetClientTeam(victim)))
			{
			FakeClientCommand(attacker, "taunt");
			}
		}
		}
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
if (IsValidClient(victim))
	{
		
		if (!IsRobot(victim, ROBOT_NAME)|| victim == attacker) return Plugin_Continue;


		
		//new Float:dmg = ((damagetype & DMG_CRIT) ? damage*3 : damage) + 10.0; // +10 to attempt to account for damage rampup.
		if (AboutToExplode[victim])
		{
			damage = 0.0;
			FakeClientCommand(victim, "taunt");
			return Plugin_Changed;
		}
		else if (damage+10.0 > GetClientHealth(victim))
		{
			damage = 0.0;
			GetReadyToExplode(victim);
			FakeClientCommand(victim, "taunt");
			return Plugin_Changed;
		}
	}
if (IsValidClient(attacker)) // This is a Sentry.
	{
		if (!IsRobot(victim, ROBOT_NAME) && !AboutToExplode[attacker])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
return Plugin_Continue;

}