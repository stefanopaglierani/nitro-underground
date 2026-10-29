shader_type spatial;
// Mountain terrain: grass on gentle ground, rock on steep slopes (cuttings, cliffs).
// Grass is mapped from above at two scales to hide tiling; rock is triplanar so cliffs do not
// stretch. Textures: see assets/LICENSES.md.

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravel_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float grass_scale = 0.06;
uniform float rock_scale = 0.05;
uniform vec3 grass_tint = vec3(0.74, 0.88, 0.58);

varying vec3 world_pos;
varying vec3 world_normal;
varying float road_near;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// COLOR.r is 1 next to the road (gravel verge) and 0 away from it.
	road_near = COLOR.r;
}

vec3 triplanar(sampler2D tex, vec3 p, vec3 n, float s) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	return texture(tex, p.zy * s).rgb * w.x + texture(tex, p.xz * s).rgb * w.y + texture(tex, p.xy * s).rgb * w.z;
}

void fragment() {
	float slope = 1.0 - world_normal.y;
	float rock_w = smoothstep(0.22, 0.42, slope);
	vec3 grass = mix(texture(grass_albedo, world_pos.xz * grass_scale).rgb,
			texture(grass_albedo, world_pos.xz * grass_scale * 0.17).rgb, 0.45) * grass_tint;
	vec3 rock = triplanar(rock_albedo, world_pos, world_normal, rock_scale);
	vec3 gravel = texture(gravel_albedo, world_pos.xz * 0.15).rgb;
	vec3 col = mix(grass, rock, rock_w);
	col = mix(col, gravel, road_near * (1.0 - rock_w));
	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.85, rock_w);
	SPECULAR = 0.3;
}
