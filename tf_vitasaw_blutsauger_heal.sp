#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <addplayerhealth>
#include <tf2wearables>
#include <sdktools_stringtables>
#include <sdktools_tempents>
#include <sdktools>
#include <loghelper>
#include <tf2attributes>
#include <tf_ontakedamage>

#if defined __stocksoup_tf_tempents_stocks_included
#endinput
#endif
#define __stocksoup_tf_tempents_stocks_included

/*Is for checking if the trace damagetype is a melee weapon, avoids the scenario where fired syringes can 
heal if you switch to vita-saw just before syringes hits a teammate
*/
#define DMG_TYPE_MELEE 134221952
#define DMG_TYPE_MELEE_CRIT 135270528

#define DMG_TYPE_SYRINGE 2230274
#define DMG_TYPE_SYRINGE_CRIT 3278850
#define sHealNoise "items/medshot4.wav"
#define sExtinguish "player/flame_out.wav"
#define sSyringeBuffOn "ui/item_nvg_pickup.wav"
// #define sSyringeBuffOff "somesound.wav"



enum //Convar names
{
	CV_bDebugMode,
	CV_SyringeComboTime,
	CV_SyringeBuffDuration,
	CV_SyringeBuffCap,
	CV_VitaSawHeal,
	CV_VitaSawUber,
	CV_VitaSawComboTime,
	CV_PluginVersion
}
/* Global Variables */

/* Global Handles */

//Handle g_hGameConf;

/* Dhooks */

/* Convar Handles */

ConVar g_cvCvarList[CV_PluginVersion+1];

int medigun;
int medigunlist[MAXPLAYERS + 1];
float uber;


Handle hGameConf;
Handle hPlayerHealedOther;

bool g_Timer_Syringe[MAXPLAYERS + 1] = false;
bool g_Applied_Buff[MAXPLAYERS + 1] = false;
int Syringe_Count[MAXPLAYERS + 1] = 0;
//float Syringe_Buff[MAXPLAYERS + 1] = 0.0;
int Timer_Syringe_Count[MAXPLAYERS + 1] = 0;
//float g_Original_Chargerate[MAXPLAYERS + 1] = 0.0;



new ParticleStorage[MAXPLAYERS + 1];
bool Dead_Check[MAXPLAYERS + 1] = false;


bool g_cv_bDebugMode;
float g_CV_SyringeComboTime
float g_CV_SyringeBuffDuration
int g_CV_SyringeBuffCap

int g_CV_VitaSawHeal;
float g_CV_VitaSawUber;
float g_CV_VitaSawComboTime;


bool g_HitWithStrongVitaSaw[MAXPLAYERS + 1] = false;


int g_Vita_Hit_Count[MAXPLAYERS + 1] = 0;
int Timer_g_Vita_Hit_Count[MAXPLAYERS + 1] = 0;

bool g_Timer_Vita[MAXPLAYERS + 1] = false;
//

