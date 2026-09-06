extends Control
var player: Node
var run: Node
var previous_hp := 6.0
var trailing_hp := 6.0
var trailing_boss := 240.0
var damage_hold := 0.0
var refresh := 0.0
var icons: Array = []
const INK = Color("172238")
const CREAM = Color("fff0c5")
func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player = get_parent().get_parent().get_node("Player")
	run = get_parent().get_parent().get_node("RunDirector")
	previous_hp = player.current_health
	trailing_hp = previous_hp
	for i in range(3):
		var icon = preload("res://polish/weapon_icon.gd").new()
		icon.kind = ["crown","biscuit","dice"][i]
		icon.position = Vector2(25+i*184,722)
		icon.size = Vector2(44,44)
		add_child(icon)
		icons.append(icon)
func _process(delta):
	if player.current_health < previous_hp:
		damage_hold = 0.5
	previous_hp = player.current_health
	damage_hold = maxf(0,damage_hold-delta)
	if damage_hold <= 0:
		trailing_hp = move_toward(trailing_hp,player.current_health,delta*3)
	trailing_hp = maxf(trailing_hp,player.current_health)
	if is_instance_valid(run.boss):
		trailing_boss = move_toward(trailing_boss,maxf(0,run.boss.hp),delta*45)
	refresh -= delta
	if refresh <= 0:
		refresh = 0.05
		var weapons = player.get_node_or_null("Weapons")
		if weapons:
			for icon in icons:
				if icon.active != weapons.equipped[icon.kind]:
					icon.active = weapons.equipped[icon.kind]
					icon.queue_redraw()
		queue_redraw()
func label_at(point: Vector2, text: String, font_size := 18, colour := CREAM):
	draw_string(ThemeDB.fallback_font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,colour)
func panel(rect: Rect2):
	draw_style_box(preload("res://polish/royal_theme.gd").box(INK,Color("526077"),1),rect)
func _draw():
	if not is_instance_valid(player) or not is_instance_valid(run):
		return
	panel(Rect2(16,16,280,86))
	label_at(Vector2(30,39),"THE KING",15)
	label_at(Vector2(180,39),"%.1f / %d" % [player.current_health,player.max_health],16)
	draw_rect(Rect2(30,49,252,14),Color("364057"))
	draw_rect(Rect2(30,49,252*clampf(trailing_hp/player.max_health,0,1),14),Color("fff0c5"))
	draw_rect(Rect2(30,49,252*clampf(player.current_health/player.max_health,0,1),14),Color("85c9e0"))
	draw_rect(Rect2(30,76,198,5),Color("364057"))
	draw_rect(Rect2(30,76,198*float(player.xp)/player.xp_to_next,5),Color("e7bd70"))
	label_at(Vector2(237,84),"Lv.%d" % player.level,14)
	panel(Rect2(420,16,440,64))
	label_at(Vector2(438,41),"%02d:%02d   %s" % [int(run.elapsed)/60,int(run.elapsed)%60,"FINAL AUDIT" if run.boss_started else run.WAVES[run.wave_index()]],19)
	label_at(Vector2(438,64),"THE BUREAUCRAB" if run.boss_started else ("Breather — collect gems" if run.is_break() else "Survive until the final audit"),15,Color("aab9cc"))
	if is_instance_valid(run.boss):
		panel(Rect2(420,88,440,29))
		draw_rect(Rect2(432,98,416*clampf(trailing_boss/run.boss.max_hp,0,1),9),CREAM)
		draw_rect(Rect2(432,98,416*clampf(float(run.boss.hp)/run.boss.max_hp,0,1),9),Color("e7bd70"))
	for i in range(3):
		panel(Rect2(16+i*184,712,176,64))
		label_at(Vector2(76+i*184,738),["CROWN","BISCUIT","DICE"][i],16)
		label_at(Vector2(76+i*184,759),"Equipped" if icons[i].active else "Level-up unlock",12,Color("aab9cc"))
	var w = player.get_node_or_null("Weapons")
	if w:
		label_at(Vector2(1110,781),"MANUAL AIM" if w.manual else "AUTO AIM",16)
	if run.elapsed < 12:
		label_at(Vector2(590,729),"Move: WASD / arrows • Optional aim: hold RMB",16)
		label_at(Vector2(590,753),"Esc: pause / help • M: sound",16)
