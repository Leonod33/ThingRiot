extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize():
	call_deferred("run")
func enemy_at(pos: Vector2):
	var e = load("res://enemy.tscn").instantiate()
	current_scene.add_child(e)
	e.global_position = pos
	e.hp = 100
	e.set_physics_process(false)
	return e
func run():
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	current_scene.get_node("RunDirector").set_process(false)
	var p = current_scene.get_node("Player")
	p.set_physics_process(false)
	p.invincible_timer = 100
	var w = p.get_node("Weapons")
	w.set_physics_process(false)
	w.muted = true
	current_scene.get_node("EnemySpawner").set_process(false)
	var origin = p.global_position + Vector2(0, 3000)
	var near = enemy_at(origin + Vector2(40,0))
	var far = enemy_at(origin + Vector2(40,150))
	var crate = current_scene.get_node("PropSpawner").spawn_crate(origin+Vector2(130,0), false)
	crate.drop_chance = 0
	var targets = [near]
	for i in range(140):
		targets.append(enemy_at(origin + Vector2(60+i*0.1,0)))
	await physics_frame
	await physics_frame
	w.fire(w.crown)
	var shot = get_nodes_in_group("riot_projectiles")[-1]
	shot.set_physics_process(false)
	shot.global_position = origin
	shot.direction = Vector2.RIGHT
	shot._physics_process(0.3)
	check(near.hp == 99, "swept query hits enemy once despite body and damage sensor")
	check(far.hp == 100, "exact narrow phase rejects distant targets")
	check(crate._hp == 1, "non-monitoring crate hurtbox remains queryable")
	check(targets.all(func(e): return e.hp == 99), "dense sweep hits all 141 enemies without query truncation")
	shot.global_position = origin
	shot._physics_process(0.3)
	check(near.hp == 99, "repeat outgoing pass is deduplicated")
	shot.begin_return()
	shot.global_position = origin
	shot.owner_player = near # Aim return through the already-hit enemy.
	shot._physics_process(0.1)
	check(near.hp == 98, "return pass still permits its own hit")
	# Query ordering must choose the nearer enemy even if the farther one was added first.
	var line = origin + Vector2(0,400)
	var second = enemy_at(line+Vector2(130,0))
	var first = enemy_at(line+Vector2(40,0))
	await physics_frame
	await physics_frame
	w.fire(w.biscuit)
	var biscuit = get_nodes_in_group("riot_projectiles")[-1]
	biscuit.set_physics_process(false)
	biscuit.global_position = line
	biscuit.direction = Vector2.RIGHT
	biscuit._physics_process(0.4)
	check(first.hp == 99 and second.hp == 100, "biscuit selects nearest swept contact")
	var event = InputEventKey.new()
	event.physical_keycode = KEY_F3
	event.pressed = true
	w._unhandled_input(event)
	w._process(0.5)
	check(w.performance_label.visible and "Enemies:" in w.performance_label.text, "F3 enables sampled performance counters")
	w._unhandled_input(event)
	check(not w.performance_label.visible, "F3 hides performance counters")
	print("COLLISION QUERIES: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
