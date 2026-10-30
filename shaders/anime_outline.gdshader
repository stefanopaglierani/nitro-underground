shader_type spatial;
// Ink outline for the anime style: the mesh drawn again, grown along its normals, back faces
// only and flat black, so a dark rim shows around the silhouette.
render_mode unshaded, cull_front, depth_draw_opaque, fog_disabled;

uniform float width = 0.02;
uniform vec3 ink : source_color = vec3(0.04, 0.03, 0.08);

void vertex() {
	// Grown in view space, so imported models with any scale get the same width in metres;
	// a little wider further away, so the line keeps about the same thickness on screen.
	vec4 v = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	v.xyz += n * width * clamp(-v.z / 8.0, 0.6, 3.0);
	POSITION = PROJECTION_MATRIX * v;
}

void fragment() {
	ALBEDO = ink;
}
