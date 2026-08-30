class_name PixelRPGEnemy
extends CharacterBody2D

enum State { PATROL, CHASE, TELEGRAPH, ATTACK, HURT, DEAD }

const ProjectileScript := preload("res://runtime/actors/enemy_projectile.gd")

var enemy_id: StringName = &"slime"
var display_name := "史萊姆"
var max_health := 48
var health := 48
var damage := 10
var move_speed := 54.0
var detection_radius := 175.0
var attack_radius := 31.0
var is_boss := false
var behavior := "melee"
var projectile_speed := 140.0
var attack_interval := 0.9
var body_color := Color("db5a6b")
var drops: Array = []
var state := State.PATROL
var state_timer := 0.0
var attack_cooldown := 0.0
var spawn_position := Vector2.ZERO
var patrol_target := Vector2.ZERO
var player: Node2D
var hurt_flash_timer := 0.0
var attack_counter := 0
var visual_sprite: Sprite2D


func configure(definition: Dictionary) -> void:
	enemy_id = StringName(definition.get("id", "slime"))
	display_name = String(definition.get("display_name", "敵人"))
	max_health = int(definition.get("max_health", 48))
	health = max_health
	damage = int(definition.get("damage", 10))
	move_speed = float(definition.get("move_speed", 54.0))
	is_boss = bool(definition.get("is_boss", false))
	behavior = String(definition.get("behavior", "melee"))
	body_color = Color(String(definition.get("color", "db5a6b")))
	detection_radius = float(definition.get("detection_radius", 260.0 if is_boss else 175.0))
	attack_radius = float(definition.get("attack_radius", 54.0 if is_boss else (145.0 if behavior == "ranged" else 31.0)))
	projectile_speed = float(definition.get("projectile_speed", 150.0))
	attack_interval = float(definition.get("attack_cooldown", 0.7 if is_boss else 0.9))
	drops = Array(definition.get("drops", [])).duplicate(true)


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	spawn_position = global_position
	patrol_target = spawn_position + Vector2(32, 0).rotated(randf() * TAU)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0 if is_boss else 10.0
	collision.shape = shape
	add_child(collision)
	_create_visual_sprite()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hurt_flash_timer = maxf(0.0, hurt_flash_timer - delta)
	_update_visual()
	queue_redraw()
	if player == null:
		velocity = Vector2.ZERO
		return

	var distance := global_position.distance_to(player.global_position)
	match state:
		State.PATROL:
			if distance <= detection_radius:
				state = State.CHASE
			else:
				_patrol(delta)
		State.CHASE:
			if distance > detection_radius * 1.35:
				state = State.PATROL
			elif distance <= attack_radius and attack_cooldown <= 0.0:
				state = State.TELEGRAPH
				state_timer = 0.46 if is_boss else 0.34
				velocity = Vector2.ZERO
			elif behavior == "ranged" and distance < attack_radius * 0.58:
				velocity = player.global_position.direction_to(global_position) * move_speed * 0.7
			else:
				velocity = global_position.direction_to(player.global_position) * move_speed
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.ATTACK
				state_timer = 0.18
				_perform_attack()
		State.ATTACK:
			state_timer -= delta
			velocity = Vector2.ZERO
			if state_timer <= 0.0:
				attack_cooldown = attack_interval
				state = State.CHASE
		State.HURT:
			state_timer -= delta
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			if state_timer <= 0.0:
				state = State.CHASE
	move_and_slide()


func _update_visual() -> void:
	if not is_instance_valid(visual_sprite):
		return
	var ticks := float(Time.get_ticks_msec()) / 1000.0
	var phase := float(get_instance_id() % 17) * 0.31
	var intensity := 2.4 if state in [State.CHASE, State.ATTACK] else 1.4
	visual_sprite.position = Vector2(0, -7 + sin(ticks * intensity + phase) * (2.0 if is_boss else 1.2))
	if is_instance_valid(player):
		visual_sprite.flip_h = player.global_position.x < global_position.x
	visual_sprite.modulate = Color(1.5, 1.5, 1.5) if hurt_flash_timer > 0.0 else Color.WHITE
	var pulse := 1.0 + sin(ticks * 3.0 + phase) * (0.025 if is_boss else 0.012)
	var base_scale := 0.18 if is_boss else 0.145
	visual_sprite.scale = Vector2(base_scale * pulse, base_scale / pulse)


func _patrol(_delta: float) -> void:
	if global_position.distance_to(patrol_target) < 8.0:
		patrol_target = spawn_position + Vector2(randf_range(-48, 48), randf_range(-48, 48))
	velocity = global_position.direction_to(patrol_target) * move_speed * 0.42


