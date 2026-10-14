extends Node
## Autoload: orchestrates save/load between application state and storage.
##
## Infrastructure layer. Owns file locations and the save transaction. It never
## mutates game rules directly; it reads/writes Game's state models.
##
## Paths are injectable so tests (and future multiple save slots) can operate
## without touching the player's real save.

const SAVE_DIR := "user://saves"
const SLOT_PATH := "user://saves/timeline.json"
const BACKUP_PATH := "user://saves/timeline.backup.json"
const TEMP_PATH := "user://saves/timeline.tmp.json"
const ARCHIVE_PATH := "user://saves/timeline.archived.json"

## Application settings live in their own file, independent of a timeline save,
## so preferences persist even with no active game (ADR-028).
const SETTINGS_PATH := "user://settings.json"
const SETTINGS_BACKUP := "user://settings.backup.json"
const SETTINGS_TEMP := "user://settings.tmp.json"


func has_save(slot := SLOT_PATH, backup := BACKUP_PATH) -> bool:
	return FileAccess.file_exists(slot) or FileAccess.file_exists(backup)


func save_game(slot := SLOT_PATH, backup := BACKUP_PATH, temp := TEMP_PATH) -> bool:
	if Game == null or Game.timeline == null:
		push_warning("SaveManager: no active session to save.")
		EventBus.save_completed.emit(false, slot)
		return false

	var data := {
		"version": SaveSchema.CURRENT_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"timeline": Game.timeline.to_dict(),
		"meta": Game.meta.to_dict(),
		"settings": Game.settings.to_dict(),
	}

	var ok := SaveStorage.write_atomic(slot, backup, temp, data)
	EventBus.save_completed.emit(ok, slot)
	return ok


func load_game(slot := SLOT_PATH, backup := BACKUP_PATH) -> bool:
	var result := SaveStorage.read_first_valid([slot, backup], _is_valid_save)
	if not result.get("ok", false):
		push_warning("SaveManager: no valid save file found.")
		EventBus.load_completed.emit(false)
		return false

	var data: Dictionary = MigrationManager.migrate(result["data"])
	Game.apply_loaded_state(data)
	EventBus.load_completed.emit(true)
	return true


## Removes the slot, its backup, and any temp file. Used by tests and by an
## explicit "delete save" action; never called during a normal restart.
func clear_slot(slot := SLOT_PATH, backup := BACKUP_PATH, temp := TEMP_PATH) -> void:
	for path in [slot, backup, temp]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


## Copies the current timeline aside before a restart so the fiction's "lost
## universe" remains recoverable in the real application. Prefers the live slot,
## falling back to the backup. Never deletes the only valid save.
func archive_current(slot := SLOT_PATH, archive := ARCHIVE_PATH, backup := BACKUP_PATH) -> bool:
	var source := slot
	if not FileAccess.file_exists(source):
		source = backup
	if not FileAccess.file_exists(source):
		return false
	if not SaveStorage.ensure_dir(archive.get_base_dir()):
		return false
	if FileAccess.file_exists(archive):
		DirAccess.remove_absolute(archive)
	return DirAccess.copy_absolute(source, archive) == OK


func _is_valid_save(data: Variant) -> bool:
	return SaveSchema.validate(data)


## Persists application settings only (volume, accessibility, display). Kept
## separate from the timeline slot so preferences never depend on a save.
func save_settings(path := SETTINGS_PATH, backup := SETTINGS_BACKUP, temp := SETTINGS_TEMP) -> bool:
	if Game == null or Game.settings == null:
		return false
	var data := {
		"version": SaveSchema.CURRENT_VERSION,
		"settings": Game.settings.to_dict(),
	}
	return SaveStorage.write_atomic(path, backup, temp, data)


func load_settings(path := SETTINGS_PATH, backup := SETTINGS_BACKUP) -> bool:
	var result := SaveStorage.read_first_valid([path, backup], _is_valid_settings)
	if not result.get("ok", false):
		return false
	Game.settings = ApplicationSettings.from_dict(result["data"].get("settings", {}))
	Game.settings.apply_to_audio_buses()
	return true


func has_settings(path := SETTINGS_PATH, backup := SETTINGS_BACKUP) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(backup)


func _is_valid_settings(data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and typeof(data.get("settings")) == TYPE_DICTIONARY
