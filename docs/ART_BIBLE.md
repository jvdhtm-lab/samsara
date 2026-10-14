# Samsara — Art Bible

The binding visual direction for the first playable world. Character identity
takes priority over asset quantity (`AGENTS.md` §8).

## Art direction

Whimsical, soft, and slightly uncanny. The world reads as a handcrafted
pastel diorama: rounded shapes, oversized plants, crooked architecture, and
warm light. The cast are **robot-creatures** — plush, toy-like machines with
visors, rivets, and antennae rather than organic animals.

- Readable at a glance: silhouette first, palette second, detail last.
- Gentle outlines via a darker "shade" tone rather than black linework.
- No photoreal texture; flat fills with a single shade tone per shape.

## Technical scale

| Setting | Value |
|---------|-------|
| Viewport | 640 x 360 |
| Window (default) | 1280 x 720 (2x) |
| Stretch mode | `canvas_items`, keep aspect |
| Design tile size | 16 px |
| Character body diameter | 28–36 px (`body_radius` 14–17) |
| Renderer | GL Compatibility |

Characters occupy roughly 1/10 of the screen height, so identity must survive
at ~32 px. Recognition cues are therefore silhouette and marking, not fine
detail.

## Shape language

- **Silhouette classes** (from `CharacterData.silhouette`):
  - `ROUND` — even sphere (Lumi, player).
  - `PEAR` — wide top, narrow base (Pip).
  - `PLUSH` — wide, low, soft (Momo).
- **Outline:** each shape is drawn a second time in `shade_color`, expanded by
  ~2 px, before the fill.
- **Rivets:** small shade dots with a highlight, reinforcing "machine".
- **Limbs:** short nub ellipses; never long or articulated at this scale.

## Palettes

| Character | Body | Shade | Face | Eye | Accent | Hue band |
|-----------|------|-------|------|-----|--------|----------|
| Lumi | lavender `#cbb7e6` | `#9e86c4` | `#f3ecff` | amber `#ffb84d` | `#ffe9a8` | ~0.74 |
| Pip | mint `#98e6c6` | `#4fb894` | `#eafff5` | deep teal `#2e5b4a` | orange `#ff9642` | ~0.42 |
| Momo | peach `#ffc0b0` | `#e08974` | `#fff2ec` | brown `#7a4a3a` | button-brown `#6b4a3a` | ~0.05 |
| Player | cyan `#b8e0e6` | `#6aa3ad` | `#f2fcff` | slate `#3a5a66` | white | ~0.52 |

Hue separation between every pair is > 0.05 (asserted by tests). Identity also
survives for colour-blind players because silhouette, accessory, and chest
marking differ independently of hue.

## Accessories (silhouette drivers)

| Accessory | Used by | Shape |
|-----------|---------|-------|
| `DROOP_EARS` | Lumi | two long ears angled outward |
| `LEAF_ANTENNA` | Pip | stem + leaf, pointed top |
| `BUTTON_STUDS` | Momo | two side nubs |
| `SIMPLE_ANTENNA` | Player | single rod + glowing bulb |

## Chest markings

`STAR` (Lumi), `LEAF` (Pip), `BUTTON` (Momo), `NONE` (player). Markings are a
second identity channel independent of palette.

## Expression grammar

Expressions map to eyes, brows, and mouth only (no redraw of the face plate):

| Expression | Eyes | Brows | Mouth |
|------------|------|-------|-------|
| neutral | 1.0 | neutral | neutral |
| happy | 0.6 (squint) | raised | smile |
| sad | 0.85 | down | frown |
| afraid | 1.3 (wide) | down | small |
| surprised | 1.4 (wide) | raised | o |
| uncanny | 1.0, no blink | neutral | uneven |

`uneven_smile` is a data flag (Momo) that keeps a subtly wrong resting smile.

## Animation set (Phase 2)

Implemented as rigged cutout motion (`CharacterRig`):

- `idle` — gentle vertical bob, tiny accessory sway.
- `walk` — hop with squash/stretch and shadow scaling.
- `uncanny_idle` — slower, no-squash drift (Momo).
- `talk` — overlaid mouth flap while a dialogue is active.

Deferred to later phases: run/hurry, listen, angry, loop reaction, restart
plea, timeline ending (`AGENTS.md` §7).

## Character asset pipeline

Current technique: **layered cutout animation**, drawn procedurally so no
binary art is required to run the game. Layer order (bottom → top):

```
Shadow → BackAccessory → Body → Face → Eyes → Mouth → Marking
```

Layers live in `scenes/characters/character_rig.tscn`; each is a separate
`CharacterLayer` node. `Face/Eyes/Mouth/Marking` are children of `Body`, so
they inherit its bob and squash. `CharacterRig` owns motion/expression/talk
state and transforms the layers.

Replacing placeholders with final art (future):

1. Export per-layer PNGs at 4x the 16 px design scale (nearest filter).
2. Keep the same layer names and origins so `CharacterRig` needs no changes.
3. Store under `assets/characters/<id>/{body,face,eyes,mouth,accessory,marking}.png`.
4. Update `CharacterData` to reference textures instead of drawing; keep
   palette/expression data as the source of truth for tinting and variants.
5. Verify identity at 1x gameplay scale before expanding the cast.

Do not add a new character as a bespoke script; add a `CharacterData` resource.

## 3D presentation (Phase 13)

Presentation can render the world and characters in 3D while gameplay stays 2D
(ADR-030). Enabled by `ApplicationSettings.use_3d_visuals` (on by default):

- `AreaWorld3D` builds a three-quarter (45°) orthographic 3D scene per area:
  sky, soft-shadowed sun, a textured ground plane, walls, houses, and a prop
  per interactable, all placed at the same coordinates as the 2D layout.
- `Actor3D` builds each creature from the same `CharacterData`. If the character
  defines `model_id`, the CC0 model is used (rigged, idle animation); otherwise
  the procedural body is built from silhouette/colour/accessory/eyes. The
  camera looks from 45°, so the face is modelled on the front-top of the body.
- Environment detail uses CC0 low-poly models from Kenney's Nature Kit
  (`assets/models/nature/`, see `docs/CREDITS.md`), auto-fitted by
  `ModelLibrary`; if absent, primitive meshes are used instead.
- The 2D procedural drawing is hidden when 3D is on; the 2D nodes remain the
  authoritative gameplay (collision + interaction).

This keeps one source of identity data (the resource) for both renderers. The
layer is intentionally simple/all-primitive; authored meshes can replace it the
same way authored PNGs replace the 2D placeholders.
