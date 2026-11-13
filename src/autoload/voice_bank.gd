extends Node
## The voice bank: the original web game's 632 recorded lines, played with the
## original per-character pitch/rate profiles, plus the Telugu subtitle text.
##
## js/voice.js plays clips.json / clips_girl.json by English line text and falls
## back to the browser speech synthesis. Here the MP3s are the real recordings;
## if a line has no clip we simply show the subtitle for the estimated time.
##
## This autoload is also the game's audio director (docs/GODOT_ARCHITECTURE.md
## §12): it owns the Master / Music / SFX / Voice / UI buses, the single
## dialogue player, the NCC "Jai Hind!" chorus pool, the volume + mute policy
## and the "stop every sound when the scene changes" rule.
##
## There is NO music in this game - the original ships no music track
## (docs/MISSING_INFORMATION.md §2.3). The Music bus exists for parity with the
## web build but is kept muted so that nothing can bleed a music bed in.
##
## See AUDIO_NOTES.md (next to this file) for the whole pipeline.

const AUDIO_DIR := "res://third_party/anits_original/audio/"
const CLIPS_FILE := AUDIO_DIR + "clips.json"
const CLIPS_GIRL_FILE := AUDIO_DIR + "clips_girl.json"

## the original per-character voice profiles (js/voice.js CFG): [pitch, rate]
const PROFILES := {
	"you": [1.28, 1.02], "youF": [1.14, 1.0], "sushma": [0.98, 1.02],
	"arjun": [1.12, 1.08], "guard": [0.72, 0.92], "clerk": [1.0, 0.95],
	"prof": [0.82, 0.9], "suresh": [1.05, 1.0], "colonel": [0.55, 0.85],
}

# --- audio buses (the web build's mixer layout) ----------------------------
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_VOICE := "Voice"
const BUS_UI := "UI"

# --- the NCC "Jai Hind!" chorus (js/voice.js chorus(), analysis doc §6.3) ---
const CHORUS_LINE := "Jai Hind!"
const CHORUS_RADIUS := 16.0        ## metres - the web build's 16 m
const CHORUS_MAX_VOICES := 6       ## mobile cap: at most six decoders at once
const CHORUS_DELAY := 0.85         ## s - the cadets answer after 850 ms
const CHORUS_DELAY_JITTER := 0.45 ## s - ... up to 1300 ms
const CHORUS_VOLUME := 0.6         ## the web build's 0.6 head-room factor
const CHORUS_DUCK := 0.35          ## chorus level while a dialogue is open
const CHORUS_GIRL_RATE := 0.96     ## girl with her own clip: 0.96 - 1.08
const CHORUS_GIRL_FALLBACK := 1.26 ## girl without one: 1.26 - 1.40 (pitched up)
const CHORUS_BOY_RATE := 0.88      ## boy: 0.88 - 1.08

# --- a line without a recording (the web build's no-TTS fallback) ---------
const SILENT_LINE_MIN := 1.2       ## s
const SILENT_LINE_PER_CHAR := 0.058 ## s per character
const SILENT_LINE_EXTRA := 0.6     ## s

const CHORUS_SCRIPT := preload("res://src/audio/chorus_player.gd")

signal clip_played(text: String, telugu: String)
signal clip_missing(text: String)
signal chorus_started(voices: int)

var clips: Dictionary = {}
var clips_girl: Dictionary = {}

## The web build applied its voice profiles to the speech-synthesis fallback
## only - the recordings themselves were played verbatim. This port plays the
## recordings with the profile pitch; set this to false for the web behaviour.
var apply_profile_pitch: bool = true

## The original has no music track. The Music bus stays muted until somebody
## deliberately switches it on.
var music_enabled: bool = false

var _loaded := false
var _player: AudioStreamPlayer
var _fallback_pitch := 1.0
var _chorus = null                       ## src/audio/chorus_player.gd
var _dialogue_open: bool = false          ## the chorus is ducked while true
var _clip_length: float = 0.0             ## length of the clip just played
var _clip_played: bool = false            ## did the last speak() sound anything
var _scene_id: int = 0                    ## the scene we are playing in
var _focus_paused: bool = false
var _cadet_ids: Dictionary = {}           ## npc_id -> stable chorus voice index


