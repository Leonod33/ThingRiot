extends Control
var kind := "crown"
var active := true
func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(44,44)
func _draw():
	var tint := Color("e7bd70") if active else Color("667083")
	draw_set_transform(size/2,0,Vector2.ONE)
	match kind:
		"crown":
			draw_colored_polygon(PackedVector2Array([Vector2(-17,-10),Vector2(-8,-3),Vector2(0,-17),Vector2(8,-3),Vector2(17,-10),Vector2(13,12),Vector2(-13,12)]),tint)
			draw_line(Vector2(-11,7),Vector2(11,7),Color("fff0c5") if active else tint,2)
		"biscuit":
			draw_circle(Vector2.ZERO,16,tint)
			for v in [Vector2(-6,-5),Vector2(7,-3),Vector2(1,7)]:
				draw_circle(v,2.5,Color("443549"))
		"dice":
			draw_style_box(preload("res://polish/royal_theme.gd").box(Color("fff0c5") if active else tint,Color("20283b")),Rect2(-18,-18,36,36))
			for x in [-8,8]:
				for y in [-9,0,9]:
					draw_circle(Vector2(x,y),2.2,Color("20283b"))
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(0,-17),Vector2(15,0),Vector2(0,17),Vector2(-15,0)]),tint)
			draw_line(Vector2(-6,0),Vector2(6,0),Color("20283b"),3)
			draw_line(Vector2(0,-6),Vector2(0,6),Color("20283b"),3)
