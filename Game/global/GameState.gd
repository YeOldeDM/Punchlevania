
extends Node

const initial_map = 'brown_castle'

onready var world = get_node('/root/World')
onready var hud = world.get_node('HUD')

var Keys = {}

var food = 0

func add_food(points):
	food += points
	print("You have "+str(food)+" points")

func add_key(type):
	if type in Keys:
		Keys[type] += 1
	else:
		Keys[type] = 1
	print(Keys)

func remove_key(type):
	if type in Keys:
		if Keys[type] > 0:
			Keys[type] -= 1
	print(Keys)


