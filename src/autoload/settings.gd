extends Node
## Audio / look / subtitle preferences. Persisted to user://settings.cfg.
## Mirrors the original's localStorage keys: anits-vol / anits-sfx / anits-look /
## anits-sublang (js/pause.js).

const CONFIG_PATH := "user://settings.cfg"

## Emitted whenever an audio setting changed, so the VoiceBank can push the
## new volumes onto the buses.
signal audio_settings_changed()

var voice_volume: float = 1.0
var sfx_volume: float = 1.0
var muted: bool = false
var look_sensitivity: float = 1.0
var subtitle_language: String = "en"   ## "en" | "te"


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	voice_volume = cfg.get_value("audio", "voice_volume", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx_volume", 1.0)
	muted = bool(cfg.get_value("audio", "muted", false))
	look_sensitivity = cfg.get_value("input", "look_sensitivity", 1.0)
	subtitle_language = cfg.get_value("subtitles", "language", "en")
	audio_settings_changed.emit()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "voice_volume", voice_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("input", "look_sensitivity", look_sensitivity)
	cfg.set_value("subtitles", "language", subtitle_language)
	cfg.save(CONFIG_PATH)


func set_voice_volume(value: float) -> void:
	voice_volume = clampf(value, 0.0, 1.0)
	save_settings()
	audio_settings_changed.emit()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	save_settings()
	audio_settings_changed.emit()


## Mutes everything (the Master bus).
func set_muted(value: bool) -> void:
	muted = value
	save_settings()
	audio_settings_changed.emit()


func is_muted() -> bool:
	return muted


func set_look_sensitivity(value: float) -> void:
	look_sensitivity = clampf(value, 0.1, 3.0)
	save_settings()


func set_subtitle_language(language: String) -> void:
	subtitle_language = "te" if language == "te" else "en"
	save_settings()


func is_telugu() -> bool:
	return subtitle_language == "te"


## True on Android/iOS, on a touchscreen laptop, or when the game is launched
## with `-- --touch-preview` for the mobile layout pass.
func is_touch_mode() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	return "--touch-preview" in OS.get_cmdline_user_args()
