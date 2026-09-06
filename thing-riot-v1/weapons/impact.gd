extends Node2D
var age := 0.0
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
	for i in range(8):
		var direction = Vector2.from_angle(i * TAU / 8)
		draw_line(direction * (7 + age * 50), direction * (14 + age * 110), Color(tint, 1.0 - age / 0.22), 3)
