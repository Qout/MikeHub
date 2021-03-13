#pragma semicolon 1

#define PLUGIN_AUTHOR "MrQout"
#define PLUGIN_VERSION "5.0R2"
#define PLUGIN_DATA "12.03.2021"

#include <sourcemod>
#include <csgo_colors>

#undef REQUIRE_PLUGIN
#include <mapchooser>
#include <shop>
#define REQUIRE_PLUGIN

#pragma newdecls required

char s_Version[32], i_ServerIp[16];
int  i_ServerPort = 0;
bool g_bMapChooser, g_bShop;

public Plugin myinfo = 
{
	name = "MikeHub",
	author = PLUGIN_AUTHOR,
	description = "MikeHub For MikeBot'a",
	version = PLUGIN_VERSION,
	url = ""
};
 
public void OnAllPluginsLoaded()
{
    g_bMapChooser = LibraryExists("mapchooser");
    g_bShop = LibraryExists("shop");
}

public void OnLibraryRemoved(const char[] sName)
{
	g_bMapChooser = !(strcmp(sName, "mapchooser") == 0);
	g_bShop = !(strcmp(sName, "shop") == 0);
}

public void OnLibraryAdded(const char[] sName)
{
	g_bMapChooser = (strcmp(sName, "mapchooser") == 0);
	g_bShop = (strcmp(sName, "shop") == 0);
}

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("Данный плагин только для игры CS:GO");
	else
	{
	 	char g_ServerIp[16], g_ServerPort[8];
	 	
	 	int iIp = GetConVarInt(FindConVar("hostip"));
	 	GetConVarString(FindConVar("hostport"), g_ServerPort, sizeof(g_ServerPort));
	 	Format(g_ServerIp, sizeof(g_ServerIp), "%i.%i.%i.%i", (iIp >> 24) & 0x000000FF, (iIp >> 16) & 0x000000FF, (iIp >>  8) & 0x000000FF, iIp & 0x000000FF);
	 	
		i_ServerIp = g_ServerIp;
		i_ServerPort = StringToInt(g_ServerPort);
		
		Format(s_Version, sizeof(s_Version), "%s (%s)", PLUGIN_VERSION, PLUGIN_DATA);
		
		g_bMapChooser = LibraryExists("mapchooser");
		g_bShop = LibraryExists("shop");
		
		RegAdminCmd("sm_mike"	   	     , i_mike	    , ADMFLAG_ROOT);
		RegAdminCmd("sm_mike_vkmessage"  , i_vkmessage  , ADMFLAG_ROOT);
		RegAdminCmd("sm_mike_getinfo"    , i_getinfo    , ADMFLAG_ROOT);
		RegAdminCmd("sm_mike_giveitems"  , i_giveitems  , ADMFLAG_ROOT);
	}
}

public Action i_mike(int client, int args)
{
	char s_ConsBuffer[256], s_ChatBuffer[1024];
	
	s_ConsBuffer = "Бот на движке: MikeBot\nВерсия: %s\n\nЭта команда доступа только Создателю";
	s_ChatBuffer = " {default}Бот на движке: {green}MikeBot\n {default}Версия: {green}%s\n\n{red} Эта команда доступа только Создателю";
	
	
	PrintToConsole(client, s_ConsBuffer, s_Version);
	
	if ((client > 0 && client <= MaxClients) && (IsClientInGame(client) && !IsFakeClient(client)))
		CGOPrintToChat	  (client, s_ChatBuffer, s_Version);
	
	return Plugin_Handled;
}

public Action i_vkmessage(int client, int args)
{
	if (args > 0)
	{
		char Msg[4096];
		GetCmdArg(1, Msg, sizeof(Msg));
		
		Format(Msg, sizeof(Msg), "{red}Сообщение из беседы:  {green}%s", Msg);
		CGOPrintToChatAll(Msg);
	}
	
	return Plugin_Handled;
}

