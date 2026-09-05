extends Node2D

var radius := 120.0
var duration := 6.0
var age := 0.0

func _ready():
	add_to_group("crumb_patches")
	z_index = 0
	var patches = get_tree().get_nodes_in_group("crumb_patches")
	if patches.size() > 24:
		patches[0].queue_free()

func _physics_process(delta):
	age += delta
	if age >= duration:
		queue_free()
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.dead and global_position.distance_squared_to(enemy.global_position) < radius * radius:
			enemy.coat_with_crumbs()
	modulate.a = minf(1.0, (duration - age) / 0.7)
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, radius, Color(0.9, 0.65, 0.25, 0.22))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color("ffe2a3"), 2)
	for i in range(24):
		var point = Vector2.from_angle(i * 2.4) * sqrt(float(i + 1) / 24.0) * radius * 0.88
		draw_rect(Rect2(point, Vector2(5, 3)), Color("ffd18a"))
