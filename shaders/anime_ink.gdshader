shader_type spatial;
// Anime style, full-screen pass: draws ink lines where the depth jumps (silhouettes) and
// leaves the rest of the picture alone (alpha 0). Lines fade out in the distance.
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 ink : source_color = vec3(0.05, 0.04, 0.1);
uniform float px = 1.2;
uniform float strength = 0.6;
uniform float fade_far = 260.0;

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

void fragment() {
	vec2 e = px / VIEWPORT_SIZE;
	float c = lin(SCREEN_UV, INV_PROJECTION_MATRIX);
	float n = lin(SCREEN_UV + vec2(0.0, e.y), INV_PROJECTION_MATRIX);
	float s = lin(SCREEN_UV - vec2(0.0, e.y), INV_PROJECTION_MATRIX);
	float w = lin(SCREEN_UV - vec2(e.x, 0.0), INV_PROJECTION_MATRIX);
	float east = lin(SCREEN_UV + vec2(e.x, 0.0), INV_PROJECTION_MATRIX);
	// Only the near side of a jump gets the line, so lines sit on the object's edge.
	float jump = max(max(n, s), max(w, east)) - c;
	float rel = jump / max(c, 0.5);
	float line = smoothstep(0.06, 0.16, rel);
	line *= 1.0 - smoothstep(fade_far * 0.5, fade_far, c);
	ALBEDO = ink;
	ALPHA = line * strength;
}
