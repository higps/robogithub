#include <sourcemod>


public Plugin myinfo =
{
	name = "berobot_bugged_plugin_reloader",
	author = "Heavy Is GPS | Bmod.TF",
	description = "Reloads a few plugins that sometimes bug out, where only a reload of them fixes it",
	version = "1.0",
	url = "https://github.com/higps/robogithub"
};


bool g_bool_loaded;

public void OnPluginStart()
{
    HookEvent("teamplay_round_start", Event_teamplay_round_start, EventHookMode_Post);
}

public void OnMapStart()
{
    g_bool_loaded = false;
}


public Action Event_teamplay_round_start(Event event, char[] name, bool dontBroadcast)
{

    if(!g_bool_loaded)
    {
     ServerCommand("sm_plugins reload /mm_cast_spell/");
     ServerCommand("sm_plugins reload /owned_building_phasing/");
     ServerCommand("sm_plugins reload /ability/");
     ServerCommand("sm_reload_robot_configs");
    //  CreateTimer(1.0, ReloadConfig);
     
     
     g_bool_loaded = true;
    }
     
}

// public Action ReloadConfig(Handle timer)
// {
//     PrintToChatAll("Reloading Configs");
    
// }