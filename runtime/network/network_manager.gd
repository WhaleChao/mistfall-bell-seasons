class_name PixelRPGNetworkManager
extends Node

signal status_changed(message: String)
signal roster_changed(roster: Array[Dictionary])
signal snapshot_received(players: Dictionary)
signal world_state_received(world: Dictionary)
signal action_result_received(action: String, result: Dictionary)

const PROTOCOL_VERSION := "1.2.0"
const DEFAULT_PORT := 27180
const DEFAULT_MAX_CLIENTS := 8
const MAX_CLIENTS_LIMIT := 16
const SNAPSHOT_INTERVAL := 0.05
const WORLD_SYNC_INTERVAL := 0.5
const WORLD_SAVE_INTERVAL := 30.0
const INPUT_RATE_LIMIT_MSEC := 25
const ACTION_RATE_LIMIT_MSEC := 150
const PLAYER_SPEED := 118.0
const VALID_MAPS := ["mistfall_farm", "mistfall_village", "mistfall_river", "bellwood_grove", "clockwork_ruins", "mistfall_depths", "dreaming_shore"]
const ALLOWED_ACTIONS := ["farm_plot", "gather", "map_resource", "fish", "ship", "tend_animal", "buy_offer", "farm_upgrade", "automation_place", "automation_configure", "automation_remove", "cook", "eat", "talk", "court_npc", "propose_npc", "family_event"]

enum Role { OFFLINE, SERVER, CLIENT }

var role := Role.OFFLINE
var peer: ENetMultiplayerPeer
var server_name := "霧落農歌伺服器"
var world_name := "default"
var local_player_name := "旅人"
var local_player_key := ""
var farm_mode := "shared"
var relationship_mode := "independent"
var local_player_node: Node2D
var is_dedicated_server := false
var handshake_complete := false
var server_players: Dictionary = {}
var latest_snapshot: Dictionary = {}
var shared_world: Dictionary = {}
var _input_accumulator := 0.0
var _snapshot_accumulator := 0.0
var _world_sync_accumulator := 0.0
var _world_save_accumulator := 0.0
var _last_input_msec: Dictionary = {}
var _last_action_msec: Dictionary = {}
var _last_sequence: Dictionary = {}
var _server_started_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	call_deferred("_start_from_command_line")


func _process(delta: float) -> void:
	if role == Role.SERVER:
		_server_process(delta)
	elif role == Role.CLIENT and handshake_complete:
		_client_process(delta)


func host_server(port: int = DEFAULT_PORT, max_clients: int = DEFAULT_MAX_CLIENTS, requested_server_name: String = "霧落農歌伺服器", requested_player_name: String = "旅人", dedicated: bool = false, requested_world_name: String = "default", requested_farm_mode: String = "shared", requested_relationship_mode: String = "independent") -> Dictionary:
	stop(false)
	if port < 1024 or port > 65535:
		return {"ok": false, "message": "連接埠必須介於 1024–65535"}
	var safe_clients := clampi(max_clients, 1, MAX_CLIENTS_LIMIT)
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, safe_clients)
	if error != OK:
		peer = null
		return {"ok": false, "message": "無法開啟 UDP %d（錯誤 %d）" % [port, error]}
	multiplayer.multiplayer_peer = peer
	role = Role.SERVER
	is_dedicated_server = dedicated
	server_name = _sanitize_name(requested_server_name, "霧落農歌伺服器", 32)
	world_name = _sanitize_world_name(requested_world_name)
	local_player_name = _sanitize_name(requested_player_name, "主機", 16)
	local_player_key = _load_or_create_client_id()
	farm_mode = requested_farm_mode if requested_farm_mode in PixelRPGMultiplayerNarrativeSystem.FARM_MODES else "shared"
	relationship_mode = requested_relationship_mode if requested_relationship_mode in PixelRPGMultiplayerNarrativeSystem.RELATIONSHIP_MODES else "independent"
	handshake_complete = not dedicated
	_server_started_msec = Time.get_ticks_msec()
	server_players.clear()
	_last_input_msec.clear()
	_last_action_msec.clear()
	_last_sequence.clear()
	_load_server_world()
	if not dedicated:
		server_players[1] = _new_player_state(1, local_player_name, local_player_key)
		_ensure_player_context(1)
		_refresh_multiplayer_story()
		_emit_roster()
		_broadcast_world()
	status_changed.emit("已開啟「%s」｜UDP %d｜上限 %d 人" % [server_name, port, safe_clients])
	if dedicated:
		print("PixelRPG dedicated server ready: protocol=%s udp=%d world=%s max_clients=%d" % [PROTOCOL_VERSION, port, world_name, safe_clients])
	return {"ok": true, "port": port, "max_clients": safe_clients, "dedicated": dedicated, "world": world_name, "farm_mode": farm_mode, "relationship_mode": relationship_mode}


