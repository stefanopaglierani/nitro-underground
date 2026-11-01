shader_type spatial;
// Full-screen pass for the 2.5D comic look, on a quad in front of the camera: colours flattened
// into cel bands, ink lines where the depth jumps, halftone dots in the shadows, hatching in the
// darkest parts and misprinted colour plates (red and blue shifted) that grow with distance,
// instead of blur (Spider-Verse-like).
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 ink : source_color = vec3(0.05, 0.04, 0.1);
uniform vec3 dot_ink : source_color = vec3(0.12, 0.05, 0.32);
uniform float line_px = 1.6;
uniform float line_strength = 0.85;
uniform float fade_far = 320.0;
uniform float bands = 4.0;
uniform float flatten = 0.55;
uniform float dot_px = 7.0;
uniform float misprint_px = 3.0;

void vertex() {
	// Mid-depth in both clip conventions; depth testing is off anyway.
	POSITION = vec4(VERTEX.xy, 0.5, 1.0);
}

float lin(vec2 uv, mat4 inv_proj) {
	float z = texture(depth_tex, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec4 v = inv_proj * vec4(vec3(uv, z) * 2.0 - 1.0, 1.0);
#else
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, z, 1.0);
#endif
	return -v.z / v.w;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	// Pixel sizes are given for a 720 px tall screen and scaled to the real one.
	float k = VIEWPORT_SIZE.y / 720.0;
	vec2 px = 1.0 / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	float c = lin(uv, INV_PROJECTION_MATRIX);

	vec3 col = texture(screen_tex, uv).rgb;
	// Misprint: the red and blue plates slip apart, more in the distance and at the edges.
	float slip = misprint_px * k * (smoothstep(25.0, 160.0, c) + length(uv - 0.5) * 0.8);
	col.r = texture(screen_tex, uv + vec2(slip, 0.0) * px).r;
	col.b = texture(screen_tex, uv - vec2(slip, slip * 0.5) * px).b;

	// Cel bands: the brightness snaps to a few levels, the hue stays.
	float l = luma(col);
	float lq = (floor(l * bands) + smoothstep(0.35, 0.65, fract(l * bands))) / bands;
	col = mix(col, col * (lq / max(l, 0.001)), flatten);
	col = clamp(col, 0.0, 1.0);

	l = luma(col);
	// Halftone: a grid of dots turned 45 degrees, bigger where the picture is darker.
	vec2 p = FRAGCOORD.xy / (dot_px * k);
	p = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * p;
	float d = length(fract(p) - 0.5);
	// Only in real shadows and never on the sky, or the whole picture turns grey.
	float shade = (1.0 - smoothstep(0.2, 0.62, l)) * (1.0 - step(fade_far * 3.0, c));
	float r = sqrt(shade) * 0.55;
	float dots = 1.0 - smoothstep(r - 0.06, r + 0.06, d);
	col = mix(col, dot_ink, dots * 0.45 * step(0.02, shade));
	// Highlights: small light dots in the brightest areas, like a printed comic.
	float hi = smoothstep(0.75, 0.95, l);
	float hdots = 1.0 - smoothstep(0.12, 0.2, length(fract(p + 0.5) - 0.5));
	col = mix(col, vec3(1.0, 0.97, 0.9), hdots * hi * 0.25);
	// Hatching: diagonal ink strokes in the darkest parts.
	float hatch = step(0.75, fract((FRAGCOORD.x + FRAGCOORD.y) / (5.0 * k)));
	col = mix(col, ink, hatch * smoothstep(0.22, 0.08, l) * 0.8);

	// Ink lines on the near side of every depth jump (silhouettes).
	vec2 e = line_px * k * px;
	float n = lin(uv + vec2(0.0, e.y), INV_PROJECTION_MATRIX);
	float s = lin(uv - vec2(0.0, e.y), INV_PROJECTION_MATRIX);
	float w = lin(uv - vec2(e.x, 0.0), INV_PROJECTION_MATRIX);
	float east = lin(uv + vec2(e.x, 0.0), INV_PROJECTION_MATRIX);
	float jump = max(max(n, s), max(w, east)) - c;
	float line = smoothstep(0.04, 0.12, jump / max(c, 0.5));
	line *= 1.0 - smoothstep(fade_far * 0.5, fade_far, c);
	col = mix(col, ink, line * line_strength);

	ALBEDO = col;
}
