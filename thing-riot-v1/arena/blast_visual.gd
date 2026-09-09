extends Node2D
var radius := 170.0
var age := 0.0
func _ready():
	z_index = 4
	add_to_group("blast_feedback")
	if get_tree().get_nodes_in_group("blast_feedback").size() > 16:
		queue_free()
func _process(delta):
	age += delta
	if age > 0.5:
		queue_free()
	queue_redraw()
func _draw():
	var t := clampf(age/0.5,0,1)
	var r := radius*(1-pow(1-t,4))
	if t < 0.22:
		draw_circle(Vector2.ZERO,r*0.5,Color(1,0.94,0.75,(1-t/0.22)*0.4))
	draw_arc(Vector2.ZERO,r,0,TAU,64,Color(0.96,0.81,0.52,(1-t)*0.25),12*(1-t)+1,true)
	draw_arc(Vector2.ZERO,r,0,TAU,64,Color(1,0.94,0.77,1-t),2.5,true)
	for i in range(12):
		var direction := Vector2.from_angle(i*2.39996)
		var point := direction*r*(0.55+float(i%3)*0.11)+Vector2(0,t*t*30)
		draw_set_transform(point,t*4+i)
		draw_rect(Rect2(-4,-2,8,4),Color(0.82,0.65,0.4,1-t))
		draw_line(Vector2(-4,-2),Vector2(4,-2),Color(1,0.9,0.66,1-t),1)
