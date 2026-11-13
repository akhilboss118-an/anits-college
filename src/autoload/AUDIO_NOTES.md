# Audio pipeline — ANITS Godot port

The port keeps the original's audio design: **recorded voice clips only, no music.**
The web build (`ANITS-WEB GAME/js/voice.js`) plays one of 632 recorded MP3s per
dialogue line, shows a Telugu caption under the English line, and shouts a
"Jai Hind!" chorus when the player salutes the NCC company. Nothing else is
audible — there is no background music track in the original
(`docs/MISSING_INFORMATION.md` §2.3).

---

## 1. File layout

| Path | What it is |
|---|---|
| `third_party/anits_original/audio/*.mp3` | the 632 original recordings (hashed file names) |
| `third_party/anits_original/audio/clips.json` | 340 lines → `[telugu, "assets/audio/xxx.mp3"]` |
| `third_party/anits_original/audio/clips_girl.json` | 310 lines → `[telugu, "assets/audio/xxx.mp3"]` |
| `src/autoload/voice_bank.gd` | **the audio director** — clip bank, buses, dialogue player, chorus, volume/mute, transport |
| `src/autoload/dialogue_service.gd` | one line at a time, auto-advance, subtitle, line timing, chorus ducking |
| `src/autoload/mission_runner.gd` | caches the player position and fires the NCC chorus on the salute |
| `src/autoload/settings.gd` | voice volume / sfx volume / mute (persisted in `user://settings.cfg`) |
| `src/audio/chorus_player.gd` | the small pool of `AudioStreamPlayer`s the chorus uses |

Autoload names (unchanged): `EventBus`, `GameState`, `Settings`, `SaveSystem`,
`CampusDB`, `Mission`, `Dialogue`, `VoiceBank`.

---

## 2. How a line is chosen and spoken

```
player presses E near an NPC
  └─ main.gd → Dialogue.start(display_name, lines, npc_id)
       └─ dialogue_service._show()
            ├─ profile  = VoiceBank.profile_for(speaker_key)     # [pitch, rate]
            ├─ female   = VoiceBank.is_female(speaker_key, GameState.is_girl)
            ├─ telugu   = VoiceBank.speak(text, female, profile.x)
            │    └─ voice_bank.speak()
            │         ├─ lookup(text, female)  → clips.json or clips_girl.json
            │         ├─ loads res://third_party/anits_original/audio/<file>.mp3
            │         └─ plays it on the "Voice" bus
            ├─ line_shown.emit(speaker, text, telugu)   → HUD
            └─ the line stays up until the recording ends
```

* **Which bank?** `clips_girl.json` when the player is a girl or the speaker is
  the clerk (Mrs. Lakshmi), otherwise `clips.json`. Same rule as the web
  build's `fem` flag in `js/voice.js`.
