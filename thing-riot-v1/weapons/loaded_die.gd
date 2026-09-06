extends Node2D
var spec: Resource
var owner_player: Node2D
var controller: Node2D
var direction := Vector2.RIGHT
var age := 0.0
var travelled := 0.0
var pips := 1
var finished := false
var damage := 1
var query := PhysicsShapeQueryParameters2D.new()
func _ready():
	add_to_group("loaded_dice")
	add_to_group("riot_projectiles")
	z_index = 4
	pips = mini(6, randi_range(1,6) + int(owner_player.stats.luck * 2))
	var area = Area2D.new()
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 16
	area.add_child(shape)
	add_child(area)
	query.shape = CircleShape2D.new()
	query.collision_mask = 2
func _physics_process(delta):
	if finished:
		return
	if not is_instance_valid(owner_player) or owner_player.dead:
		queue_free()
		return
	age += delta
	var step = minf(spec.speed * delta, maxf(0, spec.reach - travelled))
	global_position += direction * step
	travelled += step
	rotation += delta * 9 if step > 0 else 0.0
	if age >= 1.4:
		cash_out(false)
func cash_out(royal: bool):
	if finished:
		return
	finished = true
	if royal:
		pips = 6
		if is_instance_valid(controller):
			controller.celebrate_wager()
	var radius: float = spec.patch_radius * (1.5 if royal else 1.0)
	query.shape.radius = radius
	query.transform = Transform2D(0, global_position)
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 256):
		var target = hit.collider
		if target.is_in_group("enemies") and not target.dead and global_position.distance_squared_to(target.global_position) <= radius * radius:
			target.take_damage(damage + pips)
			target.apply_knockback(global_position, 200)
	var fx = preload("res://arena/blast_visual.gd").new()
	fx.radius = radius
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position
	queue_free()
func _draw():
	draw_rect(Rect2(-18,-18,36,36), Color("28263d"))
	draw_rect(Rect2(-15,-15,30,30), Color("fff0c5"))
	var dots = [Vector2(-8,-8),Vector2(8,8),Vector2(-8,8),Vector2(8,-8),Vector2(-8,0),Vector2(8,0)]
	if pips % 2 == 1:
		draw_circle(Vector2.ZERO, 2.8, Color("30243d"))
	for i in range(pips - pips % 2):
		draw_circle(dots[i], 2.8, Color("30243d"))
