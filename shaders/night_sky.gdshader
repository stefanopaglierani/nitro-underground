shader_type sky;
// Night sky over the city: deep blue at the top, a warm purple glow of city lights at the
// horizon, stars and the moon (in the direction of the moon light).

uniform vec3 zenith : source_color = vec3(0.02, 0.035, 0.11);
uniform vec3 horizon : source_color = vec3(0.32, 0.14, 0.38);
uniform vec3 glow : source_color = vec3(0.95, 0.45, 0.35);

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void sky() {
	vec3 d = EYEDIR;
	float h = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon, zenith, pow(h, 0.45));
	col += glow * pow(1.0 - h, 10.0) * 0.35;
	if (d.y < 0.0) {
		col = horizon * 0.6;
	}
	if (!AT_CUBEMAP_PASS && d.y > 0.05) {
		vec3 cell = floor(d * 220.0);
		float star = step(0.9965, hash(cell));
		col += vec3(0.9, 0.92, 1.0) * star * smoothstep(0.05, 0.3, d.y) * (0.5 + 0.5 * hash(cell + 3.0));
	}
	float md = dot(d, LIGHT0_DIRECTION);
	col += vec3(0.9, 0.93, 1.0) * (smoothstep(0.9993, 0.9996, md) * 1.6 + pow(max(md, 0.0), 60.0) * 0.12);
	COLOR = col;
}
