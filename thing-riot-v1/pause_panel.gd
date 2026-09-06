extends Panel

var player: Node = null

@onready var stats_label: Label = %StatsLabel
@onready var resume_btn: Button = %ResumeButton
@onready var quit_btn: Button   = %QuitButton



func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)

	if is_instance_valid(resume_btn):
		resume_btn.pressed.connect(_on_resume_pressed)
	if is_instance_valid(quit_btn):
		quit_btn.pressed.connect(_on_quit_pressed)

	# ensure we cover the screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(0, 0)

	

	print("[PausePanel] ready (WhenPaused)")

func open(p: Node) -> void:
	player = p
	print("[PausePanel] open()")
	_refresh()
	stats_label.add_theme_font_size_override("font_size",24)
	show()
	resume_btn.grab_focus()  # start with Resume focused

func close() -> void:
	print("[PausePanel] close()")
	hide()


func _on_resume_pressed() -> void:
	get_tree().paused = false
	close()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_screen.tscn")  # adjust path if needed

func _refresh() -> void:
	if player == null:
		return
	print("[PausePanel] refresh()")
	var s: PlayerStats = player.stats

	var lines: Array[String] = []
	
	lines.append("")
	lines.append("Level: %d" % player.level)
	lines.append("XP: %d / %d" % [player.xp, player.xp_to_next])
	lines.append("HP: %.2f / %d" % [player.current_health, player.max_health])
	lines.append("")
	lines.append("Speed: %.0f px/s" % s.speed)
	lines.append("Attack Power: %d" % s.attack_power)
	lines.append("Attack Speed: %.2f s" % s.attack_speed)
	lines.append("Projectile Count: %d" % s.projectile_count)
	lines.append("Projectile Range: %.0f" % s.projectile_range)
	lines.append("Projectile Size: x%.2f" % s.projectile_size)
	lines.append("Knockback: %.0f" % s.knockback_power)
	lines.append("Defense: %.0f%%" % (s.defense * 100.0))
	lines.append("Luck: %.0f%%" % (s.luck * 100.0))

	stats_label.text = "\n".join(lines)
	stats_label.text += "\n\nWASD / arrows: move • RMB / right stick: aim\nM: sound • Esc: resume\nReturn crown to settled dice for a Royal Six."

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause") and not event.is_echo():
		_on_resume_pressed()
		get_viewport().set_input_as_handled()
