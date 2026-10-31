shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
// Pool of light thrown on the road by a street lamp: a soft disc added on top of the asphalt.
// Instance colour = lamp colour.

uniform float strength = 0.75;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = pow(clamp(1.0 - r, 0.0, 1.0), 1.6);
	ALBEDO = COLOR.rgb * a * strength;
}
