extends Node

const MIX_RATE := 22050
const LOOP_SECONDS := 8.0

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var music_cache: Dictionary = {}
var last_music_key := ""
var refresh_timer := 0.0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -9.0
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -5.0
	add_child(sfx_player)
	_refresh_music(true)
	EventBus.actor_damaged.connect(_on_actor_damaged)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.farm_changed.connect(_on_farm_changed)
	EventBus.day_started.connect(_on_day_started)


func _exit_tree() -> void:
	shutdown_audio()


func shutdown_audio() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	if is_instance_valid(sfx_player):
		sfx_player.stop()
		sfx_player.stream = null
	music_cache.clear()


func _process(delta: float) -> void:
	refresh_timer -= delta
	if refresh_timer > 0.0:
		return
	refresh_timer = 0.5
	_refresh_music(false)
	var master := clampf(float(GameState.settings.get("master_volume", 0.8)), 0.0, 1.0)
	music_player.volume_db = linear_to_db(maxf(master * 0.36, 0.0001))
	sfx_player.volume_db = linear_to_db(maxf(master * 0.62, 0.0001))


func _refresh_music(force: bool) -> void:
	var key := "%s:%d" % [GameState.current_map_id, GameState.calendar.season_index]
	if not force and key == last_music_key:
		return
	last_music_key = key
	if not music_cache.has(key):
		music_cache[key] = _build_music_loop(_current_notes())
	music_player.stream = music_cache[key]
	music_player.play()


func _current_notes() -> Array[int]:
	var season_shift: int = int([0, 2, -2, -5][GameState.calendar.season_index])
	var base: Array[int]
	if GameState.current_map_id == &"mistfall_depths":
		base = [45, 48, 52, 50, 43, 47, 50, 48]
	elif GameState.current_map_id == &"mistfall_village":
		base = [60, 64, 67, 69, 67, 64, 62, 64]
	else:
		base = [57, 60, 64, 62, 60, 64, 67, 64]
	for index in range(base.size()):
		base[index] += season_shift
	return base


func _build_music_loop(notes: Array[int]) -> AudioStreamWAV:
	var frame_count := int(MIX_RATE * LOOP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in range(frame_count):
		var time := float(frame) / float(MIX_RATE)
		var beat := int(time) % notes.size()
		var frequency := 440.0 * pow(2.0, float(notes[beat] - 69) / 12.0)
		var lead := signf(sin(TAU * frequency * time)) * 0.115
		var bass := sin(TAU * frequency * 0.25 * time) * 0.075
		var envelope := 0.72 + 0.28 * cos(TAU * fmod(time, 1.0))
		var sample := clampi(roundi((lead + bass) * envelope * 32767.0), -32768, 32767)
		bytes[frame * 2] = sample & 0xff
		bytes[frame * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	return stream


func _build_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var frame_count := maxi(1, int(MIX_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in range(frame_count):
		var time := float(frame) / float(MIX_RATE)
		var envelope := 1.0 - float(frame) / float(frame_count)
		var sample := clampi(roundi(sin(TAU * frequency * time) * envelope * 0.32 * 32767.0), -32768, 32767)
		bytes[frame * 2] = sample & 0xff
		bytes[frame * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _play_sfx(frequency: float, duration: float) -> void:
	if not is_instance_valid(sfx_player):
		return
	sfx_player.stream = _build_tone(frequency, duration)
	sfx_player.play()


func _on_actor_damaged(_actor: Node, _amount: int, _remaining: int) -> void:
	_play_sfx(125.0, 0.12)


func _on_enemy_defeated(_enemy_id: StringName, _position: Vector2) -> void:
	_play_sfx(660.0, 0.20)


func _on_farm_changed(action: StringName, _payload: Dictionary) -> void:
	if action in [&"harvested", &"fish_caught", &"dish_cooked"]:
		_play_sfx(880.0, 0.16)


func _on_day_started(_year: int, _season: StringName, _day: int, _weather: String) -> void:
	_play_sfx(523.25, 0.32)
	_refresh_music(false)
