
extends RigidBody2D

var powerball = preload('res://resources/bullets/PowerBall.tscn')

var MAX_FLOOR_AIRTIME = 0.15

export var STOP_JUMP_FORCE = 190

export var MAX_RUN_VELOCITY = 100
export var max_climb_velocity = 50
export var RUN_ACCEL = 400
export var AIR_ACCEL = 110

export var JUMP_VELOCITY = 140
export var PUNCH_HOP = 20
export var PUNCH_DAMAGE = 1

onready var sprite = get_node('Sprite')
onready var animator = get_node('Animator')
onready var puncher = get_node('Puncher')

var on_floor = false
var on_ledge = false
var on_ladder = false
var in_liquid = false
var in_lava = false
var in_pain = false

var punching = false
var striking = false
var jumping = false
var stopping_jump = false
var dead = false

var can_jump = true
var can_punch = true

var can_use = true
var use_object = null
var current_ledge = null

var pending_warp = null


var air_time = 0.0
var floor_h_vel = 0.0

var anim = 'idle' setget _set_anim

var facing = 1 setget _set_facing

func _ready():
	pass


# Called by the 'punch' animation on Animator child..
func start_punch():
	punching = true
	var lv = get_linear_velocity()
	lv *= 0.1
	set_linear_velocity(lv)

func punch():
	var hop = PUNCH_HOP
	if in_liquid:	hop*=0.25
	var V = Vector2(hop*facing, -hop/2)
	set_linear_velocity(V)
	striking = true
#	if get_node('/root/World').hearts.is_full():
#		_shoot_powerball()
	
func end_punch():
	punching = false
	striking = false

func die():
	dead = true
	animator.play('die')

# Called when we get punched
func get_punched(punched_by, vector, damage):
	if not in_pain:
		vector = vector.normalized()*(damage*50)
		print("I got hit by a "+punched_by.get_name()+" for "+str(damage)+" hits!")
		set_linear_velocity(vector)
		get_node('/root/World').hud.get_node('HeartBox').take_hit(damage)
		in_pain = true
		get_node('PainTimer').start()

func _set_facing( value ):
	facing = value
	sprite.set_scale(Vector2(facing,1))
	puncher.set_cast_to(Vector2(8*facing,0))

func _set_anim( state ):
	anim = state
	animator.play(anim)