func _ready() -> void:
	_ensure_buses()
	_player = AudioStreamPlayer.new()
	_player.bus = BUS_VOICE
	add_child(_player)
	_chorus = CHORUS_SCRIPT.new()
	_chorus.name = "Chorus"
	add_child(_chorus)
	_chorus.setup(BUS_SFX, CHORUS_MAX_VOICES, CHORUS_DUCK)
	load_bank()
	apply_volume_settings()
	_scene_id = _current_scene_id()
	if Settings and not Settings.audio_settings_changed.is_connected(_on_audio_settings_changed):
		Settings.audio_settings_changed.connect(_on_audio_settings_changed)


## Creates the audio buses the web build has (Master / Music / SFX / Voice / UI).
func _ensure_buses() -> void:
	for bus_name in [BUS_MUSIC, BUS_SFX, BUS_VOICE, BUS_UI]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, BUS_MASTER)
	# No music track exists in the original - keep the Music bus silent.
	_set_bus_muted(BUS_MUSIC, not music_enabled)


func load_bank() -> void:
	if _loaded:
		return
	clips = _read_json(CLIPS_FILE)
	clips_girl = _read_json(CLIPS_GIRL_FILE)
	_loaded = true


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("VoiceBank: missing " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## [telugu, mp3 path] for a line, or {} when the line has no recording.
func lookup(text: String, female := false) -> Dictionary:
	load_bank()
	var bank: Dictionary = clips_girl if female else clips
	if bank.has(text):
		var entry: Variant = bank[text]
		if typeof(entry) == TYPE_ARRAY and (entry as Array).size() >= 2:
			return {"telugu": (entry as Array)[0], "mp3": (entry as Array)[1]}
		if typeof(entry) == TYPE_ARRAY and (entry as Array).size() == 1:
			return {"telugu": null, "mp3": (entry as Array)[0]}
		if typeof(entry) == TYPE_STRING:
			return {"telugu": null, "mp3": entry}
	return {}


## Plays the recording for a line (if there is one) and returns the Telugu text.
##
## A line without a usable recording is a SILENT line: nothing is played, the
## Telugu caption is still returned (the web build's __sub() falls back to the
## other bank's caption too) and the caller waits out the estimated duration.
func speak(text: String, female := false, pitch := 1.0) -> String:
	var entry := lookup(text, female)
	var telugu := _telugu_for(text, female)
	var mp3: Variant = entry.get("mp3", null)
	_clip_played = false
	_clip_length = 0.0
	if mp3 != null and str(mp3) != "":
		var file_name := str(mp3).get_file()
		var path := AUDIO_DIR + file_name
		if file_name != "" and ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream != null:
				if stream is AudioStreamMP3:
					(stream as AudioStreamMP3).loop = false
				var play_pitch := clampf(pitch, 0.5, 2.0) if apply_profile_pitch else 1.0
				_player.stream = stream
				_player.pitch_scale = play_pitch
				_player.volume_db = 0.0
				_player.play()
				_clip_played = true
				_clip_length = maxf(0.0, stream.get_length())
				clip_played.emit(text, telugu)
				return telugu
	# No recording for this line - a silent line, never an error.
	clip_missing.emit(text)
	return telugu


## The Telugu caption of a line.
##
## Exactly the web build's __sub(): the caption comes from the bank of the
## speaker, and when that bank does not know the line at all the other bank's
## caption is used instead. A bank entry without a caption stays untranslated.
func _telugu_for(text: String, female: bool) -> String:
	var entry := lookup(text, female)
	if not entry.is_empty():
		var value: Variant = entry.get("telugu", null)
		return str(value) if value != null else ""
	var other := lookup(text, not female)
	var fallback: Variant = other.get("telugu", null)
	return str(fallback) if fallback != null else ""


## The length in seconds of the clip played by the last speak() call (0 when
## the line was silent). The dialogue service uses it to wait for the
## recording, like the web build waits for the clip's onended.
func clip_duration() -> float:
	return _clip_length


## True when the last speak() call actually played a recording.
func has_played_clip() -> bool:
	return _clip_played


## True when a line has a playable recording.
func has_clip(text: String, female := false) -> bool:
	var file_name := _clip_file_name(text, female)
	if file_name == "":
		return false
	return ResourceLoader.exists(AUDIO_DIR + file_name)


## The profile for a speaker key (used by the dialogue service).
static func profile_for(key: String) -> Vector2:
	if PROFILES.has(key):
		var p: Array = PROFILES[key]
		return Vector2(float(p[0]), float(p[1]))
	return Vector2(1.0, 1.0)


## True when a female voice should be used for this speaker.
static func is_female(speaker_id: String, player_is_girl: bool) -> bool:
	if player_is_girl:
		return true
	return speaker_id == "clerk"


# --- the NCC "Jai Hind!" chorus -------------------------------------------

## Every cadet within `radius` metres of the player shouts the line in its own
## voice: a stable per-cadet playback rate, a volume that falls off with the
## distance and a small stagger after the player's salute.
##
## The chorus is independent of the dialogue - it never cuts a spoken line -
## but it is ducked while a dialogue is open.
##
## At most CHORUS_MAX_VOICES cadets are heard (the nearest ones), so a phone
## never runs more than six decoders at once.
## Returns the number of voices that were queued.
func play_chorus(listener_position: Vector3, radius: float = CHORUS_RADIUS) -> int:
	if not _chorus_valid():
		return 0
	load_bank()
	var girl_stream := _chorus_stream(true)
	var boy_stream := _chorus_stream(false)
	if girl_stream == null and boy_stream == null:
		return 0
	var voices: Array = []
	for node in _cadets():
		var distance := listener_position.distance_to(node.global_position)
		if distance > radius:
			continue
		var index := _cadet_index(node)
		var female := _cadet_is_female(node)
		var stream: AudioStream = girl_stream if female else boy_stream
		if female and girl_stream == null:
			stream = boy_stream
		if stream == null:
			continue
		voices.append({
			"stream": stream,
			"pitch": _chorus_rate(female, index, girl_stream != null),
			"volume": clampf(1.15 - distance / 20.0, 0.25, 1.0) * CHORUS_VOLUME,
			"delay": CHORUS_DELAY + randf() * CHORUS_DELAY_JITTER,
			"distance": distance,
		})
	# The nearest cadets are the loudest ones - keep those.
	voices.sort_custom(_sort_by_distance)
	if voices.size() > CHORUS_MAX_VOICES:
		voices = voices.slice(0, CHORUS_MAX_VOICES)
	if voices.is_empty():
		return 0
	_chorus.play(voices)
	chorus_started.emit(voices.size())
	return voices.size()


## The playback rate of one chorus voice (js/voice.js).
func _chorus_rate(female: bool, index: int, girl_clip: bool) -> float:
	if female:
		if girl_clip:
			return CHORUS_GIRL_RATE + float((index * 29) % 13) / 100.0
		return CHORUS_GIRL_FALLBACK + float((index * 31) % 15) / 100.0
	return CHORUS_BOY_RATE + float((index * 37) % 21) / 100.0


## The "Jai Hind!" recording of the girl / boy bank (null when it is missing).
func _chorus_stream(female: bool) -> AudioStream:
	return _chorus_stream_for(CHORUS_LINE, female)


## The recording of a line, loaded from disk (null when there is none).
func _chorus_stream_for(text: String, female: bool) -> AudioStream:
	var file_name := _clip_file_name(text, female)
	if file_name == "":
		return null
	var path := AUDIO_DIR + file_name
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


## The file name of a line's recording inside AUDIO_DIR ("" when the line has
## no recording at all).
func _clip_file_name(text: String, female: bool) -> String:
	load_bank()
	var bank: Dictionary = clips_girl if female else clips
	if not bank.has(text):
		return ""
	var entry: Variant = bank[text]
	if typeof(entry) == TYPE_ARRAY and (entry as Array).size() >= 2:
		return str((entry as Array)[1]).get_file()
	if typeof(entry) == TYPE_ARRAY and (entry as Array).size() == 1:
		return str((entry as Array)[0]).get_file()
	if typeof(entry) == TYPE_STRING:
		return str(entry).get_file()
	return ""


## The NCC cadets in the scene.
func _cadets() -> Array[Node3D]:
	var out: Array[Node3D] = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group("npcs"):
		if not node is Node3D:
			continue
		var npc := node as Node3D
		if _npc_string(npc, "group_name") != "cadet":
			continue
		out.append(npc)
	return out


## A stable per-cadet index, so every cadet always shouts in the same voice.
func _cadet_index(node: Node) -> int:
	var id := _npc_string(node, "npc_id")
	if _cadet_ids.has(id):
		return int(_cadet_ids[id])
	var index := _cadet_ids.size()
	_cadet_ids[id] = index
	return index


## True for the girl cadets - npc.gd::_model_id() makes every third cadet a
## girl (index % 3 == 1).
func _cadet_is_female(node: Node) -> bool:
	var id := _npc_string(node, "npc_id")
	if id.begins_with("cadet_"):
		return int(id.substr(6)) % 3 == 1
	return false


func _npc_string(node: Node, property: String) -> String:
	var value = node.get(property)
	return str(value) if value != null else ""


func _sort_by_distance(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0))


