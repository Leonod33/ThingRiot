extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, title: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(title)
func _initialize():
	call_deferred("run_checks")
func settle():
	await process_frame
	await process_frame
	await physics_frame
func run_checks():
	set_meta("music_on",false)
	set_meta("impact_on",false)
	change_scene_to_file("res://main.tscn")
	await settle()
	var game = current_scene
	var p = game.get_node("Player")
	var run = game.get_node("RunDirector")
	var feedback = game.get_node("Feedback")
	game.get_node("EnemySpawner").set_process(false)
	run.set_process(false)
	p.get_node("Weapons").set_physics_process(false)
	check(not game.get_node("UILayer/HUD").visible,"legacy HUD hidden")
	check(feedback.voices.launch.size() == 3 and feedback.voices.impact.size() == 3,"routine audio bounded")
	check(feedback.voices.damage.size() == 1 and feedback.voices.signature.size() == 1,"damage and signature voices reserved")
	feedback.hurt()
	var hurt_voice = feedback.voices.damage[0]
	var hurt_stream = hurt_voice.stream
	for kind in ["crunch","crown_hit","clack","dice","six"]:
		feedback.sound(kind)
	check(hurt_voice.stream == hurt_stream and hurt_stream == feedback.sounds.hurt,"routine and signature audio cannot replace hurt stream")
	check(feedback.duck_time > 0,"important feedback ducks background mix")
	p.invincible_timer = 1.5
	p.get_node("KingVisual")._process(0.01)
	check(p.get_node("KingVisual").modulate.a == 1,"hit King stays opaque")
	var bolt = load("res://arena/enemy_bolt.gd").new()
	game.add_child(bolt)
	check(bolt.z_index > p.z_index and p.z_index > 5,"hostile shots remain above King and friendly shots")
	bolt.queue_free()
	run.start_boss()
	var boss = run.boss
	boss.set_physics_process(false)
	boss.take_damage(1)
	check(boss.flash_time > 0,"boss damage flashes")
	boss.stamp_attack()
	check(get_nodes_in_group("boss_stamps").size() > 0 and boss.stamp_pose > 0,"claw anticipation accompanies real warnings")
	boss.take_damage(1000)
	boss.take_damage(1000)
	check(run.victory_pending and not run.ended,"boss death begins guarded presentation")
	check(not p.is_physics_processing() and not p.get_node("Weapons").is_physics_processing(),"ending stops combat input")
	for stamp in get_nodes_in_group("boss_stamps"):
		check(not stamp.is_physics_processing(),"ending disables stamp damage immediately")
	game._on_player_level_up(9)
	check(game.pending_level_ups == 0,"ending rejects queued upgrade interruption")
	await create_timer(1.8).timeout
	await settle()
	check(current_scene.name == "GameOverScreen" and current_scene.summary.victory,"ending produces victory results")
	change_scene_to_file("res://main.tscn")
	await settle()
	check(not current_scene.get_node("RunDirector").victory_pending and Engine.time_scale == 1,"restart clears ending state and impact timing")
	print("PRESENTATION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
