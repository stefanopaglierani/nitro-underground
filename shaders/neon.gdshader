shader_type spatial;
render_mode unshaded, cull_disabled;
// Glowing sign or lamp: the colour (per instance in a MultiMesh) times `energy`, so it blooms.

uniform float energy = 3.0;

void fragment() {
	ALBEDO = COLOR.rgb * energy;
}
