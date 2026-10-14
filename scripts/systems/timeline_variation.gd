class_name TimelineVariation
extends RefCounted
## Deterministic per-timeline variation.
##
## Systems layer, pure/static and headless-testable. Given a timeline and
## meta-progression it derives a stable "theme" and related flags so each
## timeline looks and reads a little differently, while characters and the core
## arc stay recognizable. The seed comes from the timeline id (regenerated every
## restart) plus cross-timeline counters, so re-loading the same timeline yields
## the same variation.

const THEMES: Array[String] = ["clear", "dawn", "dusk", "storm", "gloom"]

const PALETTES := {
	"clear": {"sky": Color("#8fd0f2"), "ground": Color("#86c96f"), "accent": Color("#f2c14e"), "light": Color("#fff2cf")},
	"dawn": {"sky": Color("#ffc07a"), "ground": Color("#c9b45e"), "accent": Color("#ff9a4d"), "light": Color("#ffd9a0")},
	"dusk": {"sky": Color("#b06fd0"), "ground": Color("#78a878"), "accent": Color("#e07aa8"), "light": Color("#ffc0d8")},
	"storm": {"sky": Color("#7f9fb8"), "ground": Color("#6f9a78"), "accent": Color("#a8c6e0"), "light": Color("#dfeaff")},
	"gloom": {"sky": Color("#5a5470"), "ground": Color("#5f7060"), "accent": Color("#8f95b0"), "light": Color("#c4cede")},
}


static func rng_for(timeline: TimelineState, meta: MetaProgression) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var restarts := meta.restart_count if meta != null else 0
	var completions := meta.completed_timelines if meta != null else 0
	rng.seed = absi(hash(timeline.timeline_id)) + restarts * 1013904223 + completions * 1664525
	return rng


static func theme_index(timeline: TimelineState, meta: MetaProgression) -> int:
	return rng_for(timeline, meta).randi() % THEMES.size()


static func theme(timeline: TimelineState, meta: MetaProgression) -> String:
	return THEMES[theme_index(timeline, meta)]


static func palette(theme_name: String) -> Dictionary:
	return PALETTES.get(theme_name, PALETTES["clear"])


## A small hue rotation for procedural palettes (roughly -0.04..0.04).
static func hue_shift(timeline: TimelineState, meta: MetaProgression) -> float:
	var rng := rng_for(timeline, meta)
	rng.randi()
	rng.randi()
	return rng.randf_range(-0.04, 0.04)


## Picks one of `slots` deterministic variants (used to relocate secrets).
static func variant_index(timeline: TimelineState, meta: MetaProgression, slots: int) -> int:
	if slots <= 1:
		return 0
	var rng := rng_for(timeline, meta)
	rng.randi()
	rng.randi()
	rng.randi()
	return rng.randi() % slots


## Writes the variation flags onto the timeline. The application layer calls
## this whenever a timeline becomes active (new or loaded).
static func apply(timeline: TimelineState, meta: MetaProgression) -> String:
	var theme_name := theme(timeline, meta)
	timeline.set_flag(&"variation_theme", theme_name)
	for candidate in THEMES:
		timeline.set_flag(StringName("variant_%s" % candidate), candidate == theme_name)
	return theme_name
