extends SceneTree

class ProbeAvatar:
	extends Node2D
	var facing := Vector2.DOWN

var role := ""
var port := PixelRPGNetworkManager.DEFAULT_PORT
var report_path := ""
var player_name := "Probe"
var expected_clients := 2
var farm_mode_arg := "competitive"
var relationship_mode_arg := "competitive"
var failures: Array[String] = []
var action_results: Array[Dictionary] = []
var network: Node


func _initialize() -> void:
	_parse_arguments()
	call_deferred("_run")


func _parse_arguments() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--probe-role="):
			role = argument.trim_prefix("--probe-role=")
		elif argument.begins_with("--port="):
			port = int(argument.trim_prefix("--port="))
		elif argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")
		elif argument.begins_with("--name="):
			player_name = argument.trim_prefix("--name=")
		elif argument.begins_with("--expected-clients="):
			expected_clients = int(argument.trim_prefix("--expected-clients="))
		elif argument.begins_with("--farm-mode="):
			farm_mode_arg = argument.trim_prefix("--farm-mode=")
		elif argument.begins_with("--relationship-mode="):
			relationship_mode_arg = argument.trim_prefix("--relationship-mode=")


func _run() -> void:
	network = root.get_node("NetworkManager")
	network.action_result_received.connect(_on_action_result)
	if role == "server":
		await _run_server()
	elif role == "client":
		await _run_client()
	else:
		failures.append("Missing --probe-role=server|client")
		_write_report({})
		quit(2)


func _run_server() -> void:
	var result: Dictionary = network.host_server(port, 8, "QA Dedicated", "", true, "qa_%d" % port, farm_mode_arg, relationship_mode_arg)
	if not bool(result.get("ok", false)):
		failures.append(String(result.get("message", "server failed")))
		_write_report(result)
		quit(1)
		return
	var peak_clients := 0
	var story_at_peak: Dictionary = {}
	var deadline := Time.get_ticks_msec() + 15_000
	while Time.get_ticks_msec() < deadline:
		peak_clients = maxi(peak_clients, network.server_players.size())
		if peak_clients >= expected_clients:
			story_at_peak = Dictionary(network.shared_world.get("story_variant", {})).duplicate(true)
			break
		await process_frame
	if peak_clients < expected_clients:
		failures.append("Expected %d clients, peak was %d" % [expected_clients, peak_clients])
	var action_deadline := Time.get_ticks_msec() + 3500
	while Time.get_ticks_msec() < action_deadline:
		peak_clients = maxi(peak_clients, network.server_players.size())
		await process_frame
	network._capture_shared_world()
	var player_worlds: Dictionary = network.shared_world.get("player_worlds", {})
	var private_farms_ok := true
	var shared_plots: Dictionary = Dictionary(network.shared_world.get("farm", {})).get("plots", {})
	if farm_mode_arg == "shared":
		if shared_plots.is_empty():
			failures.append("Shared farm action was not integrated into the common farm")
	else:
		private_farms_ok = player_worlds.size() == expected_clients
		for context: Dictionary in player_worlds.values():
			private_farms_ok = private_farms_ok and not Dictionary(Dictionary(context.get("farm", {})).get("plots", {})).is_empty()
		if not private_farms_ok:
			failures.append("Private farms were not isolated per player")
	var story: Dictionary = story_at_peak
	if String(story.get("id", "")) != "twin_bell_pact" or int(story.get("player_count", 0)) != 2:
		failures.append("Two-player adaptive story branch was not selected")
	var player_names: Dictionary = network.shared_world.get("player_names", {})
	var romance_board := PixelRPGMultiplayerNarrativeSystem.romance_board(player_worlds, player_names, "mira")
	if romance_board.size() != 2:
		failures.append("Per-player relationship contexts did not include both players")
	var verdict_worlds := player_worlds.duplicate(true)
	var keys := verdict_worlds.keys()
	var tie_blocked := false
	var leader_allowed := false
	if keys.size() == 2:
		for player_key: String in keys:
			var context: Dictionary = verdict_worlds[player_key]
			var relationships: Dictionary = Dictionary(context.get("relationships", {})).duplicate(true)
			relationships["mira"] = {"friendship":2500,"romance":0,"dating":true,"events_seen":[]}
			context["relationships"] = relationships
			verdict_worlds[player_key] = context
		var tie_verdict := PixelRPGMultiplayerNarrativeSystem.proposal_verdict(String(keys[0]), "mira", verdict_worlds, {}, true)
		tie_blocked = not bool(tie_verdict.get("ok", false)) and "平手" in String(tie_verdict.get("message", ""))
		var leader_context: Dictionary = verdict_worlds[keys[0]]
		var leader_relationships: Dictionary = Dictionary(leader_context.get("relationships", {})).duplicate(true)
		var leader_mira: Dictionary = Dictionary(leader_relationships["mira"]).duplicate(true)
		leader_mira["friendship"] = 2501
		leader_relationships["mira"] = leader_mira
		leader_context["relationships"] = leader_relationships
		verdict_worlds[keys[0]] = leader_context
		leader_allowed = bool(PixelRPGMultiplayerNarrativeSystem.proposal_verdict(String(keys[0]), "mira", verdict_worlds, {}, true).get("ok", false))
	if relationship_mode_arg == "competitive" and (not tie_blocked or not leader_allowed):
		failures.append("Romance competition tie/leader proposal rules failed")
	var world_path := ProjectSettings.globalize_path(network.server_world_path())
	network.stop(false)
	if not FileAccess.file_exists(world_path):
		failures.append("Dedicated server world save was not written")
	_write_report({"peak_clients": peak_clients, "world_path": network.server_world_path(), "farm_mode":farm_mode_arg, "relationship_mode":relationship_mode_arg, "shared_plots":shared_plots.size(), "private_player_worlds": player_worlds.size(), "private_farms_ok":private_farms_ok, "story_variant": story, "romance_suitors": romance_board.size(), "tie_blocked":tie_blocked, "leader_allowed":leader_allowed, "protocol": PixelRPGNetworkManager.PROTOCOL_VERSION})
	quit(0 if failures.is_empty() else 1)


