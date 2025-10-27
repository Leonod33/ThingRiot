extends CharacterBody2D

@export var stats: PlayerStats   # assign PlayerStats_Default.tres in the editor

# --- XP / Level ---
var level: int = 1
var xp: int = 0
var xp_to_next: int = 5

signal xp_changed(xp: int, xp_to_next: int, level: int)
signal level_up(level: int)

# --- Health System (values will be seeded from stats in _ready) ---
var max_health: int = 6
var current_health: int = 6

var invincible_timer := 0.0
const INVINCIBLE_TIME := 1.0  # seconds

var knockback_vector := Vector2.ZERO

func _ready():
	# collision setup
	collision_layer = 1
	collision_mask = 1
	if not is_in_group("Player"):
		add_to_group("Player")

	# seed runtime health from stats
	if stats:
		max_health = stats.max_health
		current_health = max_health
		# attack rate (seconds between shots)
		if has_node("AttackTimer"):
			$AttackTimer.wait_time = max(0.05, stats.attack_speed)

	# connect HUD XP bar updates
	var hud := get_node("/root/Main/UILayer")
	if hud and not is_connected("xp_changed", Callable(hud, "update_xp")):
		connect("xp_changed", Callable(hud, "update_xp"))

func add_xp(n: int) -> void:
	xp += n
	emit_signal("xp_changed", xp, xp_to_next, level)

	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		_on_level_up()
		emit_signal("xp_changed", xp, xp_to_next, level)  # refresh for new threshold

func _on_level_up() -> void:
	# No automatic stat increases. We’ll offer choices via a picker UI.
	xp_to_next = int(ceil(xp_to_next * 1.5))

	# (Optional) tiny heal on level-up; comment out if you want none
	# current_health = min(current_health + 1, max_health)
	# get_node("/root/Main/UILayer/HUD/HBoxContainer").update_hearts()

	# Popup “Lvl Up!” over the player (you already have this)
	var hud := get_node("/root/Main/UILayer")
	if hud:
		hud.call("show_level_up_at_player", self)

	emit_signal("level_up", level)

	# TODO soon: pause game and open the 3-choice upgrade picker
	# get_tree().paused = true
	# $UILayer/UpgradePicker.open(self, _on_upgrade_selected)


func apply_knockback(from_position: Vector2) -> void:
	# use knockback from stats
	var strength := stats.knockback_power if stats else 140.0
	var direction := (global_position - from_position).normalized()
	knockback_vector = direction * strength

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

	# MOVE using stats.speed
	var move_speed := stats.speed if stats else 260.0
	velocity = input_vector * move_speed
	move_and_slide()

	# map bounds clamp
	var map_node = get_node("/root/Main/Level1/TileMapLayer")
	var tile_size = map_node.tile_set.tile_size
	var map_rect = map_node.get_used_rect()
	var map_size = map_rect.size * tile_size

	# knockback decay
	if knockback_vector.length() > 0.1:
		position += knockback_vector * delta
		knockback_vector = lerp(knockback_vector, Vector2.ZERO, 6 * delta)

	position.x = clamp(position.x, 0, map_size.x)
	position.y = clamp(position.y, 0, map_size.y)

func _on_attack_timer_timeout():
	attack_nearest_enemy()

func attack_nearest_enemy() -> void:
	var nearest: Node2D = null
	var nearest_dist: float = INF

	var attack_range := stats.projectile_range if stats else 300.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist := global_position.distance_to(enemy.global_position)
		if dist < attack_range and dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	if nearest == null:
		return

	var dir := (nearest.global_position - global_position)
	if dir.length() < 8.0:
		return
	dir = dir.normalized()

	var count := stats.projectile_count if stats else 1
	var spread_deg: float = clamp(float(count - 1), 0.0, 6.0) * 6.0  # gentle fan spread as count grows
	var start_angle := -deg_to_rad(spread_deg * 0.5)
	var step := deg_to_rad(spread_deg / max(1, count - 1))

	for i in count:
		var angle := start_angle + step * i
		var shot_dir := dir.rotated(angle)

		var bullet = preload("res://crown_bullet.tscn").instantiate()

		# --- set everything the bullet needs BEFORE it's added to the tree ---
		bullet.direction = shot_dir
		if stats:
			bullet.damage = stats.attack_power
			bullet.size_multiplier = stats.projectile_size
			# lifetime from desired range (range / speed), with a small floor
			if bullet.speed > 0.0:
				bullet.lifetime = max(0.2, stats.projectile_range / bullet.speed)

		# you can set position before or after add_child; size must be before
		# (I’ll keep position after add_child, as in your original style)
		get_tree().current_scene.add_child(bullet)

		# spawn slightly ahead to avoid self-collision
		bullet.global_position = global_position + shot_dir * 14.0
		bullet.direction = shot_dir

		# --- feed stats straight in (no has_variable) ---
		if stats:
			bullet.damage = stats.attack_power
			bullet.size_multiplier = stats.projectile_size

			# lifetime from desired range (range / speed), with a small floor
			if bullet.speed > 0.0:
				bullet.lifetime = max(0.2, stats.projectile_range / bullet.speed)
