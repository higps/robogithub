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