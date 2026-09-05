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
@export var offscreen_margin := 160.0  # extra padding outside the camera

# --- Bias toward player's movement direction ---
@export var bias_enabled := true         # turn weighting on/off
@export var bias_ahead := true           # true = spawn ahead of movement; false = behind (more chasey)
@export_range(0.0, 1.0, 0.05) var bias_probability := 0.7
@export_range(10.0, 360.0, 5.0) var bias_arc_deg := 120.0

var _t := 0.0
var spawned_total := 0
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

func _offscreen_radius() -> float:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		# Fallback to your old fixed radius if there’s no active camera yet
		return ring_radius

	# Visible size in pixels → scaled by camera zoom → half-diagonal in world units
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half_size_world := (vp_size / cam.zoom) * 0.5
	var half_diagonal := half_size_world.length()

	return half_diagonal + offscreen_margin

func _spawn_enemy_batch(diff: float) -> void:
	var count := int(floor(lerp(1.0, float(batch_max), diff)))
	for i in count:
		_spawn_one_enemy()

func _spawn_one_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= 180:
		return
	var e := enemy_scene.instantiate()
	spawned_total += 1
	if _t >= 20.0 and spawned_total % 3 == 0:
		e.set_script(preload("res://arena/tactical_enemy.gd"))
		e.kind = "caster" if _t >= 40.0 and spawned_total % 2 == 0 else "charger"
	get_tree().current_scene.add_child(e)
	e.global_position = _ring_spawn_position()

func _ring_spawn_position() -> Vector2:
	var a := _pick_spawn_angle()
	var rr := _offscreen_radius()  # from the previous step we added earlier
	var r := rr + randf_range(-ring_thickness, ring_thickness)
	return _player.global_position + Vector2.RIGHT.rotated(a) * r
	
func _pick_spawn_angle() -> float:
	# Sometimes: unbiased (uniform ring)
	if (not bias_enabled) or (randf() > bias_probability):
		return randf() * TAU

	var target_dir: Vector2 = _target_direction()
	if target_dir.length() < 0.001:
		# Stationary → fall back to uniform
		return randf() * TAU

	# Ahead vs. behind (chasey)
	if not bias_ahead:
		target_dir = -target_dir

	var base_angle: float = target_dir.angle()
	var half_arc: float = deg_to_rad(max(5.0, bias_arc_deg) * 0.5)
	return base_angle + randf_range(-half_arc, half_arc)


func _target_direction() -> Vector2:
	# Prefer actual movement velocity if Player is a CharacterBody2D
	if _player is CharacterBody2D:
		var v := (_player as CharacterBody2D).velocity
		if v.length() > 0.1:
			return v.normalized()

	# Fallback: if you store input direction on the player, you could read that instead.
	# As a last fallback, return zero (caller will handle).
	return Vector2.ZERO
