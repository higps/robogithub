#if defined _berobot_core_included
 #endinput
#endif
#define _berobot_core_included "0.1"

methodmap TimeLeftResource < TimeLeftResourceDefinition {
    property bool Active {
        public get(){
            return this.SecondsBeforeEndOfRound > 0;
        }
    }
    property bool Enabled {
        public get(){ 
            if (!this.Active)
                return true;

            bool value;
            this.GetValue("Enabled", value);
            return value;
        }
        public set(bool value){
            this.SetValue("Enabled", value);
        }
    }

    public TimeLeftResource() {
        TimeLeftResource resource = view_as<TimeLeftResource>(new StringMap());
        resource.Enabled = false;
        return resource;
    }

    public void GetRobotName(char buffer[NAMELENGTH])
    {
        this.GetString("RobotName", buffer, NAMELENGTH);
    }

    public TimeLeftResource From(TimeLeftResourceDefinition definition, char robotName[NAMELENGTH])
    {
        this.SetString("RobotName", robotName);
        if (definition == null)
        {
            SMLogTag(SML_VERBOSE, "TimeLeftResourceDefinition does not exist");
            return this;
        }
        SMLogTag(SML_VERBOSE, "assigning SecondsBeforeEndOfRound to %i", definition.SecondsBeforeEndOfRound);
        this.SecondsBeforeEndOfRound = definition.SecondsBeforeEndOfRound;
        SMLogTag(SML_VERBOSE, "SecondsBeforeEndOfRound is %i", this.SecondsBeforeEndOfRound);
        return this;
    }
}
methodmap Resources < StringMap {
    property TimeLeftResource TimeLeft {
        public get(){ 
            TimeLeftResource value;
            this.GetValue("TimeLeft", value);
            return value;
        }
        public set(TimeLeftResource value){
            this.SetValue("TimeLeft", value);
        }
    }

    public Resources() {
        return view_as<Resources>(new StringMap());
    }

    public bool IsEnabled()
    {
        return this.TimeLeft.Enabled;
    }

    public void From(ResourcesDefinition definition, char robotName[NAMELENGTH])
    {
        if (definition == null)
        {
            SMLogTag(SML_VERBOSE, "ResourcesDefinition created");
            definition = new ResourcesDefinition();
        }
        TimeLeftResource timeLeft = new TimeLeftResource();        
        this.TimeLeft = timeLeft.From(definition.TimeLeft, robotName);
    }
}
enum struct Robot {
  char name[NAMELENGTH];
  char role[NAMELENGTH];
  char class[9];
  char shortDescription[NAMELENGTH];
  PrivateForward callback;
  RobotSounds sounds;
  Resources resources;
}

/**
 * checks if the plugin is enabled
 * 
 * @return  true: plugin is enabled;
 *          false: plugin is disabled
 */
native bool IsEnabled();


/**
 * checks if the plugin is enabled
 * 
 * @return  true: plugin is enabled;
 *          false: plugin is disabled
 */
native bool IsYTEnabled();

/**
 * checks if robot-mode is active right now
 * 
 * @return  true: robot-mode is active;
 *          false: robot-mode is _not_ active
 */
native bool IsActive();

/**
 * returns the robot-definition 
 * 
 * @param name      name of the robot-definition
 * @param robot     buffer to store robot-definiton
 * @noreturn
 */
native int GetRobotDefinition(char name[NAMELENGTH], const any[] robot);

/**
 * returns all robot-resources 
 * 
 * @return  StringMap containing all resources per robot-name
 */
native ArrayList GetRobotResources();

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
 * starts a vote who wants to be robot
 * 
 * @noreturn
 */
native void StartAutomaticVolunteerVote();

/**
 * checks if automatic volunteer vote is in progress
 * 
 * @return      true if automatic volunteer vote is in progress; 
                flase if no automatic volunteer vote is in progress
 */
native bool AutomaticVolunteerVoteIsInProgress();

/**
 * returns a clientId of previously volunteered player
 * 
 * @param ignoredClientIds      array of clientIds that will be ignored when picking volunteer
 * @param maxDestLength         maximum length of ignoredClientIds-array
 * @return                      clientId of previously volunteered player; 
                                -1 if no volunteers are left
 */
native int GetRandomVolunteer(int[] ignoredClientIds, int length);

/**
 * sets the provided clientIds as volunteers
 * 
 * @param volunteers    array of clientIds that should be set as volunteers
 * @param length        length of the volunteers-array
 * @noreturn
 */
native void SetVolunteers(int[] volunteers, int length);

/**
 * adds a random volunteer to the robot team or removes a random robot from the robot team
 * depending on the current/wanted team-size
 * 
 * @noreturn
 */
native void EnsureRobotCount();

/**
 * turns a robot into human again
 * 
 * @param clientId    clientId of robot
 * @noreturn
 */
native void UnmakeRobot(int clientId);

/**
 * Called after robot-definition was added/removed
 * 
 * @noreturn
 */
forward void MM_OnRobotStorageChanged();

/**
 * Called after enabled-state changed
 * 
 * @noreturn
 */
forward void MM_OnEnabledChanged(int enabled);

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
 * @noreturn
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

/**
 * prints text with MannedMachine prefix and teamcolor
 * 
 * @param client    client to send the text to
 * @param text      text to be send
 * @noreturn
 */
stock void MM_PrintToChatAll(char[] text)
{
    for(int i = 1; i < MaxClients; i++)
    {
        if (!IsValidClient(i))
            continue;
        MM_PrintToChat(i, text);
    }
}

/**
 * prints text with MannedMachine prefix and teamcolor
 * 
 * @param client    client to send the text to
 * @param text      text to be send
 * @noreturn
 */
stock void MM_PrintToChat(int client, char[] text)
{
    MC_PrintToChatEx(client, client, "[ {orange}SM {default}] {teamcolor}%s", text);
}

/**
 * generates a random boolean based on the given uniform distribution
 * 
 * @param trueCases     count of cases that produce a true result
 * @param maxCases      count of all cases
 * @return              randomly true/false based on the given uniform distribution
 */
stock bool MM_Random(int trueCases, int maxCases)
{
    return true;
    
    int random = GetRandomInt(1, maxCases);
    return random <= trueCases;
}