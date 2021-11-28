#if defined _berobot_core_resources_included
 #endinput
#endif
#define _berobot_core_resources_included "0.1"

/**
 * Called after resoruce of a robot changed
 * 
 * @noreturn
 */
forward void MM_OnResourceChanged(char name[NAMELENGTH]);

/**
 * invokes MM_OnResourceChanged
 * 
 * @noreturn
 */
native void OnResourceChanged(char name[NAMELENGTH]);

/**
 * pays resource to create robot
 * 
 * @param resources     Resources of the robot, that should be created
 * @param clientId      clientId
 * @return              true: succesfully paid
                        false: was not able to pay
 */
native bool RobotCoin(Resources resources, int clientId);

/**
 * add a specified amount to the robot-coins
 * 
 * @param team      resources will be added to this team
 * @param amount    amount of resources to add
 * @noreturn
 */
native void AddRobotCoins(TFTeam team, int amount);

/**
 * add a specified amount to the robot-coins
 * 
 * @param clientId  resources will be added to this clients team
 * @param amount    amount of resources to add
 * @noreturn
 */
native void AddRobotCoinsFor(int clientId, int amount);

/**
 * returns available robot-coins
 * 
 * @param team      robot-coins will be returned for this team
 * @return          amount of robot-coins available to the clients team
 */
native int GetRobotCoins(TFTeam team);

/**
 * returns available robot-coins
 * 
 * @param clientId  robot-coins will be returned for this clients team
 * @return          amount of robot-coins available to the clients team
 */
native int GetRobotCoinsFor(int clientId);