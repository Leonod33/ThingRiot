extends Node2D
# A repeated floor quad and deterministic, camera-local set dressing. No bodies,
# no gameplay RNG, no texture allocation or full-arena scans during movement.
const FLOOR = preload("res://assets/midnight/arena/slate.svg")
const SEAL = preload("res://assets/midnight/arena/medallion.svg")
const GARDEN = preload("res://assets/midnight/arena/garden.svg")
const LAMP = preload("res://assets/midnight/arena/lamp.svg")
const CELL := 900.0
var player: Node2D
var cell := Vector2i(99999,99999)
var scenery: Node2D
var decorations := 0
var arena_rect := Rect2(0,0,25428,15024)

func _ready():
	name = "Courtyard"
	z_index = -20
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	player = get_parent().get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	arena_rect = Rect2(camera.limit_left,camera.limit_top,camera.limit_right-camera.limit_left,camera.limit_bottom-camera.limit_top)
	get_parent().get_node("Level1").hide()
	scenery = Node2D.new()
	scenery.name = "SetDressing"
	add_child(scenery)
	_process(0)

func _draw():
	draw_texture_rect(FLOOR,arena_rect,true)
	# Architectural borders, quiet enough for warning lanes and projectile trails.
	draw_rect(arena_rect.grow(-24),Color("1f3343"),false,48)
	draw_rect(arena_rect.grow(-56),Color("78806d"),false,2)

func _process(_delta):
	if not is_instance_valid(player):
		return
	var next_cell := Vector2i(floori(player.global_position.x/CELL),floori(player.global_position.y/CELL))
	if next_cell == cell:
		return
	cell = next_cell
	for child in scenery.get_children():
		child.free()
	decorations = 0
	# A fixed 5x5 neighbourhood bounds memory over the whole 25,000-pixel arena.
	for y in range(cell.y-2,cell.y+3):
		for x in range(cell.x-2,cell.x+3):
			var point := Vector2(x,y)*CELL+Vector2(600,0)
			if not arena_rect.grow(-120).has_point(point):
				continue
			var key := absi(x*73+y*137)
			if key%3 == 0:
				place(SEAL,point,0.9,0.72)
			place(GARDEN,point+Vector2(-320,230),0.8+float(key%4)*0.1,0.92)
			place(GARDEN,point+Vector2(280,-240),0.7,0.8)
			place(LAMP,point+Vector2(-340,-190),0.75,0.95)
			# Discarded stationery connects the arena to its inhabitants.
			var scraps := Node2D.new()
			scraps.position = point+Vector2(140,110)
			scraps.draw.connect(func():
				for i in range(4):
					scraps.draw_set_transform(Vector2(i*19,(i%2)*13),i*0.8)
					scraps.draw_rect(Rect2(-4,-6,8,12),Color(0.7,0.76,0.73,0.4))
					scraps.draw_line(Vector2(-2,-2),Vector2(2,-2),Color("425866"),1))
			scenery.add_child(scraps)
			decorations += 1

func place(art: Texture2D, point: Vector2, size: float, opacity: float):
	var sprite := Sprite2D.new()
	sprite.texture = art
	sprite.position = point
	sprite.scale = Vector2.ONE*size
	sprite.modulate.a = opacity
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	scenery.add_child(sprite)
	decorations += 1
