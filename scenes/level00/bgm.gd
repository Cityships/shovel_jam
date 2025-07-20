## BGMDirector.gd – Stem‑based background music (BGM) controller
##
## A lightweight audio director for handling synchronized BGM playback using stems.
## Drop this script on any `Node` (not an `AudioStreamPlayer`) to automatically
## manage music layering and dynamic stem mixing.
##
## Features:
## * Preloads backing, drums, melody, and alternate track stems.
## * Starts all stems in sync.
## * Supports soloing melody, cross-fading stems, or playing an alternate full track.
##
## Intended for adaptive soundtracks, letting designers fade elements in/out during gameplay.

extends Node
class_name BGMDirector

# ────────────────────────────────────────────────────────────────────────────
# ── ASSET PRELOADS ──
# Audio stem files for multi-track mixing. Replace with your own .ogg stems.
const ST_BACKING : AudioStream = preload("res://assets/ogg/BGM backing.ogg")
const ST_DRUMS   : AudioStream = preload("res://assets/ogg/BGM drums.ogg")
const ST_MELODY  : AudioStream = preload("res://assets/ogg/BGM melody.ogg")
const ST_ALT     : AudioStream = preload("res://assets/ogg/Freedom is a privelege.ogg")

# ────────────────────────────────────────────────────────────────────────────
# ── CONFIGURABLE PROPERTIES ──
@export var default_volume_db : float = -6.0   ## Initial volume (dB) per stem
@export var fade_time         : float = 1.0    ## Duration for cross-fades (in seconds)

# ────────────────────────────────────────────────────────────────────────────
# ── INTERNAL STATE ──
var _player_backing : AudioStreamPlayer
var _player_drums   : AudioStreamPlayer
var _player_melody  : AudioStreamPlayer

# ────────────────────────────────────────────────────────────────────────────
# ── INITIALIZATION ──
func _ready() -> void:
	## Create stream players for each stem and start them in sync.
	_player_backing = _add_player(ST_BACKING)
	_player_drums   = _add_player(ST_DRUMS)
	_player_melody  = _add_player(ST_MELODY)
	_set_stems_volume(-80)#
	_start_all()
	_fade_to(_player_backing, default_volume_db, 1)#
	GlobalEvents.gadget_obtained.connect(
		func(value):
			if value.name == "EmpObject":
				_fade_to(_player_drums, default_volume_db, 1)
	)

# ────────────────────────────────────────────────────────────────────────────
# ── PUBLIC API ──

## Resumes full stem playback at full volume.
func play_full_mix() -> void:
	_set_stems_volume(0.0)      ## Restore volumes to default (0 dB)
	_start_all()

## Solos the melody stem, muting drums and backing track with a fade.
func solo_melody() -> void:
	_fade_to(_player_backing, -80, fade_time)  ## Fade out (mute)
	_fade_to(_player_drums,   -80, fade_time)
	_fade_to(_player_melody,    0, fade_time)  ## Full volume

## Stops current BGM and fades in a new alternate track (non-layered).
func play_alternate_track() -> void:
	_fade_group_out([_player_backing, _player_drums, _player_melody], fade_time)

	var alt := _add_player(ST_ALT)
	alt.volume_db = -80        ## Start muted
	alt.play()
	_fade_to(alt, 0, fade_time)

# ────────────────────────────────────────────────────────────────────────────
# ── INTERNAL HELPERS ──

## Creates a new AudioStreamPlayer for the given stream and adds it to the node.
func _add_player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Music" 
	p.volume_db = default_volume_db
	p.autoplay = false
	add_child(p)
	return p

## Starts all stem players (assumes same timing/loop settings).
func _start_all() -> void:
	_player_backing.play()
	_player_drums.play()
	_player_melody.play()

## Sets all stems to a specified volume in dB (e.g., -6.0 for low, 0 for full).
func _set_stems_volume(db: float) -> void:
	for p in [_player_backing, _player_drums, _player_melody]:
		p.volume_db = db

## Fades out a group of players to silence over the given duration.
func _fade_group_out(players: Array, time: float) -> void:
	for p in players:
		_fade_to(p, -80, time)

## Fades the given AudioStreamPlayer to the target volume in dB over `time` seconds.
func _fade_to(player: AudioStreamPlayer, target_db: float, time: float) -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(player, "volume_db", target_db, time)\
		 .set_trans(Tween.TRANS_SINE)\
		 .set_ease(Tween.EASE_IN_OUT)
