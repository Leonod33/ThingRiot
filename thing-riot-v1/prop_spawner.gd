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
		var prop = prop_scene.instantiate()
		get_tree().current_scene.add_child(prop)
		prop.global_position = pos
		# Scale the entire prop so its collision matches its drawing.
		prop.scale = Vector2(2,2)
		placed_positions.append(pos)
