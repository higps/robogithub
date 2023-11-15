#include <sourcemod>

#include <tf2>
#include <tf2_stocks>

#include <tf_custom_attributes>
#include <tf2utils>

#include <stocksoup/var_strings>

#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "[CA] Fire Ring Attribute"
#define PLUGIN_AUTHOR       "Zabaniya001"
#define PLUGIN_DESCRIPTION  "Hello darling. This plugin uses Nosoop's Custom Attributes framework. This Custom Attribute lets, once you reach enough rage, utilize fire spells ( damage depends on how much rage you have )."
#define PLUGIN_VERSION      "1.0.1"
#define PLUGIN_URL          "https://alliedmods.net"

public Plugin myinfo = {
    name        =   PLUGIN_NAME,
    author      =   PLUGIN_AUTHOR,
    description =   PLUGIN_DESCRIPTION,
    version     =   PLUGIN_VERSION,
    url         =   PLUGIN_URL
};

// ||──────────────────────────────────────────────────────────────────────────||
// ||                              GLOBAL VARIABLES                            ||
// ||──────────────────────────────────────────────────────────────────────────||

enum eWeaponState
{
    AC_STATE_INACTIVE,
    AC_STATE_ACTIVE
};

enum struct weapon_t
{
    float m_fRage;
    float m_fPerc;

    float m_fMaxRage;
    float m_fDamage;

    float m_fDuration;
    float m_fRadius;

    eWeaponState m_eState;

    void Init(char[] sAttribute)
    {
        this.m_fMaxRage   =   ReadFloatVar(sAttribute, "max_rage",  1000.0);
        this.m_fDamage    =   ReadFloatVar(sAttribute, "damage",    1.0);
        this.m_fRadius    =   ReadFloatVar(sAttribute, "radius",    135.0);   // Base Huo-Long heater radius
        this.m_fDuration  =   ReadFloatVar(sAttribute, "duration",  10.0);

        return;
    }

    void Destroy()
    {
        this.m_fMaxRage   =   0.0;
        this.m_fRage      =   0.0;
        this.m_fRadius    =   0.0;
        this.m_fPerc      =   0.0;
        this.m_fDamage    =   0.0;
        this.m_fDuration  =   0.0;

        return;
    }

    float CalculatePercentage()
    {
        return 100.0 - ((FloatAbs(this.m_fMaxRage - this.m_fRage) / this.m_fMaxRage) * 100.0);
    }
}

weapon_t Weapon[2048];

// If you want to change, add or remove sounds, just go ahead. No need to change the code since it uses sizeof.
static const char sDeniedSounds[][] =
{
    "replay/record_fail.wav"
};

// ||──────────────────────────────────────────────────────────────────────────||
// ||                               SOURCEMOD API                              ||
// ||──────────────────────────────────────────────────────────────────────────||

public void OnPluginStart() 
{
    HookEvent("post_inventory_application", Event_OnPostInventoryApplication);

    // In case of late load.
    for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if(IsClientInGame(iClient))
            OnClientPutInServer(iClient);
    }
    
    return;
}

public void OnMapStart()
{
    for(int i = 0; i < sizeof(sDeniedSounds); i++)
    {
        PrecacheSound(sDeniedSounds[i], true);
    }

    return;
}