func join_server(address: String, port: int = DEFAULT_PORT, requested_player_name: String = "旅人") -> Dictionary:
	stop(false)
	var safe_address := address.strip_edges()
	if safe_address.is_empty() or safe_address.length() > 255 or " " in safe_address:
		return {"ok": false, "message": "伺服器位址格式不正確"}
	if port < 1024 or port > 65535:
		return {"ok": false, "message": "連接埠必須介於 1024–65535"}
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(safe_address, port)
	if error != OK:
		peer = null
		return {"ok": false, "message": "無法連線（錯誤 %d）" % error}
	multiplayer.multiplayer_peer = peer
	role = Role.CLIENT
	local_player_name = _sanitize_name(requested_player_name, "旅人", 16)
	local_player_key = _load_or_create_client_id()
	handshake_complete = false
	status_changed.emit("正在連線至 %s:%d…" % [safe_address, port])
	return {"ok": true, "address": safe_address, "port": port}


func stop(announce: bool = true) -> void:
	if role == Role.SERVER:
		_capture_shared_world()
		_save_server_world()
	# Change role before closing: ENet may emit disconnect signals synchronously.
	role = Role.OFFLINE
	if peer != null:
		peer.close()
	multiplayer.multiplayer_peer = null
	peer = null
	is_dedicated_server = false
	handshake_complete = false
	server_players.clear()
	latest_snapshot.clear()
	_last_input_msec.clear()
	_last_action_msec.clear()
	_last_sequence.clear()
	if announce:
		status_changed.emit("離線模式")
		var empty_roster: Array[Dictionary] = []
		roster_changed.emit(empty_roster)


func set_local_player_node(node: Node2D) -> void:
	local_player_node = node


func is_online() -> bool:
	return role != Role.OFFLINE


func is_server() -> bool:
	return role == Role.SERVER


func is_client() -> bool:
	return role == Role.CLIENT


func connected_player_count() -> int:
	return server_players.size() if role == Role.SERVER else latest_snapshot.size()


func connection_summary() -> String:
	match role:
		Role.SERVER:
			return "專用伺服器｜%d 人" % server_players.size() if is_dedicated_server else "主機｜%d 人" % server_players.size()
		Role.CLIENT:
			return "已加入 %s｜%d 人" % [server_name, latest_snapshot.size()] if handshake_complete else "連線中"
		_:
			return "離線單人"


func local_world_view() -> Dictionary:
	if role == Role.SERVER and server_players.has(1):
		return _world_view_for_peer(1)
	return shared_world.duplicate(true)


func request_world_action(action: String, payload: Dictionary = {}) -> bool:
	if action not in ALLOWED_ACTIONS or JSON.stringify(payload).length() > 2048:
		return false
	if role == Role.SERVER:
		var result := _execute_world_action(1, action, payload)
		action_result_received.emit(action, result)
		_capture_shared_world()
		_broadcast_world()
		return true
	if role == Role.CLIENT and handshake_complete and peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_request_world_action.rpc_id(1, action, payload)
		return true
	return false


func server_world_path() -> String:
	return "user://pixelrpg_servers/%s.json" % world_name


func _server_process(delta: float) -> void:
	if not is_dedicated_server and is_instance_valid(local_player_node) and server_players.has(1):
		var host_state: Dictionary = server_players[1]
		host_state["position"] = [local_player_node.global_position.x, local_player_node.global_position.y]
		host_state["facing"] = [_local_facing().x, _local_facing().y]
		host_state["map"] = _current_map()
		server_players[1] = host_state
	for peer_id: int in server_players:
		if peer_id == 1:
			continue
		var state: Dictionary = server_players[peer_id]
		var input := _array_to_vector(state.get("input", [0.0, 0.0])).limit_length(1.0)
		var position := _array_to_vector(state.get("position", [320.0, 180.0]))
		position += input * PLAYER_SPEED * delta
		position.x = clampf(position.x, 30.0, 610.0)
		position.y = clampf(position.y, 42.0, 330.0)
		state["position"] = [position.x, position.y]
		server_players[peer_id] = state
	_snapshot_accumulator += delta
	if _snapshot_accumulator >= SNAPSHOT_INTERVAL:
		_snapshot_accumulator = 0.0
		latest_snapshot = server_players.duplicate(true)
		var server_tick := Time.get_ticks_msec() - _server_started_msec
		for remote_peer_id: int in server_players:
			if remote_peer_id != 1 and _can_send_to_peer(remote_peer_id):
				_receive_snapshot.rpc_id(remote_peer_id, server_tick, latest_snapshot)
		snapshot_received.emit(latest_snapshot)
	_world_sync_accumulator += delta
	if _world_sync_accumulator >= WORLD_SYNC_INTERVAL:
		_world_sync_accumulator = 0.0
		_capture_shared_world()
		_broadcast_world()
	_world_save_accumulator += delta
	if _world_save_accumulator >= WORLD_SAVE_INTERVAL:
		_world_save_accumulator = 0.0
		_save_server_world()


