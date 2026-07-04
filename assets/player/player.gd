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
@onready var pan_pivot = $pivot/sprite/pan_pivot
@onready var pan = $pivot/sprite/pan_pivot/pan

@export var max_speed: int = 300
@export var acceleration: int = 12
@export var friction: int = 8
@export var can_attack_again: bool = true

var default_scale = Vector2(1.0,1.0)

var facing: int = 1
var is_attacking: bool = false
var animation_jump_strengh_set: float = 3
var animation_jump_strengh: float = 0.0
var animation_offset_y: float = 0.0
var alpha: float = 1.0

func _ready() -> void:
	play_animation(Animations.IDLE)
	animation_player.animation_finished.connect(animation_finished)

func _process(delta: float) -> void:
	
	#debug.text = "pivot: " + str(pan_pivot.rotation_degrees) + '\n' + "pan: " + str(pan.rotation_degrees) + ' ' + str(pan.flip_v)
	#debug.text = "pivot: " + str(pan_pivot.rotation_degrees) 
	debug.text = str(can_attack_again) 
	#debug.text = str($pivot/sprite/pan_pivot/Hitbox/CollisionPolygon2D.disabled) 
	
	sprite.offset.y = animation_offset_y - 60
	pan.offset.y = animation_offset_y * facing
	$pivot/sprite/pan_pivot/pan/trail.offset.y = animation_offset_y * facing
	
	if Input.is_action_just_released("attack"):
		if not is_attacking or can_attack_again:
			pan_pivot.look_at(get_global_mouse_position())
			animation_player.stop()
			play_animation(Animations.ATTACK)

func _physics_process(delta: float) -> void:
	var input = Vector2(
		Input.get_action_strength('right') - Input.get_action_strength('left'),
		Input.get_action_strength('down') - Input.get_action_strength('up')	
	).normalized()
	
	rotation(delta)
	
	jumping(input)
	
	var lerp_weight = delta * (acceleration if input else friction)
	velocity = lerp(velocity, input * max_speed, lerp_weight)
	
	move_and_slide()

#handling rotation and animations
func rotation(delta):
	var mouse_pos = get_local_mouse_position()
	if mouse_pos.y > -100:
		pan_pivot.show_behind_parent = false
		alpha = lerp(alpha, 1.0, 0.1)
	else:
		pan_pivot.show_behind_parent = true
		alpha = lerp(alpha, 0.5, 0.1)
	sprite.set_self_modulate(Color(1,1,1,alpha))
	
	if is_attacking and not can_attack_again:
		return
	
	if not is_attacking or can_attack_again:
		if Vector2.ZERO.distance_to(mouse_pos) > 20:
			if mouse_pos.x > 20:
				sprite.flip_h = false
				facing = 1
			elif mouse_pos.x < -20:
				sprite.flip_h = true
				facing = -1
			if not is_attacking:
				var target_angle = global_position.angle_to_point(get_global_mouse_position())
				pan_pivot.rotation = lerp_angle(pan_pivot.rotation, target_angle, 25 * delta)

		if not is_attacking:
			play_animation(Animations.IDLE)

# jump if moving
func jumping(input):
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
	if animation in ["attack-left", "attack-right"]:
		play_animation(Animations.IDLE)
		is_attacking = false
			
func spawn_landingdust():
	var fx = fx_landingdust.instantiate()
	get_parent().add_child(fx)
	fx.global_position = self.global_position
	fx.emitting = true
