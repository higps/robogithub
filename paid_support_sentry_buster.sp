#pragma semicolon 1
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_ontakedamage>
#include <sdkhooks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Buster"
#define ROBOT_ROLE "Sentry Buster"
#define ROBOT_DESCRIPTION ""

#define GBUSTER		"models/bots/demo/bot_sentry_buster.mdl"
#define SPAWN	"#mvm/sentrybuster/mvm_sentrybuster_intro.wav"
#define DEATH	"mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define LOOP	"mvm/sentrybuster/mvm_sentrybuster_loop.wav"

int TracedTarget = INVALID_ENT_REFERENCE;

bool AboutToExplode[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[TF2] Be the Giant Sentry Buster",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Sentry Buster from MvM",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

bool g_Taunt_clamp = false;
public void OnPluginStart()
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
    restrictions.RobotCoins.Overall = 2;

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

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	// PrintToChat(victim,"You died as sentry buster");
	if (IsRobotWhenDead(victim, ROBOT_NAME))
	{
		AboutToExplode[victim] = false;
		CreateTimer(4.0, Timer_Respawn, victim);
		// PrintToChat(victim,"Creating timer");
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


public APLRes AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//	CreateNative("BeGiantDemoKnight_MakeBuster", Native_SetGiantDemoKnight);
	//	CreateNative("BeGiantDemoKnight_IsGiantDemoKnight", Native_IsGiantDemoKnight);
	return APLRes_Success;
}

public void OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, OnTouch);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack); // hook for when someone joins in the middle of a round
}

public void OnClientDisconnect_Post(client)
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
}
public Action OnTouch(int client, int ent)
{
    if (IsValidClient(client) && IsValidEntity(ent))
    {
		if (IsRobot(client, ROBOT_NAME))
		{
        	char entname[MAX_NAME_LENGTH];
        	GetEntityClassname(ent, entname, sizeof(entname));

        	if (StrEqual(entname, "obj_sentrygun"))
        	{
				
	            //int iBuilder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
				int iBuildingTeam = GetEntPropEnt(ent, Prop_Send, "m_iTeamNum");
				int iClientTeam = GetClientTeam(client);

				if(iClientTeam != iBuildingTeam && !g_Taunt_clamp)
				{
					SetEntPropEnt(ent, Prop_Send, "m_bGlowEnabled", 1);
					//PrintToChatAll("not the same team");
					GetReadyToExplode(client);
					FakeClientCommand(client, "taunt");
					TF2_AddCondition(client, TFCond_FreezeInput, 7.0);
					g_Taunt_clamp = true;
					CreateTimer(2.5, FakeCommand_Clamp);
				}
        	}
			if (StrEqual(entname, "player"))
			{
				int iCarried = GetEntPropEnt(ent, Prop_Send, "m_hCarriedObject");

				if (iCarried > MaxClients)
				{
					char entname[MAX_NAME_LENGTH];
        			GetEdictClassname(iCarried, entname, sizeof(entname));
					//	PrintToChatAll("%s Object carried", entname);
					if (StrEqual(entname, "obj_sentrygun") && !AboutToExplode[client])
        			{
						GetReadyToExplode(client);
						TF2_AddCondition(client, TFCond_FreezeInput);
						FakeClientCommand(client, "taunt");
					}
				}
			}
		}
    }
}

public Action SetModel(int client, const char[] model)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

void MakeBuster(client)
{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll))
		RemoveEntity(ragdoll);

	char weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	RequestFrame(ClientSwitch, client);
	SetModel(client, GBUSTER);
	int iHealth = 2500;
	int MaxHealth = 175;
	int iAdditiveHP = iHealth - MaxHealth;
	TF2_SetHealth(client, iHealth);

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



