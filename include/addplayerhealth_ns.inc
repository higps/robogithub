/*
	Converted for new sourcemod syntax (https://wiki.alliedmods.net/SourcePawn_Transitional_Syntax)
	
    Example usage: Blutsauger heals 50 hp via an attribute.
    But you want it to add to overheal via AddPlayerHealth because the attribute doesn't do so.
    You can't just call AddPlayerHealth when he's less than MaxHealth because you'd see 10hp +50 +50 = 110 instead of stopping at 60
    You can't just check if his health is >= MaxHealth because if it's a scout at 100/125 hp, in that scenario he only heals 25 hp instead of 50, before being able to gain overheal.

    In the 100/125 scenario, this will return true to say we should use AddPlayerHealth. AddPlayerHealth will set the player's hp to 150/125 and thus prevent the attribute from doing anything.
    ... In OnTakeDamage. Dunno about player_hurt... UNTESTED


    Edit: This is now technically useless due to the ShowHealthGain() function I added - you can just remove the attribute, and always use AddPlayerHealth for every hit
*/
stock bool ReadyToOverheal(int iClient, int iAdd = 0, bool bAdd = false)
{
	return (bAdd) ? ((TF2_GetMaxHealth(iClient) - GetClientHealth(iClient)) < iAdd) : (GetClientHealth(iClient) >= TF2_GetMaxHealth(iClient));
}

/*
    Adds health to a player until they reach a certain amount of overheal.

    Does not go above the overheal amount.

    Defaults to normal medigun overheal amount.
*/

stock void AddPlayerHealth(int iClient, int iAdd, float flOverheal = 1.5, bool bAdditive = false, bool bEvent = false)
{
	int iHealth = GetClientHealth(iClient);
	int iNewHealth = iHealth + iAdd;
	int iMax = bAdditive ? (TF2_GetMaxHealth(iClient) + RoundFloat(flOverheal)) : TF2_GetMaxOverHeal(iClient, flOverheal);
	if (iHealth < iMax)
	{
		iNewHealth = min(iNewHealth, iMax);
		if (bEvent)
		{
			ShowHealthGain(iClient, iNewHealth-iHealth);
		}
		SetEntityHealth(iClient, iNewHealth);
	}
}

stock void ShowHealthGain(int iPatient, int iHealth, int iHealer = -1, bool bAddToScore = true)
{
	int iUserId = GetClientUserId(iPatient);
	
	Handle hEvent = CreateEvent("player_healed", true);
	
	SetEventBool(hEvent, "sourcemod", true);
	SetEventInt(hEvent, "patient", iUserId);
	SetEventInt(hEvent, "healer", IsValidClient(iHealer) ? GetClientUserId(iHealer) : iUserId);
	SetEventInt(hEvent, "amount", iHealth);
	
	FireEvent(hEvent);
	
	hEvent = CreateEvent("player_healonhit", true);
	
	SetEventBool(hEvent, "sourcemod", true);
	SetEventInt(hEvent, "amount", iHealth);
	SetEventInt(hEvent, "entindex", iPatient);
	
	//Adds to healing score if wanted
	if(bAddToScore)
	{
		Handle hGameConf;
		Handle hPlayerHealedOther;
		
		Address pGameStats;
		
		if((hGameConf = LoadGameConfigFile("playerhealedother")) != INVALID_HANDLE) // Needs the gamedata
		{
			StartPrepSDKCall(SDKCall_Raw);
		
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFGameStats::Event_PlayerHealedOther");
			
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			
			hPlayerHealedOther = EndPrepSDKCall();
			
			pGameStats = GameConfGetAddress(hGameConf, "CTFGameStats");
			
			SDKCall(hPlayerHealedOther, pGameStats, IsValidClient(iHealer) ? iHealer : iPatient, float(iHealth));
			
			delete hGameConf;
			delete hPlayerHealedOther;
		}
	}
	
	FireEvent(hEvent);
}
stock int TF2_GetMaxHealth(int iClient)
{
	int maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
	return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}

// Returns a client's max health if fully overhealed
stock float TF2_GetMaxOverHeal(int iClient, float flOverHeal = 1.5) // Quick-Fix would be 1.25
{
	return RoundFloat(float(TF2_GetMaxHealth(iClient)) * flOverHeal);
}

// Returns the amount of overheal a client can receive
stock float TF2_GetOverHeal(int iClient, float flOverHeal = 1.5)
{
	return RoundFloat(float(TF2_GetMaxHealth(iClient)) * (flOverHeal-1.0));
}

// SetEntityHealth works the same
stock void TF2_SetHealth(int iClient, int NewHealth)
{
	SetEntProp(iClient, Prop_Send, "m_iHealth", NewHealth);
	SetEntProp(iClient, Prop_Data, "m_iHealth", NewHealth);
} 