func _perform_attack() -> void:
	if not is_instance_valid(player):
		return
	attack_counter += 1
	if is_boss:
		match String(enemy_id):
			"spring_root_guardian":
				if attack_counter % 2 == 0:
					for shot_index in range(6):
						_spawn_projectile(Vector2.RIGHT.rotated(TAU * float(shot_index) / 6.0))
					return
			"summer_forge_drake":
				var summer_aim := global_position.direction_to(player.global_position)
				for angle in [-0.42, -0.21, 0.0, 0.21, 0.42]:
					_spawn_projectile(summer_aim.rotated(float(angle)))
				return
			"autumn_harvest_golem":
				if attack_counter % 3 == 0:
					for shot_index in range(10):
						_spawn_projectile(Vector2.RIGHT.rotated(TAU * float(shot_index) / 10.0))
					return
			"winter_bell_warden":
				var offset := float(attack_counter % 5) * 0.13
				for shot_index in range(12):
					_spawn_projectile(Vector2.RIGHT.rotated(offset + TAU * float(shot_index) / 12.0))
				return
	if behavior == "ranged":
		_spawn_projectile(global_position.direction_to(player.global_position))
		return
	if is_boss and attack_counter % 3 == 0:
		for shot_index in range(8):
			_spawn_projectile(Vector2.RIGHT.rotated(TAU * float(shot_index) / 8.0))
		return
	if is_boss and global_position.distance_to(player.global_position) > attack_radius * 0.8:
		_spawn_projectile(global_position.direction_to(player.global_position))
		_spawn_projectile(global_position.direction_to(player.global_position).rotated(0.22))
		_spawn_projectile(global_position.direction_to(player.global_position).rotated(-0.22))
		return
	if global_position.distance_to(player.global_position) <= attack_radius + 8.0 and player.has_method("take_damage"):
		player.take_damage(damage, self)


func _spawn_projectile(travel_direction: Vector2) -> void:
	var projectile := ProjectileScript.new() as PixelRPGEnemyProjectile
	projectile.configure(global_position, travel_direction, projectile_speed, damage, body_color.lightened(0.18), self)
	get_parent().add_child(projectile)


func _create_visual_sprite() -> void:
	var ids := ["moss_slime","thorn_rat","pollen_wisp","ember_slime","cave_bat","magma_beetle","amber_slime","stone_boar","fog_wisp","ice_slime","frost_wolf","bell_guardian","spring_root_guardian","summer_forge_drake","autumn_harvest_golem","winter_bell_warden"]
	var index := ids.find(String(enemy_id))
	if index < 0:
		return
	var atlas: Texture2D = load("res://assets/runtime/sprites/enemy_atlas.png")
	if atlas == null:
		return
	var region := AtlasTexture.new()
	region.atlas = atlas
	region.region = Rect2((index % 4) * atlas.get_width() / 4.0, (index / 4) * atlas.get_height() / 4.0, atlas.get_width() / 4.0, atlas.get_height() / 4.0)
	visual_sprite = Sprite2D.new()
	visual_sprite.texture = region
	visual_sprite.position = Vector2(0, -7)
	visual_sprite.scale = Vector2(0.18, 0.18) if is_boss else Vector2(0.145, 0.145)
	visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual_sprite.z_index = -1
	var chroma := ShaderMaterial.new()
	chroma.shader = load("res://assets/shaders/chroma_transparency.gdshader")
	visual_sprite.material = chroma
	add_child(visual_sprite)


func take_damage(amount: int, source: Node = null) -> void:
	if state == State.DEAD:
		return
	health = maxi(0, health - maxi(0, amount))
	hurt_flash_timer = 0.14
	EventBus.actor_damaged.emit(self, amount, health)
	if health <= 0:
		_die()
	else:
		state = State.HURT
		state_timer = 0.18
		if source != null and source is Node2D:
			var source_2d := source as Node2D
			velocity = source_2d.global_position.direction_to(global_position) * (105.0 if is_boss else 160.0)


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	EventBus.enemy_defeated.emit(enemy_id, global_position)
	for drop: Dictionary in drops:
		if randf() <= float(drop.get("chance", 0.0)):
			InventoryAdapter.add_item(StringName(drop.get("item_id", "")), int(drop.get("count", 1)))
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK)
	await tween.finished
	queue_free()


func _draw() -> void:
	var radius := 27.0 if is_boss else 15.0
	var color := body_color
	if hurt_flash_timer > 0.0:
		color = Color.WHITE
	if not is_instance_valid(visual_sprite):
		draw_circle(Vector2.ZERO, radius, color)
	if state == State.TELEGRAPH:
		draw_arc(Vector2.ZERO, radius + 6.0, 0.0, TAU, 24, Color("ffcf5c"), 3.0)
	var health_ratio := float(health) / float(max_health)
	draw_rect(Rect2(-radius, -radius - 8, radius * 2.0, 3), Color("2b3154"))
	draw_rect(Rect2(-radius, -radius - 8, radius * 2.0 * health_ratio, 3), Color("78dcca"))
