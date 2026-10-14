class_name SaveSchema
extends RefCounted
## Versioned save schema definition and structural validation.
##
## Infrastructure layer. Pure/static so it can be unit tested without the
## scene tree or autoloads.

const CURRENT_VERSION := 2
const MIN_SUPPORTED_VERSION := 1
const REQUIRED_KEYS: Array[String] = ["version", "timeline", "meta", "settings"]


static func validate(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var dict: Dictionary = data
	for key in REQUIRED_KEYS:
		if not dict.has(key):
			return false
	if typeof(dict["timeline"]) != TYPE_DICTIONARY:
		return false
	if typeof(dict["meta"]) != TYPE_DICTIONARY:
		return false
	if typeof(dict["settings"]) != TYPE_DICTIONARY:
		return false
	var version := int(dict.get("version", -1))
	if version < MIN_SUPPORTED_VERSION or version > CURRENT_VERSION:
		return false
	return true
