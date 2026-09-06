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
	draw_arc(Vector2.ZERO,radius*minf(1,t*3),0,TAU,48,Color(tint,1-t),4)
	for i in range(pips*3):
		var dir = Vector2.from_angle(TAU*i/(pips*3))
		draw_line(dir*radius*t,dir*(radius*t+10),Color(tint,1-t),3)
	draw_string(ThemeDB.fallback_font,Vector2(-110,-25-t*32),("ROYAL " if royal else "")+"%d  •  %d DAMAGE" % [pips,damage],HORIZONTAL_ALIGNMENT_CENTER,220,20,Color(1,0.95,0.8,1-t))
