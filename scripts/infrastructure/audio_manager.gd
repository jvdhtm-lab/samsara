extends Node
## Autoload: procedural sound feedback, music, and ambience.
##
## Infrastructure layer. Until real audio assets exist, sounds are synthesized:
## `play_tone` makes short sine blips (cached), while `play_music`/`play_ambience`
## generate seamless looping beds from small authored specs. Music respects
## `Game.settings.music_volume`; SFX respects `sfx_volume`. This is genuine
## synthesis, not a placeholder stub (ADR-022, ADR-028).

const MIX_RATE := 22050
const VOICES := 6
const MUSIC_DURATION := 6.0
const AMBIENCE_DURATION := 6.0

## Music beds: additive partials with a slow tremolo. `id -> spec`.
const MUSIC_TRACKS := {
	"menu": {"freqs": [220.0, 261.63, 329.63], "rate": 0.12, "gain": 0.42},
	"village": {"freqs": [196.0, 246.94, 293.66, 392.0], "rate": 0.18, "gain": 0.42},
	"workshop": {"freqs": [174.61, 220.0, 261.63], "rate": 0.30, "gain": 0.38},
	"hollow": {"freqs": [110.0, 130.81, 164.81], "rate": 0.08, "gain": 0.46},
	"picnic": {"freqs": [146.83, 196.0, 246.94], "rate": 0.15, "gain": 0.40},
	"ending": {"freqs": [261.63, 329.63, 392.0, 523.25], "rate": 0.10, "gain": 0.46},
}

## Ambience beds: a low drone plus gently filtered noise. `id -> spec`.
const AMBIENCE_TRACKS := {
	"village_wind": {"base": 90.0, "noise": 0.06, "rate": 0.07},
	"workshop_hum": {"base": 120.0, "noise": 0.04, "rate": 0.25},
	"hollow_drip": {"base": 60.0, "noise": 0.10, "rate": 0.05},
	"picnic_breeze": {"base": 100.0, "noise": 0.05, "rate": 0.09},
}

const MUSIC_BASE_DB := -9.0
const AMBIENCE_BASE_DB := -14.0

var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _cache: Dictionary = {}

var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _music_id := ""
var _ambience_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(VOICES):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -60.0
	add_child(_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.volume_db = -60.0
	add_child(_ambience_player)


## Releases playback resources on shutdown so looping beds do not leak at exit.
func _exit_tree() -> void:
	shutdown_audio()


func shutdown_audio() -> void:
	for player in _players:
		player.stop()
		player.stream = null
	if _music_player != null:
		_music_player.stop()
		_music_player.stream = null
	if _ambience_player != null:
		_ambience_player.stop()
		_ambience_player.stream = null
	_music_id = ""
	_ambience_id = ""
	_cache.clear()


# --- SFX -------------------------------------------------------------------

func play_tone(freq := 440.0, duration := 0.12, volume_db := -12.0) -> void:
	if _players.is_empty():
		return
	var key := "%.1f_%.3f" % [freq, duration]
	var stream: AudioStreamWAV
	if _cache.has(key):
		stream = _cache[key]
	else:
		stream = _make_tone(freq, duration)
		_cache[key] = stream

	var player := _players[_next_voice]
	_next_voice = (_next_voice + 1) % _players.size()

	player.stream = stream
	player.volume_db = volume_db + linear_to_db(clampf(_sfx_volume(), 0.0001, 1.0))
	player.play()


# --- Music / ambience ------------------------------------------------------

func has_music(track_id: StringName) -> bool:
	return MUSIC_TRACKS.has(String(track_id))


func has_ambience(track_id: StringName) -> bool:
	return AMBIENCE_TRACKS.has(String(track_id))


func current_music() -> StringName:
	return StringName(_music_id)


## Crossfades to a music bed. Repeating the current track is a no-op.
func play_music(track_id: StringName, fade := 0.9) -> void:
	var key := String(track_id)
	if key == _music_id or not MUSIC_TRACKS.has(key):
		return
	_music_id = key
	if _music_player == null:
		return
	_music_player.stream = _stream_for("music", key)
	if not _music_player.playing:
		_music_player.volume_db = -60.0
		_music_player.play()
	_fade_player(_music_player, _music_target_db(), fade)


func stop_music(fade := 0.6) -> void:
	_music_id = ""
	if _music_player != null and _music_player.playing:
		_fade_player(_music_player, -60.0, fade, true)


func play_ambience(track_id: StringName, fade := 1.2) -> void:
	var key := String(track_id)
	if key == _ambience_id or not AMBIENCE_TRACKS.has(key):
		return
	_ambience_id = key
	if _ambience_player == null:
		return
	_ambience_player.stream = _stream_for("ambience", key)
	if not _ambience_player.playing:
		_ambience_player.volume_db = -60.0
		_ambience_player.play()
	_fade_player(_ambience_player, _ambience_target_db(), fade)


func stop_ambience(fade := 0.8) -> void:
	_ambience_id = ""
	if _ambience_player != null and _ambience_player.playing:
		_fade_player(_ambience_player, -60.0, fade, true)


## Re-targets the current music volume after the settings change.
func refresh_music_volume() -> void:
	if _music_player != null and _music_player.playing:
		_music_player.volume_db = _music_target_db()


func _fade_player(player: AudioStreamPlayer, target_db: float, fade: float, stop_after := false) -> void:
	if fade <= 0.0:
		player.volume_db = target_db
		if stop_after:
			player.stop()
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, fade)
	if stop_after:
		tween.tween_callback(player.stop)


