
extends RigidBody2D
tool

var path = 'res://graphics/items/'

var sprite = Sprite.new()
var shape = CollisionPolygon2D.new()

export var lock_type = 0 setget _set_lock_type

func _set_lock_type( value ):
	value = clamp(value,0,3)
	var tex = load(path+'door'+str(value)+'.png')
	lock_type = value
	if sprite:
		sprite.set_texture(tex)

func _enter_tree():
	add_child(shape)
	add_child(sprite)
	
	set_mode(MODE_STATIC)
	var square = Vector2Array([
		Vector2(-8,-8), Vector2(8,-8),
		Vector2(8,8), Vector2(-8,8)])
	shape.set_polygon(square)
	set('lock_type', lock_type)

func unlock():
	if lock_type in get_node('/root/GameState').Keys:
		if get_node('/root/GameState').Keys[lock_type] > 0:
			get_node('/root/GameState').remove_key(lock_type)
			hide()
			PS2D.body_clear_shapes(get_rid())
			#print(GameState.Keys)