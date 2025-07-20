class_name BaseEnemyBody
extends CharacterBody2D
## -----------------------------------------------------------------------------
## BaseEnemyBody (GDScript 4.x)
## -----------------------------------------------------------------------------
## A reusable *foundation* class that bundles the most common 2‑D enemy behaviour
## used throughout the project.  It is intended to be *sub‑classed* rather than
## placed directly in a level.
##
## ### Responsibilities
## * **Locomotion** – handles gravity, horizontal acceleration and automatic
##   turning when the enemy hits a wall or reaches the edge of a platform.
## * **Finite‑State Machine (FSM)** – manages six built‑in states:
##   `IDLE`, `MOVE`, `CHASE`, `WIND_UP`, `ATTACK`, `STUNNED`.
## * **Player Detection** – two RayCast2D sensors (front & back) are provided to
##   spot the player no matter which way the enemy is currently facing.
##
## ### Typical Extension Points
## * **Visuals** – swap or add child nodes (AnimatedSprite2D, Particles, etc.).
## * **Tuning** – adjust the exported variables (speed, gravity, delays …).
## * **Behaviour** – override `_process_state()` and/or add new FSM states.
##
## ### Public Signals
## * `state_changed(new_state:int)` – emitted every time the internal state
##   changes.  Use for SFX, UI, analytics …
## * `emp_disabled(duration:float)` – call from *external* code to temporarily
##   stun the enemy (e.g. an EMP grenade).
## * `flipped(dir:int)` – emitted after the sprite (and rays) are flipped.
##   `dir` is the new facing direction (`‑1 = left`, `1 = right`).
##
## ### Change‑log (key fixes)
## * **2025‑07‑17** – Centralised `_flip_rays()` ➜ updates *all* RayCast2Ds.
## * **2025‑07‑17** – Safeguard: `_move_dir` can no longer become `0`.
## * **2025‑07‑17** – NEW: When entering **MOVE** the enemy continues in the *last
##                      seen* direction of the player (smarter patrols).
## -----------------------------------------------------------------------------

#region Signals --------------------------------------------------------------
signal state_changed(new_state: int)   ## Fired whenever `_state` changes.
signal emp_disabled(duration: float)   ## External stun trigger (EMP, etc.).
signal flipped(dir: int)               ## Horizontal flip completed.
#endregion

# ───────── CONFIGURABLE STATS (exported) ────────────────────────────────────
@export var max_speed     : float   = 60.0   ## Maximum horizontal speed (px/s).
@export var accel         : float   = 500.0  ## Rate of horizontal acceleration.
@export var gravity       : float   = 900.0  ## Down‑ward acceleration (px/s²).
@export var turn_delay    : float   = 0.12   ## Seconds to wait *before* turning.
@export var target_offset : Vector2 = Vector2(15, 0) ## Perpendicular chase offset.
@export var attack_range  : float   = 24.0   ## Distance that triggers an attack.
@export var wind_up_delay : float   = 1.0    ## Delay spent in `WIND_UP` state.



# ───────── INTERNAL STATE (runtime only) ────────────────────────────────────
var _move_dir        : int    = 1   ## Current facing / movement dir (`‑1`/`1`).
var _turn_timer      : float  = 0.0  ## Counts up to `turn_delay` while turning.
var _target_position : Vector2 = Vector2.ZERO ## Cached player position.
var _windup_started  : bool   = false
var _last_player_dir : int    = 1   ## Last known horizontal dir to the player.

# ───────── STATE MACHINE DEFINITION ─────────────────────────────────────────
## Built‑in states exposed through the `State` enum.  When adding new states
## extend this enum *and* update `_process_state()` and `enter_state()`.
enum State { IDLE, MOVE, STUNNED, CHASE, ATTACK, WIND_UP }
@export var _state : State = State.IDLE   ## Initial state when the scene loads.

# ───────── CHILD NODE REFERENCES ────────────────────────────────────────────
@onready var front_vision : RayCast2D = %RayVision2 ## Detects player in front.
@onready var back_vision  : RayCast2D = $RayVision  ## Detects player behind.
@onready var ray_front    : RayCast2D = %RayFront   ## Wall sensor (forward).
@onready var ray_down     : RayCast2D = %RayDown    ## Ledge sensor (down‑front).
@onready var sprite       : AnimatedSprite2D = %VisualTreeRoot ## Main visuals.
@onready var debug        : Label = %Debug           ## On‑screen debug label.
@onready var wind_up : Timer = %WindUP       ## Timer node for wind‑up handling.
# ───────────────────────────── LIFECYCLE CALLBACKS ──────────────────────────
func _ready() -> void:
	## Connect signals that originate *outside* this script.
	emp_disabled.connect(try_emp_stun)

