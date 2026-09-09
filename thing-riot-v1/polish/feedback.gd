extends CanvasLayer
# Original offline recordings; no synthesis or buffer allocation during combat.
const BANK = preload("res://polish/audio_bank.gd")
const MUSIC_FADE := 60.0/112.0*4.0
var variants := {}
var previous_variant := {}
var music_players: Array[AudioStreamPlayer] = []
var music_index := 0
var music_from := -1
var music_blend := 1.0
var duck_gain := 0.0
var sounds := {}
var voices := {}
var last_sound := {}
var duck_time := 0.0
var rng := RandomNumberGenerator.new()
var banner: Label
var banner_time := 0.0
var music: AudioStreamPlayer
var music_stage := -1
var hurt_time := 0.0
var wash: ColorRect
var message: Label
var camera: Camera2D
var freeze_active := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	camera = get_parent().get_node("Player/Camera2D")
	rng.seed = 9042
	setup_buses()
	variants = BANK.VARIANTS
	for kind in variants:
		sounds[kind] = variants[kind][0]
		for recording in variants[kind]:
			recording.loop = false
	for group in ["launch","impact","damage","signature"]:
		voices[group] = []
		for i in range(3 if group in ["launch","impact"] else 1):
			var voice := AudioStreamPlayer.new()
			voice.bus = "RiotPriority" if group in ["damage","signature"] else "RiotEffects"
			add_child(voice)
			voices[group].append(voice)
	for i in range(2):
		var voice := AudioStreamPlayer.new()
		voice.bus = "RiotMusic"
		voice.volume_db = -60
		add_child(voice)
		music_players.append(voice)
	music = music_players[0]
	wash = ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.color = Color(1,0.85,0.6,0)
	add_child(wash)
	message = Label.new()
	message.position = Vector2.ZERO
	message.size = Vector2(120,40)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size",24)
	message.add_theme_color_override("font_shadow_color",Color.BLACK)
	message.add_theme_constant_override("shadow_offset_y",2)
	message.text = "HIT!"
	message.hide()
	add_child(message)
	banner = Label.new()
	banner.position = Vector2(300,594)
	banner.size = Vector2(680,80)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size",30)
	banner.add_theme_color_override("font_color",Color("fff0c5"))
	banner.add_theme_color_override("font_shadow_color",Color("172238"))
	banner.add_theme_constant_override("shadow_offset_y",3)
	banner.hide()
	add_child(banner)

func setup_buses():
	if AudioServer.get_bus_index("RiotMix") >= 0:
		return
	for bus_name in ["RiotMix","RiotMusic","RiotEffects","RiotPriority"]:
		AudioServer.add_bus()
		var index := AudioServer.bus_count-1
		AudioServer.set_bus_name(index,bus_name)
		AudioServer.set_bus_send(index,"Master" if bus_name == "RiotMix" else "RiotMix")
	var compressor := AudioEffectCompressor.new()
	compressor.threshold = -7
	compressor.ratio = 4
	compressor.attack_us = 1500
	compressor.release_ms = 120
	AudioServer.add_bus_effect(AudioServer.get_bus_index("RiotEffects"),compressor)
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = -1.5
	limiter.threshold_db = -3
	limiter.soft_clip_db = 0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("RiotMix"),limiter)

func choose_recording(kind: String) -> AudioStream:
	var pool: Array = variants[kind]
	var previous: int = previous_variant.get(kind,-1)
	var index := 0
	if pool.size() > 1:
		index = rng.randi_range(0,pool.size()-1 if previous < 0 else pool.size()-2)
		if index >= previous and previous >= 0:
			index += 1
	previous_variant[kind] = index
	return pool[index]

func transition_music(stage: int):
	var phase := music.get_playback_position() if music.playing else 0.0
	music_from = music_index if music_stage >= 0 else -1
	music_index = 1-music_index if music_from >= 0 else 0
	music_stage = stage
	music = music_players[music_index]
	music.stream = BANK.MUSIC[stage]
	music.stream.loop = true
	music.play(fmod(phase,music.stream.get_length()))
	music_blend = 0.0

