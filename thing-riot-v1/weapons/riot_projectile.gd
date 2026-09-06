extends Node2D

const Patch = preload("res://weapons/crumb_patch.gd")
const Impact = preload("res://weapons/impact.gd")
var spec: Resource
var owner_player: Node2D
var controller: Node2D
var direction := Vector2.RIGHT
var damage := 1
var knockback := 140.0
var size_mult := 1.0
var reach := 480.0
var travelled := 0.0
var age := 0.0
var returning := false
var hits := {}
var bounce_count := 0
var bounce_target: Node2D
var trail: Array[Vector2] = []
var finished := false
var sweep_shape := RectangleShape2D.new()
var sweep_query := PhysicsShapeQueryParameters2D.new()

func _ready():
	add_to_group("riot_projectiles")
	z_index = 5
	sweep_query.shape = sweep_shape
	sweep_query.collision_mask = 2
	sweep_query.collide_with_areas = true
	sweep_query.collide_with_bodies = true

func _physics_process(delta):
	if finished:
		return
	if not is_instance_valid(owner_player) or owner_player.dead or age > 8.0:
		queue_free()
		return
	age += delta
	if is_instance_valid(bounce_target) and not bounce_target.is_queued_for_deletion():
		direction = global_position.direction_to(bounce_target.global_position)
	elif returning:
		direction = global_position.direction_to(owner_player.global_position)
	var before := global_position
	var speed: float = spec.speed * (1.25 if returning else 1.0)
	global_position += direction * speed * delta
	travelled += speed * delta
	trail.push_front(global_position)
	if trail.size() > 9:
		trail.pop_back()
	# Ask the physics broad phase for nearby candidates, then retain the exact
	# swept centre-distance rule. The reusable query avoids per-shot allocations.
	var hit_radius := 25 + 12 * size_mult
	var sweep_bounds := Rect2(before, Vector2.ZERO).expand(global_position).grow(hit_radius)
	sweep_shape.size = sweep_bounds.size
	sweep_query.transform = Transform2D(0, sweep_bounds.get_center())
	var candidates := {}
	for overlap in get_world_2d().direct_space_state.intersect_shape(sweep_query, 1024):
		var target = overlap.collider
		if not target.is_in_group("enemies"):
			target = target.get_parent()
			if not target or not (target.is_in_group("destructible") or target.is_in_group("loaded_dice")):
				continue
		var id = target.get_instance_id()
		if target.is_queued_for_deletion() or hits.has(id) or candidates.has(target):
			continue
		var nearest = Geometry2D.get_closest_point_to_segment(target.global_position, before, global_position)
		if nearest.distance_squared_to(target.global_position) <= hit_radius * hit_radius:
			candidates[target] = before.distance_squared_to(nearest)
	# Biscuits stop at the first target along the sweep, regardless of tree order.
	var ordered = candidates.keys()
	ordered.sort_custom(func(a, b): return candidates[a] < candidates[b])
	for target in ordered:
		strike(target)
		if finished:
			return
	if spec.kind == "biscuit" and travelled >= reach:
		burst()
	elif spec.kind == "crown":
		if not returning and travelled >= reach and not is_instance_valid(bounce_target):
			begin_return()
		if returning and Geometry2D.get_closest_point_to_segment(owner_player.global_position, before, global_position).distance_to(owner_player.global_position) < 26:
			finished = true
			queue_free()
	queue_redraw()

func begin_return():
	returning = true
	bounce_target = null
	hits.clear() # Each target may be hit once outward and once returning.

func strike(target: Node2D):
	if finished or hits.has(target.get_instance_id()):
		return
	if target.is_in_group("loaded_dice"):
		if spec.kind == "crown":
			target.cash_out(true)
		return
	hits[target.get_instance_id()] = true
	var coated: bool = target.is_in_group("enemies") and target.crumb_time > 0
	if spec.kind == "biscuit":
		# Coat before damage; even a lethal shot leaves a useful patch.
		if target.has_method("coat_with_crumbs"):
			target.coat_with_crumbs()
		target.take_damage(damage)
		burst()
		return
	target.take_damage(damage)
	if target.has_method("apply_knockback"):
		target.apply_knockback(global_position - direction, knockback)
	var fx = Impact.new()
	get_tree().current_scene.add_child(fx)
	fx.global_position = target.global_position
	if target == bounce_target:
		bounce_target = null
	if coated and not returning and bounce_count < spec.bounce_limit:
		var best: Node2D = null
		var distance := 240.0
		for candidate in get_tree().get_nodes_in_group("enemies"):
			if candidate.dead or hits.has(candidate.get_instance_id()) or candidate.crumb_time <= 0:
				continue
			var d = target.global_position.distance_to(candidate.global_position)
			if d < distance:
				distance = d
				best = candidate
		if best:
			bounce_count += 1
			bounce_target = best
			direction = global_position.direction_to(best.global_position)
			if is_instance_valid(controller):
				controller.celebrate_combo(bounce_count)

func burst():
	if finished:
		return
	finished = true
	var patch = Patch.new()
	patch.radius = spec.patch_radius
	patch.duration = spec.patch_lifetime
	get_tree().current_scene.add_child(patch)
	patch.global_position = global_position
	queue_free()

func _draw():
	for i in range(1, trail.size()):
		draw_line(to_local(trail[i - 1]), to_local(trail[i]), Color(0.5, 0.85, 1.0, 0.5 * (1.0 - float(i) / 9)), 4)
	if spec.kind == "biscuit":
		draw_circle(Vector2.ZERO, 13, Color("eab26b"))
		draw_arc(Vector2.ZERO, 13, 0, TAU, 20, Color("503321"), 2)
		for point in [Vector2(-5,-4), Vector2(5,-3), Vector2(1,5)]:
			draw_circle(point, 2, Color("503321"))
	else:
		draw_set_transform(Vector2.ZERO, age * 12, Vector2.ONE * size_mult)
		var points = PackedVector2Array([Vector2(-16,-10),Vector2(-7,-3),Vector2(0,-15),Vector2(7,-3),Vector2(16,-10),Vector2(12,12),Vector2(-12,12)])
		draw_colored_polygon(points, Color("ffe090") if not returning else Color("a5ecff"))
		points.append(points[0])
		draw_polyline(points, Color("312c4a"), 2)