func _physics_process(delta: float) -> void:
	## Per‑physics‑frame update.  Order is important:
	##   1. Apply gravity so vertical motion is always up‑to‑date.
	##   2. Process the current FSM state (may alter `velocity`).
	##   3. Move the body via built‑in `move_and_slide()`.
	##   4. Update debug overlay (editor‑only convenience).
	_apply_gravity(delta)
	_process_state(delta)
	move_and_slide()
	_update_debug()

# ───────── STATE MACHINE RUNTIME LOGIC ──────────────────────────────────────
func _process_state(delta: float) -> void:
	## Execute behaviour for the *current* state and transition when criteria
	## are met.  Keeping logic split by state makes the code easy to extend.
	match _state:
		State.IDLE:
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta) ## Slow to a halt.
			if _should_chase():
				enter_state(State.CHASE)

		State.MOVE:
			_patrol_ground(delta)
			if _should_chase():
				enter_state(State.CHASE)

		State.STUNNED:
			velocity = Vector2.ZERO
			pass ## Movement is deliberately frozen.

		State.CHASE:
			_chase_player(delta)
			if !_should_chase():
				enter_state(State.MOVE)

		State.ATTACK:
			pass

		State.WIND_UP:
			velocity = Vector2.ZERO  ## Waiting to transition to ATTACK / MOVE.

# ───────── STATE ENTRY HANDLER ──────────────────────────────────────────────
func enter_state(new_state: int) -> void:
	## Centralised point where *all* state transitions go through.  Useful for
	## play‑once animations, SFX, resetting timers, etc.
	if _state == new_state:
		return  ## Ignore redundant transitions.

	state_changed.emit(new_state)
	_state = new_state
	_windup_started = false  ## Reset wind‑up guard flag.

	match new_state:
		State.IDLE:
			sprite.play("Idle")

		State.MOVE:
			## Keep moving in whichever direction the *player* was last seen.
			if _last_player_dir != 0 and _last_player_dir != _move_dir:
				_move_dir = _last_player_dir
				_flip_rays()
			sprite.play("Moving")

		State.STUNNED:
			sprite.play("Stunned")

		State.CHASE:
			sprite.play("Moving")

		State.ATTACK:
			sprite.play("Attack")

		State.WIND_UP:
			## Start the wind‑up coroutine *once*, not each physics frame.
			if not _windup_started:
				_windup_started = true
				sprite.play("WindUp")
				_wind_up_logic()

# ───────── EMP STUN LOGIC ───────────────────────────────────────────────────
func try_emp_stun(duration: float) -> void:
	## Temporarily forces the enemy into the `STUNNED` state for `duration`
	## seconds, then automatically resumes patrolling (`MOVE`).
	var tween := create_tween()
	tween.tween_callback(func(): _state = State.STUNNED)
	tween.chain().tween_interval(duration)
	tween.chain().tween_callback(func(): _state = State.MOVE)

# ───────── DEBUG OVERLAY ────────────────────────────────────────────────────
func _update_debug() -> void:
	## Shows the *current* FSM state as text in the editor/game view.  Because
	## enums map to 0‑based indices we can cheaply index into an array.
	debug.text = ["Idle", "Move", "Stunned", "Chase", "Attack", "WindUp"][_state]

# ───────── MOVEMENT HELPERS ─────────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	## Applies gravity only when the body is *not* on the floor.  Reset the
	## vertical velocity when grounded to avoid the tiny jiggle artefact that
	## can occur when combining acceleration and `move_and_slide()`.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

func _patrol_ground(delta: float) -> void:
	## Simple left/right patrol behaviour.
	## • If the front sensor hits a wall *or* the down‑front sensor detects no
	##   ground ahead, start a short `turn_delay` countdown, then flip.
	## • Otherwise accelerate toward the `_move_dir`.
	if _should_turn():
		_turn_timer += delta
		if _turn_timer >= turn_delay:
			_move_dir *= -1  ## Reverse direction.
			_turn_timer = 0.0
			_flip_rays()
			flipped.emit(_move_dir)
	else:
		_turn_timer = 0.0  ## Reset timer while path is clear.

	velocity.x = move_toward(velocity.x, _move_dir * max_speed, accel * delta)

