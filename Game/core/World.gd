
extends Node2D

onready var hud = get_node('HUD')
onready var hearts = hud.get_node('HeartBox')
onready var player = get_node('Player')
onready var map = get_node('Map')

var in_menu = false
var in_pause = false

var respawn_map = 'brown_castle'
var respawn_point = 'START'

var player_obj = preload('res://resources/player.tscn')


func _ready():
	# Bootstrap map system
	warp(GameState.initial_map, 'START')
	
	set_process_input(true)

func _input(event):
	if event.type != InputEvent.KEY:
		return
	if event.pressed and not event.is_echo():
		if event.is_action_pressed('pause'):
			toggle_pause(true)
		
		if event.is_action_pressed('menu'):
			toggle_menu()
			

# Toggle Pause State, with these rules:
#	-pause while menu is on
#	-disable unpausing while menu is on
#	-toggle on/off while menu is off
func toggle_pause( manual=false ):
	if get_tree().is_paused():
			if in_menu:	return
			get_tree().set_pause(false)
			print('pause OFF!')
			hud.get_node('PauseLabel').hide()
	else:
		get_tree().set_pause(true)
		print('pause ON!')
		hud.get_node('PauseLabel').show()
	# manual=true, function is called via key input
	# manual=false, function is called via toggle_menu func
	if manual:
		in_pause = get_tree().is_paused()


func toggle_menu():
	if in_menu:
		in_menu = false
		print('menu OFF!')
		hud.get_node('Menu').hide()

	else:
		in_menu = true
		print('menu ON!')
		hud.get_node('Menu').popup_centered()
	toggle_pause()

func respawn():
	var new_player = player_obj.instance()
	player.queue_free()
	add_child(new_player)
	player = new_player
	
	warp(respawn_map, respawn_point)
	hearts.restore_hit(hearts.max_hearts*4)
	

func warp(destination, door='GAME_Door'):
	var path = ''
	if typeof(destination) == TYPE_STRING:
		path = 'res://maps/'+destination+'.tscn'
	else:
		path = destination.get_filename()
	var new_map = null
	if map:
		if map.get_filename() != path:
			new_map = load(path)
	elif not map:
		var new_map = load(path)
	if new_map:
		map.queue_free()
		new_map = new_map.instance()
		add_child(new_map)
		move_child(new_map, 0)
		map = new_map

	
	var new_door = map.find_node(door)
	if new_door:
		player.pending_warp = new_door.get_pos()
	
func actor_say( what, where ):
	print(what)
	var frame = preload('res://resources/SpeechFrame.tscn').instance()
	frame.set_text(what)
	where.add_child(frame)

func set_checkpoint( point ):
	respawn_map = map
	respawn_point = point