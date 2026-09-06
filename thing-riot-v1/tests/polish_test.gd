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
func run_tests():
	set_meta("music_on",false)
	set_meta("sound_on",false)
	set_meta("impact_on",false)
	change_scene_to_file("res://main.tscn")
	await settle()
	var game = current_scene
	var p = game.get_node("Player")
	var w = p.get_node("Weapons")
	game.get_node("EnemySpawner").set_process(false)
	game.get_node("RunDirector").set_process(false)
	p.set_physics_process(false)
	w.set_physics_process(false)
	check(w.equipped_names() == ["Returning Crown"],"start crown only")
	var picker = game.get_node("UILayer/UpgradePicker")
	picker.open_for(p)
	var offered := []
	for choice in picker.current_choices:
		offered.append(choice.id)
	check(offered.has("unlock_dice") and offered.has("unlock_biscuit"),"both weapons offered")
	check(not picker._is_available("dice_radius") and not picker._is_available("royal_chain"),"locked weapon upgrades excluded")
	picker._choose(offered.find("unlock_dice"))
	check(w.equipped.dice and not w.equipped.biscuit,"chosen weapon unlocks alone")
	check(not picker._is_available("unlock_dice") and picker._is_available("dice_radius"),"unlock cannot repeat; its upgrades become available")
	paused = false
	w.aim = Vector2.RIGHT
	w.fire_dice()
	var die = get_nodes_in_group("loaded_dice")[-1]
	die.set_physics_process(false)
	die.pips = 1
	w.fire(w.crown)
	var crown = get_nodes_in_group("riot_projectiles")[-1]
	crown.set_physics_process(false)
	crown.strike(die)
	crown.begin_return()
	crown.strike(die)
	check(die.state == "rolling" and not die.finished and die.pips == 1,"both crown passes ignore rolling dice")
	var radius := 0.0
	for face in range(1,7):
		die.pips = face
		check(die.blast_radius() > radius,"face %d increases blast radius" % face)
		radius = die.blast_radius()
	die._physics_process(1.0)
	check(die.state == "ready","die settles before arming")
	w.fire(w.biscuit)
	var biscuit = get_nodes_in_group("riot_projectiles")[-1]
	biscuit.set_physics_process(false)
	biscuit.strike(die)
	check(die.state == "ready" and not biscuit.finished,"biscuits pass settled dice")
	crown.returning = false
	crown.strike(die)
	check(die.state == "ready","outward crown cannot cash settled die")
	var enemy = load("res://enemy.tscn").instantiate()
	game.add_child(enemy)
	enemy.global_position = die.global_position + Vector2(40,0)
	enemy.hp = 100
	enemy.set_physics_process(false)
	await settle()
	die.pips = 1
	crown.begin_return()
	crown.strike(die)
	check(die.pips == 6 and die.royal and not die.finished and enemy.hp == 100,"Royal Six visibly reveals before damage")
	die._physics_process(0.3)
	check(enemy.hp == 100,"reveal has a readable duration")
	die._physics_process(0.26)
	check(enemy.hp == 100-die.damage-6,"revealed six determines actual damage")
	var hp = enemy.hp
	die.detonate()
	check(enemy.hp == hp,"blast cannot apply twice")
	enemy.global_position = p.global_position + Vector2(40,0)
	p.invincible_timer = 0
	var health = p.current_health
	check(p.change_health(-1),"first hit accepted")
	check(not p.change_health(-1) and p.current_health == health-1,"overlapping hit blocked")
	check(p.invincible_timer == 1.6 and p.escape_timer > 0,"hit starts shield and escape window")
	check(enemy.knockback_velocity.length() > 400,"hit pushes surrounding enemy away")
	set_meta("impact_on",true)
	var feedback = game.get_node("Feedback")
	feedback.hurt()
	check(Engine.time_scale < 1,"impact pause starts")
	paused = true
	await create_timer(0.1,true,false,true).timeout
	check(Engine.time_scale == 1,"impact pause restores speed even while paused")
	paused = false
	change_scene_to_file("res://main.tscn")
	await settle()
	check(current_scene.get_node("Player/Weapons").equipped_names() == ["Returning Crown"],"restart resets unlocks")
	print("POLISH: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
