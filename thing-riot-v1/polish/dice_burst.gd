extends Node2D
var age := 0.0
var radius := 120.0
var pips := 1
var damage := 2
var royal := false
func _ready():
	z_index = 6
	add_to_group("dice_feedback")
	if get_tree().get_nodes_in_group("dice_feedback").size() > 8:
		queue_free()
func _process(delta):
	age += delta
	if age >= 0.7:
		queue_free()
	queue_redraw()
func _draw():
	var t := clampf(age/0.7,0,1)
	var tint = Color("ffe196") if royal else Color("a9e3ed")
	var r := radius*(1-pow(1-t,4))
	draw_arc(Vector2.ZERO,r,0,TAU,64,Color(tint,(1-t)*0.2),12*(1-t)+1,true)
	draw_arc(Vector2.ZERO,r,0,TAU,64,Color(tint,1-t),2.5,true)
	if royal:
		for i in range(6):
			var angle := i*TAU/6
			var point := Vector2.from_angle(angle)*r*0.65
			draw_set_transform(point,angle+t)
			var diamond := PackedVector2Array([Vector2(0,-7),Vector2(4,0),Vector2(0,7),Vector2(-4,0)])
			draw_colored_polygon(diamond,Color(tint,1-t))
		draw_set_transform(Vector2.ZERO)
	for i in range(pips*3):
		var dir = Vector2.from_angle(TAU*i/(pips*3))
		draw_line(dir*radius*t,dir*(radius*t+10),Color(tint,1-t),3)
	draw_string(ThemeDB.fallback_font,Vector2(-110,-25-t*32),("ROYAL " if royal else "")+"%d  •  %d DAMAGE" % [pips,damage],HORIZONTAL_ALIGNMENT_CENTER,220,20,Color(1,0.95,0.8,1-t))
