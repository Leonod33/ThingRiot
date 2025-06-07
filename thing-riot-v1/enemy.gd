extends CharacterBody2D

@export var speed := 100
@export var damage := 1

var player = null

func _ready():
	# Find player node once at start (adjust path if needed)
	player = get_node("/root/Main/Player")

func _physics_process(delta):
	if player:
		var dir = (player.position - position).normalized()
		velocity = dir * speed
		move_and_slide()

func _on_body_entered(body):
	if body == player:
		player.change_health(-damage)
		


func _on_DamageArea_body_entered(body):
	if body.is_in_group("Player"):
		body.change_health(-damage)
		body.apply_knockback(position)  # 'position' here is the enemy's position
		# Simple push enemy back (optional)
		var push_dir = (position - body.position).normalized()
		position += push_dir * 20  # move enemy away by 20 pixels
