#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <berobot_constants>
#include <berobot>
#include <berobot_core>
#include <particle>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "berobot_death_effects",
    author = "Fragancia & Heavy Is GPS",
    description = "Robot death explosions, ragdoll removal and rune cleanup",
    version = "1.0.0",
    url = "bmod.tf"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int assister = GetClientOfUserId(GetEventInt(event, "assister"));

        if (IsAnyRobot(victim))
        {

            CreateTimer(0.0, RemoveBody, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
            float position[3];
            GetEntPropVector(victim, Prop_Data, "m_vecOrigin", position);	
            int attach = CreateEntityByName("trigger_push");
            TeleportEntity(attach, position, NULL_VECTOR, NULL_VECTOR);

            TE_Particle("hightower_explosion", position, _, _, attach, 1,0);	

        }

}

public Action RemoveBody(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (!IsValidClient(client)) return Plugin_Stop;

    if (HasEntProp(client, Prop_Send, "m_hRagdoll"))
    {
        int BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
        if(IsValidEdict(BodyRagdoll))
        {
            AcceptEntityInput(BodyRagdoll, "kill");

        }
    }
}

public void OnEntityCreated(int iEntity, const char[] sClassName) 
{
	if (StrContains(sClassName, "item_powerup_rune") == 0)
	{
		AcceptEntityInput(iEntity, "Kill");
	}

}
