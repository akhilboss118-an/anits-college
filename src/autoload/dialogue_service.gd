extends Node
## Dialogue playback. One line at a time, auto-advancing - the same feel as the
## original (js/game.js showDlg/interact).
##
## The original plays a recorded MP3 per line (632 clips) and falls back to the
## browser speech synthesis. The Godot build plays the same recordings through
## the VoiceBank and always shows the subtitle.
##
## Timing: a line that has a recording is shown until the recording ends (the
## web build waits for the clip's onended); a line without one is shown for
## the estimated duration of the web build's no-speech-synthesis fallback.

signal line_shown(speaker: String, text: String, telugu: String)
signal dialogue_started(speaker: String)
signal dialogue_ended()

## A line without a recording is shown for this long - the web build's
## no-speech-synthesis fallback (js/voice.js: max(1200, len * 58 + 600) ms).
const SILENT_LINE_MIN := 1.2
const SILENT_LINE_PER_CHAR := 0.058
const SILENT_LINE_EXTRA := 0.6

var active: bool = false
var speaker: String = ""
var speaker_key: String = ""
var lines: Array = []
var index: int = 0
var _timer: float = 0.0
var _audio_open: bool = false   ## the chorus is ducked while a line is open


func start(new_speaker: String, new_lines: Array, key := "") -> void:
	if new_lines.is_empty():
		return
	speaker = new_speaker
	speaker_key = key
	lines = new_lines
	index = 0
	active = true
	_open_audio()
	dialogue_started.emit(speaker)
	_show()


func _show() -> void:
	if index >= lines.size():
		_finish()
		return
	var text := str(lines[index])
	# the original voice profiles (js/voice.js CFG)
	var profile := VoiceBank.profile_for(speaker_key) if VoiceBank else Vector2(1.0, 1.0)
	var female := VoiceBank.is_female(speaker_key, GameState.is_girl if GameState else false) if VoiceBank else false
	var telugu := ""
	var spoken := 0.0
	if VoiceBank:
		telugu = VoiceBank.speak(text, female, profile.x)
		spoken = VoiceBank.clip_duration()
	line_shown.emit(speaker, text, telugu)
	_timer = _line_duration(text, spoken)


## How long a line stays on screen.
func _line_duration(text: String, spoken: float) -> float:
	if spoken > 0.0:
		# a recording is playing - wait for it (js/voice.js waits for onended)
		return maxf(spoken + 0.15, float(text.length()) * 0.055)
	# no recording: the web build's no-speech-synthesis fallback
	return maxf(SILENT_LINE_MIN, float(text.length()) * SILENT_LINE_PER_CHAR + SILENT_LINE_EXTRA)


func _process(delta: float) -> void:
	if not active:
		# the dialogue was closed from the outside (the check tour force-ends
		# it): make sure the audio is released anyway.
		_close_audio()
		return
	_timer -= delta
	if _timer <= 0.0:
		index += 1
		if index >= lines.size():
			_finish()
		else:
			_show()


func _finish() -> void:
	active = false
	_close_audio()
	dialogue_ended.emit()


func skip() -> void:
	## E / click: jump to the next line immediately.
	if not active:
		return
	_timer = 0.0


## Opens the dialogue: the chorus is ducked while a line is on screen.
func _open_audio() -> void:
	if _audio_open:
		return
	_audio_open = true
	if VoiceBank:
		VoiceBank.set_dialogue_open(true)


## Closes the dialogue: the chorus comes back up and the last line stops
## (the web build's __voice.stop()).
func _close_audio() -> void:
	if not _audio_open:
		return
	_audio_open = false
	if VoiceBank:
		VoiceBank.set_dialogue_open(false)
		VoiceBank.stop()
