
extends Node2D

onready var map = get_node('Map')
onready var hud = get_node('HUD')
onready var player = get_node('Player')

var in_menu = false
var in_pause = false

func _ready():
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


func warp(destination, door='GAME_Door'):
	var path = 'res://maps/'+destination+'.tscn'
	var new_map = load(path)
	if !new_map:	
		OS.alert("Could not find"+path+"!")
	new_map = new_map.instance()
	map.queue_free()
	add_child(new_map)
	move_child(new_map, 0)
	map = new_map
	
	var new_door = map.find_node(door)
	if new_door:
		player.pending_warp = new_door.get_pos()
	
	