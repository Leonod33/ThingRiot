extends Node
const BOSS_TIME := 420.0
const WAVES := ["Royal welcome", "Charge of the clerks", "Paperwork patrol", "Lunch rush", "The audit", "Mandatory overtime", "Final notice"]
var elapsed := 0.0
var ended := false
var boss_started := false
var boss: Node2D
var kills := 0
var biggest_chain := 0
var combinations := {}
var upgrades := {}
var status: Label
var boss_bar: ProgressBar
var refresh := 0.0
var cleanup := 0.0
func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var canvas = CanvasLayer.new()
	add_child(canvas)
	status = Label.new()
	status.position = Vector2(420,16)
	status.size = Vector2(440,58)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size",20)
	status.add_theme_color_override("font_shadow_color", Color.BLACK)
	status.add_theme_constant_override("shadow_offset_x",2)
	status.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(status)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(440,76)
	boss_bar.size = Vector2(400,18)
	boss_bar.show_percentage = false
	boss_bar.hide()
	canvas.add_child(boss_bar)
	update_hud()
func _process(delta):
	if ended:
		return
	elapsed += delta
	cleanup -= delta
	if cleanup <= 0 and not boss_started:
		cleanup = 2.0
		var p = get_parent().get_node("Player")
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.global_position.distance_squared_to(p.global_position) > 2200.0 * 2200.0:
				e.queue_free()
	if elapsed >= BOSS_TIME and not boss_started:
		start_boss()
	refresh -= delta
	if refresh <= 0:
		refresh = 0.1
		update_hud()
func wave_index() -> int:
	return mini(6, int(elapsed / 60))
func is_break() -> bool:
	return not boss_started and fmod(elapsed,60.0) >= 50.0
func update_hud():
	var time = "%02d:%02d" % [int(elapsed)/60, int(elapsed)%60]
	if boss_started:
		status.text = time + "  •  THE BUREAUCRAB\nDodge the stamped forms. End the audit!"
		if is_instance_valid(boss):
			boss_bar.max_value = boss.max_hp
			boss_bar.value = maxi(0,boss.hp)
			boss_bar.show()
	else:
		status.text = time + "  •  " + WAVES[wave_index()] + "\n" + ("Breather: collect gems!" if is_break() else "Final audit at 07:00")
func start_boss():
	if boss_started or ended:
		return
	boss_started = true
	get_parent().get_node("EnemySpawner").set_process(false)
	# A clean boss entrance gives both stamp shapes room to be learned.
	for group in ["enemies", "enemy_bolts"]:
		for actor in get_tree().get_nodes_in_group(group):
			actor.queue_free()
	boss = preload("res://enemy.tscn").instantiate()
	boss.set_script(preload("res://run/bureaucrab.gd"))
	boss.director = self
	get_parent().add_child(boss)
	var p = get_parent().get_node("Player")
	var cam = p.get_node("Camera2D")
	var point = p.global_position + Vector2(0,-300)
	point.x = clampf(point.x,cam.limit_left+160,cam.limit_right-160)
	point.y = clampf(point.y,cam.limit_top+160,cam.limit_bottom-160)
	boss.global_position = point
	update_hud()
func discover(combo: String, chain: int):
	combinations[combo] = true
	biggest_chain = maxi(biggest_chain,chain)
func record_upgrade(title: String):
	upgrades[title] = upgrades.get(title,0) + 1
func finish(victory: bool):
	if ended:
		return
	ended = true
	var game = get_parent()
	var p = game.get_node("Player")
	var build: Array[String] = []
	for title in upgrades:
		build.append("%s ×%d" % [title,upgrades[title]])
	build.sort()
	get_tree().set_meta("riot_result", {
		"victory":victory, "elapsed":elapsed, "level":p.level,
		"kills":kills + (1 if victory else 0), "chain":biggest_chain,
		"combos":combinations.keys(), "build":build,
		"power":p.stats.attack_power, "crowns":p.stats.projectile_count,
		"defense":p.stats.defense})
	game.pending_level_ups = 0
	game.upgrade_picker.hide()
	game.pause_panel.close()
	get_tree().paused = true
	show_results.call_deferred()
func show_results():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://GameOverScreen.tscn")
