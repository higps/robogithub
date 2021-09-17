#if defined _berobot_included
 #endinput
#endif
#define _berobot_included "0.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required
#pragma semicolon 1

const int NAMELENGTH = 128;
typedef RobotCallback = function void (int client, char target[32]);


native void AddRobot(char name[NAMELENGTH], RobotCallback callback);
native void RemoveRobot(char name[NAMELENGTH]);

native ArrayList GetRobotNames();

native void CreateRobot(char[] name, int client, char target[32]);