extends Node2D
var radius := 170.0
var age := 0.0
func _ready():
	z_index = 4
func _process(delta):
	age += delta
	if age > 0.35:
		queue_free()
	queue_redraw()
func _draw():
	var r := radius * minf(1, age / 0.18)
	draw_arc(Vector2.ZERO,r,0,TAU,64,Color(1,0.87,0.55,1-age/0.35),5)
	for i in range(12):
		var direction = Vector2.from_angle(i*TAU/12)
		draw_line(direction*r*0.5,direction*r,Color(1,0.95,0.8,1-age/0.35),3)