* **Pitch.** The recording is played with the speaker's profile pitch
  (`PROFILES` — the original's `CFG` table). The web build applied those
  profiles to its speech-synthesis *fallback* only and played the recordings
  verbatim; set `VoiceBank.apply_profile_pitch = false` for the web behaviour.
  The profile *rate* is not applied (the web build did not apply it to the
  recordings either).
* **One line at a time.** A new line restarts the single `AudioStreamPlayer`,
  which cuts the previous clip — exactly like the web build's `__voice.stop()`
  inside `speak()`.
* **Line timing.** A line with a recording stays on screen until the clip has
  finished (`clip length + 0.15 s`, never shorter than the old text estimate).
  The web build waits for the clip's `onended`, so this removes the old
  "clip is cut off mid-sentence" behaviour.

## 3. How the Telugu subtitle is produced

The caption comes from the clip bank entry, exactly like the web build's
`__sub()`:

1. the bank of the speaker wins — its `[0]` element is the Telugu text;
2. if that bank does not know the line at all, the **other** bank's caption is
   used;
3. a bank entry whose Telugu field is `null` stays untranslated (the English
   line is shown) — the port does **not** borrow the other bank's caption here,
   matching the web build.

The HUD picks English or Telugu from `Settings.subtitle_language`
(`src/main.gd::_on_line`).

## 4. The NCC "Jai Hind!" chorus

The web build fires one `<audio>` element per cadet (`js/voice.js chorus()`).
The port reproduces it in `VoiceBank.play_chorus()`:

| Rule | Value | Source |
|---|---|---|
| who shouts | every cadet within **16 m** of the player | `js/game.js salute()` |
| playback rate (boy) | `0.88 + (k * 37) % 21 / 100` → 0.88–1.08 | `js/voice.js` |
| playback rate (girl, own clip) | `0.96 + (k * 29) % 13 / 100` → 0.96–1.08 | `js/voice.js` |
| playback rate (girl, no girl clip) | `1.26 + (k * 31) % 15 / 100` → 1.26–1.40 | `js/voice.js` |
| volume | `clamp(1.15 − d / 20, 0.25, 1) × 0.6` | `js/voice.js` |
| start delay | 850 ms + random × 450 ms after the player | `js/voice.js` |
| `k` | a stable per-cadet index, so a cadet always shouts in the same voice | `n.vi` in `js/voice.js` |

* The girl's own recording is `clips_girl.json["Jai Hind!"]`; the boy's is
  `clips.json["Jai Hind!"]`. A girl without a girl clip shouts the boy's
  recording pitched up, like the web build.
* Godot's `pitch_scale` changes speed **and** pitch together, which is exactly
  what the web build did (`preservesPitch = false` + `playbackRate`).
* Girl cadets are the ones `npc.gd::_model_id()` makes female
  (`cadet_XX` with `XX % 3 == 1`).
* The chorus is **independent of the dialogue** — it never cuts a spoken line,
  like the web build.

### How it is triggered

`src/main.gd::_salute()` calls `Mission.notify_salute()`; the mission runner
then calls `VoiceBank.play_chorus(player_position)`. The player position is
the one `main.gd::_process()` passes to `Mission.notify_position()` every
frame.

> **Integration point.** The salute animation in `main.gd` also plays when the
> player is merely *near* the parade ground, while `Mission.notify_salute()`
> only fires during a "salute" mission step. To let the chorus answer *every*
> salute press, add one line to `main.gd::_salute()`:
> `VoiceBank.play_chorus(player.global_position)`.
> `main.gd` is outside this task's ownership, so it was left untouched.

---

## 5. Buses

| Bus | Content | Volume source |
|---|---|---|
| `Master` | everything | mute only |
| `Voice` | the dialogue recordings | `Settings.voice_volume` |
| `SFX` | the NCC chorus | `Settings.sfx_volume` |
| `UI` | menu sounds (none yet) | `Settings.sfx_volume` |
| `Music` | **empty — and muted** | – |

The buses are created at runtime by `VoiceBank._ensure_buses()` (the same
approach as before, so no `default_bus_layout.tres` is needed).
`VoiceBank.set_music_enabled(true)` un-mutes the Music bus; it is off by
default because the original has no music track.

### Volume and mute

* `Settings.voice_volume` / `Settings.sfx_volume` / `Settings.muted` are
  persisted in `user://settings.cfg` (keys `audio/voice_volume`,
  `audio/sfx_volume`, `audio/muted`).
* `Settings.audio_settings_changed` is emitted on every change;
  `VoiceBank` listens to it and pushes the values onto the buses, so a volume
  change is heard immediately — even on a line that is already playing.
* `VoiceBank.set_muted(bool)` / `VoiceBank.is_muted()` are the audio-side
  wrappers.

---

## 6. Fallback rules

| Situation | What happens |
|---|---|
| the line has no entry in the bank | **silent line** — no sound, no error; the English line is shown |
| the entry has no MP3 path (`""`) | **silent line** — no sound, no error |
| the MP3 file is missing on disk | **silent line** — no sound, no error, `clip_missing` is emitted |
| the line is silent | it stays on screen for `max(1.2 s, len × 0.058 s + 0.6 s)` — the web build's no-speech-synthesis fallback (`max(1200, len × 58 + 600) ms`) |
| the clip cannot be decoded | silent line (`load()` returns null → no playback) |
| the "Jai Hind!" clip is missing | the chorus plays nothing and returns 0 |
| the dialogue is closed from the outside (the `--check` tour force-ends it) | the dialogue service releases the audio on the next frame, so the chorus is un-ducked and the line stops |

A silent line is **never** an error: the game keeps running and the subtitle
still appears. (Godot has no speech synthesis, so the web build's TTS
fallback is replaced by "show the caption for the estimated time".)

---

## 7. Transport rules

* **Scene change** — `VoiceBank._process()` watches `get_tree().current_scene`;
  when it changes, `stop_all()` drops every sound. The autoload outlives the
  scenes, so nothing can leak across a level change.
* **New day** — `Mission.start_day()` calls `VoiceBank.stop_all()` (the campus
  is rebuilt for the new day).
* **Focus loss** — `NOTIFICATION_APPLICATION_FOCUS_OUT` pauses the voice and
  the chorus, `NOTIFICATION_APPLICATION_FOCUS_IN` resumes them. This mirrors
  the web build's `pagehide` / `visibilitychange` handling and is what a phone
  needs when the app is backgrounded.
* **Window close** — `NOTIFICATION_WM_CLOSE_REQUEST` and `_exit_tree()` stop
  everything.

---

## 8. Tuning knobs

All of them are constants at the top of `src/autoload/voice_bank.gd` (or of
`src/audio/chorus_player.gd`):

| Constant | Default | Meaning |
|---|---|---|
| `CHORUS_RADIUS` | `16.0` | how close a cadet must be to shout (metres) |
| `CHORUS_MAX_VOICES` | `6` | maximum simultaneous chorus voices (mobile cap) |
| `CHORUS_DELAY` / `CHORUS_DELAY_JITTER` | `0.85` / `0.45` | the cadets answer 0.85–1.30 s after the player |
| `CHORUS_VOLUME` | `0.6` | the web build's head-room factor |
| `CHORUS_DUCK` | `0.35` | chorus level while a dialogue is open |
| `CHORUS_GIRL_RATE` / `CHORUS_GIRL_FALLBACK` / `CHORUS_BOY_RATE` | `0.96` / `1.26` / `0.88` | the base playback rates |
| `SILENT_LINE_MIN` / `_PER_CHAR` / `_EXTRA` | `1.2` / `0.058` / `0.6` | the duration of a line without a recording |
| `apply_profile_pitch` (property) | `true` | play the recordings with the speaker's profile pitch |
| `music_enabled` (property) | `false` | the Music bus stays muted |
| `DEFAULT_POOL_SIZE` (chorus player) | `6` | the size of the chorus player pool |
| `DEFAULT_DUCK_SCALE` (chorus player) | `0.35` | the ducking factor used when the pool is set up |

---

## 9. Web / GL Compatibility and mobile notes

* Only `AudioStreamPlayer` is used — no `AudioStreamPlayer3D`, no
  `AudioStreamGenerator`, no `AudioEffect` instances, no `AudioListener`.
  Everything in this pipeline works in the **Compatibility** renderer and in
  the web export.
* The distance falloff of the chorus is computed in script (a plain volume
  multiplier) instead of with a 3D emitter: no spatial audio on the web, and
  the cost stays the same on a phone.
* **At most six MP3 decoders run at the same time** (the chorus pool). The
  dialogue uses exactly one more.
* The recordings are loaded on demand (`load()` on the clip path) and are
  cached by Godot's `ResourceCache`, so a line is decoded once.
* The MP3s are imported with `loop = false`; the port also enforces it when a
  stream is used.

---

## 10. Preserved API (nothing was renamed or removed)

### `VoiceBank` (autoload)

| Member | Status |
|---|---|
| `AUDIO_DIR`, `CLIPS_FILE`, `CLIPS_GIRL_FILE`, `PROFILES` | unchanged |
| `clips`, `clips_girl` | unchanged |
| `load_bank()`, `lookup(text, female = false)` | unchanged |
| `speak(text, female = false, pitch = 1.0) -> String` | signature unchanged — **the return value now also carries the Telugu caption of a line whose recording is missing** (the web build shows the caption in that case too) |
| `profile_for(key) -> Vector2` (static) | unchanged |
| `is_female(speaker_id, player_is_girl) -> bool` (static) | unchanged |

New members: `clip_played` / `clip_missing` / `chorus_started` signals,
`clip_duration()`, `has_played_clip()`, `has_clip()`, `play_chorus()`,
`stop()`, `stop_all()`, `pause_all()`, `resume_all()`, `set_dialogue_open()`,
`is_dialogue_open()`, `apply_volume_settings()`, `set_muted()`, `is_muted()`,
`set_music_enabled()`, and the `apply_profile_pitch` / `music_enabled`
properties.

### `Dialogue` (autoload)

`line_shown`, `dialogue_started`, `dialogue_ended` (signals), `active`,
`speaker`, `speaker_key`, `lines`, `index` (properties), `start()`,
`skip()` — **all unchanged**.

### `Mission` (autoload)

`step_changed`, `completed` (signals), `day`, `steps`, `index`, `finished`,
`active` (properties), `start_day()`, `current()`, `advance()`,
`notify_talked_to()`, `notify_position()`, `notify_salute()` — **all
unchanged** (`notify_position()` now also caches the player position).

### `Settings` (autoload)

`voice_volume`, `sfx_volume`, `look_sensitivity`, `subtitle_language`,
`load_settings()`, `save_settings()`, `set_voice_volume()`,
`set_sfx_volume()`, `set_look_sensitivity()`, `set_subtitle_language()`,
`is_telugu()`, `is_touch_mode()` — **all unchanged**. New: `muted`,
`set_muted()`, `is_muted()`, `audio_settings_changed`.