func _client_process(delta: float) -> void:
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	_input_accumulator += delta
	if _input_accumulator < SNAPSHOT_INTERVAL:
		return
	_input_accumulator = 0.0
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	input = input.limit_length(1.0)
	var facing := _local_facing()
	var sequence := int(_last_sequence.get(multiplayer.get_unique_id(), 0)) + 1
	_last_sequence[multiplayer.get_unique_id()] = sequence
	_submit_input.rpc_id(1, sequence, [input.x, input.y], [facing.x, facing.y], _current_map())


func _start_from_command_line() -> void:
	var arguments := OS.get_cmdline_user_args()
	if "--server" not in arguments:
		return
	var port := DEFAULT_PORT
	var max_clients := DEFAULT_MAX_CLIENTS
	var requested_name := "霧落農歌專用伺服器"
	var requested_world := "default"
	var requested_farm_mode := "shared"
	var requested_relationship_mode := "independent"
	for argument: String in arguments:
		if argument.begins_with("--port="):
			port = int(argument.trim_prefix("--port="))
		elif argument.begins_with("--max-clients="):
			max_clients = int(argument.trim_prefix("--max-clients="))
		elif argument.begins_with("--server-name="):
			requested_name = argument.trim_prefix("--server-name=")
		elif argument.begins_with("--world="):
			requested_world = argument.trim_prefix("--world=")
		elif argument.begins_with("--farm-mode="):
			requested_farm_mode = argument.trim_prefix("--farm-mode=")
		elif argument.begins_with("--relationship-mode="):
			requested_relationship_mode = argument.trim_prefix("--relationship-mode=")
	var result := host_server(port, max_clients, requested_name, "", true, requested_world, requested_farm_mode, requested_relationship_mode)
	if not bool(result.get("ok", false)):
		push_error(String(result.get("message", "專用伺服器啟動失敗")))
		get_tree().quit(2)


func _on_peer_connected(peer_id: int) -> void:
	if role == Role.SERVER:
		status_changed.emit("玩家 %d 正在進行版本握手…" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if role != Role.SERVER:
		return
	server_players.erase(peer_id)
	_last_input_msec.erase(peer_id)
	_last_action_msec.erase(peer_id)
	_last_sequence.erase(peer_id)
	_refresh_multiplayer_story()
	_emit_roster()
	status_changed.emit("玩家 %d 已離線｜目前 %d 人" % [peer_id, server_players.size()])


func _on_connected_to_server() -> void:
	_submit_handshake.rpc_id(1, PROTOCOL_VERSION, local_player_name, local_player_key)


func _on_connection_failed() -> void:
	stop(false)
	status_changed.emit("連線失敗：請確認 IP、UDP %d 與防火牆／路由器轉送" % DEFAULT_PORT)


func _on_server_disconnected() -> void:
	stop(false)
	status_changed.emit("與伺服器的連線已中斷")


@rpc("any_peer", "call_remote", "reliable")
func _submit_handshake(protocol: String, requested_name: String, requested_player_key: String) -> void:
	if role != Role.SERVER:
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if protocol != PROTOCOL_VERSION:
		_receive_rejection.rpc_id(peer_id, "版本不相容：伺服器需要 %s" % PROTOCOL_VERSION)
		_disconnect_later(peer_id)
		return
	if server_players.has(peer_id):
		return
	var safe_player_key := requested_player_key.to_lower()
	if not _is_valid_player_key(safe_player_key):
		_receive_rejection.rpc_id(peer_id, "玩家識別碼格式不正確")
		_disconnect_later(peer_id)
		return
	for existing: Dictionary in server_players.values():
		if String(existing.get("player_key", "")) == safe_player_key:
			_receive_rejection.rpc_id(peer_id, "相同玩家身份已在線")
			_disconnect_later(peer_id)
			return
	var safe_name := _sanitize_name(requested_name, "旅人%d" % peer_id, 16)
	server_players[peer_id] = _new_player_state(peer_id, safe_name, safe_player_key)
	_ensure_player_context(peer_id)
	shared_world["total_connections"] = int(shared_world.get("total_connections", 0)) + 1
	_refresh_multiplayer_story()
	_receive_handshake_accepted.rpc_id(peer_id, peer_id, server_name)
	_receive_world_state.rpc_id(peer_id, _world_view_for_peer(peer_id))
	_emit_roster()
	status_changed.emit("%s 已加入｜目前 %d 人" % [safe_name, server_players.size()])
	print("PixelRPG peer accepted: id=%d name=%s protocol=%s" % [peer_id, safe_name, protocol])


@rpc("authority", "call_remote", "reliable")
func _receive_handshake_accepted(_assigned_peer_id: int, accepted_server_name: String) -> void:
	if role != Role.CLIENT:
		return
	server_name = accepted_server_name
	handshake_complete = true
	status_changed.emit("已加入「%s」" % server_name)


@rpc("authority", "call_remote", "reliable")
func _receive_rejection(reason: String) -> void:
	if role == Role.CLIENT:
		status_changed.emit("伺服器拒絕連線：%s" % reason.substr(0, 160))
		call_deferred("stop", false)


@rpc("any_peer", "call_remote", "unreliable_ordered", 0)
func _submit_input(sequence: int, input_array: Array, facing_array: Array, map_id: String) -> void:
	if role != Role.SERVER:
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not server_players.has(peer_id):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_input_msec.get(peer_id, 0)) < INPUT_RATE_LIMIT_MSEC:
		return
	if sequence <= int(_last_sequence.get(peer_id, -1)):
		return
	_last_input_msec[peer_id] = now
	_last_sequence[peer_id] = sequence
	var input := _array_to_vector(input_array)
	if not is_finite(input.x) or not is_finite(input.y) or input.length() > 1.05:
		return
	var facing := _array_to_vector(facing_array)
	var state: Dictionary = server_players[peer_id]
	state["input"] = [input.x, input.y]
	if facing.length_squared() > 0.01:
		facing = facing.normalized()
		state["facing"] = [facing.x, facing.y]
	state["map"] = map_id if map_id in VALID_MAPS else "mistfall_farm"
	server_players[peer_id] = state