# State mainloop
func _integrate_forces(state):
	# Setup
	var delta = state.get_step()
	var lv = get_linear_velocity()
	var run_spd = RUN_ACCEL
	var max_spd = MAX_RUN_VELOCITY
	var air_spd = AIR_ACCEL
	var jump_pow = JUMP_VELOCITY
	if in_liquid:
		run_spd *= 0.25
		max_spd *= 0.25
		air_spd *= 0.25
		jump_pow *= 0.25
	
	var new_anim = anim
	var new_facing = facing
	
	# Process warping
	if pending_warp != null:
		var c = get_node('Camera')
		state.set_transform(Matrix32(0, pending_warp))
		c.reset_smoothing()
		print(get_global_pos())
		pending_warp = null
	
	# Get Input
	var LEFT = Input.is_action_pressed('run_left')
	var RIGHT = Input.is_action_pressed('run_right')
	var UP = Input.is_action_pressed('climb_up')
	if not UP and not can_use:		can_use = true
	var DOWN = Input.is_action_pressed('climb_down')
	var JUMP = Input.is_action_pressed('jump')
	if not JUMP and not can_jump:	can_jump = true
	var PUNCH = Input.is_action_pressed('punch')
	if not PUNCH and not can_punch:	can_punch = true
	
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
			var floor_y = int(state.get_contact_local_pos(x).y)
			if get_pos().y + 8 > floor_y:
				_pop_to_floor(floor_y)
			floor_index = x
			# Ledge Detection
			var L = state.get_contact_collider_object(x)
			var N = L.get_name()
			if N.begins_with("Ledge"):
				if not on_ledge:	
					on_ledge = true
					current_ledge = L
			else:	if on_ledge:	on_ledge = false
	
	# Calculate Airtime
	if found_floor:	air_time = 0.0
	else:	air_time += delta
	on_floor = air_time < MAX_FLOOR_AIRTIME
	
	if not dead:
		# Calculate Jump mechanics
		if jumping:
			if lv.y > 0:
				jumping = false
			elif not JUMP:
				stopping_jump = true
			if stopping_jump:
				lv.y += STOP_JUMP_FORCE*delta
			# Apply Punch input
			if not punching and PUNCH and can_punch:
				new_anim = 'punch'
		
		if not on_ledge and current_ledge:
			PS2D.body_remove_collision_exception(get_rid(), current_ledge.get_rid())
			current_ledge = null
		# On-Floor mechanics
		if on_floor and not punching:
			
			# USE an object with UP
			if use_object != null and can_use:
				if UP and not DOWN and not LEFT and not RIGHT:
					# Exclude speechFrame triggers that are already speaking
					if not use_object.has_node('SpeechFrame'):
						use_object.use()
						can_use = false

			# Apply left input
			if LEFT and not RIGHT:
				if lv.x > -max_spd:
					lv.x -= run_spd*delta
			# or Apply right input
			elif RIGHT and not LEFT:
				if lv.x < max_spd:
					lv.x += run_spd*delta
			# or Decellerate
			else:
				var xv = abs(lv.x)
				xv -= run_spd*delta
				if xv < 0:
					xv = 0
				lv.x = sign(lv.x)*xv
		
			# Apply Jump input
			if not jumping and JUMP and can_jump:
				if DOWN and current_ledge:
					PS2D.body_add_collision_exception(get_rid(), current_ledge.get_rid())
				else:
					#print(get_global_pos())
					lv.y -= jump_pow
					jumping = true
					stopping_jump = false
					can_jump = false
				
			if lv.x < 0 and LEFT:
				new_facing = -1
			elif lv.x > 0 and RIGHT:
				new_facing = 1
			
			# Decide on a new animation..
			if jumping:
				new_anim = 'jump'
			elif abs(lv.x) < 0.1:
				new_anim = 'idle'
			elif LEFT or RIGHT:
				new_anim = 'run'
			else:
				new_anim = 'idle'
			
			# Hop on ladder if on floor and pressing UP
			if on_ladder:
				if UP and not DOWN:
					lv.y -= 1
			
			# Apply Punch input
			if PUNCH and can_punch:
				new_anim = 'punch'
				can_punch = false
		
		# on ladder and not on floor
		elif on_ladder and not punching:
			jumping = false
			stopping_jump = false
			new_anim = 'climb'
			if jumping:	jumping = false
			if UP and not DOWN:
				if lv.y > -max_climb_velocity:
					lv.y -= air_spd*delta
			elif DOWN and not UP:
				if lv.y < max_climb_velocity:
					lv.y += air_spd*delta
			else:
				var yv = abs(lv.y)
				yv -= air_spd*delta*100
				if yv < 0:	yv = 0
				lv.y = sign(lv.y)*yv
				
			if LEFT and not RIGHT:
				if lv.x > -max_climb_velocity:
					lv.x -= air_spd*delta
			elif RIGHT and not LEFT:
				if lv.x < max_climb_velocity:
					lv.x += air_spd*delta
			else:
				var xv = abs(lv.x)
				xv -= air_spd*delta*100
				if xv < 0:	xv = 0
				lv.x = sign(lv.x)*xv
			lv.y = clamp(lv.y, -max_climb_velocity, max_climb_velocity)
			
		# Mid-air mechanics
		else:
			if not punching:
				if LEFT and not RIGHT:
					if lv.x > -max_spd:
						lv.x -= air_spd*delta
				elif RIGHT and not LEFT:
					if lv.x < max_spd:
						lv.x += air_spd*delta
				else:
					var xv = abs(lv.x)
					xv -= air_spd*delta
					if xv < 0:	xv = 0
					lv.x = sign(lv.x)*xv
				new_anim = 'jump'
			# Apply Punch input
			if PUNCH and can_punch:
				new_anim = 'punch'
				can_punch = false
	
	else:
		new_anim = 'die'
		if on_floor:
			var xv = abs(lv.x)
			xv -= run_spd*delta
			if xv < 0:	xv = 0
			lv.x = sign(lv.x)*xv

	# Update facing
	if facing != new_facing:
		set('facing', new_facing)
	# Update animator
	if anim != new_anim:
		set('anim', new_anim)
	
	# Apply floor velocity
	if found_floor:
		floor_h_vel = state.get_contact_collider_velocity_at_pos(floor_index).x
	
	# Apply gravity and velocity
	if not on_ladder:
		var g = state.get_total_gravity()
		if punching:	g.y*=0.75
		if in_liquid:	g.y*=0.1
		lv += g*delta
	state.set_linear_velocity(lv)
	
	# Process Punchees
	if striking:
		if puncher.is_colliding():
			var punchee = puncher.get_collider()
			# Only bodies that can be punched, will be punched
			if punchee.has_method('get_punched'):	# punchable mob
				punchee.get_punched(self,puncher.get_cast_to(), PUNCH_DAMAGE)
				striking = false
			elif 'lock_type' in punchee:	# locked door
				punchee.unlock()
			# Rebound from punching the wall
			var V = -puncher.get_cast_to().normalized()
			set_linear_velocity(V*50)
		elif get_node('/root/World').hearts.is_full():
			_shoot_powerball()
			striking = false
	
	if not in_pain:
		if in_lava and not dead:
			get_punched(self, Vector2(0,0), 4)
	
	if dead and PUNCH:
		get_node('/root/World').respawn()
	
func _pop_to_floor(y):
	var pos = get_pos()
	pos.y = y - 8.0001
	set_pos(pos)

func _shoot_powerball():
	var pb = powerball.instance()
	get_owner().add_child(pb)
	pb.owner = self
	var pos = get_pos()
	pos += Vector2(4*facing, 0)
	pb.set_pos(pos)
	
	pb.Shoot(Vector2(facing,0))

# The Detector detects any Area-based objects that come in contact
# with the player. This includes ladders, warp doors, and powerups.
func _on_Detector_area_enter( area ):
	# Process ladders
	if area.get_name().begins_with('Ladders'):
		if not on_ladder:	on_ladder = true
	
	if area.get_name().begins_with('Slime'):
		if not dead:
			pass
			#die()
		if not in_liquid:
			in_liquid = true
	if area.get_name().begins_with('Lava'):
		if not in_liquid:
			in_liquid = true
		if not in_lava:
			in_lava = true
	
	# Process Pick-Up items
	if area.has_method('pickup'):
		area.pickup()

	
	elif area.has_method('use'):
		use_object = area
	
func _on_Detector_area_exit( area ):
	# Process exit ladders
	if area.get_name().begins_with('Ladders'):
		if on_ladder:	on_ladder = false
		# Ensure flip reset after climbing animation is changed
		sprite.set_flip_h(false)


	if area.get_name().begins_with('Slime'):
		if in_liquid:	in_liquid = false
	if area.get_name().begins_with('Lava'):
		if in_liquid:	in_liquid = false
		if in_lava:		in_lava = false

	if area.has_method('use'):
		if use_object:	use_object = null

func _on_PainTimer_timeout():
	in_pain = false
