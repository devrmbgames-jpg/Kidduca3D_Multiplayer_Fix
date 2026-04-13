extends RigidBody

var can_trap := true

var _max_speed_ball := 15.0

func _physics_process(_delta) -> void :
	if linear_velocity.length() > _max_speed_ball * 1.1:
		linear_velocity = linear_velocity.normalized() * _max_speed_ball
