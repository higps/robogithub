#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf_ontakedamage>
#include <morecolors>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf2attributes>

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

#define WAVESTART "music/mvm_start_wave.wav"


public Plugin myinfo =
{
	name = "berobot_voicelines",
	author = "icebear, heavy is gps",
	description = "Manned Machines voice line handler",
	version = "0.1",
	url = "https://github.com/higps/robogithub"
};

bool g_VoiceCalloutClamp[MAXPLAYERS + 1];
bool AnnounceWhenDecloak[MAXPLAYERS + 1] = {true,...};

public void OnPluginStart()
{
    SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
    SMLogTag(SML_INFO, "berobot_voicelines started at %i", GetTime());

    AddNormalSoundHook(NormalSoundHook);
    HookEvent("player_death", Event_Death, EventHookMode_Pre);
    HookEvent("player_escort_score", Event_player_escort_score, EventHookMode_Post);
    HookEvent("teamplay_setup_finished", Event_teamplay_setup_finished, EventHookMode_Post);
    HookEvent("teamplay_round_win", Event_teamplay_round_win, EventHookMode_Post);
    HookEvent("post_inventory_application", Event_post_inventory_application, EventHookMode_Post);
    
    // HookEvent("teamplay_round_win", Event_Teamplay_Round_Win, EventHookMode_Post);
}

// int EveryOtherStep[MAXPLAYERS + 1] = {0,...};

#define MVMSTART "vo/mvm_wave_start01.mp3"
#define ANNOUNCERWAVESTART "Announcer.MVM_Wave_Start"
#define ANNOUNCER_ALL_DEAD "Announcer.MVM_All_Dead"
#define ANNOUNCER_ENGINEER_BOT_SPAWN "Announcer.MVM_First_Engineer_Teleport_Spawned"

#define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
#define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
#define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"

#define GUNFIRE_DEMO ")mvm/giant_demoman/giant_demoman_grenade_shoot.wav"
// Easier to have all the sounds we want in a single variable array for better access
// static const char WaveVoiceLineStartSounds[][256] =
// {
//     "vo/mvm_wave_start01.mp3",
//     "vo/mvm_wave_start02.mp3",
//     "vo/mvm_wave_start03.mp3",
//     "vo/mvm_wave_start04.mp3",
//     "vo/mvm_wave_start05.mp3",
//     "vo/mvm_wave_start06.mp3",
//     "vo/mvm_wave_start07.mp3",
//     "vo/mvm_wave_start08.mp3",
//     "vo/mvm_wave_start09.mp3",
//     "vo/mvm_wave_start10.mp3",
//     "vo/mvm_wave_start11.mp3",
//     "vo/mvm_wave_start12.mp3"
// };

bool b_AnnounceClamp = false;

static const char Spy_Spawn[][256] =
{
    "vo/mvm_spy_spawn01.mp3",
    "vo/mvm_spy_spawn02.mp3",
    "vo/mvm_spy_spawn03.mp3",
    "vo/mvm_spy_spawn04.mp3"
};

static const char One_Spy_Death[][256]=
{
    "vo/mvm_spybot_death01.mp3", //SINGLE SPYBOT
    "vo/mvm_spybot_death02.mp3",
    "vo/mvm_spybot_death03.mp3",
    "vo/mvm_spybot_death04.mp3", //ALL SPYBOTS DESTROYED
    "vo/mvm_spybot_death05.mp3",
    "vo/mvm_spybot_death06.mp3",
    "vo/mvm_spybot_death07.mp3",
    "vo/mvm_spybot_death08.mp3", //6 SPYBOTS REMAIN
    "vo/mvm_spybot_death09.mp3", //5 SPYBOT REMAIN
    "vo/mvm_spybot_death10.mp3", //4
    "vo/mvm_spybot_death11.mp3", //3
    "vo/mvm_spybot_death12.mp3", //2
    "vo/mvm_spybot_death13.mp3" //1

};

static const char One_Engineer_Spawn[][256] =
{
    "vo/announcer_mvm_engbot_arrive01.mp3",
    "vo/announcer_mvm_engbot_arrive02.mp3",
    "vo/announcer_mvm_engbot_arrive03.mp3"
};

static const char Two_Engineer_Spawn[][256] =
{
	"vo/announcer_mvm_engbot_another01.mp3",
	"vo/announcer_mvm_engbot_another02.mp3"
};

static const char Three_Pluss_Engineer_Spawn[][256] =
{
	"vo/announcer_mvm_engbots_arrive01.mp3",
	"vo/announcer_mvm_engbots_arrive02.mp3"
};


static const char EngBotDead_NoTele[][256] =
{
    "vo/announcer_mvm_engbot_dead_notele01.mp3",
	"vo/announcer_mvm_engbot_dead_notele02.mp3",
	"vo/announcer_mvm_engbot_dead_notele03.mp3"
};
static const char EngBotDead_Tele[][256] =
{
		"vo/announcer_mvm_engbot_dead_tele01.mp3",
		"vo/announcer_mvm_engbot_dead_tele02.mp3"
};

static const char HeavyBotSteps[][256] =
{
        ")mvm/giant_heavy/giant_heavy_step01.wav",
        ")mvm/giant_heavy/giant_heavy_step03.wav",
        ")mvm/giant_heavy/giant_heavy_step02.wav",
        ")mvm/giant_heavy/giant_heavy_step04.wav"
};

static const char DemoBotSteps[][256] =
{
        ")mvm/giant_demoman/giant_demoman_step_01.wav",
        ")mvm/giant_demoman/giant_demoman_step_03.wav",
        ")mvm/giant_demoman/giant_demoman_step_02.wav",
        ")mvm/giant_demoman/giant_demoman_step_04.wav"
};

static const char ScoutBotSteps[][256] =
{
        ")mvm/giant_scout/giant_scout_step_01.wav",
        ")mvm/giant_scout/giant_scout_step_03.wav",
        ")mvm/giant_scout/giant_scout_step_02.wav",
        ")mvm/giant_scout/giant_scout_step_04.wav"
};

static const char SoldierBotSteps[][256] =
{
    ")mvm/giant_soldier/giant_soldier_step01.wav",
    ")mvm/giant_soldier/giant_soldier_step03.wav",
    ")mvm/giant_soldier/giant_soldier_step02.wav",
    ")mvm/giant_soldier/giant_soldier_step04.wav"
};

