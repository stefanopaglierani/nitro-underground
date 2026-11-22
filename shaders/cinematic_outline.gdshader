shader_type spatial;
// Graphic-novel contour for the cinematic look (--look=cinema): the car drawn again, grown along
// its normals, back faces only, in a deep blue-violet ink (not black). Thin, about the same width
// on screen at any distance, and fading into the fog with the rest of the scene.
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform float width = 0.012;
uniform vec3 ink : source_color = vec3(0.05, 0.04, 0.12);

void vertex() {
	vec4 v = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	v.xyz += n * width * clamp(-v.z / 6.0, 0.7, 4.0);
	POSITION = PROJECTION_MATRIX * v;
}

void fragment() {
	ALBEDO = ink;
}
