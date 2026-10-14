class_name Style3D
extends RefCounted
## Shared procedural 3D styling: materials, textures, meshes, and helpers used
## by `Actor3D` and `AreaWorld3D`.
##
## Everything is generated so the project needs no binary art to run (same
## philosophy as the 2D placeholders). Centralised here so the look stays
## consistent and is easy to art-direct in one place.

static var _shadow_texture: GradientTexture2D
static var _noise_cache: Dictionary = {}


# --- Materials -------------------------------------------------------------

static func matte(color: Color, roughness := 0.85) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	material.metallic_specular = 0.35
	return material


static func toy(color: Color) -> StandardMaterial3D:
	## Soft, slightly glossy plush look for creatures.
	var material := matte(color, 0.62)
	material.metallic_specular = 0.5
	material.rim_enabled = true
	material.rim = 0.4
	return material


static func glossy(color: Color, roughness := 0.3) -> StandardMaterial3D:
	var material := matte(color, roughness)
	material.metallic = 0.15
	material.metallic_specular = 0.7
	return material


static func emissive(color: Color, energy := 1.3) -> StandardMaterial3D:
	var material := matte(color, 0.4)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


static func unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


static func textured(color: Color, texture: Texture2D, uv_scale := 6.0, roughness := 0.92) -> StandardMaterial3D:
	var material := matte(color, roughness)
	material.albedo_texture = texture
	material.uv1_scale = Vector3(uv_scale, uv_scale, 1.0)
	return material


# --- Textures --------------------------------------------------------------

static func radial_alpha() -> GradientTexture2D:
	if _shadow_texture != null:
		return _shadow_texture
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 1.0))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_shadow_texture = texture
	return texture


static func noise_texture(seed_value: int, frequency := 0.03, roughness := 0.6) -> NoiseTexture2D:
	var key := "%d_%.3f" % [seed_value, frequency]
	if _noise_cache.has(key):
		return _noise_cache[key]
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_octaves = 4
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	_noise_cache[key] = texture
	return texture


# --- Meshes ----------------------------------------------------------------

static func sphere(radius: float, segments := 24, rings := 16) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	return mesh


static func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func cylinder(top: float, bottom: float, height: float, segments := 20) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	return mesh


static func cone(radius: float, height: float, segments := 20) -> CylinderMesh:
	return cylinder(0.0, radius, height, segments)


static func capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	mesh.radial_segments = 16
	return mesh


static func plane(size: Vector2, subdivide := 8) -> PlaneMesh:
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.subdivide_width = subdivide
	mesh.subdivide_depth = subdivide
	return mesh


# --- Instance helpers ------------------------------------------------------

static func instance(mesh: Mesh, material: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	return node


## A soft, radial blob shadow lying flat on the ground.
static func blob_shadow(radius: float, alpha := 0.32) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(radius * 2.4, radius * 2.4)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = radial_alpha()
	material.albedo_color = Color(0.02, 0.02, 0.04, alpha)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node := MeshInstance3D.new()
	node.mesh = quad
	node.material_override = material
	node.rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)
	node.position = Vector3(0.0, 0.04, 0.0)
	return node