static const char RegularBotSteps[][256] =
{
    "mvm/player/footsteps/robostep_01.wav",
    "mvm/player/footsteps/robostep_02.wav",
    "mvm/player/footsteps/robostep_03.wav",
    "mvm/player/footsteps/robostep_04.wav",
    "mvm/player/footsteps/robostep_05.wav",
    "mvm/player/footsteps/robostep_06.wav",
    "mvm/player/footsteps/robostep_07.wav",
    "mvm/player/footsteps/robostep_08.wav",
    "mvm/player/footsteps/robostep_09.wav",
    "mvm/player/footsteps/robostep_10.wav",
    "mvm/player/footsteps/robostep_11.wav",
    "mvm/player/footsteps/robostep_12.wav",
    "mvm/player/footsteps/robostep_13.wav",
    "mvm/player/footsteps/robostep_14.wav",
    "mvm/player/footsteps/robostep_15.wav",
    "mvm/player/footsteps/robostep_16.wav",
    "mvm/player/footsteps/robostep_17.wav",
    "mvm/player/footsteps/robostep_18.wav"
   
};

static const char GiantCommonBotSteps[][256] =
{
    "mvm/giant_common/giant_common_step_01.wav",
    "mvm/giant_common/giant_common_step_02.wav",
    "mvm/giant_common/giant_common_step_03.wav",
    "mvm/giant_common/giant_common_step_04.wav",
    "mvm/giant_common/giant_common_step_05.wav",
    "mvm/giant_common/giant_common_step_06.wav",
    "mvm/giant_common/giant_common_step_07.wav",
    "mvm/giant_common/giant_common_step_08.wav"
};

static const char SentryBusterCallOut[][256] =
{
    "vo/heavy_mvm_sentry_buster01.mp3",//SB ALERT
    "vo/heavy_mvm_sentry_buster02.mp3",//SB DOWN
    "vo/soldier_mvm_sentry_buster01.mp3",
    "vo/soldier_mvm_sentry_buster02.mp3",
    "vo/medic_mvm_sentry_buster01.mp3",
    "vo/medic_mvm_sentry_buster02.mp3",
    "vo/engineer_mvm_sentry_buster01.mp3",
    "vo/engineer_mvm_sentry_buster02.mp3"
};