func _run_client() -> void:
	var avatar := ProbeAvatar.new()
	avatar.global_position = Vector2(320, 205)
	root.add_child(avatar)
	network.set_local_player_node(avatar)
	var result: Dictionary = network.join_server("127.0.0.1", port, player_name)
	if not bool(result.get("ok", false)):
		failures.append(String(result.get("message", "client failed")))
		_write_report(result)
		quit(1)
		return
	var peak_snapshot_players := 0
	var connect_deadline := Time.get_ticks_msec() + 10_000
	while not network.handshake_complete and Time.get_ticks_msec() < connect_deadline:
		peak_snapshot_players = maxi(peak_snapshot_players, network.latest_snapshot.size())
		await process_frame
	if not network.handshake_complete:
		failures.append("Handshake did not complete")
	else:
		if player_name.ends_with("A"):
			Input.action_press("move_right")
		else:
			Input.action_press("move_down")
		var movement_deadline := Time.get_ticks_msec() + 1100
		while Time.get_ticks_msec() < movement_deadline:
			peak_snapshot_players = maxi(peak_snapshot_players, network.latest_snapshot.size())
			await process_frame
		Input.action_release("move_right")
		Input.action_release("move_down")
		network.request_world_action("farm_plot", {"x": 0, "y": 0, "seed_id": "spring_turnip"})
		var action_gap := Time.get_ticks_msec() + 240
		while Time.get_ticks_msec() < action_gap:
			peak_snapshot_players = maxi(peak_snapshot_players, network.latest_snapshot.size())
			await process_frame
		network.request_world_action("talk", {"npc_id":"mira"})
		var sync_deadline := Time.get_ticks_msec() + 1200
		while Time.get_ticks_msec() < sync_deadline:
			peak_snapshot_players = maxi(peak_snapshot_players, network.latest_snapshot.size())
			await process_frame
	peak_snapshot_players = maxi(peak_snapshot_players, network.latest_snapshot.size())
	var own_id: int = network.multiplayer.get_unique_id()
	var own_state: Dictionary = network.latest_snapshot.get(own_id, {})
	var position_data: Array = own_state.get("position", [320.0, 205.0])
	var moved := position_data.size() >= 2 and Vector2(float(position_data[0]), float(position_data[1])).distance_to(Vector2(320.0 + float((own_id % 5) * 18), 205.0)) > 20.0
	if not moved:
		failures.append("Server-authoritative player position did not move")
	if peak_snapshot_players < expected_clients:
		failures.append("Client did not receive both player snapshots")
	if action_results.is_empty() or not bool(action_results[-1].get("ok", false)):
		failures.append("Shared world action did not return success")
	var local_world: Dictionary = network.shared_world
	var multiplayer_data: Dictionary = local_world.get("multiplayer", {})
	var own_plots: Dictionary = Dictionary(local_world.get("farm", {})).get("plots", {})
	var client_romance_board: Array = Dictionary(multiplayer_data.get("romance_boards", {})).get("mira", [])
	if String(multiplayer_data.get("farm_mode", "")) != farm_mode_arg or String(multiplayer_data.get("relationship_mode", "")) != relationship_mode_arg or String(Dictionary(multiplayer_data.get("story_variant", {})).get("id", "")) != "twin_bell_pact":
		failures.append("Client did not receive selected world rules and adaptive story")
	if own_plots.is_empty():
		failures.append("Client view did not contain the selected shared/private farm")
	if relationship_mode_arg == "competitive" and client_romance_board.size() < 2:
		failures.append("Client view did not contain romance rivals")
	if relationship_mode_arg == "independent" and not Dictionary(local_world.get("relationships", {})).has("mira"):
		failures.append("Client view did not contain its independent relationship progress")
	var details := {"peer_id": own_id, "peak_snapshot_players": peak_snapshot_players, "final_snapshot_players": network.latest_snapshot.size(), "moved": moved, "own_private_plots":own_plots.size(), "romance_suitors":client_romance_board.size(), "world_rules":multiplayer_data, "action_results": action_results, "protocol": PixelRPGNetworkManager.PROTOCOL_VERSION}
	network.stop(false)
	_write_report(details)
	quit(0 if failures.is_empty() else 1)


func _on_action_result(_action: String, result: Dictionary) -> void:
	action_results.append(result.duplicate(true))


func _write_report(details: Dictionary) -> void:
	var report := {"role": role, "passed": failures.is_empty(), "failures": failures, "details": details, "generated_at": Time.get_datetime_string_from_system(true)}
	if report_path.is_empty():
		print(JSON.stringify(report))
		return
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ") + "\n")
	print("PixelRPG multiplayer probe %s: %s" % [role, "PASS" if failures.is_empty() else "FAIL"])
