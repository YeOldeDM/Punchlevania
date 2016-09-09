
extends RigidBody2D

# Children
onready var sprite = get_node('Sprite')
onready var animator = get_node('Animator')

# Params
var MAX_FLOOR_AIRTIME = 0.15
var MAX_WALL_AIRTIME = 0.15
var airtime = 0.0

export var STOP_JUMP_FORCE = 190

export var MAX_RUN_VELOCITY = 20
export var RUN_ACCEL = 50
export var AIR_ACCEL = 110

export var JUMP_VELOCITY = 140
export var PUNCH_HOP = 50
export var PUNCH_DAMAGE = 1

export(int, "Right", "Left") var initial_facing = 0

# Self-setters
var facing = 1 setget _set_facing
var anim = 'idle' setget _set_anim

# Flags
var is_stalking = false
var stalking_target
var in_pain = false
var is_dead = false
var on_wall = false

# Stats
var hits = 0 setget _set_hits
var life = 3




# PUBLIC FUNCTIONS #

func get_punched(origin, vector, damage):
	if not in_pain and not is_dead:
		set('hits', hits+damage)
		if not is_dead:
			in_pain = true
			set('anim', 'pain')
	

func kill():
	set('anim', 'die')
	is_dead = true



# PRIVATE FUNCTIONS #

func _die():
	set_mode(RigidBody2D.MODE_STATIC)
	PS2D.body_clear_shapes(get_rid())

func _end_pain():
	in_pain = false

func _set_hits(value):
	hits = value
	if hits >= life:
		kill()

func _set_facing(value):
	facing = value
	sprite.set_scale(Vector2(value,1))

func _set_anim(animation):
	anim = animation
	animator.play(animation)

func _ready():
	if initial_facing == 1:
		set('facing', -1)

func _integrate_forces(state):
	var delta = state.get_step()
	var lv = state.get_linear_velocity()
	var new_facing = facing
	var new_anim = anim
	
	var found_wall = false
	for x in range(state.get_contact_count()):
		var norm = state.get_contact_local_normal(x)
		var N = norm.dot(Vector2(-1,0))
		if N*facing == 1:
			found_wall = true
		if -N < 0:	new_facing = -1
		elif -N > 0:	new_facing = 1
		
		if found_wall:	airtime = 0.0
		else:	airtime += delta
		on_wall = airtime < MAX_WALL_AIRTIME
	
	if not is_dead:
		if abs(lv.x) < MAX_RUN_VELOCITY:
			lv.x += RUN_ACCEL*facing*delta
	else:
		lv.x = 0
	
	if abs(lv.x) > 0 and not in_pain:
		new_anim = 'run'
	
	if new_facing != facing:
		set('facing',new_facing)
	if new_anim != anim:
		set('anim', new_anim)
	
	if not is_dead:
		var g = state.get_total_gravity()
		lv += g
	state.set_linear_velocity(lv)



