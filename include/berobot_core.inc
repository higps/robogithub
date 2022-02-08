#if defined _berobot_core_included
 #endinput
#endif
#define _berobot_core_included "0.1"


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
 * returns all robot-restrictions 
 * 
 * @return  StringMap containing all restrictions per robot-name
 */
native ArrayList GetRobotRestrictions();

/**
 * turns a player into a mercenary again
 * 
 * @param client     the client in whos context the command should be executed
 * @param target     the target of the command (usualy "" can be "@me" etc.)
 * 
 * @return  error code 
            0: no error
            1: old robot not found. couldn't stop sounds
            1024: targeting error
 */
native int TrashRobot(int client, char target[32] = "");

/**
 * returns the name of the robot picked by a client
 * returns the name of the robot currently played by a client
 * 
 * @param client            clientId to check
 * @param dest              buffer to store value
 * @param maxDestLength     maximum length of string-buffer
 * @noreturn
 */
native void GetRobot(int client, char[] dest, int maxDestLength);

/**
 * returns the amount of robots per team
 * 
 * @return  count of robots per team
 */
native int GetRobotCountPerTeam();

/**
 * returns how many robots of a specified type are on the battlefield
 * 
 * @param robotname     name of the robot to check
 * @return              count of robots on the battlefield
 */
native int GetRobotCount(char robotname[NAMELENGTH]);

/**
 * returns the how many robots of a specified type are allowed on the battlefield
 * 
 * @param robotname     name of the robot to check
 * @return              count of robots on the battlefield
 */
native int GetRobotCap(char robotname[NAMELENGTH]);

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
 * turns a human into a specified robot
 * 
 * @param robotname     name robot that should be created
 * @param clientId      clientId of human
 * @noreturn
 */
native void SetRobot(char robotname[NAMELENGTH], int clientId);

/**
 * saves whether the provided client is repicking a robot
 *
 * @param clientId      client to whom repicking should be saved
 * @param repicking     true if client is repicking a robot; false otherwise;
 * 
 * @noreturn
 */
native void SetClientRepicking(int clientId, bool repicking);

/**
 * redraws robot-selection-menu 
 * 
 * @noreturn
 */
native void RedrawChooseRobotMenu();

/**
 * redraws robot-selection-menu for the provided client
 * 
 * @param clientId      client for whom the menu should be drawn again
 *
 * @noreturn
 */
native void RedrawChooseRobotMenuFor(int client);

/**
 * displays the robot-selection-menu to the provided client
 *
 * @param clientId      client to whom the menu should be displayed
 * 
 * @noreturn
 */
native void Menu_RobotSelection(int clientId);

/**
 * checks if client is repicking a robot
 *
 * @param clientId      client to check
 * 
 * @noreturn
 */
native bool IsRepicking(int clientId);

/**
 * keeps track of which client uses which robot and how many robots are used
 * 
 * @param clientId      clientId to keep track of
 * @param robotname     name of the robot of the client
 * @noreturn
 */
native void TrackRobot(int clientId, char robotname[NAMELENGTH]);

/**
 * keeps track of which clients robot was created
 * 
 * @param clientId      clientId to keep track of
 * @param created       true if the robot was just created, false otherwise
 * @noreturn
 */
native void TrackRobotCreation(int clientId, bool created);

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
 * Called while reseting a client from being a robot
 * 
 * @noreturn
 */
forward void MM_OnClientReseting(int clientId);

/**
 * Called when mode-reset was requested
 * 
 * @noreturn
 */
forward void MM_ModeResetRequested();

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
			//aSMLOGTag(SML_ERROR, "unknown class when checking for deep robot voice lines: %s", class);
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
    for(int i = 1; i <= MaxClients; i++)
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
    int random = GetRandomInt(trueCases, maxCases);
    if(random <= trueCases){
        return true;
    }else{
        return false;
    }
    
}

methodmap TimeLeftRestriction < TimeLeftRestrictionDefinition {
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

    public TimeLeftRestriction() {
        TimeLeftRestriction restriction = view_as<TimeLeftRestriction>(new StringMap());
        restriction.Enabled = false;
        return restriction;
    }

    public void GetRobotName(char buffer[NAMELENGTH])
    {
        this.GetString("RobotName", buffer, NAMELENGTH);
    }

    public TimeLeftRestriction From(TimeLeftRestrictionDefinition definition, char robotName[NAMELENGTH])
    {
        this.SetString("RobotName", robotName);
        if (definition == null)
        {
        //aSMLOGTag(SML_VERBOSE, "TimeLeftRestrictionDefinition does not exist");
            return this;
        }
        //aSMLOGTag(SML_VERBOSE, "assigning SecondsBeforeEndOfRound to %i", definition.SecondsBeforeEndOfRound);
        this.SecondsBeforeEndOfRound = definition.SecondsBeforeEndOfRound;
        //aSMLOGTag(SML_VERBOSE, "SecondsBeforeEndOfRound is %i", this.SecondsBeforeEndOfRound);
        return this;
    }
}

