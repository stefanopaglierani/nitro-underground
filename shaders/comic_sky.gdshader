shader_type sky;
// Comic style sky: deep blue at the top, pale at the horizon, a soft sun and big flat clouds
// with a lit top and a blue-grey underside, like a painted background.

uniform vec3 zenith : source_color = vec3(0.12, 0.38, 0.92);
uniform vec3 horizon : source_color = vec3(0.72, 0.88, 1.0);
uniform vec3 cloud_lit : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_shade : source_color = vec3(0.68, 0.76, 0.93);
uniform float cover = 0.48;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	float h = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon, zenith, pow(h, 0.55));
	if (d.y < 0.0) {
		col = horizon * 0.95;
	}
	// Sun: a bright disc with a wide glow.
	float sd = dot(d, LIGHT0_DIRECTION);
	col += vec3(1.0, 0.95, 0.8) * (smoothstep(0.9985, 0.9992, sd) * 2.0 + pow(max(sd, 0.0), 40.0) * 0.35);
	if (d.y > 0.01 && !AT_CUBEMAP_PASS) {
		vec2 p = d.xz / (d.y + 0.12) * 1.3 + vec2(TIME * 0.004, 0.0);
		float n = fbm(p);
		float shape = smoothstep(cover, cover + 0.04, n);
		// Lighter on the side the sun is on: compare with the noise a little towards the sun.
		float n2 = fbm(p + normalize(LIGHT0_DIRECTION.xz + 0.0001) * 0.06);
		float lit = step(n2, n);
		vec3 cl = mix(cloud_shade, cloud_lit, max(lit, smoothstep(cover + 0.2, cover + 0.25, n)));
		float fade = smoothstep(0.01, 0.12, d.y);
		col = mix(col, cl, shape * fade);
	}
	COLOR = col;
}
