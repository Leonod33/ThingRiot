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
var current_health: float = 6.0
var dead := false

var invincible_timer := 0.0
var escape_timer := 0.0
const INVINCIBLE_TIME := 1.6  # seconds

var hit_direction := Vector2.UP
var knockback_vector := Vector2.ZERO

func _ready():
	$Sprite2D.hide()
	var king = preload("res://characters/king_visual.gd").new()
	king.name = "KingVisual"
	add_child(king)
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	$CollisionShape2D.shape = shape
	$CollisionShape2D.scale = Vector2.ONE
	$CollisionShape2D.position = Vector2(0,2)

	z_index = 6
	var weapons = preload("res://weapons/weapon_controller.gd").new()
	weapons.name = "Weapons"
	add_child.call_deferred(weapons)
	$AttackTimer.stop()
	# Resources loaded from disk are shared; upgrades belong to this run only.
	stats = stats.duplicate(true) if stats else PlayerStats.new()
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
	if dead or n <= 0:
		return
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

func apply_knockback(from_position: Vector2) -> void:
	hit_direction = global_position.direction_to(from_position)
	var direction := (global_position - from_position).normalized()
	knockback_vector = direction * 85.0

# Returns whether the hit/heal was accepted, so contact effects respect immunity.
func change_health(amount: float) -> bool:
	if dead or amount == 0.0 or (amount < 0.0 and invincible_timer > 0.0):
		return false
	if amount < 0.0:
		amount *= 1.0 - clampf(stats.defense, 0.0, 0.8)
		invincible_timer = INVINCIBLE_TIME
		escape_timer = 0.7
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if global_position.distance_squared_to(enemy.global_position) < 130.0*130.0:
				enemy.apply_knockback(global_position,430.0)
		var feedback = get_tree().current_scene.get_node_or_null("Feedback")
		if feedback:
			feedback.hurt()
	current_health = clampf(current_health + amount, 0.0, float(max_health))
	get_node("/root/Main/UILayer/HUD/HBoxContainer").update_hearts()
	if current_health <= 0.000001:
		die()
	return true

func die():
	if dead:
		return
	dead = true
	get_tree().paused = false
	var director = get_tree().current_scene.get_node_or_null("RunDirector")
	if director:
		director.finish(false)
	else:
		get_tree().change_scene_to_file.call_deferred("res://GameOverScreen.tscn")

func _physics_process(delta):
	escape_timer = maxf(0,escape_timer-delta)
	var input_vector = Vector2.ZERO

	if invincible_timer > 0:
		invincible_timer -= delta

	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector += Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	var pads = Input.get_connected_joypads()
	if not pads.is_empty():
		var stick = Vector2(Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_X), Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2:
			input_vector = stick.normalized() * clampf((stick.length() - 0.2) / 0.8, 0.0, 1.0)
	input_vector = input_vector.limit_length(1.0)

	# MOVE using stats.speed
	var move_speed := stats.speed if stats else 260.0
	velocity = input_vector * move_speed * (1.3 if escape_timer > 0 else 1.0) + knockback_vector
	move_and_slide()
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 650.0 * delta)
	var camera: Camera2D = $Camera2D
	global_position.x = clampf(global_position.x, camera.limit_left + 35, camera.limit_right - 35)
	global_position.y = clampf(global_position.y, camera.limit_top + 55, camera.limit_bottom - 55)

func _on_attack_timer_timeout():
	pass # WeaponController owns independent weapon cooldowns.
