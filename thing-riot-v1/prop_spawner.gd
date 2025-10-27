extends Node

@export var prop_scene: PackedScene
@export var count: int = 20
@export var min_distance_from_player: float = 160.0
@export var tilemap_path: NodePath = ^"/root/Main/Level1/TileMapLayer"

func _ready() -> void:
	print("PropSpawner: READY on ", get_path())

	if prop_scene == null:
		push_warning("PropSpawner: prop_scene is null")
		return

	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		push_warning("PropSpawner: no Player in group 'Player'")
		return

	var map := get_node_or_null(tilemap_path) as TileMap
	if map == null:
		push_warning("PropSpawner: TileMap not found at %s" % [tilemap_path])
		return

	# --- world-space bounds from used_rect ---
	var used_rect: Rect2i = map.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		push_warning("PropSpawner: TileMap used_rect is EMPTY")
		# fallback box around player so we still see something
		var origin_world := player.global_position - Vector2(512, 512)
		var size_world := Vector2(1024, 1024)
		print("PropSpawner: FALLBACK rect origin=", origin_world, " size=", size_world)
		_scatter_props(player, origin_world, size_world)
		_spawn_test_prop(player)
		return

	var tile_size := Vector2(map.tile_set.tile_size)
	var origin_world: Vector2 = map.to_global(Vector2(used_rect.position) * tile_size)
	var size_world:   Vector2 = Vector2(used_rect.size) * tile_size

	print("PropSpawner: world rect origin=", origin_world, " size=", size_world)
	_scatter_props(player, origin_world, size_world)
	_spawn_test_prop(player)  # guaranteed visible test prop

func _scatter_props(player: Node2D, origin_world: Vector2, size_world: Vector2) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 30:
		tries += 1
		var p := Vector2(
			randf_range(origin_world.x, origin_world.x + size_world.x),
			randf_range(origin_world.y, origin_world.y + size_world.y)
		)
		if player.global_position.distance_to(p) < min_distance_from_player:
			continue

		var prop := prop_scene.instantiate() as Node2D
		get_tree().current_scene.add_child(prop)
		prop.global_position = p
		prop.z_index = 50
		placed += 1

	print("PropSpawner: placed %d props (tries=%d)" % [placed, tries])

func _spawn_test_prop(player: Node2D) -> void:
	var test := prop_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(test)
	test.global_position = player.global_position + Vector2(0, -48)
	test.z_index = 50
	print("PropSpawner: spawned a TEST prop near player at ", test.global_position)
