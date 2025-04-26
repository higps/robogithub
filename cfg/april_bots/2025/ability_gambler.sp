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
float g_DamageDone;
bool g_core;
public void OnMapStart()
{
	PrecacheSound(sJackpotLine);
	
	PrecacheSound(sSpawnSound);

	int size = sizeof Gambler_Positive;
	for (int i = 0; i < size; i++)
	PrecacheSound(Gambler_Positive[i], true);

	size = sizeof Gambler_Neutral;
	for (int i = 0; i < size; i++)
	PrecacheSound(Gambler_Neutral[i], true);

	size = sizeof Gambler_Negative;
	for (int i = 0; i < size; i++)
	PrecacheSound(Gambler_Negative[i], true);

	bool g_core = false;
	g_DamageDone = 0.0;

}

public Plugin:myinfo =
{
	name = "[TF2] Gambler Bot Ability",
	author = "Ham | Based on GPS' Ability",
	description = "Ability For The Gambler, Roll a Random Effect",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(!IsValidClient(victim))
	return Plugin_Continue;    

 	if (IsRobot(attacker, ROBOT_NAME))
	{
				if (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) || (TF2_IsPlayerInCondition(victim, TFCond_UberchargedCanteen)
				|| TF2_IsPlayerInCondition(attacker, TFCond_Ubercharged) || TF2_IsPlayerInCondition(attacker, TFCond_UberchargedCanteen) ))
				{
					return Plugin_Continue;
				}

			
			g_DamageDone += damage;
		
	}
	return Plugin_Continue;
}


bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_duration = 15.0;
float GambleModeTimer = -1.0;
float g_skill; 
float g_skill_cooldown = 200.0;


public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
//		PrintToChat(client, "Gambling");
		if( GetEntProp( client, Prop_Data, "m_afButtonPressed" ) & (IN_ATTACK3|IN_USE) ) 
		{
//			PrintToChatAll("Pressed");
            g_button_held[client] = true;
		}



		if( GetEntProp( client, Prop_Data, "m_afButtonReleased" ) & (IN_ATTACK3|IN_USE) ) 
		{
//			("Released");
			g_button_held[client] = false;
            
		}

		g_skill = GetEngineTime();
		
		DrawHUD(client);

	}
	return Plugin_Continue;
}

