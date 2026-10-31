shader_type spatial;
render_mode cull_disabled;
// Building facade at night: the model's own photo texture, darkened like a wall in the evening,
// with its windows lit. Windows are the glassy pixels (darker and bluer than the wall); each
// storey-sized cell of the facade is randomly on or off, warm or cool, so the floors look lived in.
// A soft upward wash at the base looks like the light of the shop windows and street lamps.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float wall_dim = 0.5;
uniform float window_glow = 2.4;
uniform float lit_share = 0.55;
uniform float street_glow = 0.22;

varying vec3 wpos;
varying vec3 wnorm;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec4 t = texture(albedo_tex, UV) * tint;
	float lum = dot(t.rgb, vec3(0.299, 0.587, 0.114));
	float wall = 1.0 - abs(wnorm.y);  // vertical surfaces only, not roofs
	float glass = smoothstep(-0.02, 0.08, t.b - t.r) * (1.0 - smoothstep(0.22, 0.5, lum));
	glass = max(glass, (1.0 - smoothstep(0.06, 0.2, lum)) * 0.7);
	vec2 cell = floor(vec2(wpos.x * 0.7 + wpos.z * 0.7, wpos.y) / vec2(2.6, 3.3));
	float on = step(1.0 - lit_share, hash(cell));
	vec3 warm = mix(vec3(1.0, 0.72, 0.38), vec3(0.62, 0.86, 1.0), step(0.72, hash(cell + 7.31)));
	ALBEDO = t.rgb * wall_dim;
	float low = 1.0 - smoothstep(1.0, 9.0, wpos.y);
	EMISSION = warm * glass * on * window_glow * wall + t.rgb * low * street_glow * wall;
	ROUGHNESS = 0.8;
}
