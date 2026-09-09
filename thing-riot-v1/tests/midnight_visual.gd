extends SceneTree
# Staged actors belong only to this fixture. Production health/spawns never change.
var p: Node2D
var weapons: Node2D
var director: Node
func _initialize():
	call_deferred("run")
func capture(label: String):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://midnight-"+label+".png")
func enemy_at(kind: String, point: Vector2):
	var e = load("res://enemy.tscn").instantiate()
	if kind != "clerk":
		e.set_script(load("res://arena/tactical_enemy.gd"))
		e.kind = kind
	current_scene.add_child(e)
	e.global_position = p.global_position+point
	e.set_physics_process(false)
	e.hp = 10000
	return e
func run():
	seed(417)
	set_meta("music_on",false)
	set_meta("sound_on",false)
	set_meta("impact_on",false)
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	p = current_scene.get_node("Player")
	p.set_physics_process(false)
	weapons = p.get_node("Weapons")
	weapons.set_physics_process(false)
	weapons.muted = true
	director = current_scene.get_node("RunDirector")
	director.set_process(false)
	current_scene.get_node("EnemySpawner").set_process(false)
	await capture("opening")
	weapons.equipped.biscuit = true
	weapons.equipped.dice = true
	director.elapsed = 193
	for i in range(22):
		var point := Vector2.from_angle(i*2.39996)*Vector2(220+i%4*87,120+i%5*39)
		var e = enemy_at(["clerk","clerk","charger","caster"][i%4],point)
		if i%4 == 0:
			e.coat_with_crumbs()
	var charger = enemy_at("charger",Vector2(310,-150))
	charger.state = "windup"
	charger.clock = 0.5
	charger.attack_direction = Vector2(-0.9,0.3).normalized()
	charger.queue_redraw()
	for pos in [Vector2(-120,90),Vector2(225,-40)]:
		var patch = load("res://weapons/crumb_patch.gd").new()
		current_scene.add_child(patch)
		patch.global_position = p.global_position+pos
	weapons.aim = Vector2.RIGHT
	weapons.fire(weapons.crown)
	var crown = get_nodes_in_group("riot_projectiles")[-1]
	crown.set_physics_process(false)
	crown.global_position = p.global_position+Vector2(160,-75)
	crown.age = 0.4
	for i in range(9):
		crown.trail.append(crown.global_position-Vector2(i*12,-sin(i*0.25)*20))
	crown.queue_redraw()
	weapons.fire_dice()
	var die = get_nodes_in_group("loaded_dice")[-1]
	die.set_physics_process(false)
	die.global_position = p.global_position+Vector2(120,120)
	die.pips = 6
	die.state = "six"
	die.royal = true
	die.fuse = 0.4
	die.queue_redraw()
	await create_timer(0.15).timeout
	await capture("combat")
	for i in range(6):
		var face = load("res://weapons/loaded_die.gd").new()
		face.spec = weapons.dice
		face.owner_player = p
		current_scene.add_child(face)
		face.set_physics_process(false)
		face.global_position = p.global_position+Vector2((i-2.5)*115,-200)
		face.pips = i+1
		face.state = "ready"
		face.fuse = 1.5
		face.queue_redraw()
	await capture("dice")
	for i in range(130):
		enemy_at(["clerk","charger","caster"][i%3],Vector2.from_angle(i*2.39996)*Vector2(90+i%13*35,50+i%11*21))
	p.invincible_timer = 1.5
	p.current_health = 4
	current_scene.get_node("Feedback").hurt()
	await capture("crowd")
	for node in get_nodes_in_group("enemies")+get_nodes_in_group("riot_projectiles")+get_nodes_in_group("crumb_patches"):
		node.queue_free()
	await process_frame
	p.invincible_timer = 0
	current_scene.get_node("Feedback").hurt_time = 0
	director.elapsed = 421
	director.start_boss()
	var boss = director.boss
	boss.set_physics_process(false)
	boss.global_position = p.global_position+Vector2(250,30)
	boss.hp = 100
	boss.attacks = 4
	boss.stamp_attack()
	for stamp in get_nodes_in_group("boss_stamps"):
		stamp.set_physics_process(false)
		stamp.age = 0.6
		stamp.queue_redraw()
	await capture("boss")
	current_scene.get_node("UILayer/UpgradePicker").open_for(p)
	await capture("cards")
	print("MIDNIGHT VISUALS: ",OS.get_user_data_dir())
	quit()