#define CHAR_FULL "■"
#define CHAR_EMPTY "□"
void DrawHUD(int client)
{
	char sHUDText[128];
	char sProgress[32];
	int iPercents = RoundToCeil(g_DamageDone / g_skill_cooldown * 100.0);

	for (int j = 1; j <= 10; j++)
	{
		if (iPercents >= j * 10)StrCat(sProgress, sizeof(sProgress), CHAR_FULL);
		else StrCat(sProgress, sizeof(sProgress), CHAR_EMPTY);
	}
//	PrintToChatAll("Damage: %f, skilltime %f", g_DamageDone, g_skill_cooldown);

	int iCountDownFiring = RoundToCeil(GambleModeTimer - g_skill);
	
	Format(sHUDText, sizeof(sHUDText), "Gamble Core: %i %%%%\n    %s",iPercents, sProgress);

	if(iPercents >= 100)
	{

			if (g_core){
				Format(sHUDText, sizeof(sHUDText), "Gamble Core Active! %i", iCountDownFiring);
				SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 255, 255);
			}else{
				Format(sHUDText, sizeof(sHUDText), "Gamble Core Ready!\nUse Special Attack to Activate!");
				SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);	
				}


			
	}else {

		SetHudTextParams(0.85, 0.6, 0.1, 255, 0, 0, 155);
	}

	if (g_button_held[client] && iPercents >= 100 && !g_core)
		{
			if (GambleModeTimer <= GetEngineTime() || GambleModeTimer == -1.0)
			{
//				TF2_AddCondition(client, TFCond_ObscuredSmoke, g_duration);
//				TF2_AddCondition(client, TFCond_RuneHaste, g_duration);
//				TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 1.5);
//				TF2Attrib_AddCustomPlayerAttribute(client, "dmg taken increased", 2.0);
            	int size = sizeof Gambler_Positive;
            	int soundswitch = GetRandomInt(0, size - 1);
            	
            	int size2 = sizeof Gambler_Neutral;
            	int soundswitch2 = GetRandomInt(0, size2 - 1);
            	
            	int size3 = sizeof Gambler_Negative;
            	int soundswitch3 = GetRandomInt(0, size3 - 1);
				switch(GetRandomInt(0, 5))
				{
					case 0:
					{
						MC_PrintToChatAll("{red}Warning! {orange}The Gambler {red}Has Hit The {pink}JACKPOT");
						TF2_AddCondition(client, TFCond_Ubercharged, g_duration);
						TF2_AddCondition(client, TFCond_Kritzkrieged, g_duration);
						TF2_AddCondition(client, TFCond_MegaHeal, g_duration);
						MC_PrintToChatEx(client, client, "{pink}MAJOR SUCCESS! You've Been Granted: JACKPOT");
						EmitSoundToClient(client,sJackpotLine);
					}
					default:
					{
//						PrintToChatAll("Not Jackpot")
						switch(GetRandomInt(0, 19))
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
								TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, g_duration);
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
							case 7:
							{
								TF2_AddCondition(client, TFCond_HalloweenSpeedBoost, g_duration);
								MC_PrintToChatEx(client, client, "{green}Success! You've Been Granted: Infinite Air Jumps");
								EmitSoundToClient(client,Gambler_Positive[soundswitch]);
	
							}
							case 8:
							{
								TF2_AddCondition(client, TFCond_Bonked, g_duration);
								MC_PrintToChatEx(client, client, "{yellow}Success? You've Been Granted: Full DODGE With No Attack");
								EmitSoundToClient(client,Gambler_Neutral[soundswitch2]);
								
							}
							case 9:
							{
								TF2_AddCondition(client, TFCond_SwimmingCurse, g_duration);
								MC_PrintToChatEx(client, client, "{yellow}Success? You've Been Granted: Air Swimming");
								EmitSoundToClient(client,Gambler_Neutral[soundswitch2]);
								
							}
							case 10:
							{
								TF2_AddCondition(client, TFCond_BalloonHead, g_duration);
								MC_PrintToChatEx(client, client, "{yellow}Success? You've Been Granted: A Balloon Head");
								EmitSoundToClient(client,Gambler_Neutral[soundswitch2]);
								
							}
							case 11:
							{
								TF2_AddCondition(client, TFCond_LostFooting, g_duration);
								MC_PrintToChatEx(client, client, "{yellow}Success? You've Been Granted: Slippery Walk");
								EmitSoundToClient(client,Gambler_Neutral[soundswitch2]);
								
							}
							case 12:
							{
								TF2_AddCondition(client, TFCond_Charging, g_duration);
								MC_PrintToChatEx(client, client, "{yellow}Success? You've Been Granted: Demoknight Charge");
								EmitSoundToClient(client,Gambler_Neutral[soundswitch2]);
								
							}
							case 13:
							{
								TF2_StunPlayer(client, 15, 0.0,	TF_STUNFLAGS_LOSERSTATE, client);
								TF2_AddCondition(client, TFCond_MVMBotRadiowave, 16);
								MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Short Circuit");
								EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
								
							}
							case 14:
							{
								TF2_AddCondition(client, TFCond_MarkedForDeath, g_duration);
								MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Marked For Death");
								EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
								
							}
							case 15:
							{
								TF2_AddCondition(client, TFCond_HalloweenKart, g_duration);
								MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Bumper Cart");
								EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
								
							}
							case 16:
							{
								TF2_AddCondition(client, TFCond_Slowed, g_duration);
								TF2Attrib_SetByName(client, "move speed penalty", 0.5);
								MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Slow Down");
								EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
								
							}
							case 17:
							{
								TF2_AddCondition(client, TFCond_Gas, g_duration);
								TF2Attrib_AddCustomPlayerAttribute(client, "dmg taken from fire increased", 2.5, g_duration);								
								MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Flammable");
								EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
								
							}
							case 18:
							{
								TF2_AddCondition(client, TFCond_Milked, g_duration);
								MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Mad Milk");
								EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
								
							}
							case 19:
							{
								TF2_AddCondition(client, TFCond_Jarated, g_duration);
								MC_PrintToChatEx(client, client, "{red}Failure! You've Been Cursed With: Jarate");
								EmitSoundToClient(client,Gambler_Negative[soundswitch3]);
								
							}
						}
					}
				}
				g_DamageDone = 0.0;
			}
		}

	if (GambleModeTimer <= GetEngineTime() && g_core)
	{
		g_core = false;
		g_DamageDone = 0.0;
	}


	ShowHudText(client, -3, sHUDText);
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