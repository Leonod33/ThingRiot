extends CanvasLayer  # attached to UILayer

@onready var hearts_box      := $HUD/HBoxContainer
@onready var xp_bar: ProgressBar = $HUD/XPBar
@onready var level_label: Label  = $HUD/LevelLabel
@onready var level_up_label: Label = $LevelUpLabel  # separate label node under UILayer

# Called by Player.xp_changed
func update_xp(xp: int, xp_to_next: int, level: int) -> void:
	if xp_bar == null or level_label == null:
		return
	var pct := 0
	if xp_to_next > 0:
		pct = int(clamp((float(xp) / float(xp_to_next)) * 100.0, 0.0, 100.0))
	xp_bar.max_value = 100
	xp_bar.value = pct
	level_label.text = "Lv. %d" % level

func show_level_up_at_player(player: Node2D) -> void:
	if level_up_label == null or player == null:
		return

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	# World → Screen conversion (Godot 4):
	# screen_origin_world = world position of the top-left of the screen
	var vr := get_viewport().get_visible_rect()
	var half := vr.size / 2.0
	var screen_origin_world := cam.get_screen_center_position() - half

	var screen_v2 := (player.global_position - screen_origin_world) + Vector2(0, -40)
	var screen_pos: Vector2i = Vector2i(screen_v2)

	level_up_label.text = "Lvl Up!"
	level_up_label.visible = true
	level_up_label.modulate.a = 1.0
	level_up_label.scale = Vector2(1.2, 1.2)
	level_up_label.position = screen_pos

	var tw := create_tween()
	tw.tween_property(level_up_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_property(level_up_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(Callable(level_up_label, "hide"))
