extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	change_scene_to_file("res://main.tscn")
	await create_timer(0.3).timeout
	var p = current_scene.get_node("Player")
	p.invincible_timer = 0
	p.get_node("Weapons").set_physics_process(false)
	for i in range(2):
		var e = load("res://enemy.tscn").instantiate()
		e.set_script(load("res://arena/tactical_enemy.gd"))
		e.kind = "charger" if i == 0 else "caster"
		current_scene.add_child(e)
		e.global_position = p.global_position + Vector2(210+i*80,-120+i*180)
		e.state = "windup"
		e.clock = 0.55
		e.attack_direction = e.global_position.direction_to(p.global_position)
		e.set_physics_process(false)
	Input.action_press("ui_right")
	await create_timer(0.15).timeout
	Input.action_release("ui_right")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://arena-gameplay.png")
	# Portrait inspection uses the actual animated drawing, scaled for QA only.
	p.get_node("KingVisual").scale = Vector2(4,4)
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://king-portrait.png")
	quit()
