extends Node2D

@export var max_health: int = 2
@export var drop_chance: float = 0.35         # 35% to drop something
@export var drop_scene: PackedScene            # assign HealthPickup.tscn later
@export var destroy_fx: PackedScene            # optional puff/anim

var _hp: int

func _ready() -> void:
	_hp = max_health
	if not is_in_group("destructible"):
		add_to_group("destructible")
	# If you want the Hurtbox to relay body/area_entered to this node,
	# just leave bullet’s Area2D overlap to call our take_damage via group+method.

func take_damage(n: int) -> void:
	_hp -= n
	if _hp <= 0:
		_die()

func _die() -> void:
	if destroy_fx:
		var fx := destroy_fx.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = global_position

	# Drop logic
	if drop_scene and randf() < drop_chance:
		var drop := drop_scene.instantiate()
		get_tree().current_scene.add_child(drop)
		drop.global_position = global_position

	queue_free()
