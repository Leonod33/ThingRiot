extends Node2D
var direction := Vector2.RIGHT
var age := 0.0
var spent := false
var player: Node2D
func _ready():
	add_to_group("enemy_bolts")
	z_index = 7
	player = get_tree().get_first_node_in_group("Player")
func _physics_process(delta):
	if spent:
		return
	age += delta
	var before := global_position
	global_position += direction * 300 * delta
	var p = player
	if is_instance_valid(p) and not p.dead and Geometry2D.get_closest_point_to_segment(p.global_position, before, global_position).distance_to(p.global_position) < 20:
		p.hit_direction = -direction
		p.change_health(-1)
		spent = true
		queue_free()
	if age > 4:
		queue_free()
func _draw():
	draw_set_transform(Vector2.ZERO,direction.angle())
	var points := PackedVector2Array([Vector2(15,0),Vector2(-11,-9),Vector2(-6,0),Vector2(-11,9)])
	draw_colored_polygon(points,Color("fff0c5"))
	points.append(points[0])
	draw_polyline(points,Color("20283b"),3,true)
	draw_line(Vector2(-6,0),Vector2(9,0),Color("d29869"),2,true)
	draw_line(Vector2(-21,0),Vector2(-14,0),Color("fff0c5"),2,true)
