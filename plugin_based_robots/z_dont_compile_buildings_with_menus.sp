#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <tfobjects>

enum struct ObjectPointer
{
	int reference; //reference

	void set(int entity)
	{
		if (IsValidEntity(entity) && entity > 0)
			this.reference = EntIndexToEntRef(entity);
		else
			this.reference = INVALID_ENT_REFERENCE;
	}

	int get()
	{
		return EntRefToEntIndex(this.reference);
	}

	void GetPos(float pos[3])
	{
		if (this.valid())
			GetEntPropVector(this.get(), Prop_Data, "m_vecOrigin", pos);
	}

	bool valid()
	{
		int ent = this.get();
		if (IsValidEntity(ent) && ent > 0)
			return true;

		return false;
	}
}

ObjectPointer PlayerTele[MAXPLAYERS + 1];

int SelectedIndex[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_teleportto", CmdTele);
}

Action CmdTele(int client, int args)
{
	ObjectPointer target;
	target = PlayerTele[client];

	if (target.valid())
	{
		float destination[3];
		target.GetPos(destination);

		destination[2] += 40.0;

		TeleportEntity(client, destination, NULL_VECTOR, NULL_VECTOR);
	}
	else
		PrintCenterText(client, "No teleporters found");

	return Plugin_Continue;
}

void GetFarthestTele(int client, ObjectPointer target, ObjectPointer teleporters[32]) //shouldn't ever be more than 32 teleporters at a time... really only 16 for team teleporters but doing 32 just in case
{
	float distance = 0.0;

	float origin[3], destination[3];

	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (TF2_GetPlayerClass(i) == TFClass_Engineer && GetClientTeam(client) == GetClientTeam(i)) //engineers on same team
			{
				ObjectPointer tele;
				tele.set(TF2_GetObjectOfType(i, TFObject_Teleporter, TFObjectMode_Exit, false));

				if (tele.valid())
				{
					teleporters[count] = tele;

					count++;

					tele.GetPos(destination);
					GetClientAbsOrigin(client, origin);

					float teleDistance = GetVectorDistance(origin, destination);
					if (teleDistance >= distance)
					{
						distance = teleDistance;
						target = tele;
					}
				}
			}
		}
	}
}

///
/// Finds all active teleporters, sets the farthest teleport as the current active teleporter
/// Status of the farthest teleporter
/// Just move this to wherever you need it to be
///

public Action OnPlayerRunCmd(int client)
{
	ObjectPointer teleporters[32];
	ObjectPointer farthest;
	GetFarthestTele(client, farthest, teleporters);

	CreateTeleMenu(client, teleporters);

	GetActiveSelection(client, PlayerTele[client], farthest);

	ObjectPointer tele;
	tele = PlayerTele[client];

	char description[256];

	if (tele.valid())
	{
		int teleporter = tele.get();
		char teleName[64];
		int owner = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");

		if (owner > 0 && IsClientInGame(owner))
			FormatEx(teleName, sizeof teleName, "%N's Teleporter\n", owner);
		else
			FormatEx(teleName, sizeof teleName, "Teleporter: %i\n", teleporter);

		if (GetEntProp(teleporter, Prop_Send, "m_bDisabled"))
			FormatEx(description, sizeof description, "%sDisabled/Sapped", teleName);
		else
			FormatEx(description, sizeof description, "%sActive", teleName);
	}
	else
		FormatEx(description, sizeof description, "No Teleporter Found");

	PrintCenterText(client, description);

	return Plugin_Continue;
}

// Creates a menu with all active teleporters
void CreateTeleMenu(int client, ObjectPointer teleporters[32])
{
	if (!teleporters[0].valid()) // Only create a menu if teleporters exist
		return;

	Menu selection = new Menu(SelectionCallback);
	selection.SetTitle("Choose Teleporter Exit");

	selection.AddItem("-1", "Farthest Exit");

	for (int i = 0; i < 32; i++)
	{
		if (teleporters[i].valid())
		{
			int tele = teleporters[i].get();

			char index[8], teleName[256], teleStatus[32];
			IntToString(tele, index, sizeof index);

			int owner = GetEntPropEnt(tele, Prop_Send, "m_hBuilder");

			if (GetEntProp(tele, Prop_Send, "m_bDisabled"))
				FormatEx(teleStatus, sizeof teleStatus, "Sapped");
			else
				FormatEx(teleStatus, sizeof teleStatus, "Active");

			// Get the name of the teleporter's owner, otherwise set the teleporter's index as the name as a fallback
			if (IsClientInGame(owner))
				FormatEx(teleName, sizeof teleName, "%N's Exit (%s)", owner, teleStatus);
			else
				FormatEx(teleName, sizeof teleName, "Exit %i (%s)", tele, teleStatus);

			selection.AddItem(index, teleName);
		}
		else	// Stop populating if we find an invalid index
			break;
	}

	selection.Display(client, 3);
}

int SelectionCallback(Menu menu, MenuAction action, int client, int selection)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char value[8];
			menu.GetItem(selection, value, sizeof value);

			SelectedIndex[client] = StringToInt(value);
		}
	}
	return 0;
}

void GetActiveSelection(int client, ObjectPointer teleporter, ObjectPointer farthest)
{
	if (SelectedIndex[client] == -1) // farthest selection
		teleporter = farthest;
	else
		teleporter.set(SelectedIndex[client]);
}
