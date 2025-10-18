extends Node2D

@export var enemy_scene: PackedScene = preload("res://enemy.tscn")

# Spawn pacing
@export var spawn_interval_min := 0.3
@export var spawn_interval_max := 2.4
@export var ramp_seconds := 180.0  # over 3 minutes from easy → busy
@export var batch_max := 3         # max enemies per spawn

# Spawn geometry
@export var ring_radius := 520.0   # spawn around player, outside screen
@export var ring_thickness := 60.0 # randomize a bit so it’s not exact ring

var _t := 0.0
var _timer := 0.0
var _player: Node2D

func _ready():
	_player = get_tree().get_first_node_in_group("Player")
	_timer = spawn_interval_max

func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("Player")
		return

	_t = clamp(_t + delta, 0.0, ramp_seconds)
	var diff : float = _t / ramp_seconds            # 0..1
	var interval : float = lerp(spawn_interval_max, spawn_interval_min, diff)
	_timer -= delta

	if _timer <= 0.0:
		_spawn_enemy_batch(diff)
		_timer = interval

func _spawn_enemy_batch(diff: float) -> void:
	var count := 1 + int(floor(lerp(1.0, float(batch_max), diff)))
	for i in count:
		_spawn_one_enemy()

func _spawn_one_enemy() -> void:
	var e := enemy_scene.instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = _ring_spawn_position()

func _ring_spawn_position() -> Vector2:
	var a := randf() * TAU
	var r := ring_radius + randf_range(-ring_thickness, ring_thickness)
	return _player.global_position + Vector2.RIGHT.rotated(a) * r