@rpc("authority", "call_remote", "unreliable_ordered", 0)
func _receive_snapshot(_server_tick: int, players: Dictionary) -> void:
	if role != Role.CLIENT:
		return
	latest_snapshot = players.duplicate(true)
	var own_id := multiplayer.get_unique_id()
	if is_instance_valid(local_player_node) and latest_snapshot.has(own_id):
		var target := _array_to_vector(Dictionary(latest_snapshot[own_id]).get("position", [320.0, 180.0]))
		var error_distance := local_player_node.global_position.distance_to(target)
		local_player_node.global_position = target if error_distance > 64.0 else local_player_node.global_position.lerp(target, 0.18)
	snapshot_received.emit(latest_snapshot)
	_emit_roster_from_snapshot()


@rpc("any_peer", "call_remote", "reliable")
func _request_world_action(action: String, payload: Dictionary) -> void:
	if role != Role.SERVER or action not in ALLOWED_ACTIONS or JSON.stringify(payload).length() > 2048:
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not server_players.has(peer_id):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_action_msec.get(peer_id, 0)) < ACTION_RATE_LIMIT_MSEC:
		if _can_send_to_peer(peer_id):
			_receive_action_result.rpc_id(peer_id, action, {"ok": false, "message": "操作過快，請稍候"})
		return
	_last_action_msec[peer_id] = now
	var result := _execute_world_action(peer_id, action, payload)
	if _can_send_to_peer(peer_id):
		_receive_action_result.rpc_id(peer_id, action, result)
	_capture_shared_world()
	_broadcast_world()


@rpc("authority", "call_remote", "reliable")
func _receive_action_result(action: String, result: Dictionary) -> void:
	if role == Role.CLIENT:
		action_result_received.emit(action, result)


@rpc("authority", "call_remote", "reliable")
func _receive_world_state(world: Dictionary) -> void:
	if role != Role.CLIENT:
		return
	shared_world = world.duplicate(true)
	_apply_shared_world(shared_world)
	world_state_received.emit(shared_world)


func _execute_world_action(peer_id: int, action: String, payload: Dictionary) -> Dictionary:
	var state_store := get_node_or_null("/root/GameState")
	if state_store == null:
		return {"ok": false, "message": "伺服器世界尚未就緒"}
	if action in ["talk", "court_npc", "propose_npc", "family_event"]:
		return _execute_relationship_action(peer_id, action, payload)
	if farm_mode != "shared":
		return _execute_in_player_context(peer_id, action, payload)
	return _execute_game_state_action(state_store, action, payload)


func _execute_game_state_action(state_store: Node, action: String, payload: Dictionary) -> Dictionary:
	match action:
		"farm_plot":
			var tile := Vector2i(clampi(int(payload.get("x", -1)), 0, 63), clampi(int(payload.get("y", -1)), 0, 63))
			return state_store.interact_farm_plot(tile, StringName(String(payload.get("seed_id", ""))))
		"gather":
			return state_store.gather_resource(String(payload.get("node_id", "")), String(payload.get("kind", "")))
		"map_resource":
			return state_store.gather_map_resource(String(payload.get("node_id", "")))
		"fish":
			return state_store.fish_at(String(payload.get("location", "pond")))
		"ship":
			return state_store.ship_all_produce()
		"tend_animal":
			return state_store.interact_animal(String(payload.get("animal_id", "")))
		"buy_offer":
			return state_store.buy_offer(StringName(String(payload.get("shop_id", ""))), String(payload.get("offer_id", "")))
		"farm_upgrade":
			return state_store.purchase_next_farm_upgrade()
		"automation_place":
			var automation_tile := Vector2i(clampi(int(payload.get("x", -1)), 0, 5), clampi(int(payload.get("y", -1)), 0, 3))
			return state_store.purchase_automation_device(automation_tile, StringName(String(payload.get("device_id", ""))), Dictionary(payload.get("config", {})))
		"automation_configure":
			var configure_tile := Vector2i(clampi(int(payload.get("x", -1)), 0, 5), clampi(int(payload.get("y", -1)), 0, 3))
			return state_store.configure_automation_device(configure_tile, Dictionary(payload.get("config", {})))
		"automation_remove":
			var remove_tile := Vector2i(clampi(int(payload.get("x", -1)), 0, 5), clampi(int(payload.get("y", -1)), 0, 3))
			return state_store.remove_automation_device(remove_tile)
		"cook":
			return state_store.cook_recipe(StringName(String(payload.get("recipe_id", ""))))
		"eat":
			return state_store.eat_dish(StringName(String(payload.get("recipe_id", ""))))
	return {"ok": false, "message": "不支援的共同世界操作"}


