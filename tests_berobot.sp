#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sm_logger>
#include <berobot>
#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "tests_berobot",
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
	char target[32];
}

ArrayList _created;

public void OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_VERBOSE|SML_INFO|SML_ERROR|SML_FAILED_ASSERT, SML_ALL);
	SMLogTag(SML_INFO, "tests_berobot started at %i", GetTime());

	_created = new ArrayList(3);

	AddRobot("A", "ClassA", CreateA);
	AddRobot("B", "ClassB", CreateB);

	Assert();
}

public void OnPluginEnd()
{
	RemoveRobot("A");
	RemoveRobot("B");
}

public void CreateA(int client, char target[32])
{
	SMLogTag(SML_VERBOSE, "CreateA called at %i for client %i and target %s", GetTime(), client, target);

	CreateCall call;
	call.name = "A";
	call.client = client;
	call.target = target;

	_created.PushArray(call);
}

public void CreateB(int client, char target[32])
{
	SMLogTag(SML_VERBOSE, "CreateB called at %i for client %i and target %s", GetTime(), client, target);
	
	CreateCall call;
	call.name = "B";
	call.client = client;
	call.target = target;

	_created.PushArray(call);
}

public void Assert()
{
	if (!AssertNames())
		return;
	if (!AssertClasses())
		return;
	if (!AssertCalls())
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

public bool AssertClasses()
{
	char classA[9];
	GetRobotClass("A", classA);
	if (!AssertEqualString("ClassA", classA, "GetRobotClass did not return expected class"))
		return false;

	char classB[9];
	GetRobotClass("B", classB);
	if (!AssertEqualString("ClassB", classB, "GetRobotClass did not return expected class"))
		return false;

	return true;
}

public bool AssertCalls()
{
	CreateRobot("A", 1, "@me");
	CreateRobot("B", 2, "@me");
	
	if (!AssertEqual(2, _created.Length, "Create-functions were not called the expected number of times"))
		return false;
		
	CreateCall call;
	
	_created.GetArray(0, call, sizeof(call));
	if (!AssertEqualCalls(call, "A", 1, "@me", "first call"))
		return false;

	_created.GetArray(1, call, sizeof(call));
	if (!AssertEqualCalls(call, "B", 2, "@me", "second call"))
		return false;

	return true;
}

public bool AssertEqualCalls(CreateCall call, char[] expectedName, int expectedClient, char expectedTarget[32], char[] message)
{
	char nameMessage[265];
	strcopy(nameMessage, 265, message);
	StrCat(nameMessage, 265, " did not have expected name");
	if (!AssertEqualString(expectedName, call.name, nameMessage))
		return false;

	char clientMessage[265];
	strcopy(clientMessage, 265, message);
	StrCat(clientMessage, 265, " did not have expected client");
	if (!AssertEqual(expectedClient, call.client, clientMessage))
		return false;

	char argsMessage[265];
	strcopy(argsMessage, 265, message);
	StrCat(argsMessage, 265, " did not have expected args");
	if (!AssertEqualString(expectedTarget, call.target, argsMessage))
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