/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: particle.inc
 * Description: Functions to show TF2 particles
 * Author(s): L. Duke
 */

#if defined _particle_included
#endinput
#endif
#define _particle_included

#include <timers>

stock gParticleCount = 0;

// Particle Attachment Types  -------------------------------------------------
enum ParticleAttachmentType
{
    NoAttach = 0,
    Attach,
    AttachMaintainOffset
};

// Particles ------------------------------------------------------------------

/* CreateParticle()
**
** Creates a particle at an entity's position. Attach determines the attachment
** type (0 = not attached, 1 = normal attachment, 2 = head attachment). Allows
** offsets from the entity's position.
** ------------------------------------------------------------------------- */
stock CreateParticle(const String:particleType[], Float:time=5.0, entity=-1,
                     ParticleAttachmentType:attach=Attach,
                     const String:attachToBone[]="head",
                     const Float:offsetPos[3]=NULL_VECTOR,
                     const Float:offsetAng[3]=NULL_VECTOR,
                     Timer:deleteFunc=Timer:0,
                     &Handle:timerHandle=INVALID_HANDLE,
                     target=-1, const String:targetBone[]="flag",
                     &target_particle=0)
{
    new particle = CreateEntityByName("info_particle_system");
    if (particle > 0 && IsValidEdict(particle))
    {
        decl Float:pos[3], Float:ang[3];
        if (entity > 0)
        {
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
            AddVectors(pos, offsetPos, pos);

            GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);
            AddVectors(ang, offsetAng, ang);
        }
        else
        {
            pos[0] = offsetPos[0];
            pos[1] = offsetPos[1];
            pos[2] = offsetPos[2];

            ang[0] = offsetAng[0];
            ang[1] = offsetAng[1];
            ang[2] = offsetAng[2];
        }

        TeleportEntity(particle, pos, ang, NULL_VECTOR);

        DispatchKeyValue(particle, "effect_name", particleType);

        if (entity > 0)
        {
            if (attach > NoAttach)
            {
                decl String:eName[32];
                Format(eName, sizeof(eName), "target%i", entity);
                DispatchKeyValue(entity, "targetname", eName);
                DispatchKeyValue(particle, "parentname", eName);

                //SetVariantString("!activator");
                //AcceptEntityInput(particle, "SetParent", entity, particle, 0);
                SetVariantString(eName);
                AcceptEntityInput(particle, "SetParent");

                if (attachToBone[0] != '\0')
                {
                    SetVariantString(attachToBone);
                    AcceptEntityInput(particle, (attach >= AttachMaintainOffset)
                                                ? "SetParentAttachmentMaintainOffset"
                                                : "SetParentAttachment");
                }
            }
        }

        if (target > 0)
        {
            target_particle = CreateEntityByName("info_particle_system");
            if (target_particle > 0 && IsValidEdict(target_particle))
            {
                decl String:pName[32];
                Format(pName, sizeof(pName), "TF2particle%i", particle);
                DispatchKeyValue(particle, "targetname", pName);

                decl String:tName[32];
                Format(tName, sizeof(tName), "target%i", target);
                DispatchKeyValue(target, "targetname", tName);
                DispatchKeyValue(target_particle, "parentname", tName);

                new Float:origin[3];
                GetEntPropVector(target, Prop_Send, "m_vecOrigin", origin);
                DispatchKeyValueVector(target_particle, "origin", origin);

                SetVariantString(pName);
                AcceptEntityInput(target_particle, "SetParent");
                //SetVariantString("!activator");
                //AcceptEntityInput(target_particle, "SetParent", particle, target_particle, 0);

                //Join the source particle to the destination particle
                new String:tpName[128];
                Format(tpName, sizeof(tpName), "TF2particle%i", target_particle);
                DispatchKeyValue(target_particle, "targetname", tpName);
                DispatchKeyValue(particle, "cpoint1", tpName);

                if (targetBone[0] != '\0')
                {
                    SetVariantString(targetBone);
                    AcceptEntityInput(target_particle, "SetParentAttachment");
                }
            }
            else
                LogError("CreateParticle: could not create target info_particle_system");
        }

        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        gParticleCount++;

        if (time > 0.0)
        {
            timerHandle = CreateTimer(time, deleteFunc ? deleteFunc : DeleteParticles,
                                      EntIndexToEntRef(particle));
        }
    }
    else
        LogError("CreateParticle: could not create info_particle_system");

    return particle;
}

