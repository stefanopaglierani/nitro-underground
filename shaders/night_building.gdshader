shader_type spatial;
// Night city tower: coloured walls with a grid of lit windows, computed from world position.
// Vertex COLOR.rgb is the wall colour of the building, COLOR.a a per-building seed.
// The roof (faces looking up) has no windows.

uniform float lit_ratio = 0.55;
uniform float window_energy = 1.7;

varying vec3 wpos;
varying vec3 wnorm;
varying vec4 tint;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	tint = COLOR;
}

void fragment() {
	vec3 col = tint.rgb;
	vec3 emit = vec3(0.0);
	if (abs(wnorm.y) < 0.5) {
		// Window grid along the wall: the horizontal coordinate runs along the face.
		vec3 along = normalize(cross(vec3(0.0, 1.0, 0.0), wnorm));
		vec2 uv = vec2(dot(wpos, along), wpos.y);
		vec2 cell_size = vec2(2.8, 3.3);
		vec2 cell = floor(uv / cell_size);
		vec2 f = fract(uv / cell_size);
		float win = step(0.16, f.x) * step(f.x, 0.84) * step(0.2, f.y) * step(f.y, 0.75);
		win *= step(3.0, wpos.y);
		float s = tint.a * 97.0;
		float lit = step(1.0 - lit_ratio, hash(cell + vec2(s, s * 1.7)));
		float h = hash(cell * 1.3 + s);
		vec3 wc = h < 0.6 ? vec3(1.0, 0.8, 0.5) : (h < 0.85 ? vec3(0.75, 0.88, 1.0) : vec3(1.0, 0.55, 0.85));
		col = mix(col, vec3(0.04, 0.05, 0.08), win);
		emit = wc * win * lit * window_energy;
		// Far away the grid is smaller than a pixel and would flicker: fade to its average glow.
		vec2 fw = fwidth(uv / cell_size);
		float blur = smoothstep(0.25, 0.7, max(fw.x, fw.y));
		vec3 avg = vec3(1.0, 0.8, 0.6) * 0.37 * lit_ratio * window_energy * step(3.0, wpos.y);
		emit = mix(emit, avg, blur);
		col = mix(col, tint.rgb * 0.7, blur);
		// Ground floor shops: a lit band all along the street.
		float shop = step(0.6, wpos.y) * step(wpos.y, 2.7) * step(0.35, hash(vec2(floor(uv.x / 6.0), s)));
		emit += vec3(1.0, 0.85, 0.6) * shop * 0.9;
		col = mix(col, vec3(0.9, 0.85, 0.75), shop * 0.5);
	} else {
		col *= 0.6;
	}
	ALBEDO = col;
	ROUGHNESS = 0.8;
	EMISSION = emit;
}
