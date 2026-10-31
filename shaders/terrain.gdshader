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
uniform vec3 rock_tint = vec3(1.0);
// Coast: sand below sand_top (beaches), wet and darker under the sea. Off by default.
uniform sampler2D sand_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float sand_top = -1000.0;
uniform float sea_level = -1000.0;
uniform vec3 sand_tint = vec3(1.0, 0.95, 0.85);
// High mountains: snow above snow_line (ragged edge), less on steep rock. Off by default.
uniform float snow_line = 100000.0;

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
	vec3 rock = triplanar(rock_albedo, world_pos, world_normal, rock_scale) * rock_tint;
	vec3 gravel = texture(gravel_albedo, world_pos.xz * 0.15).rgb;
	vec3 col = mix(grass, rock, rock_w);
	col = mix(col, gravel, road_near * (1.0 - rock_w));
	float sand_w = (1.0 - smoothstep(sand_top - 1.5, sand_top + 1.5, world_pos.y)) * (1.0 - smoothstep(0.3, 0.5, slope)) * (1.0 - road_near);
	if (sand_w > 0.0) {
		vec3 sand = texture(sand_albedo, world_pos.xz * 0.04).rgb * sand_tint;
		col = mix(col, sand, sand_w);
	}
	// Under the sea: wet, then fading into blue-green with depth.
	float depth = sea_level - world_pos.y;
	col *= mix(1.0, 0.7, smoothstep(-0.6, 0.2, depth));
	col = mix(col, vec3(0.05, 0.32, 0.36), smoothstep(0.0, 8.0, depth) * 0.85);
	float ragged = texture(rock_albedo, world_pos.xz * 0.013).r * 22.0;
	float snow_w = smoothstep(snow_line - 6.0, snow_line + 6.0, world_pos.y + ragged) * (1.0 - smoothstep(0.3, 0.55, slope) * 0.85);
	col = mix(col, vec3(0.8, 0.85, 0.95), snow_w);
	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.85, rock_w);
	SPECULAR = 0.3;
}
