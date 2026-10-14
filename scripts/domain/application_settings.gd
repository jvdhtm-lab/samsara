class_name ApplicationSettings
extends RefCounted
## Player/application preferences. NEVER reset by a timeline restart.
##
## Domain layer (but non-narrative). Kept strictly separate from timeline
## state so accessibility and display choices survive every restart.

var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var reduce_motion: bool = false
var high_contrast_text: bool = false
var fullscreen: bool = false
var text_speed: float = 42.0
var use_3d_visuals: bool = true


func apply_to_audio_buses() -> void:
	if AudioServer.get_bus_index("Master") != -1:
		AudioServer.set_bus_volume_db(0, linear_to_db(clampf(master_volume, 0.0, 1.0)))


## Applies the display preference. Guarded so headless runs never touch it.
func apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func to_dict() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"reduce_motion": reduce_motion,
		"high_contrast_text": high_contrast_text,
		"fullscreen": fullscreen,
		"text_speed": text_speed,
		"use_3d_visuals": use_3d_visuals,
	}


static func from_dict(data: Dictionary) -> ApplicationSettings:
	var settings := ApplicationSettings.new()
	settings.master_volume = float(data.get("master_volume", 0.8))
	settings.music_volume = float(data.get("music_volume", 0.7))
	settings.sfx_volume = float(data.get("sfx_volume", 0.8))
	settings.reduce_motion = bool(data.get("reduce_motion", false))
	settings.high_contrast_text = bool(data.get("high_contrast_text", false))
	settings.fullscreen = bool(data.get("fullscreen", false))
	settings.text_speed = float(data.get("text_speed", 42.0))
	settings.use_3d_visuals = bool(data.get("use_3d_visuals", true))
	return settings
