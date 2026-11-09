class_name Perf
## Lighter settings for the phone (v0.22, Stefano: "alleggerire veramente tanto").
## The PC keeps everything as it is. Start the game with "-- --mobile" on the PC to try the phone
## profile there (used by the measurements in docs/TECNICO.md).

## True on Android/iOS, or when the game is started with --mobile.
static var mobile: bool = OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--mobile")

## 3D picture drawn at this fraction of the screen resolution, then stretched (HUD stays sharp).
const RENDER_SCALE := 0.62
## Share of the camera's view distance kept on the phone; depth fog hides the cut.
const VIEW_SHARE := 0.5
## Shadows only this far from the camera (metres): enough for the cars and the nearby road side.
const SHADOW_DISTANCE := 45.0
## Share of the roadside models, trees and grass kept on the phone, and of their visibility range.
const DENSITY := 0.5
const VISIBILITY := 0.6
## City traffic cars on the phone (24 on PC): each one is a physics body with four wheel probes.
const TRAFFIC := 12
## Set by apply(): the race is at night (the player's headlight is only lit then on the phone).
static var night_level := false


## Multiplier for "how many copies" of decoration: 1 on PC.
static func density() -> float:
	return DENSITY if mobile else 1.0


## Multiplier for visibility ranges of decoration: 1 on PC.
static func visibility() -> float:
	return VISIBILITY if mobile else 1.0


## Called once the level, its sky and its sun exist. Does nothing on PC.
static func apply(parent: Node, camera: Camera3D, level: Node = null) -> void:
	night_level = level != null and level.get("night") == true
	if not mobile:
		return
	var vp := parent.get_viewport()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = RENDER_SCALE
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	camera.far = maxf(camera.far * VIEW_SHARE, 300.0)
	if level:
		_shorten(level)
	for c in parent.get_children():
		if c is WorldEnvironment and c.environment:
			var env: Environment = c.environment
			# Glow is a blur of the whole screen in several passes: the costliest effect on the phone.
			env.glow_enabled = false
			env.ssao_enabled = false
			env.ssr_enabled = false
			env.sdfgi_enabled = false
			env.volumetric_fog_enabled = false
			# Fog by distance: clear up close, full at the end of the (shorter) view.
			if env.fog_enabled:
				env.fog_mode = Environment.FOG_MODE_DEPTH
				env.fog_depth_begin = camera.far * 0.35
				env.fog_depth_end = camera.far * 0.95
				env.fog_depth_curve = 1.0
				env.fog_density = 1.0
		elif c is DirectionalLight3D and c.shadow_enabled:
			var sun: DirectionalLight3D = c
			# One shadow map instead of two or four: the scene is drawn once less per frame.
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			sun.directional_shadow_max_distance = minf(sun.directional_shadow_max_distance, SHADOW_DISTANCE)


## Decoration that fades out at a set distance (trees, rocks, houses, poles) fades out sooner.
static func _shorten(n: Node) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D and c.visibility_range_end > 0.0 and c.visibility_range_begin == 0.0:
			c.visibility_range_end *= VISIBILITY
		_shorten(c)
