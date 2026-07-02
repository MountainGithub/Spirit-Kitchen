extends CharacterBody2D

enum Animations {
	JUMP, LAND, ATTACK, IDLE
}

# loading scene
const fx_landingdust = preload("res://assets/particles/landingdust.tscn")

#defind childs
@onready var sprite = $pivot/sprite
@onready var sprite_pivot = $pivot
@onready var debug = $debug
@onready var animation_player = $animation_player
@onready var pan = $pivot/pan

@export var max_speed: int = 300
@export var acceleration: int = 12
@export var friction: int = 8
var default_scale = Vector2(1.0,1.0)

var facing: int
var is_attacking: bool = false
var animation_jump_strengh_set: float = 3
var animation_jump_strengh: float = 0.0
var animation_offset_y: float = 0.0

func _ready() -> void:
	play_animation(Animations.IDLE)
	animation_player.animation_finished.connect(animation_finished)

func _process(delta: float) -> void:
	
	#debug.text = str(animation_jump_strengh) + '\n' + str(animation_offset_y)
	sprite.offset.y = animation_offset_y
	pan.offset.y = animation_offset_y * facing
	
	if Input.is_action_just_pressed("attack"):
		play_animation(Animations.ATTACK)

func _physics_process(delta: float) -> void:
	var input = Vector2(
		Input.get_action_strength('right') - Input.get_action_strength('left'),
		Input.get_action_strength('down') - Input.get_action_strength('up')	
	).normalized()
	
	
	var mouse_x = get_local_mouse_position().x
	if mouse_x > 50:
		sprite.flip_h = false
		facing = 1
	elif mouse_x < -50:
		sprite.flip_h = true
		facing = -1
	if not is_attacking:
		play_animation(Animations.IDLE)
		
	pan.look_at(get_global_mouse_position())
	
	
	if animation_jump_strengh == 0 and animation_offset_y == 0:
		if input != Vector2.ZERO:
			animation_jump_strengh = animation_jump_strengh_set
			play_animation(Animations.JUMP)
	else:
		animation_offset_y -= animation_jump_strengh
		animation_jump_strengh -= 0.3
		if animation_jump_strengh < 0 and animation_offset_y > 0:
			animation_jump_strengh = 0
			animation_offset_y = 0
			play_animation(Animations.LAND)
			spawn_landingdust()
	
	var lerp_weight = delta * (acceleration if input else friction)
	velocity = lerp(velocity, input * max_speed, lerp_weight)
	
	move_and_slide()

func play_animation(animation):
	match animation:
		Animations.JUMP:
			var tween = create_tween()
			tween.set_parallel()
			tween.tween_property(sprite_pivot, "scale:x", default_scale.x - 0.2, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			tween.tween_property(sprite_pivot, "scale:y", default_scale.y + 0.1, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			
			tween.chain().tween_property(sprite_pivot, "scale:x", default_scale.x, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			tween.tween_property(sprite_pivot, "scale:y", default_scale.y, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		
		Animations.LAND:
			var tween = create_tween()
			tween.set_parallel()
			tween.tween_property(sprite_pivot, "scale:x", default_scale.x + 0.2, 0.05).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			tween.tween_property(sprite_pivot, "scale:y", default_scale.y - 0.1, 0.05).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)

			tween.chain().tween_property(sprite_pivot, "scale:x", default_scale.x, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			tween.tween_property(sprite_pivot, "scale:y", default_scale.y, 0.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			
		Animations.IDLE:
			if facing == 1:
				animation_player.play("idle-right")
			else:
				animation_player.play("idle-left")
			
		Animations.ATTACK:
			is_attacking = true
			if facing == 1:
				animation_player.play("attack-right")
			else:
				animation_player.play("attack-left")
			
func animation_finished(animation):
	if animation in ["attack-right", "attack-left"]:
		play_animation(Animations.IDLE)
		is_attacking = false
			
func spawn_landingdust():
	var fx = fx_landingdust.instantiate()
	get_parent().add_child(fx)
	fx.global_position = self.global_position
	fx.emitting = true
