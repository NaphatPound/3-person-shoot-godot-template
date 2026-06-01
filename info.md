# info — Third-Person Shooter (Aim & Shoot) 3D Game Template (Godot)

> Project brief & environment facts. See [[plan]] for the design/task breakdown and [[logs]] for the running build log.

## Goal
Build a reusable **3D third-person shooter template for the Godot engine** centered on
**over-the-shoulder aiming and shooting**, in the style of **Resident Evil 4 Remake**.
The template should:

1. Be based on the user's starter project — `https://github.com/NaphatPound/godot-starter-pack`.
2. Use the provided character **model** and **Shooting** animation as the playable avatar.
3. Implement the aim/shoot loop:
   - **Right-click (hold)** → enter **aim**: play the shooting animation and *hold its first (aim) pose*, raise the gun.
   - **Left-click** → **shoot**: play the firing motion (recoil), fire a hit-scan ray, muzzle flash.
4. **Create a gun** in-engine and **attach it to the character's hand** (bone socket).
5. **Third-person, over-the-shoulder camera** sitting behind the shoulder. On aim, the camera
   **zooms in (RE4-remake style)** — closer, tighter FOV, tighter shoulder offset — and the **mouse still moves** the aim.
6. **Upper-body / arm bones follow the crosshair** fixed at screen center, so the gun points where the camera looks
   (body yaws to the camera while aiming; spine bones pitch up/down to the reticle).
7. Run in **DEBUG mode** for testing / bug-fixing.
8. **Export to Web (HTML5)** and run on a **localhost** website.
9. Ship with an automated **test** harness; every bug fixed and feature change recorded in [[logs]].

## Provided assets
| Type | File | Notes |
|---|---|---|
| Character model | `model/Ch35_nonPBR.fbx` | Mixamo character ("Ch35", non-PBR textures), Mixamo rig |
| Shooting animation | `animation/Shooting.fbx` | Mixamo "Shooting" clip on the same rig (aim stance + firing) |

Both are FBX. Godot 4.6 imports FBX natively (via `ufbx`) — no Blender / FBX2glTF needed.
Exact bone names, the hand bone, the spine chain, the clip name/length, and the aim-hold vs.
fire-recoil timings are discovered at the **inspection** step (see [[plan]] §T3 and [[logs]]).

## Environment (discovered on this machine)
| Tool | Value |
|---|---|
| Godot editor | **4.6.2.stable (Steam)** — `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe` (self-contained, runs headless) |
| Export templates | 4.6.2.stable installed (incl. `web_nothreads_*` — no COOP/COEP headers needed) |
| git | 2.51 |
| Python | 3.10 / 3.13 (used for the local web server) |
| Blender | not installed (not required for 4.6 native FBX) |
| OS / Shell | Windows 11, PowerShell |

## Key technical decisions
- **Engine = Godot 4.6.2** to match the starter pack (`features=PackedStringArray("4.6", …)`) and the installed 4.6.2 templates.
- **Renderer = GL Compatibility** (overrides the starter's *Forward+*). Browsers run WebGL2, which only
  supports the Compatibility renderer — so DEBUG testing matches the web build exactly. Forward+/Vulkan/D3D12
  cannot run in a browser.
- **Physics = Jolt** (kept; built-in in 4.6, renderer-independent).
- **Aim solve = a custom `SkeletonModifier3D`** that runs *after* the AnimationPlayer poses the skeleton and
  additively pitches the spine chain toward the center crosshair. Chosen over hand-authored per-frame
  `set_bone_pose` hacks because modifiers run in the correct order in the skeleton's update and compose cleanly
  with the animation. Horizontal aim = the whole body yaws to face the camera while aiming.
- **Gun = procedural mesh** (a few `BoxMesh` blocks + a muzzle `Marker3D`) built in code and parented to a
  `BoneAttachment3D` on the right-hand bone — no external gun asset required, easy to swap later.
- **Shooting = hit-scan raycast** from the camera through screen-center, with a muzzle flash light and an impact
  marker. Chosen over projectiles for a crisp, renderer-/web-safe template.
- **Web variant = `nothreads`** so the exported game runs from any static localhost server without
  cross-origin-isolation headers.

## Project layout (target)
```
3-person-angle/              <- Obsidian vault AND Godot project root (res://)
├── info.md  plan.md  logs.md
├── project.godot            <- from starter pack, reconfigured
├── animation/  model/       <- provided FBX assets (res://animation, res://model)
├── scenes/                  <- world.tscn, player.tscn, hud.tscn
├── scripts/                 <- player.gd, camera_rig.gd, aim_modifier.gd, gun.gd, hud.gd, game_input.gd, test_runner.gd
├── export_presets.cfg       <- Web (HTML5) preset
└── build/web/               <- exported HTML5 build (served on localhost)
```

## Controls (target)
- **Move:** WASD · **Look/aim camera:** mouse · **Aim (hold):** Right-Mouse · **Shoot:** Left-Mouse
- **Release mouse / quit:** Esc · **Toggle debug overlay:** F3
- Note: only a *Shooting* animation was supplied (no idle/walk locomotion clip), so movement uses the rest pose
  and slides the avatar — a documented extension point. The aim/shoot loop is the focus of this template.
