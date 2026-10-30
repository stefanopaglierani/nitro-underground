shader_type canvas_item;
// Anime style speed lines: thin white streaks pointing at the screen centre, only near the
// edges, flickering. amount 0 = none, 1 = full (top speed or nitro).

uniform float amount = 0.0;

float hash(float x) {
	return fract(sin(x * 91.3458) * 47453.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float r = length(p);
	float a = atan(p.y, p.x);
	float slots = 180.0;
	float id = floor((a / 6.28318 + 0.5) * slots);
	float t = floor(TIME * 18.0);
	float on = step(0.72, hash(id + t * 13.1));
	float within = fract((a / 6.28318 + 0.5) * slots);
	float thin = smoothstep(0.5, 0.0, abs(within - 0.5) * 2.2);
	float start = 0.36 + hash(id * 3.7 + t) * 0.18 - amount * 0.1;
	float edge = smoothstep(start, start + 0.14, r);
	COLOR = vec4(1.0, 1.0, 1.0, on * thin * edge * amount * 0.55);
}