func _flip_rays() -> void:
	## Mirrors the X component of *all* relevant RayCast2Ds & visuals so that
	## they always face the same horizontal direction as `_move_dir`.
	ray_front.target_position.x = abs(ray_front.target_position.x) * _move_dir
	ray_down.target_position.x  = abs(ray_down.target_position.x)  * _move_dir
	_update_vision_targets()          ## Keep vision rays in sync.
	ray_front.force_raycast_update()
	ray_down.force_raycast_update()
	sprite.flip_h = _move_dir < 0

func _should_turn() -> bool:
	## Returns **true** when the enemy should reverse direction:
	## • There is a wall directly in front (`ray_front` collides), *or*
	## • There is *no* ground ahead (`ray_down` sees nothing).
	return ray_front.is_colliding() or not ray_down.is_colliding()

# ───────── CHASE & COMBAT LOGIC ─────────────────────────────────────────────
func _should_chase() -> bool:
	## Evaluates both vision rays and caches the player's position, returning
	## **true** when the player was detected.  Also updates `_last_player_dir`
	## so the patrol state knows which way to move after losing sight.
	var vision_hit = null
	if back_vision.is_colliding():
		vision_hit = back_vision
	elif front_vision.is_colliding():
		vision_hit = front_vision

	if vision_hit:
		var body = vision_hit.get_collider()
		if body is Node2D:
			_target_position = body.global_position
		else:
			_target_position = vision_hit.get_collision_point()

		if body.is_in_group("Player"):
			_last_player_dir = sign(_target_position.x - global_position.x)
			if _last_player_dir == 0:
				_last_player_dir = _move_dir  ## Edge‑case: player directly above.
			return true
	return false

func _chase_player(delta: float) -> void:
	## Pursues the cached `_target_position` while maintaining a small sideways
	## offset so the enemy does not overlap the player perfectly.
	if _should_chase():
		var to_target := _target_position - global_position
		var distance   : float = clamp(to_target.length(), 0.0, 400.0)
		var dir        : Vector2 = to_target.normalized()

		## Calculate a perpendicular offset which scales with distance so that
		## the enemy flanks the player slightly instead of forming a straight
		## "queue".  The offset fades out when close to prepare for attack.
		var perpendicular : Vector2 = Vector2(-dir.y, dir.x)
		var dynamic_offset = perpendicular * target_offset.x * distance
		if distance < attack_range * 2.0:
			dynamic_offset *= distance / (attack_range * 2.0)

		var offset_target = _target_position + dynamic_offset
		var desired = (offset_target - global_position).normalized() * max_speed
		velocity = velocity.move_toward(desired, accel * delta)

		var new_dir = sign(to_target.x)
		if new_dir != 0 and new_dir != _move_dir:
			_move_dir = new_dir
			_last_player_dir = _move_dir
			_flip_rays()

		if global_position.distance_to(_target_position) < attack_range:
			enter_state(State.WIND_UP)
			_target_position = Vector2.ZERO
	else:
		velocity = velocity.move_toward(Vector2.ZERO, accel * delta) ## Stop.

# ───────── WIND‑UP / ATTACK FLOW ────────────────────────────────────────────
func _wind_up_logic() -> void:
	## Coroutine started on entering `WIND_UP`.  Waits for `wind_up_delay`, then
	## either transitions to `ATTACK` (if player is still in range) or resumes
	## patrolling.
	if _state != State.WIND_UP:
		return

	velocity = Vector2.ZERO  ## Freeze during wind‑up.
	await get_tree().create_timer(wind_up_delay).timeout

	if _state != State.WIND_UP:  ## State may have changed while waiting.
		return

	if _should_chase() and global_position.distance_to(_target_position) < attack_range:
		enter_state(State.ATTACK)
	else:
		enter_state(State.MOVE)

# ───────── VISION RAY HELPERS ───────────────────────────────────────────────
func _update_vision_targets() -> void:
	## Re‑aligns the *vision* rays so that one always faces front and the other
	## back, relative to `_move_dir`.  (Using `-dir` for the front ray keeps its
	## "sight" pointing ahead because the ray is defined from *tail → head*.)
	back_vision.target_position.x  = abs(back_vision.target_position.x)  * _move_dir
	front_vision.target_position.x = abs(front_vision.target_position.x) * -_move_dir


func set_resources(resource):
	sprite.set_sprite_frames(resource)
	pass