public void OnClientPutInServer(int iClient)
{
    SDKHook(iClient, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
    SDKHook(iClient, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
    SDKHook(iClient, SDKHook_WeaponEquipPost,   OnWeaponEquipPost);

    return;
}

// ||──────────────────────────────────────────────────────────────────────────||
// ||                                EVENTS                                    ||
// ||──────────────────────────────────────────────────────────────────────────||

public void OnEntityDestroyed(int iEntity)
{
    if(iEntity < 0 || iEntity > 2048)
        return;

    Weapon[iEntity].Destroy();

    return;
}

void OnWeaponEquipPost(int iClient, int iWeapon)
{
    char sAttributes[140];
    if(!TF2CustAttr_GetString(iWeapon, "fire ring attribute", sAttributes, sizeof(sAttributes)))
        return;

    Weapon[iWeapon].Destroy();
    
    Weapon[iWeapon].Init(sAttributes);

    return;
}

void Event_OnPostInventoryApplication(Event event, const char[] name, bool bDontBroadcast)
{
    int iClient = GetClientOfUserId(event.GetInt("userid"));

    if(!IsValidClient(iClient))
        return;

    RequestFrame(checkafterinventory, iClient);

    return;
}

void checkafterinventory(int iClient)
{
    for(int iSlot = 0; iSlot < 10; iSlot++)
    {
        int iWeapon = TF2Util_GetPlayerLoadoutEntity(iClient, iSlot);

        if(!IsValidEntity(iWeapon))
            continue;

        char sAttributes[140];
        if(!TF2CustAttr_GetString(iWeapon, "fire ring attribute", sAttributes, sizeof(sAttributes)))
            continue;

        Weapon[iWeapon].Destroy();

        Weapon[iWeapon].Init(sAttributes);
    }

}

public void OnPlayerRunCmdPost(int iClient, int iButtons)
{
    if(!(iButtons & IN_ATTACK3))
        return;

    if(!IsValidClient(iClient))
        return;

    int iWeapon = TF2_GetActiveWeapon(iClient);

    if(iWeapon <= 0 || iWeapon > 2048)
        return;

    if(!Weapon[iWeapon].m_fMaxRage)
        return;

    static float fWarningDelay[2048];

    if(Weapon[iWeapon].m_eState == AC_STATE_ACTIVE)
        return;

    if(Weapon[iWeapon].m_fPerc < 100.0)
    {
        if(fWarningDelay[iWeapon] >= GetGameTime())
            return;

        fWarningDelay[iWeapon] = GetGameTime() + 1.0;

        EmitSoundToClient(iClient, sDeniedSounds[GetRandomInt(0, sizeof(sDeniedSounds) - 1)], _, _, SNDLEVEL_CAR);

        return;
    }

    fWarningDelay[iWeapon] = GetGameTime() + 1.0;

    Weapon[iWeapon].m_eState = AC_STATE_ACTIVE;

    float fDuration = GetGameTime() + Weapon[iWeapon].m_fDuration;

    DataPack hDataPack;
    CreateDataTimer(0.5, Timer_FireRing, hDataPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    hDataPack.WriteCell(EntIndexToEntRef(iClient));
    hDataPack.WriteCell(EntIndexToEntRef(iWeapon));
    hDataPack.WriteFloat(fDuration);

    return;
}

Action OnTakeDamageAlive(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, int &iWeapon, float fDamageForce[3], float fDamagePosition[3], int iDamageCustom)
{
    if(!IsValidEntity(iVictim) || !IsValidEntity(iAttacker) || !IsValidEntity(iWeapon) || iAttacker == iVictim)
        return Plugin_Continue;

    if(!Weapon[iWeapon].m_fMaxRage)
        return Plugin_Continue;

    return Plugin_Changed;
}

public void OnTakeDamageAlivePost(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float fDamageForce[3], const float fDamagePosition[3])
{
    if(!IsValidEntity(iVictim) || !IsValidEntity(iAttacker) || !IsValidEntity(iWeapon) || iAttacker == iVictim)
        return;

    if(!Weapon[iWeapon].m_fMaxRage)
        return;

    if(Weapon[iWeapon].m_eState == AC_STATE_ACTIVE)
        return;

    Weapon[iWeapon].m_fRage += fDamage;

    if(Weapon[iWeapon].m_fRage > Weapon[iWeapon].m_fMaxRage)
        Weapon[iWeapon].m_fRage = Weapon[iWeapon].m_fMaxRage;

    Weapon[iWeapon].m_fPerc = Weapon[iWeapon].CalculatePercentage();

    return;
}

// ||──────────────────────────────────────────────────────────────────────────||
// ||                               Functions                                  ||
// ||──────────────────────────────────────────────────────────────────────────||

Action Timer_FireRing(Handle timer, DataPack hPack)
{
    hPack.Reset();

    int iClient = EntRefToEntIndex(hPack.ReadCell());
    int iWeapon = EntRefToEntIndex(hPack.ReadCell());

    float fDuration = hPack.ReadFloat();

    if(iWeapon < 0 || iWeapon > 2048)
        return Plugin_Handled;

    if(Weapon[iWeapon].m_fPerc <= 0.0 || !IsPlayerAlive(iClient))
    {
        Weapon[iWeapon].m_eState = AC_STATE_INACTIVE;
        Weapon[iWeapon].m_fPerc = 0.0;
        Weapon[iWeapon].m_fRage = 0.0;

        return Plugin_Handled;
    }

    if(!IsValidClient(iClient) || !IsValidEntity(iWeapon) || TF2_IsPlayerInCondition(iClient, TFCond_Dazed) || fDuration < GetGameTime())
    {
        Weapon[iWeapon].m_eState = AC_STATE_INACTIVE;

        return Plugin_Handled;
    }

    Weapon[iWeapon].m_fPerc -= 100.0 / (Weapon[iWeapon].m_fDuration / 0.5);
    Weapon[iWeapon].m_fRage -= Weapon[iWeapon].m_fMaxRage / (Weapon[iWeapon].m_fDuration / 0.5);

    InitiateFireRing(iClient, iWeapon);

    return Plugin_Continue;
}

// Similar logic to what the huo long heater has apart from a little portion. It was too overkill :shrug: for what I needed
void InitiateFireRing(int iClient, int iWeapon)
{
    TFTeam team = TF2_GetClientTeam(iClient);

    float fVec[3];
    GetClientAbsOrigin(iClient, fVec);

    //TF2_AddCondition(iClient, TFCond_RuneVampire, 0.5);

    AttachParticle(iClient, "heavy_ring_of_fire", 0.5);
    AttachParticle(iClient, "heavy_ring_of_fire_fp", 0.5, _, false);

    float fMax[3];
    float fMin[3];

    float fVecEnemy[3];

    ArrayList playersHitList = new ArrayList();
    TR_EnumerateEntitiesSphere(fVec, Weapon[iWeapon].m_fRadius, PARTITION_SOLID_EDICTS, TraceFindPlayers, playersHitList);

    for(int index = 0; index < playersHitList.Length; index++) 
    {
        int iEntity = EntRefToEntIndex(playersHitList.Get(index));

        if(iEntity == -1)
            continue;

        if(iClient == iEntity)
            continue;

        if(TF2_GetClientTeam(iEntity) == team)
            continue;

        if(TF2_IsPlayerInCondition(iEntity, TFCond_UberchargedHidden) || TF2_IsPlayerInCondition(iEntity, TFCond_FireImmune) || TF2_IsPlayerInCondition(iEntity, TFCond_Ubercharged))
            continue;

        GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", fMax);
        GetEntPropVector(iEntity, Prop_Send, "m_vecMins", fMin);

        GetClientAbsOrigin(iEntity, fVecEnemy);

        if(!((fVec[2] > fVecEnemy[2] + fMin[2] - 32.0) && (fVec[2] < fVecEnemy[2] + fMax[2])))
            continue;
        
        SDKHooks_TakeDamage(iEntity, iClient, iClient, Weapon[iWeapon].m_fDamage, DMG_PLASMA);
    }

    return;
}

bool TraceFindPlayers(int hitEntity, ArrayList list)
{
    if(hitEntity <= 0 || hitEntity > MaxClients)
        return true;

    list.Push(EntIndexToEntRef(hitEntity));

    return true;
}

// ||──────────────────────────────────────────────────────────────────────────||
// ||                                   HUD                                    ||
// ||──────────────────────────────────────────────────────────────────────────||

public Action OnCustomStatusHUDUpdate(int iClient, StringMap entries)
{
    int iActiveWeapon = TF2_GetActiveWeapon(iClient);

    if(!IsValidEntity(iActiveWeapon) || !Weapon[iActiveWeapon].m_fMaxRage)
        return Plugin_Continue;

    char sHudPerc[64];
    Format(sHudPerc, sizeof(sHudPerc), "Fire Ring: %0.f%%", Weapon[iActiveWeapon].m_fPerc);

    entries.SetString("1ca_firering_perc", sHudPerc);

    return Plugin_Changed;
}

// ||──────────────────────────────────────────────────────────────────────────||
// ||                           Internal Functions                             ||
// ||──────────────────────────────────────────────────────────────────────────||

stock bool IsValidClient(int client)
{
    if(client<=0 || client>MaxClients)
    {
        return false;
    }

    if(!IsClientInGame(client))
    {
        return false;
    }

    if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
    {
        return false;
    }
    
    return true;
}

stock int TF2_GetActiveWeapon(int iClient)
{
    return GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock int AttachParticle(int entity, char[] particleType, float duration = 1.0, float offset=0.0, bool attach=true)
{
    int particle = CreateEntityByName("info_particle_system");

    char targetName[128];
    float position[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
    position[2]+=offset;
    TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

    Format(targetName, sizeof(targetName), "target%i", entity);
    DispatchKeyValue(entity, "targetname", targetName);

    DispatchKeyValue(particle, "targetname", "tf2particle");
    DispatchKeyValue(particle, "parentname", targetName);
    DispatchKeyValue(particle, "effect_name", particleType);
    DispatchSpawn(particle);
    SetVariantString(targetName);

    if(attach)
    {
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);
        SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
    }
    else
    {
        SetEntPropEnt(particle, Prop_Data, "m_hEffectEntity", entity);
    }

    ActivateEntity(particle);
    AcceptEntityInput(particle, "start");

    return particle;
}