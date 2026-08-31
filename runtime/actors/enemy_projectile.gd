class_name PixelRPGEnemyProjectile
extends Area2D

var direction := Vector2.RIGHT
var speed := 140.0
var damage := 8
var tint := Color("f0b85a")
var lifetime := 4.0
var source: Node


func configure(origin: Vector2, travel_direction: Vector2, projectile_speed: float, attack_damage: int, color: Color, owner_node: Node) -> void:
	global_position = origin
	direction = travel_direction.normalized()
	speed = projectile_speed
	damage = attack_damage
	tint = color
	source = owner_node


func _ready() -> void:
	add_to_group("enemy_projectiles")
	z_index = 6
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0 or global_position.x < 10.0 or global_position.x > 630.0 or global_position.y < 50.0 or global_position.y > 345.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, tint)
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
