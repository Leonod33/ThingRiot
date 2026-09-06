extends Area2D

@export var xp_value: int = 1
@export var magnet_radius: float = 140.0
var _player: Node2D
var collected := false

func _ready() -> void:
	$Sprite2D.hide()
	# Your Player group is "Player" (capital P)
	_player = get_tree().get_first_node_in_group("Player")

func _process(delta: float) -> void:
	# Gentle vacuum when close
	if _player and global_position.distance_to(_player.global_position) < magnet_radius:
		global_position = global_position.lerp(_player.global_position, 5.0 * delta)

func _on_body_entered(body: Node) -> void:
	if not collected and body.is_in_group("Player") and not body.dead:
		collected = true
		var feedback = get_tree().current_scene.get_node_or_null("Feedback")
		if feedback:
			feedback.sound("pickup")
		body.add_xp(xp_value)
		queue_free()

func _draw():
	draw_colored_polygon(PackedVector2Array([Vector2(0,-4),Vector2(3,0),Vector2(0,4),Vector2(-3,0)]),Color("1b3148"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-3),Vector2(2,0),Vector2(0,3),Vector2(-2,0)]),Color("80d7ec"))
	draw_line(Vector2(0,-2),Vector2(-1,0),Color.WHITE,0.6,true)