func _capture_shared_world() -> void:
	var state_store := get_node_or_null("/root/GameState")
	if state_store == null:
		return
	shared_world.merge({
		"schema_version": 1,
		"protocol": PROTOCOL_VERSION,
		"world_name": world_name,
		"server_name": server_name,
		"calendar": state_store.calendar.date_snapshot(),
		"weather": state_store.current_weather,
		"farm": state_store.farm.to_data(),
		"flags": state_store.flags.duplicate(true),
		"quests": state_store.quest_states.duplicate(true),
		"dungeon": state_store.dungeon.to_data(),
		"eldritch": state_store.eldritch.to_data(),
		"story": state_store.story_state.duplicate(true),
		"multiplayer_rules": {"farm_mode": farm_mode, "relationship_mode": relationship_mode},
		"updated_at_unix": int(Time.get_unix_time_from_system()),
	}, true)


func _apply_shared_world(world: Dictionary) -> void:
	if int(world.get("schema_version", 0)) != 1 or String(world.get("protocol", "")) != PROTOCOL_VERSION:
		return
	var state_store := get_node_or_null("/root/GameState")
	if state_store == null:
		return
	state_store.calendar.load_data(Dictionary(world.get("calendar", {})))
	state_store.current_weather = String(world.get("weather", "clear"))
	state_store.farm.load_data(Dictionary(world.get("farm", {})))
	state_store.flags = Dictionary(world.get("flags", {})).duplicate(true)
	state_store.quest_states = Dictionary(world.get("quests", {})).duplicate(true)
	state_store.dungeon.load_data(Dictionary(world.get("dungeon", {})))
	state_store.eldritch.load_data(Dictionary(world.get("eldritch", {})))
	state_store.story_state = Dictionary(world.get("story", {})).duplicate(true)
	if world.has("inventory"):
		state_store.inventory = Dictionary(world.get("inventory", {})).duplicate(true)
	if world.has("coins"):
		state_store.coins = maxi(0, int(world.get("coins", 0)))
	if world.has("tools"):
		state_store.tools.load_data(Dictionary(world.get("tools", {})))
	if world.has("economy"):
		state_store.economy.load_data(Dictionary(world.get("economy", {})))
	if world.has("lifetime_stats"):
		state_store.lifetime_stats = Dictionary(world.get("lifetime_stats", {})).duplicate(true)
	if world.has("relationships"):
		state_store.social.load_data({"relationships":world.get("relationships", {}), "marriage":world.get("marriage", {}), "child":world.get("child", {})})
	var rules: Dictionary = world.get("multiplayer_rules", {})
	farm_mode = String(rules.get("farm_mode", farm_mode))
	relationship_mode = String(rules.get("relationship_mode", relationship_mode))


func _broadcast_world() -> void:
	if role == Role.SERVER and not shared_world.is_empty():
		for peer_id: int in server_players:
			if peer_id != 1 and _can_send_to_peer(peer_id):
				_receive_world_state.rpc_id(peer_id, _world_view_for_peer(peer_id))
		if not is_dedicated_server and server_players.has(1):
			_apply_shared_world(_world_view_for_peer(1))
			world_state_received.emit(_world_view_for_peer(1))


func _load_server_world() -> void:
	shared_world = {"schema_version": 1, "protocol": PROTOCOL_VERSION, "world_name": world_name, "server_name": server_name, "created_at_unix": int(Time.get_unix_time_from_system()), "total_connections": 0, "multiplayer_rules":{"farm_mode":farm_mode,"relationship_mode":relationship_mode}, "player_worlds":{}, "romance_claims":{}, "narrative_events":[]}
	var path := server_world_path()
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and int(parsed.get("schema_version", 0)) == 1 and String(parsed.get("protocol", "")) == PROTOCOL_VERSION:
			shared_world = Dictionary(parsed).duplicate(true)
			var loaded_rules: Dictionary = shared_world.get("multiplayer_rules", {})
			farm_mode = String(loaded_rules.get("farm_mode", farm_mode))
			relationship_mode = String(loaded_rules.get("relationship_mode", relationship_mode))
			_apply_shared_world(shared_world)
	_capture_shared_world()


