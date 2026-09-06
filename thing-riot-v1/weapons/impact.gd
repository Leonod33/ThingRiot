extends Node2D
var age := 0.0
var kind := "crown"
var tint := Color("fff0a0")
func _ready():
	z_index = 2
	add_to_group("polish_effects")
	if get_tree().get_nodes_in_group("polish_effects").size() > 32:
		queue_free()
func _process(delta):
	age += delta
	if age > 0.22:
		queue_free()
	queue_redraw()
func _draw():
	if kind == "biscuit":
		for i in range(7):
			var point := Vector2.from_angle(i*2.4)*(8+age*100)
			draw_set_transform(point,age*8+i)
			draw_rect(Rect2(-3,-2,6,4),Color(0.92,0.72,0.43,1-age/0.22))
		return
	for i in range(5):
		var direction = Vector2.from_angle(i * TAU / 5)
		draw_line(direction * (7 + age * 50), direction * (14 + age * 110), Color(tint, 1.0 - age / 0.22), 1.8)