public void OnMapStart()
{
    
    	//sound and model precaching should always be done in OnMapStart
	// int size = sizeof WaveVoiceLineStartSounds;
	// for (int i = 0; i < size; i++)
	// 	PrecacheSound(WaveVoiceLineStartSounds[i], true);
   
   	int size = sizeof Spy_Spawn;
	for (int i = 0; i < size; i++)
		PrecacheSound(Spy_Spawn[i], true);

   	size = sizeof One_Spy_Death;
	for (int i = 0; i < size; i++)
		PrecacheSound(One_Spy_Death[i], true);

   	size = sizeof One_Engineer_Spawn;
	for (int i = 0; i < size; i++)
		PrecacheSound(One_Engineer_Spawn[i], true);

    size = sizeof Two_Engineer_Spawn;
	for (int i = 0; i < size; i++)
		PrecacheSound(Two_Engineer_Spawn[i], true);

    size = sizeof Three_Pluss_Engineer_Spawn;
	for (int i = 0; i < size; i++)
		PrecacheSound(Three_Pluss_Engineer_Spawn[i], true);

    size = sizeof EngBotDead_NoTele;
	for (int i = 0; i < size; i++)
		PrecacheSound(EngBotDead_NoTele[i], true);

    size = sizeof EngBotDead_Tele;
	for (int i = 0; i < size; i++)
		PrecacheSound(EngBotDead_Tele[i], true);

    size = sizeof HeavyBotSteps;
	for (int i = 0; i < size; i++)
		PrecacheSound(HeavyBotSteps[i], true);

    size = sizeof DemoBotSteps;
	for (int i = 0; i < size; i++)
		PrecacheSound(DemoBotSteps[i], true);

    size = sizeof ScoutBotSteps;
	for (int i = 0; i < size; i++)
		PrecacheSound(ScoutBotSteps[i], true);
 
    size = sizeof RegularBotSteps;
	for (int i = 0; i < size; i++)
		PrecacheSound(RegularBotSteps[i], true);

    size = sizeof GiantCommonBotSteps;
	for (int i = 0; i < size; i++)
		PrecacheSound(GiantCommonBotSteps[i], true);

    size = sizeof SentryBusterCallOut;
	for (int i = 0; i < size; i++)
		PrecacheSound(GiantCommonBotSteps[i], true);

	PrecacheSound(GUNFIRE);
	PrecacheSound(GUNFIRE_CRIT);
	PrecacheSound(GUNFIRE_EXPLOSION);
	PrecacheSound(GUNFIRE_DEMO);
    
    PrecacheSound(")mvm/giant_pyro/giant_pyro_flamethrower_loop.wav");
    PrecacheSound(")mvm/giant_pyro/giant_pyro_flamethrower_start.wav");

    // PrecacheSound("bigjoey.wav");
    // PrecacheSound("later.wav");

    PrecacheScriptSound(ANNOUNCERWAVESTART);
    PrecacheScriptSound(ANNOUNCER_ALL_DEAD);
    PrecacheScriptSound(ANNOUNCER_ENGINEER_BOT_SPAWN);
    
    
    PrecacheSound(MVMSTART);

    PrecacheSound("music/mvm_start_wave.wav");
    PrecacheSound("music/mvm_end_tank_wave.wav");
    PrecacheSound(ANNOUNCER_ENGINEER_BOT_SPAWN);
    
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

	if (IsRobot(entity, "Saxtron")) //skip if saxtron
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

        char robotName[NAMELENGTH];
        GetRobot(entity, robotName, NAMELENGTH);
        Robot robot;
        GetRobotDefinition(robotName, robot);

    if (strncmp(sample, ")weapons/", 9, false) == 0) 
	{

        
//        PrintToChatAll("WEAPON SHOOTING! Robot was %s %s for %N",robot.name, robot.sounds.gunfire, GetClientOfUserId(entity));

    switch(robot.weaponsound)
    {
        case ROBOT_WEAPON_SOUND_ROCKETLAUNCHER:
        {
            if (StrContains(sample, "rocket_shoot.wav", false) != -1)
            {
                Format(sample, sizeof(sample), robot.sounds.gunfire);
                EmitSoundToAll(sample, entity);
              //  PrintToChatAll("EMITTED ROCKETSHOOT");
                
            }
            else if (StrContains(sample, "rocket_shoot_crit.wav", false) != -1)
            {
                Format(sample, sizeof(sample), robot.sounds.gunfire_crit);
                EmitSoundToAll(sample, entity);
             //   PrintToChatAll("EMITTED ROCKETSHOOT CRIT");
            }
        }
        case ROBOT_WEAPON_SOUND_GRENADELAUNCHER:
        {
            if (strncmp(sample, ")weapons/", 9, false) == 0)
            {
                if (StrContains(sample, "grenade_launcher_shoot.wav", false) != -1)
                {
                    Format(sample, sizeof(sample), robot.sounds.gunfire);
                    // PrintToChatAll("EMITTED GRENADE SHOOT");
                    EmitSoundToAll(sample, entity,_,_,_, 0.07);	
			        return Plugin_Changed;	
                }
                
            }
        }
    }

		
		//Explosion doesnæt quite work
		/* 		else if (StrContains(sample, "explode1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "explode2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "explode3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), GUNFIRE_EXPLOSION);
			EmitSoundToAll(sample, entity);
		} */
		return Plugin_Changed;
	}

    if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{       
        if (robot.footstep == ROBOT_FOOTSTEPS_CLASS)
        {        
            if (StrContains(sample, "1.wav", false) != -1)
            {
                switch(class)
                {
                    case TFClass_DemoMan:
                    {
                        EmitSoundToAll(DemoBotSteps[0], entity);
                    }
                    case TFClass_Heavy:
                    {
                        EmitSoundToAll(HeavyBotSteps[0], entity);
                    }
                    case TFClass_Scout:
                    {
                        EmitSoundToAll(ScoutBotSteps[0], entity);
                    }
                    case TFClass_Soldier:
                    {
                        EmitSoundToAll(SoldierBotSteps[0], entity);
                    }
                }
                
            }
            else if (StrContains(sample, "3.wav", false) != -1)
            {
                switch(class)
                {
                    case TFClass_DemoMan:
                    {
                        EmitSoundToAll(DemoBotSteps[1], entity);
                    }
                    case TFClass_Heavy:
                    {
                        EmitSoundToAll(HeavyBotSteps[1], entity);
                    }
                    case TFClass_Scout:
                    {
                        EmitSoundToAll(ScoutBotSteps[1], entity);
                    }
                    case TFClass_Soldier:
                    {
                        EmitSoundToAll(SoldierBotSteps[1], entity);
                    }
                }
            }
            else if (StrContains(sample, "2.wav", false) != -1)
            {
                switch(class)
                {
                    case TFClass_DemoMan:
                    {
                        EmitSoundToAll(DemoBotSteps[2], entity);
                    }
                    case TFClass_Heavy:
                    {
                        EmitSoundToAll(HeavyBotSteps[2], entity);
                    }
                    case TFClass_Scout:
                    {
                        EmitSoundToAll(ScoutBotSteps[2], entity);
                    }
                    case TFClass_Soldier:
                    {
                        EmitSoundToAll(SoldierBotSteps[2], entity);
                    }
                }
            }
            else if (StrContains(sample, "4.wav", false) != -1)
            {
                switch(class)
                {
                    case TFClass_DemoMan:
                    {
                        EmitSoundToAll(DemoBotSteps[3], entity);
                    }
                    case TFClass_Heavy:
                    {
                        EmitSoundToAll(HeavyBotSteps[3], entity);
                    }
                    case TFClass_Scout:
                    {
                        EmitSoundToAll(ScoutBotSteps[3], entity);
                    }
                    case TFClass_Soldier:
                    {
                        EmitSoundToAll(SoldierBotSteps[3], entity);
                    }
                }
            }
        }
        else if (robot.footstep == ROBOT_FOOTSTEP_NORMAL)
        { 
            int rand = GetRandomInt(1,18);
            Format(sample, sizeof(sample), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
			pitch = GetRandomInt(95, 100);
			EmitSoundToAll(sample, entity, _, _, _, 0.5, pitch);
			return Plugin_Changed;
        }
        else if (robot.footstep == ROBOT_FOOTSTEP_GIANTCOMMON)
        {   
            // int iActiveWeapon = GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");
            // int Weapon1 = GetPlayerWeaponSlot(entity, TFWeaponSlot_Primary);

            // if (iActiveWeapon == Weapon1 && !EveryOtherStep[entity])
            // { 
            //         EveryOtherStep[entity] = 1;
            // }else if(iActiveWeapon == Weapon1 && EveryOtherStep[entity])
            // {
            //     EveryOtherStep[entity] = 0;
            // }
        

            // if (iActiveWeapon != Weapon1)
            // {
            //     EveryOtherStep[entity] = 0;
            // }

            // if (!EveryOtherStep[entity])
            // {
                // PrintToChatAll("HOLDING PRIMARY");
                // PrintToChatAll("FOOTSTEP");
                int rand = GetRandomInt(1,8);
                Format(sample, sizeof(sample), "mvm/giant_common/giant_common_step_%s%i.wav", (rand < 10) ? "0" : "", rand);
                pitch = GetRandomInt(70, 85);
                EmitSoundToAll(sample, entity, _, _, _, 0.3, pitch);
                return Plugin_Changed;
                
            // }

        }

        
		return Plugin_Changed;
	}
// if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
    // if (strncmp(sample, ")weapons/", 9, false) == 0)
    // {
    //     if (StrContains(sample, "rocket_shoot.wav", false) != -1)
    //     {
    //         Format(sample, sizeof(sample), GUNFIRE);
    //         EmitSoundToAll(sample, entity);
            
    //     }
    //     else if (StrContains(sample, "rocket_shoot_crit.wav", false) != -1)
    //     {
    //         Format(sample, sizeof(sample), GUNFIRE_CRIT);
    //         EmitSoundToAll(sample, entity);
    //     }
    // }

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
    if (StrContains(sample, "mvm_spy", false) != -1)
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because 'mvm_spy' was not found in %s", sample);
		return Plugin_Continue;
	}
    if (StrContains(sample, "mvm_tank_alerts", false) != -1)
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because 'mvm_tank_alerts' was not found in %s", sample);
		return Plugin_Continue;
	}
    if (StrContains(sample, "engbot", false) != -1)
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because 'engbot' was not found in %s", sample);
		return Plugin_Continue;
	}
    if (StrContains(sample, "mvm_eng", false) != -1)
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because 'mvm_eng' was not found in %s", sample);
		return Plugin_Continue;
	}
    if (StrContains(sample, "mvm_", false) != -1)
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because 'mvm_wave' was not found in %s", sample);
		return Plugin_Continue;
	}
    if (StrContains(sample, "sentry_buster_alerts", false) != -1)
	{
		SMLogTag(SML_NormalSoundHook, "skipping SoundHook because 'sentry_buster_alerts' was not found in %s", sample);
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

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
    if (IsValidClient(client) && IsAnyRobot(client) && TF2_GetPlayerClass(client) == TFClass_Spy && condition == TFCond_Cloaked)
    {
        if(AnnounceWhenDecloak[client])
        {
        // PrintToChatAll("Spy Decloaked it was %N",client);
        int size = sizeof Spy_Spawn;
        int soundswitch = GetRandomInt(0, size - 1);
        // PrintToChatAll("Emitting %s", Spy_Spawn[soundswitch]);
	    EmitSoundToAll(Spy_Spawn[soundswitch]);
        AnnounceWhenDecloak[client] = false;
        }
    
    }
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
    if (IsValidClient(client) && condition == TFCond_Healing)
    {
        int iHP = GetClientHealth(client);
        if (iHP < 25){
           // PrintToChatAll("HEALING! %i", iHP);
                int iClass = TF2_GetPlayerClass(client);
                char szVO[512];
                switch(iClass)
                {
                    case TFClass_Heavy:
                    {
                        int digit = GetRandomInt(1,2);

                        Format(szVO, sizeof(szVO), "heavy_mvm_close_call0%i", digit);
                    }
                    case TFClass_Soldier:
                    {
                        strcopy(szVO, sizeof(szVO), "soldier_mvm_close_call01");
                    }
                    case TFClass_Engineer:
                    {
                        strcopy(szVO, sizeof(szVO), "engineer_mvm_close_call01");
                    }
                    default:
                        return;
                }

                float random_timer = GetRandomFloat(20.5,60.5);
                EmitSoundWithClamp(client, szVO, random_timer);
    }
        }
        
}


