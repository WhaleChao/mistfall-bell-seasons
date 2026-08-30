class_name PixelRPGPlayer
extends CharacterBody2D

enum State { MOVE, ATTACK, DODGE, HURT, DEAD }

const MOVE_SPEED := 118.0
const DODGE_SPEED := 255.0
const DODGE_DURATION := 0.24
const DODGE_COOLDOWN := 0.42
const ATTACK_DURATIONS := [0.24, 0.22, 0.34]
const ATTACK_DAMAGE_MULTIPLIERS := [1.0, 1.15, 1.5]

var max_health := 100
var health := 100
var attack_power := 16
var state := State.MOVE
var facing := Vector2.DOWN
var dodge_direction := Vector2.DOWN
var state_timer := 0.0
var dodge_cooldown_timer := 0.0
var skill_cooldown_timer := 0.0
var combo_stage := 0
var combo_queued := false
var attack_has_landed := false
var invulnerable := false
var hurt_flash_timer := 0.0
var skill_flash_timer := 0.0
var visual_sprite: Sprite2D
var visual_region: AtlasTexture
var visual_frame := -1
var visual_direction_row := -1


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4 | 16
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 7.0
	shape.height = 19.0
	collision.shape = shape
	collision.position = Vector2(0, 4)
	add_child(collision)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 640
	camera.limit_bottom = 360
	add_child(camera)
	_create_visual_sprite()
	restore_from_game_state()
	queue_redraw()
	if is_instance_valid(visual_sprite):
		visual_sprite.modulate = Color(1, 1, 1, 0.55 if state == State.DODGE else 1.0)
		if hurt_flash_timer > 0.0:
			visual_sprite.modulate = Color(1.4, 1.4, 1.4, visual_sprite.modulate.a)


func _physics_process(delta: float) -> void:
	dodge_cooldown_timer = maxf(0.0, dodge_cooldown_timer - delta)
	skill_cooldown_timer = maxf(0.0, skill_cooldown_timer - delta)
	hurt_flash_timer = maxf(0.0, hurt_flash_timer - delta)
	skill_flash_timer = maxf(0.0, skill_flash_timer - delta)
	queue_redraw()
	_update_visual()

	if state == State.DEAD:
		velocity = Vector2.ZERO
		return

	if Input.is_action_just_pressed("quick_save"):
		SaveManager.save_quick()
	if Input.is_action_just_pressed("quick_load"):
		SaveManager.load_quick()

	match state:
		State.MOVE:
			_process_move(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DODGE:
			_process_dodge(delta)
		State.HURT:
			_process_hurt(delta)

	move_and_slide()
	global_position.x = clampf(global_position.x, 30.0, 610.0)
	global_position.y = clampf(global_position.y, 42.0, 330.0)


func _process_move(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction += Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = direction.limit_length(1.0)
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
		velocity = direction * MOVE_SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * get_physics_process_delta_time())

	if Input.is_action_just_pressed("attack"):
		_start_attack(0)
	elif Input.is_action_just_pressed("dodge") and dodge_cooldown_timer <= 0.0:
		_start_dodge(direction)
	elif Input.is_action_just_pressed("active_skill") and skill_cooldown_timer <= 0.0:
		_use_active_skill()


func _process_attack(delta: float) -> void:
	state_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 1000.0 * delta)
	var duration: float = ATTACK_DURATIONS[combo_stage]
	if not attack_has_landed and state_timer <= duration * 0.64:
		attack_has_landed = true
		_perform_melee_hit()
	if Input.is_action_just_pressed("attack") and state_timer <= duration * 0.55:
		combo_queued = true
	if Input.is_action_just_pressed("dodge") and dodge_cooldown_timer <= 0.0 and state_timer <= duration * 0.35:
		_start_dodge(Vector2.ZERO)
		return
	if state_timer <= 0.0:
		if combo_queued and combo_stage < ATTACK_DURATIONS.size() - 1:
			_start_attack(combo_stage + 1)
		else:
			combo_stage = 0
			combo_queued = false
			state = State.MOVE


func _process_dodge(delta: float) -> void:
	state_timer -= delta
	velocity = dodge_direction * DODGE_SPEED
	if state_timer <= 0.0:
		invulnerable = false
		state = State.MOVE


func _process_hurt(delta: float) -> void:
	state_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 480.0 * delta)
	if state_timer <= 0.0:
		state = State.MOVE


func _start_attack(stage: int) -> void:
	state = State.ATTACK
	combo_stage = clampi(stage, 0, ATTACK_DURATIONS.size() - 1)
	state_timer = ATTACK_DURATIONS[combo_stage]
	combo_queued = false
	attack_has_landed = false


func _start_dodge(direction: Vector2) -> void:
	state = State.DODGE
	state_timer = DODGE_DURATION
	dodge_cooldown_timer = DODGE_COOLDOWN
	dodge_direction = direction.normalized() if direction.length_squared() > 0.01 else facing.normalized()
	invulnerable = true


func _perform_melee_hit() -> void:
	var radius := 22.0 + float(combo_stage) * 3.0
	var center := global_position + facing.normalized() * 24.0
	var hits := _query_enemies(center, radius)
	for enemy: Node in hits:
		var damage := roundi(float(attack_power) * ATTACK_DAMAGE_MULTIPLIERS[combo_stage])
		enemy.take_damage(damage, self)
	if not hits.is_empty():
		EventBus.request_hit_stop(0.035 + combo_stage * 0.012)


