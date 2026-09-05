extends Node2D
var cooldowns := {}
var pulse := 0.0
var bounce_count := 0
func _ready():
	add_to_group("bumpers")
func _physics_process(delta):
	pulse = maxf(0,pulse-delta)
	for id in cooldowns.keys():
		cooldowns[id] -= delta
		if cooldowns[id] <= 0:
			cooldowns.erase(id)
	for group in ["Player","enemies"]:
		for body in get_tree().get_nodes_in_group(group):
			if body.dead or body.is_queued_for_deletion() or cooldowns.has(body.get_instance_id()):
				continue
			if global_position.distance_to(body.global_position) < 42:
				bounce(body)
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
func _draw():
	draw_circle(Vector2.ZERO,32,Color("27303f"))
	draw_arc(Vector2.ZERO,28,0,TAU,40,Color("a7e5ee"),3)
	var r := 20.0 - pulse*16
	draw_circle(Vector2.ZERO,r,Color("498ca6"))
	draw_arc(Vector2.ZERO,r,0,TAU,32,Color("fff0c7"),3)
	var points := PackedVector2Array()
	for i in range(7):
		points.append(Vector2(-12+i*4, -5 if i%2==0 else 5))
	draw_polyline(points,Color.WHITE,2)
