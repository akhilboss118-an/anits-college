extends SceneTree
## Synthesises the game's sound effects and ambience beds as 16-bit mono WAVs.
## The project ships no third-party SFX, so every sound here is generated from
## scratch: short envelopes, filtered noise and a few harmonic partials. Run:
##
##   godot --headless --path <project> --script res://tools/build_sfx.gd
##
## Output: assets/audio/sfx/*.wav and assets/audio/ambient/*.wav
## The files are deterministic (fixed RNG seed) and safe to regenerate.

const RATE := 22050
const SFX_DIR := "res://assets/audio/sfx"
const AMB_DIR := "res://assets/audio/ambient"
const SEED := 20261117


class Synth:
	var buf := PackedFloat32Array()
	var rng := RandomNumberGenerator.new()
	const RATE := 22050

	func _init(seconds: float, seed_value: int = 1) -> void:
		buf.resize(maxi(1, int(seconds * RATE)))
		rng.seed = seed_value

	## A decaying sine with an optional second harmonic.
	func tone(start_s: float, freq: float, dur: float, amp: float,
			decay: float = 2.0, harm: float = 0.0) -> void:
		var i0 := int(start_s * RATE)
		var n := int(dur * RATE)
		var phase := 0.0
		for i in n:
			var idx := i0 + i
			if idx < 0 or idx >= buf.size():
				continue
			var t := float(i) / RATE
			var env := pow(maxf(0.0, 1.0 - t / dur), decay)
			phase += TAU * freq / RATE
			buf[idx] += (sin(phase) + harm * sin(phase * 2.0)) * amp * env

	## A sine with a linear attack and release - used for whistles, hums and
	## bird chirps, where an instant attack would click.
	func tone_ar(start_s: float, freq: float, dur: float, amp: float,
			attack: float, release: float, vibrato: float = 0.0, harm: float = 0.0) -> void:
		var i0 := int(start_s * RATE)
		var n := int(dur * RATE)
		var phase := 0.0
		for i in n:
			var idx := i0 + i
			if idx < 0 or idx >= buf.size():
				continue
			var t := float(i) / RATE
			var env := 1.0
			if t < attack:
				env = t / maxf(attack, 0.0001)
			elif t > dur - release:
				env = maxf(0.0, (dur - t) / maxf(release, 0.0001))
			var f := freq + sin(TAU * 6.0 * t) * vibrato
			phase += TAU * f / RATE
			buf[idx] += (sin(phase) + harm * sin(phase * 2.0)) * amp * env

	## Filtered noise with a power-curve decay. `lp` is a one-pole low-pass
	## coefficient (1 = open, 0.05 = heavy) and `hp` an optional high-pass.
	func noise(start_s: float, dur: float, amp: float, decay: float = 2.0,
			lp: float = 0.35, hp: float = 0.0) -> void:
		var i0 := int(start_s * RATE)
		var n := int(dur * RATE)
		var y := 0.0
		var px := 0.0
		var py := 0.0
		for i in n:
			var idx := i0 + i
			if idx < 0 or idx >= buf.size():
				continue
			var t := float(i) / RATE
			var env := pow(maxf(0.0, 1.0 - t / dur), decay)
			var x := rng.randf_range(-1.0, 1.0)
			y += lp * (x - y)
			var s := y
			if hp > 0.0:
				var hy := hp * (py + s - px)
				px = s
				py = hy
				s = hy
			buf[idx] += s * amp * env

	## Shapes the whole buffer with an attack/release envelope.
	func shape(attack: float, release: float) -> void:
		var n := buf.size()
		var dur := float(n) / RATE
		for i in n:
			var t := float(i) / RATE
			var env := 1.0
			if t < attack:
				env = t / maxf(attack, 0.0001)
			elif t > dur - release:
				env = maxf(0.0, (dur - t) / maxf(release, 0.0001))
			buf[i] *= env

	## Blends the tail into the head and trims it, so the clip loops without a
	## click. Generate `fade_s` extra seconds for the crossfade.
	func loopify(fade_s: float) -> void:
		var fade := int(fade_s * RATE)
		var n := buf.size() - fade
		for i in fade:
			var t := float(i) / float(fade)
			buf[i] = buf[i] * t + buf[n + i] * (1.0 - t)
		buf.resize(n)

	func write(path: String) -> void:
		var n := buf.size()
		var data := PackedByteArray()
		data.resize(n * 2)
		for i in n:
			var v := int(round(clampf(buf[i], -1.0, 1.0) * 32767.0))
			data.encode_s16(i * 2, v)
		var header := PackedByteArray()
		header.resize(44)
		header.encode_u32(0, 0x46464952)   # RIFF
		header.encode_u32(4, 36 + data.size())
		header.encode_u32(8, 0x45564157)   # WAVE
		header.encode_u32(12, 0x20746D66)  # "fmt "
		header.encode_u32(16, 16)
		header.encode_u16(20, 1)           # PCM
		header.encode_u16(22, 1)           # mono
		header.encode_u32(24, RATE)
		header.encode_u32(28, RATE * 2)
		header.encode_u16(32, 2)
		header.encode_u16(34, 16)
		header.encode_u32(36, 0x61746164)  # data
		header.encode_u32(40, data.size())
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			push_error("build_sfx: cannot write " + path)
			return
		f.store_buffer(header)
		f.store_buffer(data)
		f.close()
		print("  %-28s %6d samples  %.2fs" % [path.get_file(), n, float(n) / RATE])


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(SFX_DIR)
	DirAccess.make_dir_recursive_absolute(AMB_DIR)
	print("=== ANITS SFX BUILD ===")
	_write_sfx()
	_write_ambience()
	print("=== SFX BUILD DONE ===")
	quit(0)


