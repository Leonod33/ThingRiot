extends Sprite2D
# Imported, cached artwork. Movement animates the transform, never rebuilds paths.
const CLERK = preload("res://assets/midnight/enemies/clerk.svg")
const CHARGER = preload("res://assets/midnight/enemies/charger.svg")
const CASTER = preload("res://assets/midnight/enemies/caster.svg")
var phase := 0.0
var tick := 0.0
var kind := "clerk"
var actor: Node2D
var base_y := -17.0

func _ready():
	actor = get_parent()
	if not actor.basic_art:
		kind = actor.kind
	texture = CLERK if kind == "clerk" else (CHARGER if kind == "charger" else CASTER)
	centered = false
	offset = Vector2(-48, -96 if kind == "clerk" else (-76 if kind == "charger" else -80))
	scale = Vector2.ONE * (0.30 if kind == "clerk" else 0.48)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Instance IDs provide a visual phase without consuming gameplay randomness.
	phase = float(get_instance_id() % 127) * 0.049
	position = Vector2.ZERO
	visibility_layer = 1
	var screen := VisibleOnScreenNotifier2D.new()
	screen.rect = Rect2(-30,-48,60,72)
	add_child(screen)
	screen.screen_entered.connect(func(): set_process(true))
	screen.screen_exited.connect(func(): set_process(false))

func _process(delta):
	# 20 Hz transform animation is sufficient for small enemies in large crowds.
	tick += delta
	if tick < 0.05:
		return
	phase += tick * (6.0 if kind == "caster" else 11.0)
	tick = 0.0
	var moving: float = clampf(actor.velocity.length() / 140.0, 0, 1)
	position.y = sin(phase) * (1.1 if kind == "caster" else moving * 1.1)
	rotation = sin(phase * 0.5) * 0.025 * moving
	if kind != "clerk" and actor.state == "windup":
		position.y = 1.8 if kind == "charger" else -2.0
		rotation = sin(phase * 3.0) * 0.025
	elif kind == "charger" and actor.state == "charge":
		rotation = clampf(actor.attack_direction.x * 0.13, -0.13, 0.13)

func flash(active: bool):
	modulate = Color(2.6,2.6,2.6) if active else Color.WHITE
