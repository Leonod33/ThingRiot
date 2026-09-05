extends Node2D

@export var max_health: int = 2
@export var drop_chance: float = 0.35         # 35% to drop something
@export var drop_scene: PackedScene            # assign HealthPickup.tscn later
@export var destroy_fx: PackedScene            # optional puff/anim

var _hp: int
var destroyed := false

func _ready() -> void:
	_hp = max_health
	if not is_in_group("destructible"):
		add_to_group("destructible")
	# If you want the Hurtbox to relay body/area_entered to this node,
	# just leave bullet’s Area2D overlap to call our take_damage via group+method.

func take_damage(n: int) -> void:
	if destroyed or n <= 0:
		return
	_hp -= n
	if _hp <= 0:
		_die()

func _die() -> void:
	if destroyed:
		return
	destroyed = true
	if destroy_fx:
		var fx := destroy_fx.instantiate()
		get_tree().current_scene.add_child.call_deferred(fx)
		fx.global_position = global_position

	# Drop logic
	if drop_scene and randf() < effective_drop_chance():
		var drop := drop_scene.instantiate()
		get_tree().current_scene.add_child.call_deferred(drop)
		drop.global_position = global_position

	queue_free()

func effective_drop_chance() -> float:
	var player = get_tree().get_first_node_in_group("Player")
	var luck: float = player.stats.luck if player else 0.0
	return clampf(drop_chance * (1.0 + luck), 0.0, 1.0)
