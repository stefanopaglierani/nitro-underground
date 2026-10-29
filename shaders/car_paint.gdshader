shader_type spatial;
// KayKit atlas material with a repaintable body: texels inside paint_rect (the body's colour
// swatch in the atlas) take the paint colour, keeping the swatch's light-to-dark gradient.

uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform vec4 paint_rect = vec4(0.0); // u0, v0, u1, v1; all zero = no repaint
uniform vec3 paint : source_color = vec3(1.0);
uniform float swatch_luma = 0.5;

void fragment() {
	vec3 c = texture(atlas, UV).rgb;
	bool body = UV.x >= paint_rect.x && UV.x <= paint_rect.z && UV.y >= paint_rect.y && UV.y <= paint_rect.w;
	if (body) {
		float l = dot(c, vec3(0.299, 0.587, 0.114)) / max(swatch_luma, 0.01);
		ALBEDO = clamp(paint * l, 0.0, 1.0);
		METALLIC = 0.3;
		ROUGHNESS = 0.3;
	} else {
		ALBEDO = c;
		METALLIC = 0.0;
		ROUGHNESS = 0.45;
	}
}
