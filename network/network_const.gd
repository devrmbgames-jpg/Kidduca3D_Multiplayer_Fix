extends Reference


# for op code nakama
enum GLOBAL_TYPE_DATA {
	LOBBY = 1,
	RACE = 2,
	OPEN_GAME = 3,
	
	LOBBY_FOOTBALL = 4,
	FOOTBALL = 5,
}

const _paths := {
	GLOBAL_TYPE_DATA.LOBBY : "/root/Singletones/Network Globalgd/NetworkLobby_v2",
	GLOBAL_TYPE_DATA.LOBBY_FOOTBALL : "/root/Singletones/Network Globalgd/NetworkLobbyFootball_v2",
	GLOBAL_TYPE_DATA.RACE : "/root/RaceBase",
	GLOBAL_TYPE_DATA.OPEN_GAME : "/root/Main/World",
	GLOBAL_TYPE_DATA.FOOTBALL : "/root/Main/World/RoomList/Island/Levels/SportsFootball"
}

enum TYPE_DATA_RACE {
	UPDATE_RACE,
	UPDATE_CAR,
	UPDATE_BONUS_BOX,
	UPDATE_ROCKET,
	UPDATE_BOMB,
	UPDATE_BUSH,
	UPDATE_INTER_OBJ,
}

enum TYPE_DATA_OPEN_GAME {
	UPDATE_OG_WORLD,
	UPDATE_OG_PLAYER,
	UPDATE_OG_PLAYER_NETWORK,
	
	UPDATE_OG_PLAYER_NETWORK_LEVEL,
	UPDATE_OG_LOBBY,
	UPDATE_OG_LEVELS,
	UPDATE_OG_TRIGGER,
}

enum TYPE_OBJ_LEVEL {
	FOOTBALL_TEAM_MARK,
	FOOTBALL_BALL,
	FOOTBALL_GAME,
	FOOTBALL_BOT,
}


static func get_path(global_type: int) -> String :
	assert(_paths.has(global_type))
	return _paths[global_type]
