extends HBoxContainer

@export var player: NodePath = "/root/Main/Player"

var full_heart : Texture2D
var half_heart : Texture2D
var empty_heart : Texture2D

func _ready():
	# Load heart textures
	full_heart = load("res://assets/sprites/FullHeart.png")
	half_heart = load("res://assets/sprites/HalfHeart.png")
	empty_heart = load("res://assets/sprites/EmptyHeart.png")
	update_hearts()

func update_hearts():
	# Clear any existing hearts
	for c in get_children():
		c.queue_free()

	var p = get_node(player)
	var health = p.current_health
	var max_health = p.max_health

	var hearts = max_health / 2
	for i in range(hearts):
		var heart = TextureRect.new()
		if health >= 2:
			heart.texture = full_heart
			health -= 2
		elif health == 1:
			heart.texture = half_heart
			health -= 1
		else:
			heart.texture = empty_heart
		# Optional: scale down if too big
		# heart.rect_min_size = Vector2(32, 32)
		add_child(heart)
