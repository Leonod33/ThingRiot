extends Control
var summary := {}
func _ready():
	theme = preload("res://polish/royal_theme.gd").make()
	$VBoxContainer.hide()
	var result = get_tree().get_meta("riot_result", {})
	summary = result
	get_tree().remove_meta("riot_result")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background = ColorRect.new()
	background.color = Color("202238")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+edge,44)
	add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	margin.add_child(column)
	add_label(column, "VICTORY — AUDIT REJECTED!" if result.get("victory",false) else "DEFEAT — THE CROWN FALLS",44)
	add_label(column, "The Bureaucrab has been overruled." if result.get("victory",false) else "Another reign awaits. Try a different royal recipe.",22)
	var seconds: int = int(result.get("elapsed",0))
	add_label(column,"%02d:%02d survived  •  Level %d  •  %d foes defeated" % [seconds/60,seconds%60,result.get("level",1),result.get("kills",0)],24)
	add_label(column,"%s\nPower %d  •  Crowns %d  •  Armour %d%%" % ["  +  ".join(result.get("weapons",["Returning Crown"])),result.get("power",1),result.get("crowns",1),int(result.get("defense",0)*100)],22)
	var combos: Array = result.get("combos",[])
	add_label(column,"Combinations discovered: %d / 2\n%s\nBiggest chain: %d links" % [combos.size(),", ".join(combos) if not combos.is_empty() else "None yet — combine crowns with crumbs or dice!",result.get("chain",0)],22)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var build: Array = result.get("build",[])
	add_label(scroll,"YOUR BUILD\n" + ("\n".join(build) if not build.is_empty() else "Starting royal equipment"),20)
	var retry = Button.new()
	retry.text = "Play again"
	retry.custom_minimum_size.y = 48
	retry.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
	column.add_child(retry)
	var title = Button.new()
	title.text = "Back to title"
	title.custom_minimum_size.y = 44
	title.pressed.connect(_on_restart_button_pressed)
	column.add_child(title)
	retry.grab_focus()
func add_label(parent: Node, text: String, font_size: int):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("fff0c5"))
	parent.add_child(label)
func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_screen.tscn")
