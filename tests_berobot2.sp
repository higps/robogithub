#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <berobot>
#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "tests_berobot2",
	author = "icebear",
	description = "",
	version = "0.1",
	url = "https://github.com/eisbaer66/robogithub"
};

char LOG_TAGS[][] =	 {"VERBOSE", "INFO", "ERROR", "FAILED_ASSERT"};
enum (<<= 1)
{
	SML_VERBOSE = 1,
	SML_INFO,
	SML_ERROR,
	SML_FAILED_ASSERT,
}

enum struct CreateCall{
	char name[1];
	int client;
	int args;
}

ArrayList _created;

public void OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_VERBOSE|SML_INFO|SML_ERROR|SML_FAILED_ASSERT, SML_ALL);
	SMLogTag(SML_INFO, "tests_berobot2 started at %i", GetTime());

	_created = new ArrayList(3);

	Assert();
}

public void Assert()
{
	if (!AssertNames())
		return;

	SMLogTag(SML_INFO, "Asserts passed");
}

public bool AssertNames()
{
	ArrayList names = GetRobotNames();
	if (!AssertEqual(2, names.Length, "GetRobotNames did not return expected number of names"))
		return false;

	char actualA[2];
	names.GetString(0, actualA, 2);
	if (!AssertEqualString("B", actualA, "GetRobotNames did not have 'B' in first Position"))
		return false;

	char actualB[2];
	names.GetString(1, actualB, 2);
	if (!AssertEqualString("A", actualB, "GetRobotNames did not have 'A' in second Position"))
		return false;

	return true;
}

public bool AssertEqual(int expected, int actual, char[] message)
{
	if (actual == expected)
		return true;
		
	StrCat(message, 265, ". Expected: %i Actual: %i");
	SMLogTag(SML_FAILED_ASSERT, message, expected, actual);

	return false;
}

public bool AssertEqualString(char[] expected, char[] actual, char[] message)
{
	if (strcmp(actual, expected) == 0)
		return true;
		
	StrCat(message, 265, ". Expected: %s Actual: %s");
	SMLogTag(SML_FAILED_ASSERT, message, expected, actual);

	return false;
}