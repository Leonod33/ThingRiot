extends Node2D
const Shot = preload("res://weapons/riot_projectile.gd")
var crown = preload("res://weapons/crown.tres")
var biscuit = preload("res://weapons/biscuit.tres")
var player: Node2D
var crown_timer := 0.15
var biscuit_timer := 0.05
var manual := false
var aim := Vector2.RIGHT
var combo_count := 0
var combo_time := 0.0
var sound_cooldown := 0.0
var muted := false
var readout: Label
var combo_label: Label
var audio: AudioStreamPlayer
var tones := {}
var performance_label: Label
var performance_timer := 0.0

func _ready():
	player = get_parent()
	crown = crown.duplicate(true)
	biscuit = biscuit.duplicate(true)
	audio = AudioStreamPlayer.new()
	audio.volume_db = -20
	add_child(audio)
	for kind in ["crown", "biscuit", "combo"]:
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = 22050
		var data := PackedByteArray()
		data.resize(2205 * 2)
		var freq: float = {"crown": 520.0, "biscuit": 190.0, "combo": 880.0}[kind]
		for i in range(2205):
			var sample = int(sin(TAU * freq * i / 22050.0) * (1.0 - float(i) / 2205) * 9000)
			data.encode_s16(i * 2, sample)
		wav.data = data
		tones[kind] = wav
	var ui = CanvasLayer.new()
	add_child(ui)
	readout = Label.new()
	readout.position = Vector2(16, 125)
	readout.add_theme_font_size_override("font_size", 16)
	ui.add_child(readout)
	performance_label = Label.new()
	performance_label.position = Vector2(930, 16)
	performance_label.add_theme_font_size_override("font_size", 16)
	performance_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	performance_label.add_theme_constant_override("shadow_offset_x", 1)
	performance_label.add_theme_constant_override("shadow_offset_y", 1)
	performance_label.hide()
	ui.add_child(performance_label)
	combo_label = Label.new()
	combo_label.position = Vector2(16, 242)
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.add_theme_color_override("font_color", Color("ffe090"))
	ui.add_child(combo_label)

func _process(delta):
	if not performance_label.visible:
		return
	performance_timer -= delta
	if performance_timer <= 0:
		performance_timer = 0.5
		performance_label.text = "FPS: %d | physics: %.1f ms\nEnemies: %d | hostile shots: %d\nRoyal shots: %d | crumb patches: %d\nF3: hide performance" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000, get_tree().get_nodes_in_group("enemies").size(), get_tree().get_nodes_in_group("enemy_bolts").size(), get_tree().get_nodes_in_group("riot_projectiles").size(), get_tree().get_nodes_in_group("crumb_patches").size()]

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		performance_label.visible = not performance_label.visible
		performance_timer = 0.0
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		muted = not muted
		if muted:
			audio.stop()

func _physics_process(delta):
	if player.dead:
		return
	sound_cooldown = maxf(0, sound_cooldown - delta)
	combo_time = maxf(0, combo_time - delta)
	combo_label.visible = combo_time > 0
	manual = false
	var pads = Input.get_connected_joypads()
	if not pads.is_empty():
		var stick = Vector2(Input.get_joy_axis(pads[0], JOY_AXIS_RIGHT_X), Input.get_joy_axis(pads[0], JOY_AXIS_RIGHT_Y))
		if stick.length() > 0.25:
			manual = true
			aim = stick.normalized()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		manual = true
		aim = player.global_position.direction_to(get_global_mouse_position())
	var target: Node2D = null
	var closest: float = crown.reach * player.stats.projectile_range / 300.0
	if not manual:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.dead:
				continue
			var d = player.global_position.distance_to(enemy.global_position)
			if d < closest:
				closest = d
				target = enemy
		if target:
			aim = player.global_position.direction_to(target.global_position)
	crown_timer -= delta
	biscuit_timer -= delta
	if manual or target:
		if biscuit_timer <= 0:
			fire(biscuit)
			biscuit_timer = biscuit.cooldown * player.stats.attack_speed
		if crown_timer <= 0:
			fire(crown)
			crown_timer = crown.cooldown * player.stats.attack_speed
	readout.text = "RETURNING CROWN + BISCUIT BLASTER\n%s  |  Hold RMB / right stick to aim\nWASD / arrows / left stick  •  M: sound %s\nCrumbs enable ricochets. Bomb crates blast foes; spring pads launch." % ["MANUAL AIM" if manual else "AUTO AIM", "OFF" if muted else "ON"]
	queue_redraw()

func fire(spec: Resource):
	var count: int = player.stats.projectile_count if spec.kind == "crown" else 1
	for i in range(count):
		if get_tree().get_nodes_in_group("riot_projectiles").size() >= 48:
			return
		var shot = Shot.new()
		shot.spec = spec
		shot.owner_player = player
		shot.controller = self
		shot.direction = aim.rotated((i - (count - 1) * 0.5) * 0.12)
		shot.damage = player.stats.attack_power
		shot.knockback = player.stats.knockback_power
		shot.size_mult = player.stats.projectile_size
		shot.reach = spec.reach * player.stats.projectile_range / 300.0
		get_tree().current_scene.add_child(shot)
		shot.global_position = player.global_position + shot.direction * 22
	play_tone(spec.kind)

func play_tone(kind: String):
	if muted or (sound_cooldown > 0 and kind != "combo"):
		return
	audio.stream = tones[kind]
	audio.play()
	sound_cooldown = 0.08

func celebrate_combo(chain: int):
	combo_count += 1
	combo_time = 1.3
	combo_label.text = "ROYAL CRUMBLE!  ×%d" % chain
	play_tone("combo")

func _draw():
	if manual:
		var point = aim * 90
		draw_arc(point, 10, 0, TAU, 24, Color.WHITE, 2)
		draw_line(point - Vector2(15,0), point + Vector2(15,0), Color.WHITE, 1)
		draw_line(point - Vector2(0,15), point + Vector2(0,15), Color.WHITE, 1)
