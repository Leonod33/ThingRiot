extends "res://pickup_base.gd"

@export var heal_amount: int = 1

func _on_collected(player: Node) -> void:
	if player.has_method("change_health"):
		player.change_health(heal_amount)   # your Player already clamps & updates HUD
	queue_free()
