extends Node2D
var cooldowns := {}
var pulse := 0.0
var bounce_count := 0
var sensor: Area2D
func _ready():
	add_to_group("bumpers")
	sensor = Area2D.new()
	sensor.collision_layer = 0
	sensor.monitorable = false
	sensor.collision_mask = 3
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 42
	sensor.add_child(shape)
	add_child(sensor)
func _physics_process(delta):
	pulse = maxf(0,pulse-delta)
	for id in cooldowns.keys():
		cooldowns[id] -= delta
		if cooldowns[id] <= 0:
			cooldowns.erase(id)
	# The physics broad phase maintains nearby bodies; distant pads do no scans.
	for body in sensor.get_overlapping_bodies():
		if not (body.is_in_group("Player") or body.is_in_group("enemies")):
			continue
		if body.dead or body.is_queued_for_deletion() or cooldowns.has(body.get_instance_id()):
			continue
		if global_position.distance_squared_to(body.global_position) < 42 * 42:
			bounce(body)
	if pulse > 0 or not cooldowns.is_empty():
		queue_redraw()

func bounce(body):
	var dir := global_position.direction_to(body.global_position)
	if dir.is_zero_approx():
		dir = Vector2.RIGHT
	if body.is_in_group("Player"):
		body.knockback_vector = dir * 550
	else:
		body.apply_knockback(global_position-dir,650)
	cooldowns[body.get_instance_id()] = 0.9
	pulse = 0.3
	bounce_count += 1
	if body.is_in_group("Player"):
		var feedback = get_tree().current_scene.get_node_or_null("Feedback")
		if feedback:
			feedback.sound("spring")
func _draw():
	draw_set_transform(Vector2(0,5),0,Vector2(1,0.72))
	draw_circle(Vector2.ZERO,35,Color("1c2d40"))
	draw_circle(Vector2.ZERO,31,Color("866f4f"))
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2.ZERO,32,Color("27303f"))
	draw_arc(Vector2.ZERO,28,0,TAU,40,Color("a7e5ee"),3)
	var r := 20.0 - pulse*16
	draw_circle(Vector2.ZERO,r,Color("498ca6"))
	draw_arc(Vector2.ZERO,r,0,TAU,32,Color("fff0c7"),3)
	var points := PackedVector2Array()
	for i in range(7):
		points.append(Vector2(-12+i*4, -5 if i%2==0 else 5))
	draw_polyline(points,Color.WHITE,2)
	for i in range(8):
		var point := Vector2.from_angle(i*TAU/8)*29
		draw_circle(point,2.0,Color("e7bd70"))
