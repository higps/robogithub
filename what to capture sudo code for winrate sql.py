g_round_id = 0
g_map
g_pick_list = [][]
Event Round Start():

    pick_list = [][] empty
    Timestamp = GetEngineTime()+Dato+Tid+Whatever
    map
    antall spillere
    RobotTeam 
    g_round_id = Timestamp+no_shit
    g_map = map()
    round_start = GetEngineTime()



OnRobotPick():
    Name = GetRobotName()
    PickTime = GetEngineTime()
    Client = GetRobotClient()
    Team = GetClientTeam()
    RandomPick = WasItRandom?()
    Map 
    pick_list.append([Name, xxxx, g_round_id])


Event Round End():
    Winning Team = TeamThatWon()
    WasRobot = IsRobotTeam()
    TotalTime = GetEngineTime()
    Total Players = GetAllPlayers()

    SaveToPickTableSQL():
        pick_list[][] to sql

    SaveToRundeInfoSQL():
        Timestamp = GetEngineTime()+Dato+Tid+Whatever
        map
        antall spillere
        RobotTeam 
        g_round_id = Timestamp+no_shit
        g_map = map()
        round_start = GetEngineTime()
