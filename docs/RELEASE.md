# Samsara — Release & Build

How to produce and verify a desktop build. The game targets Godot 4.5.x.

> **Renderer:** the 3D look uses the **Forward+** renderer (desktop) with a
> colour grade (ACES tonemap, adjustments, glow, SSAO, fog), so the Windows/
> Linux builds require a **Vulkan-capable GPU**. To target older hardware,
> set `rendering/renderer/rendering_method="gl_compatibility"` in
> `project.godot` (this disables the post-processing grade).

## Prerequisites

1. **Godot 4.5.x** (standard or mono) matching the project's `config/features`
   (`4.5`, GL Compatibility).
2. **Export templates** for each target platform. The engine ships none by
   default; install them from the editor (*Editor → Manage Export Templates…*)
   or place them under
   `%APPDATA%\Godot\export_templates\4.5.1.stable\` on Windows
   (`~/.local/share/godot/export_templates/4.5.1.stable/` on Linux).

   Without templates, export fails with:

   ```
   No export template found at the expected path:
   .../export_templates/4.5.1.stable/windows_release_x86_64.exe
   ```

   To install from the official archive without the editor UI:

   ```
   curl -L -o godot_templates.tpz \
     https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_export_templates.tpz
   ```

   The `.tpz` is a ZIP whose `templates/` entries go directly into
   `%APPDATA%\Godot\export_templates\4.5.1.stable\`. Extract only what you need
   (e.g. `windows_release_x86_64.exe`, `linux_release.x86_64`, `version.txt`);
   the full archive is ~1.26 GB, so mind free disk space.

   Also create the output directory first — Godot does **not** create the
   parent of the export path (`build/windows`, `build/linux`).

## Presets

`export_presets.cfg` defines:

| Preset | Platform | Output |
|--------|----------|--------|
| `Windows Desktop` | Windows Desktop (x86_64) | `build/windows/Samsara.exe` |
| `Linux/X11` | Linux (x86_64) | `build/linux/Samsara.x86_64` |

## Building (headless)

```
godot --headless --path . --export-release "Windows Desktop" build/windows/Samsara.exe
godot --headless --path . --export-release "Linux/X11"       build/linux/Samsara.x86_64
```

(Use `--export-debug` for a debug build with the console wrapper.)

## Verifying the build

1. Launch the exported binary on a machine **without** the Godot editor or
   project files. It should open on the title screen.
2. Confirm the flow: **Continue** (if a save exists) or **New Timeline** →
   move, interact (E / gamepad A), open the Journal (J / Y) and Settings.
3. Confirm audio: music/ambience per area, SFX on interactions, silence when a
   volume is zeroed.
4. Confirm a full arc: complete Pip/Lumi/Momo, resolve the picnic, meet Fern,
   settle the returning tree, and touch the plaza lantern to finish a timeline.
5. Confirm saves: Save/Load from the pause menu; restart archives the old
   timeline and preserves settings + meta-progression.

## Release checklist (AGENTS.md §Phase 12)

- [x] Movement and interaction feel refined (acceleration/friction).
- [x] Dialogue timing/presentation refined (typewriter + skip, high-contrast).
- [x] Music and ambience added and balanced per area (synthesized beds).
- [x] Transitions and animation improved (fade; reduce-motion aware).
- [x] Lighting/colour/atmosphere refined (`MetaUI` escalation, area palettes).
- [x] Accessibility settings tested (reduce motion, high-contrast text, volumes,
      text speed, fullscreen) — persisted independently of saves.
- [x] Keyboard + controller bindings tested at the input-map level.
- [x] Saves, restarts, and recovery tested (suite + manual steps above).
- [~] Performance profiling — the game is a lightweight 2D project; profile a
      real GPU build before shipping (see Known limitations).
- [x] Gameplay blockers/regressions fixed (`493 passed, 0 failed`).
- [x] Export presets prepared and used to build `build/windows/Samsara.exe` and
      `build/linux/Samsara.x86_64` (Godot 4.5.1 templates installed).
- [x] Exported build launches on a clean run: the release binary boots through
      `boot.tscn` → title screen and exits `0` (`--headless --quit-after`).

## Known limitations

- **Builds are regenerable artifacts, not committed.** `build/` is produced by
  the commands above; it is ~167 MB and can be deleted and rebuilt.
- **Benign shutdown warning in forced-quit runs.** A headless `--quit-after`
  exit can print `ObjectDB instances leaked at exit` because the audio thread
  has not released stopped music playbacks before the engine's cleanup. Verbose
  runs (slower) do not reproduce it, the process still exits `0`, and the test
  runner settles audio before quitting so the suite itself is clean.
- **Placeholder art and audio.** Visuals are procedural but intentional
  (`docs/ART_BIBLE.md`); audio is synthesized. Authored assets are a future
  pass.
- **No hardware profiling in CI.** Headless runs cannot measure frame time;
  profile a real GPU build before shipping.
- Ability selection is contextual (first valid), not a browsable menu.
