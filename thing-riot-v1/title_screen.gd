extends Control
func _ready():
	$VBoxContainer.hide()
	theme = preload("res://polish/royal_theme.gd").make()
	add_child(preload("res://polish/menu_art.gd").new())
	var column := VBoxContainer.new()
	column.position = Vector2(290,105)
	column.size = Vector2(700,600)
	column.add_theme_constant_override("separation",16)
	add_child(column)
	label(column,"THE ROYAL CRUMBLE",18)
	label(column,"THING RIOT",76)
	label(column,"A small king. An unreasonable amount of trouble.",22)
	label(column,"Start with your Returning Crown.\nCollect gems, choose new weapons, discover royal recipes.\nSurvive the riot. Reject the Bureaucrab's final audit.",20)
	var start := Button.new()
	start.text = "Begin your reign"
	start.custom_minimum_size.y = 64
	start.pressed.connect(_start_game)
	column.add_child(start)
	var options := HBoxContainer.new()
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(options)
	for option in [["Music","music_on",true],["Sound","sound_on",true],["Shake","shake_on",false],["Impact pause","impact_on",true]]:
		var toggle := CheckButton.new()
		toggle.text = option[0]
		toggle.button_pressed = get_tree().get_meta(option[1],option[2])
		var key: String = option[1]
		toggle.toggled.connect(func(on): get_tree().set_meta(key,on))
		options.add_child(toggle)
	label(column,"Move: WASD / arrows / left stick   •   Attacks aim automatically\nOptional aim: hold right mouse / right stick   •   Esc: pause",16)
	start.grab_focus()
func label(parent: Node, text: String, font_size: int):
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",font_size)
	parent.add_child(l)
func _on_start_button_pressed():
	_start_game()
func _start_game():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")
