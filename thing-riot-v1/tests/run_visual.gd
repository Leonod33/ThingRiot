extends SceneTree
# Isolated visual fixture; never changes production timing, health or spawns.
func _initialize():
	call_deferred("run")
func run():
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	var p = current_scene.get_node("Player")
	p.set_physics_process(false)
	p.invincible_timer = 0
	var weapons = p.get_node("Weapons")
	weapons.set_physics_process(false)
	weapons.muted = true
	var director = current_scene.get_node("RunDirector")
	director.set_process(false)
	director.elapsed = 421
	director.start_boss()
	var boss = director.boss
	boss.set_physics_process(false)
	boss.global_position = p.global_position + Vector2(250,40)
	boss.hp = 100
	boss.attacks = 4
	boss.stamp_attack()
	for stamp in get_nodes_in_group("boss_stamps"):
		stamp.set_physics_process(false)
		stamp.age = 0.6
		stamp.queue_redraw()
	weapons.fire_dice()
	var die = get_nodes_in_group("loaded_dice")[-1]
	die.set_physics_process(false)
	die.global_position = p.global_position + Vector2(80,-80)
	die.pips = 6
	die.queue_redraw()
	director.update_hud()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://step4-boss.png")
	director.discover("Royal Crumble",5)
	director.discover("Royal Wager",1)
	for upgrade in ["High Roller","Extra Crown","High Roller","Swift Boots","Quick Throw"]:
		director.record_upgrade(upgrade)
	director.elapsed = 481
	director.kills = 302
	director.finish(true)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://step4-results.png")
	print("STEP4 VISUALS: ",OS.get_user_data_dir())
	quit()
