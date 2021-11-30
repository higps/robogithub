// TeamRoundTimer
// By icebear
// Inspired by: NoobBalance's sugestion: https://forums.alliedmods.net/showthread.php?t=137841

#if defined _team_round_timer_included
 #endinput
#endif
#define _team_round_timer_included "0.1"

methodmap TeamRoundTimerIterator < StringMap {
    property int EntityId {
        public get(){ 
            int value;
            this.GetValue("EntityId", value);
            return value;
        }
        public set(int value){
            this.SetValue("EntityId", value);
        }
    }
    property bool IsPaused {
        public get(){
            if (this.EntityId < 0)
                return true;
            return view_as<bool>(GetEntProp(this.EntityId, Prop_Send, "m_bTimerPaused"));
        }
    }
    property bool IsDisabled {
        public get(){
            if (this.EntityId < 0)
                return true;
            return view_as<bool>(GetEntProp(this.EntityId, Prop_Send, "m_bIsDisabled"));
        }
    }
    property float EndTime {
        public get(){
            if (this.EntityId < 0)
                return -1.0;
            return GetEntPropFloat(this.EntityId, Prop_Send, "m_flTimerEndTime");
        }
    }

    public TeamRoundTimerIterator() {
        TeamRoundTimerIterator timer = view_as<TeamRoundTimerIterator>(new StringMap());
        timer.EntityId = -1;
        return timer;
    }

    public void HookOnFinished(EntityOutput callback, bool once = false)
    {
        HookSingleEntityOutput(this.EntityId, "OnFinished", callback, once);
    }

    public void UnhookOnFinished(EntityOutput callback)
    {
        UnhookSingleEntityOutput(this.EntityId, "OnFinished", callback);
    }

    public bool FindNextTimer()
    {
        this.EntityId = FindEntityByClassname(this.EntityId, "team_round_timer");

        return this.EntityId != -1;
    }
}

methodmap TeamRoundTimer __nullable__ {

    public TeamRoundTimer() {
        return view_as<TeamRoundTimer>(0);
    }
    
    public bool HookOnFinished(EntityOutput callback, bool once = false)
    {        
        TeamRoundTimerIterator internal = new TeamRoundTimerIterator();

        bool found;
        while (internal.FindNextTimer()) {
            internal.HookOnFinished(callback, once);
            found = true;
        }
        delete internal;

        return found;
    }
    
    public bool UnhookOnFinished(EntityOutput callback)
    {        
        TeamRoundTimerIterator internal = new TeamRoundTimerIterator();

        bool found;
        while (internal.FindNextTimer()) {
            internal.UnhookOnFinished(callback);
            found = true;
        }
        delete internal;

        return found;
    }
    
    public bool GetEndTime(float& buffer)
    {        
        TeamRoundTimerIterator internal = new TeamRoundTimerIterator();

        bool found;
        float earliestRoundEndTime = 1000000000000.0;
        while (internal.FindNextTimer()) {
            if (internal.IsPaused)
                continue;
            if (internal.IsDisabled)
                continue;

            if (internal.EndTime < earliestRoundEndTime || !found) {
                earliestRoundEndTime = internal.EndTime;
                found = true;
            }
        }
        delete internal;

        if (!found)
            return false;

        buffer = earliestRoundEndTime;
        return true;
    }
}