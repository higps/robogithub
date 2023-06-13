#if defined _berobot_constants_included
 #endinput
#endif
#define _berobot_constants_included "0.1"

#define MENU_ANSWER_YES "yes"
#define MENU_ANSWER_NO "no"

#define CONVAR_ROBOCAP_TEAM "sm_robocap_team"

#define TEAMCOUNT 4

#define NAMELENGTH 128
const int MAX_INT = 2147483647;

enum //Weapon Sounds
{
    ROBOT_WEAPON_SOUND_NONE = 0,
	ROBOT_WEAPON_SOUND_ROCKETLAUNCHER,
    ROBOT_WEAPON_SOUND_MINIGUN,
    ROBOT_WEAPON_SOUND_FLAMETHROWER,
    ROBOT_WEAPON_SOUND_GRENADELAUNCHER,
}
enum
{
    ROBOT_FOOTSTEPS_CLASS = 0,
    ROBOT_FOOTSTEP_NORMAL,
    ROBOT_FOOTSTEP_GIANTCOMMON,
    ROBOT_NO_FOOTSTEPS,
}