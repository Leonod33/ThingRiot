extends "res://enemy.gd"
var kind := "charger"
var state := "approach"
var clock := 1.0
var attack_direction := Vector2.RIGHT
var windup_count := 0
func _ready():
	basic_art = false
	super._ready()
	$Sprite2D.hide()
	scale = Vector2(1.4,1.4)
	hp = 5 if kind == "charger" else 4
	speed = 115
func _desired_velocity(delta: float, dir: Vector2) -> Vector2:
	# Only the warning ring changes continuously; the body drawing is cached.
	if state == "windup":
		queue_redraw()
	clock -= delta
	var distance := global_position.distance_to(player.global_position)
	match state:
		"windup":
			if clock <= 0:
				if kind == "charger":
					state = "charge"
					clock = 0.55
				else:
					shoot()
					state = "recover"
					clock = 1.2
			return Vector2.ZERO
		"charge":
			if clock <= 0:
				state = "recover"
				clock = 1.0
			return attack_direction * 500 * (0.45 if crumb_time > 0 else 1.0)
		"recover":
			if clock <= 0:
				state = "approach"
				clock = 1.0
			return Vector2.ZERO
	if distance < (420 if kind == "caster" else 310) and clock <= 0:
		state = "windup"
		queue_redraw()
		clock = 1.0
		attack_direction = dir
		windup_count += 1
		return Vector2.ZERO
	var factor := 0.45 if crumb_time > 0 else 1.0
	if kind == "caster" and distance < 260:
		return -dir * speed * factor
	return dir * speed * factor
func shoot():
	if get_tree().get_nodes_in_group("enemy_bolts").size() >= 32:
		return
	var bolt = preload("res://arena/enemy_bolt.gd").new()
	bolt.direction = attack_direction
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position + attack_direction * 26
func _draw():
	if state == "windup":
		var length := 275.0 / scale.x if kind == "charger" else 400.0 / scale.x
		var colour := Color(1,0.87,0.6,0.7)
		draw_line(Vector2.ZERO, attack_direction*length, colour, 2)
		for offset in [-1,1]:
			var normal = attack_direction.orthogonal() * 13 * offset
			draw_line(normal, attack_direction*length+normal,colour,1)
		draw_arc(Vector2.ZERO,23, -PI/2, -PI/2+TAU*(1-clock),32,Color.WHITE,3)
	super._draw()
