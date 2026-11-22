shader_type sky;
// Painted sky of the cinematic look (--look=cinema): its colours are set 4 times a second by the
// day and night cycle (scripts/day_night.gd). Glow around the sun, soft layered clouds lit from
// the sun's side, stars and the moon at night. Realistic shapes, illustrated colours: no flat bands.

uniform vec3 zenith : source_color = vec3(0.08, 0.14, 0.42);
uniform vec3 mid : source_color = vec3(0.34, 0.42, 0.78);
uniform vec3 horizon : source_color = vec3(1.0, 0.58, 0.32);
uniform vec3 ground : source_color = vec3(0.16, 0.12, 0.2);
uniform vec3 sun_glow : source_color = vec3(1.0, 0.62, 0.3);
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.66, 0.42);
uniform vec3 cloud_shade : source_color = vec3(0.36, 0.3, 0.52);
uniform float cloud_cover = 0.5;
uniform float energy = 1.0;
uniform vec3 sun_dir = vec3(0.0, 0.24, -0.97);
uniform float night = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += noise(p) * a;
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	// Gradient: horizon band -> mid blue -> zenith.
	vec3 col = mix(horizon, mid, smoothstep(0.0, 0.22, h));
	col = mix(col, zenith, smoothstep(0.2, 0.75, h));
	col = mix(col, ground, smoothstep(0.0, -0.12, h));

	float s = max(dot(d, sun_dir), 0.0);
	// Wide warm glow on the sun's side of the sky, tight halo and the disc.
	col += sun_glow * (pow(s, 6.0) * 0.45 + pow(s, 48.0) * 0.6) * (1.0 - smoothstep(0.1, 0.6, h) * 0.5);
	col += vec3(1.0, 0.9, 0.7) * smoothstep(0.9993, 0.9997, s) * 6.0;

	// Clouds: soft layer projected on a dome, only above the horizon.
	if (h > 0.0 && !AT_CUBEMAP_PASS) {
		vec2 uv = d.xz / (h + 0.12) * 1.6;
		float c = fbm(uv);
		c = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.32, c);
		float lit = pow(s, 3.0) * 0.7 + 0.3 * smoothstep(0.35, 0.0, h);
		vec3 cc = mix(cloud_shade, cloud_lit, clamp(lit + fbm(uv * 2.3) * 0.25, 0.0, 1.0));
		col = mix(col, cc, c * smoothstep(0.0, 0.08, h) * 0.85);
	}
	if (night > 0.0 && h > 0.0) {
		// Stars: tiny points on a fine grid of the sky dome, fading near the horizon.
		vec3 g = d * 220.0;
		vec3 cell = floor(g);
		float r = fract(sin(dot(cell, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
		float star = step(0.985, r) * smoothstep(0.42, 0.0, length(fract(g) - 0.5)) * (0.4 + r * 0.6);
		col += vec3(0.85, 0.9, 1.0) * star * night * smoothstep(0.02, 0.25, h) * 1.6;
		// The moon, opposite the sun, with a cold halo.
		float m = max(dot(d, -sun_dir), 0.0);
		col += vec3(0.5, 0.6, 0.9) * pow(m, 60.0) * 0.25 * night;
		col += vec3(0.92, 0.94, 1.0) * smoothstep(0.99955, 0.9998, m) * 2.5 * night;
	}
	COLOR = col * energy;
}