# --- transport -------------------------------------------------------------

## Stops the spoken line (the web build's __voice.stop()).
func stop() -> void:
	if _player:
		_player.stop()


## Stops every sound: the spoken line and the chorus.
func stop_all() -> void:
	if _player:
		_player.stop()
		_player.stream = null
	if _chorus_valid():
		_chorus.stop()


## Pauses every sound (the window lost focus / the app was backgrounded).
func pause_all() -> void:
	if _player:
		_player.stream_paused = true
	if _chorus_valid():
		_chorus.pause()


## Resumes the paused sounds.
func resume_all() -> void:
	if _player:
		_player.stream_paused = false
	if _chorus_valid():
		_chorus.resume()


## The dialogue service opens this while a line is on screen: the chorus is
## ducked so the dialogue stays in front.
func set_dialogue_open(open: bool) -> void:
	if _dialogue_open == open:
		return
	_dialogue_open = open
	if _chorus_valid():
		_chorus.set_ducked(open)


func is_dialogue_open() -> bool:
	return _dialogue_open


func _chorus_valid() -> bool:
	return _chorus != null and is_instance_valid(_chorus)


# --- volume / mute ---------------------------------------------------------

## Pushes the settings onto the buses: the voice volume on the Voice bus, the
## sfx volume on the SFX and UI buses and the mute on the Master bus.
func apply_volume_settings() -> void:
	var voice := 1.0
	var sfx := 1.0
	var muted := false
	if Settings:
		voice = clampf(Settings.voice_volume, 0.0, 1.0)
		sfx = clampf(Settings.sfx_volume, 0.0, 1.0)
		muted = Settings.muted
	_set_bus_volume(BUS_VOICE, voice)
	_set_bus_volume(BUS_SFX, sfx)
	_set_bus_volume(BUS_UI, sfx)
	_set_bus_muted(BUS_MASTER, muted)


