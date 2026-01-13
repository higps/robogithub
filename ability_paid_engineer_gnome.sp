#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Gnome"

public Plugin:myinfo =
{
	name = "[TF2] Gnome sentry on kill",
	author = "HiGPS | Bmod.TF",
	description = "Spawns sentries on kill",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}
public void OnPluginStart()
{
    HookEvent("player_death", Event_Death, EventHookMode_Post);
}
public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{

    	int death_flags = GetEventInt(event, "death_flags");
    if((death_flags & TF_DEATHFLAG_DEADRINGER) != TF_DEATHFLAG_DEADRINGER) 
        {
        int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        int victim = GetClientOfUserId(GetEventInt(event, "userid"));
        int weaponindex = event.GetInt("weapon_def_index");
        char weaponName[64];
        GetEventString(event, "weapon_logclassname", weaponName, sizeof(weaponName));


        if (IsRobot(attacker, ROBOT_NAME))
        {   
            // PrintToChatAll("%s",weaponName);

            if (StrContains(weaponName, "sentry", false) != -1)
            {
                // PrintToChatAll("Kill was by sentry!");
            }else
            {
                // PrintToChatAll("Kill was not by sentry!");
                // PrintToChatAll("WepIndex:%i",weaponindex);
                
                
                    float vicorigvec[3];
                    GetClientAbsOrigin(victim, vicorigvec);

                bool mini;

                if (weaponindex == 141)
                {
                    mini = true;
                } 
                if ( weaponindex == 7)
                {
                    mini = false;
                }

                float angl[3] = {0.0, 0.0, 0.0};
                BuildSentry(attacker,vicorigvec, angl, 1, mini);
                
    
            }


            
        }
    }
    return Plugin_Continue;
}


stock int BuildSentry(int iBuilder, float Position[3], float Angle[3], int iLevel, bool bMini=false)
{
	static int iSentryFlags = 4;
	static float fMinsMini[3] = {-15.0, -15.0, 0.0};
	static float fMaxsMini[3] = {15.0, 15.0, 49.5};
    Position[2] += 10.0;
	int iSentry = CreateEntityByName("obj_sentrygun");
	if (!IsValidEntity(iSentry))
		return 0;

	int iTeam = GetClientTeam(iBuilder);
	SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder", iBuilder);

	SetVariantInt(iTeam);
	AcceptEntityInput(iSentry, "SetTeam");

	DispatchKeyValueVector(iSentry, "origin", Position);
	DispatchKeyValueVector(iSentry, "angles", Angle);

	if (bMini)
	{
		SetEntProp(iSentry, Prop_Send, "m_bMiniBuilding", 1);
		SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Data, "m_spawnflags", iSentryFlags);
		SetEntProp(iSentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(iSentry, Prop_Send, "m_nSkin", iLevel == 1 ? iTeam : iTeam -2);
		DispatchSpawn(iSentry);

		SetVariantInt(100);
		AcceptEntityInput(iSentry, "SetHealth");

		SetEntPropFloat(iSentry, Prop_Send, "m_flModelScale", 0.75);
		SetEntPropVector(iSentry, Prop_Send, "m_vecMins", fMinsMini);
		SetEntPropVector(iSentry, Prop_Send, "m_vecMaxs", fMaxsMini);
	}
	else
	{
		SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Data, "m_spawnflags", iSentryFlags);
		SetEntProp(iSentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(iSentry, Prop_Send, "m_nSkin", iTeam -2);
		DispatchSpawn(iSentry);
	}
    int entRef = EntIndexToEntRef(iSentry);
    CreateTimer(60.0, Timer_DestroySentry, entRef, TIMER_FLAG_NO_MAPCHANGE);
	return iSentry;
}

public Action Timer_DestroySentry(Handle timer, any entRef)
{
    int sentry = EntRefToEntIndex(entRef);

    if (sentry == INVALID_ENT_REFERENCE || !IsValidEntity(sentry))
        return Plugin_Stop;

    // Proper way to remove buildings
    // ExplodeSentry(sentry);
    AcceptEntityInput(sentry, "Kill");

    return Plugin_Stop;
}


