extends CharacterBody2D

func _ready():
	# your existing setup
	collision_layer = 1
	collision_mask = 1
	if not is_in_group("Player"):
		add_to_group("Player")

	# connect to the HUD once
	var hud := get_node("/root/Main/UILayer")
	if hud and not is_connected("xp_changed", Callable(hud, "update_xp")):
		connect("xp_changed", Callable(hud, "update_xp"))
# Movement speed in pixels/sec
var speed := 260

# --- XP / Level ---
var level: int = 1
var xp: int = 0
var xp_to_next: int = 5

signal xp_changed(xp: int, xp_to_next: int, level: int)
signal level_up(level: int)


func add_xp(n: int) -> void:
	xp += n
	emit_signal("xp_changed", xp, xp_to_next, level)

	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		_on_level_up()
		emit_signal("xp_changed", xp, xp_to_next, level)  # refresh for new threshold

func _on_level_up() -> void:
	# your buffs
	max_health += 2
	current_health = min(current_health + 2, max_health)
	speed += 8
	xp_to_next = int(ceil(xp_to_next * 1.5))

	# update hearts (you already use this exact path)
	get_node("/root/Main/UILayer/HUD/HBoxContainer").update_hearts()

	# popup above player
	var hud := get_node("/root/Main/UILayer")
	if hud:
		hud.call("show_level_up_at_player", self)

	emit_signal("level_up", level)


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
		get_node("/root/Main/UILayer/HUD/HBoxContainer").update_hearts()
		
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
	
	
func attack_nearest_enemy() -> void:
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist := global_position.distance_to(enemy.global_position)
		if dist < 300.0 and dist < nearest_dist:  # 300 is your attack range
			nearest = enemy
			nearest_dist = dist

	if nearest:
		var dir := (nearest.global_position - global_position)
		if dir.length() < 8.0:
			return  # too close; skip this tick (or pick another target)
		dir = dir.normalized()

		var bullet := preload("res://crown_bullet.tscn").instantiate()
		get_tree().current_scene.add_child(bullet)

		# spawn slightly ahead to avoid self-collision
		bullet.global_position = global_position + dir * 14.0
		bullet.direction = dir
