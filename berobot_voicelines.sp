#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf_ontakedamage>
#include <sm_logger>
#include <berobot_constants>

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR", "NormalSoundHook"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
    SML_NormalSoundHook,
}
#include <berobot_core>
#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "berobot_voicelines",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

bool g_VoiceCalloutClamp[MAXPLAYERS + 1];

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_voicelines started at %i", GetTime());

    AddNormalSoundHook(NormalSoundHook);
    HookEvent("player_death", Event_Death, EventHookMode_Post);
    HookEvent("player_escort_score", Event_player_escort_score, EventHookMode_Post);
}

public Action NormalSoundHook(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (!IsValidClient(entity)) 
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because client %i is not valid", entity);
		return Plugin_Continue;
	}

	SMLogTag(SML_NormalSoundHook, "playing sound %s for %L at volume %f", sample, entity, volume);

	if (!IsAnyRobot(entity)) //skip if no robot is picked
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because %L is not a robot", entity);
		return Plugin_Continue;
	}
	
	if (volume == 0.0 || volume == 0.9997)
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because volume is set to %f", volume);
		return Plugin_Continue;
	}
	TFClassType class = TF2_GetPlayerClass(entity);

	if (StrContains(sample, "vo/", false) == -1)
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because 'vo/' was not found in %s", sample);
		return Plugin_Continue;
	}
	if (StrContains(sample, "announcer", false) != -1)
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because 'announcer' was not found in %s", sample);
		return Plugin_Continue;
	}
	if (ClassHasDeepRobotVoiceLines(class))
	{
		ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/mght/", false);
		ReplaceString(sample, sizeof(sample), "_", "_m_", false);
	}
	else
	{
		ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/norm/", false);
	}
	ReplaceString(sample, sizeof(sample), ".wav", ".mp3", false);
	char classname[10]; 
	char classname_mvm[15];
	TF2_GetNameOfClass(class, classname, sizeof(classname));
	Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
	ReplaceString(sample, sizeof(sample), classname, classname_mvm, false);

	SMLogTag(SML_NormalSoundHook, "turned sample into %s", sample);
	PrecacheSound(sample);
	return Plugin_Changed;
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int assister = GetClientOfUserId(GetEventInt(event, "assister"));

    SMLogTag(SML_VERBOSE, "Event_Death triggerd with attacker %L, assister %L and victim %L", attacker, assister, victim);

    //Robot died
    if (IsAnyRobot(victim))
    {
        PlayRobotDeathVoiceOver(attacker);
        PlayRobotDeathVoiceOver(assister);
    }

    //player died to robot
    if (!IsAnyRobot(victim) && IsAnyRobot(attacker))
    {
        PlayRobotKilledFriendVoiceOver();
    }
}

public Action Event_player_escort_score(Event event, char[] name, bool dontBroadcast)
{   
    SMLogTag(SML_VERBOSE, "Event_player_escort_score called");
    //Adds voice line if boss mode is active
    if (!IsEnabled())
    {
        SMLogTag(SML_VERBOSE, "Event_player_escort_score ignored, because MM is not enabled");
        return;
    }
    if(!IsActive())
    {
        SMLogTag(SML_VERBOSE, "Event_player_escort_score ignored, because robo-mode is not active");
        return;
    }  

    int iCapper = GetEventInt(event, "player");
    TFTeam iCapperTeam = TF2_GetClientTeam(iCapper);
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
        {
            SMLogTag(SML_VERBOSE, "Event_player_escort_score ignored for %i, because the client is not valid", i);
            continue;
        }  
        if (!IsClientInGame(i))
        {
            SMLogTag(SML_VERBOSE, "Event_player_escort_score ignored for %i, because the client is not ingame", i);
            continue;
        }  
        if (IsAnyRobot(i))
        {
            SMLogTag(SML_VERBOSE, "Event_player_escort_score ignored for %i, because the client is a robot", i);
            continue;
        }  
        if (!IsPlayerAlive(i))
        {
            SMLogTag(SML_VERBOSE, "Event_player_escort_score ignored for %i, because the client is not alive", i);
            continue;
        }  

        TFTeam iPlayerTeam = TF2_GetClientTeam(i);  
        if (iPlayerTeam == iCapperTeam)
        {
            SMLogTag(SML_VERBOSE, "Event_player_escort_score ignored for %i, because the client is on the capping team", i);
            continue;
        }  

        if (!MM_Random(1,3))
        {
            SMLogTag(SML_VERBOSE, "Event_player_escort_score ignored for %i, because random says no", i);
            continue;
        }  

        PlayRobotPushedCartVoiceOver(i);        
    }
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    if (!IsEnabled())
    {
        SMLogTag(SML_VERBOSE, "TF2_OnTakeDamageModifyRules ignored, because MM is not enabled");
        return Plugin_Continue;
    }
    if(!IsValidClient(victim))
    {
        SMLogTag(SML_VERBOSE, "TF2_OnTakeDamageModifyRules ignored, because victim %i was not a valid client", victim);
        return Plugin_Continue;
    }  
    if(!IsValidClient(attacker))
    {
        SMLogTag(SML_VERBOSE, "TF2_OnTakeDamageModifyRules ignored, because attacker %i was not a valid client", attacker);
        return Plugin_Continue;
    }  


    TFClassType iClassAttacker = TF2_GetPlayerClass(attacker);

    PlayRobotTakeDamageVoiceOver(attacker, iClassAttacker, victim);

    return Plugin_Continue;
}