## Mutes / unmutes everything. The setting is persisted by Settings.
func set_muted(value: bool) -> void:
	if Settings:
		Settings.set_muted(value)
	else:
		_set_bus_muted(BUS_MASTER, value)


func is_muted() -> bool:
	return bool(Settings.muted) if Settings else false


## The original ships no music track - this stays off unless the client asks
## for a background bed.
func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_set_bus_muted(BUS_MUSIC, not enabled)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


func _set_bus_muted(bus_name: String, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, muted)


func _on_audio_settings_changed() -> void:
	apply_volume_settings()


# --- engine plumbing -------------------------------------------------------

func _process(_delta: float) -> void:
	# "Stop every sound when the scene changes" - the campus is rebuilt
	# between the days and the autoload outlives every scene.
	var id := _current_scene_id()
	if id != _scene_id:
		_scene_id = id
		stop_all()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if not _focus_paused:
				_focus_paused = true
				pause_all()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			if _focus_paused:
				_focus_paused = false
				resume_all()
		NOTIFICATION_WM_CLOSE_REQUEST:
			stop_all()


func _exit_tree() -> void:
	if _player:
		_player.stop()


func _current_scene_id() -> int:
	if not is_inside_tree():
		return 0
	var scene := get_tree().current_scene
	return scene.get_instance_id() if scene != null else 0
