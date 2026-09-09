extends Node2D
var age := 0.0
var kind := "crown"
var tint := Color("fff0a0")
var lifetime := 0.28
func _ready():
	z_index = 3
	lifetime = 0.48 if kind == "paper" else 0.28
	add_to_group("polish_effects")
	if get_tree().get_nodes_in_group("polish_effects").size() > 32:
		queue_free()
func _process(delta):
	age += delta
	if age > lifetime:
		queue_free()
	queue_redraw()
func _draw():
	var t := clampf(age/lifetime,0,1)
	var ease := 1-pow(1-t,3)
	if kind in ["biscuit","paper"]:
		for i in range(7):
			var direction := Vector2.from_angle(i*2.39996)
			var point := direction*(6+ease*(24+i%3*9))+Vector2(0,t*t*24)
			draw_set_transform(point,age*(6+i)+i)
			var size := Vector2(5,8) if kind == "paper" else Vector2(5+i%3,3+i%2)
			draw_rect(Rect2(-size/2+Vector2(1,2),size),Color(0.08,0.12,0.18,(1-t)*0.25))
			draw_rect(Rect2(-size/2,size),Color(Color("d9dece") if kind == "paper" else Color("e6b775"),1-t))
			if kind == "paper":
				draw_line(Vector2(-1,-2),Vector2(2,-2),Color(0.3,0.4,0.45,1-t),1)
			draw_line(-size/2,Vector2(size.x/2,-size.y/2),Color(1,0.96,0.79,1-t),1)
		return
	if t < 0.28:
		draw_circle(Vector2.ZERO,12*(1-t/0.28),Color(1,0.95,0.77,(1-t/0.28)*0.8))
	for i in range(6):
		var direction := Vector2.from_angle(i*TAU/6+0.2)
		var point := direction*(7+ease*22)
		var tip := point+direction*(12*(1-t))
		draw_line(point,tip,Color(0.91,0.74,0.44,1-t),3*(1-t),true)
		draw_line(point,tip,Color(1,0.99,0.87,1-t),1,true)
