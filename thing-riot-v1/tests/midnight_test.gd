extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize():
	call_deferred("run")
func settle():
	await process_frame
	await process_frame
	await physics_frame
func run():
	set_meta("impact_on",false)
	set_meta("music_on",false)
	change_scene_to_file("res://main.tscn")
	await settle()
	var game = current_scene
	var p = game.get_node("Player")
	game.get_node("EnemySpawner").set_process(false)
	game.get_node("RunDirector").set_process(false)
	p.set_physics_process(false)
	p.get_node("Weapons").set_physics_process(false)
	var courtyard = game.get_node("Courtyard")
	check(not game.get_node("Level1").visible,"legacy bright grass is hidden")
	var bus_count := AudioServer.bus_count
	var f = game.get_node("Feedback")
	f.set_process(false)
	f.setup_buses()
	check(AudioServer.bus_count == bus_count,"audio buses never multiply on restart")
	check(AudioServer.get_bus_effect_count(AudioServer.get_bus_index("RiotMix")) == 1,"mix has a bounded output limiter")
	check(f.music_players.size() == 2,"music crossfade is limited to two streams")
	for track in f.BANK.MUSIC:
		check(track.get_length() > 60 and track.get_length() < 70,"full-length music arrangement imported")
	var last: AudioStream
	for i in range(12):
		var recording: AudioStream = f.choose_recording("crunch")
		check(recording != last,"material variations never repeat consecutively")
		last = recording
	seed(771)
	var expected := randi()
	seed(771)
	f.choose_recording("crown")
	check(randi() == expected,"audio variation preserves gameplay randomness")
	seed(441)
	expected = randi()
	seed(441)
	for i in range(6):
		p.global_position = Vector2(1800+i*1800,1500+i*900)
		courtyard._process(0)
		check(courtyard.decorations <= 125 and courtyard.scenery.get_child_count() <= 125,"travelling keeps decoration count bounded")
	check(randi() == expected,"arena decoration preserves gameplay randomness")
	f.hurt()
	var hurt_stream = f.voices.damage[0].stream
	for kind in ["crunch","clack","bomb","stamp","six"]:
		f.sound(kind)
	check(f.voices.damage[0].stream == hurt_stream,"busy material mix preserves the damage cue")
	set_meta("sound_on",false)
	f._process(0.02)
	check(not f.voices.damage[0].playing,"sound toggle stops existing sound voices")
	set_meta("music_on",true)
	f.update_music(0.1,0)
	f.update_music(0.1,1)
	check(f.music_from >= 0 and f.music_blend < 1,"stage transition crossfades rather than replacing abruptly")
	paused = true
	var blend: float = f.music_blend
	f.update_music(0.5,1)
	check(f.music_blend == blend and f.music.stream_paused,"pause freezes both music and crossfade")
	paused = false
	f.update_music(3,1)
	check(f.music_from == -1 and f.music.stream.loop,"crossfade releases old voice and new music loops")
	print("MIDNIGHT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
