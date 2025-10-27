extends Node

@export var prop_scene: PackedScene
@export var count: int = 20
@export var min_distance_from_player: float = 160.0
@export var tilemap_path: NodePath = ^"/root/Main/Level1/TileMapLayer"

# NEW: control how far from the player to sprinkle props
@export var spawn_radius_min: float = 300.0
@export var spawn_radius_max: float = 900.0

func _ready() -> void:
	print("PropSpawner: READY on ", get_path())
	call_deferred("_start_spawning")

func _start_spawning() -> void:
	if prop_scene == null:
		push_warning("PropSpawner: prop_scene is null")
		return

	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		push_warning("PropSpawner: no Player in group 'Player'")
		return

	# --- fetch map node (TileMapLayer or TileMap) ---
	var map := get_node_or_null(tilemap_path)
	if map == null:
		push_warning("PropSpawner: TileMap not found at %s" % [tilemap_path])
		return
	if not (map is TileMapLayer or map is TileMap):
		push_warning("PropSpawner: node at %s is not a TileMapLayer/TileMap" % [tilemap_path])
		return
	if not map.has_method("get_used_rect"):
		push_warning("PropSpawner: node at %s has no get_used_rect()" % [tilemap_path])
		return

	# --- compute a world-space rect for the map; we'll clamp to it ---
	var world_rect := _map_world_rect(map)
	print("PropSpawner: map world rect = ", world_rect)

	_scatter_props_around_player(player, world_rect)
	_spawn_test_prop(player)  # guaranteed visible test prop

func _map_world_rect(map: Node) -> Rect2:
	var used_rect: Rect2i = map.get_used_rect()
	# If empty, give a big sandbox around 0,0
	if used_rect.size == Vector2i.ZERO:
		return Rect2(Vector2(-1024, -1024), Vector2(2048, 2048))

	# Convert tile coords → world coords
	var tile_size := Vector2((map as TileMap).tile_set.tile_size) if (map is TileMap) else Vector2(64, 64)
	var origin_world: Vector2 = map.to_global(Vector2(used_rect.position) * tile_size)
	var size_world:   Vector2 = Vector2(used_rect.size) * tile_size
	return Rect2(origin_world, size_world)

func _scatter_props_around_player(player: Node2D, world_rect: Rect2) -> void:
	var placed := 0
	var tries := 0
	print("PropSpawner: scattering ", count, " props. scene=", prop_scene, " path=", prop_scene.resource_path)

	while placed < count and tries < count * 100:
		tries += 1

		# Ring around the player (visible area)
		var angle := randf() * TAU
		var r := randf_range(spawn_radius_min, spawn_radius_max)
		var p := player.global_position + Vector2.RIGHT.rotated(angle) * r

		# Keep a little away from the player
		if player.global_position.distance_to(p) < min_distance_from_player:
			continue

		# TEMP: do NOT clamp/reject by world_rect — just spawn so we can see them
		var prop := prop_scene.instantiate() as Node2D
		prop.top_level = true
		prop.global_position = p
		_force_visible(prop)
		_log_spawn(prop)
		get_tree().current_scene.call_deferred("add_child", prop)

		placed += 1

	print("PropSpawner: placed ", placed, " props (tries=", tries, ")")


func _spawn_test_prop(player: Node2D) -> void:
	var test := prop_scene.instantiate() as Node2D
	test.top_level = true
	test.global_position = player.global_position + Vector2(0, -48)
	_force_visible(test)
	_log_spawn(test)
	get_tree().current_scene.call_deferred("add_child", test)
	print("PropSpawner: spawned a TEST prop near player at ", test.global_position)

# --- helpers -----------------------------------------------------------------

func _force_visible(n: Node) -> void:
	if n is CanvasItem:
		var ci := n as CanvasItem
		ci.visible = true
		ci.z_index = 200
		ci.z_as_relative = false

	var spr := n.get_node_or_null("Sprite2D") as Sprite2D
	if spr:
		spr.visible = true
		spr.self_modulate = Color(1, 1, 1, 1)
		spr.scale = Vector2(2, 2)   # TEMP: easier to see
		spr.z_index = 200
		spr.z_as_relative = false

func _log_spawn(n: Node) -> void:
	var pos := (n as Node2D).global_position if n is Node2D else Vector2.ZERO
	print("PropSpawner: spawned type=", n.get_class(), " name=", n.name, " at ", pos)
	for c in n.get_children():
		print("  child: ", c.name, " (", c.get_class(), ")")
