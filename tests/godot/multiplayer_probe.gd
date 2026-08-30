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
var probe_mode := "world"
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
		elif argument.begins_with("--probe-mode="):
			probe_mode = argument.trim_prefix("--probe-mode=")


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
	# Every scenario uses the shipping maximum so the 16-client capacity path is
	# exercised by the same server implementation used by the release build.
	var result: Dictionary = network.host_server(port, PixelRPGNetworkManager.MAX_CLIENTS_LIMIT, "QA Dedicated", "", true, "qa_%d" % port, farm_mode_arg, relationship_mode_arg)
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
	if probe_mode == "story":
		var observation_deadline := Time.get_ticks_msec() + 5000
		while Time.get_ticks_msec() < observation_deadline:
			peak_clients = maxi(peak_clients, network.server_players.size())
			await process_frame
		network._capture_shared_world()
		var expected_story := _expected_story_id(expected_clients)
		if String(story_at_peak.get("id", "")) != expected_story or int(story_at_peak.get("player_count", 0)) != expected_clients:
			failures.append("Expected adaptive story %s for %d players" % [expected_story, expected_clients])
		var story_world_path := ProjectSettings.globalize_path(network.server_world_path())
		network.stop(false)
		if not FileAccess.file_exists(story_world_path):
			failures.append("Story-scaling server world save was not written")
		_write_report({"peak_clients":peak_clients, "world_path":network.server_world_path(), "story_variant":story_at_peak, "protocol":PixelRPGNetworkManager.PROTOCOL_VERSION})
		quit(0 if failures.is_empty() else 1)
		return
	_prepare_automation_test_world()
	var action_deadline := Time.get_ticks_msec() + 3500
	while Time.get_ticks_msec() < action_deadline:
		peak_clients = maxi(peak_clients, network.server_players.size())
		await process_frame
	network._capture_shared_world()
	var player_worlds: Dictionary = network.shared_world.get("player_worlds", {})
	var private_farms_ok := true
	var shared_plots: Dictionary = Dictionary(network.shared_world.get("farm", {})).get("plots", {})
	var shared_automation: Dictionary = Dictionary(network.shared_world.get("farm", {})).get("automation_devices", {})
	var automation_isolation_ok := true
	if farm_mode_arg == "shared":
		if shared_plots.is_empty():
			failures.append("Shared farm action was not integrated into the common farm")
		if shared_automation.size() != expected_clients:
			failures.append("Shared automation expected %d devices, got %d" % [expected_clients, shared_automation.size()])
	else:
		private_farms_ok = player_worlds.size() == expected_clients
		for context: Dictionary in player_worlds.values():
			var context_farm: Dictionary = context.get("farm", {})
			private_farms_ok = private_farms_ok and not Dictionary(context_farm.get("plots", {})).is_empty()
			automation_isolation_ok = automation_isolation_ok and Dictionary(context_farm.get("automation_devices", {})).size() == 1
		if not private_farms_ok:
			failures.append("Private farms were not isolated per player")
		if not automation_isolation_ok:
			failures.append("Private automation devices were not isolated per player")
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
	var unique_claim_enforced := relationship_mode_arg != "competitive"
	var claim_persisted := relationship_mode_arg != "competitive"
	var claimed_player_key := ""
	var winning_proposal_result: Dictionary = {}
	var rival_proposal_result: Dictionary = {}
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
		if relationship_mode_arg == "competitive":
			network.shared_world["player_worlds"] = verdict_worlds
			var peer_by_key: Dictionary = {}
			for connected_peer_id: int in network.server_players:
				var connected_state: Dictionary = network.server_players[connected_peer_id]
				peer_by_key[String(connected_state.get("player_key", ""))] = connected_peer_id
			claimed_player_key = String(keys[0])
			var rival_key := String(keys[1])
			winning_proposal_result = network._execute_relationship_action(int(peer_by_key.get(claimed_player_key, 0)), "propose_npc", {"npc_id":"mira"})
			rival_proposal_result = network._execute_relationship_action(int(peer_by_key.get(rival_key, 0)), "propose_npc", {"npc_id":"mira"})
			unique_claim_enforced = bool(winning_proposal_result.get("ok", false)) and not bool(rival_proposal_result.get("ok", false)) and String(Dictionary(network.shared_world.get("romance_claims", {})).get("mira", "")) == claimed_player_key and "婚約" in String(rival_proposal_result.get("message", ""))
	if relationship_mode_arg == "competitive" and (not tie_blocked or not leader_allowed):
		failures.append("Romance competition tie/leader proposal rules failed")
	if relationship_mode_arg == "competitive" and not unique_claim_enforced:
		failures.append("Server did not enforce a unique competitive romance claim")
	network._capture_shared_world()
	network._broadcast_world()
	var final_delivery_deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < final_delivery_deadline:
		await process_frame
	var world_path := ProjectSettings.globalize_path(network.server_world_path())
	network.stop(false)
	if not FileAccess.file_exists(world_path):
		failures.append("Dedicated server world save was not written")
	else:
		var saved_world: Variant = JSON.parse_string(FileAccess.get_file_as_string(world_path))
		if saved_world is Dictionary:
			claim_persisted = relationship_mode_arg != "competitive" or String(Dictionary(Dictionary(saved_world).get("romance_claims", {})).get("mira", "")) == claimed_player_key
			if farm_mode_arg == "shared":
				var saved_devices: Dictionary = Dictionary(Dictionary(saved_world).get("farm", {})).get("automation_devices", {})
				if saved_devices.size() != expected_clients:
					failures.append("Shared automation devices were not persisted in the server world")
			else:
				var saved_player_worlds: Dictionary = Dictionary(saved_world).get("player_worlds", {})
				for saved_context: Dictionary in saved_player_worlds.values():
					var saved_context_devices: Dictionary = Dictionary(Dictionary(saved_context.get("farm", {})).get("automation_devices", {}))
					if saved_context_devices.size() != 1:
						failures.append("Private automation isolation was not persisted in the server world")
						break
	if relationship_mode_arg == "competitive" and not claim_persisted:
		failures.append("Competitive romance claim was not persisted in the server world")
	_write_report({"peak_clients": peak_clients, "world_path": network.server_world_path(), "farm_mode":farm_mode_arg, "relationship_mode":relationship_mode_arg, "shared_plots":shared_plots.size(), "shared_automation_devices":shared_automation.size(), "private_player_worlds": player_worlds.size(), "private_farms_ok":private_farms_ok, "automation_isolation_ok":automation_isolation_ok, "story_variant": story, "romance_suitors": romance_board.size(), "tie_blocked":tie_blocked, "leader_allowed":leader_allowed, "winning_proposal":winning_proposal_result, "rival_proposal":rival_proposal_result, "romance_claims":network.shared_world.get("romance_claims", {}), "unique_claim_enforced":unique_claim_enforced, "claim_persisted":claim_persisted, "protocol": PixelRPGNetworkManager.PROTOCOL_VERSION})
	quit(0 if failures.is_empty() else 1)


