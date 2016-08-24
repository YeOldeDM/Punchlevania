
extends RigidBody2D

onready var sprite = get_node('Sprite')
onready var animator = get_node('Animator')

export var FLY_SPEED = 50
export var DAMAGE = 1
export var LIFE = 1

export var face_left = false


var MAX_WALL_AIRTIME = 0.15
var airtime = 0.0

var hits = 0 setget _set_hits

var facing = 1 setget _set_facing
var anim = '' setget _set_anim

var on_wall = false

var in_pain = false
var dead = false

func _ready():
	if face_left:
		set('facing',-1)

func _set_facing(value):
	facing = clamp(value, -1, 1)
	sprite.set_scale(Vector2(facing,1))

func _set_anim(what):
	anim = what
	animator.play(what)

func _set_hits(value):
	if value >= LIFE:
		die()
	hits = value

func die():
	dead = true
	animator.play('fall')

func start_pain():
	in_pain = true

func stop_pain():
	in_pain = false

func get_punched(who, direction, damage):
	if not dead:
		set('hits', hits+damage)
		if not dead:
			animator.play('pain')
	

func _integrate_forces(state):
	# setup
	var delta = state.get_step()
	var lv = state.get_linear_velocity()
	
	var new_facing = facing
	var new_anim = anim
	
	# find walls
	if not dead:
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
		
		
		new_anim = 'fly'
		
		if new_facing != facing:
			set('facing',new_facing)
		if new_anim != anim:
			set('anim', new_anim)
		
		lv.x = facing*(FLY_SPEED)
		lv.y = 0
		state.set_linear_velocity(lv)
	else:
		state.set_linear_velocity(state.get_total_gravity())
		for x in range(state.get_contact_count()):
			var norm = state.get_contact_local_normal(x)
			if norm.dot(Vector2(0, -1)) > 0.6:
				animator.play('dead')
				set_linear_velocity(Vector2(0,0))
				set_mode(RigidBody2D.MODE_STATIC)
				PS2D.body_clear_shapes(get_rid())
	






func _on_Bat_body_enter( body ):
	if not dead:
		if body == get_node('/root/World').player:
			body.get_punched(self, (body.get_pos()-get_pos()), DAMAGE)
