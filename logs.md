# logs — Build journal

> Running log of setup, bugs found & fixed, and feature changes for the Third-Person Shooter
> (Aim & Shoot) template. Brief: [[info]] · Design: [[plan]]. Newest entries at the bottom of each section.
> Each entry is tagged **[Setup]**, **[Bug]**, **[Feature]**, **[Test]**, or **[Build]**.

## Environment & decisions
- **2026-06-01** — Toolchain discovered: Godot **4.6.2.stable (Steam)** at
  `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe` (self-contained, headless OK);
  git 2.51; Python 3.10 & 3.13. Blender absent (not needed — 4.6 native `ufbx` FBX import).
- **2026-06-01** — Export templates **4.6.2.stable** present incl. `web_nothreads_release.zip`.
- **2026-06-01** — Engine **4.6.2** (matches starter pack `features=4.6`); renderer **gl_compatibility**
  (WebGL2 requirement — Forward+ can't run in a browser); physics **Jolt** (kept). Aim solve = custom
  `SkeletonModifier3D` (runs after the animation pose); gun = procedural mesh on a hand-bone `BoneAttachment3D`;
  shooting = hit-scan raycast from the camera through screen-center; web variant = `nothreads`.
- **2026-06-01** — Starter pack `github.com/NaphatPound/godot-starter-pack` is minimal: `project.godot`
  (4.6 / Jolt / Forward+ / d3d12), `icon.svg`, and `scenes/world.tscn` (an empty `Node2D`). The 3D scene is
  built from scratch.

## Setup
- **2026-06-01 — T2** Copied starter-pack files into the vault root (`icon.svg`, dotfiles); rewrote
  `project.godot`: name "Third-Person Shooter Template", main scene `res://scenes/world.tscn`, renderer
  `gl_compatibility`, Jolt kept, window 1280×720. Input actions registered in code via the `GameInput`
  autoload (`scripts/game_input.gd`): `aim` (RMB), `attack`/fire (LMB + Space), `move_*` (WASD/arrows),
  `toggle_debug` (F3); `ui_cancel`/Esc reused for release-mouse/quit.
- **2026-06-01 — T3** Headless `--import` OK (exit 0). A bare `SceneTree -s` inspector could **not** apply
  AnimationPlayer poses (skeleton stayed in bind pose for every `seek`) — switched to a scene-based inspector
  (`scenes/inspect.tscn` + `scripts/inspect_node.gd`) that awaits real process frames, which applies the pose.
  Inspection findings:
  - **Model** `res://model/Ch35_nonPBR.fbx`: `Node3D > Skeleton3D ( Ch35 MeshInstance3D ) + AnimationPlayer`.
    **65 bones, `mixamorig_*`** naming. Scale correct (hand ≈1.3–1.4 m, character ≈1.7 m). Model's own clips:
    `Take 001` (9.08 s, **static**) and `mixamo_com` (0.033 s bind pose).
  - **Key bones**: Hips=0, Spine=1, Spine1=2, Spine2=3, Neck=4, Head=5, RightShoulder=31, RightArm=32,
    RightForeArm=33, **RightHand=34** (gun socket). Full left/right hands + legs present.
  - **Animation** `res://animation/Shooting.fbx`: clips `Take 001` (9.08 s, **static — ignore**) and
    **`mixamo_com` (1.167 s, 53 tracks)** = the real shooting motion.
  - **`mixamo_com` motion** (right-hand in skeleton space): a two-handed **gun-forward aiming loop** — steady
    aim (handZ≈0.546 fwd, handY≈1.26) → **recoil kick** (handZ pulls back to ≈0.501, right-arm pitch dips
    −6°→−13°) over **t≈0.25→0.50**, deepest ≈0.42–0.46 → recovers to steady by **t≈1.0**; frame 0 ≈ frame end
    (loop seam). Right-hand rest (skeleton space) = (-0.689, 1.421, -0.032); aim-pose hand = (-0.165, 1.264, 0.546).
  - **Chosen calibration** → `AIM_POSE_TIME = 0.21` (steady, just before the kick), `FIRE_START = 0.21`,
    `FIRE_END = 1.0` (recovery). Hold-aim = play `shoot` + seek(0.21) + pause; fire = unpause → play to 1.0 →
    seek back to 0.21 + pause, with muzzle flash + hit-scan ray fired on the click.

## Bugs found & fixed
- **2026-06-01 — T3** Inspector parse error `Cannot infer the type of "full"` (concatenating two `Variant`
  loop vars from an untyped array). Fixed with an explicit `var full: String = String(pre) + String(bn)`.
  (Godot 4.6 promotes inferred-from-Variant to an error.)
- **2026-06-01 — T7** `gun.gd` crashed on spawn: `Node not found: "Muzzle"`.
  **Root cause:** `@onready var muzzle := $Muzzle` resolves the moment the Gun enters the tree — but the
  Muzzle marker is created later inside `_ready()`'s `_build_mesh()`, so it didn't exist yet.
  **Fix:** dropped the `@onready` and assign `muzzle = m` when the marker is built.
- **2026-06-01 — T7** Spine aim bent the **wrong way** — looking up hunched the character forward instead of
  raising the gun (verified in `build/demo_5_lookup.png`).
  **Root cause:** `AimModifier.pitch_sign` was +1; rotating the Mixamo spine about +local-X pitches the torso
  *forward*, but a positive (look-up) camera pitch should arch it *back*.
  **Fix:** default `pitch_sign = -1.0`. Re-verified: look-up raises the gun to the sky, look-down lowers it
  to the ground (`demo_5_lookup.png` / `demo_6_lookdown.png`).

## Feature changes
- **2026-06-01 — T4–T6** Core TPS aim/shoot template implemented:
  - `GameInput` autoload — registers `aim`/`attack`/`move_*`/`toggle_debug` in code.
  - `camera_rig.gd` (CameraRig) — over-the-shoulder camera that looks **forward** (screen-center = aim).
    Blends a hip profile (dist 3.4 m, FOV 70°, shoulder +0.55) to an **RE4 aim profile** (dist 1.45 m, FOV
    45°, shoulder +0.42) on aim; mouse drives yaw/pitch; manual ray-based collision keeps it out of walls;
    transient recoil kick; `look_at_point()` helper for scripted aim.
  - `player.gd` (CharacterBody3D) — instances the model, merges the `mixamo_com` Shooting clip as `shoot`,
    holds the steady aim pose (seek 0.21 + pause). RMB → aim (body faces camera, strafe, camera zoom); LMB →
    fire (plays the recoil window 0.21→1.0 at 1.4×, muzzle flash, camera+crosshair kick, hit-scan ray from the
    camera through screen-center). Builds the gun on a `BoneAttachment3D(mixamorig_RightHand)` and adds the
    spine `AimModifier`; feeds it the camera pitch eased by the aim blend.
  - `aim_modifier.gd` (SkeletonModifier3D) — post-animation, distributes the camera pitch across
    Spine/Spine1/Spine2 so the upper body + gun follow the center crosshair; blended by the built-in `influence`.
  - `gun.gd` (Gun) — procedural pistol (boxes) + muzzle Marker3D + muzzle-flash OmniLight pulse.
  - `dummy.gd` (TargetDummy) — shootable capsule on the dummy layer; flashes red on `on_hit()`.
  - `hud.gd` — center crosshair that tightens on aim and kicks on fire, hit-marker flash, controls hint,
    F3 debug overlay (FPS, state, aim_t, anim time, spine pitch, last hit).
  - `world.gd` / `world.tscn` — sky/ambient env, sun w/ shadows, ground, two walls (camera-collision demo),
    three target dummies, player, camera rig, HUD. `-- --demo` hook auto-aims/fires and screenshots to `build/`.

## Tests
- **2026-06-01 — T7** Windowed DEBUG run (`-- --demo`): **clean, exit 0**, GL Compatibility context OK.
  Six screenshots saved to `build/`. Visual sign-off: character (Ch35 SWAT) holds the gun two-handed;
  **RE4 aim-zoom** pushes the camera over the right shoulder with a tighter FOV; firing shows a **muzzle
  flash + recoil + crosshair kick**; the hit-scan ray reddens the centre dummy (`dummy @ 7.6m`); looking up
  **raises** the gun to the sky and looking down **lowers** it (spine modifier follows the centre crosshair).
  No null-refs, no shader/material errors after the two fixes above.
- **2026-06-01 — T8** `scripts/test_runner.gd` (headless, scene-based, CI exit code) via `scenes/test.tscn`.
  Result: **17/17 PASS, exit 0**. Covers: player + camera present, skeleton resolved (65 bones), AnimationPlayer
  resolved, `shoot` clip merged, right-hand + Spine/Spine1/Spine2 bones found, gun socket is a hand
  `BoneAttachment3D`, gun + Muzzle attached, `AimModifier` present under the skeleton and **moves the gun >5cm**
  when aiming up, and the **hit-scan ray hits a dummy**.
  - **Note (Godot 4.6 gotcha):** `Skeleton3D.get_bone_global_pose()` returns the *pre-modifier* (animation)
    pose — it reads Δ=0 even while the `SkeletonModifier3D` is bending the spine. The modifier output only
    shows up in the *rendered* pose, which `BoneAttachment3D`-parented nodes follow. So the test measures the
    **gun's** world position (Δ≈1.08 m) instead of the hand bone pose. First version failed for exactly this
    reason before switching probes.
  - Run: `godot --headless --path . scenes/test.tscn --quit-after 600`

## Build & deploy
- **2026-06-01 — T9 [Bug] Web PCK was 310 MB.** First `--export-release "Web"` produced an `index.pck` of
  **310 MB**. **Root cause:** both FBX are ~142 MB with **12 embedded textures each** (some 28 MB PNGs ≈ 4K–8K),
  and Mixamo embeds the **same** texture set in the model *and* the animation FBX, so it's duplicated; the
  textures imported **lossless** (`compress/mode=0`) with **no size cap** (`process/size_limit=0`) → 299 MB of
  `.ctex`. **Fix:** batch-edited the 24 `*.png.import` files to VRAM compression (`compress/mode=2`, ETC2/ASTC —
  the preset already sets `import_etc2_astc=true`) and capped resolution — model textures at **1024**, the
  never-rendered animation textures at **256** — then re-imported. **PCK 310 MB → 11.1 MB.** Re-ran the demo:
  character still renders correctly (no pink/missing textures) on GL Compatibility.
- **2026-06-01 — T9** Added `export_presets.cfg` (Web preset, `variant/thread_support=false` → non-threaded,
  `exclude_filter` drops the inspect/test scripts+scenes and `build/*`). Headless `--export-release "Web"` →
  **exit 0**. Output in `build/web/`: `index.html` (5.5 KB), `index.js` (316 KB), `index.wasm` (37.7 MB),
  `index.pck` (11.1 MB), audio worklets + icons.
- **2026-06-01 — T9** `serve.py` (Python `http.server`) serves `build/web` with `.wasm`→`application/wasm`,
  `.pck`→`application/octet-stream`, `.js`→`text/javascript`; no COOP/COEP needed (non-threaded). Chose port
  **8061** (8060 was held by the Sword-Trail build's server). Verified `curl -I`: `/`, `/index.wasm`,
  `/index.pck`, `/index.js` all **HTTP 200** with correct MIME; `<title>Third-Person Shooter Template</title>`.
- **2026-06-01 — T9** **Confirmed it runs in-browser.** Headless Chrome (`--headless=new`, software WebGL via
  `--use-angle=swiftshader`) loaded `http://localhost:8061/` and rendered the full scene — character holds the
  gun, walls + dummies visible, HUD (crosshair, controls, debug) drawn (`build/web_browser.png`). FPS is low
  only because of software rendering; the GL Compatibility path is identical to the verified desktop run.
- **Run the web build:** `python serve.py` (from the project root) then open `http://localhost:8061/`.
