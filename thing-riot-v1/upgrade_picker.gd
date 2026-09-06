extends PopupPanel
class_name UpgradePicker

signal upgrade_picked(id: String)

var player: Node = null
var current_choices: Array = []


@onready var title_lbl: Label = %Title
@onready var btn_a: Button = %OptA
@onready var btn_b: Button = %OptB
@onready var btn_c: Button = %OptC

func _ready() -> void:
	theme = preload("res://polish/royal_theme.gd").make()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	exclusive = true
	popup_window = false
	unresizable = true
	# Button handlers
	btn_a.pressed.connect(func(): _choose(0))
	btn_b.pressed.connect(func(): _choose(1))
	btn_c.pressed.connect(func(): _choose(2))

	# Controller: A = accept focused button, B/Esc cancels (optional)
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# Optional: disallow cancel; do nothing
		get_viewport().set_input_as_handled()

# ---------- Upgrade definitions ----------

# Each entry: id, title, desc, apply(player)
func _pool() -> Array:
	return [
		{"id":"unlock_biscuit", "title":"NEW • Biscuit Blaster", "desc":"Slowing crumbs + crown ricochets", "apply":Callable(self,"_unlock_biscuit")},
		{"id":"unlock_dice", "title":"NEW • Loaded Dice", "desc":"Roll. Settle. Return crown for six!", "apply":Callable(self,"_unlock_dice")},
		{"id":"dice_radius", "title":"High Roller", "desc":"+20% Dice Blast Radius", "apply":Callable(self,"_apply_dice_radius")},
		{"id":"dice_rate", "title":"Another Throw", "desc":"15% Faster Dice (max 50%)", "apply":Callable(self,"_apply_dice_rate")},
		{"id": "crumb_radius", "title": "Family Biscuit", "desc": "+20% Crumb Patch Radius", "apply": Callable(self, "_apply_crumb_radius")},
		{"id": "crumb_life", "title": "Stale but Deadly", "desc": "+2 Seconds Crumb Duration", "apply": Callable(self, "_apply_crumb_life")},
		{"id": "royal_chain", "title": "Royal Crumble", "desc": "+1 Ricochet (max 5)", "apply": Callable(self, "_apply_royal_chain")},
		{
			"id": "spd_10",
			"title": "Swift Boots",
			"desc": "+10% Movement Speed",
			"apply": Callable(self, "_apply_spd_10"),
		},
		{
			"id": "dmg_1",
			"title": "Sharpened Crown",
			"desc": "+1 Attack Power",
			"apply": Callable(self, "_apply_dmg_1"),
		},
		{
			"id": "rate_10",
			"title": "Quick Throw",
			"desc": "-10% Attack Cooldown",
			"apply": Callable(self, "_apply_rate_10"),
		},
		{
			"id": "proj_1",
			"title": "Extra Crown",
			"desc": "+1 Projectile (max 6)",
			"apply": Callable(self, "_apply_proj_1"),
		},
		{
			"id": "range_20",
			"title": "Long Throw",
			"desc": "+20% Range",
			"apply": Callable(self, "_apply_range_20"),
		},
		{
			"id": "size_20",
			"title": "Heavy Crown",
			"desc": "+20% Projectile Size",
			"apply": Callable(self, "_apply_size_20"),
		},
		{
			"id": "kb_20",
			"title": "Knockback",
			"desc": "+20% Crown Knockback",
			"apply": Callable(self, "_apply_kb_20"),
		},
		{
			"id": "def_5",
			"title": "Armor",
			"desc": "+5% Defense (reduces damage)",
			"apply": Callable(self, "_apply_def_5"),
		},
		{
			"id": "luck_10",
			"title": "Clover",
			"desc": "+10% of base crate-drop chance",
			"apply": Callable(self, "_apply_luck_10"),
		},
		{
			"id": "hp_1",
			"title": "Heart",
			"desc": "+1 Max HP (heal 1)",
			"apply": Callable(self, "_apply_hp_1"),
		},
	]

# ---- Apply helpers ----

func _apply_spd_10(p):
	p.stats.speed *= 1.10

func _apply_dmg_1(p):
	p.stats.attack_power += 1

func _apply_rate_10(p):
	p.stats.attack_speed = max(0.05, p.stats.attack_speed * 0.90)
	if p.has_node("AttackTimer"):
		(p.get_node("AttackTimer") as Timer).wait_time = p.stats.attack_speed

func _apply_proj_1(p):
	p.stats.projectile_count = clamp(p.stats.projectile_count + 1, 1, 6)

func _apply_range_20(p):
	p.stats.projectile_range *= 1.20

