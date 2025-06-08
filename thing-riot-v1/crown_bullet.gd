extends Area2D

@export var speed: float = 400
var direction: Vector2 = Vector2.ZERO

func _process(delta):
	position += direction * speed * delta

	# Optionally, remove bullet if it leaves the screen:
	if not get_viewport_rect().has_point(position):
		queue_free()

func _on_area_entered(area):
	print("Bullet overlapped with:", area, "Name:", area.name, "Type:", typeof(area))
	var maybe_enemy = area.get_parent()
	print("Parent of overlapped area:", maybe_enemy, "Name:", maybe_enemy.name, "Groups:", maybe_enemy.get_groups())
	if maybe_enemy.is_in_group("enemies"):
		print("Bullet hit enemy!")
		maybe_enemy.take_damage(1)
		queue_free()
