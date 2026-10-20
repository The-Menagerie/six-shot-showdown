extends Node
class_name HealthComponent

@export var MAX_HEALTH := 1.0
var health : float
var fatal_attack: Attack
var owner_of
func _ready():
	health = MAX_HEALTH

func damage(attack: Attack):
	health -= attack.attack_damage
	if health <= 0:
		if fatal_attack == null:
			fatal_attack = attack
		var parent = get_parent()
		if parent.has_method("handle_death"):
			parent.handle_death()
		else:
			parent.target_destroyed.emit(parent)
			parent.queue_free()
