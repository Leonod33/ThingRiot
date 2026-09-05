extends Area2D

@export var attract_radius: float = 0.0  # set >0 later for magnet behavior

var collected := false

func _ready() -> void:
	monitoring = true
	monitorable = true
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not collected and body.is_in_group("Player") and not body.dead:
		collected = true
		_on_collected(body)

func _on_collected(player: Node) -> void:
	# override in child types
	queue_free()
