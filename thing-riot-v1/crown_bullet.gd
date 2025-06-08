extends Area2D

@export var speed: float = 400
var direction: Vector2 = Vector2.ZERO

func _ready():
        # Put the bullet on its own layer and make sure it can detect enemies
        # (which use layer 2). Using a dedicated layer prevents unintended
        # collisions with the map or the player.
        collision_layer = 4
        collision_mask = 2
        connect("body_entered", _on_body_entered)

func _process(delta):
        position += direction * speed * delta

        # Optionally, remove bullet if it leaves the screen
        if not get_viewport_rect().has_point(position):
                queue_free()

func _damage_target(target):
        if target.is_in_group("enemies"):
                target.take_damage(1)
                queue_free()

func _on_area_entered(area):
        var maybe_enemy = area.get_parent()
        _damage_target(maybe_enemy)

func _on_body_entered(body):
        _damage_target(body)
