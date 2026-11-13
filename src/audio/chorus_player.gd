extends Node
## A small pool of AudioStreamPlayers used for the NCC "Jai Hind!" chorus.
##
## The web build (js/voice.js `chorus()`) fires one `<audio>` element per cadet:
## every cadet shouts the line in his / her own voice - a stable per-cadet
## playback rate, a volume that falls off with the distance to the player - and
## they all start 850-1300 ms after the player.
##
## Godot has no "fire and forget" WebAudio element, so the chorus is a pool of
## plain AudioStreamPlayers:
##   * web / GL Compatibility safe - only AudioStreamPlayer + pitch_scale +
##     volume_db + AudioServer bus routing are used (no AudioStreamPlayer3D,
##     no audio effects, no AudioStreamGenerator),
##   * mobile friendly - the pool is small (six voices by default), so at most
##     six MP3 decoders ever run at the same time,
##   * independent of the dialogue - the chorus never cuts a spoken line.
##
## See src/autoload/AUDIO_NOTES.md for the full description.

const DEFAULT_POOL_SIZE := 6
const DEFAULT_DUCK_SCALE := 0.35   ## level while a dialogue line is open

var _bus: String = "SFX"
var _pool: Array[Dictionary] = []    ## [{player, busy, volume, age}]
var _pending: Array[Dictionary] = [] ## [{stream, pitch, volume, delay}]
var _ducked: bool = false
var _duck_scale: float = DEFAULT_DUCK_SCALE


## Creates the player pool.
## `bus` is the audio bus the chorus is routed to, `pool_size` the maximum
## number of voices that may sound at the same time and `duck_scale` the
## level the chorus drops to while a dialogue is open.
func setup(bus: String, pool_size: int = DEFAULT_POOL_SIZE,
		duck_scale: float = DEFAULT_DUCK_SCALE) -> void:
	_bus = bus
	_duck_scale = maxf(0.0, duck_scale)
	for entry in _pool:
		var old: AudioStreamPlayer = entry.get("player", null)
		if is_instance_valid(old):
			old.stop()
			old.queue_free()
	_pool.clear()
	_pending.clear()
	for i in maxi(1, pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = _bus
		player.volume_db = 0.0
		add_child(player)
		_pool.append({"player": player, "busy": false, "volume": 1.0, "age": 0.0})


## Queues the chorus voices. Every voice is a dictionary:
##   {stream: AudioStream, pitch: float, volume: float, delay: float}
## Voices that arrive after the pool is full are dropped (mobile cap).
func play(voices: Array) -> void:
	for v in voices:
		if typeof(v) != TYPE_DICTIONARY:
			continue
		var stream: AudioStream = v.get("stream", null)
		if stream == null:
			continue
		_pending.append({
			"stream": stream,
			"pitch": clampf(float(v.get("pitch", 1.0)), 0.5, 2.0),
			"volume": clampf(float(v.get("volume", 1.0)), 0.0, 1.0),
			"delay": maxf(0.0, float(v.get("delay", 0.0))),
		})


## Stops every voice and clears the queue.
func stop() -> void:
	_pending.clear()
	for entry in _pool:
		var p: AudioStreamPlayer = entry.get("player", null)
		if is_instance_valid(p):
			p.stop()
		entry["busy"] = false
		entry["age"] = 0.0


## Pauses the running voices (the window lost focus / the app went to the
## background).
func pause() -> void:
	for entry in _pool:
		var p: AudioStreamPlayer = entry.get("player", null)
		if is_instance_valid(p):
			p.stream_paused = true


## Resumes the paused voices.
func resume() -> void:
	for entry in _pool:
		var p: AudioStreamPlayer = entry.get("player", null)
		if is_instance_valid(p):
			p.stream_paused = false


## While ducked the chorus is quieter, so an open dialogue stays in front.
func set_ducked(ducked: bool) -> void:
	_ducked = ducked


func is_ducked() -> bool:
	return _ducked


## True while a voice is queued or sounding.
func is_playing() -> bool:
	return not _pending.is_empty() or voice_count() > 0


## The number of voices that are queued or sounding.
func voice_count() -> int:
	var n := _pending.size()
	for entry in _pool:
		if entry.get("busy", false):
			n += 1
	return n


func _process(delta: float) -> void:
	_start_due(delta)
	_update_playing(delta)


func _start_due(delta: float) -> void:
	for i in range(_pending.size() - 1, -1, -1):
		var voice: Dictionary = _pending[i]
		voice["delay"] = float(voice["delay"]) - delta
		if float(voice["delay"]) > 0.0:
			continue
		_pending.remove_at(i)
		_start(voice)


func _start(voice: Dictionary) -> void:
	var slot := _free_slot()
	if slot.is_empty():
		return   # the pool is full - this voice is dropped (mobile cap)
	var p: AudioStreamPlayer = slot["player"]
	slot["busy"] = true
	slot["age"] = 0.0
	slot["volume"] = float(voice["volume"])
	p.stream = voice["stream"]
	p.pitch_scale = float(voice["pitch"])
	p.volume_db = _to_db(float(voice["volume"]) * _duck_factor())
	p.play()


func _free_slot() -> Dictionary:
	for entry in _pool:
		if not entry.get("busy", false):
			return entry
	return {}


func _update_playing(delta: float) -> void:
	for entry in _pool:
		if not entry.get("busy", false):
			continue
		var p: AudioStreamPlayer = entry.get("player", null)
		if not is_instance_valid(p):
			entry["busy"] = false
			continue
		entry["age"] = float(entry["age"]) + delta
		if float(entry["age"]) > 0.05 and not p.playing:
			entry["busy"] = false
			entry["age"] = 0.0
			p.stop()
			continue
		p.volume_db = _to_db(float(entry["volume"]) * _duck_factor())


func _duck_factor() -> float:
	return _duck_scale if _ducked else 1.0


func _to_db(linear: float) -> float:
	return linear_to_db(maxf(linear, 0.0001))
