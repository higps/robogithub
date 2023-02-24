// CTFPlayer::GetObjectCount()
stock int TF2_GetObjectCount(int client)
{
	// CUtlVector<CBaseObject*, CUtlMemory<CBaseObject*, int>>
	return GetEntData(client, FindSendPropInfo("CTFPlayer", "m_flMvMLastDamageTime") + 48 + 12);
}

// CTFPlayer::GetObject(int)
stock int TF2_GetObject(int client, int objidx)
{
	//8568 linux
	//8560 windows
	int offset = FindSendPropInfo("CTFPlayer", "m_flMvMLastDamageTime") + 48;
	Address m_aObjects = view_as< Address >(LoadFromAddress(GetEntityAddress(client) + view_as< Address >(offset), NumberType_Int32));
	return LoadFromAddress(m_aObjects + view_as< Address >(4 * objidx), NumberType_Int32) & 0xFFF;
}

// CTFPlayer::GetObjectOfType(int, int)
stock int TF2_GetObjectOfType(int client, TFObjectType objtype, TFObjectMode objmode = TFObjectMode_None, bool incdisposables = false)
{
	int numobjs = TF2_GetObjectCount(client);
	if (numobjs <= 0)
		return -1;

	int obj;
	int count;
	do
	{
		obj = TF2_GetObject(client, count);
		if (TF2_GetObjectType(obj) == objtype
		&& TF2_GetObjectMode(obj) == objmode
		&& !(GetEntProp(obj, Prop_Send, "m_bDisposableBuilding") && !incdisposables))
		{
			return obj;
		}

	}	while ++count < numobjs;
	return -1;
}

// CTFPlayer::GetNumObjects(int, int)
stock int TF2_GetNumObjects(int client, TFObjectMode objmode, TFObjectType objtype, bool incdisposables = false)
{
	int objects;
	int count;
	int objcount = TF2_GetObjectCount(client);
	int obj;
	if (objtype == view_as< TFObjectType >(-1))
	{
		while (count < objcount)
		{
			obj = TF2_GetObject(client, count);
			if (!(GetEntProp(obj, Prop_Send, "m_bDisposableBuilding") && !incdisposables))
			{
				if (TF2_GetObjectMode(obj) == objmode)
					++objects;
			}
			++count;
		}
	}
	else
	{
		while (objcount > count)
		{
			obj = TF2_GetObject(client, count);
			if (!(GetEntProp(obj, Prop_Send, "m_bDisposableBuilding") && !incdisposables))
			{
				if (TF2_GetObjectMode(obj) == objmode && TF2_GetObjectType(obj) == objtype)
					++objects;
			}
			++count;
		}
	}
	return objects;
}