// void ExplodeSentry(int sentry, int attacker = 0)
// {
//     if (!IsValidEntity(sentry))
//         return;

//     int health = GetEntProp(sentry, Prop_Send, "m_iHealth");

//     SDKHooks_TakeDamage(
//         sentry,
//         attacker > 0 ? attacker : sentry, // inflictor
//         attacker > 0 ? attacker : sentry, // attacker
//         float(health + 100),              // guaranteed lethal
//         2
//     );
// }
// #include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

// void BuildSentry(int iBuilder, float fOrigin[3], float fAngle[3], int iLevel = 1)
// {
//     float fBuildMaxs[3] = {24.0, 24.0, 66.0};
//     float fMdlWidth[3]  = {1.0, 0.5, 0.0};

//     char sModel[64];
//     int uTeam = TF2_GetClientTeam(iBuilder);
//     int iTeam = GetClientTeam(iBuilder);
//     PrintToChatAll("iteam was %i,", iTeam, uTeam);
//     int iShells = 0;
//     int iHealth = 0;
//     int iRockets = 0;

//     if (iLevel == 1)
//     {
//         strcopy(sModel, sizeof(sModel), "models/buildables/sentry1.mdl");
//         iShells = 100;
//         iHealth = 150;
//     }
//     else if (iLevel == 2)
//     {
//         strcopy(sModel, sizeof(sModel), "models/buildables/sentry2.mdl");
//         iShells = 120;
//         iHealth = 180;
//     }
//     else if (iLevel == 3)
//     {
//         strcopy(sModel, sizeof(sModel), "models/buildables/sentry3.mdl");
//         iShells = 144;
//         iHealth = 216;
//         iRockets = 20;
//     }

//     int iSentry = CreateEntityByName("obj_sentrygun");
//     if (iSentry == -1)
//         return;

//     DispatchSpawn(iSentry);
//     TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);

//     SetEntityModel(iSentry, sModel);

//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_flAnimTime"), 51, 4, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_nNewSequenceParity"), 4, 4, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_nResetEventsParity"), 4, 4, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells"), iShells, 4, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_iMaxHealth"), iHealth, 4, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_iHealth"), iHealth, 4, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_bBuilding"), 0, 2, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_bPlacing"), 0, 2, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_bDisabled"), 0, 2, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_iObjectType"), 3, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_iState"), 1, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_iUpgradeMetal"), 0, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_bHasSapper"), 0, 2, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_nSkin"), (iTeam - 2), 1, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_bServerOverridePlacement"), 1, 1, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_iUpgradeLevel"), iLevel, 4, true);
//     SetEntData(iSentry, FindSendPropInfo("CObjectSentrygun", "m_iAmmoRockets"), iRockets, 4, true);

//     SetEntDataEnt2(iSentry, FindSendPropInfo("CObjectSentrygun", "m_nSequence"), 0, true);
//     SetEntDataEnt2(iSentry, FindSendPropInfo("CObjectSentrygun", "m_hBuilder"), iBuilder, true);

//     SetEntDataFloat(iSentry, FindSendPropInfo("CObjectSentrygun", "m_flCycle"), 0.0, true);
//     SetEntDataFloat(iSentry, FindSendPropInfo("CObjectSentrygun", "m_flPlaybackRate"), 1.0, true);
//     SetEntDataFloat(iSentry, FindSendPropInfo("CObjectSentrygun", "m_flPercentageConstructed"), 1.0, true);

//     SetEntDataVector(iSentry, FindSendPropInfo("CObjectSentrygun", "m_vecOrigin"), fOrigin, true);
//     SetEntDataVector(iSentry, FindSendPropInfo("CObjectSentrygun", "m_angRotation"), fAngle, true);
//     SetEntDataVector(iSentry, FindSendPropInfo("CObjectSentrygun", "m_vecBuildMaxs"), fBuildMaxs, true);
//     SetEntDataVector(iSentry, FindSendPropInfo("CObjectSentrygun", "m_flModelWidthScale"), fMdlWidth, true);

//     SetVariantInt(iTeam);
//     AcceptEntityInput(iSentry, "TeamNum");

//     SetVariantInt(iTeam);
//     AcceptEntityInput(iSentry, "SetTeam");
// }
