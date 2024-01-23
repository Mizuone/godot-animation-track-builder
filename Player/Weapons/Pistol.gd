extends Node3D

class_name Pistol

var ready_to_fire = true : set = set_ready_to_fire, get = get_ready_to_fire

func fire():
	set_ready_to_fire(false);

func fire_finished():
	set_ready_to_fire(true)

func reload_finished():
	set_ready_to_fire(true)

func set_ready_to_fire(value: bool):
	ready_to_fire = value

func get_ready_to_fire():
	return ready_to_fire