public Action Event_teamplay_round_win(Event event, const char[] name, bool dontBroadcast)
{

    int winteam = GetEventInt(event, "team");

  //  PrintToChatAll("Winning team was %i", winteam);
    CreateTimer(5.0, team_play_win_timer, winteam);
  
        
        //EmitGameSoundToAll("Announcer.mvm_spybot_death");

}

public Action team_play_win_timer (Handle timer, int winteam)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
        {
            SMLogTag(SML_VERBOSE, "team_play_win_timer ignored for %i, because the client is not valid", i);
            continue;
        }  
        if (!IsClientInGame(i))
        {
            SMLogTag(SML_VERBOSE, "team_play_win_timer ignored for %i, because the client is not ingame", i);
            continue;
        }  
        if (IsAnyRobot(i))
        {
            SMLogTag(SML_VERBOSE, "team_play_win_timer ignored for %i, because the client is a robot", i);
            continue;
        }  
        if (!IsPlayerAlive(i))
        {
            SMLogTag(SML_VERBOSE, "team_play_win_timer ignored for %i, because the client is not alive", i);
            continue;
        }  

        PlayRobotRoundFinishVoiceOver(i, winteam);
    }
}


public Action Event_teamplay_setup_finished(Event event, const char[] name, bool dontBroadcast)
{
    
    
    // int size = sizeof WaveVoiceLineStartSounds;
    // int soundswitch = GetRandomInt(0, size - 1);
	// EmitSoundToAll(WaveVoiceLineStartSounds[soundswitch]);
	// for(int i = 1; i <= MaxClients+1; i++)
	// {
	// 	if(IsValidClient(i))
	// 	{
    //         EmitSoundToClient(i,WaveVoiceLineStartSounds[soundswitch]);
    //         EmitGameSoundToClient(i,WaveVoiceLineStartSounds[soundswitch]);
            
    //         //EmitSoundToAll("Announcer.MVM_Wave_Start");
	// 		//DHookEntity(g_hIsDeflectable, false, i);
	// 	}
	// }

    
    EmitGameSoundToAll(ANNOUNCERWAVESTART);
    // EmitSoundToAll(WaveVoiceLineStartSounds[soundswitch]);

    // EmitSoundToAll(MVMSTART);
    //EmitGameSoundToAll(MVMSTART, _, _, );

    // EmitSoundToAll(WAVESTART);

        for(int i = 1; i <= MAXPLAYERS+1; i++)
        {
            if (IsValidClient(i) && !IsFakeClient(i))
            {
                EmitSoundToClient(i,WAVESTART);
            }
        }

    CreateTimer(5.0, Event_teamplay_setup_finished_timer);
    
        
        //EmitGameSoundToAll("Announcer.mvm_spybot_death");

}

public Action Event_teamplay_setup_finished_timer (Handle timer)
{
    SMLogTag(SML_VERBOSE, "Event_teamplay_setup_finished called");
    if(!IsActive())
    {
        SMLogTag(SML_VERBOSE, "Event_teamplay_setup_finished ignored, because robo-mode is not active");
        return;
    }  

    for(int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
        {
            SMLogTag(SML_VERBOSE, "Event_teamplay_setup_finished ignored for %i, because the client is not valid", i);
            continue;
        }  
        if (!IsClientInGame(i))
        {
            SMLogTag(SML_VERBOSE, "Event_teamplay_setup_finished ignored for %i, because the client is not ingame", i);
            continue;
        }  
        if (IsAnyRobot(i))
        {
            SMLogTag(SML_VERBOSE, "Event_teamplay_setup_finished ignored for %i, because the client is a robot", i);
            continue;
        }  
        if (!IsPlayerAlive(i))
        {
            SMLogTag(SML_VERBOSE, "Event_teamplay_setup_finished ignored for %i, because the client is not alive", i);
            continue;
        }  

        if (!MM_Random(1,2))
        {
            SMLogTag(SML_VERBOSE, "Event_teamplay_setup_finished ignored for %i, because random says no", i);
            continue;
        }  

        
        PlayRobotRoundStartVoiceOver(i);
        
        //EmitGameSoundToAll("Announcer.mvm_spybot_death");
    }
}

int g_robot_kill_count = 0;
int g_robot_kill_voiceline_requirement = 2;
float g_robot_death_timer = 5.0;
float g_robot_deathtime = 0.0;


