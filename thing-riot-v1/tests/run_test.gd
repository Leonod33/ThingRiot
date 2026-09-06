extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize():
	call_deferred("run_tests")
func settle():
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame
	await physics_frame
func run_tests():
	change_scene_to_file("res://main.tscn")
	await settle()
	var game = current_scene
	var p = game.get_node("Player")
	var run = game.get_node("RunDirector")
	var spawner = game.get_node("EnemySpawner")
	var w = p.get_node("Weapons")
	p.set_physics_process(false)
	spawner.set_process(false)
	w.set_physics_process(false)
	w.muted = true
	run.set_process(false)
	check(run.wave_index() == 0 and not run.boss_started,"run begins in opening wave")
	for minute in range(7):
		run.elapsed = minute * 60
		check(run.wave_index() == minute and not run.is_break(),"wave index %d" % minute)
	run.elapsed = 55
	check(run.is_break(),"wave ends with collection break")
	var before = get_nodes_in_group("enemies").size()
	spawner._timer = 0
	spawner._process(1)
	check(get_nodes_in_group("enemies").size() == before,"breather suppresses spawning")
	run.elapsed = 120
	spawner._process(1)
	check(get_nodes_in_group("enemies").size() > before,"next wave resumes spawning")
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await settle()
	var enemy = load("res://enemy.tscn").instantiate()
	game.add_child(enemy)
	enemy.global_position = p.global_position + Vector2(150,0)
	enemy.hp = 100
	enemy.set_physics_process(false)
	w.aim = Vector2.RIGHT
	w.fire_dice()
	var die = get_nodes_in_group("loaded_dice")[-1]
	die.set_physics_process(false)
	die.global_position = enemy.global_position
	check(die.pips >= 1 and die.pips <= 6,"die rolls legal face")
	await settle()
	die.travelled = die.spec.reach
	die._physics_process(1.5)
	die._physics_process(2.1)
	check(enemy.hp < 100 and enemy.hp >= 93,"ordinary die applies bounded rolled damage")
	var hp = enemy.hp
	die.cash_out(false)
	check(enemy.hp == hp,"die explosion is idempotent")
	w.fire_dice()
	die = get_nodes_in_group("loaded_dice")[-1]
	die.set_physics_process(false)
	die.global_position = enemy.global_position
	w.fire(w.crown)
	var crown = get_nodes_in_group("riot_projectiles")[-1]
	crown.set_physics_process(false)
	await settle()
	die.global_position = enemy.global_position - Vector2(80,0)
	await settle()
	die.state = "ready"
	crown.begin_return()
	crown.global_position = die.global_position + Vector2(100,0)
	crown._physics_process(0.2)
	die._physics_process(0.56)
	check(die.pips == 6 and enemy.hp == hp-7,"crown cashes die into guaranteed six")
	check(run.combinations.has("Royal Wager"),"second combination is discovered")
	w.celebrate_combo(4)
	check(run.combinations.size() == 2 and run.biggest_chain == 4,"both combinations and biggest chain recorded")
	var picker = game.get_node("UILayer/UpgradePicker")
	picker._apply_dice_radius(p)
	check(w.dice.patch_radius > 110 and load("res://weapons/dice.tres").patch_radius == 110,"dice upgrades are per run")
	run.record_upgrade("High Roller")
	var props = game.get_node("PropSpawner")
	var a = props.spawn_crate(p.global_position + Vector2(1000,0),true)
	var b = props.spawn_crate(p.global_position + Vector2(1100,0),true)
	a.chain_depth = 6
	a.detonate()
	check(not b.armed and run.biggest_chain == 6,"bomb chains stop after six links and update results")
	# Real pause pauses the director, not just its display.
	run.set_process(true)
	paused = true
	var stopped = run.elapsed
	await create_timer(0.05,true).timeout
	check(run.elapsed == stopped,"run clock pauses")
	paused = false
	run.set_process(false)
	run.elapsed = 419.9
	run._process(0.2)
	var boss = run.boss
	boss.set_physics_process(false)
	check(run.boss_started and not spawner.is_processing(),"boss replaces waves at seven minutes")
	run.start_boss()
	check(get_nodes_in_group("boss").size() == 1,"boss spawns only once")
	boss.hp = 1
	for i in range(4):
		boss.stamp_attack()
		var stamps = get_nodes_in_group("boss_stamps")
		check(stamps.size() == 1,"teach separate stamp %d before combining" % i)
		for stamp in stamps:
			stamp.queue_free()
		await settle()
	boss.stamp_attack()
	check(get_nodes_in_group("boss_stamps").size() == 2,"boss combines learned shapes at half health")
	var stamp = get_nodes_in_group("boss_stamps")[0]
	stamp.set_physics_process(false)
	p.invincible_timer = 0
	var health = p.current_health
	stamp._physics_process(0.5)
	check(p.current_health == health,"stamp warns before damage")
	p.global_position += Vector2(500,500)
	stamp._physics_process(1)
	check(p.current_health == health,"leaving locked rectangle avoids damage")
	var hit = load("res://run/stamp.gd").new()
	game.add_child(hit)
	hit.global_position = p.global_position
	hit.set_physics_process(false)
	hit._physics_process(1.3)
	hit._physics_process(1.3)
	check(p.current_health == health-2,"stamp damages once")
	boss.take_damage(1)
	await settle()
	check(current_scene.name == "GameOverScreen" and current_scene.summary.victory,"boss kill produces victory")
	check(current_scene.summary.combos.size() == 2 and current_scene.summary.build.has("High Roller ×1"),"results show discoveries and build")
	change_scene_to_file("res://main.tscn")
	await settle()
	game = current_scene
	p = game.get_node("Player")
	run = game.get_node("RunDirector")
	check(run.combinations.is_empty() and run.upgrades.is_empty() and run.elapsed < 1,"new run resets results and clock")
	p.die()
	p.die()
	await settle()
	check(not current_scene.summary.victory and not paused,"death produces single defeat screen")
	print("RUN: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
