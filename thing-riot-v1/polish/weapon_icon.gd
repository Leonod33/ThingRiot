extends Control
const CROWN = preload("res://assets/midnight/weapons/crown.svg")
const BISCUIT = preload("res://assets/midnight/weapons/biscuit.svg")
const DIE = preload("res://assets/midnight/weapons/die.svg")
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
			draw_texture_rect(CROWN,Rect2(-21,-20,42,37),false,Color.WHITE if active else Color(0.4,0.47,0.55,0.65))
		"biscuit":
			draw_texture_rect(BISCUIT,Rect2(-19,-21,38,41),false,Color.WHITE if active else Color(0.4,0.47,0.55,0.65))
		"dice":
			draw_texture_rect(DIE,Rect2(-22,-22,44,43),false,Color.WHITE if active else Color(0.4,0.47,0.55,0.65))
			for x in [-8,8]:
				for y in [-10,-2,6]:
					draw_circle(Vector2(x,y),2,Color("20283b"))
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(0,-17),Vector2(15,0),Vector2(0,17),Vector2(-15,0)]),tint)
			draw_line(Vector2(-6,0),Vector2(6,0),Color("20283b"),3)
			draw_line(Vector2(0,-6),Vector2(0,6),Color("20283b"),3)