public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int assister = GetClientOfUserId(GetEventInt(event, "assister"));

   // SMLogTag(SML_VERBOSE, "Event_Death triggerd with attacker %L, assister %L and victim %L", attacker, assister, victim);
    // PrintToChatAll("Pre Class was: %i,", TF2_GetPlayerClass(victim));
    //Robot died
    if (IsAnyRobot(victim)){
        
        char robotName[NAMELENGTH];
        GetRobot(victim, robotName, NAMELENGTH);
        if(robotName[0] == '\0')
        {
            SMLogTag(SML_VERBOSE, "skipped Event_Death, because %L is no robot in voicelines", victim);
            return;
        }

        Robot item;
        GetRobotDefinition(robotName, item);
        EmitSoundToAll(item.sounds.death, victim);
    }
    if (IsAnyRobot(victim))
	{
        //On the first kill
        if (g_robot_kill_count == 0){

            g_robot_deathtime = GetEngineTime() + g_robot_death_timer;
        }

        g_robot_kill_count++;

        AnnounceWhenDecloak[victim] = true;
	}

    if (IsAnyRobot(victim) && attacker != victim)
    {
        PlayRobotDeathVoiceOver(attacker, victim);
        PlayRobotDeathVoiceOver(assister, victim);
    }


    //player died to robot
    if (!IsAnyRobot(victim) && IsAnyRobot(attacker))
    {
        int iTeam = GetClientTeam(victim);
        PlayRobotKilledFriendVoiceOver(iTeam);
    }

    //Plays spy alert when the spy dies
	if (IsAnyRobot(victim) && TF2_GetPlayerClass(victim) == TFClass_Spy/*  && !b_AnnounceClamp */)
	{
        int iSpyCount = GetRobotClassCount(TFClass_Spy);
        // PrintToChatAll("EMITTING SPY DEATH. There was %i spies on death",iSpyCount);
        int size = sizeof One_Spy_Death;
        int soundswitch;

        //Spycount offset by +1 since change happens on the frame after
        if (iSpyCount == 1)
        {
            soundswitch = GetRandomInt(0, 6);
            EmitSoundToAll(One_Spy_Death[soundswitch]);
        }
        if (iSpyCount == 2)
        {
            EmitSoundToAll(One_Spy_Death[12]);
        }
        if (iSpyCount == 3)
        {
            EmitSoundToAll(One_Spy_Death[11]);
        }
        if (iSpyCount == 4)
        {
            EmitSoundToAll(One_Spy_Death[10]);
        }
        if (iSpyCount == 5)
        {
            EmitSoundToAll(One_Spy_Death[9]);
        }
        if (iSpyCount == 6)
        {
            EmitSoundToAll(One_Spy_Death[8]);
        }
        if (iSpyCount == 7)
        {
            EmitSoundToAll(One_Spy_Death[7]);
        }
        // EmitGameSoundToAll();
	}

    //teamwipe logic
	// if (!g_bDoTeamWipe) return;
	
	if (GetClientCount() >= 10) // let's only play this sound if there's at least 10 people in the game
	{
        int deadplayers;
        int totalplayers;
        int team = GetClientTeam(victim);

            deadplayers = GetTeamMateDeadCount(team);
            totalplayers = GetTeamClientCount(team);
			// g_bDoTeamWipe = false;
            //EmitGameSoundToAll(ANNOUNCER_ALL_DEAD);
            //PrintToChatAll("Dead players %i. Total players %i", deadplayers, totalplayers);
           if (deadplayers == totalplayers) 
           {
               EmitGameSoundToAll(ANNOUNCER_ALL_DEAD);
           }
            // PrintToChatAll("HOw could you all die 2?");


		// if (!g_bDoTeamWipe) CreateTimer(5.0, Timer_TeamWipeCooldown, _, TIMER_FLAG_NO_MAPCHANGE); // put a cooldown on this just in case it somehow gets spammed
	}

    if (IsRobotEngineer(victim) && !b_AnnounceClamp)
    {
        //PrintToChatAll("ROBOT ENGI DEAD!");
        if(HasTeleporter(victim))
        {
            //PrintToChatAll("Teleporter found! %N", client);
            
            int soundswitch = GetRandomInt(0, 1);
            EmitSoundToAll(EngBotDead_Tele[soundswitch]);


        }else
        {
            //PrintToChatAll("No teleporters found! for %N", client);
            int size = sizeof EngBotDead_NoTele;
            int soundswitch = GetRandomInt(0, size - 1);
            EmitSoundToAll(EngBotDead_NoTele[soundswitch]);
        }
    }

        // g_robot_deathtime = GetEngineTime() + g_robot_death_timer;
	    // g_robot_kill_count++;

	if (IsAnyRobot(victim) && TF2_GetPlayerClass(victim) != TFClass_Spy && !IsRobotEngineer(victim) 
    && g_robot_kill_count >= g_robot_kill_voiceline_requirement && g_robot_deathtime >= GetEngineTime())
	{
        // PrintToChatAll("Saying voicelin killcount was %i", g_robot_kill_count);
        AnnouncerSayDeathVoiceline();
        g_robot_kill_count = 0;
    }
	

        //Plays engineer alert when the engineer bot is dead
	// if (IsAnyRobot(victim) && TF2_GetPlayerClass(victim) == TFClass_Engineer)
	// {
	// EmitGameSoundToAll("Announcer.mvm_an_engineer_bot_is_Dead");
    
	// }
}
float g_time_said = 0.0;
float g_announcer_voice_clamp;
void AnnouncerSayDeathVoiceline()
{
    g_announcer_voice_clamp = GetRandomFloat(10.0, 20.0);
    
    if (g_time_said < GetEngineTime())
    {
    EmitGameSoundToAll("Announcer.MVM_General_Destruction");
    g_time_said = GetEngineTime() + g_announcer_voice_clamp;
    
    }

    
}

public Action Event_player_escort_score(Event event, char[] name, bool dontBroadcast)
{   
    SMLogTag(SML_VERBOSE, "Event_player_escort_score called");
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

    PlayRobotTakeDamageVoiceOver(attacker, iClassAttacker, victim, weapon);

    return Plugin_Continue;
}

void PlayRobotDeathVoiceOver(int client, int victim)
{
    if (!IsValidClient(client))
    {
        SMLogTag(SML_VERBOSE, "PlayRobotDeathVoiceOver ignored, because client %i was not a valid client", client);
        return;
    }

    SMLogTag(SML_VERBOSE, "PlayRobotDeathVoiceOver for %L", client);

    TFClassType class = TF2_GetPlayerClass(client);
    char szVO[512];
    int iNumber = 1;
    int digit;
    switch(class)
    {
        case TFClass_Heavy:
        {
           //Format(szVO, sizeof(szVO), "heavy_mvm_giant_robot02");
            if(IsTank(victim))
            {
            Format(szVO, sizeof(szVO), "heavy_mvm_tank_dead01");
            }else
            {
            char voiceline[][] = {"heavy_mvm_taunt01", "heavy_mvm_taunt02", "heavy_mvm_giant_robot02"}; 
            digit = GetRandomInt(0,2);
            Format(szVO, sizeof(szVO), "%s", voiceline[digit]);
            } 

            if(IsSentryBuster(victim))
            {

                Format(szVO, sizeof(szVO), "%s", "heavy_mvm_sentry_buster02");
            } 
        }
        case TFClass_Medic:
        {
            Format(szVO, sizeof(szVO), "medic_mvm_giant_robot02");

            if(IsSentryBuster(victim))
            {

                Format(szVO, sizeof(szVO), "%s", "medic_mvm_sentry_buster02");
            } 
        }
        case TFClass_Soldier:
        {
            if(TF2_GetPlayerClass(victim) != TFClass_Heavy)
            {
                iNumber = GetRandomInt(1,5);
            }else
            {
                iNumber = 6;
            }
            Format(szVO, sizeof(szVO), "soldier_mvm_taunt0%i", iNumber);

            if(IsTank(victim))
            {
                iNumber = GetRandomInt(1,2);
                Format(szVO, sizeof(szVO), "soldier_mvm_tank_dead0%i", iNumber);
            }

            if(IsSentryBuster(victim))
            {

                Format(szVO, sizeof(szVO), "%s", "soldier_mvm_sentry_buster02");
            } 
        }
        case TFClass_Engineer:
        {
            if(IsTank(victim))
            {
            Format(szVO, sizeof(szVO), "engineer_mvm_tank_dead01");
            }else{
            int Random = GetRandomInt(1,2);             
            Format(szVO, sizeof(szVO), "engineer_mvm_taunt0%i", Random);
            }
            if(IsSentryBuster(victim))
            {
                Format(szVO, sizeof(szVO), "%s", "engineer_mvm_sentry_buster02");
            } 
        }
        case TFClass_Scout:
        {
            char voiceline[][] = {"scout_mvm_loot_rare04", "scout_mvm_loot_rare06", "scout_mvm_loot_rare07", "scout_mvm_loot_rare08"}; 
            digit = GetRandomInt(0,3);
            Format(szVO, sizeof(szVO), "%s", voiceline[digit]);
        }


        default:
            return;
    }
    
    if(IsPlayerAlive(client))
    {
         EmitGameSoundToAll(szVO, client);
    }
}

