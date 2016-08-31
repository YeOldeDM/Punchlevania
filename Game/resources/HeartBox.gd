
extends Node2D

export var max_hearts = 3

var heart = preload('res://resources/HeartCounter.tscn')


func take_hit(amount):
	get_child(get_child_count()-1).take_hit(amount)

func restore_hit(amount):
	get_child(0).restore_hit(amount)

func is_full():
	return get_child(get_child_count()-1).is_full()

func _ready():
	var pos = get_pos()+Vector2(16,12)
	for i in range(max_hearts):
		var h = heart.instance()
		add_child(h)
		pos.x += 16
		h.set_pos(pos)
	for i in range(get_child_count()):
		var h = get_child(i)
		h.connect('death',self,'_on_Death')
		h.connect('full', self, '_on_Full')
		if i != 0:
			h.next_heart = get_child(i-1)
		if i != get_child_count() - 1:
			h.prev_heart = get_child(i+1)
		
	
	#set_process_input(true)

# FOR TESTING PURPOSES ONLY
func _input(event):
	if event.type == InputEvent.KEY:
		if event.scancode == KEY_SPACE:
			take_hit(1)
		elif event.scancode == KEY_SHIFT:
			restore_hit(1)

func _on_Death():
	get_node('../../').player.die()

func _on_Full():
	print("FULL")



