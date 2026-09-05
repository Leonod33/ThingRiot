extends CharacterBody2D

@export var speed := 120
@export var damage := 1
@export var hp := 2

var player = null
var dead := false
var knockback_velocity := Vector2.ZERO

func _ready():
		# Find player node once at start (adjust path if needed)
	add_to_group("enemies")
	player = get_node("/root/Main/Player")
		# Separate the enemy from the player body so they don't block each
		# other. The enemy only collides with the map (layer 1) and uses its
		# Area2D to detect the player.
	collision_layer = 2
	collision_mask = 1
	$DamageArea.collision_layer = 2
	$DamageArea.collision_mask = 1

func _physics_process(delta):
	if is_instance_valid(player) and not dead:
		var dir = (player.position - position).normalized()
		velocity = dir * speed + knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 700.0 * delta)
		move_and_slide()

func _on_body_entered(body):
	_on_damage_area_body_entered(body)

func take_damage(amount):
	if dead or amount <= 0:
		return
	hp -= amount
	if hp <= 0:
		dead = true
		_spawn_xp_gem(global_position)
		queue_free()

func apply_knockback(from_position: Vector2, strength: float) -> void:
	if not dead:
		knockback_velocity = (global_position - from_position).normalized() * strength

func _spawn_xp_gem(pos: Vector2) -> void:
	var gem := preload("res://pickups/XPGem.tscn").instantiate()
	get_tree().current_scene.add_child.call_deferred(gem)
	gem.global_position = pos

func _on_damage_area_body_entered(body):
	if not dead and body.is_in_group("Player") and body.change_health(-damage):
		body.apply_knockback(global_position)
		var push_dir = (global_position - body.global_position).normalized()
		global_position += push_dir * 20