func _prepare_automation_test_world() -> void:
	var materials := {"copper_ore":999, "stone":999, "wood":999, "iron_ore":999, "gold_ore":999, "glass":999, "mist_shard":999}
	if farm_mode_arg == "shared":
		var state_store := root.get_node("GameState")
		state_store.farm.rank = 10
		state_store.coins = 100_000
		for item_id: String in materials:
			state_store.inventory[item_id] = materials[item_id]
		network._capture_shared_world()
	else:
		for peer_id: int in network.server_players:
			var context: Dictionary = network._ensure_player_context(peer_id)
			var context_farm: Dictionary = Dictionary(context.get("farm", {})).duplicate(true)
			context_farm["rank"] = 10
			context["farm"] = context_farm
			context["coins"] = 100_000
			var context_inventory: Dictionary = Dictionary(context.get("inventory", {})).duplicate(true)
			for item_id: String in materials:
				context_inventory[item_id] = materials[item_id]
			context["inventory"] = context_inventory
			var player_key := String(Dictionary(network.server_players[peer_id]).get("player_key", ""))
			var player_worlds: Dictionary = Dictionary(network.shared_world.get("player_worlds", {})).duplicate(true)
			player_worlds[player_key] = context
			network.shared_world["player_worlds"] = player_worlds
	network._broadcast_world()


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
		var connected_peer_id: int = network.multiplayer.get_unique_id()
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
		if probe_mode == "story":
			var story_sync_deadline := Time.get_ticks_msec() + 1400
			while Time.get_ticks_msec() < story_sync_deadline:
				peak_snapshot_players = maxi(peak_snapshot_players, network.latest_snapshot.size())
				await process_frame
			await _finish_story_client(avatar, peak_snapshot_players, connected_peer_id)
			return
		network.request_world_action("farm_plot", {"x": 0, "y": 0, "seed_id": "spring_turnip"})
		# Leave ample room above the server's 150 ms abuse throttle. ENet may
		# coalesce reliable packets while several headless peers start at once.
		var action_gap := Time.get_ticks_msec() + 500
		while Time.get_ticks_msec() < action_gap:
			peak_snapshot_players = maxi(peak_snapshot_players, network.latest_snapshot.size())
			await process_frame
		var automation_x := 0 if farm_mode_arg != "shared" or player_name.ends_with("A") else 1
		var automation_device := "bell_generator" if farm_mode_arg != "shared" or player_name.ends_with("A") else "copper_conveyor"
		network.request_world_action("automation_place", {"x":automation_x, "y":0, "device_id":automation_device, "config":{"priority":25 if player_name.ends_with("A") else 75}})
		var automation_gap := Time.get_ticks_msec() + 500
		while Time.get_ticks_msec() < automation_gap:
			peak_snapshot_players = maxi(peak_snapshot_players, network.latest_snapshot.size())
			await process_frame
		network.request_world_action("talk", {"npc_id":"mira"})
		var sync_deadline := Time.get_ticks_msec() + 1200
		while Time.get_ticks_msec() < sync_deadline:
			peak_snapshot_players = maxi(peak_snapshot_players, network.latest_snapshot.size())
			await process_frame
		# Keep the real peers connected while the server verifies competitive
		# proposal ownership and persists the unique romance claim.
		var server_verification_deadline := Time.get_ticks_msec() + 1200
		while Time.get_ticks_msec() < server_verification_deadline:
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
	var automation_action_ok := false
	for action_result: Dictionary in action_results:
		if String(action_result.get("requested_action", "")) == "automation_place" and bool(action_result.get("ok", false)):
			automation_action_ok = true
	if not automation_action_ok:
		failures.append("Automation placement did not return success")
	var local_world: Dictionary = network.shared_world
	var multiplayer_data: Dictionary = local_world.get("multiplayer", {})
	var own_plots: Dictionary = Dictionary(local_world.get("farm", {})).get("plots", {})
	var own_automation: Dictionary = Dictionary(local_world.get("farm", {})).get("automation_devices", {})
	var client_romance_board: Array = Dictionary(multiplayer_data.get("romance_boards", {})).get("mira", [])
	var twin_story_seen := _world_observed_story(local_world, "twin_bell_pact", 2)
	if String(multiplayer_data.get("farm_mode", "")) != farm_mode_arg or String(multiplayer_data.get("relationship_mode", "")) != relationship_mode_arg or not twin_story_seen:
		failures.append("Client did not receive selected world rules and adaptive story")
	if own_plots.is_empty():
		failures.append("Client view did not contain the selected shared/private farm")
	var expected_automation_devices := expected_clients if farm_mode_arg == "shared" else 1
	if own_automation.size() != expected_automation_devices:
		failures.append("Client view expected %d automation devices, got %d" % [expected_automation_devices, own_automation.size()])
	if relationship_mode_arg == "competitive" and client_romance_board.size() < 2:
		failures.append("Client view did not contain romance rivals")
	if relationship_mode_arg == "independent" and not Dictionary(local_world.get("relationships", {})).has("mira"):
		failures.append("Client view did not contain its independent relationship progress")
	var details := {"peer_id": own_id, "peak_snapshot_players": peak_snapshot_players, "final_snapshot_players": network.latest_snapshot.size(), "moved": moved, "own_private_plots":own_plots.size(), "automation_devices":own_automation.size(), "automation_action_ok":automation_action_ok, "romance_suitors":client_romance_board.size(), "twin_story_seen":twin_story_seen, "world_rules":multiplayer_data, "action_results": action_results, "protocol": PixelRPGNetworkManager.PROTOCOL_VERSION}
	await _write_client_report_and_wait(details)


