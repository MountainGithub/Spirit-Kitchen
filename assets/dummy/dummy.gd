extends CharacterBody2D

func take_damage(damage):
	$AnimationPlayer.stop()
	$AnimationPlayer.queue("hurt")