func _sfx_volume() -> float:
	var settings := _settings()
	return settings.sfx_volume if settings != null else 0.8


func _music_target_db() -> float:
	var settings := _settings()
	var volume := settings.music_volume if settings != null else 0.7
	return MUSIC_BASE_DB + linear_to_db(clampf(volume, 0.0001, 1.0))


func _ambience_target_db() -> float:
	var settings := _settings()
	var volume := settings.music_volume if settings != null else 0.7
	return AMBIENCE_BASE_DB + linear_to_db(clampf(volume, 0.0001, 1.0))


func _settings() -> ApplicationSettings:
	var game := get_node_or_null("/root/Game")
	return game.settings if game != null else null


func _stream_for(kind: String, key: String) -> AudioStreamWAV:
	var cache_key := "%s:%s" % [kind, key]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var stream: AudioStreamWAV
	if kind == "music":
		stream = _make_music(key, MUSIC_TRACKS[key])
	else:
		stream = _make_ambience(key, AMBIENCE_TRACKS[key])
	_cache[cache_key] = stream
	return stream


# --- Synthesis -------------------------------------------------------------

func _make_tone(freq: float, duration: float) -> AudioStreamWAV:
	var count := maxi(1, int(MIX_RATE * duration))
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var envelope := 1.0 - float(i) / float(count)
		var sample := sin(TAU * freq * t) * envelope * envelope * 0.6
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wav(data, count, false)


func _make_music(key: String, spec: Dictionary) -> AudioStreamWAV:
	var count := int(MIX_RATE * MUSIC_DURATION)
	var data := PackedByteArray()
	data.resize(count * 2)
	var freqs: Array = spec.get("freqs", [220.0])
	var rate := float(spec.get("rate", 0.2))
	var gain := float(spec.get("gain", 0.45))
	var rng := RandomNumberGenerator.new()
	rng.seed = key.hash()
	var detune: Array = []
	for _f in freqs:
		detune.append(rng.randf_range(-0.5, 0.5))
	var fade := maxi(1, int(MIX_RATE * 0.4))
	var partials := float(freqs.size())
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var sample := 0.0
		for k in range(freqs.size()):
			sample += sin(TAU * (float(freqs[k]) + float(detune[k])) * t)
		sample /= partials
		sample *= (0.75 + 0.25 * sin(TAU * rate * t)) * gain
		data.encode_s16(i * 2, int(clampf(sample * _fade_env(i, count, fade), -1.0, 1.0) * 32767.0))
	return _wav(data, count, true)


func _make_ambience(key: String, spec: Dictionary) -> AudioStreamWAV:
	var count := int(MIX_RATE * AMBIENCE_DURATION)
	var data := PackedByteArray()
	data.resize(count * 2)
	var base := float(spec.get("base", 90.0))
	var noise := float(spec.get("noise", 0.06))
	var rate := float(spec.get("rate", 0.1))
	var rng := RandomNumberGenerator.new()
	rng.seed = key.hash() + 7
	var fade := maxi(1, int(MIX_RATE * 0.5))
	var lowpass := 0.0
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		var drone := sin(TAU * base * t) * 0.5 + sin(TAU * base * 1.5 * t) * 0.2
		lowpass = lerpf(lowpass, rng.randf_range(-1.0, 1.0), 0.02)
		var sample := (drone + lowpass * noise * 4.0) * (0.6 + 0.4 * sin(TAU * rate * t)) * 0.4
		data.encode_s16(i * 2, int(clampf(sample * _fade_env(i, count, fade), -1.0, 1.0) * 32767.0))
	return _wav(data, count, true)


func _fade_env(i: int, count: int, fade: int) -> float:
	if i < fade:
		return float(i) / float(fade)
	if i > count - fade:
		return float(count - i) / float(fade)
	return 1.0


func _wav(data: PackedByteArray, count: int, looping: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.mix_rate = MIX_RATE
	wav.data = data
	if looping:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = count
	return wav
