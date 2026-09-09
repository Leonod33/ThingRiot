extends "res://enemy.gd"
const BODY_ART = preload("res://assets/midnight/enemies/bureaucrab.svg")
var max_hp := 240
var attack_timer := 2.5
var attacks := 0
var director: Node
var stamp_pose := 0.0
var walk_phase := 0.0
var defeat_age := 0.0
func _ready():
	basic_art = false
	super._ready()
	add_to_group("boss")
	$Sprite2D.hide()
	scale = Vector2.ONE
	hp = max_hp
	speed = 85
	var shape = CircleShape2D.new()
	shape.radius = 52
	$CollisionShape2D.shape = shape
	var touch = CircleShape2D.new()
	touch.radius = 56
	$DamageArea/CollisionShape2D.shape = touch
func _desired_velocity(delta: float, dir: Vector2) -> Vector2:
	attack_timer -= delta
	if attack_timer <= 0:
		stamp_attack()
		attack_timer = 2.8 if hp > max_hp / 2 else 2.2
	if global_position.distance_to(player.global_position) > 260:
		return dir * speed * (0.45 if crumb_time > 0 else 1.0)
	return Vector2.ZERO
func stamp_attack():
	if dead or not is_instance_valid(player) or player.dead:
		return
	stamp_pose = 1.6
	var point = player.global_position
	# Teach each rectangle separately twice before combining the two shapes.
	var combined := attacks >= 4 and hp <= max_hp / 2
	if combined:
		make_stamp(point, Vector2(110,330))
		make_stamp(point, Vector2(330,110))
	else:
		make_stamp(point, Vector2(110,330) if attacks % 2 == 0 else Vector2(330,110))
	attacks += 1
func make_stamp(point: Vector2, dimensions: Vector2):
	if get_tree().get_nodes_in_group("boss_stamps").size() >= 6:
		return
	var stamp = preload("res://run/stamp.gd").new()
	stamp.size = dimensions
	get_tree().current_scene.add_child(stamp)
	stamp.global_position = point
func take_damage(amount):
	if dead or amount <= 0:
		return
	hp -= amount
	flash_time = 0.08
	queue_redraw()
	if hp <= 0:
		dead = true
		if is_instance_valid(director):
			director.begin_victory()
		set_physics_process(false)
		$DamageArea.set_deferred("monitoring",false)
func _process(delta):
	if dead:
		flash_time = maxf(0,flash_time-delta)
		stamp_pose = 0
		defeat_age += delta
		queue_redraw()
		return
	stamp_pose = maxf(0,stamp_pose-delta)
	walk_phase += delta*4
	queue_redraw() # Only one boss; its leg/claw animation is intentionally live.

func _draw():
	if dead:
		draw_set_transform(Vector2(0,minf(1,defeat_age*3)*18),0,Vector2(1,1-minf(1,defeat_age*2)*0.3))
	var ink = Color("29283f")
	# Six angular legs, enormous paper-stamping claws, suit and spectacles.
	for side in [-1,1]:
		var lift := sin(clampf((1.6-stamp_pose)/1.25,0,1)*PI/2)*19 if stamp_pose > 0.35 else -sin(clampf(stamp_pose/0.35,0,1)*PI)*8
		for i in range(3):
			var points = PackedVector2Array([Vector2(side*35,i*18-12),Vector2(side*(66+i*5),i*22-20),Vector2(side*(84+i*5),i*23+(sin(walk_phase+i*2+side)*3 if not dead else 0))])
			draw_polyline(points,ink,10)
			draw_polyline(points,Color("d69b77"),5)
		draw_line(Vector2(side*40,-15),Vector2(side*78,-48-lift),ink,15)
		draw_circle(Vector2(side*80,-52-lift),22,Color("ddaa85"))
		draw_rect(Rect2(Vector2(side*80-25,-45-lift),Vector2(50,17)),ink)
		draw_rect(Rect2(Vector2(side*80-20,-44-lift),Vector2(40,9)),Color("fff0c5"))
	draw_texture_rect(BODY_ART,Rect2(-63,-92,126,151),false,Color(2.5,2.5,2.5) if flash_time > 0 else Color.WHITE)
	super._draw()
	if dead:
		draw_set_transform(Vector2.ZERO)
		for i in range(12):
			var direction := Vector2.from_angle(i*2.4)
			var point := direction*minf(1,defeat_age)*125+Vector2(0,defeat_age*25)
			draw_set_transform(point,i+defeat_age*2)
			draw_rect(Rect2(-6,-9,12,18),Color("fff0c5"))
			draw_line(Vector2(-3,-3),Vector2(3,-3),ink,1)
