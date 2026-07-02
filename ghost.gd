extends Node2D

@onready var sprite = $sprite

var phase: float = 0

func _process(delta: float) -> void:
	phase += delta * 2
	sprite.offset.y = sin(phase) * 10
