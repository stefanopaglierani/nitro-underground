shader_type spatial;
render_mode cull_disabled, depth_draw_always;
// Sea for the coast circuit: blue-green, clearer and lighter where it is shallow, white foam
// along the shore, small moving waves in the normal. One big flat quad at sea level.

uniform vec3 deep : source_color = vec3(0.02, 0.2, 0.42);
uniform vec3 shallow : source_color = vec3(0.12, 0.7, 0.72);
uniform vec3 foam : source_color = vec3(0.95, 0.98, 1.0);
uniform sampler2D depth_tex : hint_depth_texture, filter_linear;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float waves(vec2 p, float t) {
	return sin(dot(p, vec2(0.21, 0.13)) + t * 1.3) * 0.5
		+ sin(dot(p, vec2(-0.17, 0.29)) + t * 1.7) * 0.35
		+ sin(dot(p, vec2(0.53, -0.41)) + t * 2.6) * 0.15
		+ sin(dot(p, vec2(-0.91, -0.77)) + t * 3.3) * 0.08;
}

void fragment() {
	float t = TIME;
	vec2 p = wpos.xz;
	float e = 0.4;
	float h = waves(p, t);
	vec3 n = normalize(vec3(waves(p + vec2(e, 0.0), t) - h, e * 2.5, waves(p + vec2(0.0, e), t) - h));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

	// Water depth under this point, from the depth buffer.
	float d = texture(depth_tex, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d * 2.0 - 1.0);
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d);
#endif
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float scene_z = -view.z / view.w;
	float depth = max(scene_z + VERTEX.z, 0.0);

	vec3 col = mix(shallow, deep, smoothstep(0.0, 9.0, depth));
	float f = 1.0 - smoothstep(0.0, 1.1 + 0.5 * sin(t * 1.4 + p.x * 0.05), depth);
	f = max(f, smoothstep(0.85, 1.0, h) * 0.35);
	col = mix(col, foam, f);
	ALBEDO = col;
	ROUGHNESS = 0.06;
	SPECULAR = 0.6;
	ALPHA = clamp(0.55 + depth * 0.12 + f, 0.0, 1.0);
}
