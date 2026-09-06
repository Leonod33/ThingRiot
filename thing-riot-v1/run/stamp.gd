extends Node2D
var size := Vector2(120,320)
var warning := 1.25
var age := 0.0
var struck := false
var player: Node2D
func _ready():
	add_to_group("boss_stamps")
	z_index = 0
	player = get_tree().get_first_node_in_group("Player")
func _physics_process(delta):
	age += delta
	if not struck and age >= warning:
		struck = true
		var feedback = get_tree().current_scene.get_node_or_null("Feedback")
		if feedback:
			feedback.sound("stamp")
		if is_instance_valid(player) and not player.dead and Rect2(-size/2, size).has_point(to_local(player.global_position)):
			player.change_health(-2)
	if age >= warning + 0.35:
		queue_free()
	queue_redraw()
func _draw():
	var box := Rect2(-size/2,size)
	draw_rect(box, Color(0.12,0.1,0.19,0.7) if not struck else Color(1,0.86,0.55,0.65))
	draw_rect(box.grow(2),Color("20283b"),false,6)
	draw_rect(box, Color("fff0c5"), false, 3)
	if not struck:
		var amount := clampf(age / warning, 0, 1)
		draw_rect(Rect2(-size/2, Vector2(size.x * amount, 8)), Color("f5bd69"))
		# Repeated crosses communicate danger independently of hue.
		for y in range(int(-size.y/2)+28, int(size.y/2), 48):
			draw_line(Vector2(-8,y-8),Vector2(8,y+8),Color.WHITE,2)
			draw_line(Vector2(8,y-8),Vector2(-8,y+8),Color.WHITE,2)
	else:
		draw_line(Vector2(-size.x/3,0),Vector2(size.x/3,0),Color("28263d"),8)