public Action i_giveitems(int client, int args)
{
	if (g_bShop && args >= 4)
	{
		char SteamId[32], CategoryName[256], ItemName[256], Value[8], Buffer[1024];
		
		GetCmdArg(1, SteamId, sizeof(SteamId));
		GetCmdArg(2, CategoryName, sizeof(CategoryName));
		GetCmdArg(3, ItemName, sizeof(ItemName));
		GetCmdArg(4, Value, sizeof(Value));
		GetCmdArg(5, Buffer, sizeof(Buffer));
		
		int _Value = 0;
		StringToIntEx(Value, _Value);
		
		if (_Value > 0)
		{
			int iClient = GetClient(SteamId);
			
			if (iClient == -1)
				PrintToConsole(client, "404");
			else
			{
				if (IsPlayerItem2(iClient, CategoryName, ItemName))
					PrintToConsole(client, "405");
				else
				{
					GivePlayerItem2(iClient, CategoryName, ItemName, _Value);
					PrintToConsole(client, "1");
					
					if (Buffer[0] != '\0')
						CGOPrintToChat(iClient, Buffer);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action i_getinfo(int client, int args)
{
	char HostName[128], MapName[128], s_Buffer[1024], s_MapBuffer[PLATFORM_MAX_PATH];
	int i, slots, timemap;
	
	GetConVarString(FindConVar("hostname"), HostName, sizeof(HostName));
	GetCurrentMap(MapName, 128);
	slots = GetMaxHumanPlayers();
	
	// Get Online
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsValidPlayer(iClient)) i++;
	
	
	
	
	
	// Get Time ** [BEGIN] **
	
	GetMapTimeLeft(timemap);
	if(timemap > 0) FormatEx(s_Buffer, sizeof(s_Buffer), "%d:%02d", timemap / 60, timemap % 60);
	
	if(g_bMapChooser && !(EndOfMapVoteEnabled() && !HasEndOfMapVoteFinished()))
	{
		GetNextMap(s_MapBuffer, sizeof(s_MapBuffer));
		GetMapDisplayName(s_MapBuffer, s_MapBuffer, sizeof(s_MapBuffer));
	}
	
	Format(s_Buffer, sizeof(s_Buffer), (s_MapBuffer[0] == '\0' ? "%s%s" : (timemap > 0 ? "%s%s/%s" : "%s%s%s")), (s_MapBuffer[0] == '\0' ? "500" : (timemap > 0 ? "501" : "502")), s_Buffer, s_MapBuffer);
	
	// Get Time ** [END] **
	
	
	char s_Info[1024];
	Format(s_Info, sizeof(s_Info), "Info: %s:%i|%s|%s|%i|%i",
		i_ServerIp, i_ServerPort, MapName, s_Buffer, i, slots
	);
	
	
	
	//																											          *MAP TIME
	PrintToConsole(client, "Name: %s\n%s\n\nPlayers:\n", HostName, s_Info);
	
	int Permissions[3] = 
	{
		ADMFLAG_KICK,
		ADMFLAG_BAN,
		ADMFLAG_ROOT,
	};
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsValidPlayer(iClient))continue;
		
		int UserId;
		char NickName[MAX_NAME_LENGTH], NickNameFix[MAX_NAME_LENGTH], IsAdmin[8], SteamId[32], PlayerIP[32];
		
		Format(NickName, sizeof(NickName), "%N", iClient);
		Format(IsAdmin, sizeof(IsAdmin), "-");
		
		NickNameFix = NickName;
		TrimString(NickNameFix);
		
		UserId = GetClientUserId(iClient);
		GetClientAuthId(iClient, AuthId_Steam2, SteamId, sizeof(SteamId));
		
		for (int Permission = 0; Permission < sizeof(Permissions); Permission++)
		{
			if ((GetUserFlagBits(iClient) & Permissions[Permission]))
			{
				Format(IsAdmin, sizeof(IsAdmin), (Permission == 2 ? "7001" : ((Permission == 0 || Permission == 1) ? "7000" : "-1" )));
				break;
			}
		}
		
		if (NickNameFix[0] == '\0' || StrEqual(NickNameFix, "unnamed") || StrContains(NickNameFix, "unnamed") > 0)Format(NickName, sizeof(NickName), "unnamed#%i", UserId);
		GetClientIP(iClient, PlayerIP, sizeof(PlayerIP), false);
		PrintToConsole(client, "%s\n#%i|%s|%s|%s", NickName, UserId, SteamId, IsAdmin, PlayerIP);
	}
	
	return Plugin_Handled;
}

int GetClient(char[] Search_SteamId)
{
	int Client = -1;
	
	if (Search_SteamId[0] == '\0')return Client;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || IsFakeClient(iClient))continue;
		
		char SteamId[32];
		GetClientAuthId(iClient, AuthId_Steam2, SteamId, sizeof(SteamId));
		
		if (StrEqual(SteamId, Search_SteamId))
		{
			Client = iClient;
			break;
		}
	}
	
	return Client;
}

bool IsValidPlayer(int iClient, bool alive = false)
{
	return (
		iClient > 0 && iClient <= MaxClients
		&& IsClientConnected(iClient) && IsClientInGame(iClient)
		&& !IsFakeClient(iClient)
		&& (!alive || IsPlayerAlive(iClient)));
}

public ItemId GivePlayerItem2(int iClient, const char[] CategoryName, const char[] ItemName, int value)
{
	ItemId item_id = Shop_GetItemId(Shop_GetCategoryId(CategoryName), ItemName);
	Shop_GiveClientItem(iClient, item_id, value);
	
	return item_id;
}

public ItemId RemovePlayerItem2(int iClient, const char[] CategoryName, const char[] ItemName, int value)
{
	ItemId item_id = Shop_GetItemId(Shop_GetCategoryId(CategoryName), ItemName);
	Shop_ToggleClientItem(iClient, item_id, Toggle_Off);
	Shop_RemoveClientItem(iClient, item_id, value);
	
	return item_id;
}

public bool IsPlayerItem2(int iClient, const char[] CategoryName, const char[] ItemName)
{
	return Shop_IsClientHasItem(iClient, Shop_GetItemId(Shop_GetCategoryId(CategoryName), ItemName));
}