#define AttachParticle(%1,%2,%3,%4,%5) CreateParticle(%2,%4,%1,Attach,"head",%3)
//stock AttachParticle(ent, String:particleType[], Timer:func=Timer:0, Float:time=5.0,
//                     const Float:offsetVec[3]=NULL_VECTOR)
//{
//    return CreateParticle(particleType, time, ent, Attach, "head", offsetVec);
//}

#define AttachParticleEx(%1,%2,%3,%4,%5) CreateParticle(%2,%3,%1,Attach,"",%4,%5)
//stock AttachParticleEx(ent, String:particleType[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
//{
//    return CreateParticle(particleType, time, ent, Attach, "", addPos, addAngle);
//}

#define AttachParticleBone(%1,%2,%3,%4,%5,%6) CreateParticle(%2,%4,%1,Attach,%3,%5,%6)
//stock AttachParticleBone(ent, String:particleType[], String:attachBone[], Float:time,
//                         Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
//{
//    return CreateParticle(particleType, time, ent, Attach, attachBone, addPos, addAngle);
//}

#define ShowParticle(%1,%2,%3,%4) CreateParticle(%2,%3,0,NoAttach,"",%1,NULL_VECTOR,NULL_VECTOR,%4)
//stock ShowParticle(Float:pos[3], String:particleType[], Float:time, Timer:func)
//{
//    return CreateParticle(particleType, time, 0, NoAttach, "", pos,NULL_VECTOR,NULL_VECTOR,func);
//}

#define ShowParticleEx(%1,%2,%3,%4,%5) CreateParticle(%2,%3,0,NoAttach,"",%1,%4,%5)
//stock ShowParticleEx(String:particlename[], Float:time, Float:pos[3], Float:ang[3]=NULL_VECTOR)
//{
//    return CreateParticle(particleType, time, 0, NoAttach, "", pos, ang);
//}

#define ShowParticleEntity(%1,%2,%3,%4,%5) CreateParticle(%2,%3,%1,Attach,"",%4,%5)
//stock ShowParticleEntity(ent, String:particleType[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
//{
//    return CreateParticle(particleType, time, ent, Attach, "", pos, ang);
//}

#define GetParticleCount() gParticleCount

stock DeleteParticle(particleRef)
{
    new particle = EntRefToEntIndex(particleRef);
    if (particle > 0 && IsValidEntity(particle))
    {
        AcceptEntityInput(particle, "stop");
        RemoveEdict(particle);
    }
    gParticleCount--;
}

public Action:DeleteParticles(Handle:timer, any:particleRef)
{
    DeleteParticle(particleRef);
    return Plugin_Stop;
}

stock TE_SetupParticle(const String:Name[], const Float:origin[3]=NULL_VECTOR,
                       const Float:start[3]=NULL_VECTOR, const Float:angles[3]=NULL_VECTOR,
                       entindex=-1, attachtype=-1, attachpoint=-1, bool:resetParticles=true)
{
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }
    
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);

    if (entindex!=-1)
        TE_WriteNum("entindex", entindex);

    if (attachtype!=-1)
        TE_WriteNum("m_iAttachType", attachtype);

    if (attachpoint!=-1)
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);

    TE_WriteNum("m_bResetParticles", resetParticles);    
}

stock TE_Particle(const String:Name[], const Float:origin[3]=NULL_VECTOR,
                  const Float:start[3]=NULL_VECTOR, const Float:angles[3]=NULL_VECTOR,
                  entindex=-1, attachtype=-1, attachpoint=-1, bool:resetParticles=true,
                  Float:delay=0.0)
{
    TE_SetupParticle(Name, origin, start, angles, entindex,
                     attachtype, attachpoint, resetParticles);

    TE_SendToAll(delay);
}
