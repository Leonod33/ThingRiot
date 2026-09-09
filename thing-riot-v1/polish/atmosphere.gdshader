shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float edge = smoothstep(0.30, 1.50, dot(p,p));
	COLOR = vec4(0.035,0.065,0.12,edge*0.23);
}
