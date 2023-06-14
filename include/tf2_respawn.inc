#if defined _tf2_respawn_included
 #endinput
#endif
#define _tf2_respawn_included

//=======[NATIVES]=======

/**
 * Tells if the client is respawning.
 *
 * @param iClient	Client index.
 * @return			Return true if the client is respawning.
 */
native bool TF2_IsClientRespawning(int iClient);

/**
 * Gets the respawn time of a team.
 *
 * @param iTeam		Team number.
 * @return			Return team's respawn time.
 */
native float TF2_GetTeamRespawnTime(int iTeam);

/**
 * If the client is respawning then this returns the respawn time of the client.
 *
 * @param iClient		Client index.
 * @return				Return client's respawn time.
 */
native float TF2_GetClientRespawnTime(int iClient);

/**
 * Sets the respawn time of the client.
 * !!WARNING!! Setting a new respawn time with this function, won't update the current respawn time of the client! If you want to update the respawn time use (TF2_UpdateClientRespawnTime) instead!
 *
 * @param iClient			Client index.
 * @param flRespawnTime		Respawn time.
 * @return					Return true if the client's respawn time has been set.
 */
native bool TF2_SetClientRespawnTime(int iClient, float flRespawnTime);

/**
 * If the client is respawning then this update their current respawn time.
 *
 * @param iClient					Client index.
 * @param flUpdatedRespawnTime		Updated respawn time (can be negative).
 * @return							Return true if the client's respawn time has been updated.
 */
native bool TF2_UpdateClientRespawnTime(int iClient, float flRespawnTime);

/**
 * Sets the respawn time of a team.
 * !!WARNING!! Setting a new respawn time with this function, won't update the current respawn time of respawning clients of a team! If you want to update the respawn time use (TF2_UpdateTeamRespawnTime) instead!
 *
 * @param iTeam					Team number.
 * @param flNewRespawnTime		New respawn time.
 * @return						Return true if the team's respawn time has been set.
 */
native bool TF2_SetTeamRespawnTime(int iTeam,float flNewRespawnTime);

/**
 * Updates the respawn time of all clients in a team (similar to TF2_UpdateClientRespawnTime).
 *
 * @param iTeam						Team number.
 * @param flUpdatedRespawnTime		Updated respawn time (can be negative).
 * @return							Return true if the client's respawn time has been updated.
 */
native bool TF2_UpdateTeamRespawnTime(int iTeam, float flUpdatedRespawnTime);

//=======[FORWARDS]=======

/**
 * Called when the game sets the client's respawn time.
 * Return Plugin_Changed to override the respawn time.
 * Return Plugin_Continue to keep the same.
 *
 * @param iClient				Client Index.
 * @param flRespawnTime			The respawn time set.
 */
forward Action TF2_OnClientRespawnTimeSet(int iClient,float &flRespawnTime);

/**
 * Called when the game updates the current respawn time for a team.
 * Return Plugin_Changed to override the new respawn time.
 * Return Plugin_Continue to keep the same.
 *
 * @param iTeam					Team number.
 * @param flNewRespawnTime		The new respawn time.
 */
forward Action TF2_OnTeamRespawnTimeChanged(int iTeam,float &flNewRespawnTime);

/**
 * Called when the game updates the current respawn time of a team, and changes the respawn time of all respawning clients.
 * Return Plugin_Changed to override the new respawn time.
 * Return Plugin_Continue to keep the same.
 *
 * @param iClient					Client Index.
 * @param flUpdatedRespawnTime		The respawn time set.
 */
forward Action TF2_OnClientRespawnTimeUpdated(int iClient,float &flUpdatedRespawnTime);

public SharedPlugin __pl_tf2_respawn = 
{
	name = "tf2_respawn_time",
	file = "tf2_respawn_system_core.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};