void PlayRobotKilledFriendVoiceOver(int Team)
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
        
        TFClassType class = TF2_GetPlayerClass(i);
        int iTeam = GetClientTeam(i);

        //PrintToChatAll("Random! %i", MM_Random(1,3));

        char szVO[512];
        if (class == TFClass_Heavy && iTeam == Team){
        
            if (MM_Random(1,3))
            {
            
                SMLogTag(SML_VERBOSE, "PlayRobotKilledFriendVoiceOver for %L", i);
                
                strcopy(szVO, sizeof(szVO), "heavy_mvm_giant_robot01");
                
               // PrintToChatAll("%N was Heavy class and said voiceline", i);
                float random_timer = GetRandomFloat(10.5,30.5);
                EmitSoundWithClamp(i, szVO, random_timer);
            }
        }
    }
}

void PlayRobotRoundFinishVoiceOver(int clientId, int winteam)
{
    SMLogTag(SML_VERBOSE, "PlayRobotRoundFinishVoiceOver for %L", clientId);

    TFClassType iClass = TF2_GetPlayerClass(clientId);
    bool isSpyDisguised = iClass == TFClass_Spy && TF2_IsPlayerInCondition(clientId, TFCond_Disguised);
    if (isSpyDisguised)
    {
        iClass = view_as<TFClassType>(GetEntProp(clientId, Prop_Send, "m_nDisguiseClass"));
    }
    int iTeam = GetClientTeam(clientId);

    
    char szVO[512];
    if (iTeam == winteam){
    //If you won the round
    
    switch(iClass)
    {
        case TFClass_Heavy:
        {
            int digit = GetRandomInt(1,5);
            Format(szVO, sizeof(szVO), "heavy_mvm_wave_end0%i", digit);
        }
        case TFClass_Medic:
        {
            int digit = GetRandomInt(1,3);
            Format(szVO, sizeof(szVO), "medic_mvm_wave_end0%i", digit);
        }
        case TFClass_Soldier:
        {
            int digit = GetRandomInt(1,7);
            Format(szVO, sizeof(szVO), "soldier_mvm_wave_end0%i", digit);
        }
        case TFClass_Engineer:
        {
            int digit = GetRandomInt(1,3);
            Format(szVO, sizeof(szVO), "engineer_mvm_wave_end0%i", digit);
        }
        default:
            return;
    }
    }else{
        //If you lost the round
         switch(iClass)
    {
        // case TFClass_Heavy:
        // {
        //     strcopy(szVO, sizeof(szVO), "heavy_mvm_stand_alone02");
        // }
        case TFClass_Medic:
        {
            int digit = GetRandomInt(4,7);
            Format(szVO, sizeof(szVO), "medic_mvm_wave_end0%i", digit);
        }
        case TFClass_Soldier:
        {
            int digit = GetRandomInt(8,10);
            if (digit != 10){
            Format(szVO, sizeof(szVO), "soldier_mvm_wave_end0%i", digit);
            }else{
                Format(szVO, sizeof(szVO), "soldier_mvm_wave_end%i", digit);
            }
        }
        case TFClass_Engineer:
        {
            int digit = GetRandomInt(4,7);
            Format(szVO, sizeof(szVO), "engineer_mvm_wave_end0%i", digit);
        }
        default:
            return;
    } 
    }

    float random_timer = GetRandomFloat(20.5,60.5);
    EmitSoundWithClamp(clientId, szVO, random_timer);

}

void PlayRobotRoundStartVoiceOver(int clientId)
{
    SMLogTag(SML_VERBOSE, "PlayRobotRoundStartVoiceOver for %L", clientId);

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
            strcopy(szVO, sizeof(szVO), "heavy_mvm_stand_alone02");
        }
        case TFClass_Medic:
        {
            strcopy(szVO, sizeof(szVO), "medic_mvm_stand_alone01");
        }
        case TFClass_Soldier:
        {
            int digit = GetRandomInt(1,2);
            Format(szVO, sizeof(szVO), "soldier_mvm_stand_alone0%i", digit);
        }
        case TFClass_Engineer:
        {
            strcopy(szVO, sizeof(szVO), "engineer_mvm_wave_start01");
        }
        default:
            return;
    }

    float random_timer = GetRandomFloat(20.5,60.5);
    EmitSoundWithClamp(clientId, szVO, random_timer);
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

    float random_timer = GetRandomFloat(20.5,60.5);
    EmitSoundWithClamp(clientId, szVO, random_timer);
}

