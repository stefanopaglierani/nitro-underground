class_name BakedCar
extends Resource
## A car model prepared ahead of time by tools/bake_cars.gd: already turned, scaled, split into
## body and wheels, welded into few meshes and lightened. Loading it skips all of that work, so
## the garage preview and the race start do not have to do it on the phone.

## Body meshes: one for the solid parts, one per see-through part (glass).
@export var body: Array[ArrayMesh] = []
## Wheel pivots "WheelFL", "WheelFR", "WheelRL", "WheelRR": their position and their meshes.
@export var wheel_pos: Dictionary = {}
@export var wheel_meshes: Dictionary = {}
## The whole car (wheels included, standing still) in one light mesh, shown instead of the
## detailed one when the car is far from the camera (v0.16).
@export var far: Array[ArrayMesh] = []
## Height of the car, used to place the police sirens on the roof.
@export var height := 1.4


func to_data() -> Dictionary:
	var wheels := {}
	for corner in wheel_pos:
		var meshes: Array[ArrayMesh] = []
		meshes.assign(wheel_meshes.get(corner, []))
		wheels[corner] = [wheel_pos[corner], meshes]
	return {"body": body, "wheels": wheels, "height": height, "far": far}
