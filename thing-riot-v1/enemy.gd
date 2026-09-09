extends CharacterBody2D

@export var speed := 120
@export var damage := 1
@export var hp := 2

var basic_art := true
var player = null
var dead := false
var crumb_time := 0.0
var flash_time := 0.0
var knockback_velocity := Vector2.ZERO
var artwork: Sprite2D

func _ready():
	z_index = 1
	$Sprite2D.hide()
	if not is_in_group("boss") and get_script().resource_path != "res://run/bureaucrab.gd":
		artwork = preload("res://characters/enemy_visual.gd").new()
		artwork.name = "EnemyVisual"
		add_child(artwork)
		# Find player node once at start (adjust path if needed)
	add_to_group("enemies")
	player = get_node("/root/Main/Player")
		# Separate the enemy from the player body so they don't block each
		# other. The enemy only collides with the map (layer 1) and uses its
		# Area2D to detect the player.
	collision_layer = 2
	collision_mask = 1
	$DamageArea.collision_layer = 0
	$DamageArea.monitorable = false
	$DamageArea.collision_mask = 1

func coat_with_crumbs():
	if crumb_time <= 0:
		queue_redraw()
	crumb_time = 2.0

func _physics_process(delta):
	var was_coated := crumb_time > 0
	var was_flashing := flash_time > 0
	crumb_time = maxf(0.0, crumb_time - delta)
	flash_time = maxf(0.0, flash_time - delta)
	if was_flashing != (flash_time > 0):
		if is_instance_valid(artwork):
			artwork.flash(flash_time > 0)
		$Sprite2D.modulate = Color(3,3,3) if flash_time > 0 else Color.WHITE
		queue_redraw()
	if was_coated != (crumb_time > 0):
		queue_redraw()
	if is_instance_valid(player) and not dead:
		var dir = (player.position - position).normalized()
		velocity = _desired_velocity(delta, dir) + knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 700.0 * delta)
		move_and_slide()

func _on_body_entered(body):
	_on_damage_area_body_entered(body)

func take_damage(amount):
	if dead or amount <= 0:
		return
	flash_time = 0.08
	if is_instance_valid(artwork):
		artwork.flash(true)
	$Sprite2D.modulate = Color(3,3,3)
	queue_redraw()
	hp -= amount
	if hp <= 0:
		dead = true
		var debris = preload("res://weapons/impact.gd").new()
		debris.kind = "paper"
		get_tree().current_scene.add_child(debris)
		debris.global_position = global_position
		var run = get_tree().current_scene.get_node_or_null("RunDirector")
		if run:
			run.kills += 1
		_spawn_xp_gem(global_position)
		queue_free()

func apply_knockback(from_position: Vector2, strength: float) -> void:
	if not dead:
		var away := global_position - from_position
		knockback_velocity = (away.normalized() if away.length_squared() > 0.01 else Vector2.RIGHT) * strength

func _spawn_xp_gem(pos: Vector2) -> void:
	var gem := preload("res://pickups/XPGem.tscn").instantiate()
	get_tree().current_scene.add_child.call_deferred(gem)
	gem.global_position = pos

func _on_damage_area_body_entered(body):
	if not dead and body.is_in_group("Player") and body.change_health(-damage):
		body.apply_knockback(global_position)
		var push_dir = (global_position - body.global_position).normalized()
		global_position += push_dir * 20

func _draw():
	if basic_art and not is_instance_valid(artwork):
		draw_set_transform(Vector2(0,10),0,Vector2(1,0.3))
		draw_circle(Vector2.ZERO,15,Color(0.03,0.04,0.08,0.35))
		draw_set_transform(Vector2.ZERO)
		draw_circle(Vector2.ZERO,13,Color("20283b"))
		draw_circle(Vector2(0,-1),11,Color.WHITE if flash_time > 0 else Color("739ba8"))
		for x in [-7,0,7]:
			draw_circle(Vector2(x,7),4,Color("739ba8"))
		draw_arc(Vector2(0,-1),9,PI,PI*1.6,12,Color("bbd9db"),2,true)
		for x in [-4,4]:
			draw_circle(Vector2(x,-2),3,Color("f4ecd2"))
			draw_circle(Vector2(x,-1),1.4,Color("20283b"))
		draw_arc(Vector2(0,2),3,0,PI,8,Color("20283b"),1.4)
		draw_line(Vector2(-5,-10),Vector2(-2,-15),Color("20283b"),3)
		draw_line(Vector2(-2,-15),Vector2(5,-13),Color("e9be72"),3)
	if crumb_time > 0:
		for arc in range(4):
			draw_arc(Vector2.ZERO,17,arc*PI/2,arc*PI/2+0.75,8,Color(1,0.88,0.64,0.6),0.85,true)
		for i in range(5):
			draw_rect(Rect2(Vector2.from_angle(i * 1.25) * 14, Vector2(3,2)), Color("fff0bb"))

func _desired_velocity(_delta: float, dir: Vector2) -> Vector2:
	return dir * speed * (0.45 if crumb_time > 0 else 1.0)
