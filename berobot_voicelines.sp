#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sm_logger>
#include <berobot_constants>

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
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


public void OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_ERROR, SML_FILE);
	SMLogTag(SML_INFO, "berobot_voicelines started at %i", GetTime());
	AddNormalSoundHook(NormalSoundHook);
}

public Action NormalSoundHook(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (!IsValidClient(entity)) 
	{
		SMLogTag(SML_VERBOSE, "skipping SoundHook because client %i is not valid", entity);
		return Plugin_Continue;
	}

	SMLogTag(SML_VERBOSE, "playing sound %s for %L at volume %f", sample, entity, volume);

	if (!IsAnyRobot(entity)) //skip if no robot is picked
	{
		SMLogTag(SML_VERBOSE, "skipping SoundHook because %L is not a robot", entity);
		return Plugin_Continue;
	}
	
	if (volume == 0.0 || volume == 0.9997)
	{
		SMLogTag(SML_VERBOSE, "skipping SoundHook because volume is set to %f", volume);
		return Plugin_Continue;
	}
	TFClassType class = TF2_GetPlayerClass(entity);

	if (StrContains(sample, "vo/", false) == -1)
	{
		SMLogTag(SML_VERBOSE, "skipping SoundHook because 'vo/' was not found in %s", sample);
		return Plugin_Continue;
	}
	if (StrContains(sample, "announcer", false) != -1)
	{
		SMLogTag(SML_VERBOSE, "skipping SoundHook because 'announcer' was not found in %s", sample);
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

	SMLogTag(SML_VERBOSE, "turned sample into %s", sample);
	PrecacheSound(sample);
	return Plugin_Changed;
}