void GetReadyToExplode(int client)
{
	TF2_AddCondition(client, TFCond_MegaHeal);
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_spin.wav", client);
	StopSound(client, SNDCHAN_AUTO, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
	CreateTimer(2.0, Bewm, GetClientUserId(client));
	AboutToExplode[client] = true;
}

void DoDamage(int client, int target, int amount) // from Goomba Stomp.
{
	int pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt > MaxClients) //this shouldn't ever fail
	{
		DispatchKeyValue(target, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		char dmg[15];
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

public Action FakeCommand_Clamp(Handle timer)
{
	g_Taunt_clamp = false;
}

public void TF2_OnConditionAdded(client, TFCond condition)
{
    if (IsRobot(client, ROBOT_NAME) && condition == TFCond_Taunting)
    {
        int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
		if (IsRobot(client, ROBOT_NAME) && tauntid == -1)
		{
			GetReadyToExplode(client);
			TF2_AddCondition(client, TFCond_FreezeInput, 7.0);
		}
	}
}

public Action Bewm(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	//if (!TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Handled;
	AboutToExplode[client] = false;

	// int iClientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
	// PrintToChatAll("Team was %i", iClientTeam);
	int explosion = CreateEntityByName("env_explosion");
	float clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	if (explosion)
	{
		DispatchSpawn(explosion);
		TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode", -1, -1, 0);
		RemoveEdict(explosion);
	}
	bool FF = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) == GetClientTeam(client) && !FF) continue;
		float zPos[3];
		GetClientEyePosition(i, zPos);
		float Dist = GetVectorDistance(clientPos, zPos);
		if (Dist > 300.0) continue;

		if (CanSeeTarget(clientPos, zPos, i, client))
			DoDamage(client, i, 2500);
	}
	for (int i = MaxClients + 1; i <= 2048; i++)
	{
		if (!IsValidEntity(i)) continue;
		char cls[20];
		GetEntityClassname(i, cls, sizeof(cls));

		if (!StrEqual(cls, "obj_sentrygun", false) &&
		!StrEqual(cls, "obj_dispenser", false) &&
		!StrEqual(cls, "obj_teleporter", false)) continue;

		
		



		float zPos[3];
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", zPos);
		float Dist = GetVectorDistance(clientPos, zPos);
		if (Dist > 300.0) continue;

		
		if (CanSeeTarget(clientPos, zPos, i, client))
		{
			int iTeam = GetEntPropEnt(i, Prop_Send, "m_iTeamNum");
		//	PrintToChatAll("iTeam %i, iClient Team %i", iTeam, iClientTeam);
		// if (iTeam != iClientTeam)
		// {
				
			SetVariantInt(2500);
			AcceptEntityInput(i, "RemoveHealth");
		// }
		}
	}
	EmitSoundToAll("mvm/sentrybuster/mvm_sentrybuster_explode.wav", client);
	AttachParticle(client, "fluidSmokeExpl_ring_mvm");
	DoDamage(client, client, 2500);
	FakeClientCommand(client, "kill");
	//CreateTimer(0.0, Timer_RemoveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	TracedTarget = INVALID_ENT_REFERENCE;
	return Plugin_Handled;
}

bool CanSeeTarget(float start[3], float end[3], int target, int source)
{
	bool result = false;
	//end[2] += 50.0; //Raise the position to be roughly the center of the target player
	TracedTarget = target;
	Handle trace = TR_TraceRayFilterEx(start, end, MASK_SHOT, RayType_EndPoint, CheckTrace, source);
	if (TR_DidHit(trace))
	{
		if (TR_GetEntityIndex(trace) == target)
			result = true;
	}
	CloseHandle(trace);
	return result;
}

bool CheckTrace(int entity, int mask, int ignore)
{
	if (entity == ignore)
		return false;

	//Prevent other players from blocking line of sight
	if (IsValidClient(entity) && entity != TracedTarget)
		return false;

	return true;
}

stock bool AttachParticle(int Ent, char[] particleType, bool cache = false) // from L4D Achievement Trophy
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
public Action DeleteParticle(Handle timer, any Ent)
{
	if (!IsValidEntity(Ent)) return;
	char cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) RemoveEntity(Ent);
	return;
}

stock void TF2_SetHealth(int client, int NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", NewHealth, 1);
}

void ClientSwitch(int client)
{
	if (IsValidClient(client))
		GiveGiantDemoKnight(client);
}

stock void GiveGiantDemoKnight(int client)
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
