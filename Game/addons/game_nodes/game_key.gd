
extends Area2D
tool

var path = 'res://graphics/items/'

var sprite = Sprite.new()
var shape = CollisionShape2D.new()

export var key_type = 0 setget _set_key_type

func _set_key_type( value ):
	var type = clamp(value, 0, 3)
	var tex = load(path+'key'+str(type)+'.png')
	key_type = type
	if sprite:
		sprite.set_texture(tex)
	else:
		print("NO")

func _enter_tree():
	add_child(shape)
	add_child(sprite)
	
	var sh = CircleShape2D.new()
	sh.set_radius(8)
	shape.set_shape(sh)
	
	set('key_type', key_type)
	
	
func pickup():
	get_node('/root/GameState').add_key(key_type)
	#print(GameState.Keys)
	queue_free()

