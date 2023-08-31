Action RemoveStunEffect(Handle timer, DataPack data) {
	
    data.Reset();
	int particle = data.ReadCell();

    TE_SetupStopParticleEffect(particle, "bot_radio_waves");

    // AcceptEntityInput(particle, "Stop");
    // AcceptEntityInput(particle, "Kill");

	if (!IsValidEntity(particle)) {
		PrintToChatAll("Not valid");
		return Plugin_Handled;
	}

	
	
	return Plugin_Handled;
}

stock void TE_SetupStopParticleEffect(int entity, const char[] sParticleName)
{
	TE_Start("EffectDispatch");
	
	if(entity > 0)
		TE_WriteNum("entindex", entity);
	
	TE_WriteNum("m_nHitBox", GetParticleEffectIndex(sParticleName));
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffectStop"));
}

// stock void TE_SetupStopParticleEffects(int entity)
// {
//     TE_Start("EffectDispatch");
    
//     if(entity > 0)
//         TE_WriteNum("entindex", entity);
    
//     TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffectStop"));
// }

stock int GetParticleEffectIndex(const char[] sEffectName)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	int iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
}

stock int GetEffectIndex(const char[] sEffectName)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	int iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
}


int GetParticleSystemIndex(const char[] szParticleSystemName)
{
    if (szParticleSystemName[0])
    {
        int iStringTableParticleEffectNamesIndex = FindStringTable("ParticleEffectNames");
        if (iStringTableParticleEffectNamesIndex == INVALID_STRING_TABLE)
        {
            LogError("Missing string table 'ParticleEffectNames'");
            return 0;
        }
        
        int nIndex = FindStringIndex(iStringTableParticleEffectNamesIndex, szParticleSystemName);
        if (nIndex == INVALID_STRING_INDEX)
        {
            LogError("Missing precache for particle system '%s'", szParticleSystemName);
            return 0;
        }
        
        return nIndex;
        
    }
    
    return 0;
}

void TE_TFParticleEffectAttachment(const char[] szParticleName, int entity = -1, ParticleAttachment_t eAttachType = PATTACH_CUSTOMORIGIN, const char[] szAttachmentName, bool bResetAllParticlesOnEntity = false)
{
    int iAttachmentPoint = -1;
    if (IsValidEntity(entity))
    {
        iAttachmentPoint = LookupEntityAttachment(entity, szAttachmentName);
        if (iAttachmentPoint <= 0)
        {
            char szModelName[PLATFORM_MAX_PATH];
            GetEntPropString(entity, Prop_Data, "m_ModelName", szModelName, sizeof(szModelName));
            
            LogError("Model '%s' does not have attachment '%s' to attach particle system '%s' to", szModelName, szAttachmentName, szParticleName);
            return;
        }
    }
    
    TE_Start("TFParticleEffect");
    
    TE_WriteNum("m_iParticleSystemIndex", GetParticleSystemIndex(szParticleName));
    
    if (IsValidEntity(entity))
    {
        TE_WriteNum("entindex", entity);
    }
    
    TE_WriteNum("m_iAttachType", view_as<int>(eAttachType));
    TE_WriteNum("m_iAttachmentPointIndex", iAttachmentPoint);
    
    if (bResetAllParticlesOnEntity)
    {
        TE_WriteNum("m_bResetParticles", true);
    }
    
    TE_SendToAll();
}