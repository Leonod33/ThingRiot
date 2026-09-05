# Rendered QA fixture only: tough enemies make chains observable.
extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	change_scene_to_file("res://main.tscn")
	await create_timer(0.3).timeout
	var p = current_scene.get_node("Player")
	p.invincible_timer = 100
	for i in range(12):
		var e = load("res://enemy.tscn").instantiate()
		current_scene.add_child(e)
		e.global_position = p.global_position + Vector2(220 + (i % 4) * 50, -90 + (i / 4) * 60)
		e.hp = 100
	await create_timer(1.5).timeout
	Input.action_press("ui_down")
	await create_timer(0.5).timeout
	Input.action_release("ui_down")
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://royal-gameplay.png")
	print("VISUAL_COMBOS:", p.get_node("Weapons").combo_count)
	p.add_xp(5)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://royal-upgrades.png")
	quit()
