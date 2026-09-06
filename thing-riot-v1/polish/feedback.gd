extends CanvasLayer
# All sounds are original synthesized phrases, cached once per run.
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

func phrase(notes: Array, beat: float, looped := false) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * beat * notes.size())
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / rate
		var n := mini(notes.size()-1, int(t / beat))
		var local := fmod(t, beat)
		var freq := float(notes[n])
		var envelope := minf(local / 0.008, 1.0) * pow(1.0-local/beat, 2)
		var tone := (sin(TAU*freq*local) + 0.22*sin(TAU*freq*2*local)) if freq > 0 else 0.0
		data.encode_s16(i*2, int(tone*envelope*6500))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	if looped:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = count
	return wav

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	camera = get_parent().get_node("Player/Camera2D")
	rng.seed = 9042
	for group in ["launch","impact","damage","signature"]:
		voices[group] = []
		for i in range(3 if group in ["launch","impact"] else 1):
			var voice := AudioStreamPlayer.new()
			add_child(voice)
			voices[group].append(voice)
	music = AudioStreamPlayer.new()
	music.volume_db = -24
	add_child(music)
	sounds.hurt = material(95,0.19,0.55,0.3)
	sounds.crown = material(680,0.09,0.05,0.55)
	sounds.crown_hit = material(1100,0.12,0.1,0.8)
	sounds.catch = material(720,0.055,0,0.3)
	sounds.biscuit = material(180,0.08,0.5,0.05)
	sounds.crunch = material(125,0.15,0.9,0.08)
	sounds.throw_die = material(150,0.1,0.25,0.05)
	sounds.clack = material(360,0.065,0.5,0.15)
	sounds.dice = material(72,0.23,0.35,0.15)
	sounds.stamp = material(55,0.28,0.5,0.05)
	sounds.pickup = phrase([880,1100],0.025)
	sounds.six = phrase([392,494,587,784],0.075)
	sounds.crumble = phrase([587,740,880],0.055)
	sounds.unlock = phrase([392,494,587,784],0.12)
	sounds.arrival = phrase([147,0,147,156,0,98],0.14)
	sounds.victory = phrase([392,494,587,0,784,0,587,784],0.13)
	# Longer phrases with rests: quiet rhythmic space, not a continuous alarm.
	sounds[0] = phrase([196,0,294,247,0,294,220,0,330,0,247,294,0,247,220,0],0.36,true)
	sounds[1] = phrase([196,392,0,294,392,0,220,440,0,330,294,0,247,392,0,294],0.28,true)
	sounds[2] = phrase([147,0,294,156,311,0,147,294,0,220,196,0,147,311,294,0],0.22,true)
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

func material(freq: float, duration: float, noise: float, metal: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration*rate)
	var data := PackedByteArray()
	data.resize(count*2)
	for i in range(count):
		var t := float(i)/rate
		var envelope := minf(t/0.002,1.0)*pow(1.0-t/duration,2)
		var body := sin(TAU*freq*t)*0.6 + sin(TAU*freq*2.76*t)*metal*0.35
		body += rng.randf_range(-1,1)*noise*pow(1.0-t/duration,4)
		data.encode_s16(i*2,int(clampf(body*envelope,-1,1)*12000))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

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
	chosen.stream = sounds[kind]
	chosen.pitch_scale = 1.0 if group in ["damage","signature"] else rng.randf_range(0.96,1.04)
	chosen.volume_db = -10 if group == "damage" else (-13 if group == "signature" else -22+rng.randf_range(-1,1))
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
	music.volume_db = -32 if duck_time > 0 else -24
	for group in ["launch","impact"]:
		for voice in voices[group]:
			voice.volume_db = float(voice.get_meta("base_db",-22.0)) - (8.0 if duck_time > 0 else 0.0)
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
	if stage != music_stage:
		music_stage = stage
		music.stream = sounds[stage]
		music.play()
	music.stream_paused = get_tree().paused or not get_tree().get_meta("music_on",true)
	if not get_tree().get_meta("sound_on",true):
		for group in voices.values():
			for voice in group:
				voice.stop()

func _exit_tree():
	Engine.time_scale = 1.0
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
