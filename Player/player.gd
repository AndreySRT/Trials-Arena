extends CharacterBody2D

signal health_changed (new_health)
signal player_attack(damage)

enum {
	MOVE,
	ATTACK,
	COMBO1,
	COMBO2,
	BLOCK,
	SLIDE,
	DAMAGE,
	DEATH
}

const SPEED = 150.0
const JUMP_VELOCITY = -400.0

var graviry = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer

var max_health = 100
var health
var gold = 0
var run_speed = 1
var state = MOVE
var combo = false
var attack_cooldawn = false
var player_pos
var damage_basic = 10
var damage_multiplier = 1
var damage_current

func _ready():
	Signals.connect("enemy_attack", Callable (self, "_on_damage_received"))
	health = max_health

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += graviry * delta
	if velocity.y > 0:
		animPlayer.play("Fall")
		
	damage_current = damage_basic * damage_multiplier
		
	match state:
		MOVE:
			move_state()
		ATTACK:
			attack_state()
		COMBO1:
			combo1_state()
		COMBO2:
			combo2_state()
		BLOCK:
			block_state()
		SLIDE:
			slide_state()
		DAMAGE:
			damage_state()
		DEATH:
			death_state()
		
	move_and_slide()
	

	player_pos = self.position
	Signals.emit_signal("player_position_update", player_pos)
	
func move_state ():
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED * run_speed
		if velocity.y == 0:
			if run_speed == 1:
				animPlayer.play("Walk")
			else:
				animPlayer.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			animPlayer.play("Idle")
	#flip sprite
	if direction == -1:
		$AnimatedSprite2D.flip_h = true
		$AttackDirection.rotation_degrees = 180
	elif direction == 1:
		$AnimatedSprite2D.flip_h = false
		$AttackDirection.rotation_degrees = 0
		
	if Input.is_action_pressed("run"):
		run_speed = 1.5
	else:
		run_speed = 1
	if Input.is_action_pressed("attack"):
		if attack_cooldawn == false:
			state = ATTACK

	
	if Input.is_action_just_pressed("slide") and velocity.x != 0:
		state = SLIDE
	elif Input.is_action_pressed("slide") and velocity.x == 0:
		state = BLOCK

func attack_state ():
	damage_multiplier = 1
	if Input.is_action_just_pressed("attack") and combo == true:
		state = COMBO1
	velocity.x = 0
	animPlayer.play("Attack")
	emit_signal("player_attack", damage_current)
	await animPlayer.animation_finished
	attack_freeze()
	state = MOVE

func block_state ():
	velocity.x = move_toward(velocity.x, 0, SPEED)
	animPlayer.play("Block")
	if Input.is_action_just_released("slide"):
		state = MOVE

func slide_state ():
	animPlayer.play("Slide")
	await animPlayer.animation_finished
	state = MOVE
	
func death_state ():
	velocity.x = 0
	anim.play("Death")
	await get_tree().create_timer(1.0).timeout
	queue_free()
	get_tree().change_scene_to_file("res://menu.tscn")
	
func combo1():
	combo = true
	await animPlayer.animation_finished
	combo = false

func combo1_state():
	damage_multiplier = 1.2
	if Input.is_action_just_pressed("attack") and combo == true:
		state = COMBO2
	velocity.x = 0
	animPlayer.play("Attack2")
	emit_signal("player_attack", damage_current)
	await animPlayer.animation_finished
	
	state = MOVE

func combo2():
	combo = true
	combo = true
	await animPlayer.animation_finished
	combo = false

func combo2_state():
	damage_multiplier = 2
	if $AnimatedSprite2D.flip_h == true:
		velocity.x = -30
	else:
		velocity.x = 30
	animPlayer.play("Attack3")
	emit_signal("player_attack", damage_current)
	await animPlayer.animation_finished
	combo = false
	state = MOVE


func attack_freeze ():
	attack_cooldawn = true
	await get_tree().create_timer(0.5).timeout
	attack_cooldawn = false
	
func damage_state ():
	velocity.x = 0
	anim.play("Damage")
	await anim.animation_finished
	state = MOVE

func _on_damage_received (enemy_damage):
	if state == BLOCK:
		enemy_damage /= 2
	elif state == SLIDE:
		enemy_damage = 0
	else:
		state = DAMAGE
	health -= enemy_damage
	if health <= 0:
		health = 0
		state = DEATH
		
	emit_signal("health_changed", health)
	print(health)

func _on_hit_box_area_entered(_area):
	emit_signal("player_attack", damage_current)
