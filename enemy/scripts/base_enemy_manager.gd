class_name BaseEnemyManager
extends Node2D
## BaseEnemyManager
## ──────────────────────────────────────────────────────────────────────────────
## Central observer / coordinator for all enemy mobs in the scene.
##   • Spawns the **BaseEnemyBody** prototype or any sub‑class that extends it.
##   • Listens to signals emitted by each enemy so that higher‑level game logic
##     (e.g. score tracking, dynamic music, difficulty scaling) can react from
##     a single place.
##   • Exposes a lightweight API so level‑specific scripts can request enemy
##     spawns without touching the internals of the enemy implementation.
##
## Recommended usage pattern:
##   1. Place an instance of **BaseEnemyManager** in the level scene.
##   2. Set **enemy_resource** in the Inspector to point at an
##      **EnemyResource** (Script‑ableObject style) that defines art and stats.
##   3. Call `spawn_enemy(global_position)` from anywhere in your code. The
##      manager will handle instantiation, parenting and bookkeeping.

# ───── CONSTANTS ───────────────────────────────────────────────────────────────
const BASE_ENEMY_BODY: PackedScene = preload("res://scenes/enemy/base/base_enemy_body.tscn")
const BODY_CONTAINER = preload("res://scenes/enemy/base/body_container.tscn")
# ───── EXPORTED PROPERTIES ─────────────────────────────────────────────────────
@export var enemy_resource: EnemyResource       ## Optional data‑asset containing enemy art / stats overrides.

# ───── RUNTIME STATE ───────────────────────────────────────────────────────────
var base_enemy_body: BaseEnemyBody              ## Points to the last‑spawned enemy (future‑ready for lists).

var body_container: Node2D

# ───── LIFECYCLE ───────────────────────────────────────────────────────────────
## Called once when the node enters the scene‑tree.
func _ready() -> void:
	## Spawn an initial enemy so the level always has at least one.
	base_enemy_body = _spawn_enemy()


# ───── PUBLIC API ──────────────────────────────────────────────────────────────
## Spawns an enemy at the given position and wires up signal forwarding.
## Returns the spawned instance for optional further configuration.
## Use is for respawning enemies. 
func spawn_enemy(at: Vector2) -> BaseEnemyBody:
	return _spawn_enemy()


# ───── INTERNAL HELPERS ────────────────────────────────────────────────────────
## Creates, parents and registers an enemy.
func _spawn_enemy() -> BaseEnemyBody:
	var enemy: BaseEnemyBody = BASE_ENEMY_BODY.instantiate()
	add_child(enemy)

	## --- Signal hookup -------------------------------------------------------
	## All per‑enemy signals can be re‑emitted here so that other systems need
	## to connect only once – to the manager – instead of to every enemy.
	enemy.state_changed.connect(_on_enemy_state_changed)
	enemy.emp_disabled .connect(_on_enemy_emp_disabled)

	return enemy


# ───── SIGNAL HANDLERS ─────────────────────────────────────────────────────────
func _on_enemy_state_changed(new_state: int) -> void:
	## Placeholder: React to state changes globally (e.g., play a sound when an
	## enemy enters ATTACK state).
	pass

func _on_enemy_emp_disabled(duration: float) -> void:
	## Placeholder: Trigger a UI effect or global slow‑motion when any enemy is
	## disabled by an EMP.
	pass