methodmap RobotCoins < RobotCoinRestrictionDefinition {
    property bool Active {
        public get(){
            return this.Overall > 0 || this.PerRobot > 0;
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

    public RobotCoins(char robotName[NAMELENGTH]) {
        RobotCoins robotCoins = view_as<RobotCoins>(new StringMap());
        robotCoins.SetString("RobotName", robotName);
        robotCoins.PerRobot = 0;
        robotCoins.Overall = 0;
        return robotCoins;
    }

    public void GetRobotName(char buffer[NAMELENGTH])
    {
        this.GetString("RobotName", buffer, NAMELENGTH);
    }

    public int GetPrice()
    {
        if (this.Overall > 0)
            return this.Overall;

        int robotCount = GetRobotCountPerTeam();
        return robotCount * this.PerRobot;
    }

    public RobotCoins From(RobotCoinRestrictionDefinition definition)
    {
        if (definition == null)
        {
            //aSMLOGTag(SML_VERBOSE, "RobotCoinRestrictionDefinition does not exist");
            return this;
        }
        //aSMLOGTag(SML_VERBOSE, "assigning PerRobot to %i", definition.PerRobot);
        this.PerRobot = definition.PerRobot;
        //aSMLOGTag(SML_VERBOSE, "assigning Overall to %i", definition.Overall);
        this.Overall = definition.Overall;
        
        return this;
    }
}

methodmap Restrictions < StringMap {
    property TimeLeftRestriction TimeLeft {
        public get(){ 
            TimeLeftRestriction value;
            this.GetValue("TimeLeft", value);
            return value;
        }
        public set(TimeLeftRestriction value){
            this.SetValue("TimeLeft", value);
        }
    }
    property RobotCoins RobotCoinsRed {
        public get(){ 
            RobotCoins value;
            this.GetValue("RobotCoinsRed", value);
            return value;
        }
        public set(RobotCoins value){
            this.SetValue("RobotCoinsRed", value);
        }
    }
    property RobotCoins RobotCoinsBlu {
        public get(){ 
            RobotCoins value;
            this.GetValue("RobotCoinsBlu", value);
            return value;
        }
        public set(RobotCoins value){
            this.SetValue("RobotCoinsBlu", value);
        }
    }

    public Restrictions() {
        return view_as<Restrictions>(new StringMap());
    }

    public bool IsActive()
    {
        return this.TimeLeft.Active || this.RobotCoinsRed.Active || this.RobotCoinsBlu.Active;
    }

    public bool IsEnabled()
    {
        return this.TimeLeft.Enabled || this.RobotCoinsRed.Enabled || this.RobotCoinsBlu.Enabled;
    }

    public RobotCoins GetRobotCoins(TFTeam team)
    {
        switch (team)
        {
            case TFTeam_Blue:
                return this.RobotCoinsBlu;
            case TFTeam_Red:
                return this.RobotCoinsRed;
            default:
                return null;
        }
    }
    
    public RobotCoins GetRobotCoinsFor(int clientId)
    {        
        TFTeam team = view_as<TFTeam>(GetClientTeam(clientId));
        return this.GetRobotCoins(team);
    }

    public void From(RestrictionsDefinition definition, char robotName[NAMELENGTH])
    {
        if (definition == null)
        {
            //aSMLOGTag(SML_VERBOSE, "RestrictionsDefinition created");
            definition = new RestrictionsDefinition();
        }
        TimeLeftRestriction timeLeft = new TimeLeftRestriction();        
        this.TimeLeft = timeLeft.From(definition.TimeLeft, robotName);
        RobotCoins robotCoinsRed = new RobotCoins(robotName);        
        this.RobotCoinsRed = robotCoinsRed.From(definition.RobotCoins);
        RobotCoins robotCoinsBlu = new RobotCoins(robotName);        
        this.RobotCoinsBlu = robotCoinsBlu.From(definition.RobotCoins);
    }
}
enum struct Robot {
  char name[NAMELENGTH];
  char role[NAMELENGTH];
  char class[9];
  char shortDescription[NAMELENGTH];
  PrivateForward callback;
  RobotSounds sounds;
  Restrictions restrictions;
  int robotCoinsOnDeath;
}