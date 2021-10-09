#if defined _berobot_included
 #endinput
#endif
#define _berobot_included "0.1"


enum struct RobotSounds {
  char spawn[PLATFORM_MAX_PATH];
  char loop[PLATFORM_MAX_PATH];
  char gunfire[PLATFORM_MAX_PATH];
  char gunspin[PLATFORM_MAX_PATH];
  char windup[PLATFORM_MAX_PATH];
  char winddown[PLATFORM_MAX_PATH];
  char death[PLATFORM_MAX_PATH];
}
enum struct Robot {
  char name[NAMELENGTH];
  char role[NAMELENGTH];
  char class[9];
  char shortDescription[NAMELENGTH];
  PrivateForward callback;
  RobotSounds sounds;
}
typedef RobotCallback = function void (int client);

/**
 * Adds a robot to the storage. So it can be dynamically used by other plugins. (usually called during OnPluginStart)
 * 
 * @param robot       enum struct Robot containing robot-definition
 * @param callback     function creating this robot
 * @param version      plugin version of this indivifual robot-plugin
 * 
 * @noreturn
 */
native void AddRobot(const any[] robot, RobotCallback callback, char[] version);

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
 * turns a player into a registered robot
 * 
 * @param name       name of the robot, that should be created (call GetRobotNames() to get a list of all possible robot-names)
 * @param client     the client in whos context the command should be executed
 * @param target     the target of the command (usualy "" can be "@me" etc.)
 * 
 * @noreturn
 */
native void CreateRobot(char[] name, int client, char target[32]);

/**
 * SDKCall for CBasePlayer::EquipWearable
 * 
 * @param client     the client who should wear the equipment/item
 * @param item       the entity-index of the equipment/item
 * 
 * @noreturn
 */
native void EquipWearable(int client, int item);

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