extends SceneTree
# Fixed workload; no production stats or spawn pacing are changed.
class TickProbe extends Node:
	var starts := false
	var samples: Array[float] = []
	var start_probe: Node
	var started_at := 0
	func _physics_process(_delta):
		if starts:
			started_at = Time.get_ticks_usec()
		else:
			samples.append((Time.get_ticks_usec() - start_probe.started_at) / 1000.0)

func _initialize():
	call_deferred("run")
func run():
	seed(417)
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	var p = current_scene.get_node("Player")
	p.set_physics_process(false)
	p.invincible_timer = 1000
	current_scene.get_node("EnemySpawner").set_process(false)
	var weapons = p.get_node("Weapons")
	weapons.muted = true
	p.stats.attack_power = 0
	p.stats.projectile_count = 8
	p.stats.attack_speed = 0.3
	for i in range(180):
		var e = load("res://enemy.tscn").instantiate()
		e.set_script(load("res://arena/tactical_enemy.gd"))
		e.kind = "caster" if i % 3 != 0 else "charger"
		current_scene.add_child(e)
		e.global_position = p.global_position + Vector2.from_angle(i * 2.39996) * (260 + i % 180)
		e.hp = 100000
	for i in range(24):
		var patch = load("res://weapons/crumb_patch.gd").new()
		patch.duration = 100
		current_scene.add_child(patch)
		patch.global_position = p.global_position + Vector2.from_angle(i * 2.39996) * 340
	var start = TickProbe.new()
	start.starts = true
	start.process_physics_priority = -10000
	current_scene.add_child(start)
	var end = TickProbe.new()
	end.start_probe = start
	end.process_physics_priority = 10000
	current_scene.add_child(end)
	var last_frame = Time.get_ticks_usec()
	var physics: Array[float] = []
	var frames: Array[float] = []
	for i in range(420):
		await process_frame
		var now = Time.get_ticks_usec()
		if i > 60:
			frames.append((now - last_frame) / 1000.0)
		last_frame = now
	physics.assign(end.samples.slice(60))
	physics.sort()
	frames.sort()
	print("BENCHMARK enemies=", get_nodes_in_group("enemies").size(), " bolts=", get_nodes_in_group("enemy_bolts").size(), " shots=", get_nodes_in_group("riot_projectiles").size())
	print("SCRIPT TICK ms median=%.3f p95=%.3f | WALL FRAME median=%.3f p95=%.3f" % [physics[physics.size()/2], physics[int(physics.size()*0.95)], frames[frames.size()/2], frames[int(frames.size()*0.95)]])
	quit()
