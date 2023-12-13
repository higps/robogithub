#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2attributes>
#include <tf_custom_attributes>
#include <stocksoup/var_strings>
#pragma semicolon 1
#pragma newdecls required

#define DEFAULT_POWERUP_CHARGES	3

enum PowerupBottleType
{
	POWERUP_BOTTLE_NONE, 
	
	POWERUP_BOTTLE_CRITBOOST, 
	POWERUP_BOTTLE_UBERCHARGE, 
	POWERUP_BOTTLE_RECALL, 
	POWERUP_BOTTLE_REFILL_AMMO, 
	POWERUP_BOTTLE_BUILDINGS_INSTANT_UPGRADE, 
	POWERUP_BOTTLE_RADIUS_STEALTH, 
	POWERUP_BOTTLE_SEE_CASH_THROUGH_WALL, 
	
	POWERUP_BOTTLE_TOTAL
};

int g_type[MAXPLAYERS + 1];
int g_charges[MAXPLAYERS + 1];
int g_charges_on_kill[MAXPLAYERS + 1];
int g_kills_needed_refill[MAXPLAYERS + 1];
int g_max_charge[MAXPLAYERS + 1];
int kills[MAXPLAYERS + 1] = {0,...};

bool HasStats(int client)
{
	char stat_buffer[256];
	if (!TF2CustAttr_GetString(client, "has-canteen", stat_buffer, sizeof(stat_buffer))) {
		return false;
	}

	g_type[client] = ReadIntVar(stat_buffer, "type", 1);
	g_charges[client] = ReadIntVar(stat_buffer, "start-charges", 1);
	g_charges_on_kill[client] = ReadIntVar(stat_buffer, "charges-on-kill", 1);
	g_kills_needed_refill[client] = ReadIntVar(stat_buffer, "kills-needed", 1);
	g_max_charge[client] = ReadIntVar(stat_buffer, "max-charge", 1);
	return true;
	
}

public Plugin myinfo = 
{
	name = "Manned Machines Attribute for setting Power Up Canteen Charges", 
	author = "HiGPS | Bmod.TF Mikusch", 
	description = "Sets charges on your Power Up Canteen", 
	version = "1.0.0", 
	url = "https://github.com/Mikusch/canteens"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	LoadTranslations("canteens.phrases.txt");
	
	RegAdminCmd("sm_canteen", ConCmd_SetPowerupBottleCharges, ADMFLAG_ROOT);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.6, Timer_StatCheck, client);
	return Plugin_Continue;
}
public Action Event_PlayerDeath(Event event, char[] name, bool dontBroadcast){

	int client = GetClientOfUserId(event.GetInt("attacker"));
	if(HasStats(client)){ 
		
		

		if (kills[client] >= g_kills_needed_refill[client])
		{
		ApplyCharge(client, view_as<PowerupBottleType>(g_type[client]), g_charges_on_kill[client]);
		kills[client] = 0;
		}
		else
		{
			kills[client]++;
		}
	}
	else
	{
		kills[client] = 0;
	}
	return Plugin_Continue;
}

public Action Timer_StatCheck(Handle timer, int client)
{
    if (HasStats(client))
    { 
        ApplyCharge(client, view_as<PowerupBottleType>(g_type[client]), g_charges[client]);
    }

	return Plugin_Continue;
}

public Action ConCmd_SetPowerupBottleCharges(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		ReplyToCommand(client, "%t", "SetPowerupBottleCharges_Usage");
		return Plugin_Handled;
	}
	
	PowerupBottleType type;
	int charges = DEFAULT_POWERUP_CHARGES;
	
	char arg[64];
	if (GetCmdArg(1, arg, sizeof(arg)) > 0)
		type = view_as<PowerupBottleType>(StringToInt(arg));
	if (GetCmdArg(2, arg, sizeof(arg)) > 0)
		charges = StringToInt(arg);
	
	ApplyCharge(client, type, charges);
	return Plugin_Continue;
}

public Action ApplyCharge(int client, PowerupBottleType type, int charges)
{
	int bottle = MaxClients + 1;
	while ((bottle = FindEntityByClassname(bottle, "tf_powerup_bottle*")) != -1)
	{
		if (GetEntPropEnt(bottle, Prop_Send, "m_hOwnerEntity") == client)
		{
			//Clear old powerup(s)
			for (PowerupBottleType i = POWERUP_BOTTLE_NONE; i < POWERUP_BOTTLE_TOTAL; i++)
			{
				char attrib[64];
				if (GetAttributeNameForPowerupType(i, attrib, sizeof(attrib)))
				{
					TF2Attrib_RemoveByName(client, attrib);
				}
			}
			
			if (type == POWERUP_BOTTLE_NONE)
			{
				SetEntProp(bottle, Prop_Send, "m_usNumCharges", 0);
			}
			else
			{
				//Apply powerup
				char attrib[64];
				if (GetAttributeNameForPowerupType(type, attrib, sizeof(attrib)))
				{
					TF2Attrib_SetByName(client, attrib, 1.0);
				}
				else
				{
					ReplyToCommand(client, "%t", "Unknown_Powerup_Type", type);
					return Plugin_Handled;
				}
				int current_charge = GetEntProp(bottle, Prop_Send, "m_usNumCharges");

				int new_charge = current_charge + charges;
				//Prevent Charges going over 5
				if (new_charge > g_max_charge)new_charge = g_max_charge;
				SetEntProp(bottle, Prop_Send, "m_usNumCharges", new_charge);
				//Add visual effect to see when it refills
				TF2_AddCondition(client, TFCond_InHealRadius, 0.5);
				
			}
			
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

bool GetAttributeNameForPowerupType(PowerupBottleType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case POWERUP_BOTTLE_CRITBOOST:
		{
			return strcopy(buffer, maxlen, "critboost") > 0;
		}
		case POWERUP_BOTTLE_UBERCHARGE:
		{
			return strcopy(buffer, maxlen, "ubercharge") > 0;
		}
		case POWERUP_BOTTLE_RECALL:
		{
			return strcopy(buffer, maxlen, "recall") > 0;
		}
		case POWERUP_BOTTLE_REFILL_AMMO:
		{
			return strcopy(buffer, maxlen, "refill_ammo") > 0;
		}
		case POWERUP_BOTTLE_BUILDINGS_INSTANT_UPGRADE:
		{
			return strcopy(buffer, maxlen, "building instant upgrade") > 0;
		}
		default:
		{
			return false;
		}
	}
}