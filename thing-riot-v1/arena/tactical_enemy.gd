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
	var tint := Color.WHITE if flash_time > 0 else Color("b7c9d5")
	if kind == "charger":
		draw_circle(Vector2(0,3),17,Color("272638"))
		draw_circle(Vector2(0,1),14,tint)
		draw_rect(Rect2(-12,-5,24,6),Color("272638"))
		for x in [-7,7]:
			draw_line(Vector2(x,-2),Vector2(x+3,-2),Color("ffe4a3"),2)
		draw_colored_polygon(PackedVector2Array([Vector2(-7,-13),Vector2(0,-28),Vector2(7,-13)]),Color("f0c875"))
		draw_line(Vector2(-16,11),Vector2(16,11),Color("796487"),5)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-19,18),Vector2(0,-23),Vector2(19,18)]),Color("30283e"))
		draw_colored_polygon(PackedVector2Array([Vector2(-13,14),Vector2(0,-18),Vector2(13,14)]),Color("74729d"))
		draw_circle(Vector2(0,-1),8,Color("202135"))
		for x in [-3,3]:
			draw_circle(Vector2(x,-2),1.5,Color("fff2cd"))
		draw_line(Vector2(17,18),Vector2(20,-13),Color("dec48b"),3)
		draw_circle(Vector2(20,-16),4,Color("fff2cd"))
	super._draw()