func _use_active_skill() -> void:
	skill_cooldown_timer = 4.0
	skill_flash_timer = 0.32
	var hits := _query_enemies(global_position, 74.0)
	for enemy: Node in hits:
		enemy.take_damage(roundi(attack_power * 1.8), self)
	if not hits.is_empty():
		EventBus.request_hit_stop(0.08)
	EventBus.toast("迴旋斬！")


func _query_enemies(center: Vector2, radius: float) -> Array[Node]:
	var circle := CircleShape2D.new()
	circle.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, center)
	query.collision_mask = 4
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var unique: Dictionary = {}
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 24):
		var collider: Node = result.get("collider")
		if collider != null and collider.has_method("take_damage"):
			unique[collider.get_instance_id()] = collider
	var nodes: Array[Node] = []
	for value: Variant in unique.values():
		nodes.append(value)
	return nodes


func take_damage(amount: int, source: Node = null) -> void:
	if state == State.DEAD or invulnerable:
		return
	health = maxi(0, health - maxi(0, amount))
	GameState.player_stats["health"] = health
	hurt_flash_timer = 0.16
	EventBus.actor_damaged.emit(self, amount, health)
	if health <= 0:
		state = State.DEAD
		velocity = Vector2.ZERO
		EventBus.player_defeated.emit()
	else:
		state = State.HURT
		state_timer = 0.22
		invulnerable = true
		var source_position := global_position - facing
		if source != null and source is Node2D:
			var source_2d := source as Node2D
			source_position = source_2d.global_position
		velocity = source_position.direction_to(global_position) * 135.0
		_clear_hurt_invulnerability()


func _clear_hurt_invulnerability() -> void:
	await get_tree().create_timer(0.5).timeout
	invulnerable = state == State.DODGE


func heal(amount: int) -> void:
	var previous := health
	health = mini(max_health, health + maxi(0, amount))
	GameState.player_stats["health"] = health
	EventBus.actor_healed.emit(self, health - previous, health)


func restore_from_game_state() -> void:
	max_health = int(GameState.player_stats.get("max_health", 100))
	health = clampi(int(GameState.player_stats.get("health", max_health)), 1, max_health)
	attack_power = int(GameState.player_stats.get("attack", 16))
	state = State.MOVE
	invulnerable = false
	queue_redraw()


func _create_visual_sprite() -> void:
	var atlas: Texture2D = load("res://assets/runtime/sprites/player_walk_atlas.png")
	if atlas == null:
		return
	var frame_width := floori(atlas.get_width() / 4.0)
	var frame_height := floori(atlas.get_height() / 4.0)
	visual_region = AtlasTexture.new()
	visual_region.atlas = atlas
	visual_region.region = Rect2(0, 0, frame_width, frame_height)
	visual_sprite = Sprite2D.new()
	visual_sprite.texture = visual_region
	visual_sprite.position = Vector2(0, -12)
	visual_sprite.scale = Vector2(0.15, 0.15)
	visual_sprite.z_index = -1
	visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var chroma := ShaderMaterial.new()
	chroma.shader = load("res://assets/shaders/chroma_transparency.gdshader")
	visual_sprite.material = chroma
	add_child(visual_sprite)


func _update_visual() -> void:
	if not is_instance_valid(visual_sprite):
		return
	var outfit_index: int = clampi(int(Dictionary(GameState.player_profile.get("appearance", {})).get("outfit", 0)), 0, 3)
	var outfit_tints := [Color.WHITE, Color("d6f0d0"), Color("ffd3c8"), Color("d6ddff")]
	var outfit_tint: Color = outfit_tints[outfit_index]
	visual_sprite.modulate = Color(outfit_tint.r, outfit_tint.g, outfit_tint.b, 0.55 if state == State.DODGE else 1.0)
	var moving := velocity.length_squared() > 36.0 and state == State.MOVE
	var direction_row := 0
	if absf(facing.x) > absf(facing.y):
		direction_row = 1 if facing.x < 0.0 else 2
	elif facing.y < 0.0:
		direction_row = 3
	var frame := int(Time.get_ticks_msec() / 135) % 4 if moving else 0
	if frame != visual_frame or direction_row != visual_direction_row:
		visual_frame = frame
		visual_direction_row = direction_row
		var atlas := visual_region.atlas
		var frame_width := floori(atlas.get_width() / 4.0)
		var frame_height := floori(atlas.get_height() / 4.0)
		visual_region.region = Rect2(frame * frame_width, direction_row * frame_height, frame_width, frame_height)
	visual_sprite.position = Vector2(0, -12)
	visual_sprite.flip_h = false
	visual_sprite.rotation = 0.0
	if hurt_flash_timer > 0.0:
		visual_sprite.modulate = Color(1.4, 1.4, 1.4, visual_sprite.modulate.a)


func _draw() -> void:
	if state == State.ATTACK:
		var arc_center := facing.normalized() * 22.0
		draw_arc(arc_center, 17.0 + combo_stage * 2.0, -1.5, 1.5, 12, Color("fff3cf"), 4.0)
	if skill_flash_timer > 0.0:
		var progress := 1.0 - skill_flash_timer / 0.32
		draw_arc(Vector2.ZERO, lerpf(18.0, 74.0, progress), 0.0, TAU, 40, Color(0.47, 0.86, 0.79, 1.0 - progress), 3.0)
