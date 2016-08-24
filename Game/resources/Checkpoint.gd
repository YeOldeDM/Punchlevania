
extends Area2D

onready var sprite = get_node('Sprite')
onready var animator = get_node('Animator')
onready var parti = get_node('Particles')

var active = false

func _ready():
	parti.set_emitting(false)

func use():
	if not active:
		animator.play('activate')
		active = true
		get_node('/root/World').set_checkpoint(get_name())

func activate():
	active = true
	sprite.set_frame(3)
	parti.set_emitting(true)

func deactivate():
	active = false
	sprite.set_frame(0)
	parti.set_emitting(false)


