extends CharacterBody2D

@export var speed := 145
@export var damage := 1
@export var hp := 3

var player = null

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
	if player:
		var dir = (player.position - position).normalized()
		velocity = dir * speed
		move_and_slide()

func _on_body_entered(body):
	if body == player:
		player.change_health(-damage)
		

func take_damage(amount):
	hp -= amount
	print("Enemy took damage, HP is now:", hp)
	if hp <= 0:
		print("Enemy should be dead")
		queue_free()


func _on_damage_area_body_entered(body):
	if body.is_in_group("Player"):
		body.change_health(-damage)
		body.apply_knockback(position)  # 'position' here is the enemy's position
		# Simple push enemy back (optional)
		var push_dir = (position - body.position).normalized()
		position += push_dir * 20  # move enemy away by 20 pixels
