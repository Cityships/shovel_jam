class_name MenInBlack extends Patroller

@onready var beam: Line2D = %Beam
@onready var ray: RayCast2D = %Ray

@export var max_distance   : float = 800.0
@export var flash_time     : float = 0.05
@export var cooldown_time  : float = 0.5
@export var damage         : int   = 10

var _ready_to_fire: bool = true
var _has_fired_during_attack: bool = false

func _ready() -> void:
	if base_enemy_body:
		base_enemy_body.state_changed.connect(_on_state_changed)

func _on_state_changed(state):
	if state == base_enemy_body.State.ATTACK and not _has_fired_during_attack:
		_has_fired_during_attack = true
		await shoot_laser()
	elif state != base_enemy_body.State.ATTACK:
		_has_fired_during_attack = false  


func shoot_laser() -> void:
	if not _ready_to_fire:
		return

	_ready_to_fire = false
	ray.enabled = true

	var aim_direction = Vector2(base_enemy_body._move_dir, 0).normalized()
	var aim_end = global_position + aim_direction * max_distance
	ray.target_position = ray.to_local(aim_end)
	ray.force_raycast_update()

	var hit_pos: Vector2
	if ray.is_colliding():
		hit_pos = ray.get_collision_point()
		var body = ray.get_collider()
		if body and body.has_method("apply_damage"):
			body.apply_damage(damage)
	else:
		hit_pos = aim_end

	beam.global_position = ray.global_position
	beam.points = [Vector2.ZERO, hit_pos - beam.global_position]
	beam.visible = true

	await get_tree().create_timer(flash_time).timeout
	beam.visible = false
	ray.enabled = false

	await get_tree().create_timer(cooldown_time - flash_time).timeout
	_ready_to_fire = true

	base_enemy_body.enter_state(base_enemy_body.State.WIND_UP)
