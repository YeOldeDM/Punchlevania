
extends RigidBody2D

var owner

var damage = 1
var speed = 160

var life = 0.5

func Shoot(direction):

	get_node('Sprite').set_scale(Vector2(sign(direction.x),1))
	var lv = direction.normalized() * speed
	set_linear_velocity(lv)
	get_node('KillTimer').start()

func _ready():
	get_node('KillTimer').set_wait_time(life)


func _kill():
	queue_free()


func _on_KillTimer_timeout():
	_kill()


func _on_Visibility_exit_screen():
	_kill()


func _on_Area2D_body_enter( body ):
	if body extends TileMap:
		_kill()
	if body.has_method('get_punched') and owner:
		if body != owner:
			var dir = body.get_pos() - get_pos()
			dir.y = 0
			body.get_punched(self, dir, damage)
			_kill()