void PlayRobotTakeDamageVoiceOver(int attackerClientId, TFClassType attackerClass, int victimClientId, int weapon)
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

            //Format(szVO, sizeof(szVO), "medic_mvm_giant_robot01");
            if(IsTank(victimClientId))
            {
            char voiceline[][] = {"heavy_mvm_tank_alert01", "heavy_mvm_tank_alert02", "heavy_mvm_tank_alert03"}; 
            digit = GetRandomInt(0,2);
            Format(szVO, sizeof(szVO), "%s", voiceline[digit]);
            
            }

            if(IsSentryBuster(victimClientId))
            {

                Format(szVO, sizeof(szVO), "%s", "heavy_mvm_sentry_buster01");
            }
                
        }
        case TFClass_Medic:
        {
            Format(szVO, sizeof(szVO), "medic_mvm_giant_robot01");
            if(IsTank(victimClientId))
            {
            char voiceline[][] = {"medic_mvm_tank_alert01", "medic_mvm_tank_shooting01", "medic_mvm_tank_shooting02","medic_mvm_tank_shooting03"}; 
            digit = GetRandomInt(0,3);
            
            Format(szVO, sizeof(szVO), "%s", voiceline[digit]);
            }

            int MeleeWeapon = GetPlayerWeaponSlot(attackerClientId, TFWeaponSlot_Melee);

            if (MeleeWeapon == weapon)
            {
                Format(szVO, sizeof(szVO), "medic_mvm_taunt01");
            }

            if (IsSentryBuster(victimClientId))
            {
                Format(szVO, sizeof(szVO), "%s", "medic_mvm_sentry_buster01");
            }
            
        }
        case TFClass_Soldier:
        {
            if(IsTank(victimClientId))
            {
                char voiceline[][] = {"soldier_mvm_tank_shooting01", "soldier_mvm_tank_shooting02", "soldier_mvm_tank_alert01", "soldier_mvm_tank_alert02"}; 
                digit = GetRandomInt(0,3);
                
                Format(szVO, sizeof(szVO), "%s", voiceline[digit]);
            }else
            {
            char voiceline[][] = {"soldier_mvm_giant_robot01", "soldier_mvm_giant_robot02", "soldier_mvm_tank_shooting03"}; 
            digit = GetRandomInt(0,2);
            Format(szVO, sizeof(szVO), "%s", voiceline[digit]);
            
            }

            if (IsSentryBuster(victimClientId))
            {
                Format(szVO, sizeof(szVO), "%s", "soldier_mvm_sentry_buster01");
            }
        }
        case TFClass_Engineer:
        {
            if(IsTank(victimClientId))
            {           
            char voiceline[][] = {"engineer_mvm_tank_alert01", "engineer_mvm_tank_shooting01"}; 
            digit = GetRandomInt(0,1);
            Format(szVO, sizeof(szVO), "%s", voiceline[digit]);                    
            }
            else{
            digit = GetRandomInt(1,2);
            Format(szVO, sizeof(szVO), "engineer_mvm_giant_robot0%i", digit);
            }

            if (IsSentryBuster(victimClientId))
            {
                Format(szVO, sizeof(szVO), "%s", "engineer_mvm_sentry_buster01");
            }
        
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
   // PrintToChatAll("For %N",client);
    CreateTimer(clamp, calltimer_reset, client);
    g_VoiceCalloutClamp[client] = true;
}

public Action calltimer_reset (Handle timer, int client)
{
	g_VoiceCalloutClamp[client] = false;
}





public Action Event_post_inventory_application(Event event, const char[] name, bool dontBroadcast)
{

    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    CreateTimer(1.0, Timer_CheckSpawnAnnouncement, client);

    if(IsAnyRobot(client))
    {
        RequestFrame(SetSpawnPitchSound,client);
        // RequestFrame(TrackRobotSpies, client);
    }
}

// void TrackRobotSpies(int client)
// {
//     if(TF2_GetPlayerClass(client) == TFClass_Spy)
//     {
//         // PrintToChatAll("Spy Spawn it was %N", client);
//     }
// }

void SetSpawnPitchSound(int client)
{
    if(IsAnyRobot(client))
    {
        if(TF2_GetPlayerClass(client) == TFClass_Engineer || TF2_GetPlayerClass(client) == TFClass_Sniper || TF2_GetPlayerClass(client) == TFClass_Medic || TF2_GetPlayerClass(client) == TFClass_Spy)
        {
            TF2Attrib_SetByName(client, "voice pitch scale", 0.9);
        }else
        {
            TF2Attrib_SetByName(client, "voice pitch scale", 1.0);
        }
        
    }
}

public Action Timer_CheckSpawnAnnouncement(Handle timer, int client)
{
    if(IsClientInGame(client) && IsPlayerAlive(client) && !b_AnnounceClamp)
    {

        if (IsAnyRobot(client) && !b_AnnounceClamp)
        {
            switch(TF2_GetPlayerClass(client))
            {
                case TFClass_Engineer:
                {
                    CreateTimer(3.0, Timer_EngiCheck, GetRobotClassCount(TFClass_Engineer));
                    b_AnnounceClamp = true;
                }
                // case TFClass_Spy:
                // {
                //     CreateTimer(3.0, Timer_SpyCheck, GetRobotClassCount(TFClass_Spy));
                //     b_AnnounceClamp = true;
                // }
            }
        }

        if (IsTank(client) && !b_AnnounceClamp)
        {
            CreateTimer(3.0, Timer_TankCheck);
            b_AnnounceClamp = true;
        }
    }
}

int GetRobotClassCount(int class)
{
    int classcount = 0;

    for(int i = 1; i <= MaxClients; i++)
    {
        if (IsAnyRobot(i))
        {                        
            if (TF2_GetPlayerClass(i) == class)
            {
                classcount++;
               
            }
        }
    }
    return classcount;
}

public Action Timer_SpyCheck(Handle timer, int spycount)
{
	int size = sizeof Spy_Spawn;
    int soundswitch = GetRandomInt(0, size - 1);
    // PrintToChatAll("Emitting %s", Spy_Spawn[soundswitch]);
	EmitSoundToAll(Spy_Spawn[soundswitch]);
    b_AnnounceClamp = false;
	
}

public Action Timer_EngiCheck(Handle timer, int engineercount)
{
    if (engineercount == 1)
    {
        int size = sizeof One_Engineer_Spawn;
        int soundswitch = GetRandomInt(0, size - 1);
	    EmitSoundToAll(One_Engineer_Spawn[soundswitch]);
        // EmitGameSoundToAll(ANNOUNCER_ENGINEER_BOT_SPAWN);
        // EmitSoundToAll(ANNOUNCER_ENGINEER_BOT_SPAWN);
    }
    if (engineercount == 2)
    {
        int size = sizeof Two_Engineer_Spawn;
        int soundswitch = GetRandomInt(0, size - 1);
	    EmitSoundToAll(Two_Engineer_Spawn[soundswitch]);
    }

    if (engineercount >= 3)
    {
        int size = sizeof Three_Pluss_Engineer_Spawn;
        int soundswitch = GetRandomInt(0, size - 1);
	    EmitSoundToAll(Three_Pluss_Engineer_Spawn[soundswitch]);
    }

     //PrintToChatAll("Engineer count was: %i", engineercount);
    b_AnnounceClamp = false;
}

public Action Timer_TankCheck(Handle timer)
{
    int TankCount = 0;
    int robotcount = 0;

    for(int i = 1; i <= MaxClients; i++)
    {
        if (IsTank(i))
        {
            // if(g_cv_bDebugMode)PrintToChatAll("%N was a tank", i);
            TankCount++;
        }
        if (IsAnyRobot(i))
        {
            robotcount++;

        }
    }

    //PrintToChatAll("Tank count was %i\nRobot count was %i", TankCount, robotcount);


        if (TankCount == 1)
        {
            EmitGameSoundToAll("Announcer.MVM_Tank_Alert_Spawn");
        }

        if (TankCount == 2)
        {
            EmitGameSoundToAll("Announcer.MVM_Tank_Alert_Another");
        }

        if (TankCount > 2)
        {
            EmitGameSoundToAll("Announcer.MVM_Tank_Alert_Multiple");
        }

  
     if (TankCount == robotcount - 1)
    {
        for(int i = 1; i <= MAXPLAYERS+1; i++)
        {

            if (IsValidClient(i) && !IsFakeClient(i))
            {

                // EmitSoundToClient(i,"#*music/mvm_end_tank_wave.wav");
                EmitSoundToClient(i,"music/mvm_end_tank_wave.wav");

                // PrintToChat(i,"Playing sound %s to %N ", BOSSTUNE, i);
            }
        }
    }

    // if(g_cv_bDebugMode)PrintToChatAll("Tank count was %i", TankCount);
    b_AnnounceClamp = false;
}