func _ensure_player_context(peer_id: int) -> Dictionary:
	if not server_players.has(peer_id):
		return {}
	var player_state: Dictionary = server_players[peer_id]
	var player_key := String(player_state.get("player_key", ""))
	if not _is_valid_player_key(player_key):
		return {}
	var player_worlds: Dictionary = Dictionary(shared_world.get("player_worlds", {})).duplicate(true)
	if not player_worlds.has(player_key):
		var state_store := get_node_or_null("/root/GameState")
		player_worlds[player_key] = _capture_player_context(state_store) if state_store != null else {}
	shared_world["player_worlds"] = player_worlds
	var player_names: Dictionary = Dictionary(shared_world.get("player_names", {})).duplicate(true)
	player_names[player_key] = String(player_state.get("name", "旅人"))
	shared_world["player_names"] = player_names
	return Dictionary(player_worlds[player_key]).duplicate(true)


func _capture_player_context(state_store: Node) -> Dictionary:
	return {
		"farm":state_store.farm.to_data(),
		"inventory":state_store.inventory.duplicate(true),
		"coins":state_store.coins,
		"tools":state_store.tools.to_data(),
		"economy":state_store.economy.to_data(),
		"lifetime_stats":state_store.lifetime_stats.duplicate(true),
		"eldritch":state_store.eldritch.to_data(),
		"flags":state_store.flags.duplicate(true),
		"quests":state_store.quest_states.duplicate(true),
		"relationships":state_store.social.relationships.duplicate(true),
		"marriage":state_store.social.marriage.duplicate(true),
		"child":state_store.social.child.duplicate(true),
		"last_talk_days":{},
	}


func _load_player_context(state_store: Node, context: Dictionary) -> void:
	state_store.farm.load_data(Dictionary(context.get("farm", {})))
	state_store.inventory = Dictionary(context.get("inventory", {})).duplicate(true)
	state_store.coins = maxi(0, int(context.get("coins", 500)))
	state_store.tools.load_data(Dictionary(context.get("tools", {})))
	state_store.economy.load_data(Dictionary(context.get("economy", {})))
	state_store.lifetime_stats = Dictionary(context.get("lifetime_stats", {})).duplicate(true)
	state_store.eldritch.load_data(Dictionary(context.get("eldritch", {})))
	state_store.flags = Dictionary(context.get("flags", {})).duplicate(true)
	state_store.quest_states = Dictionary(context.get("quests", {})).duplicate(true)
	state_store.social.load_data({"relationships":context.get("relationships", {}), "marriage":context.get("marriage", {}), "child":context.get("child", {})})


func _execute_in_player_context(peer_id: int, action: String, payload: Dictionary) -> Dictionary:
	var state_store := get_node_or_null("/root/GameState")
	if state_store == null or not server_players.has(peer_id):
		return {"ok":false, "message":"私人農場尚未就緒"}
	var player_key := String(Dictionary(server_players[peer_id]).get("player_key", ""))
	var context := _ensure_player_context(peer_id)
	if context.is_empty():
		return {"ok":false, "message":"找不到玩家農場身份"}
	var backup := _capture_player_context(state_store)
	_load_player_context(state_store, context)
	var result := _execute_game_state_action(state_store, action, payload)
	var updated := _capture_player_context(state_store)
	updated["last_talk_days"] = Dictionary(context.get("last_talk_days", {})).duplicate(true)
	var player_worlds: Dictionary = Dictionary(shared_world.get("player_worlds", {})).duplicate(true)
	player_worlds[player_key] = updated
	shared_world["player_worlds"] = player_worlds
	_load_player_context(state_store, backup)
	if farm_mode == "competitive":
		result["leaderboard"] = PixelRPGMultiplayerNarrativeSystem.farm_leaderboard(player_worlds, Dictionary(shared_world.get("player_names", {})))
	return result


