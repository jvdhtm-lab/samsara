class_name TestCase
extends RefCounted
## Minimal assertion helper for headless test runs. No external framework.

var passed := 0
var failed := 0
var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		failures.append(message)
		printerr("FAIL: " + message)


func equal(actual: Variant, expected: Variant, message: String) -> void:
	var ok: bool = actual == expected
	if not ok and (actual is int or actual is float) and (expected is int or expected is float):
		ok = is_equal_approx(float(actual), float(expected))
	check(ok, "%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func is_true(value: bool, message: String) -> void:
	check(value, message)


func is_false(value: bool, message: String) -> void:
	check(not value, message)


func section(title: String) -> void:
	print("-- " + title)