func update_music(delta: float, stage: int):
	if stage != music_stage:
		transition_music(stage)
	var suspended: bool = get_tree().paused or not get_tree().get_meta("music_on",true)
	if not suspended:
		music_blend = minf(1,music_blend+delta/MUSIC_FADE)
	var gain := sin(music_blend*PI/2)
	music.volume_db = -8+linear_to_db(maxf(gain,0.001))-duck_gain*7
	for voice in music_players:
		voice.stream_paused = suspended
	if music_from >= 0:
		var previous := music_players[music_from]
		previous.volume_db = -8+linear_to_db(maxf(cos(music_blend*PI/2),0.001))-duck_gain*7
		if music_blend >= 1:
			previous.stop()
			music_from = -1

func sound(kind: String):
	if not get_tree().get_meta("sound_on",true) or not sounds.has(kind):
		return
	var group := "impact"
	if kind in ["crown","biscuit","throw_die","catch"]:
		group = "launch"
	elif kind == "hurt":
		group = "damage"
	elif kind in ["six","crumble","unlock","arrival","victory"]:
		group = "signature"
	var now := Time.get_ticks_msec()/1000.0
	var interval := 0.08 if group == "launch" else 0.06
	if group == "signature":
		interval = 0.8 if kind == "crumble" else 0.25
	if now-float(last_sound.get(kind,-10.0)) < interval:
		return
	last_sound[kind] = now
	var chosen: AudioStreamPlayer
	for voice in voices[group]:
		if not voice.playing:
			chosen = voice
			break
	if not chosen:
		if group in ["launch","impact"]:
			return
		# A chain or six cannot interrupt an arrival, unlock or victory motif.
		if group == "signature" and kind in ["six","crumble"]:
			return
		chosen = voices[group][0]
	if group in ["damage","signature"]:
		duck_time = 0.4
	chosen.stream = choose_recording(kind)
	if group in ["damage","signature"]:
		duck_time = maxf(duck_time,minf(1.4,chosen.stream.get_length()*0.85))
	chosen.pitch_scale = 1.0 if group in ["damage","signature"] else rng.randf_range(0.985,1.015)
	chosen.volume_db = -6 if group == "damage" else (-11 if group == "signature" else -16+rng.randf_range(-1,1))
	if kind in ["pickup","catch"]:
		chosen.volume_db -= 5
	chosen.set_meta("base_db",chosen.volume_db)
	chosen.play()

func announce(text: String, duration := 1.8):
	banner.text = text
	banner_time = duration

func hurt():
	hurt_time = 0.7
	sound("hurt")
	if get_tree().get_meta("impact_on",true) and not freeze_active:
		freeze_active = true
		Engine.time_scale = 0.25
		get_tree().create_timer(0.045,true,false,true).timeout.connect(func():
			Engine.time_scale = 1.0
			freeze_active = false)

func _process(delta):
	duck_time = maxf(0,duck_time-delta)
	banner_time = maxf(0,banner_time-delta)
	banner.visible = banner_time > 0
	banner.modulate.a = minf(1,banner_time*3)
	duck_gain = move_toward(duck_gain,1.0 if duck_time > 0 else 0.0,delta*(18.0 if duck_time > 0 else 2.5))
	for group in ["launch","impact"]:
		for voice in voices[group]:
			voice.volume_db = float(voice.get_meta("base_db",-22.0)) - duck_gain*7.0
	var p = get_parent().get_node("Player")
	message.position = p.get_global_transform_with_canvas().origin + Vector2(-60,-100)
	hurt_time = maxf(0,hurt_time-delta)
	wash.color.a = maxf(0,hurt_time-0.55)*0.8
	message.visible = hurt_time > 0
	message.modulate.a = minf(1,hurt_time*4)
	if is_instance_valid(camera):
		camera.offset = Vector2(sin(hurt_time*180),cos(hurt_time*151))*maxf(0,hurt_time-0.5)*22 if get_tree().get_meta("shake_on",false) else Vector2.ZERO
	var run = get_parent().get_node_or_null("RunDirector")
	var stage := 0
	if run:
		stage = 2 if run.elapsed >= 420 else (1 if run.elapsed >= 180 else 0)
	update_music(delta,stage)
	if not get_tree().get_meta("sound_on",true):
		for group in voices.values():
			for voice in group:
				voice.stop()

func _exit_tree():
	Engine.time_scale = 1.0
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
