extends Node2D

@onready var pause_panel := $UILayer/PausePanel
@onready var player := $Player
@onready var upgrade_picker: UpgradePicker = $UILayer/UpgradePicker

var pending_level_ups: int = 0
var run: Node

func _ready() -> void:
	get_tree().paused = false
	add_child(preload("res://arena/courtyard.gd").new())
	add_child(preload("res://polish/atmosphere.gd").new())
	run = preload("res://run/run_director.gd").new()
	run.name = "RunDirector"
	add_child(run)
	var feedback = preload("res://polish/feedback.gd").new()
	feedback.name = "Feedback"
	add_child(feedback)
	$UILayer/HUD.hide()
	var combat_hud = preload("res://polish/combat_hud.gd").new()
	$UILayer.add_child(combat_hud)
	$UILayer.move_child(combat_hud,0)
	pause_panel.remove_theme_stylebox_override("panel")
	pause_panel.theme = preload("res://polish/royal_theme.gd").make()
	# You already refresh the pause panel on stat changes:
	player.level_up.connect(_on_player_stats_changed)
	player.xp_changed.connect(_on_player_stats_changed)

	# --- Upgrade system wiring ---
	player.level_up.connect(_on_player_level_up)
	upgrade_picker.upgrade_picked.connect(_on_upgrade_picked)

func _input(event: InputEvent) -> void:
	# Ignore pause input while the upgrade picker is open
	if pending_level_ups > 0 or (run and run.victory_pending):
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		print("[Main] pause action detected")
		_toggle_pause()

func _toggle_pause() -> void:
	var pausing := not get_tree().paused
	get_tree().paused = pausing
	print("[Main] set paused =", pausing)
	if pausing:
		print("[Main] calling pause_panel.open()")
		pause_panel.open(player)
	else:
		print("[Main] calling pause_panel.close()")
		pause_panel.close()

func _on_player_stats_changed(_a = 0, _b = 0, _c = 0) -> void:
	if pause_panel.visible:
		pause_panel._refresh()

# ---------- Upgrade picker glue ----------

func _on_player_level_up(_level: int) -> void:
	if run and (run.ended or run.victory_pending):
		return
	pending_level_ups += 1
	get_tree().paused = true
	pause_panel.close()
	if pending_level_ups == 1:
		_open_next_upgrade.call_deferred()

func _on_upgrade_picked(_id: String) -> void:
	pending_level_ups = maxi(0, pending_level_ups - 1)
	if pending_level_ups > 0:
		_open_next_upgrade.call_deferred()
	else:
		get_tree().paused = false

func _open_next_upgrade() -> void:
	if pending_level_ups > 0 and not upgrade_picker.visible:
		upgrade_picker.open_for(player)
