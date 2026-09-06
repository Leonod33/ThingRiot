extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
func _initialize():
	call_deferred("run_tests")
func run_tests():
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	var player = game.get_node("Player")
	var weapons = player.get_node("Weapons")
	weapons.set_physics_process(false)
	weapons.muted = true
	game.get_node("EnemySpawner").set_process(false)
	player.set_physics_process(false)
	var positions = game.get_node("PropSpawner").placed_positions
	var farthest := 0.0
	for point in positions:
		farthest = maxf(farthest, player.global_position.distance_to(point))
	check(positions.size() >= 300 and farthest > 20000, "crates cover arena rather than spawn ring")
	weapons.crown_timer = 100.0
	weapons.biscuit_timer = 100.0
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	weapons._physics_process(0.0)
	check(weapons.manual, "right mouse enables manual aiming")
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	weapons._physics_process(0.0)
	check(not weapons.manual, "releasing mouse restores auto targeting")
	weapons.aim = Vector2.RIGHT
	weapons.fire(weapons.crown)
	var crown = get_nodes_in_group("riot_projectiles")[0]
	crown.set_physics_process(false)
	var before = crown.global_position
	crown._physics_process(0.1)
	check(crown.global_position.x > before.x, "crown travels outward")
	crown.begin_return()
	player.global_position.y += 150
	crown._physics_process(0.01)
	check(crown.direction.y > 0, "return follows moved player")
	var targets: Array[Node2D] = []
	for i in range(6):
		var enemy = load("res://enemy.tscn").instantiate()
		game.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.global_position = player.global_position + Vector2(100 + i * 45, 0)
		enemy.hp = 100
		enemy.coat_with_crumbs()
		targets.append(enemy)
	crown.returning = false
	crown.hits.clear()
	crown.global_position = targets[0].global_position
	for enemy in targets:
		crown.strike(enemy)
	check(crown.bounce_count == 3 and weapons.combo_count == 3, "chain limited to three ricochets")
	var hp = targets[0].hp
	crown.strike(targets[0])
	check(targets[0].hp == hp, "outgoing pass hits each target only once")
	crown.begin_return()
	crown.strike(targets[0])
	check(targets[0].hp == hp - 1, "return pass can hit same enemy once again")
	crown.strike(targets[0])
	check(targets[0].hp == hp - 1, "return does not repeatedly hit")
	weapons.fire(weapons.biscuit)
	var biscuit = get_nodes_in_group("riot_projectiles")[-1]
	biscuit.set_physics_process(false)
	biscuit.global_position = targets[1].global_position
	biscuit.burst()
	biscuit.burst()
	check(get_nodes_in_group("crumb_patches").size() == 1, "biscuit leaves one patch")
	var patch = get_nodes_in_group("crumb_patches")[0]
	await physics_frame
	await physics_frame
	await physics_frame
	targets[1].crumb_time = 0
	patch._physics_process(0.1)
	check(targets[1].crumb_time > 0, "patch coats enemies")
	targets[1].knockback_velocity = Vector2.ZERO
	targets[1]._physics_process(0.01)
	check(targets[1].velocity.length() < targets[1].speed * 0.5, "crumbs slow pursuit")
	targets[1].crumb_time = 0.001
	targets[1]._physics_process(0.1)
	check(is_equal_approx(targets[1].velocity.length(), float(targets[1].speed)), "slow expires")
	patch._physics_process(10)
	check(patch.is_queued_for_deletion(), "patch expires")
	for i in range(30):
		weapons.fire(weapons.crown)
	check(get_nodes_in_group("riot_projectiles").size() <= 48, "projectile population bounded")
	var picker = game.get_node("UILayer/UpgradePicker")
	picker._apply_crumb_radius(player)
	check(weapons.biscuit.patch_radius > 120 and load("res://weapons/biscuit.tres").patch_radius == 120, "weapon upgrades do not modify shared resource")
	print("WEAPONS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