func _write_sfx() -> void:
	var s: Synth

	s = Synth.new(0.10, SEED + 1)
	s.tone(0.0, 1500.0, 0.055, 0.45, 3.0)
	s.noise(0.0, 0.012, 0.18, 4.0, 0.9)
	s.write(SFX_DIR + "/ui_click.wav")

	s = Synth.new(0.08, SEED + 2)
	s.tone(0.0, 1080.0, 0.045, 0.20, 3.0)
	s.write(SFX_DIR + "/ui_hover.wav")

	s = Synth.new(0.16, SEED + 3)
	s.tone(0.0, 760.0, 0.13, 0.30, 2.0, 0.2)
	s.tone(0.0, 480.0, 0.13, 0.18, 2.0)
	s.write(SFX_DIR + "/ui_back.wav")

	s = Synth.new(0.85, SEED + 4)
	var arp := [523.25, 659.25, 783.99, 1046.5]
	for i in arp.size():
		s.tone(float(i) * 0.085, float(arp[i]), 0.55, 0.26, 2.6, 0.12)
	s.write(SFX_DIR + "/success.wav")

	s = Synth.new(0.42, SEED + 5)
	s.tone(0.0, 196.0, 0.30, 0.30, 1.6, 0.6)
	s.tone(0.0, 185.0, 0.30, 0.22, 1.6, 0.6)
	s.write(SFX_DIR + "/error.wav")

	s = Synth.new(0.70, SEED + 6)
	var chime := [1046.5, 1568.0, 2093.0]
	for i in chime.size():
		s.tone(float(i) * 0.065, float(chime[i]), 0.50, 0.22, 3.0, 0.15)
	s.write(SFX_DIR + "/item.wav")

	for i in 4:
		var pitch: float = float([1.0, 0.94, 1.06, 0.97][i])
		s = Synth.new(0.16, SEED + 10 + i)
		s.noise(0.0, 0.075, 0.55, 3.2, 0.22)
		s.tone(0.0, 78.0 * pitch, 0.10, 0.35, 3.0)
		s.write(SFX_DIR + "/step_%d.wav" % (i + 1))

	s = Synth.new(0.22, SEED + 20)
	s.tone(0.0, 120.0, 0.16, 0.55, 2.6)
	s.tone(0.0, 78.0, 0.14, 0.35, 2.6)
	s.noise(0.0, 0.03, 0.20, 4.0, 0.8)
	s.write(SFX_DIR + "/ball_bounce.wav")

	s = Synth.new(0.80, SEED + 21)
	var partials := [620.0, 1240.0, 1870.0, 2510.0, 3100.0]
	var amps := [0.24, 0.16, 0.11, 0.07, 0.045]
	var durs := [0.62, 0.46, 0.34, 0.25, 0.18]
	for i in partials.size():
		s.tone(0.0, float(partials[i]) * 1.003, float(durs[i]), float(amps[i]), 2.4)
		s.tone(0.0, float(partials[i]) * 0.997, float(durs[i]), float(amps[i]) * 0.6, 2.4)
	s.write(SFX_DIR + "/rim.wav")

	s = Synth.new(0.32, SEED + 22)
	s.noise(0.0, 0.24, 0.40, 1.5, 0.85, 0.35)
	s.tone_ar(0.0, 320.0, 0.22, 0.10, 0.03, 0.12, 120.0)
	s.write(SFX_DIR + "/throw.wav")

	s = Synth.new(0.55, SEED + 23)
	s.tone_ar(0.0, 2350.0, 0.45, 0.16, 0.03, 0.16, 14.0)
	s.tone_ar(0.0, 2372.0, 0.45, 0.14, 0.03, 0.16, 14.0)
	s.write(SFX_DIR + "/whistle.wav")

	s = Synth.new(0.09, SEED + 24)
	s.tone(0.0, 1300.0, 0.05, 0.30, 4.0)
	s.write(SFX_DIR + "/tick.wav")

	s = Synth.new(0.35, SEED + 25)
	s.tone(0.0, 1568.0, 0.16, 0.26, 3.0)
	s.tone(0.075, 2093.0, 0.22, 0.24, 3.0)
	s.write(SFX_DIR + "/coin.wav")

	s = Synth.new(1.9, SEED + 26)
	s.noise(0.0, 1.6, 0.45, 0.7, 0.30, 0.10)
	s.noise(0.05, 1.5, 0.28, 0.9, 0.75, 0.20)
	for i in 7:
		s.tone_ar(s.rng.randf_range(0.06, 1.10), s.rng.randf_range(520.0, 920.0),
			0.24, 0.10, 0.03, 0.14)
	s.shape(0.28, 0.45)
	s.write(SFX_DIR + "/cheer.wav")

	s = Synth.new(1.05, SEED + 27)
	var fan := [523.25, 659.25, 783.99, 1046.5]
	for i in fan.size():
		s.tone(float(i) * 0.11, float(fan[i]), 0.75, 0.24, 2.4, 0.18)
	s.tone(0.33, 2093.0, 0.55, 0.10, 3.0)
	s.write(SFX_DIR + "/unlock.wav")

	s = Synth.new(0.06, SEED + 28)
	s.tone(0.0, 1850.0, 0.028, 0.22, 3.5)
	s.noise(0.0, 0.012, 0.10, 4.0, 0.9)
	s.write(SFX_DIR + "/type.wav")

	s = Synth.new(0.65, SEED + 29)
	s.noise(0.0, 0.55, 0.28, 1.2, 0.85, 0.45)
	for i in 9:
		s.tone(s.rng.randf_range(0.02, 0.50), s.rng.randf_range(900.0, 1900.0),
			0.035, 0.07, 3.0)
	s.write(SFX_DIR + "/fizz.wav")

	s = Synth.new(0.55, SEED + 30)
	s.tone(0.0, 320.0, 0.45, 0.22, 1.2, 0.15)
	s.tone(0.0, 160.0, 0.45, 0.18, 1.2)
	s.noise(0.0, 0.40, 0.10, 1.5, 0.18)
	s.write(SFX_DIR + "/tired.wav")


