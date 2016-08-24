
extends RigidBody2D

var MAX_FLOOR_AIRTIME = 0.15

export var STOP_JUMP_FORCE = 190

export var MAX_RUN_VELOCITY = 100
export var RUN_ACCEL = 400
export var AIR_ACCEL = 110

export var JUMP_VELOCITY = 140
export var PUNCH_HOP = 50
export var PUNCH_DAMAGE = 1

onready var sprite = get_node('Sprite')
onready var animator = get_node('Animator')


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


