public OnPluginStart()
{
	LoadTranslations("common.phrases");

	//Please modify the code to load the robot.cfg file and map the values accordingly
	while(robots)
	{
		RobotDefinition robot;
		robot.name = ROBOT_NAME;
		robot.role = ROBOT_ROLE;
		robot.class = ROBOT_CLASS;
		robot.subclass = ROBOT_SUBCLASS;
		robot.shortDescription = ROBOT_DESCRIPTION;
		robot.sounds.spawn = SPAWN;
		robot.sounds.loop = LOOP;
		robot.sounds.gunfire = SOUND_GUNFIRE;
		robot.sounds.gunspin = SOUND_GUNSPIN;
		robot.sounds.windup = SOUND_WINDUP;
		robot.sounds.winddown = SOUND_WINDDOWN;
		robot.sounds.death = DEATH;
		robot.deathtip = ROBOT_ON_DEATH;
		robot.weaponsound = ROBOT_WEAPON_SOUND_MINIGUN;
		robot.difficulty = ROBOT_DIFFICULTY_EASY;
		AddRobot(robot, MakeRobot, PLUGIN_VERSION);
	}
}


public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

MakeRobot(client)
{	

	//Below the TFClass_Heavy should be replaced with the TFCLass read from the file, users will write Medic, but the TF2 Setplayer class requires it to be TFClass_Medic, so you will need to add that here
	TF2_SetPlayerClass(client, TFClass_Heavy);
	

	//Robot initiation stuff, no need to alter this
	TF2_RegeneratePlayer(client);
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}

	CreateTimer(0.0, Timer_Switch, client);

	//Set the robot model string from the config file
	SetModel(client, ROBOTMODEL);

	//Use the correct TFClass name and set the health from the config file
	RoboSetHealth(client,TFClass_Scout, Health, 1.5);



	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);


	//Add the player attributes from the config file here
	while(Variables)
	{
		TF2Attrib_SetByName(client, attribute, value);
	}
	TF2Attrib_SetByName(client, "move speed penalty", 0.5);
	TF2Attrib_SetByName(client, "damage force reduction", 0.1);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.0);
	
	
	UpdatePlayerHitbox(client, scale);
   

   //Initiation stuff, ignore
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	//Map the tips from the tips in the config file
	PrintHintText(client , ROBOT_TIPS);

}

 
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveEquipment(client);
}
 
stock GiveEquipment(client)
{
	if (IsValidClient(client))
	{
		//Removes all pre existing items and hats don't touch
		RoboRemoveAllWearables(client);
		//TF2_RemoveAllWearables(client);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 2);

		//Add the code to add the hats from the config file, you will ignore the name and use the itemindex instead
		while(Hats)
		{
			CreateRoboHat(client, ROTATIONSENSATION, HatLevel, HatQuality, HatPaint, HatScale, HatStyle);//Rotation sensation

		}
		

		//Add the code to create the weapons, then add the attributes to them
		while(Weapons)
		{

		CreateRoboWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, int paint);


		int Weapon1 = GetPlayerWeaponSlot(client, WEAPON_SLOT);
		if(IsValidEntity(Weapon1))
		{
			//The b_removeattrib checks if it should remove attributes from the variable "remove_attributes" from the config file
			if(b_removeattrib)TF2Attrib_RemoveAll(Weapon1);

			//Modify the code below to add the attributes ot the weapon
			for(attributes)
			{
				StringAttribute = "Read From Somewhere";
				AttributeValue = ReadFromSomewhere
				TF2Attrib_SetByName(Weapon1, StringAttribute, AttributeValue);
			}			
		}

		}
	}
}
