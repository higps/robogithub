#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sm_logger>
#include <berobot_constants>
#include <berobot>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Artillery"

// #define GUNFIRE	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav"
// #define GUNFIRE_CRIT	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"
// #define GUNFIRE_EXPLOSION	")mvm/giant_soldier/giant_soldier_rocket_explode.wav"

//Artillery code

#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


public Plugin MyInfo =
{
	name = "[TF2] Artillery Rocket Launcher",
	author = "IvoryPal",
	description = "Rocket launcher that fires volleys of rockets.",
	version = "1.0"
}

ConVar g_arcDelay;
ConVar g_arcGrav;
bool arcRockets[MAXPLAYERS+1];
bool weaponArc[2049];
bool shouldArc[2049];
float arcDelay[2049];


public Plugin:myinfo = 
{
	name = "[TF2] Be the ICBM",
	author = "Erofix using the code from: Pelipoika, PC Gamer, Jaster and StormishJustice",
	description = "Play as the Giant Icebear from Frankfurt",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

char LOG_TAGS[][] = {"VERBOSE", "INFO", "ERROR"};
enum(<<= 1)
{
    SML_VERBOSE = 1,
    SML_INFO,
    SML_ERROR,
}

public OnPluginStart()
{
	//Artillery Code
	RegConsoleCmd("sm_arcrocket", CmdToggleArc);

	//HookEvent("post_inventory_application", Event_PlayerResupply);

	g_arcDelay = CreateConVar("tf_rocket_arc_delay", "0.5", "Delay in seconds before a rocket is affected by gravity");
	g_arcGrav = CreateConVar("tf_rocket_arc_gravity", "3.5", "Gravity to apply to arcing rockets");
}

public void OnClientPutInServer(int client)
{
	arcRockets[client] = false;
}

public Action CmdToggleArc(int client, int args)
{
	arcRockets[client] = !arcRockets[client];
	PrintToChat(client, "Artillery Launcher %s", arcRockets[client] ? "Enabled. Resupply to obtain it." : "Removed.");
	return Plugin_Continue;
}

public void OnEntityDestroyed(int ent)
{
	if (IsValidEntity(ent) && ent > MaxClients && weaponArc[ent])
	{
		weaponArc[ent] = false;
	}
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_rocket") || StrEqual(classname, "tf_projectile_energy_rocket"))
	{
		SDKHook(ent, SDKHook_SpawnPost, OnProjSpawn);
		SDKHook(ent, SDKHook_Spawn, Hook_OnProjectileSpawn);
	}
}

public void Hook_OnProjectileSpawn(iEntity) {
	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
	if (0 < iClient && iClient <= MaxClients && IsRobot(iClient, ROBOT_NAME)) {
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.5);
	}
}

public void OnGameFrame()
{
	int ent = MaxClients + 1;
	while ((ent = FindEntityByClassname(ent, "tf_projectile_rocket")) != -1 || (ent = FindEntityByClassname(ent, "tf_projectile_energy_rocket")) != -1)
	{
		if (shouldArc[ent] && arcDelay[ent] <= GetEngineTime())
		{
			ArcRocket(ent);
		}
	}
}

public Action OnProjSpawn(int proj)
{
	int owner = GetEntPropEnt(proj, Prop_Send, "m_hOwnerEntity");
	//int launcher = GetEntPropEnt(proj, Prop_Send, "m_hLauncher");
	
	if (IsRobot(owner, ROBOT_NAME))
	{
		shouldArc[proj] = true;
		arcDelay[proj] = GetEngineTime() + GetConVarFloat(g_arcDelay);
	}
	else
		shouldArc[proj] = false;

	return Plugin_Continue;
}

public void ArcRocket(int rocket)
{
	float vel[3], rot[3];
	float grav = GetConVarFloat(g_arcGrav);
	
	GetEntPropVector(rocket, Prop_Data, "m_vecVelocity", vel);
	GetEntPropVector(rocket, Prop_Send, "m_angRotation", rot);
	
	vel[2] -= Pow(grav, 2.0);
	
	GetVectorAngles(vel, rot);
	ClampAngle(rot);
	
	SetEntPropVector(rocket, Prop_Data, "m_vecVelocity", vel);
	SetEntPropVector(rocket, Prop_Send, "m_angRotation", rot);
	TeleportEntity(rocket, NULL_VECTOR, rot, vel);
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}
