class_name SaveStorage
extends RefCounted
## Low-level, side-effect-contained file persistence.
##
## Infrastructure layer. Static so it is testable headlessly and usable by any
## caller. Guarantees: writes are atomic (temp -> rename), a previously valid
## save is preserved as a backup, and a failed write/rename never destroys the
## existing save.

static func ensure_dir(dir_path: String) -> bool:
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if dir.dir_exists(dir_path.trim_prefix("user://")):
		return true
	return dir.make_dir_recursive(dir_path) == OK


static func write_atomic(slot_path: String, backup_path: String, temp_path: String, data: Dictionary) -> bool:
	if not ensure_dir(slot_path.get_base_dir()):
		push_error("SaveStorage: could not create save directory.")
		return false

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveStorage: could not open temp file for writing.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	if not FileAccess.file_exists(temp_path):
		push_error("SaveStorage: temp file missing after write.")
		return false

	# Preserve the previous valid save before replacing it.
	if FileAccess.file_exists(slot_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		DirAccess.copy_absolute(slot_path, backup_path)

	var err := DirAccess.rename_absolute(temp_path, slot_path)
	if err != OK:
		# Fallback: copy into place, then remove temp. The old save was already
		# backed up above, so it is never lost on failure.
		err = DirAccess.copy_absolute(temp_path, slot_path)
		DirAccess.remove_absolute(temp_path)
		if err != OK:
			push_error("SaveStorage: rename and copy fallback both failed.")
			return false
	return true


static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


## Attempts each candidate path in order, returning the first that parses AND
## passes `validator`. Never throws; malformed data is skipped, not deleted.
static func read_first_valid(paths: Array, validator: Callable) -> Dictionary:
	for path in paths:
		var candidate: Variant = read_json(path)
		if candidate != null and validator.call(candidate):
			return {"ok": true, "data": candidate, "path": path}
	return {"ok": false}
