#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
#include <morecolors>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Gambler"

#define sJackpotLine	"vo/mvm/norm/spy_mvm_laughlong01.mp3"
#define sSpawnSound		"misc/halloween/hwn_wheel_of_fate.wav"	
#define sPositive "ui/mm_xp_chime.wav"
#define sNegative "ambient/bumper_car_quack11.wav"
static const char Gambler_Positive[][256] =
{
	"vo/mvm/norm/spy_mvm_autocappedintelligence01.mp3",
	"vo/mvm/norm/spy_mvm_autocappedcontrolpoint03.mp3",
	"vo/mvm/norm/spy_mvm_positivevocalization01.mp3",
	"vo/mvm/norm/spy_mvm_positivevocalization02.mp3",
    "vo/mvm/norm/spy_mvm_positivevocalization03.mp3",
	"vo/mvm/norm/spy_mvm_positivevocalization04.mp3",
	"vo/mvm/norm/spy_mvm_positivevocalization05.mp3",
	"vo/mvm/norm/spy_mvm_cheers04.mp3",
	"vo/mvm/norm/spy_mvm_cheers01.mp3",
	"vo/mvm/norm/spy_mvm_cheers07.mp3"
};

static const char Gambler_Neutral[][256] =
{
    "vo/mvm/norm/spy_mvm_negativevocalization04.mp3",
	"vo/mvm/norm/spy_mvm_negativevocalization03.mp3",
	"vo/mvm/norm/spy_mvm_autodejectedtie03.mp3"
};

static const char Gambler_Negative[][256] =
{
    "vo/mvm/norm/spy_mvm_paincrticialdeath01.mp3",
	"vo/mvm/norm/spy_mvm_autodejectedtie02.mp3",
	"vo/mvm/norm/spy_mvm_jaratehit06.mp3",
	"vo/mvm/norm/spy_mvm_jaratehit01.mp3",
	"vo/mvm/norm/spy_mvm_jeers01.mp3",
	"vo/mvm/norm/spy_mvm_jeers02.mp3",
	"vo/mvm/norm/spy_mvm_jeers03.mp3",
	"vo/mvm/norm/spy_mvm_jeers04.mp3",
	"vo/mvm/norm/spy_mvm_jeers05.mp3",
	"vo/mvm/norm/spy_mvm_jeers06.mp3"
};

float g_GambleEndTime[MAXPLAYERS + 1] = {-1.0, ...};

#define BASE_ODDS 50
#define MAX_ODDS 100
int g_Odds[MAXPLAYERS + 1] = {BASE_ODDS, ...};

public void OnMapStart()
{
	PrecacheSound(sJackpotLine);
	PrecacheSound(sSpawnSound);
	PrecacheSound(sPositive);
	PrecacheSound(sNegative);

	int size = sizeof Gambler_Positive;
	for (int i = 0; i < size; i++)
	PrecacheSound(Gambler_Positive[i], true);

	size = sizeof Gambler_Neutral;
	for (int i = 0; i < size; i++)
	PrecacheSound(Gambler_Neutral[i], true);

	size = sizeof Gambler_Negative;
	for (int i = 0; i < size; i++)
	PrecacheSound(Gambler_Negative[i], true);

	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		ResetGamblerProgress(i);
	}

}

public Plugin:myinfo =
{
	name = "[TF2] Gambler Bot Ability",
	author = "Ham | Based on GPS' Ability",
	description = "Ability For The Gambler, Roll a Random Effect",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

float g_duration = 15.0;

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public void MM_OnRobotSwitched(int clientId, const char[] fromRobot, const char[] toRobot)
{
	if (!StrEqual(fromRobot, ROBOT_NAME) && !StrEqual(toRobot, ROBOT_NAME))
	{
		return;
	}

	ResetGamblerProgress(clientId);
}

void ResetGamblerProgress(int client)
{
	g_GambleEndTime[client] = -1.0;
	g_Odds[client] = BASE_ODDS;
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsRobotWhenDead(victim, ROBOT_NAME))
	{
		ResetGamblerProgress(victim);
	}

	if (attacker == victim)
	return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME))
	{
		if (g_Odds[attacker] < MAX_ODDS)
		g_Odds[attacker]+=10;

		// Each kill spins its own core independently, so multiple cores can be active at once.
		// The most recently triggered core always has the furthest end time, since duration is constant.
		g_GambleEndTime[attacker] = GetEngineTime() + g_duration;
		SpinWheel(attacker);
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		DrawHUD(client);
	}
	return Plugin_Continue;
}

void DrawHUD(int client)
{
	char sHUDText[128];

	float timeLeft = g_GambleEndTime[client] - GetEngineTime();

	if (timeLeft > 0.0)
	{
		Format(sHUDText, sizeof(sHUDText), "Gamble Core Active! %i\nOdds: %i%%", RoundToCeil(timeLeft), g_Odds[client]);
		SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 255, 255);
	}
	else
	{
		Format(sHUDText, sizeof(sHUDText), "Gamble Core Ready!\nGet a Kill to Spin!\nOdds: %i%%", g_Odds[client]);
		SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);
	}

	ShowHudText(client, -3, sHUDText);
}

