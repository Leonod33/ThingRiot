extends CanvasLayer
# Lightweight screen-space vignette. Drawn beneath HUD and every warning overlay.
func _ready():
	layer = 0
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var effect := ShaderMaterial.new()
	effect.shader = preload("res://polish/atmosphere.gdshader")
	veil.material = effect
	add_child(veil)
