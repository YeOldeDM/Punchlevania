
extends Area2D
tool

var path = 'res://graphics/items/'

export var Sign = 0 setget _set_sign_texture
export(String, MULTILINE) var Message = ""

var sprite = Sprite.new()
var shape = CollisionShape2D.new()


func _set_sign_texture( what ):
	what = clamp(what, 0, 2)
	var file = path+'sign'+str(what)+'.png'
	var tex = load(file)
	if tex:
		sprite.set_texture(tex)
		Sign = what
	else:
		OS.alert("No file: "+file)

func _enter_tree():
	add_child(sprite)
	add_child(shape)
	
	var sh = CircleShape2D.new()
	sh.set_radius(8)
	shape.set_shape(sh)
	
	set('Sign', Sign)

func use():
	get_node('/root/World').actor_say(Message, self)


