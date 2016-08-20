
extends RigidBody2D

var MAX_FLOOR_AIRTIME = 0.15

var STOP_JUMP_FORCE = 190

var MAX_RUN_VELOCITY = 100
var RUN_ACCEL = 400
var AIR_ACCEL = 110

var JUMP_VELOCITY = 140
var PUNCH_HOP = 50
var PUNCH_DAMAGE = 1

onready var sprite = get_node('Sprite')
onready var animator = get_node('Animator')
onready var puncher = get_node('Puncher')

var on_floor = false
var on_ladder = false

var punching = false
var striking = false
var jumping = false
var stopping_jump = false

var air_time = 0.0
var floor_h_vel = 0.0

var anim = 'idle' setget _set_anim

var facing = 1 setget _set_facing

var max_health = 4
var health = max_health
var dead = false

var is_hit = false


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


# Called by the 'punch' animation on Animator child..
func start_punch():
	punching = true
	var lv = get_linear_velocity()
	lv *= 0.1
	set_linear_velocity(lv)

func punch():
	var V = Vector2(PUNCH_HOP*facing, -PUNCH_HOP)
	set_linear_velocity(V)
	striking = true
	
func end_punch():
	punching = false
	striking = false



# Called when we get punched
func get_punched(punched_by, vector, damage):
	if is_hit or dead:
		return
	print(get_name()+" got punched by "+punched_by.get_name()+" for "+str(damage)+" hits!")
	
	var V = vector.normalized()*(damage*100)
	V.y -= damage*50
	set_linear_velocity(V)
	var x = sign(punched_by.get_pos().x - get_pos().x)
	set('facing', x)
	
	is_hit = true
	get_node('HitTimer').start()
	var new_health = health - damage
	if new_health <= 0:
		die()
	health = max(0,new_health)

func die():
	set_linear_velocity(Vector2(0,0))
	animator.play('die')
	dead = true
	PS2D.body_clear_shapes(get_rid())
	set_z(-1)

func _set_facing( value ):
	facing = value
	sprite.set_scale(Vector2(facing,1))
	puncher.set_cast_to(Vector2(8*facing,0))

func _set_anim( state ):
	anim = state
	animator.play(anim)

# State mainloop
func _integrate_forces(state):
	if dead:
		return
	# Setup
	var delta = state.get_step()
	var lv = get_linear_velocity()
	
	var new_anim = anim
	var new_facing = facing
	
