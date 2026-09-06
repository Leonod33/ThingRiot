extends "res://enemy.gd"
var max_hp := 240
var attack_timer := 2.5
var attacks := 0
var director: Node
func _ready():
	basic_art = false
	super._ready()
	add_to_group("boss")
	$Sprite2D.hide()
	scale = Vector2.ONE
	hp = max_hp
	speed = 85
	var shape = CircleShape2D.new()
	shape.radius = 52
	$CollisionShape2D.shape = shape
	var touch = CircleShape2D.new()
	touch.radius = 56
	$DamageArea/CollisionShape2D.shape = touch
func _desired_velocity(delta: float, dir: Vector2) -> Vector2:
	attack_timer -= delta
	if attack_timer <= 0:
		stamp_attack()
		attack_timer = 2.8 if hp > max_hp / 2 else 2.2
	if global_position.distance_to(player.global_position) > 260:
		return dir * speed * (0.45 if crumb_time > 0 else 1.0)
	return Vector2.ZERO
func stamp_attack():
	if dead or not is_instance_valid(player) or player.dead:
		return
	var point = player.global_position
	# Teach each rectangle separately twice before combining the two shapes.
	var combined := attacks >= 4 and hp <= max_hp / 2
	if combined:
		make_stamp(point, Vector2(110,330))
		make_stamp(point, Vector2(330,110))
	else:
		make_stamp(point, Vector2(110,330) if attacks % 2 == 0 else Vector2(330,110))
	attacks += 1
func make_stamp(point: Vector2, dimensions: Vector2):
	if get_tree().get_nodes_in_group("boss_stamps").size() >= 6:
		return
	var stamp = preload("res://run/stamp.gd").new()
	stamp.size = dimensions
	get_tree().current_scene.add_child(stamp)
	stamp.global_position = point
func take_damage(amount):
	if dead or amount <= 0:
		return
	hp -= amount
	queue_redraw()
	if hp <= 0:
		dead = true
		if is_instance_valid(director):
			director.finish(true)
		queue_free()
func _draw():
	var ink = Color("29283f")
	# Six angular legs, enormous paper-stamping claws, suit and spectacles.
	for side in [-1,1]:
		for i in range(3):
			var points = PackedVector2Array([Vector2(side*35,i*18-12),Vector2(side*(66+i*5),i*22-20),Vector2(side*(84+i*5),i*23)])
			draw_polyline(points,ink,10)
			draw_polyline(points,Color("d69b77"),5)
		draw_line(Vector2(side*40,-15),Vector2(side*78,-48),ink,15)
		draw_circle(Vector2(side*80,-52),22,Color("ddaa85"))
		draw_rect(Rect2(Vector2(side*80-25,-45),Vector2(50,17)),ink)
		draw_rect(Rect2(Vector2(side*80-20,-44),Vector2(40,9)),Color("fff0c5"))
	draw_circle(Vector2.ZERO,56,ink)
	draw_circle(Vector2(0,-5),49,Color("737898"))
	draw_colored_polygon(PackedVector2Array([Vector2(-22,-34),Vector2(0,28),Vector2(22,-34)]),Color("fff0c5"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-24),Vector2(-8,-10),Vector2(0,20),Vector2(8,-10)]),Color("d29c50"))
	for x in [-18,18]:
		draw_line(Vector2(x,-35),Vector2(x,-64),ink,7)
		draw_circle(Vector2(x,-64),12,Color("fff0c5"))
		draw_arc(Vector2(x,-64),12,0,TAU,20,ink,3)
		draw_circle(Vector2(x,-64),4,ink)
	draw_line(Vector2(-8,-64),Vector2(8,-64),ink,3)
	draw_rect(Rect2(-26,31,52,12),Color("fff0c5"))
	super._draw()
