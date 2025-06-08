extends CharacterBody2D

func _ready():
		# The player only collides with the map so enemies don't physically
		# block or push them. Enemy contact is handled via Area2D.
	collision_layer = 1
	collision_mask = 1

# Movement speed in pixels/sec
var speed := 260

# --- Health System ---
var max_health := 6 # For example, 3 hearts (each = 2 HP)
var current_health := max_health

var invincible_timer := 0.0
const INVINCIBLE_TIME := 1.0  # seconds

var knockback_strength := 140.0  # tweak to taste
var knockback_vector := Vector2.ZERO


func apply_knockback(from_position: Vector2):
	var direction = (position - from_position).normalized()
	knockback_vector = direction * knockback_strength


# Damage/heal function
func change_health(amount: int):
	if invincible_timer <= 0:
		current_health = clamp(current_health + amount, 0, max_health)
		get_node("/root/Main/UILayer/HBoxContainer").update_hearts()
		
		if amount < 0:
			invincible_timer = INVINCIBLE_TIME
		if current_health == 0:
			die()

func die():
	get_tree().change_scene_to_file("res://GameOverScreen.tscn")

	

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	
	if invincible_timer > 0:
		invincible_timer -= delta
	
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	velocity = input_vector * speed
	move_and_slide()
	
	var map_node = get_node("/root/Main/Level1/TileMapLayer")
	var tile_size = map_node.tile_set.tile_size
	var map_rect = map_node.get_used_rect()
	var map_size = map_rect.size * tile_size
	
	
	if knockback_vector.length() > 0.1:
		position += knockback_vector * delta
		knockback_vector = lerp(knockback_vector, Vector2.ZERO, 6 * delta)  # "decay" the knockback over time
	

	position.x = clamp(position.x, 0, map_size.x)
	position.y = clamp(position.y, 0, map_size.y)



# Get viewport size


func _on_attack_timer_timeout():
	attack_nearest_enemy()
	
	
func attack_nearest_enemy():
	var nearest = null
	var nearest_dist = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = position.distance_to(enemy.position)
		if dist < 300 and dist < nearest_dist:  # 300 is your attack range
			nearest = enemy
			nearest_dist = dist
	if nearest:
		var bullet = preload("res://crown_bullet.tscn").instantiate()
		get_parent().add_child(bullet)
		bullet.position = position
		bullet.direction = (nearest.position - position).normalized()
