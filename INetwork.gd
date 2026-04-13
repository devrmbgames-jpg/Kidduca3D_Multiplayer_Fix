extends Node

const TOKEN_PATH := "user://token.txt"
const LOBBY_PKG := preload("res://content/network/lobby/network_lobby_v2.tscn")
const LOBBY_FOOTBALL_PKG := preload("res://content/network/lobby/network_lobby_football_v2.tscn")

const LOBBY := preload("res://content/network/lobby/network_lobby_v2.gd")
const LOBBY_FOOTBALL := preload("res://content/network/lobby/network_lobby_football_v2.gd")

const NetworkBridgeAPI := preload("res://content/network/network_bridge_api.gd")
const NetworkBridgeENet := preload("res://content/network/network_bridge_enet.gd")
const NetworkBridgeNakama := preload("res://content/network/network_bridge_nakama.gd")

var api : NetworkBridgeNakama
#var api_nakama : NetworkBridgeNakama = null
var lobby : LOBBY
var lobby_football : LOBBY_FOOTBALL 

var rematching := false

var token := ""

func load_tokens_and_init():
	pass

func create_token() -> void:
	pass

