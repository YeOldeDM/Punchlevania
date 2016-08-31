
extends RigidBody2D
tool

var hits = 0 setget _set_hits

var path = 'res://graphics/items/'

var sprite = Sprite.new()
var shape = CollisionPolygon2D.new()

func _set_hits( value ):
	hits = value
	if hits > 3:
		die()
	else:
		sprite.set_frame(hits)

func _enter_tree():
	add_child(shape)
	add_child(sprite)
	
	set_mode(MODE_STATIC)
	sprite.set_texture(load(path+'punch_door0.png'))
	sprite.set_hframes(4)
	sprite.set_frame(0)
	var square = Vector2Array([
		Vector2(-8,-8), Vector2(8,-8),
		Vector2(8,8), Vector2(-8,8)])
	shape.set_polygon(square)

func get_punched(source, origin, damage):
	set('hits', hits+damage)

func die():
	PS2D.body_clear_shapes(get_rid())
	hide()