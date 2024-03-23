#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <berobot_constants>
#include <berobot>
#include <sdkhooks>
#include <tf_ontakedamage>
 
#define PLUGIN_VERSION "1.0"
#define ROBOT_NAME	"Samwiz"
#define BANANA_MODEL "models/items/banana/banana.mdl"
#define BananaHat 30643

public Plugin:myinfo =
{
	name = "[TF2] Be the Giant Samwiz",
	author = "HiGPS | Bmod.TF",
	description = "Play as the Giant Samwiz from youtube",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public void OnMapStart()
{
	PrecacheModel(BANANA_MODEL);
}


bool g_BananaMode = false;
float g_DamageDone = 0.0;

// public TF2_OnConditionRemoved(client, TFCond:condition)
// {

// }

public TF2_OnConditionAdded(client, TFCond:condition)
{
    if (IsRobot(client, ROBOT_NAME))
    {

		if(condition == TFCond_SpeedBuffAlly){
			FindHat(client);
		}
		if(condition == TFCond_Taunting)
			{
			int tauntid = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");

		//PrintToChatAll("Taunt ID %i", tauntid);
		

			if (tauntid == -1)
			{
			//	TF2_AddCondition(client, TFCond_SpawnOutline, 10);
				CreateTimer(1.2, Timer_Taunt_Cancel, client);
			}	  
		}

	}
}

public Action:Timer_Taunt_Cancel(Handle:timer, any:client)
{
	if (IsValidClient(client)){
		TF2_RemoveCondition(client, TFCond_Taunting);
		
	}
}



public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
    // if (!g_Enable)
    //     return Plugin_Continue;
	if(!IsValidClient(victim))
	return Plugin_Continue;    
	if(!IsValidClient(attacker))
	return Plugin_Continue;

	if (IsRobot(attacker, ROBOT_NAME))
	{

	if (g_BananaMode)
	{
		SpawnBombs(victim, attacker);
	}else
	{
		g_DamageDone += damage;
	}
	}
	return Plugin_Continue;
}

void SetProjectileModel (int iEntity)
{
	SetEntityModel(iEntity, BANANA_MODEL);
}

void SpawnBombs(int client, int attacker)
{
	
	int team = GetClientTeam(attacker);
	float pos[3], vel[3], ang[3];
	int children = 1;
	float speed = 250.0;


	GetEntPropVector(client, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	

	pos[2] += 120.0;
	for (int i = 1; i <= children; i++)
	{
		int child = CreateEntityByName("tf_projectile_pipe");
		
		
		float child_vel[3];
		float child_ang[3];

		//Prevent child grenades from detonating on contact
		SetEntProp(child, Prop_Send, "m_bTouched", 1);

		//Set properties
		//SetEntProp(child, Prop_Send, "m_bCritical", view_as<int>(crit));
		SetEntPropEnt(child, Prop_Data, "m_hOwnerEntity", attacker);
		SetEntPropFloat(child, Prop_Send, "m_flDamage", 100.0);
		SetEntPropFloat(child, Prop_Send, "m_flModelScale", 1.2);

		for (int axis = 0; axis < 3; axis++){

			child_vel[axis] = vel[axis] + GetRandomFloat(speed * -1.0, speed);
			child_ang[axis] = ang[axis] + GetRandomFloat(0.0 , 360.0);
		}
		child_vel[2] = FloatAbs(child_vel[2]);

		SetEntProp(child, Prop_Send, "m_iTeamNum", team);
		SetEntProp(child, Prop_Send, "m_bIsLive", 1);

		DispatchSpawn(child);
		//SDKHook(child, SDKHook_Touch, OnMirvOverlap);
		TeleportEntity(child, pos, child_ang, child_vel);
		RequestFrame(SetProjectileModel, child);
	}
}


bool g_button_held[MAXPLAYERS + 1] = {false, ...};
float g_duration = 12.0;
float FireModeTimer = -1.0;
float g_skill; 
float g_skill_cooldown = 600.0;
// float g_skill_time;

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsRobot(client, ROBOT_NAME))
	{
		//0 = fireball
		//PrintToChat(client, "Throwing spell!");
		if( GetEntProp(client, Prop_Data, "m_afButtonPressed") & (IN_ATTACK3|IN_USE)) 
		{
			// PrintToChatAll("Press");
            g_button_held[client] = true;
		}



		if( GetEntProp(client, Prop_Data, "m_afButtonReleased") & (IN_ATTACK3|IN_USE)) 
		{
			// PrintToChatAll("Release");
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
	//PrintToChatAll("Damage: %f, skilltime %f", g_DamageDone, g_skill_cooldown);

	// int iCountDown = RoundToCeil(g_skill_time - g_skill);
	int iCountDownFiring = RoundToCeil(FireModeTimer - g_skill);
	
	Format(sHUDText, sizeof(sHUDText), "Banana Mode: %i %%%%\n    %s",iPercents, sProgress);

	if(iPercents >= 100)
	{

			if (g_BananaMode){
				Format(sHUDText, sizeof(sHUDText), "Banana Mode! %i", iCountDownFiring);
				SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 0, 255);
			}else{
				Format(sHUDText, sizeof(sHUDText), "Banana Mode Ready!\nUse Special Attack to Activate!");
				SetHudTextParams(0.85, 0.6, 0.1, 0, 255, 0, 255);	
				}


			
	}else {

		SetHudTextParams(0.85, 0.6, 0.1, 255, 255, 255, 255);
	}

	if (g_button_held[client] && iPercents >= 100 && !g_BananaMode)
		{
			if (FireModeTimer <= GetEngineTime() || FireModeTimer == -1.0)
			{
				
				EnterBananaMode(client);
			
			}
		}

	if (FireModeTimer <= GetEngineTime() && g_BananaMode)
	{
		g_BananaMode = false;
		g_DamageDone = 0.0;
		FindHat(client);
	}


	ShowHudText(client, -3, sHUDText);
	// b_hud_clamp[client] = false;
}

void EnterBananaMode(int client)
{

	// g_skill_time = g_duration;
	g_BananaMode = true;
	FireModeTimer = GetEngineTime() + g_duration;
	FindHat(client);


}

public FindHat(int iClient)
{
	int iWearableItem = -1;
	// PrintToServer("LOOKING HAT 1 !");
	while ((iWearableItem = FindEntityByClassname(iWearableItem, "tf_wearable*")) != -1) // Regular hats.
	{	
		// We check for the wearable's item def index and its owner.
		int iWearableIndex = GetEntProp(iWearableItem, Prop_Send, "m_iItemDefinitionIndex");
		int iWearableOwner = GetEntPropEnt(iWearableItem, Prop_Send, "m_hOwnerEntity");
		// PrintToServer("LOOKING HAT 2 !");
		// If the owners match.
		if (iWearableOwner == iClient)
		{
			// Going through all items. 4 = cosmetics
			for (int i = 0; i < 4; i++)
			{			
				// PrintToServer("LOOKING HAT 3 !");
				// If a weapon's definition index matches with the one stored...
				if (iWearableIndex == BananaHat)
				{
					// PrintToServer("FOUND HAT! %i", iWearableItem);
					if (g_BananaMode){
						SetEntityRenderMode(iWearableItem, RENDER_NORMAL);
					}else
					{
						SetEntityRenderMode(iWearableItem, RENDER_NONE);
					}
					//SetEntityRenderFx(iWearableItem, RENDER_TRANSALPHA);
					// return true;
				}
			}
		}
	}
	// return false;
}
