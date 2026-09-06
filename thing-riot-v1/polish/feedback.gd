extends CanvasLayer
# All sounds are original synthesized phrases, cached once per run.
var sounds := {}
var voice: AudioStreamPlayer
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
		var tone := sin(TAU*freq*local) + 0.22*sin(TAU*freq*2*local)
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
	voice = AudioStreamPlayer.new()
	voice.volume_db = -12
	add_child(voice)
	music = AudioStreamPlayer.new()
	music.volume_db = -24
	add_child(music)
	sounds.hurt = phrase([140,100,70],0.055)
	sounds.dice = phrase([130,90],0.07)
	sounds.six = phrase([392,494,587,784],0.065)
	sounds.unlock = phrase([392,494,587,784],0.12)
	sounds[0] = phrase([196,294,247,294,220,330,247,294],0.36,true)
	sounds[1] = phrase([196,392,294,392,220,440,330,294],0.26,true)
	sounds[2] = phrase([147,294,156,311,147,294,220,196],0.19,true)
	wash = ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.color = Color(1,0.85,0.6,0)
	add_child(wash)
	message = Label.new()
	message.position = Vector2(440,650)
	message.size = Vector2(400,70)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size",24)
	message.add_theme_color_override("font_shadow_color",Color.BLACK)
	message.add_theme_constant_override("shadow_offset_y",2)
	message.text = "HIT!  Keep moving\nBrief shield + escape boost"
	message.hide()
	add_child(message)

func sound(kind: String):
	if get_tree().get_meta("sound_on",true) and sounds.has(kind):
		voice.stream = sounds[kind]
		voice.play()

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
		voice.stop()

func _exit_tree():
	Engine.time_scale = 1.0
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
