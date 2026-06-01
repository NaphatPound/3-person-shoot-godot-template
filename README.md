# Third-Person Shooter (Aim & Shoot) — Godot 4.6 Template

A reusable **over-the-shoulder third-person shooter** template for Godot, in the style of
**Resident Evil 4 Remake**: shoulder camera, right-click to aim & zoom, left-click to fire,
a gun attached to the character's hand, and an upper body that bends to follow the center
crosshair. Built on [NaphatPound/godot-starter-pack](https://github.com/NaphatPound/godot-starter-pack)
with the provided Mixamo model + `Shooting` animation.

> Design brief: [info.md](info.md) · Task plan: [plan.md](plan.md) · Build journal: [logs.md](logs.md)

## Controls
| Action | Input |
|---|---|
| Move | `W A S D` / arrows |
| Aim (hold) → RE4 zoom | **Right Mouse** |
| Shoot | **Left Mouse** (or `Space`) |
| Toggle debug overlay | `F3` |
| Release mouse / quit | `Esc` |

*(First click captures the mouse — required for browser pointer-lock.)*

## What it demonstrates
- **Over-the-shoulder camera** (`scripts/camera_rig.gd`) that looks forward (screen-center = aim),
  with a hip↔aim profile blend (distance, FOV, shoulder offset) and ray-based wall collision.
- **Aim/shoot loop** (`scripts/player.gd`): holds the steady aim pose, plays the recoil window on
  fire, hit-scan ray from the camera, muzzle flash, camera + crosshair kick.
- **Gun on a hand bone** (`scripts/gun.gd` on a `BoneAttachment3D(mixamorig_RightHand)`).
- **Bone-accurate aiming** (`scripts/aim_modifier.gd`, a `SkeletonModifier3D`): the spine chain pitches
  to the crosshair so the gun points where the camera looks.
- **HUD** (`scripts/hud.gd`): reactive crosshair, hit-marker, F3 debug readout.

## Run / debug / test / deploy
Set `GODOT` to your editor binary (here: the Steam build):
`"G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"`

```sh
# Play (DEBUG)
"$GODOT" --path . scenes/world.tscn
# Auto aim/shoot demo + screenshots to build/
"$GODOT" --path . scenes/world.tscn -- --demo
# Headless tests (CI exit code)
"$GODOT" --headless --path . scenes/test.tscn --quit-after 600
# Web export (HTML5, non-threaded)
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
# Serve the web build, then open http://localhost:8061/
python serve.py
```

## Project layout
```
3-person-angle/            <- Obsidian vault AND Godot project root (res://)
├── info.md plan.md logs.md README.md
├── project.godot          export_presets.cfg   serve.py
├── animation/ model/      provided Mixamo FBX (Shooting clip + Ch35 model)
├── scenes/                world.tscn · player.tscn · hud.tscn · dummy.tscn · (inspect/test)
├── scripts/               player · camera_rig · aim_modifier · gun · hud · dummy · world · game_input · test_runner
└── build/web/             exported HTML5 build (served on localhost)
```

## Tuning & extension points
- **Camera feel** — `CameraRig` exports: hip/aim `distance`, `height`, `shoulder`, `fov`, `sensitivity`,
  `aim_blend_speed`, recoil `max_kick`.
- **Aim bend** — `AimModifier` exports: `bone_names`, `max_total_pitch_deg`, `pitch_axis`, `pitch_sign`.
- **Fire feel** — `Player` exports: `fire_cooldown`, `fire_speed_scale`, `fire_recoil`, `aim_pitch_gain`,
  `gun_offset`; clip timing constants `AIM_POSE_TIME` / `FIRE_START` / `FIRE_END`.
- **Locomotion** — only a `Shooting` clip was supplied. Merge a walk/idle clip the same way `_merge_shoot_clip()`
  does and drive it from movement to replace the static-pose slide.
- **Weapons / damage** — swap the procedural `Gun` for a model (keep a `Muzzle` child); give dummies HP and the
  ray a damage payload.

## Tech notes
- Godot **4.6.2**, renderer **GL Compatibility** (required for WebGL2 — Forward+ can't run in a browser),
  physics **Jolt**.
- Web export is the **non-threaded** variant, so it runs behind a plain static server (no COOP/COEP headers).
- The Mixamo FBX embed large lossless textures; they're re-imported VRAM-compressed and size-capped so the web
  PCK is ~11 MB (see logs.md §Build).
