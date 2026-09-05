extends Node

@export var prop_scene: PackedScene
@export var count: int = 320
@export var min_distance_from_player := 180.0
var placed_positions: Array[Vector2] = []

func _ready():
	call_deferred("_start_spawning")

func _start_spawning():
	var player = get_tree().get_first_node_in_group("Player")
	if not player or not prop_scene:
		return
	var camera: Camera2D = player.get_node("Camera2D")
	var bounds := Rect2(camera.limit_left, camera.limit_top, camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top).grow(-100)
	# Stratified distribution covers the whole playable rectangle without piles.
	var columns := ceili(sqrt(count * bounds.size.x / bounds.size.y))
	var rows := ceili(float(count) / columns)
	var cell := bounds.size / Vector2(columns, rows)
	for index in range(count):
		var pos := bounds.position + (Vector2(index % columns, index / columns) + Vector2(randf_range(0.2,0.8), randf_range(0.2,0.8))) * cell
		if pos.distance_to(player.global_position) < min_distance_from_player:
			continue
		spawn_crate(pos, index % 4 == 0)
		if index % 8 == 0:
			spawn_crate(pos + Vector2(-100,0), true)
		if index % 5 == 0:
			spawn_bumper(pos + Vector2(-70,-70))
	# A small introductory encounter makes the new interactions discoverable.
	spawn_crate(player.global_position + Vector2(400,60), true)
	spawn_crate(player.global_position + Vector2(510,60), true)
	spawn_bumper(player.global_position + Vector2(-190,120))

func spawn_crate(pos: Vector2, explosive: bool):
	var prop = prop_scene.instantiate()
	if explosive:
		prop.set_script(preload("res://arena/explosive_crate.gd"))
	get_tree().current_scene.add_child(prop)
	prop.global_position = pos
	prop.scale = Vector2(2,2)
	placed_positions.append(pos)
	return prop

func spawn_bumper(pos: Vector2):
	var bumper = preload("res://arena/bumper.gd").new()
	get_tree().current_scene.add_child(bumper)
	bumper.global_position = pos
	return bumper
