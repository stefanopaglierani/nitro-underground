class_name TrafficCar
extends AnimatableBody3D
## Civilian car that drives along one lane of the track at a steady speed. On an open lane it
## wraps around to the start when it reaches the end.

const BODIES := ["sedan", "hatchback", "suv", "van", "taxi", "pickup"]

var curve: Curve3D
var offset := 3.5
var dir := 1.0
var loop := false
var speed := 11.0
var t := 0.0
var _length := 0.0


func setup(track: Track, rng: RandomNumberGenerator) -> void:
	add_to_group("traffic")
	sync_to_physics = false
	var lane := track.traffic_lane(rng)
	curve = lane["curve"]
	offset = lane["offset"]
	dir = lane["dir"]
	loop = lane["loop"]
	_length = curve.get_baked_length()
	speed = rng.randf_range(8.0, 13.0)
	t = rng.randf_range(0.0, _length)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.5, 4.2)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.85
	add_child(col)
	add_child(CarModel.build(Color(0, 0, 0, 0), false, BODIES[rng.randi() % BODIES.size()]))
	_apply()


func _apply() -> void:
	var pos := curve.sample_baked(t)
	var ahead := curve.sample_baked(clampf(t + dir * 2.0, 0.0, _length)) if not loop else curve.sample_baked(fposmod(t + dir * 2.0, _length))
	var facing := ahead - pos
	var flat := Vector3(facing.x, 0, facing.z)
	if flat.length() < 0.01:
		return
	var right := flat.normalized().cross(Vector3.UP)
	# Pitch with the road so the car sits on slopes.
	global_transform = Transform3D(Basis.looking_at(facing.normalized(), Vector3.UP), pos + right * offset)


func _physics_process(delta: float) -> void:
	t += dir * speed * delta
	if loop:
		t = fposmod(t, _length)
	elif t > _length:
		t = 0.0
	elif t < 0.0:
		t = _length
	_apply()