public void OnPluginStart()
{
	g_cvCvarList[CV_VitaSawHeal] = CreateConVar("vita_saw_heal", "40", "Amount of health healed when hitting a teammate with the Vita-saw");
	g_cvCvarList[CV_VitaSawUber] = CreateConVar("vita_saw_uber", "0.015", "Amount of UberCharge gained upon a successful team-hit with the Vita-saw");
	g_cvCvarList[CV_VitaSawComboTime] = CreateConVar("vita_saw_cooldown", "10.0", "Amount of time before you can land a strong vita-saw hit again");
	CreateConVar("vita_saw_allow_overheal", "0", "If Vita-saw can overheal or not.");
	CreateConVar("blutsauger_heal_team", "2", "Amount of health given when hitting a teammate with the blutsauger");
	CreateConVar("blutsauger_heal_team_allow_overheal", "0", "Decides if blutsauger medics can overheal from hitting teammates.");
	CreateConVar("blutsauger_heal_enemy", "3", "Amount of health given when hitting a enemy with the blutsauger");
	CreateConVar("blutsauger_razorback_max_overheal", "15", "Tells the plugin the amount of overheal allowed for razorback snipers");
	
	RegAdminCmd("bm_reset_uber", Reset_Uber,ADMFLAG_SLAY, "Reset Uber to all medics");
	RegAdminCmd("bm_set_charge", Set_Uber, ADMFLAG_SLAY, "Sets charge, debug");
	
	g_cvCvarList[CV_bDebugMode] = CreateConVar("bm_medic_debug", "0", "Debug for medic related plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvCvarList[CV_SyringeComboTime] = CreateConVar("bm_syringe_gun_uber_combo_time", "1.5", "The time duration in seconds before the combo ends and the buff is applied.");
	g_cvCvarList[CV_SyringeBuffDuration] = CreateConVar("bm_syringe_gun_uber_g_CV_SyringeBuffDuration", "10.00", "The time duration in seconds the bonus ubercharge from the syringe lasts");
	g_cvCvarList[CV_SyringeBuffCap] = CreateConVar("bm_syringe_gun_uber_gain_cap", "20.0", "The max amount of addtional ubercharge build rate syringe guns can give");
	//g_cvCvarList[CV_QuickFixAoeDuration] = CreateConVar("bm_quickfix_aoe_duration", "5.0", "The amount of seconds the quickfix AOE uber lasts");
	
	hGameConf = LoadGameConfigFile("playerhealedother");
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFGameStats::Event_PlayerHealedOther");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	hPlayerHealedOther = EndPrepSDKCall();
	
	// HookEvent("post_inventory_application", Event_PlayerLoadoutRefresh, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	//HookEvent("player_chargedeployed", Event_ChargeDeployed, EventHookMode_Pre);
	
	g_cv_bDebugMode = GetConVarBool(g_cvCvarList[CV_bDebugMode]);
	
	g_CV_VitaSawHeal = GetConVarInt(g_cvCvarList[CV_VitaSawHeal]);
	g_CV_VitaSawUber = GetConVarFloat(g_cvCvarList[CV_VitaSawUber]);
	g_CV_VitaSawComboTime = GetConVarFloat(g_cvCvarList[CV_VitaSawComboTime]);

	g_cvCvarList[CV_VitaSawHeal].AddChangeHook(CvarChangeHook);
	g_cvCvarList[CV_VitaSawUber].AddChangeHook(CvarChangeHook);
	g_cvCvarList[CV_VitaSawComboTime].AddChangeHook(CvarChangeHook);

	g_CV_SyringeComboTime = GetConVarFloat(g_cvCvarList[CV_SyringeComboTime]);
	g_CV_SyringeBuffDuration = GetConVarFloat(g_cvCvarList[CV_SyringeBuffDuration]);
	g_CV_SyringeBuffCap = GetConVarInt(g_cvCvarList[CV_SyringeBuffCap]);
	
	g_cvCvarList[CV_bDebugMode].AddChangeHook(CvarChangeHook);
	g_cvCvarList[CV_SyringeComboTime].AddChangeHook(CvarChangeHook);
	g_cvCvarList[CV_SyringeBuffDuration].AddChangeHook(CvarChangeHook);
	g_cvCvarList[CV_SyringeBuffCap].AddChangeHook(CvarChangeHook);
	
	for(int client = 1 ; client <= MaxClients ; client++)
	{
		if(IsClientInGame(client))
		{
			SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
		}
	}
}



/* Publics */
public void CvarChangeHook(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
	if(convar == g_cvCvarList[CV_bDebugMode]) g_cv_bDebugMode = view_as<bool>(StringToInt(sNewValue));
	if(convar == g_cvCvarList[CV_SyringeComboTime]) g_CV_SyringeComboTime = StringToFloat(sNewValue);
	if(convar == g_cvCvarList[CV_VitaSawHeal]) g_CV_VitaSawHeal = StringToInt(sNewValue);
	if(convar == g_cvCvarList[CV_VitaSawUber]) g_CV_VitaSawUber = StringToFloat(sNewValue);
	if(convar == g_cvCvarList[CV_VitaSawComboTime]) g_CV_VitaSawComboTime = StringToFloat(sNewValue);
	
}

// public Action Event_ChargeDeployed(Event event, char[] name, bool dontBroadcast){

	// int client = GetClientOfUserId(event.GetInt("userid"));
	// int target = GetClientOfUserId(event.GetInt("targetid"));
	
	// int iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);


	// if (isQuickfix(iWeapon)){
	
	// if(g_cv_bDebugMode)PrintToChatAll("Applying AOE on quickfix");
	
	//TF2_AddCondition(client, TFCond_RadiusHealOnDamage, 8.0, client);
	//TF2_AddCondition(client, TFCond_InHealRadius, 5.0, client);
	//TF2_AddCondition(client, TFCond_Healing, 5.0, client);
	//
	
	// }
	
// }

// public Action ReApplyHeal(Handle timer, int client){

	// TF2_AddCondition(client, TFCond_Healing, -1, client);
// }

/* bool isQuickfix(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If quickfix gets skins in future with different indices, add them here
	case 411: //quickfix
		{
			return true;
		}
	}
	return false;
}
 */
public Action Event_PlayerDeath(Event event, char[] name, bool dontBroadcast){

	int client = GetClientOfUserId(event.GetInt("userid"));
	
	//DeleteParticleOnDeath(client, particle);/
	if(IsValidClient(client)){ 

		Syringe_Count[client] = 0;

		DeleteParticle(0.1, ParticleStorage[client]);
		Dead_Check[client] = true;
	}
	
	
}



//////////////
/// FOR CREATORS.TF AUSTRALIUM MEDIGUN
// public Action Event_PlayerLoadoutRefresh(Event event, char[] name, bool dontBroadcast)
// {
// 	int client = GetClientOfUserId(event.GetInt("userid"));
	
// 	if(IsValidClient(client)){
	
// 	if (TF2_GetPlayerClass(client) == TFClass_Medic)
// 	{
		
		
// 		//GiveChargeAmount(client);
// 		// Syringe_Count[client] = 0;
// 		// Timer_Syringe_Count[client] = 0;
// 		// Syringe_Buff[client] = 0.0;
		
		
		
// 		if(g_cv_bDebugMode)PrintToChatAll("Class is medic?");
// 		medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		
// 		uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		
// 		//if(g_cv_bDebugMode)PrintToChatAll("On spawn charge amount:                       %f", GiveChargeAmount(client));
		
		
// 		// PrintToChatAll("Medigun before pack %i", medigun);
// 		//PrintToChatAll("%f uber", uber);
		
		
// 		//Checks if the previous medigun is a medigun
// 		switch(GetEntProp(medigun, Prop_Send, "m_iItemDefinitionIndex"))
// 		{
// 			//Do not  set any uber if it's kritz, quickfix or vaccinator
// 		case 35,411,998:
// 			{
// 				if(g_cv_bDebugMode)PrintToChatAll("Found kritz, quickfix or vaccinator equipped");
				
// 			}
// 		default:
// 			{
// 				DataPack pack;
// 				CreateDataTimer(0.1, SetUber_timer, pack, TIMER_DATA_HNDL_CLOSE);
// 				pack.WriteCell(client);
// 				pack.WriteFloat(uber);
				
// 			}
			
// 		}

		
// 	}
	
// 	}
// 	return Plugin_Continue;
// }
//
// public Action SetUber_timer(Handle timer, DataPack pack)
// {

// 	//PrintToChatAll("Attempting pack");
// 	pack.Reset();
// 	int client = pack.ReadCell();
// 	if(IsValidClient(client) && IsClientInGame(client) && IsPlayerAlive(client)){
// 	float iuber = pack.ReadFloat();

// 	int iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

// 	if (iWeapon != -1)
// 	{
// 		if (HasEntProp(iWeapon, Prop_Send, "m_flChargeLevel"))
// 		{
		
// 		if(g_cv_bDebugMode)PrintToChatAll("iWeapon in pack %i", iWeapon);
// 		if(g_cv_bDebugMode)PrintToChatAll("iuber in pack %f", iuber);

		
		
// 		SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel", iuber);
// 			}
// 		}
// 	}

// }


public Action Reset_Uber(int caller, int args){

if (g_cv_bDebugMode)
{

	for(int client = 1 ; client <= MaxClients ; client++)
	{
		if(IsClientInGame(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			medigunlist[client] = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			SetEntPropFloat(medigunlist[client], Prop_Send, "m_flChargeLevel", 0.00);
			if(g_cv_bDebugMode)PrintToChatAll("Setting uber to 0 for client %i", client);
		}
	}
}
	
}
public Action Set_Uber(int caller, int args){
if (g_cv_bDebugMode)
{
	for(int client = 1 ; client <= MaxClients ; client++)
	{
		if(IsClientInGame(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			medigunlist[client] = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			SetEntPropFloat(medigunlist[client], Prop_Send, "m_flChargeLevel", 1.00);
			if(g_cv_bDebugMode)PrintToChatAll("Setting uber to 0 for client %i", client);
		}
	}
}	
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
int damagecustom, CritType &critType)
{

	if(IsValidClient(victim)){
		
		
		
		if(IsValidClient(attacker) && !isMiniBoss(attacker)){
			
			//int iWeapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
			//if(iWeapon == -1) return false;
			
			if (IsSyringeGun(weapon))
			{
				
				if(g_cv_bDebugMode)PrintToChatAll("=============");
				
				if (!TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) && !TF2_IsPlayerInCondition(victim, TFCond_Disguised)){
					if(g_cv_bDebugMode)PrintToChatAll("%N, was not ubercharged", victim);
					Syringe_Count[attacker]++;
				} 
				//Syringe_Buff[attacker] += 0.01;
				
				//GiveChargeAmount(attacker);
				//If we haven't gotten the original medigun charge rate, we get it now
				//if(g_cv_bDebugMode)PrintToChatAll("On hit charge amount:                       %f", GiveChargeAmount(attacker));
				
				
				if(g_cv_bDebugMode)PrintToChatAll("Syringe Counter while firing %i", Syringe_Count[attacker]);
				//if(g_cv_bDebugMode) PrintToChatAll("Syringe Buff is %f:", Syringe_Buff[attacker]);
				if(g_cv_bDebugMode)PrintToChatAll("Timer Syringe Counter while firing %i", Timer_Syringe_Count[attacker]);
				
				if(g_cv_bDebugMode)PrintToChatAll("=============");
				
				if (!g_Timer_Syringe[attacker] && Syringe_Count[attacker] != 0){
					
					CreateTimer(g_CV_SyringeComboTime, Syringe_Combo_Check_Timer, attacker);
					Timer_Syringe_Count[attacker] = Syringe_Count[attacker];
					
					g_Timer_Syringe[attacker] = true;
				}
			}
			
		}
		
	}
}

public Action VitaSawCoolDown (Handle timer, int client)
{	
	if (IsValidClient(client) && IsClientInGame(client) && IsPlayerAlive(client))
		{

			if (g_Vita_Hit_Count[client] > Timer_g_Vita_Hit_Count[client])
			{
				
			if(g_cv_bDebugMode)PrintToChatAll("Vita ...Combo still going...");
			Timer_g_Vita_Hit_Count[client] = g_Vita_Hit_Count[client];
			CreateTimer(g_CV_SyringeComboTime, VitaSawCoolDown, client);

			}else
			{	
				if(g_cv_bDebugMode) PrintToChatAll("---------Stopped Vita combo---------");	
				g_Timer_Syringe[client] = false;
				g_HitWithStrongVitaSaw[client] = false;
				g_Vita_Hit_Count[client] = 0;
				Timer_g_Vita_Hit_Count[client] = 0;

			}
		}
}


public Action Syringe_Combo_Check_Timer (Handle timer, int client)
{	


	if (IsValidClient(client))
		{


		if(g_cv_bDebugMode)PrintToChatAll("========================");
		if(g_cv_bDebugMode)PrintToChatAll("Inside timer Syringe_Count %i:", Syringe_Count[client]);
		if(g_cv_bDebugMode)PrintToChatAll("Inside timer Timer_Syringe_Count %i:", Timer_Syringe_Count[client]);
		
		if (Syringe_Count[client] > Timer_Syringe_Count[client]){
			
			if(g_cv_bDebugMode)PrintToChatAll("...Combo still going...");
			Timer_Syringe_Count[client] = Syringe_Count[client];
			
			CreateTimer(g_CV_SyringeComboTime, Syringe_Combo_Check_Timer, client);
		}else
		{	

			
			if(g_cv_bDebugMode) PrintToChatAll("---------Stopped combo---------");
			
			g_Timer_Syringe[client] = false;
			if (IsPlayerAlive(client) && IsPlayerInGame(client)){ 	
			
			Calculate_Uber_Buff(client);
			Dead_Check[client] = false;
			}
			
		
			}
	}
}

public Action Calculate_Uber_Buff (int client){

	
	//Address pAttribute;
	
	
	
	// float g_CV_SyringeBuffDuration = g_CV_SyringeBuffDuration;
	// int g_CV_SyringeBuffCap = g_CV_SyringeBuffCap;
	
	
	//do something here to change syringe count from 2 to 0.2
	
	//pAttribute = TF2Attrib_GetByName(iWeapon, "Reload time decreased")
	
	if(g_cv_bDebugMode) PrintToChatAll("Syringe_Count int was %i", Syringe_Count[client]);
	if(g_cv_bDebugMode) PrintToChatAll("g_CV_SyringeBuffCap int was %i", g_CV_SyringeBuffCap);

		if (Syringe_Count[client] < 6)
	{
		
		if(g_cv_bDebugMode) PrintToChatAll("***Miminum Combo was %i Syringe_Buff was %f", g_CV_SyringeBuffCap, Syringe_Count[client]);
		
		Syringe_Count[client] = 5;
		
		
	}
	
	if (Syringe_Count[client] > g_CV_SyringeBuffCap)
	{
		
		if(g_cv_bDebugMode) PrintToChatAll("***Cap was %i Syringe_Buff was %f", g_CV_SyringeBuffCap, Syringe_Count[client]);
		
		Syringe_Count[client] = 20;
		
		
	}
	
	//Moving decimals
	float buff_to_add =float(Syringe_Count[client])/100;
	
	//Show buff added to player
	PrintCenterText(client, "%i %% bonus ubercharge build rate added", Syringe_Count[client]);
	///Setting the temporary buff and playing voice line code here
	
	
	if(g_cv_bDebugMode) PrintToChatAll("Setting buff to : %f percent for %f", 1.0 + buff_to_add, g_CV_SyringeBuffDuration);
	TF2Attrib_AddCustomPlayerAttribute(client, "ubercharge rate bonus", 1.0 + buff_to_add, g_CV_SyringeBuffDuration);
	
	// For future mapping particles to a weapon
	// int iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	// TF2Attrib_SetByName(iWeapon, "attach particle effect", 17.0);
	//TF2Attrib_AddCustomPlayerAttribute(client, "attach particle effect", 5.0, g_CV_SyringeBuffDuration);
	
	//TF2Attrib_AddCustomPlayerAttribute(client, "ubercharge rate bonus", 1.25, g_CV_SyringeBuffDuration);
	
	TF2_AddCondition(client, TFCond_Unknown2, g_CV_SyringeBuffDuration, client);

	//Sound effect for applying the buff
	float fVictimAbsOrigin[3];
	GetClientAbsOrigin(client, fVictimAbsOrigin);
	
	EmitAmbientSound(sSyringeBuffOn, fVictimAbsOrigin, client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);

	
	// char szVO[512];
	// Format(szVO, sizeof(szVO), "medic_sf12_goodmagic01");
	//	EmitGameSoundToAll(szVO, client);
	
	
	//EmitSoundToAll(sExtinguish, victim);
	
	// TFTeam iteam = TF2_GetClientTeam(client);
	// char particle[512];
	
	//if team blue - use player_glowblue
	//if team red use - player_glowred
	
	
	// if (iteam == TFTeam_Red) Format(particle, sizeof(particle), "player_glowred");
	// if (iteam == TFTeam_Blue) Format(particle, sizeof(particle), "player_glowblue");
	TFTeam iteam = TF2_GetClientTeam(client);
	char particle[512];
	
	//if team blue - use player_glowblue
	//if team red use - player_glowred
	
	
	if (iteam == TFTeam_Red) Format(particle, sizeof(particle), "player_glowred");
	if (iteam == TFTeam_Blue) Format(particle, sizeof(particle), "player_glowblue");
	
	
	
	CreateParticle(client, particle, g_CV_SyringeBuffDuration);
	
	CreateTimer(g_CV_SyringeBuffDuration, Syringe_Buff_Expired_Timer_Notification, client);
	
	// if (g_Applied_Buff[client]){
	// g_Applied_Buff[client] = false;
	// }else{
	// g_Applied_Buff[client] = true;
	// }
	
	
	//	EmitSoundToAll(sSyringeBuffOn, client);
	
	//play sound medic_mvm_get_upgrade02 - i feel like a million deutchmarks
	// medic_sf12_goodmagic01 - I have so much power
	
	// on end medic_sf12_badmagic10
	Syringe_Count[client] = 0;
	Timer_Syringe_Count[client] = 0;
	//Syringe_Buff[client] = 0.0;
	//Only create the timer if combo has stopped
	//	CreateTimer(g_CV_SyringeBuffDuration, Remove_attribute_timer, client);
	
	//if(g_cv_bDebugMode) PrintToChatAll("=============");
}

public Action Syringe_Buff_Expired_Timer_Notification (Handle timer, int client){

	if(IsValidClient(client) && IsClientInGame(client))
	{
	if(!TF2_IsPlayerInCondition(client, TFCond_Unknown2) && IsPlayerAlive(client)){
		
		if(g_cv_bDebugMode) PrintToChatAll("You are not buffed anymore");
		char szVO[512];
		Format(szVO, sizeof(szVO), "medic_sf12_badmagic10");
		if(!Dead_Check[client]) EmitGameSoundToAll(szVO, client);
		CreateTimer(1.6, soundcancel, client);
		g_Applied_Buff[client] = false;
	}else{
		if(g_cv_bDebugMode) PrintToChatAll("You are still buffed");
		
		g_Applied_Buff[client] = true;
		
	}
	}
	
}

stock CreateParticle(ent, String:particleType[], Float:time)
{

	//int iWeapon = GetPlayerWeaponSlot(ent, TFWeaponSlot_Secondary);
	new particle = CreateEntityByName("info_particle_system");

	decl String:name[64];

	if (IsValidEdict(particle))
	{
	
		//Delete existing particle if it's already there
		//CreateTimer(0.0, DeleteParticle, particle);
		
		new Float:position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		
		position[0] += 0.0;
		position[1] += 0.0;
		position[2] += -20.0; //z
		
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", name);
		DispatchKeyValue(particle, "effect_name", particleType);
		
		
		//DispatchKeyValue(particle, "angles", "90.0 90.0 0.0"); 
		DispatchSpawn(particle);
		// SetVariantString(name);
		
		// AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		//if team blue - use player_glowblue
		//if team red use - player_glowred
		
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		
		
		SetVariantString("head");
		AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
		
		DispatchKeyValue(particle, "targetname", "present");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticle, particle);
		ParticleStorage[ent] = particle;
	}
}

public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classN[64];
		GetEdictClassname(particle, classN, sizeof(classN));
		if (StrEqual(classN, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
}

public Action soundcancel (Handle timer, int client)
{

	//StopSound(client, 255, "vo\scout_cloakedspyidentify09.mp3");
	//StopSoundPermAny(client, "Scout.cloakedspyidentify09");
	StopSoundPermAny(client, "vo/medic_sf12_badmagic10.mp3");
	//snipercallclamp[client] = false;
	//PrintToChatAll("Stopping sound");
}

stock void StopSoundPermAny(int i, char[] sound) 
{

	StopSound(i, SNDCHAN_AUTO, sound);
	StopSound(i, SNDCHAN_WEAPON, sound);
	StopSound(i, SNDCHAN_VOICE, sound);
	StopSound(i, SNDCHAN_ITEM, sound);
	StopSound(i, SNDCHAN_BODY, sound);
	StopSound(i, SNDCHAN_STREAM, sound);
	StopSound(i, SNDCHAN_VOICE_BASE, sound);
	StopSound(i, SNDCHAN_USER_BASE, sound);
} 

/* public Action Remove_attribute_timer (Handle timer, int client)
{
	//Check which medigun is active and set back to normal
	if(g_cv_bDebugMode)	PrintToChatAll("Resetting build rate to %f: ", g_Original_Chargerate[client]);
	int iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	
	// TF2Attrib_SetByName(iWeapon, "ubercharge rate bonus", g_Original_Chargerate[client]);
	
	// g_Original_Chargerate[client] = -1.0;
	switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		// Only check if it's not a medigun, just remove bonus if it's a medigun. Sets the 
	case 35: //Kritzkrieg
		{
			if(g_cv_bDebugMode)	PrintToChatAll("Kritzkrieg now normal for bmod");
			TF2Attrib_SetByName(iWeapon, "ubercharge rate bonus", 1.25);
		}
	case 411://quckfix
		{
			if(g_cv_bDebugMode)PrintToChatAll("quickfix now normal for bmod");
			TF2Attrib_SetByName(iWeapon, "ubercharge rate bonus", 1.67);
		}
	case 998://vaccinator
		{
			if(g_cv_bDebugMode)PrintToChatAll("Vaccinator now normal for bmod");
			TF2Attrib_SetByName(iWeapon, "ubercharge rate bonus", 3.0);
		}
	default:
		{
			if(g_cv_bDebugMode)PrintToChatAll("Medigun now normal");
			TF2Attrib_SetByName(iWeapon, "ubercharge rate bonus", 1.0);
		}
	} 
} */

bool IsSyringeGun(int weapon)
{
	if(weapon == -1 && weapon <= MaxClients) return false;
	
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		//If Syringe Guns gets skins in future with different indices, add them here
	case 17, 204: //Syringe Gun, Strange Syringe Gun
		{
			return true;
		}
	}
	return false;
}


public PlayerHealedOther(int client, float amount)
{
	SDKCall(hPlayerHealedOther, GetCTFGameStats(), client, amount);
}
stock Address:GetCTFGameStats()
{
	return GameConfGetAddress(hGameConf, "CTFGameStats");
}

public void OnMapStart()
{	
	PrecacheSound(sHealNoise);
	PrecacheSound(sExtinguish);
	PrecacheSound(sSyringeBuffOn);
	// PrecacheSound(sSyringeBuffOff);
}
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack); // hook for when someone joins in the middle of a round
}
public Action OnTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	//TraceAttack fires everytime hitscan is used and in some cases, for syringes and Dragon's fury fireballs etc.
	
	
	
	
	
	//Vita-saw code - start
	if((IsValidEntity(victim) && IsValidEntity(attacker) && IsValidEntity(inflictor)) &&
			(victim <= MaxClients && victim > 0) &&
			(attacker <= MaxClients && attacker > 0) &&
			(inflictor <= MaxClients && inflictor > 0)) //Validity checks
	{
		/*
				Checks if: The weapon is the vita-saw, the medic is hitting a teammate, 
				the inflictor is the medic and actually playing the class, 
				damagetype is also checked to determine if the trace came from a melee weapon.
			*/
		if((IsClientInGame(victim) && IsClientInGame(attacker) && IsClientInGame(inflictor)) &&
				(GetEntProp(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_iItemDefinitionIndex") == 173) && 
				(TF2_GetClientTeam(attacker) == TF2_GetClientTeam(victim)) &&
				(inflictor == attacker) && 
				(TF2_GetPlayerClass(inflictor) == TFClass_Medic) &&
				(damagetype == DMG_TYPE_MELEE || damagetype == DMG_TYPE_MELEE_CRIT))
		{
			
			
			int heal = g_CV_VitaSawHeal;
			int clientHP = GetClientHealth(victim);
			g_Vita_Hit_Count[victim]++;
			if(!g_HitWithStrongVitaSaw[victim])
			{
				heal = (g_CV_VitaSawHeal+g_CV_VitaSawHeal-15);
				
			}

			if(g_cv_bDebugMode) PrintToChatAll("Heal: %i",heal);
			if(g_cv_bDebugMode) PrintToChatAll("g_Vita_Hit_Count: %i , Timer Hit Count: %i",g_Vita_Hit_Count[victim], Timer_g_Vita_Hit_Count[victim]);
			
			int amount = GetClientHealth(victim) + (heal - 10);
			
			if (GetClientHealth(victim) <= TF2_GetPlayerMaxBuffedHealth(victim)) // only do this if they're not already overhealed & vita_saw_allow_overheal is 1
			{

				if(IsValidEntity(TF2_GetPlayerLoadoutSlot(victim, TF2LoadoutSlot_Secondary)) && GetEntProp(TF2_GetPlayerLoadoutSlot(victim, TF2LoadoutSlot_Secondary), Prop_Send, "m_iItemDefinitionIndex") == 57) //CHECKS IF IT'S RAZORBACK
				{
					if(amount > 139)
					{
						if (GetConVarBool(FindConVar("vita_saw_allow_overheal"))){
							SetEntityHealth(victim, 140);
							HitVitaSaw(attacker, victim, heal);
						}else
						{
							
							if (clientHP < TF2_GetPlayerMaxHealth(victim)) 
							{
								
								SetEntityHealth(victim, GetClientHealth(victim) + heal);
								HitVitaSaw(attacker, victim, heal);
							}

						}
					}
					else
					{
						SetEntityHealth(victim, amount);
						HitVitaSaw(attacker, victim, heal);
					}
				}
				else
				{
					if (GetConVarBool(FindConVar("vita_saw_allow_overheal")))
					{
						if (amount >= TF2_GetPlayerMaxBuffedHealth(victim)) 
						{
							
							SetEntityHealth(victim, TF2_GetPlayerMaxBuffedHealth(victim));
							HitVitaSaw(attacker, victim, heal);
							
						}else
						{
							SetEntityHealth(victim, GetClientHealth(victim) + heal);
							HitVitaSaw(attacker, victim, heal);
						}
					}else
					{
						if (clientHP < TF2_GetPlayerMaxHealth(victim)) 
						{
							
							SetEntityHealth(victim, GetClientHealth(victim) + heal);
							HitVitaSaw(attacker, victim, heal);
						}
					}
					
				}

				
			}

			
			
			RemoveDebuffs(victim, attacker);
			return Plugin_Continue;
		}
	}
	//Vita-saw code - end
	//Blutsauger code - start
	
	if((IsValidEntity(victim) && IsValidEntity(attacker) && IsValidEntity(inflictor)) &&
			(victim <= MaxClients && victim > 0) &&
			(attacker <= MaxClients && attacker > 0)) //Validity checks
	{
		/*
				Checks if: The weapon is the blutsauger, the medic is hitting a teammate/enemy, applies self-heal/overheal decided by cvars
			*/
		if((IsClientInGame(victim) && IsClientInGame(attacker)) &&
				(damagetype == DMG_TYPE_SYRINGE || damagetype == DMG_TYPE_SYRINGE_CRIT))
		{
			//int iActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			int iActiveWeapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
			if(iActiveWeapon != -1 && GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex") == 36)
			{
				
				if(TF2_GetClientTeam(attacker) == TF2_GetClientTeam(victim) && !TF2_IsPlayerInCondition(victim, TFCond_Ubercharged))
				{
					int iBlutHealthBuff = GetClientHealth(attacker) + GetConVarInt(FindConVar("blutsauger_heal_team"));
					int iMaxHealth = TF2_GetPlayerMaxHealth(attacker);
					int iMaxBuffedHealth = TF2_GetPlayerMaxBuffedHealth(attacker);
					int iCurrentHealth = GetClientHealth(attacker);
					
					int blutsauger_heal_team_amount = GetConVarInt(FindConVar("blutsauger_heal_team"));
					
					int iBlutHealthBuff_victim = GetClientHealth(victim) + GetConVarInt(FindConVar("blutsauger_heal_team"));
					int iMaxHealth_victim = TF2_GetPlayerMaxHealth(victim);
					int iMaxBuffedHealth_victim = TF2_GetPlayerMaxBuffedHealth(victim);
					int iCurrentHealth_victim = GetClientHealth(victim);
					int iMaxBuffedHealth_victim_razorback = iMaxHealth_victim + GetConVarInt(FindConVar("blutsauger_razorback_max_overheal"));
					
					if(iBlutHealthBuff < iMaxHealth && !GetConVarBool(FindConVar("blutsauger_heal_team_allow_overheal")))
					{
						SetEntityHealth(attacker, iBlutHealthBuff);
						HitBlutsauger(attacker, false);
					}
					else if(iBlutHealthBuff >= iMaxHealth && iCurrentHealth < iMaxHealth && !GetConVarBool(FindConVar("blutsauger_heal_team_allow_overheal")))
					{
						SetEntityHealth(attacker, iMaxHealth);
						HitBlutsauger(attacker, false);
					}
					if(GetConVarBool(FindConVar("blutsauger_heal_team_allow_overheal")))
					{
						if(iBlutHealthBuff > iMaxBuffedHealth)
						{
							SetEntityHealth(attacker, iMaxBuffedHealth);
							HitBlutsauger(attacker, false);
						}
						else if(iCurrentHealth < iMaxBuffedHealth)
						{
							SetEntityHealth(attacker, iBlutHealthBuff);
							HitBlutsauger(attacker, false);
						}
					}
					
					//Code that handles healing of teammates
					if(iBlutHealthBuff_victim < iMaxHealth_victim && !GetConVarBool(FindConVar("blutsauger_heal_team_allow_overheal")))
					{
						SetEntityHealth(victim, iBlutHealthBuff_victim);
						PlayerHealedOther(attacker,  float(blutsauger_heal_team_amount));
						HitBlutsauger(victim, false);
					}
					else if(iBlutHealthBuff_victim >= iMaxHealth_victim && iCurrentHealth_victim < iMaxHealth_victim && !GetConVarBool(FindConVar("blutsauger_heal_team_allow_overheal")))
					{
						SetEntityHealth(victim, iMaxHealth_victim);

						PlayerHealedOther(attacker,  float(blutsauger_heal_team_amount));
						HitBlutsauger(victim, false);
					}
					
					if(GetConVarBool(FindConVar("blutsauger_heal_team_allow_overheal")))
					{
						if(iBlutHealthBuff_victim > iMaxBuffedHealth_victim)
						{
							SetEntityHealth(victim, iMaxBuffedHealth_victim);
							HitBlutsauger(victim, false);
							PlayerHealedOther(attacker,  float(blutsauger_heal_team_amount));
						}
						else if(iCurrentHealth_victim < iMaxBuffedHealth_victim)
						{
							SetEntityHealth(victim, iBlutHealthBuff_victim);
							HitBlutsauger(victim, false);
							PlayerHealedOther(attacker,  float(blutsauger_heal_team_amount));
						}
					}
					if((GetConVarBool(FindConVar("blutsauger_heal_team_allow_overheal"))) &&
							(TF2_GetPlayerClass(victim) == TFClass_Sniper) &&
							(IsValidEntity(TF2_GetPlayerLoadoutSlot(victim, TF2LoadoutSlot_Secondary))) && 
							(GetEntProp(TF2_GetPlayerLoadoutSlot(victim, TF2LoadoutSlot_Secondary), Prop_Send, "m_iItemDefinitionIndex") == 57))
					{
						if(iBlutHealthBuff_victim > iMaxBuffedHealth_victim_razorback)
						{
							SetEntityHealth(victim, iMaxBuffedHealth_victim_razorback);
							HitBlutsauger(victim, false);
							PlayerHealedOther(attacker,  float(blutsauger_heal_team_amount));
						}
						else if(iCurrentHealth_victim < iMaxBuffedHealth_victim_razorback)
						{
							SetEntityHealth(victim, iBlutHealthBuff_victim);
							HitBlutsauger(victim, false);
							PlayerHealedOther(attacker,  float(blutsauger_heal_team_amount));
						}
					}
				}
				if((TF2_GetClientTeam(attacker) != TF2_GetClientTeam(victim)) && 
						(GetClientHealth(attacker) >= TF2_GetPlayerMaxHealth(attacker)) && 
						(!TF2_IsPlayerInCondition(victim, TFCond_Ubercharged)) && 
						(!TF2_IsPlayerInCondition(victim, TFCond_Cloaked) && !TF2_IsPlayerInCondition(victim, TFCond_Disguised)))
				{
					int iBlutHealthBuff = GetClientHealth(attacker) + GetConVarInt(FindConVar("blutsauger_heal_enemy"));
					//int iMaxHealth = TF2_GetPlayerMaxHealth(attacker) - 1;
					int iMaxBuffedHealth = TF2_GetPlayerMaxBuffedHealth(attacker);
					
					if(iBlutHealthBuff > iMaxBuffedHealth)
					{
						SetEntityHealth(attacker, TF2_GetPlayerMaxBuffedHealth(attacker));
						HitBlutsauger(attacker, true);
					}
					else
					{
						SetEntityHealth(attacker, iBlutHealthBuff);
						HitBlutsauger(attacker, true);
					}
				}
			}
			return Plugin_Continue;
		}
	} //Blutsauger code - end
	return Plugin_Continue;
}

stock void HitVitaSaw(int attacker, int victim, int heal)
{

	if (!Timer_g_Vita_Hit_Count[victim] && g_Vita_Hit_Count[victim] != 0)
	{
	
	CreateTimer(g_CV_VitaSawComboTime, VitaSawCoolDown, victim);
	Timer_g_Vita_Hit_Count[victim] = g_Vita_Hit_Count[victim];
	
	
	}

	function_playhealsounds(attacker, victim);
	function_upuber(attacker);
	ShowHealthGain(victim, heal, attacker);
	
	int statamount = heal;
	//PrintToServer("%d statamount", statamount)
	PlayerHealedOther(attacker,  float(statamount));
	
	//logging
	LogPlayerEvent(attacker, "triggered", "vita_saw_medic");
	LogPlayerEvent(victim, "triggered", "vita_saw_patient");

	g_HitWithStrongVitaSaw[victim] = true;
}
stock void HitBlutsauger(int attacker, bool IsHittingEnemy)
{
	if(IsHittingEnemy)
	{
		ShowHealthGain(attacker, GetConVarInt(FindConVar("blutsauger_heal_enemy")), attacker);
	}
	else if(!IsHittingEnemy)
	{
		ShowHealthGain(attacker, GetConVarInt(FindConVar("blutsauger_heal_team")), attacker);
	}
}
stock void RemoveDebuffs(int victim, int attacker)
{

	//ExtinguishPlayer (victim);
	
	if (TF2_IsPlayerInCondition(victim, TFCond_OnFire))
	{
		//EmitSoundToAll(sExtinguish, victim);
		float fVictimAbsOrigin[3];
		GetClientAbsOrigin(victim, fVictimAbsOrigin);
		
		EmitAmbientSound(sExtinguish, fVictimAbsOrigin, victim, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
		LogPlayerEvent(attacker, "triggered", "vita_saw_extinguish");
	}
	//ExtinguishPlayer(victim);
	
	TF2_RemoveCondition(victim, TFCond_OnFire);
	TF2_RemoveCondition(victim, TFCond_Jarated);
	TF2_RemoveCondition(victim, TFCond_Milked);
	TF2_RemoveCondition(victim, TFCond_MarkedForDeath);
	TF2_RemoveCondition(victim, TFCond_Gas);
}

stock void function_playhealsounds(attacker, victim)
{
	float fVictimAbsOrigin[3];
	float fAttackerAbsOrigin[3];
	GetClientAbsOrigin(victim, fVictimAbsOrigin);
	GetClientAbsOrigin(attacker, fAttackerAbsOrigin);
	
	EmitAmbientSound(sHealNoise, fVictimAbsOrigin, victim, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
	EmitAmbientSound(sHealNoise, fAttackerAbsOrigin, attacker, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
}
stock void function_upuber(attacker)
{
	medigun = GetPlayerWeaponSlot(attacker, 1);
	uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
	if (uber + g_CV_VitaSawUber > 0.99)
	{
		SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 1.00);
	}
	else
	{
		SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", (uber + g_CV_VitaSawUber));
	}
}
// stock functions from sm community
stock int GetWeaponIndex(iWeapon)
{
	return IsValidEnt(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}
stock bool IsValidEnt(iEnt)
{
	return iEnt > MaxClients && IsValidEntity(iEnt);
}
stock GetIndexOfWeaponSlot(iClient, iSlot)
{
	return GetWeaponIndex(GetPlayerWeaponSlot(iClient, iSlot));
}
stock int TF2_GetPlayerMaxHealth(int client)
{
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}
stock int TF2_GetPlayerMaxBuffedHealth(int client)
{
	return RoundToNearest(GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxBuffedHealth", _, client) * 1.5);
}
//stock int TF2_GetPlayerMaxBuffedHealth(int client)
//{
//    return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxBuffedHealth", _, client);
//}
stock bool IsValidClient(iClient)
{
	return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}
//MANNED MACHINES CODE
bool isMiniBoss(int client)
{
    if(IsValidClient(client))
    {
        if(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
        {
            if(g_cv_bDebugMode) PrintToChatAll("%N Was mini boss", client);
            return true;
        }
        else
        {
            if(g_cv_bDebugMode)PrintToChatAll("%N Was not mini boss", client);
            return false;
        }
    }
    return false;
}

// stock float GiveChargeAmount(int client)
//{
/* 	int iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	Address addr = TF2Attrib_GetByDefIndex(iWeapon, 10);
	float old;
	
	TF2Attrib_HookValueFloat

	if (addr != Address_Null)
	{
		old = TF2Attrib_GetValue(addr);
		if(g_cv_bDebugMode)PrintToChatAll("========================");
		if(g_cv_bDebugMode)PrintToChatAll("GOT THE ATTRIBUTE at %f", old);
		if(g_cv_bDebugMode)PrintToChatAll("========================");
	}else{
		if(g_cv_bDebugMode)PrintToChatAll("========================");
		if(g_cv_bDebugMode)PrintToChatAll("FAILED AT GETTING THE ATTRIBUTE");
		if(g_cv_bDebugMode)PrintToChatAll("========================");
	}
	
	//if(g_cv_bDebugMode)PrintToChatAll("OLD CHARGE %f", old);
	
	return old; */
// }

// public Action SetOriginalChargeRate(int client){//



// int iWeapons = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

// Address pAttribute = TF2Attrib_GetByName(iWeapons, "ubercharge rate bonus");

// if(pAttribute != Address_Null)
// {

// g_Original_Chargerate[client] = TF2Attrib_GetValue(pAttribute);


// if(g_cv_bDebugMode)PrintToChatAll("========================");
// if(g_cv_bDebugMode)PrintToChatAll("GOT ORIGINAL CHARGERATE at %f", g_Original_Chargerate[client]);
// if(g_cv_bDebugMode)PrintToChatAll("========================");

// g_Got_Original_Value[client] = true;

// }else{
// if(g_cv_bDebugMode)PrintToChatAll("========================");
// if(g_cv_bDebugMode)PrintToChatAll("FAILED AT GETTING CHARGE RATE %f", g_Original_Chargerate[client]);
// if(g_cv_bDebugMode)PrintToChatAll("========================");
// }


// }

/* public Action SetOriginalChargeRate(int client){

	Address pAttribute;
	
	int iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	
	//float chargerate;
	
		if(g_cv_bDebugMode)PrintToChatAll("========================");
		if(g_cv_bDebugMode)PrintToChatAll("SetOriginalChargeRate was called and iWeapon was %i", iWeapon);
		if(g_cv_bDebugMode)PrintToChatAll("========================");
	
	if((pAttribute = TF2Attrib_GetByName(iWeapon, "ubercharge rate bonus")) != Address_Null)
	{
		
		g_Original_Chargerate[client] = TF2Attrib_GetValue(pAttribute);
		//chargerate = TF2Attrib_GetValue(pAttribute);
		
		if(g_cv_bDebugMode)PrintToChatAll("========================");
		if(g_cv_bDebugMode)PrintToChatAll("GOT ORIGINAL CHARGERATE was %f", g_Original_Chargerate[client]);
		if(g_cv_bDebugMode)PrintToChatAll("========================");
		
		g_Got_Original_Value[client] = true;
		
		//return chargerate;
		
	}else{
		if(g_cv_bDebugMode)PrintToChatAll("========================");
		if(g_cv_bDebugMode)PrintToChatAll("FAILED AT ORIGINAL CHARGERATE");
		if(g_cv_bDebugMode)PrintToChatAll("========================");
		//return -1.0;
	}

	
} */