func _apply_size_20(p):
	p.stats.projectile_size *= 1.20

func _apply_kb_20(p):
	p.stats.knockback_power *= 1.20

func _apply_def_5(p):
	p.stats.defense = clamp(p.stats.defense + 0.05, 0.0, 0.8)

func _apply_luck_10(p):
	p.stats.luck = minf(1.0, p.stats.luck + 0.10)

func _apply_hp_1(p):
	p.stats.max_health += 1
	p.max_health = p.stats.max_health
	p.current_health = min(p.current_health + 1, p.max_health)
	p.get_node("/root/Main/UILayer/HUD/HBoxContainer").update_hearts()

# ---------- Open / choose ----------

func open_for(player_ref: Node) -> void:
	player = player_ref
	# Pause game and show
	get_tree().paused = true
	# pick 3 unique choices
	var pool := _pool().filter(func(choice): return _is_available(choice["id"]))
	pool.shuffle()
	var unlocks = pool.filter(func(choice): return choice["id"].begins_with("unlock_"))
	var upgrades = pool.filter(func(choice): return not choice["id"].begins_with("unlock_"))
	current_choices = unlocks + upgrades.slice(0,3-unlocks.size())
	# Fill buttons
	_set_button(btn_a, current_choices[0])
	_set_button(btn_b, current_choices[1])
	_set_button(btn_c, current_choices[2])
	get_node("Center").set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_centered(Vector2i(1040,260))
	btn_a.grab_focus()

func _set_button(btn: Button, choice: Dictionary) -> void:
	var lines := ""
	var width := 0
	for word in str(choice["desc"]).split(" "):
		if width + word.length() > 27:
			lines += "\n"
			width = 0
		lines += word + " "
		width += word.length()+1
	btn.text = "%s\n\n%s" % [choice["title"],lines.strip_edges()]
	btn.add_theme_font_size_override("font_size",17)
	btn.focus_mode = Control.FOCUS_ALL
	# (Optional) wider buttons:
	btn.custom_minimum_size = Vector2(320, 126)

func _choose(index: int) -> void:
	if not visible or player == null or index < 0 or index >= current_choices.size():
		return
	var choice : Dictionary = current_choices[index]
	(choice["apply"] as Callable).call(player)
	var director = get_tree().current_scene.get_node_or_null("RunDirector")
	if director:
		director.record_upgrade(choice["title"])
	hide()
	current_choices.clear()
	emit_signal("upgrade_picked", choice["id"])

func _is_available(id: String) -> bool:
	var weapons = player.get_node("Weapons")
	if id in ["dice_radius","dice_rate"] and not weapons.equipped.dice:
		return false
	if id in ["crumb_radius","crumb_life","royal_chain"] and not weapons.equipped.biscuit:
		return false
	match id:
		"unlock_biscuit": return not weapons.equipped.biscuit
		"unlock_dice": return not weapons.equipped.dice
		"dice_radius": return player.get_node("Weapons").dice.patch_radius < 219.99
		"dice_rate": return player.get_node("Weapons").dice.cooldown > 1.20001
		"crumb_radius": return player.get_node("Weapons").biscuit.patch_radius < 239.99
		"crumb_life": return player.get_node("Weapons").biscuit.patch_lifetime < 12.0
		"royal_chain": return player.get_node("Weapons").crown.bounce_limit < 5
		"proj_1": return player.stats.projectile_count < 6
		"rate_10": return player.stats.attack_speed > 0.050001
		"def_5": return player.stats.defense < 0.799999
		"luck_10": return player.stats.luck < 0.999999
	return true

func _apply_crumb_radius(p):
	p.get_node("Weapons").biscuit.patch_radius = minf(240.0, p.get_node("Weapons").biscuit.patch_radius * 1.2)

func _apply_crumb_life(p):
	p.get_node("Weapons").biscuit.patch_lifetime = minf(12.0, p.get_node("Weapons").biscuit.patch_lifetime + 2.0)

func _apply_royal_chain(p):
	p.get_node("Weapons").crown.bounce_limit = mini(5, p.get_node("Weapons").crown.bounce_limit + 1)

func _apply_dice_radius(p):
	p.get_node("Weapons").dice.patch_radius = minf(220.0,p.get_node("Weapons").dice.patch_radius*1.2)

func _apply_dice_rate(p):
	p.get_node("Weapons").dice.cooldown = maxf(1.2,p.get_node("Weapons").dice.cooldown*0.85)

func _unlock_biscuit(p):
	p.get_node("Weapons").unlock("biscuit")

func _unlock_dice(p):
	p.get_node("Weapons").unlock("dice")
