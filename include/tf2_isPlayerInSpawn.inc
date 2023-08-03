/****************************************
 * isPlayerInSpawn.inc version 18.0121.0
 * Used in conjunction with isPlayerInSpawn.smx to inform other plugins
 * of whether or not a player is in spawn.
 *
 * https://forums.alliedmods.net/showthread.php?t=247950
 * http://ddhoward.com/sourcemod/updater/plugins/tf2_isPlayerInSpawn.smx
 * http://ddhoward.com/sourcemod/updater/scripting/tf2_isPlayerInSpawn.sp
 * http://ddhoward.com/sourcemod/updater/scripting/include/tf2_isPlayerInSpawn.inc
 *
 *
 * It is asked, but not required that you call CreateIPISVersionPrinter() within
 * your plugin's OnPluginStart().
 */

#if defined _tf2isinspawn_version
  #endinput
#endif
#define _tf2isinspawn_version "18.0121.0"

public SharedPlugin __pl_tf2isinspawn = {
	name = "tf2_isPlayerInSpawn",
	file = "tf2_isPlayerInSpawn.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_tf2isinspawn_SetNTVOptional() {
	MarkNativeAsOptional("TF2Spawn_IsClientInSpawn2");
	MarkNativeAsOptional("TF2Spawn_GetPluginVersion2");
}
#endif


/****************************************************************************************************
	FORWARDS
*****************************************************************************************************/


/**
 * Called every time a player enters their own team's spawnroom.
 *
 *
 * @param client		Client Index.
 * @param room			Entity of the func_respawnroom in question
 */
forward void TF2Spawn_EnterSpawn(int client, int spawn);

/**
 * Called every time a player leaves their own team's spawnroom.
 * This is not called if the player leaves spawn by disconnecting from the server.
 *
 *
 * @param client		Client Index.
 * @param room			Entity of the func_respawnroom in question
 */
forward void TF2Spawn_LeaveSpawn(int client, int spawn);


/****************************************************************************************************
	NATIVES
	
	Please note that all following "natives" run a simple check to see if isPlayerInSpawn.smx is even
	loaded before calling the real native; this ensures that an unavailable native is never called,
	since calling an unavailable native will result in the entire callback being aborted. However,
	this check is considered to be expensive. If you will be using one or more of these natives
	repeatedly and rapidly (such as OnGameFrame, OnPlayerRunCmd, etc.), you may want to bypass the
	check. You can do so by simply adding a '2' to the end of the native name. For example,
	TF2_IsInSpawn() becomes TF2Spawn_IsClientInSpawn2().

	Before manually calling a '2' native, you must do your own checking to see if the plugin is
	loaded. This can be done by using OnAllPluginsLoaded()+LibraryExists(), OnLibraryAdded(), and
	OnLibraryRemoved() with the library name "tf2_isPlayerInSpawn", and storing	the result in
	a bool variable. Check that the variable is true before manually calling the '2' native!!
	
*****************************************************************************************************/

native bool TF2Spawn_IsClientInSpawn2(int client);
/**
 * Returns whether or not a given player is in their team's spawn room.
 *
 * @param client		Client Index.
 * @return				TRUE if in spawn, FALSE if not or an error occured.
 */
stock bool TF2Spawn_IsClientInSpawn(int client) {
	CreateIPISVersionPrinter();
	if (GetFeatureStatus(FeatureType_Native, "TF2Spawn_IsClientInSpawn2") == FeatureStatus_Available)
		return TF2Spawn_IsClientInSpawn2(client);
	else
		return false;
}


/****************************************************************************************************
	OTHER
*****************************************************************************************************/

stock void CreateIPISVersionPrinter() {
	static bool ipisListenerCreated;
	if (!ipisListenerCreated) {
		AddCommandListener(print_isInSpawn_include_version, "tf2_isplayerinspawn_include_versions");
		ipisListenerCreated = true;
	}
}

//command listener which prints information to the chat, ALL plugins with this include will respond
public Action print_isInSpawn_include_version(int client, const char[] cmdname, int Args) {
	if (CheckCommandAccess(client, "tf2_isplayerinspawn_include_versions", ADMFLAG_ROOT, true)) {

		char pluginFilename[PLATFORM_MAX_PATH];
		GetPluginFilename(INVALID_HANDLE, pluginFilename, sizeof(pluginFilename));

		char pluginName[64];
		if (GetPluginInfo(INVALID_HANDLE, PlInfo_Name, pluginName, sizeof(pluginName))) {
			Format(pluginName, sizeof(pluginName), "%s%s", pluginName, " - ");
		}

		char pluginVersion[32];
		if (!GetPluginInfo(INVALID_HANDLE, PlInfo_Version, pluginVersion, sizeof(pluginVersion))) {
			Format(pluginVersion, sizeof(pluginVersion), "UNKNOWN");
		}
		
		ReplyToCommand(client, "%s - %s%s v. %s", _tf2isinspawn_version, pluginName, pluginFilename, pluginVersion);
	}
	return Plugin_Continue;
}