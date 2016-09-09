
extends RigidBody2D

var hits = 0 setget _set_hits
export var Life = 4
var is_dead = false

var on_floor = false

var linear_velocity = Vector2(0,0)

var MAX_RUN_VELOCITY = 20
var RUN_ACCEL = 5

var max_floor_airtime = 0.15
var airtime = 0
var floor_h_vel = 0


export var Damage = 3

var facing = 1
var anim = 'run'


func get_punched(origin, vector, damage):
	print("WEOE")

func kill():
	is_dead = true

func _die():
	pass

func _set_hits(value):
	hits = value
	if hits >= Life:
		kill()

func _integrate_forces(state):
	# Setup
	var delta = state.get_step()
	var lv = state.get_transform().get_origin()
	var new_anim = anim
	var new_facing = facing

	# Deapply floor velocity
	lv.x -= floor_h_vel
	floor_h_vel = 0.0
	
	# Detect Floor
	var found_floor = false
	var floor_index = -1
	
	for x in range(state.get_contact_count()):
		var norm = state.get_contact_local_normal(x)
		if norm.dot(Vector2(0, -1)) > 0.6:
			found_floor = true
			floor_index = x

	# Calculate Airtime
	if found_floor:	airtime = 0.0
	else:	airtime += delta
	on_floor = airtime < max_floor_airtime

	if not is_dead:
		if lv.x < MAX_RUN_VELOCITY:
			lv.x += RUN_ACCEL*delta*facing
		else:
			if abs(lv.x) > 0:
				lv.x -= sign(lv.x)*RUN_ACCEL*delta
	
	var new_transform = state.get_transform()
	new_transform = new_transform.translated(lv)
	state.set_transform(new_transform)