func _execute_relationship_action(peer_id: int, action: String, payload: Dictionary) -> Dictionary:
	if not server_players.has(peer_id):
		return {"ok":false, "message":"玩家尚未完成連線握手"}
	var npc_id := String(payload.get("npc_id", ""))
	if npc_id not in PixelRPGMultiplayerNarrativeSystem.ROMANCE_CANDIDATES and action != "family_event":
		return {"ok":false, "message":"這名角色不是戀愛候選人"}
	var player_state: Dictionary = server_players[peer_id]
	var player_key := String(player_state.get("player_key", ""))
	var player_worlds: Dictionary = Dictionary(shared_world.get("player_worlds", {})).duplicate(true)
	var context := _ensure_player_context(peer_id)
	var relationships: Dictionary = Dictionary(context.get("relationships", {})).duplicate(true)
	var relationship: Dictionary = Dictionary(relationships.get(npc_id, {"friendship":0,"romance":0,"dating":false,"events_seen":[]})).duplicate(true)
	var result: Dictionary
	match action:
		"talk":
			var state_store := get_node_or_null("/root/GameState")
			var absolute_day := int(state_store.calendar.absolute_day()) if state_store != null else 1
			var last_days: Dictionary = Dictionary(context.get("last_talk_days", {})).duplicate(true)
			if int(last_days.get(npc_id, -1)) == absolute_day:
				result = {"ok":true, "message":"今天已和%s聊過；關係進度不會重複增加" % npc_id, "hearts":clampi(int(relationship.get("friendship", 0)) / 250, 0, 10)}
			else:
				relationship["friendship"] = clampi(int(relationship.get("friendship", 0)) + 25, 0, 2500)
				last_days[npc_id] = absolute_day
				context["last_talk_days"] = last_days
				result = {"ok":true, "message":"與%s交談，好感 %d♥" % [npc_id, int(relationship.friendship) / 250], "hearts":clampi(int(relationship.friendship) / 250, 0, 10)}
		"court_npc":
			if int(relationship.get("friendship", 0)) < 1500:
				return {"ok":false, "message":"需要 6 心才能開始交往"}
			relationship["dating"] = true
			result = {"ok":true, "message":"你正式加入了%s的追求線" % npc_id}
		"propose_npc":
			var claims: Dictionary = Dictionary(shared_world.get("romance_claims", {})).duplicate(true)
			var verdict := PixelRPGMultiplayerNarrativeSystem.proposal_verdict(player_key, npc_id, player_worlds, claims, relationship_mode == "competitive")
			if not bool(verdict.get("ok", false)):
				return verdict
			var state_store := get_node_or_null("/root/GameState")
			var absolute_day := int(state_store.calendar.absolute_day()) if state_store != null else 1
			context["marriage"] = {"spouse_id":npc_id,"married_absolute_day":absolute_day,"family_talk_seen":false}
			if relationship_mode == "competitive":
				claims[npc_id] = player_key
				shared_world["romance_claims"] = claims
			result = verdict
		"family_event":
			var marriage: Dictionary = Dictionary(context.get("marriage", {})).duplicate(true)
			var state_store := get_node_or_null("/root/GameState")
			var absolute_day := int(state_store.calendar.absolute_day()) if state_store != null else 1
			if String(marriage.get("spouse_id", "")).is_empty():
				return {"ok":false,"message":"需要先結婚"}
			if not bool(marriage.get("family_talk_seen", false)) and absolute_day - int(marriage.get("married_absolute_day", absolute_day)) >= 30:
				marriage["family_talk_seen"] = true
				context["marriage"] = marriage
				result = {"ok":true,"message":"你們談過未來，決定迎接新的家人"}
			elif bool(marriage.get("family_talk_seen", false)) and not bool(Dictionary(context.get("child", {})).get("exists", false)) and absolute_day - int(marriage.get("married_absolute_day", absolute_day)) >= 60:
				context["child"] = {"exists":true,"name":"小鐘","born_absolute_day":absolute_day,"stage":"baby"}
				result = {"ok":true,"message":"小鐘來到了這個家"}
			else:
				return {"ok":false,"message":"家庭事件尚未到達日期條件"}
	relationships[npc_id] = relationship
	context["relationships"] = relationships
	player_worlds[player_key] = context
	shared_world["player_worlds"] = player_worlds
	var board := PixelRPGMultiplayerNarrativeSystem.romance_board(player_worlds, Dictionary(shared_world.get("player_names", {})), npc_id) if not npc_id.is_empty() else []
	result["romance_board"] = board
	if relationship_mode == "competitive" and board.size() > 1:
		result["message"] = "%s｜目前第 %d／%d 名" % [result.get("message", "關係更新"), _rank_for_player(board, player_key), board.size()]
	return result


func _rank_for_player(board: Array[Dictionary], player_key: String) -> int:
	for entry: Dictionary in board:
		if String(entry.get("player_key", "")) == player_key:
			return int(entry.get("rank", 0))
	return 0


func _world_view_for_peer(peer_id: int) -> Dictionary:
	var view := shared_world.duplicate(true)
	var context := _ensure_player_context(peer_id)
	if not context.is_empty():
		if farm_mode != "shared":
			for key in ["farm", "inventory", "coins", "tools", "economy", "lifetime_stats", "eldritch", "flags", "quests"]:
				view[key] = context.get(key, view.get(key))
		view["relationships"] = context.get("relationships", {})
		view["marriage"] = context.get("marriage", {})
		view["child"] = context.get("child", {})
	var player_names: Dictionary = shared_world.get("player_names", {})
	var romance_boards: Dictionary = {}
	if relationship_mode == "competitive":
		for npc_id: String in PixelRPGMultiplayerNarrativeSystem.ROMANCE_CANDIDATES:
			romance_boards[npc_id] = PixelRPGMultiplayerNarrativeSystem.romance_board(Dictionary(shared_world.get("player_worlds", {})), player_names, npc_id)
	view["multiplayer"] = {
		"local_player_key":String(Dictionary(server_players.get(peer_id, {})).get("player_key", "")),
		"player_count":server_players.size(),
		"farm_mode":farm_mode,
		"relationship_mode":relationship_mode,
		"story_variant":shared_world.get("story_variant", {}),
		"farm_leaderboard":PixelRPGMultiplayerNarrativeSystem.farm_leaderboard(Dictionary(shared_world.get("player_worlds", {})), player_names) if farm_mode == "competitive" else [],
		"romance_boards":romance_boards,
		"romance_claims":shared_world.get("romance_claims", {}),
	}
	return view


