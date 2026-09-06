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
func enemy_at(pos: Vector2, kind: String):
	var enemy = load("res://enemy.tscn").instantiate()
	if not kind.is_empty():
		enemy.set_script(load("res://arena/tactical_enemy.gd"))
		enemy.kind = kind
	current_scene.add_child(enemy)
	enemy.global_position = pos
	enemy.set_physics_process(false)
	return enemy
func run_tests():
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	var p = current_scene.get_node("Player")
	p.set_physics_process(false)
	p.get_node("Weapons").set_physics_process(false)
	current_scene.get_node("EnemySpawner").set_process(false)
	check(p.has_node("KingVisual") and not p.get_node("Sprite2D").visible, "new king replaces old sprite")
	check(p.get_node("CollisionShape2D").shape.radius == 14 and p.get_node("CollisionShape2D").scale == Vector2.ONE, "compact king has matching foot collision")
	var spawner = current_scene.get_node("PropSpawner")
	var origin = p.global_position + Vector2(0,1800)
	var a = spawner.spawn_crate(origin, true)
	var b = spawner.spawn_crate(origin + Vector2(100,0), true)
	var far = enemy_at(origin + Vector2(400,0), "")
	var near = enemy_at(origin + Vector2(30,0), "")
	near.hp = 20
	a.take_damage(10)
	check(a.armed and not a.exploded and not b.armed, "damage arms fuse without instant blast")
	a._physics_process(0.1)
	check(not a.exploded, "fuse gives warning interval")
	a.detonate()
	check(near.hp == 14 and far.hp == 2, "blast only damages nearby enemies")
	check(b.armed, "blast starts neighboring crate fuse")
	a.detonate()
	check(near.hp == 14, "explosion applies damage once")
	b.detonate()
	check(near.hp == 8, "second crate completes bounded chain")
	var bumper = spawner.spawn_bumper(p.global_position - Vector2(10,0))
	await physics_frame
	await physics_frame
	bumper._physics_process(0.01)
	check(p.knockback_vector.x > 0 and bumper.bounce_count == 1, "bumper launches king away")
	bumper._physics_process(0.01)
	check(bumper.bounce_count == 1, "bumper cooldown prevents repeated contact")
	var charger = enemy_at(p.global_position + Vector2(200,0), "charger")
	charger.clock = 0
	charger._physics_process(0.01)
	check(charger.state == "windup" and charger.velocity.length() == 0, "charger stops to warn")
	var locked = charger.attack_direction
	p.global_position.y += 100
	charger._physics_process(0.5)
	check(charger.state == "windup" and charger.attack_direction == locked, "charge direction stays locked while player dodges")
	charger._physics_process(0.6)
	charger._physics_process(0.01)
	check(charger.state == "charge" and charger.velocity.length() > 400, "charger attacks after warning")
	charger.coat_with_crumbs()
	charger._physics_process(0.01)
	check(charger.velocity.length() < 250, "crumbs slow charge")
	charger._physics_process(0.6)
	check(charger.state == "recover", "charge ends with recovery")
	var caster = enemy_at(p.global_position + Vector2(300,0), "caster")
	caster.clock = 0
	var bolts_before = get_nodes_in_group("enemy_bolts").size()
	caster._physics_process(0.01)
	check(caster.state == "windup" and get_nodes_in_group("enemy_bolts").size() == bolts_before, "caster warns before shot")
	caster._physics_process(1.1)
	check(get_nodes_in_group("enemy_bolts").size() == bolts_before + 1, "caster fires one bolt after warning")
	var bolt = get_nodes_in_group("enemy_bolts")[-1]
	bolt.global_position = p.global_position - Vector2(50,0)
	bolt.direction = Vector2.RIGHT
	p.invincible_timer = 0
	var health = p.current_health
	bolt._physics_process(0.3)
	bolt._physics_process(0.3)
	check(p.current_health == health - 1, "fast enemy bolt hits once with swept collision")
	var doomed = enemy_at(p.global_position + Vector2(150,0), "caster")
	doomed.clock = 0
	doomed._physics_process(0.01)
	doomed.take_damage(99)
	bolts_before = get_nodes_in_group("enemy_bolts").size()
	doomed._physics_process(2)
	check(get_nodes_in_group("enemy_bolts").size() == bolts_before, "death interrupts enemy attack")
	print("ARENA: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
