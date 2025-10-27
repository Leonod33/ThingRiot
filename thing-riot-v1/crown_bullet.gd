extends Area2D

@export var speed: float = 460.0
@export var lifetime: float = 1.6
@export var damage: int = 1
@export var size_multiplier: float = 1.0
@export var base_hit_radius: float = 6.0
@export var base_visual_scale: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var colshape: CollisionShape2D = $CollisionShape2D

var direction: Vector2 = Vector2.ZERO
var _t := 0.0
var _sprite_base_scale := Vector2.ONE

func _ready() -> void:
	# Layers: Player=1, Enemy=2 → put bullet on 4, detect 2
	collision_layer = 4
	collision_mask = 2
	monitoring = true

	# cache original editor scale so upgrades don't permanently distort it
	if sprite:
		_sprite_base_scale = sprite.scale
		sprite.scale = _sprite_base_scale * (base_visual_scale * size_multiplier)

	if colshape and colshape.shape is CircleShape2D:
		(colshape.shape as CircleShape2D).radius = base_hit_radius * size_multiplier

	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		connect("area_entered", Callable(self, "_on_area_entered"))

	if direction.length() < 0.001:
		direction = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	direction = Vector2.RIGHT if direction.length() < 0.001 else direction.normalized()
	global_position += direction * speed * delta
	_t += delta
	if _t >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if (body.is_in_group("enemies") or body.is_in_group("destructible")) and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var maybe := area.get_parent()
	if maybe and (maybe.is_in_group("enemies") or maybe.is_in_group("destructible")) and maybe.has_method("take_damage"):
		maybe.take_damage(damage)
		queue_free()