void PlayRobotDeathVoiceOver(int client)
{
    if (!IsValidClient(client))
    {
        SMLogTag(SML_VERBOSE, "PlayRobotDeathVoiceOver ignored, because client %i was not a valid client", client);
        return;
    }

    SMLogTag(SML_VERBOSE, "PlayRobotDeathVoiceOver for %L", client);

    TFClassType class = TF2_GetPlayerClass(client);
    char szVO[512];
    switch(class)
    {
        case TFClass_Heavy:
        {
            strcopy(szVO, sizeof(szVO), "heavy_mvm_giant_robot02");
        }
        case TFClass_Medic:
        {
            strcopy(szVO, sizeof(szVO), "medic_mvm_giant_robot02");
        }
        default:
            return;
    }
    
    EmitGameSoundToAll(szVO, client);
}

void PlayRobotKilledFriendVoiceOver()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsValidClient(i))
        {
            SMLogTag(SML_VERBOSE, "PlayRobotKilledFriendVoiceOver ignored, because client %i was not a valid client", i);
            continue;
        }
        if(!IsPlayerAlive(i))
        {
            SMLogTag(SML_VERBOSE, "PlayRobotKilledFriendVoiceOver ignored, because client %i was not alive", i);
            continue;
        }
            
        char szVO[512];
        switch(i)
        {
            case TFClass_Heavy:
            {
                if (MM_Random(1, 10)){
                    SMLogTag(SML_VERBOSE, "PlayRobotKilledFriendVoiceOver for %L", i);
                    strcopy(szVO, sizeof(szVO), "heavy_mvm_giant_robot01");
                    EmitGameSoundToAll(szVO, i);
                }
            }
        }
    }
}

void PlayRobotPushedCartVoiceOver(int clientId)
{
    SMLogTag(SML_VERBOSE, "PlayRobotPushedCartVoiceOver for %L", clientId);

    TFClassType iClass = TF2_GetPlayerClass(clientId);
    bool isSpyDisguised = iClass == TFClass_Spy && TF2_IsPlayerInCondition(clientId, TFCond_Disguised);
    if (isSpyDisguised)
    {
        iClass = view_as<TFClassType>(GetEntProp(clientId, Prop_Send, "m_nDisguiseClass"));
    }

    char szVO[512];
    switch(iClass)
    {
        case TFClass_Heavy:
        {
            strcopy(szVO, sizeof(szVO), "heavy_mvm_giant_robot03");
        }
        case TFClass_Medic:
        {
            strcopy(szVO, sizeof(szVO), "medic_mvm_giant_robot03");
        }
        case TFClass_Soldier:
        {
            int digit = GetRandomInt(3,4);
            Format(szVO, sizeof(szVO), "soldier_mvm_giant_robot0%i", digit);
        }
        case TFClass_Engineer:
        {
            strcopy(szVO, sizeof(szVO), "engineer_mvm_giant_robot03");
        }
        default:
            return;
    }

    EmitGameSoundToAll(szVO, clientId);
}

void PlayRobotTakeDamageVoiceOver(int attackerClientId, TFClassType attackerClass, int victimClientId)
{
    if (!IsAnyRobot(victimClientId)) 
    {
        SMLogTag(SML_VERBOSE, "PlayRobotTakeDamageVoiceOver ignored, because victim %i was not a robot", victimClientId);
        return;
    }
    if (!MM_Random(1,4))
    {
        SMLogTag(SML_VERBOSE, "PlayRobotTakeDamageVoiceOver ignored, because random says no");
        return;
    }
    if (IsAnyRobot(attackerClientId))
    {
        SMLogTag(SML_VERBOSE, "PlayRobotTakeDamageVoiceOver ignored, because attacker %i was a robot", victimClientId);
        return;
    }

    SMLogTag(SML_VERBOSE, "PlayRobotTakeDamageVoiceOver for attacker %L and victim %L", attackerClientId, victimClientId);

    char szVO[512];
    int digit = 0;
    switch(attackerClass)
    {
        case TFClass_Heavy:
        {
            Format(szVO, sizeof(szVO), "heavy_mvm_giant_robot04");
        }
        case TFClass_Medic:
        {
            Format(szVO, sizeof(szVO), "medic_mvm_giant_robot01");
        }
        case TFClass_Soldier:
        {
            digit = GetRandomInt(1,2);
            Format(szVO, sizeof(szVO), "soldier_mvm_giant_robot0%i", digit);
        }
        case TFClass_Engineer:
        {
            digit = GetRandomInt(1,2);
            Format(szVO, sizeof(szVO), "engineer_mvm_giant_robot0%i", digit);
        }
        default:
            return;
    }

    float random_timer = GetRandomFloat(20.5,60.5);
    EmitSoundWithClamp(attackerClientId, szVO, random_timer);
}

void EmitSoundWithClamp(int client, char[] voiceline, float clamp)
{
    if (g_VoiceCalloutClamp[client])
    {
        SMLogTag(SML_VERBOSE, "EmitSoundWithClamp ignored, because clamped for client %L", client);
        return;
    }
    if (!IsPlayerAlive(client))
    {
        SMLogTag(SML_VERBOSE, "EmitSoundWithClamp ignored, because client %L is not alive", client);
        return;
    }
        
    EmitGameSoundToAll(voiceline, client);

    CreateTimer(clamp, calltimer_reset, client);
    g_VoiceCalloutClamp[client] = true;
}

public Action calltimer_reset (Handle timer, int client)
{
	g_VoiceCalloutClamp[client] = false;
}