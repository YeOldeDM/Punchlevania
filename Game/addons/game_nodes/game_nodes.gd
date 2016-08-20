
extends EditorPlugin
tool
var path = 'res://addons/game_nodes/'

func _enter_tree():
	add_custom_type("GAME_Key", "Area2D", load(path+'game_key.gd'), load(path+'game_key_icon.png'))
	add_custom_type("GAME_Door", "RigidBody2D", load(path+'game_door.gd'), load(path+'game_door_icon.png'))
	add_custom_type("GAME_Portal", "Area2D", load(path+'game_portal.gd'), load(path+'game_portal_icon.png'))
	add_custom_type("GAME_Food", "Area2D", load(path+'game_food.gd'), load(path+'game_food_icon.png'))
	
func _exit_tree():
	remove_custom_type("GAME_Key")
	remove_custom_type("GAME_Door")
	remove_custom_type("GAME_Portal")
	remove_custom_type("GAME_Food")

