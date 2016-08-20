
extends Area2D
tool

var path = 'res://graphics/items/'

var sprite = Sprite.new()
var shape = CollisionPolygon2D.new()

export var destination_map = "NO MAP"
export var destination_portal = "NO DOOR"

func _enter_tree():
	add_child(shape)
	add_child(sprite)
	sprite.set_texture(load(path+'portal2.png'))
	var square = Vector2Array([
		Vector2(-8,-8), Vector2(8,-8),
		Vector2(8,8), Vector2(-8,8)])
	shape.set_polygon(square)
	set_z(-1)

func warp():
	prints(destination_map, destination_portal)
	get_node('/root/World').warp(destination_map, destination_portal)

