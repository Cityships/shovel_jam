## Laser Turret Controller
##
## Provides hitscan laser functionality for a turret or weapon sprite. The script:
##  • Casts a RayCast2D each time the laser is fired to determine hit position.
##  • Draws a Line2D “beam” for a brief flash to visualise the shot.
##  • Applies optional damage to colliders that implement `apply_damage()`. No actual implementation, simply place holder. 
##  • Handles cooldown timing so the laser cannot be spam‑fired.
##  • Can run a temporary EMP‑style shader effect via `play_emp_disable()`.
##
## **Node setup requirements**
## Attach this script to an **AnimatedSprite2D** that has exactly two children:
##  • **RayCast2D** named **"Ray"** – used to detect what the laser hits.
##  • **Line2D**   named **"Beam"** – used to render the laser flash.
##
## Godot version: 4.4.1

extends AnimatedSprite2D

@onready var ray  : RayCast2D = %Ray   ## Cached reference to the RayCast2D child.
@onready var beam : Line2D    = %Beam  ## Cached reference to the Line2D child.

## Maximum travel distance of the laser in pixels. If the ray hits nothing     
## within this distance, the beam stops at max_distance.
@export var max_distance  : float = 800.0

## How long (seconds) the beam is visible after a shot. That way we can do Continuos beem or single shots to bursts. 
@export var flash_time    : float = 0.05

## Delay (seconds) after each shot before the laser can fire again.            
## This implicitly includes `flash_time` – make sure `cooldown_time` > `flash_time`.
@export var cooldown_time : float = 0.5

## Damage applied to a collider that implements an `apply_damage(amount:int)`  
## method. 0 disables damage.
@export var damage        : int   = 10

## Internal flag that indicates whether the laser is ready to fire.            
## Managed automatically by `shoot_laser()`.
var _ready_to_fire := true


#───────────────────────────────────────────────────────────────────────────────
## Lifecycle
#───────────────────────────────────────────────────────────────────────────────

## Called when the node enters the scene tree. Duplicate the material so that
## shader parameters can be modified per‑instance without affecting siblings.
func _ready() -> void:
	material = material.duplicate()


#───────────────────────────────────────────────────────────────────────────────
## Shader helpers
#───────────────────────────────────────────────────────────────────────────────

## Toggles a solid‑fill colour inside the shader.
##
## @param flag  If **true**, the shader fills the sprite with `color`.
## @param color Colour used when `flag` is **true**.
func set_solid_color(flag: bool, color: Color) -> void:
	# `modulate` cannot override a custom shader; expose a uniform instead.
	material.set_shader_parameter("fill_color", color)
	material.set_shader_parameter("fill_enabled", flag)

## Enables or disables a grayscale shader pass.
func set_grayscale(flag: bool) -> void:
	material.set_shader_parameter("grayscale_enabled", flag)


#───────────────────────────────────────────────────────────────────────────────
## Visual EMP effect
#───────────────────────────────────────────────────────────────────────────────

## Runs a temporary flickering grayscale / white effect to simulate an EMP
## shutdown. Timing is split into two phases: a short initial flash followed
## by a longer stochastic flicker.
##
## @param duration Total duration (seconds) of the effect.
func play_emp_disable(duration : float) -> void:
	var tween = create_tween()

	## Phase 1 – fade to grayscale.
	tween.tween_callback(set_grayscale.bind(true))
	tween.chain().tween_interval(0.50 * duration)

	## Phase 2 – rapid white/normal flashes.
	tween.chain().tween_method(            ## 0 → 4 toggles
		func(value):
			if fmod(value, 2) == 0:
				set_solid_color(true, Color.WHITE)
			else:
				set_solid_color(false, Color.WHITE),
		0, 4, 0.25 * duration
	)
	tween.chain().tween_method(            ## 5 → 15 slower toggles
		func(value):
			if fmod(value, 2) == 0:
				set_solid_color(true, Color.WHITE)
			else:
				set_solid_color(false, Color.WHITE),
		5, 15, 0.25 * duration
	)

	## Cleanup – restore original shader state.
	tween.chain().tween_callback(set_solid_color.bind(false, Color.WHITE))
	tween.chain().tween_callback(set_grayscale.bind(false))


#───────────────────────────────────────────────────────────────────────────────
## Firing logic
#───────────────────────────────────────────────────────────────────────────────

## Fires the laser once if it is ready.
##
## Behaviour overview:
##  • Enables the RayCast2D and forces an update to detect a hit.
##  • If a collider is detected and has `apply_damage()`, damage is applied. Dmg is not implemented
##  • Computes the end‑point (hit or max range) and draws the beam.
##  • Waits `flash_time` seconds, hides the beam, disables the ray.
##  • Waits the remaining cooldown, then marks the laser as ready again.

func shoot_laser() -> bool:
	## Head fires only if controller says it may.
	if not _ready_to_fire:
		return false          # let caller know it failed

	_ready_to_fire = false   # lock immediately

	## ───── raycast straight ahead ─────
	ray.enabled = true
	ray.target_position = Vector2.RIGHT * max_distance
	ray.force_raycast_update()

	var hit_pos : Vector2
	if ray.is_colliding():
		hit_pos = ray.get_collision_point()
		var body := ray.get_collider()
		if body.is_in_group("Player"):
			print("Die!")
			GlobalEvents.player_death.emit()
	else:
		hit_pos = global_position + global_transform.x * max_distance

	# ───── show beam ─────
	beam.points  = [Vector2.ZERO, beam.to_local(hit_pos)]
	beam.visible = true

	## Short flash only – NOT the long cooldown
	await get_tree().create_timer(flash_time).timeout
	beam.visible = false
	ray.enabled  = false

	return true               ## tell controller it fired


func reset_cooldown() -> void:
	_ready_to_fire = true      ## controller calls this after reload_timer
