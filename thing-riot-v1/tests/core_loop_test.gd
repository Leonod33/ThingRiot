extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func _initialize():
	call_deferred("run_tests")

func settle():
	await process_frame
	await process_frame

func run_tests():
	change_scene_to_file("res://main.tscn")
	await settle()
	var game = current_scene
	var player = game.get_node("Player")
	var picker = game.get_node("UILayer/UpgradePicker")
	var template = load("res://data/PlayerStats_default.tres")
	check(player.stats != template, "run owns its stats")
	player.add_xp(25) # thresholds 5, 8, 12 = three choices
	await settle()
	check(game.pending_level_ups == 3 and paused and picker.visible, "three levels queue")
	for remaining in [2, 1, 0]:
		picker.btn_a.pressed.emit()
		picker._choose(0) # duplicate callback in same frame must not consume next choice
		check(game.pending_level_ups == remaining, "one selection per choice")
		await settle()
		check(paused == (remaining > 0), "paused until all rewards selected")
		check(picker.visible == (remaining > 0), "next choice remains visible")
	check(template.attack_power == 1 and template.max_health == 6 and template.projectile_count == 1, "template untouched")
	player.max_health = 6
	player.stats.defense = 0.05
	player.current_health = 6.0
	player.invincible_timer = 0
	check(player.change_health(-1), "damage accepted")
	check(is_equal_approx(player.current_health, 5.05), "5% armor affects one-point hit")
	check(not player.change_health(-1) and is_equal_approx(player.current_health, 5.05), "invulnerability blocks repeat damage")
	check(player.change_health(1) and player.current_health == 6, "healing works during invulnerability")
	var potion = load("res://HealthPickup.tscn").instantiate()
	game.add_child(potion)
	player.current_health = 3.0
	potion._on_body_entered(player)
	potion._on_body_entered(player)
	check(player.current_health == 4.0, "health potion heals exactly once during immunity")
	await settle()
	player.stats.max_health = 7
	player.max_health = 7
	game.get_node("UILayer/HUD/HBoxContainer").update_hearts()
	check(game.get_node("UILayer/HUD/HBoxContainer").get_child_count() == 4, "odd max health has visible extra heart")
	player.stats.projectile_count = 6
	player.stats.defense = 0.8
	player.stats.attack_speed = 0.05
	player.stats.luck = 1.0
	picker.player = player
	for id in ["proj_1", "def_5", "rate_10", "luck_10"]:
		check(not picker._is_available(id), "capped upgrade excluded: " + id)
	var prop = load("res://DestructibleProp.tscn").instantiate()
	game.add_child(prop)
	check(is_equal_approx(prop.effective_drop_chance(), 0.70), "luck improves crate drops")
	prop.drop_chance = 1.0
	var children_before = game.get_child_count()
	prop.take_damage(100)
	prop.take_damage(100)
	await settle()
	check(game.get_child_count() == children_before, "one crate replaced by exactly one drop")
	var enemy = load("res://enemy.tscn").instantiate()
	game.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(300,0)
	enemy.apply_knockback(player.global_position, 200)
	check(enemy.knockback_velocity.x == 200, "outgoing knockback affects enemy")
	children_before = game.get_child_count()
	enemy.take_damage(100)
	enemy.take_damage(100)
	await settle()
	check(game.get_child_count() == children_before, "one enemy replaced by exactly one XP gem")
	var bullet_a = load("res://crown_bullet.tscn").instantiate()
	var bullet_b = load("res://crown_bullet.tscn").instantiate()
	bullet_b.size_multiplier = 2
	game.add_child(bullet_a)
	game.add_child(bullet_b)
	check(bullet_a.colshape.shape.size == Vector2(29,20) and bullet_b.colshape.shape.size == Vector2(58,40), "projectile collision shapes independent")
	var target = load("res://enemy.tscn").instantiate()
	game.add_child(target)
	target.hp = 10
	bullet_a._on_body_entered(target)
	bullet_a._on_area_entered(target.get_node("DamageArea"))
	check(target.hp == 9, "body and hurtbox cannot double-hit")
	var gem = load("res://pickups/XPGem.tscn").instantiate()
	game.add_child(gem)
	var xp_before = player.xp
	gem._on_body_entered(player)
	gem._on_body_entered(player)
	check(player.xp == xp_before + 1, "XP pickup awarded once")
	game._toggle_pause()
	check(paused, "pause opens")
	var event := InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	game.pause_panel._unhandled_input(event)
	check(not paused, "pause key resumes")
	player.die()
	player.die()
	await settle()
	check(current_scene.name == "GameOverScreen" and not paused, "death transitions once")
	current_scene._on_restart_button_pressed()
	await settle()
	check(current_scene.scene_file_path == "res://title_screen.tscn", "restart goes to title")
	current_scene._start_game()
	await settle()
	player = current_scene.get_node("Player")
	check(player.level == 1 and player.xp == 0 and player.current_health == 6 and player.stats.defense == 0 and player.stats.projectile_count == 1, "fresh run resets all gameplay state")
	print("CORE LOOP: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
