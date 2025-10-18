extends Area2D

@export var speed: float = 460.0
@export var lifetime: float = 1.6
var direction: Vector2 = Vector2.ZERO

var _t := 0.0

func _ready() -> void:
	# Layers: Player=1, Enemy=2  (per your setup)
	collision_layer = 4              # bullet on its own layer
	collision_mask = 2               # only hit enemies

	# If direction wasn’t set by the spawner for any reason, pick a fallback
	if direction.length() < 0.001:
		direction = Vector2.RIGHT

	# Optional: ignore collisions for the first instant to avoid any spawn overlap oddities
	# set_deferred("monitoring", false)
	# await get_tree().process_frame
	# set_deferred("monitoring", true)

	# Connect signals if not wired in the scene
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	# Normalize once to avoid tiny magnitudes stalling motion
	if direction.length() < 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	global_position += direction * speed * delta

	# Hard TTL so bullets never hang around
	_t += delta
	if _t >= lifetime:
		queue_free()



func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
