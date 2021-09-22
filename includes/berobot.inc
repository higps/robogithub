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
}
enum struct Robot {
  char name[NAMELENGTH];
  char class[9];
  PrivateForward callback;
  RobotSounds sounds;
}
typedef RobotCallback = function void (int client);

/**
 * Adds a robot to the storage. So it can be dynamically used by other plugins. (usually called during OnPluginStart)
 * 
 * @param name         name of the robot (used as a Identifierer by other plugins)
 * @param class        class of the robot (Soldier, Engineer, etc.)
 * @param callback     function creating this robot
 * @param version      plugin version of this indivifual robot-plugin
 * @param sounds       enum struct RobotSounds containing sounds relevant to the robot
 * 
 * @noreturn
 */
native void AddRobot(char name[NAMELENGTH], char class[9], RobotCallback callback, char[] version, const any[] sounds);

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
 * turns a player into a registered robot
 * 
 * @param name       name of the robot, that should be created (call GetRobotNames() to get a list of all possible robot-names)
 * @param client     the client in whos context the command should be executed
 * @param target     the target of the command (usualy "" can be "@me" etc.)
 * 
 * @noreturn
 */
native void CreateRobot(char[] name, int client, char target[32]);