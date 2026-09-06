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
var state := "rolling"
var fuse := 2.0
var royal := false
var spin := 0.0
var clacks := 0
var query := PhysicsShapeQueryParameters2D.new()
func _ready():
	add_to_group("loaded_dice")
	add_to_group("riot_projectiles")
	z_index = 4
	pips = mini(6,randi_range(1,6)+int(owner_player.stats.luck*2))
	var area = Area2D.new()
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 20
	area.add_child(shape)
	add_child(area)
	query.shape = CircleShape2D.new()
	query.collision_mask = 2
func can_cash_out() -> bool:
	return state == "ready" and not finished
func blast_radius() -> float:
	# Every face is distinct in size as well as damage; royal six is larger again.
	return spec.patch_radius * (0.55 + pips * 0.12) * (1.2 if royal else 1.0)
func _physics_process(delta):
	if finished:
		return
	if not is_instance_valid(owner_player) or owner_player.dead:
		queue_free()
		return
	age += delta
	if state == "rolling":
		var step = minf(spec.speed*delta,maxf(0,spec.reach-travelled))
		global_position += direction * step
		travelled += step
		var progress := clampf(travelled/spec.reach,0,1)
		spin = TAU*2*(1-pow(1-progress,2))
		if age >= 0.25+clacks*0.3 and clacks < 2:
			clacks += 1
			play_clack()
		if travelled >= spec.reach and age >= 0.75:
			state = "ready"
			spin = 0
			play_clack()
	else:
		fuse -= delta
		if fuse <= 0:
			detonate()
	queue_redraw()
func cash_out(guaranteed: bool):
	if not can_cash_out():
		return
	if guaranteed:
		royal = true
		pips = 6
		state = "six"
		fuse = 0.55 # Show the actual six before applying its damage.
		if is_instance_valid(controller):
			controller.celebrate_wager()
		queue_redraw()
	else:
		detonate()
func detonate():
	if finished:
		return
	finished = true
	var radius := blast_radius()
	query.shape.radius = radius
	query.transform = Transform2D(0,global_position)
	for hit in get_world_2d().direct_space_state.intersect_shape(query,256):
		var target = hit.collider
		if target.is_in_group("enemies") and not target.dead and global_position.distance_squared_to(target.global_position) <= radius*radius:
			target.take_damage(damage+pips)
			target.apply_knockback(global_position,160+pips*20)
	var fx = preload("res://polish/dice_burst.gd").new()
	fx.radius = radius
	fx.pips = pips
	fx.damage = damage+pips
	fx.royal = royal
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position
	var feedback = get_tree().current_scene.get_node_or_null("Feedback")
	if feedback:
		feedback.sound("six" if royal else "dice")
	queue_free()
func _draw():
	var radius := blast_radius()
	if state != "rolling":
		draw_arc(Vector2.ZERO,radius,0,TAU,48,Color(1,0.9,0.65,0.18),1.5)
		for i in range(pips):
			var a = -PI/2 + TAU*i/pips
			draw_arc(Vector2.ZERO,30+pips*2,a,a+TAU/pips*0.75,10,Color("ffe3a0"),3)
		draw_arc(Vector2.ZERO,26,-PI/2,-PI/2+TAU*clampf(fuse/(0.55 if royal else 2.0),0,1),40,Color.WHITE,2)
	draw_circle(Vector2(0,9),20,Color(0.08,0.09,0.16,0.35))
	var lift = -absf(sin(age*12))*12*(1-clampf(travelled/spec.reach,0,1)) if state == "rolling" else -2.0
	draw_set_transform(Vector2(0,lift),spin,Vector2.ONE*(1.25 if royal else 1.0))
	draw_rect(Rect2(-20,-17,40,39),Color("25273e"))
	draw_rect(Rect2(-17,13,34,7),Color("b5a68e"))
	draw_rect(Rect2(-17,-17,34,34),Color("ffe196") if royal else Color("fff3dc"))
	draw_line(Vector2(-16,-16),Vector2(16,-16),Color.WHITE,2)
	var dots = [Vector2(-8,-8),Vector2(8,8),Vector2(-8,8),Vector2(8,-8),Vector2(-8,0),Vector2(8,0)]
	if pips%2 == 1:
		draw_circle(Vector2.ZERO,2.8,Color("30243d"))
	for i in range(pips-pips%2):
		draw_circle(dots[i],2.8,Color("30243d"))
	draw_set_transform(Vector2.ZERO)
	if state != "rolling":
		if royal:
			var seal := PackedVector2Array([Vector2(-10,-71),Vector2(-5,-64),Vector2(0,-75),Vector2(5,-64),Vector2(10,-71),Vector2(8,-59),Vector2(-8,-59)])
			draw_colored_polygon(seal,Color("ffe196"))
		var label = "ROYAL SIX!" if royal else "%d" % pips
		draw_string(ThemeDB.fallback_font,Vector2(-75,-46),label,HORIZONTAL_ALIGNMENT_CENTER,150,14,Color("fff3dc"))

func play_clack():
	var feedback = get_tree().current_scene.get_node_or_null("Feedback")
	if feedback:
		feedback.sound("clack")