void SpinWheel(int client)
{
	int size = sizeof Gambler_Positive;
	int soundswitch = GetRandomInt(0, size - 1);

	int size2 = sizeof Gambler_Neutral;
	int soundswitch2 = GetRandomInt(0, size2 - 1);

	int size3 = sizeof Gambler_Negative;
	int soundswitch3 = GetRandomInt(0, size3 - 1);

	// g_Odds is the % chance of a positive result, increasing 1% per kill up to MAX_ODDS (guaranteed positive)
	if (GetRandomInt(1, 100) <= g_Odds[client])
	{
		// Jackpot chance scales with odds too: 5% at BASE_ODDS (50), ramping up to 20% at MAX_ODDS (100)
		int jackpotChance = RoundToNearest(5.0 + (15.0 * float(g_Odds[client] - BASE_ODDS) / float(MAX_ODDS - BASE_ODDS)));
		if (GetRandomInt(1, 100) <= jackpotChance)
		{
			MC_PrintToChatAll("{red}Warning! {orange}The Gambler {red}Has Hit The {pink}JACKPOT");
			TF2_AddCondition(client, TFCond_DefenseBuffed, g_duration);
			TF2_AddCondition(client, TFCond_HalloweenQuickHeal, g_duration);
			TF2_AddCondition(client, TFCond_Kritzkrieged, g_duration);
			TF2_AddCondition(client, TFCond_MegaHeal, g_duration);
			TF2_AddCondition(client, TFCond_RuneHaste, g_duration);
			MC_PrintToChatEx(client, client, "{pink}MAJOR SUCCESS! You've Been Granted: JACKPOT");
			EmitSoundToClient(client,sJackpotLine);
		}else
		{
			EmitSoundToClient(client,sPositive);
			switch(GetRandomInt(0, 7))
				{
					case 0:
					{
						TF2_AddCondition(client, TFCond_ObscuredSmoke, g_duration);
						MC_PrintToChatEx(client, client, "{green}Success! You've Been Granted: 75% DODGE");
						EmitSoundToClient(client,Gambler_Positive[soundswitch]);
						
					}
					case 1:
					{
						TF2_AddCondition(client, TFCond_StealthedUserBuffFade, g_duration);
						MC_PrintToChatEx(client, client, "{green}Success! You've Been Granted: Invisibility");
						EmitSoundToClient(client,Gambler_Positive[soundswitch]);
						
					}
					case 2:
					{
						TF2_AddCondition(client, TFCond_RuneResist, g_duration);
						MC_PrintToChatEx(client, client, "{green}Success! You've Been Granted: The Resist Powerup");
						EmitSoundToClient(client,Gambler_Positive[soundswitch]);
						
					}
					case 3:
					{
						TF2_AddCondition(client, TFCond_DefenseBuffed, g_duration);
						MC_PrintToChatEx(client, client, "{green}Success! You've Been Granted: Battalion's Backup");
						EmitSoundToClient(client,Gambler_Positive[soundswitch]);
						
					}
					case 4:
					{
						TF2_AddCondition(client, TFCond_CritCola, g_duration);
						MC_PrintToChatEx(client, client, "{green}Success! You've Been Granted: Mini-Crits");
						EmitSoundToClient(client,Gambler_Positive[soundswitch]);
						
					}
					case 5:
					{
						TF2_AddCondition(client, TFCond_RuneHaste, g_duration);
						MC_PrintToChatEx(client, client, "{green}Success! You've Been Granted: Haste");
						EmitSoundToClient(client,Gambler_Positive[soundswitch]);
						
					}
					case 6:
					{
						TF2_AddCondition(client, TFCond_RadiusHealOnDamage, g_duration);
						TF2Attrib_AddCustomPlayerAttribute(client, "mod weapon blocks healing", 1.0, g_duration);
						TF2Attrib_AddCustomPlayerAttribute(client, "healing received bonus", 4.0, g_duration);
						MC_PrintToChatEx(client, client, "{green}Success! You've Been Granted: AoE Healing");
						EmitSoundToClient(client,Gambler_Positive[soundswitch]);
						
					}
				}
			}
	}
	else //Bad luck
	{
		EmitSoundToClient(client,sNegative);
		//7 Curses
		switch(GetRandomInt(0, 6))
		{
			case 0:
			{
				TF2_AddCondition(client, TFCond_SwimmingCurse, g_duration);
				MC_PrintToChatEx(client, client, "{yellow}Failure! You've Been Granted: Air Swimming");
				EmitSoundToClient(client,Gambler_Neutral[soundswitch2]);
				
			}
			case 1:
			{
				TF2_AddCondition(client, TFCond_LostFooting, g_duration);
				MC_PrintToChatEx(client, client, "{yellow}Failure! You've Been Granted: Slippery Walk");
				EmitSoundToClient(client,Gambler_Neutral[soundswitch2]);
				
			}
			case 2:
			{
				TF2_StunPlayer(client, 15, 5.0,	TF_STUNFLAGS_LOSERSTATE, client);
				TF2_AddCondition(client, TFCond_MVMBotRadiowave, 16);
				MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Short Circuit");
				EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
				
			}
			case 3:
			{
				TF2_AddCondition(client, TFCond_MarkedForDeath, g_duration);
				MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Marked For Death");
				EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
				
			}
			case 4:
			{
				TF2_AddCondition(client, TFCond_Gas, g_duration);
				TF2Attrib_AddCustomPlayerAttribute(client, "dmg taken from fire increased", 2.5, g_duration);								
				MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Flammable");
				EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
				
			}
			case 5:
			{
				TF2_AddCondition(client, TFCond_Milked, g_duration);
				MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Mad Milk");
				EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
				
			}
			case 6:
			{
				TF2_AddCondition(client, TFCond_Jarated, g_duration);
				MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Jarate");
				EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
				
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	//PrintToChatAll("Effects Removed");
	if (IsRobot(client, ROBOT_NAME)){

	
    if(condition == TFCond_ObscuredSmoke){
    	TF2Attrib_RemoveCustomPlayerAttribute(client, "move speed penalty");
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		TF2Attrib_SetByName(client, "move speed penalty", 1.0);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	}
   }

}