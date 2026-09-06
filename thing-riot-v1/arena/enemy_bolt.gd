extends Node2D
var direction := Vector2.RIGHT
var age := 0.0
var spent := false
var player: Node2D
func _ready():
	add_to_group("enemy_bolts")
	z_index = 3
	player = get_tree().get_first_node_in_group("Player")
func _physics_process(delta):
	if spent:
		return
	age += delta
	var before := global_position
	global_position += direction * 300 * delta
	var p = player
	if is_instance_valid(p) and not p.dead and Geometry2D.get_closest_point_to_segment(p.global_position, before, global_position).distance_to(p.global_position) < 20:
		p.change_health(-1)
		spent = true
		queue_free()
	if age > 4:
		queue_free()
func _draw():
	draw_circle(Vector2.ZERO, 9, Color("30243d"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-8),Vector2(7,0),Vector2(0,8),Vector2(-7,0)]),Color("fff0c2"))
	draw_line(-direction*20, -direction*9, Color("f2aa70"),3)