// bool g_bDoTeamWipe = true;

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	
}

bool IsRobotEngineer(int client)
{
    if (TF2_GetPlayerClass(client) == TFClass_Engineer && IsAnyRobot(client))
    {
        return true;
    }
    return false;
}

bool IsRobotSpy(int client)
{
    if (TF2_GetPlayerClass(client) == TFClass_Spy && IsAnyRobot(client))
    {
        return true;
    }
    return false;
}

bool HasTeleporter(int client)
{
        int team = TF2_GetClientTeam(client);
        int ent = -1;
        int tele;

	while ((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != team)
			continue;
		if (GetEntProp(ent, Prop_Send, "m_bCarried"))	// If being carried
			continue;
		if (GetEntProp(ent, Prop_Send, "m_iObjectMode") != 1)	// If not exit
			continue;

			tele = ent;
	}
	// If no teleporters found
	//if (GetVectorDistance(vecIsActuallyGoingToSpawn, vecSpawns[i]) >= 70000)
	if (!tele)
	{
		return false;
	}
	return true;
}


// public Action Timer_TeamWipeCooldown(Handle hTimer)
// {
// 	g_bDoTeamWipe = true;
// }

stock int GetTeamMateDeadCount(int team)
{
	int players_team = 1;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team && !IsPlayerAlive(i) && !IsAnyRobot(i))
			players_team++;
	}
    //PrintToChatAll("player teamz %i", players_team);
	return players_team;
}

bool Locked1[MAXPLAYERS+1];
bool Locked2[MAXPLAYERS+1];
bool Locked3[MAXPLAYERS+1];
bool CanWindDown[MAXPLAYERS+1];

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (IsValidClient(client) && IsAnyRobot(client) && IsPlayerAlive(client) && GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) != -1 && (TF2_GetPlayerClass(client) == TFClass_Heavy || TF2_GetPlayerClass(client) == TFClass_Pyro))
	{	

        char robotName[NAMELENGTH];
        GetRobot(client, robotName, NAMELENGTH);
        Robot robot;
        GetRobotDefinition(robotName, robot);
        int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
        
        // PrintToChatAll("WEAPON SHOOTING! %i for %N\nRobot Sounds %s",robot.weaponsound, client, robot.sounds.gunfire);
// PrintToChatAll("WEAPON SHOOTING! %i for %N",robot.weaponsound, client);
    //MINIGUN 
    if (robot.weaponsound == ROBOT_WEAPON_SOUND_MINIGUN)
    {
        
        
        if (HasEntProp(weapon, Prop_Send, "m_iWeaponState"))
        {
            if(IsValidEntity(weapon))//850 == deflector
            {
                int iWeaponState = GetEntProp(weapon, Prop_Send, "m_iWeaponState");
                if (iWeaponState == 1 && !Locked1[client])
                {
                    EmitSoundToAll(robot.sounds.windup, client);
                //	PrintToChatAll("WeaponState = Windup");
                    
                    Locked1[client] = true;
                    Locked2[client] = false;
                    Locked3[client] = false;
                    CanWindDown[client] = true;
                    
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.gunspin);
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.gunfire);
                }
                else if (iWeaponState == 2 && !Locked2[client])
                {
                    EmitSoundToAll(robot.sounds.gunfire, client);
                //	PrintToChatAll("WeaponState = Firing");
                    
                    Locked2[client] = true;
                    Locked1[client] = true;
                    Locked3[client] = false;
                    CanWindDown[client] = true;
                    
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.gunspin);
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.windup);
                }
                else if (iWeaponState == 3 && !Locked3[client])
                {
                    EmitSoundToAll(robot.sounds.gunspin, client);
                //	PrintToChatAll("WeaponState = Spun Up");
                    
                    Locked3[client] = true;
                    Locked1[client] = true;
                    Locked2[client] = false;
                    CanWindDown[client] = true;
                    
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.gunfire);
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.windup);
                }
                else if (iWeaponState == 0)
                {
                    if (CanWindDown[client])
                    {
                //		PrintToChatAll("WeaponState = WindDown");
                        EmitSoundToAll(robot.sounds.winddown, client);
                        CanWindDown[client] = false;
                    }
                    
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.gunspin);
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.gunfire);
                    
                    Locked1[client] = false;
                    Locked2[client] = false;
                    Locked3[client] = false;
                }
            }
        }
	}


    //Flamethrower
    if (robot.weaponsound == ROBOT_WEAPON_SOUND_FLAMETHROWER)
    {
        if(IsValidEntity(weapon))
            {
                int iWeaponState = GetEntProp(weapon, Prop_Send, "m_iWeaponState");
                if (iWeaponState == 1 && !Locked1[client])
                {
                    EmitSoundToAll(robot.sounds.windup, client);
                //	PrintToChatAll("WeaponState = Windup");
                    
                    Locked1[client] = true;
                    Locked2[client] = false;
                    Locked3[client] = false;
                    CanWindDown[client] = true;
                    
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.gunfire);
                }
                else if (iWeaponState == 2 && !Locked2[client])
                {
                    EmitSoundToAll(robot.sounds.gunfire, client);
                //	PrintToChatAll("WeaponState = Firing");
                    
                    Locked2[client] = true;
                    Locked1[client] = true;
                    Locked3[client] = false;
                    CanWindDown[client] = true;
                    
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.windup);
                }
                else if (iWeaponState == 3 && !Locked3[client])
                {

                //	PrintToChatAll("WeaponState = Spun Up");
                    
                    Locked3[client] = true;
                    Locked1[client] = true;
                    Locked2[client] = false;
                    CanWindDown[client] = true;
                    
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.gunfire);
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.windup);
                }
                else if (iWeaponState == 0)
                {
                    if (CanWindDown[client])
                    {
                //		PrintToChatAll("WeaponState = WindDown");

                        CanWindDown[client] = false;
                    }
                    
                    StopSound(client, SNDCHAN_AUTO, robot.sounds.gunfire);
                    
                    Locked1[client] = false;
                    Locked2[client] = false;
                    Locked3[client] = false;
                }
            }
        }


	}
	return Plugin_Continue;
}