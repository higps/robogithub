#if defined _berobot_included
 #endinput
#endif
#define _berobot_included "0.1"


enum struct RobotSounds {
  char spawn[PLATFORM_MAX_PATH];
  char loop[PLATFORM_MAX_PATH];
  char gunfire[PLATFORM_MAX_PATH];
  char gunfire_crit[PLATFORM_MAX_PATH];
  char gunspin[PLATFORM_MAX_PATH];
  char windup[PLATFORM_MAX_PATH];
  char winddown[PLATFORM_MAX_PATH];
  char death[PLATFORM_MAX_PATH];
}
methodmap TimeLeftRestrictionDefinition < StringMap {
    property int SecondsBeforeEndOfRound {
        public get(){ 
            int value;
            this.GetValue("SecondsBeforeEndOfRound", value);
            return value;
        }
        public set(int value){
            this.SetValue("SecondsBeforeEndOfRound", value);
        }
    }

    public TimeLeftRestrictionDefinition() {
        return view_as<TimeLeftRestrictionDefinition>(new StringMap());
    }
}
methodmap RobotCoinRestrictionDefinition < StringMap {
    property float PerRobot {
        public get(){ 
            float value;
            this.GetValue("PerRobot", value);
            return value;
        }
        public set(float value){
            this.SetValue("PerRobot", value);
        }
    }
    property int Overall {
        public get(){ 
            int value;
            this.GetValue("Overall", value);
            return value;
        }
        public set(int value){
            this.SetValue("Overall", value);
        }
    }

    public RobotCoinRestrictionDefinition() {
        return view_as<RobotCoinRestrictionDefinition>(new StringMap());
    }
}
methodmap RestrictionsDefinition < StringMap {
    property TimeLeftRestrictionDefinition TimeLeft {
        public get(){ 
            TimeLeftRestrictionDefinition value;
            this.GetValue("TimeLeft", value);
            return value;
        }
        public set(TimeLeftRestrictionDefinition value){
            this.SetValue("TimeLeft", value);
        }
    }
    property RobotCoinRestrictionDefinition RobotCoins {
        public get(){ 
            RobotCoinRestrictionDefinition value;
            this.GetValue("RobotCoins", value);
            return value;
        }
        public set(RobotCoinRestrictionDefinition value){
            this.SetValue("RobotCoins", value);
        }
    }
    property RobotCoinRestrictionDefinition TeamCoins {
        public get(){ 
            RobotCoinRestrictionDefinition value;
            this.GetValue("TeamCoins", value);
            return value;
        }
        public set(RobotCoinRestrictionDefinition value){
            this.SetValue("TeamCoins", value);
        }
    }

    public RestrictionsDefinition() {
        return view_as<RestrictionsDefinition>(new StringMap());
    }
}
enum struct RobotDefinition {
  char name[NAMELENGTH];
  char role[NAMELENGTH];
  char class[9];
  char subclass[32];
  char shortDescription[NAMELENGTH];
  char deathtip[512];
  char tips[512];
  char model[512];
  RobotSounds sounds;
  int health;
  float scale;
  char deatheffect[64];
  int weaponsound;
  int footstep;
  int difficulty;
  int robotCoinsOnDeath;
  int teamCoinsOnDeath;
}
typedef RobotCallback = function void (int client);

/**
 * Adds a robot to the storage. So it can be dynamically used by other plugins. (usually called during OnPluginStart)
 * 
 * @param robot             enum struct Robot containing robot-definition
 * @param callback          function creating this robot
 * @param version           plugin version of this individual robot-plugin
 * @param restrictions      restrictions on spawning this robot (null means no restricitons)
 * 
 * @noreturn
 */
//native void AddRobot(const any[] robot, RobotCallback callback, char[] version, RestrictionsDefinition restrictions = null, int robotCoinsOnDeath = 10, int teamCoinsOnDeath = 0);
native void AddRobot(const any[] robot, RobotCallback callback, char[] version, RestrictionsDefinition restrictions = null);

