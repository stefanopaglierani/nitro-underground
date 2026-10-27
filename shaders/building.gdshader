shader_type spatial;

// Night-time facade: dark walls with a grid of randomly lit windows, computed from world position.
uniform vec3 base_color : source_color = vec3(0.07, 0.07, 0.09);
uniform vec3 window_color : source_color = vec3(1.0, 0.78, 0.45);
uniform float lit_ratio = 0.35;
uniform float seed = 0.0;

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
	vec3 col = base_color;
	vec3 emit = vec3(0.0);
	if (abs(wnorm.y) < 0.5) {
		vec2 uv = abs(wnorm.x) > 0.5 ? vec2(wpos.z, wpos.y) : vec2(wpos.x, wpos.y);
		vec2 cell_size = vec2(2.6, 3.2);
		vec2 cell = floor(uv / cell_size);
		vec2 f = fract(uv / cell_size);
		float win = step(0.18, f.x) * step(f.x, 0.82) * step(0.22, f.y) * step(f.y, 0.72);
		win *= step(2.5, wpos.y);
		float lit = step(1.0 - lit_ratio, hash(cell + vec2(seed, seed * 1.7)));
		vec3 tint = mix(window_color, vec3(0.6, 0.8, 1.0), step(0.8, hash(cell * 1.3 + seed)));
		col = mix(col, vec3(0.03, 0.04, 0.06), win);
		emit = tint * win * lit * 1.4;
	} else {
		col = base_color * 0.8;
	}
	ALBEDO = col;
	ROUGHNESS = 0.85;
	EMISSION = emit;
}