func _finish_story_client(avatar: Node2D, peak_snapshot_players: int, own_id: int) -> void:
	var own_state: Dictionary = network.latest_snapshot.get(own_id, {})
	var position_data: Array = own_state.get("position", [avatar.global_position.x, avatar.global_position.y])
	var expected_spawn := Vector2(320.0 + float((own_id % 5) * 18), 205.0)
	var moved := position_data.size() >= 2 and Vector2(float(position_data[0]), float(position_data[1])).distance_to(expected_spawn) > 20.0
	if not moved:
		failures.append("Story-scaling client movement was not authoritative")
	if peak_snapshot_players < expected_clients:
		failures.append("Story-scaling client saw %d/%d player snapshots" % [peak_snapshot_players, expected_clients])
	var multiplayer_data: Dictionary = network.shared_world.get("multiplayer", {})
	var story: Dictionary = multiplayer_data.get("story_variant", {})
	var expected_story := _expected_story_id(expected_clients)
	var expected_story_seen := _world_observed_story(network.shared_world, expected_story, expected_clients)
	if not expected_story_seen:
		failures.append("Client expected adaptive story %s for %d players" % [expected_story, expected_clients])
	var details := {"peer_id":own_id, "peak_snapshot_players":peak_snapshot_players, "moved":moved, "expected_story_id":expected_story, "expected_story_seen":expected_story_seen, "story_variant":story, "protocol":PixelRPGNetworkManager.PROTOCOL_VERSION}
	await _write_client_report_and_wait(details)