func _refresh_multiplayer_story() -> void:
	if role != Role.SERVER:
		return
	var variant := PixelRPGMultiplayerNarrativeSystem.story_variant(maxi(1, server_players.size()), farm_mode, relationship_mode)
	var previous: Dictionary = shared_world.get("story_variant", {})
	if String(previous.get("id", "")) != String(variant.get("id", "")) or int(previous.get("player_count", 0)) != int(variant.get("player_count", 0)):
		var events: Array = Array(shared_world.get("narrative_events", [])).duplicate(true)
		events.append({"at_unix":int(Time.get_unix_time_from_system()), "variant_id":variant.id, "player_count":variant.player_count, "text":variant.intro})
		while events.size() > 64:
			events.pop_front()
		shared_world["narrative_events"] = events
	shared_world["story_variant"] = variant
	shared_world["multiplayer_rules"] = {"farm_mode":farm_mode,"relationship_mode":relationship_mode}


func _save_server_world() -> bool:
	if role != Role.SERVER or shared_world.is_empty():
		return false
	var absolute_directory := ProjectSettings.globalize_path("user://pixelrpg_servers")
	DirAccess.make_dir_recursive_absolute(absolute_directory)
	var path := ProjectSettings.globalize_path(server_world_path())
	var temporary_path := "%s.tmp" % path
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(shared_world, "  ") + "\n")
	file.close()
	var backup_path := "%s.bak" % path
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, backup_path)
	return DirAccess.rename_absolute(temporary_path, path) == OK


func _new_player_state(peer_id: int, player_name: String, player_key: String) -> Dictionary:
	var offset := float((peer_id % 5) * 18)
	return {"peer_id": peer_id, "player_key":player_key, "name": player_name, "position": [320.0 + offset, 205.0], "input": [0.0, 0.0], "facing": [0.0, 1.0], "map": "mistfall_farm"}


func _emit_roster() -> void:
	var roster: Array[Dictionary] = []
	for peer_id: int in server_players:
		var state: Dictionary = server_players[peer_id]
		roster.append({"peer_id": peer_id, "name": String(state.get("name", "旅人"))})
	roster.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.peer_id) < int(b.peer_id))
	roster_changed.emit(roster)


func _emit_roster_from_snapshot() -> void:
	var roster: Array[Dictionary] = []
	for peer_id: Variant in latest_snapshot:
		var state: Dictionary = latest_snapshot[peer_id]
		roster.append({"peer_id": int(peer_id), "name": String(state.get("name", "旅人"))})
	roster.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.peer_id) < int(b.peer_id))
	roster_changed.emit(roster)


func _disconnect_later(peer_id: int) -> void:
	await get_tree().create_timer(0.15, true).timeout
	if role == Role.SERVER and peer != null:
		peer.disconnect_peer(peer_id)


func _can_send_to_peer(peer_id: int) -> bool:
	if role != Role.SERVER or peer == null or peer_id <= 1:
		return false
	var packet_peer := peer.get_peer(peer_id)
	return packet_peer != null and packet_peer.get_state() == ENetPacketPeer.STATE_CONNECTED


func _local_facing() -> Vector2:
	if is_instance_valid(local_player_node) and "facing" in local_player_node:
		return Vector2(local_player_node.facing)
	return Vector2.DOWN


func _current_map() -> String:
	var state_store := get_node_or_null("/root/GameState")
	return String(state_store.current_map_id) if state_store != null else "mistfall_farm"


func _array_to_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


func _sanitize_name(value: String, fallback: String, max_length: int) -> String:
	var safe := value.replace("\n", " ").replace("\r", " ").replace("\t", " ").strip_edges().substr(0, max_length)
	return fallback if safe.is_empty() else safe


func _sanitize_world_name(value: String) -> String:
	var regex := RegEx.new()
	regex.compile("[^A-Za-z0-9_-]")
	var safe := regex.sub(value.strip_edges(), "_", true).substr(0, 32)
	return "default" if safe.is_empty() else safe


func _load_or_create_client_id() -> String:
	const client_id_path := "user://pixelrpg_client_id.txt"
	if FileAccess.file_exists(client_id_path):
		var stored := FileAccess.get_file_as_string(client_id_path).strip_edges().to_lower()
		if _is_valid_player_key(stored):
			return stored
	var generated := Crypto.new().generate_random_bytes(16).hex_encode()
	var file := FileAccess.open(client_id_path, FileAccess.WRITE)
	if file != null:
		file.store_string(generated + "\n")
	return generated


func _is_valid_player_key(value: String) -> bool:
	if value.length() != 32:
		return false
	var regex := RegEx.new()
	regex.compile("^[0-9a-f]{32}$")
	return regex.search(value) != null
