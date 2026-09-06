extends Node2D
# Original vector character, drawn in local pixels around a small foot hitbox.
var phase := 0.0
var facing := 1.0
var walking := 0.0
const INK = Color("252238")
func _process(delta):
	var p = get_parent()
	walking = clampf(p.velocity.length() / 260.0, 0, 1)
	phase += delta * (12.0 if walking > 0.1 else 2.0)
	if absf(p.velocity.x) > 15:
		facing = signf(p.velocity.x)
	modulate.a = 0.65 if p.invincible_timer > 0 and sin(phase * 5) > 0 else 1.0
	queue_redraw()
func shape(points: Array, colour: Color):
	var poly := PackedVector2Array(points)
	draw_colored_polygon(poly, colour)
	poly.append(poly[0])
	draw_polyline(poly, INK, 2.0, true)
func _draw():
	var shield: float = get_parent().invincible_timer
	if shield > 0:
		draw_arc(Vector2(0,-17),36,-PI/2,-PI/2+TAU*shield/1.6,40,Color("c5edff"),3.0,true)
		draw_arc(Vector2(0,-17),40,0,TAU,40,Color(0.7,0.9,1,0.3),1.0,true)
		for i in range(4):
			var tip := Vector2(0,-17)+Vector2.from_angle(PI/4+i*PI/2)*43
			draw_line(tip-Vector2(3,0),tip+Vector2(3,0),Color.WHITE,2)
	draw_set_transform(Vector2(0,4), 0, Vector2(1,0.3))
	draw_circle(Vector2.ZERO, 20, Color(0.05,0.08,0.12,0.3))
	var bob := sin(phase * 2) * walking * 1.5
	draw_set_transform(Vector2(0,bob), 0, Vector2.ONE)
	var sway := sin(phase) * (2 + walking * 4)
	shape([Vector2(-15,-29),Vector2(12,-28),Vector2(21+sway,0),Vector2(3,5),Vector2(-20+sway,0)], Color("3478a5"))
	draw_line(Vector2(-12,-20),Vector2(-14+sway,-1),Color("85c9e0"),2)
	for side in [-1,1]:
		var step := sin(phase + (PI if side < 0 else 0)) * walking * 3
		draw_style_box(boot_style(), Rect2(Vector2(side*8-5,-2+step),Vector2(12,7)))
	shape([Vector2(-12,-26),Vector2(12,-26),Vector2(15,-3),Vector2(-15,-3)],Color("684681"))
	draw_line(Vector2(0,-23),Vector2(0,-4),Color("efc975"),2)
	draw_line(Vector2(-13,-7),Vector2(13,-7),Color("efc975"),3)
	for y in [-19,-13]:
		draw_circle(Vector2(4,y),1.5,Color("ffe3a0"))
	for side in [-1,1]:
		var hand := Vector2(side*17,-17 + sin(phase + side)*walking*3)
		draw_line(Vector2(side*10,-25),hand,INK,8)
		draw_line(Vector2(side*10,-25),hand,Color("684681"),5)
		draw_circle(hand,4.5,INK)
		draw_circle(hand,3.3,Color("fff3d4"))
	draw_circle(Vector2(0,-32),13,INK)
	draw_circle(Vector2(0,-32),11.5,Color("eebc8b"))
	# Ermine collar and a magnificent moustache.
	for x in [-10,-5,0,5,10]:
		draw_circle(Vector2(x,-23),3.2,Color("fff3d4"))
	var look := facing * 1.5
	for x in [-5,5]:
		draw_circle(Vector2(x+look,-34),1.7,INK)
		draw_line(Vector2(x-2+look,-38),Vector2(x+2+look,-39),INK,2)
	draw_circle(Vector2(look,-30),3,Color("d98c69"))
	shape([Vector2(-11,-30),Vector2(-5,-27),Vector2(0,-29),Vector2(5,-27),Vector2(11,-30),Vector2(7,-24),Vector2(0,-25),Vector2(-7,-24)],Color("fff3d4"))
	shape([Vector2(-13,-41),Vector2(-16,-53),Vector2(-7,-47),Vector2(0,-58),Vector2(7,-47),Vector2(16,-53),Vector2(13,-41)],Color("edb94e"))
	draw_line(Vector2(-12,-43),Vector2(12,-43),Color("fff0aa"),3)
	shape([Vector2(0,-49),Vector2(3,-45),Vector2(0,-42),Vector2(-3,-45)],Color("5bbbd1"))
	for point in [Vector2(-16,-53),Vector2(0,-58),Vector2(16,-53)]:
		draw_circle(point,2.2,Color("fff0aa"))
func boot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = INK
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	return style