/**
 * Removes a robot to the storage. So it can't be used by other plugins anymore. (usually called during OnPluginEnd)
 * 
 * @param name      name of the robot (used as a Identifierer by other plugins)
 * 
 * @noreturn
 */
native void RemoveRobot(char name[NAMELENGTH]);

/**
 * return the names of all added/registered robots
 * 
 * @return     ArrayList containing all robot-names
 */
native ArrayList GetRobotNames();

/**
 * returns the class of a registered robot.
 * 
 * @param name      name of the robot in question (call GetRobotNames() to get a list of all possible robot-names)
 * @param class     destination-string will contain the class
 * 
 * @noreturn
 */
native void GetRobotClass(char name[NAMELENGTH], char class[9]);

/**
 * checks if a client is the specified robot
 * 
 * @param client    clientId to check for robot
 * @param name      name of the robot in question (call GetRobotNames() to get a list of all possible robot-names)
 * 
 * @return          true: client is specified robot;
 *                  false: client is _not_ specified robot
 */
native bool IsRobot(int client, char name[NAMELENGTH]);

/**
 * checks if a client is the specified robot when dead
 * 
 * @param client    clientId to check for robot
 * @param name      name of the robot in question (call GetRobotNames() to get a list of all possible robot-names)
 * 
 * @return          true: client is specified robot;
 *                  false: client is _not_ specified robot
 */
 native bool IsRobotWhenDead(int client, char name[NAMELENGTH]);

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
 * checks if a client is a boss
 * 
 * @param client    clientId to check for robot
 * 
 * @return          return handled
 */
 native bool IsBoss(int client);

 /**
 * checks if a client is a tank
 * @param client    clientId to check for robot
 * 
 * @return          return handled
 */
 native bool IsTank(int client);

 /**
 * checks if a client is a sentry buster
 * @param client    clientId to check for robot
 * 
 * @return          return handled
 */
 native bool IsSentryBuster(int client);

 /**
 * Sets the stats for tanks
 * 
 * @param client    clientId to check for robot
 * 
 * @return          Handled
 *                  
 */
 native void SetTankStats(int client);

 /**
 * Sets the boss healthbar
 * 
 * @param client    clientId to check for robot
 * 
 * @return          Handled
 *                  
 */
 native void SetBossHealth(int client);

  /**
 * The Health of the robot during creation
 * 
 * @param client    clientId to check for robot
 * @param iClass
 * @param iHealth
 * @param OverHealRate
 * @return          Handled
 *                  
 */
native void RoboSetHealth(int client, int iClass, int iHealth, float OverHealRate = 1.5)

 /**
 * Sets the boss healthbar
 * 
 * @param client    clientId to check for robot
 * 
 * @return          Handled
 *                  
 */
 native void UnSetBossHealth(int client);

/**
 * turns a player into a registered robot
 * 
 * @param name       name of the robot, that should be created (call GetRobotNames() to get a list of all possible robot-names)
 * @param client     the client in whos context the command should be executed
 * @param target     the target of the command (usualy "" can be "@me" etc.)
 * 
 * @return  error code 
            0: no error
            1: robot not found
            2: target error
            3: could not pay robot-coins
 */
native int CreateRobot(char[] name, int client, char target[32]);

/**
 * Returns an int of the team that is currently the robot team 
 * 
 * */
native int GetRobotTeam();
/**
 * SDKCall for CBasePlayer::EquipWearable
 * 
 * @param client     the client who should wear the equipment/item
 * @param item       the entity-index of the equipment/item
 * 
 * @noreturn
 */

/**
 * Sets the health and has a boolean to display the health on hud or not 
 * 
 * */
native int AddPlayerHealth(int iClient, int iAdd, int iOverheal = 0, bool bStaticMax = false, bShowHealthGain = true);
/**
 * Adds health and shows it on the hud
 *  @param iClient
 *  @param iAdd amount of health to be added
 *  @param iOverheal how much overheal
 *  @param bStaticMax if the max health is static or not
 *  @param bShowHealthGain show the health on the hud
 * 
 * @noreturn
 */


native void EquipWearable(int client, int item);