func _write_ambience() -> void:
	var s: Synth

	# Outdoor bed: slow wind, a distant hum and five bird calls.
	s = Synth.new(12.6, SEED + 40)
	var wind := 0.0
	for i in s.buf.size():
		var t := float(i) / Synth.RATE
		var env := 0.55 + 0.25 * sin(TAU * 0.08 * t) + 0.12 * sin(TAU * 0.21 * t + 1.3)
		var x := s.rng.randf_range(-1.0, 1.0)
		wind += 0.03 * (x - wind)
		s.buf[i] += wind * 0.55 * env
	s.tone_ar(0.0, 90.0, 12.6, 0.025, 0.6, 0.6)
	for start in [1.4, 3.9, 6.2, 8.6, 10.8]:
		_bird(s, float(start))
	s.loopify(0.6)
	s.write(AMB_DIR + "/ambient_campus.wav")

	# Indoor bed: mains hum plus air-conditioning wash.
	s = Synth.new(8.5, SEED + 41)
	s.tone_ar(0.0, 50.0, 8.5, 0.055, 0.4, 0.4)
	s.tone_ar(0.0, 100.0, 8.5, 0.030, 0.4, 0.4)
	var air := 0.0
	for i in s.buf.size():
		var t := float(i) / Synth.RATE
		var env := 0.8 + 0.2 * sin(TAU * 0.12 * t)
		var x := s.rng.randf_range(-1.0, 1.0)
		air += 0.02 * (x - air)
		s.buf[i] += air * 0.5 * env
	s.loopify(0.5)
	s.write(AMB_DIR + "/ambient_interior.wav")


## Two short descending chirps, mixed into the outdoor bed.
func _bird(s: Synth, start: float) -> void:
	for k in 2:
		var t0 := start + float(k) * 0.16
		var dur := 0.09
		var n := int(dur * Synth.RATE)
		var phase := 0.0
		for i in n:
			var idx := int(t0 * Synth.RATE) + i
			if idx < 0 or idx >= s.buf.size():
				continue
			var t := float(i) / Synth.RATE
			var f := 2600.0 + 900.0 * sin(PI * t / dur)
			phase += TAU * f / Synth.RATE
			var env := sin(PI * t / dur)
			s.buf[idx] += sin(phase) * 0.045 * env
