extends "res://destructible_prop.gd"
var armed := false
var fuse := 0.55
var blast_radius := 170.0
var exploded := false
func _ready():
	super._ready()
	$Sprite2D.hide()
func _die():
	if armed or exploded:
		return
	destroyed = true
	armed = true
func _physics_process(delta):
	if armed and not exploded:
		fuse -= delta
		if fuse <= 0:
			detonate()
	queue_redraw()
func detonate():
	if exploded:
		return
	exploded = true
	for group in ["enemies", "destructible"]:
		for target in get_tree().get_nodes_in_group(group):
			if target == self or target.is_queued_for_deletion():
				continue
			if global_position.distance_to(target.global_position) <= blast_radius:
				target.take_damage(6)
	# Friendly explosions reward positioning without surprise player damage.
	var fx = preload("res://arena/blast_visual.gd").new()
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position
	fx.radius = blast_radius
	queue_free()
func _draw():
	draw_rect(Rect2(-13,-13,26,26), Color("382936"))
	draw_rect(Rect2(-11,-11,22,22), Color("d99b57"))
	for y in [-8,8]:
		draw_line(Vector2(-11,y),Vector2(11,y),Color("ffe0a0"),2)
	# A bomb silhouette, not colour alone, distinguishes explosive crates.
	draw_circle(Vector2(0,2),6,Color("302335"))
	draw_arc(Vector2(4,-4),4,PI,TAU,12,Color("fff0ca"),2)
	if armed:
		draw_arc(Vector2.ZERO,blast_radius/scale.x,0,TAU,64,Color(1,0.88,0.65,0.8),1)
		draw_circle(Vector2(7,-7),2+sin(fuse*40),Color.WHITE)
