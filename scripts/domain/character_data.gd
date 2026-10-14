class_name CharacterData
extends Resource
## Immutable authored definition of a character's identity and appearance.
##
## Domain layer data definition. Shared and read-only during gameplay; any
## mutable per-timeline values live in TimelineState instead.

enum Silhouette { ROUND, PEAR, PLUSH }
enum Accessory { DROOP_EARS, LEAF_ANTENNA, BUTTON_STUDS, SIMPLE_ANTENNA }
enum Marking { NONE, STAR, LEAF, BUTTON }
enum EyeShape { ROUND, OVERSIZED, HALF }

@export var id: StringName = &""
@export var display_name: String = ""
@export var role: String = ""
@export var personality: String = ""
@export var dialogue_style: String = ""
@export var dialogue_id: StringName = &""

@export_group("Appearance")
@export var silhouette: Silhouette = Silhouette.ROUND
@export var accessory: Accessory = Accessory.DROOP_EARS
@export var marking: Marking = Marking.NONE
@export var eye_shape: EyeShape = EyeShape.ROUND
@export var body_color: Color = Color("#cbb7e6")
@export var shade_color: Color = Color("#9e86c4")
@export var face_color: Color = Color("#f3ecff")
@export var eye_color: Color = Color("#ffb84d")
@export var accent_color: Color = Color("#ffe9a8")
@export var body_radius: float = 16.0

@export_group("Animation")
@export var idle_motion: StringName = &"idle"   # idle | uncanny_idle
@export var uneven_smile: bool = false

@export_group("Palette (recognition)")
@export var palette_name: String = ""
@export var footprint: float = 10.0

@export_group("3D model (optional)")
## CC0 model id under `assets/models/` (e.g. "chars/Astronaut_FinnTheFrog").
## When set and present, the 3D actor uses it instead of the procedural body.
@export var model_id: String = ""
## Extra yaw (degrees) so the model faces the camera.
@export var model_yaw: float = 0.0