#	# Get Input
	var LEFT = false#Input.is_action_pressed('run_left')
	var RIGHT = false#Input.is_action_pressed('run_right')
	var UP = false#Input.is_action_pressed('climb_up')
	var DOWN = false#Input.is_action_pressed('climb_down')
	var JUMP = false#Input.is_action_pressed('jump')
	var PUNCH = false#Input.is_action_pressed('punch')
	
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
	if found_floor:	air_time = 0.0
	else:	air_time += delta
	on_floor = air_time < MAX_FLOOR_AIRTIME
	
	# Calculate Jump mechanics
	if jumping:
		if lv.y > 0:
			jumping = false
		elif not JUMP:
			stopping_jump = true
		if stopping_jump:
			lv.y += STOP_JUMP_FORCE*delta
		# Apply Punch input
		if not punching and PUNCH:
			new_anim = 'punch'
	
	# On-Floor mechanics
	if on_floor and not punching:
		# Apply left input
		if LEFT and not RIGHT:
			if lv.x > -MAX_RUN_VELOCITY:
				lv.x -= RUN_ACCEL*delta
		# or Apply right input
		elif RIGHT and not LEFT:
			if lv.x < MAX_RUN_VELOCITY:
				lv.x += RUN_ACCEL*delta
		# or Decellerate
		else:
			var xv = abs(lv.x)
			xv -= RUN_ACCEL*delta
			if xv < 0:
				xv = 0
			lv.x = sign(lv.x)*xv
	
		# Apply Jump input
		if not jumping and JUMP:
			lv.y -= JUMP_VELOCITY
			jumping = true
			stopping_jump = false
			
		if lv.x < 0 and LEFT:
			new_facing = -1
		elif lv.x > 0 and RIGHT:
			new_facing = 1
		
		# Decide on a new animation..
		if jumping:
			new_anim = 'jump'
		elif abs(lv.x) < 0.1:
			new_anim = 'idle'
		else:
			new_anim = 'run'
		
		# Hop on ladder if on floor and pressing UP
		if on_ladder:
			if UP and not DOWN:
				lv.y -= 1
		
		# Apply Punch input
		if PUNCH:
			new_anim = 'punch'
	
	# on ladder and not on floor
	elif on_ladder and not punching:
		new_anim = 'climb'
		if jumping:	jumping = false
		if UP and not DOWN:
			if lv.y > -MAX_RUN_VELOCITY:
				lv.y -= AIR_ACCEL*delta
		elif DOWN and not UP:
			if lv.y < MAX_RUN_VELOCITY:
				lv.y += AIR_ACCEL*delta
		else:
			var yv = abs(lv.y)
			yv -= AIR_ACCEL*delta*10
			if yv < 0:	yv = 0
			lv.y = sign(lv.y)*yv
			
		if LEFT and not RIGHT:
			if lv.x > -MAX_RUN_VELOCITY:
				lv.x -= AIR_ACCEL*delta
		elif RIGHT and not LEFT:
			if lv.x < MAX_RUN_VELOCITY:
				lv.x += AIR_ACCEL*delta
		else:
			var xv = abs(lv.x)
			xv -= AIR_ACCEL*delta*10
			if xv < 0:	xv = 0
			lv.x = sign(lv.x)*xv

		
	# Mid-air mechanics
	else:
		if not punching:
			if LEFT and not RIGHT:
				if lv.x > -MAX_RUN_VELOCITY:
					lv.x -= AIR_ACCEL*delta
			elif RIGHT and not LEFT:
				if lv.x < MAX_RUN_VELOCITY:
					lv.x += AIR_ACCEL*delta
			else:
				var xv = abs(lv.x)
				xv -= AIR_ACCEL*delta
				if xv < 0:	xv = 0
				if not is_hit:
					lv.x = sign(lv.x)*xv
			new_anim = 'jump'
		# Apply Punch input
		if PUNCH:
			new_anim = 'punch'
	# Update facing
	if facing != new_facing:
		facing = new_facing
		sprite.set_scale(Vector2(facing,1))
		get_node('Puncher').set_cast_to(Vector2(8*facing,0))
	# Update animator
	if anim != new_anim:
		set('anim', new_anim)
	
	# Apply floor velocity
	if found_floor:
		floor_h_vel = state.get_contact_collider_velocity_at_pos(floor_index).x
	
	# Apply gravity and velocity
	if not on_ladder or dead:
		var g = state.get_total_gravity()
		if punching:	g*=0.75
		lv += g*delta
	state.set_linear_velocity(lv)
	
	# Process Punchees
	if striking:
		if puncher.is_colliding():
			var punchee = puncher.get_collider()
			# Only bodies that can be punched, will be punched
			if punchee.has_method('get_punched'):
				punchee.get_punched(self,puncher.get_cast_to(), PUNCH_DAMAGE)
			# Rebound from punching the wall
			elif punchee extends TileMap:
				var V = -puncher.get_cast_to().normalized()
				set_linear_velocity(V*50)


# The Detector detects any Area-based objects that come in contact
# with the player. This includes ladders, warp doors, and powerups.
func _on_Detector_area_enter( area ):
	# Process ladders
	if area.get_name().begins_with('Ladders'):
		if not on_ladder:	on_ladder = true


func _on_Detector_area_exit( area ):
	# Process ladders
	if area.get_name().begins_with('Ladders'):
		if on_ladder:	on_ladder = false
		# Ensure flip reset after climbing animation is changed
		sprite.set_flip_h(false)



func _on_HitTimer_timeout():
	is_hit = false
