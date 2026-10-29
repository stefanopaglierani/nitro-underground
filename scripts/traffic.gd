class_name TrafficCar
extends AnimatableBody3D
## Civilian car that drives straight along one road lane and wraps around at the city edge.

const BODIES := ["car_sedan", "car_hatchback", "car_stationwagon", "car_taxi"]

var along_x := true
var line := 0.0
var dir := 1.0
var speed := 11.0
var t := 0.0
var _min := 0.0
var _max := 0.0


func setup(city: City, rng: RandomNumberGenerator) -> void:
	add_to_group("traffic")
	sync_to_physics = false
	along_x = rng.randf() < 0.5
	dir = 1.0 if rng.randf() < 0.5 else -1.0
	line = rng.randi_range(0, City.BLOCKS) * City.SPACING + 3.5 * dir * (1.0 if along_x else -1.0)
	speed = rng.randf_range(8.0, 13.0)
	_min = -City.ROAD / 2.0 + 2.5
	_max = city.extent + City.ROAD / 2.0 - 2.5
	t = rng.randf_range(_min, _max)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.5, 4.2)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 0.85
	add_child(col)
	add_child(CarModel.build(Color(0, 0, 0, 0), false, BODIES[rng.randi() % BODIES.size()]))
	_apply()


func _apply() -> void:
	var pos := Vector3(t, 0, line) if along_x else Vector3(line, 0, t)
	var facing := Vector3(dir, 0, 0) if along_x else Vector3(0, 0, dir)
	global_transform = Transform3D(Basis.looking_at(facing, Vector3.UP), pos)


func _physics_process(delta: float) -> void:
	t += dir * speed * delta
	if t > _max:
		t = _min
	elif t < _min:
		t = _max
	_apply()
