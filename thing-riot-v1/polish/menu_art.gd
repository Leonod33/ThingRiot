extends Control
func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw():
	draw_rect(Rect2(0,0,1280,800),Color("111c2f"))
	for x in range(40,1280,80):
		for y in range(40,800,80):
			draw_circle(Vector2(x,y),1,Color("304057"))
	for x in [140,1140]:
		draw_arc(Vector2(x,380),88,0,TAU,64,Color("57607a"),1.5,true)
		draw_arc(Vector2(x,380),96,-PI*0.8,PI*0.1,32,Color("d4ab66"),3,true)
		draw_line(Vector2(x,110),Vector2(x,240),Color("57607a"),1)
		draw_line(Vector2(x,520),Vector2(x,660),Color("57607a"),1)
	draw_set_transform(Vector2(140,380),-0.15,Vector2(2.5,2.5))
	var crown := PackedVector2Array([Vector2(-22,-16),Vector2(-11,-4),Vector2(0,-23),Vector2(11,-4),Vector2(22,-16),Vector2(17,18),Vector2(-17,18)])
	draw_colored_polygon(crown,Color("f2cc7e"))
	draw_line(Vector2(-16,12),Vector2(16,12),Color("fff4c7"),2)
	draw_circle(Vector2(0,7),3,Color("5fb4d7"))
	draw_set_transform(Vector2(1140,380),0.15,Vector2(2.5,2.5))
	draw_rect(Rect2(-20,-20,40,40),Color("fff0ce"))
	for x in [-9,9]:
		for y in [-10,0,10]:
			draw_circle(Vector2(x,y),3,Color("25364f"))