func _expected_story_id(player_count: int) -> String:
	if player_count <= 1:
		return "solo_bell"
	if player_count == 2:
		return "twin_bell_pact"
	if player_count <= 4:
		return "four_season_chorus"
	return "mistfall_council"


func _world_observed_story(world: Dictionary, expected_id: String, expected_count: int) -> bool:
	var current: Dictionary = Dictionary(world.get("multiplayer", {})).get("story_variant", world.get("story_variant", {}))
	if String(current.get("id", "")) == expected_id and int(current.get("player_count", 0)) == expected_count:
		return true
	for event_value: Variant in Array(world.get("narrative_events", [])):
		if event_value is Dictionary:
			var event: Dictionary = event_value
			if String(event.get("variant_id", "")) == expected_id and int(event.get("player_count", 0)) == expected_count:
				return true
	return false


func _write_client_report_and_wait(details: Dictionary) -> void:
	var shutdown_deadline := Time.get_ticks_msec() + 7000
	while network.role == PixelRPGNetworkManager.Role.CLIENT and Time.get_ticks_msec() < shutdown_deadline:
		await process_frame
	if network.role == PixelRPGNetworkManager.Role.CLIENT:
		failures.append("Server did not complete coordinated test shutdown")
		network.stop(false)
	_write_report(details)
	quit(0 if failures.is_empty() else 1)


func _on_action_result(action: String, result: Dictionary) -> void:
	var recorded := result.duplicate(true)
	recorded["requested_action"] = action
	action_results.append(recorded)


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
