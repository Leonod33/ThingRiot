extends RefCounted
static func box(colour: Color, border: Color, width := 2) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = colour
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(10)
	b.content_margin_left = 20
	b.content_margin_right = 20
	b.content_margin_top = 12
	b.content_margin_bottom = 12
	return b
static func make() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	t.set_color("font_color","Label",Color("fff1d0"))
	t.set_stylebox("normal","Button",box(Color("25364f"),Color("65758b")))
	t.set_stylebox("hover","Button",box(Color("364d6b"),Color("ffe09a")))
	t.set_stylebox("pressed","Button",box(Color("4f4268"),Color.WHITE))
	t.set_stylebox("focus","Button",box(Color(0,0,0,0),Color("ffe09a"),3))
	t.set_stylebox("panel","PopupPanel",box(Color("141f33"),Color("e7bd70")))
	t.set_stylebox("panel","Panel",box(Color("141f33"),Color("e7bd70")))
	return t
