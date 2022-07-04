#if defined _berobot_core_restrictions_included
 #endinput
#endif
#define _berobot_core_restrictions_included "0.1"

/**
 * Called after resoruce of a robot changed
 * 
 * @noreturn
 */
forward void MM_OnRestrictionChanged(char name[NAMELENGTH]);

/**
 * invokes MM_OnRestrictionChanged
 * 
 * @noreturn
 */
native void OnRestrictionChanged(char name[NAMELENGTH]);

/**
 * pays robot-coin to create robot
 * 
 * @param restrictions      Restrictions of the robot, that should be created
 * @param clientId          clientId
 * @return                  true: succesfully paid
                            false: was not able to pay
 */
native bool PayRobotCoin(Restrictions restrictions, int clientId);

/**
 * add a specified amount to the robot-coins
 * 
 * @param team      robot-coin will be added to this team
 * @param amount    amount of robot-coin to add
 * @noreturn
 */
native void AddRobotCoins(TFTeam team, int amount);

/**
 * add a specified amount to the robot-coins
 * 
 * @param clientId  robot-coin will be added to this clients team
 * @param amount    amount of robot-coin to add
 * @noreturn
 */
native void AddRobotCoinsFor(int clientId, int amount);

/**
 * add a specified amount to the robot-coins
 * 
 * @param team      robot-coin will be added to this team
 * @param amount    amount of robot-coin to add
 * @noreturn
 */
native void AddTeamCoins(TFTeam team, int amount);

/**
 * add a specified amount to the robot-coins
 * 
 * @param clientId  robot-coin will be added to this clients team
 * @param amount    amount of robot-coin to add
 * @noreturn
 */
native void AddTeamCoinsFor(int clientId, int amount);

/**
 * returns available team-coins
 * 
 * @param clientId  team-coins will be returned for this clients team
 * @return          amount of team-coins available to the clients team
 */
native int GetTeamCoinsFor(int clientId);

/**
 * returns available robot-coins
 * 
 * @param clientId  robot-coins will be returned for this clients team
 * @return          amount of robot-coins available to the clients team
 */
native int GetRobotCoinsFor(int clientId);

/**
 * resets both type of coins for all clients/teams
 * 
 * @noretutn
 */
native void ResetCoins();