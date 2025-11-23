extends CharacterBody2D

enum {
	IDLE,
	ATTACK,
	CHASE,
	DAMAGE,
	DEATH,
	RECOVER
}

var state: int = 0:
	set(value):
		state = value
		match state:
			IDLE:
				idle_state()
			ATTACK:
				attack_state()
			DAMAGE:
				damage_state()
			DEATH:
				death_state()
			RECOVER:
				recover_state()

@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D

var graviry = ProjectSettings.get_setting("physics/2d/default_gravity")
var player 
var direction
var damage = 25
var health = 100
var speed = 50

func _ready():
	Signals.connect("player_position_update", Callable(self, "_on_player_position_update"))
	Signals.connect("player_attack", Callable(self, "_on_damage_received"))

func _on_player_death():
	state = IDLE
	animPlayer.play("Idle")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += graviry * delta
		
	if state == CHASE:
		chase_state()
	
	move_and_slide()

func _on_player_position_update(player_pos):
	player = player_pos

func _on_attack_range_body_entered(_body):
	state = ATTACK
	
func idle_state():
	animPlayer.play("Idle")
	state = CHASE
	
func attack_state():
	animPlayer.play("Attack")
	await animPlayer.animation_finished
	state = RECOVER
	
func chase_state():
	direction = (player - self.position).normalized()
	if direction.x < 0:
		sprite.flip_h = true
		$AttackDirection.rotation_degrees = 180
	else:
		sprite.flip_h = false
		$AttackDirection.rotation_degrees = 0
		

func damage_state():
	animPlayer.play("Damage")
	await animPlayer.animation_finished
	state = IDLE
	
func death_state():
	animPlayer.play("Death")
	await animPlayer.animation_finished
	queue_free()
	
func recover_state():
	animPlayer.play("Recover")
	await animPlayer.animation_finished
	state = IDLE

func _on_hit_box_area_entered(_area):
	Signals.emit_signal("enemy_attack", damage)
	
func _on_damage_received(player_damage):
	health -= player_damage
	if health <= 0:
		state = DEATH
	else:
		state = IDLE
		state = DAMAGE
