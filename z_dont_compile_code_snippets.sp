// Action RemoveStunEffect(Handle timer, DataPack data) {
	
//     data.Reset();
// 	int particle = data.ReadCell();

//     TE_SetupStopParticleEffect(particle, "bot_radio_waves");

//     // AcceptEntityInput(particle, "Stop");
//     // AcceptEntityInput(particle, "Kill");

// 	if (!IsValidEntity(particle)) {
// 		PrintToChatAll("Not valid");
// 		return Plugin_Handled;
// 	}

	
	
// 	return Plugin_Handled;
// }

// stock void TE_SetupStopParticleEffect(int entity, const char[] sParticleName)
// {
// 	TE_Start("EffectDispatch");
	
// 	if(entity > 0)
// 		TE_WriteNum("entindex", entity);
	
// 	TE_WriteNum("m_nHitBox", GetParticleEffectIndex(sParticleName));
// 	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffectStop"));
// }

// // stock void TE_SetupStopParticleEffects(int entity)
// // {
// //     TE_Start("EffectDispatch");
    
// //     if(entity > 0)
// //         TE_WriteNum("entindex", entity);
    
// //     TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffectStop"));
// // }

// stock int GetParticleEffectIndex(const char[] sEffectName)
// {
// 	int table = INVALID_STRING_TABLE;
	
// 	if (table == INVALID_STRING_TABLE)
// 	{
// 		table = FindStringTable("ParticleEffectNames");
// 	}
	
// 	int iIndex = FindStringIndex(table, sEffectName);
// 	if(iIndex != INVALID_STRING_INDEX)
// 		return iIndex;
	
// 	// This is the invalid string index
// 	return 0;
// }

// stock int GetEffectIndex(const char[] sEffectName)
// {
// 	int table = INVALID_STRING_TABLE;
	
// 	if (table == INVALID_STRING_TABLE)
// 	{
// 		table = FindStringTable("EffectDispatch");
// 	}
	
// 	int iIndex = FindStringIndex(table, sEffectName);
// 	if(iIndex != INVALID_STRING_INDEX)
// 		return iIndex;
	
// 	// This is the invalid string index
// 	return 0;
// }