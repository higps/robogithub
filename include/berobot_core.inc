#if defined _berobot_core_included
 #endinput
#endif
#define _berobot_core_included "0.1"

/**
 * returns the robot-definition 
 * 
 * @param name      name of the robot-definition
 * @param robot     buffer to store robot-definiton
 * @noreturn
 */
native int GetRobotDefinition(char name[NAMELENGTH], const any[] robot);

/**
 * returns the name of the robot picked by a client
 * 
 * @param client            clientId to check
 * @param dest              buffer to store value
 * @param maxDestLength     maximum length of string-buffer
 * @noreturn
 */
native void GetPickedRobot(int client, char[] dest, int maxDestLength);

/**
 * checks if a client is any robot
 * 
 * @param client    clientId to check for robot
 * 
 * @return          true: client is a robot;
 *                  false: client is _not_ a robot
 */
native bool IsAnyRobot(int client);

/**
 * starts a vote who wants to be robot
 * 
 * @param neededRobots    number of robots needed to start a round
 * @noreturn
 */
native void StartAutomaticVolunteerVote(int neededRobots);

/**
 * checks if automatic volunteer vote is in progress
 * 
 * @return      true if automatic volunteer vote is in progress
                flase if no automatic volunteer vote is in progress
 */
native bool AutomaticVolunteerVoteIsInProgress();

/**
 * sets the provided clientIds as volunteers
 * 
 * @param volunteers    array of clientIds that should be set as volunteers
 * @param length        length of the volunteers-array
 * @noreturn
 */
native void SetVolunteers(int[] volunteers, int length);

/**
 * returns which classes have deep robot voicelines (opposed to only normal robot voicelines)
 * 
 * @param class     the class to check
 * @return          true: class has deep robot voicelines;
 *                  false: class has only normal robot voicelines
 */
stock bool ClassHasDeepRobotVoiceLines(TFClassType class)
{
	switch (class)
	{
		case TFClass_Scout: return true;
		case TFClass_Soldier: return true;
		case TFClass_Pyro: return true;
		case TFClass_DemoMan: return true;
		case TFClass_Heavy: return true;
		case TFClass_Engineer: return false;
		case TFClass_Medic: return false;
		case TFClass_Sniper: return false;
		case TFClass_Spy: return false;
		default: 
		{
			SMLogTag(SML_ERROR, "unknown class when checking for deep robot voice lines: %s", class);
			return false;
		}
	}
}

/**
 * translates a tf2-class into a string
 * 
 * @param class      class to translate
 * @param name       buffer to store value
 * @param maxlen     maximum length of string-buffer
 * @noretrurn
 */
stock void TF2_GetNameOfClass(TFClassType class, char[] name, int maxlen)
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}


stock bool IsValidClient(int client, bool replaycheck = true)
{
    if(client <= 0 || client > MaxClients)
        return false;
    if(!IsClientInGame(client))
        return false;
    if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
        return false;
    if(replaycheck)
    {
        if(IsClientSourceTV(client) || IsClientReplay(client))
            return false;
    }
    return true;
}
/*
	Swaps and respawns a player to a specified team.
	
	TFTeam_Unassigned = 0,
	TFTeam_Spectator = 1,
	TFTeam_Red = 2,
	TFTeam_Blue = 3
*/
stock void TF2_SwapTeamAndRespawn(int client, int team)
{
    SetEntProp(client, Prop_Send, "m_lifeState", 2);
    ChangeClientTeam(client, team);
    TF2_RespawnPlayer(client);
    SetEntProp(client, Prop_Send, "m_lifeState", 0);
}