/**
 * Creates a weapon with level
 * 
 * @param client     the client who should wear the equipment/item
 * @param classname  the class name of the weapon like "tf_weapon_minigun"
 * @param itemindex  the item index of the weapon to be used, doesn't have to match classname
 * @param quality    the quality of the item, 6 is unique, 9 is australium and so on.
 * @param level       the level of the item
 * @param slot      the weapon slot this weapon will be put in, starts at 0
 * @noreturn
 */
 //CreateWeapon(client, "tf_weapon_minigun", 850, 6, 1, 2);
native int CreateRoboWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, int paint);

/**
 * Creates a weapon with attributes
 * 
 * @param client     the client who should wear the equipment/item
 * @param classname  the class name of the weapon like "tf_weapon_minigun"
 * @param itemindex  the item index of the weapon to be used, doesn't have to match classname
 * @param quality    the quality of the item, 6 is unique, 9 is australium and so on.
 * @param level       the level of the item
 * @param visible      if the weapon is visible
 * @param preserve      if attributes should be preserved
 * @param attribute     attributes for the item created
 * @noreturn
 */
 //CreateWeapon(client, "tf_weapon_minigun", 850, 6, 1, 2);
native bool CreateRoboWeaponWithAttributes(int client, char[] classname, int itemindex, int quality, int level, bool visible, bool preserve, char[] attribute);


/**
 * Creates a hat with with paint and scale
 * 
 * @param client     the client who should wear the equipment/item
 * @param classname  the class name of the weapon like "tf_weapon_minigun"
 * @param itemindex  the item index of the weapon to be used, doesn't have to match classname
 * @param quality    the quality of the item, 6 is unique, 9 is australium and so on.
 * @param level       the level of the item
 * @param paint      the paint, has to be a float value ending with .0 for attributes to work properly
 * @param scale     the scale of the hat, will only work on single bone hats.
 * @noreturn
 */
 //CreateWeapon(client, "tf_weapon_minigun", 850, 6, 1, 2);
native void  CreateRoboHat(int client, int itemindex, int level, int quality, int paint, int paint2, float scale, float style);


/**
* Removes all wearables
*
**/
native void RoboRemoveAllWearables(int client);


/**
* Fixes Clipsize on weapons that has less or more standard clip size
*
**/
native void RoboCorrectClipSize(int item);

/**
 * scales the hitbox of player-hitbox
 * 
 * @param client     clientId of the player being scaled
 * @param fScale     scale of how much the hitbox changes compared to the default hitbox
 * @noreturn
 */
stock void UpdatePlayerHitbox(const int client, const float fScale)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };

	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;

	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);

	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}


/**
 * returns how many robot players there are (non humans)
 * 
 * @return              number of robots
 */
stock int GetCurrentRobotCount()
{
        int CurrentRobots = 0;
        // int STV = 0;
        for(int i = 0; i <= MaxClients+1; i++)
        {
            if(IsAnyRobot(i))
            {
                CurrentRobots++;
            }
        }
        return CurrentRobots;
}

/**
 * returns how many human players there are (non robots)
 * 
 * @return              number of humans:
 */
stock int GetCurrentHumanCount()
{
    int CurrentHumans = 0;
    for(int i = 0; i <= MaxClients+1; i++)
    {
        if(!IsAnyRobot(i) && IsValidClient(i))
        {
            CurrentHumans++;
        }
    }
    return CurrentHumans;
}


/**
 * checks if the given client is valid (in game, not coaching and if requested not SourceTV/replay)
 * 
 * @param client        clientId to check
 * @param replaycheck   indicates if SourceTV/Replay should be considered invalid
 * @return              true: client is valid;
 *                      false: client is invalid
 */
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


// /**
//  * Returns the number of robots, excluding them if they are in spectate or unassigned
//  * 
//  * @noreturn
//  */
// native int GetCurrentRobotCount();


// /**
//  * Returns the number of humans, excluding them if they are in spectate or unassigned
//  * 
//  * @noreturn
//  */
// native int GetCurrentHumanCount();