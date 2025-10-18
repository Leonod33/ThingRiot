extends Area2D

@export var xp_value: int = 1
@export var magnet_radius: float = 140.0
var _player: Node2D

func _ready() -> void:
	# Your Player group is "Player" (capital P)
	_player = get_tree().get_first_node_in_group("Player")

func _process(delta: float) -> void:
	# Gentle vacuum when close
	if _player and global_position.distance_to(_player.global_position) < magnet_radius:
		global_position = global_position.lerp(_player.global_position, 5.0 * delta)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("add_xp"):
		body.add_xp(xp_value)
		queue_free()
