# plan — Third-Person Shooter (Aim & Shoot) 3D Template

> Design & task breakdown. Brief: [[info]]. Build journal: [[logs]].

## 1. Game design (template scope)

A minimal **over-the-shoulder third-person shooter**, modeled on **Resident Evil 4 Remake**
aiming. The avatar (the provided Mixamo character) stands in a small arena with a few target
dummies. The camera sits behind the right shoulder. **Right-click** raises the gun into an aim
stance and the camera **zooms in** (closer, narrower FOV, tighter shoulder offset) while the mouse
keeps steering the aim; **left-click** fires — recoil animation, muzzle flash, and a hit-scan ray
through screen-center. The character's **upper body bends to follow the center crosshair** so the
gun visibly points where you aim. Intentionally small — it's a *template* meant to be extended
(weapons, enemies, locomotion, damage).

### Pillars
- **RE4-style OTS aim** — shoulder camera + smooth aim-zoom blend; aim never loses mouse control.
- **Bone-accurate aiming** — a drop-in `SkeletonModifier3D` pitches the spine to the reticle; the gun rides a hand bone socket.
- **Web-first** — renderer (GL Compatibility), VFX, and build are all validated against the HTML5 target.
- **Readable** — plain GDScript, commented, no external addons; data lives on `@export`s for easy tuning.

### Scene tree (target)
```
World (Node3D)                       scenes/world.tscn — main scene
├── WorldEnvironment                 procedural sky + ambient (Compatibility-safe)
├── DirectionalLight3D               sun + shadows
├── Ground (StaticBody3D)            box collider + mesh
├── Props / TargetDummies (Node3D)   a few static blocks + dummies as aim targets
├── Player (CharacterBody3D)         scenes/player.tscn — scripts/player.gd
│   ├── CollisionShape3D (capsule)
│   ├── Model (Node3D)               ← instanced model FBX (Skeleton3D + AnimationPlayer)
│   │   └── …Skeleton3D…
│   │        ├── AimModifier (SkeletonModifier3D)  scripts/aim_modifier.gd — pitches spine to reticle
│   │        └── BoneAttachment3D (right-hand bone)
│   │             └── Gun (Node3D)    scripts/gun.gd — procedural mesh + Muzzle (Marker3D)
│   └── AnimationPlayer (from model; Shooting clip merged in)
├── CameraRig (Node3D)               scripts/camera_rig.gd — OTS + aim-zoom + collision
│   └── SpringArm3D └── Camera3D
└── HUD (CanvasLayer)                scenes/hud.tscn — scripts/hud.gd — crosshair + debug
```

### Aim / shoot design (core mechanic)
- **State:** `HIP` (default) ↔ `AIM` (while RMB held). `firing` is a brief one-shot inside `AIM`.
- **Right-click → AIM:**
  - Play the merged `Shooting` clip and **hold at `AIM_POSE_TIME`** (paused) — the steady aiming pose.
  - Body **yaws to face the camera** direction (RE4: you aim where the camera looks).
  - Camera blends to the **aim profile** (see camera design).
  - `AimModifier` activates: spine chain pitches to the center crosshair.
- **Left-click (while aiming) → SHOOT:**
  - Play the clip's **recoil window** `[FIRE_START, FIRE_END]` once, then snap back to the aim hold.
  - Hit-scan **raycast from the Camera through screen-center**; on hit, spawn an impact marker (and flash the dummy).
  - **Muzzle flash** (OmniLight pulse) at the gun muzzle; HUD crosshair kicks; brief camera recoil.
- **Release RMB → HIP:** camera blends back out; spine modifier eases off; gun lowers (rest pose).
- Exact `AIM_POSE_TIME` / `FIRE_START` / `FIRE_END` are calibrated from the clip at inspection (T3).

### Camera design (OTS + aim-zoom)
- `CameraRig` (yaw) → `SpringArm3D` (pitch + collision) → `Camera3D`, with a lateral **shoulder offset**.
- Two profiles blended by `aim_t` (0→1 eased):
  | Param | Hip (0) | Aim (1) |
  |---|---|---|
  | spring length (distance) | 3.5 m | 1.6 m |
  | shoulder offset (local x) | 0.55 m | 0.40 m |
  | height | 1.55 m | 1.45 m |
  | FOV | 70° | 50° |
- Mouse drives `yaw` (around the rig) and `pitch` (on the spring arm), clamped. `SpringArm3D` keeps the
  camera out of walls. Aim-zoom is a `lerp` toward the aim profile each frame — mouse control is never lost.

### Spine-aim modifier design (`aim_modifier.gd`)
- A `SkeletonModifier3D` subclass added under the model's `Skeleton3D`. Its `_process_modification()` runs
  **after** the AnimationPlayer writes the pose, so it can additively rotate bones without the animation
  overwriting it.
- While `influence > 0`, it distributes a **target pitch** (the camera's pitch toward the reticle) across a
  configurable spine chain (e.g. `Spine`, `Spine1`, `Spine2`), each bone taking a share, rotating about its
  local right axis. `influence` is eased in/out with the aim state so hip-fire keeps the raw animation pose.
- Result: the gun (on the hand bone, downstream of the spine) lifts/lowers to match where the camera looks —
  "arm/body bone follows the crosshair at screen center."

### Animation strategy
- Model FBX provides `Skeleton3D` + mesh + an `AnimationPlayer` (its own clip is usually just a bind/rest pose).
- `Shooting` FBX provides the same Mixamo rig + the shooting clip. At runtime, load the animation scene and copy
  its clip into the model's `AnimationPlayer` via a shared `AnimationLibrary` (Mixamo bone names match — no
  retargeting). Inspection (T3) confirms the exact clip name, length, the hand bone, the spine chain, and the
  aim-hold / fire-recoil sample times before wiring.

## 2. Task plan

- [x] **T1 — Planning docs**: info.md, plan.md, logs.md. *(this file)*
- [x] **T2 — Project setup**: clone starter pack into vault root; rewrite `project.godot` (4.6, **gl_compatibility**, Jolt, main scene `res://scenes/world.tscn`, window 1280×720); input actions via `GameInput` autoload (`aim`=RMB, `attack`/fire=LMB, `move_*`, `toggle_debug`=F3, `ui_cancel`).
- [x] **T3 — Import & inspect**: headless import; dump tree + bone names; find right-hand bone + spine chain + model scale; list `Shooting` clip name/length; sample the right-hand/arm height across the clip to pick `AIM_POSE_TIME` and the `[FIRE_START, FIRE_END]` recoil window. Record findings in [[logs]].
- [x] **T4 — World scene + camera**: ground, sun, sky env, props + target dummies; `CameraRig` (OTS, mouse yaw/pitch, aim-zoom blend, ~~SpringArm~~ manual-ray collision — see §5).
- [x] **T5 — Player aim/shoot**: instance model, resolve Skeleton3D/AnimationPlayer, merge `Shooting` clip; HIP/AIM state machine; RMB aim-hold + body-faces-camera; LMB fire (recoil window + hit-scan ray + muzzle flash + impact); build `Gun` mesh and attach to the right-hand `BoneAttachment3D`; add `AimModifier` and feed it the camera pitch.
- [x] **T6 — HUD/debug**: center crosshair (expands on hip, tightens on aim, kicks on fire), controls hint, hit-marker, debug panel (FPS, state, aim_t, anim time, spine pitch, last-hit).
- [x] **T7 — DEBUG run & fix**: run main scene (windowed + a headless `--demo` that auto-aims/fires and screenshots); capture log; fix every error/warning until clean. Log each in [[logs]].
- [x] **T8 — Tests**: headless `test_runner.gd` asserting skeleton/anim resolved, hand + spine bones found, `Shooting` clip merged, gun attached under the hand bone, `AimModifier` moves the gun when influenced, raycast fires and reports a hit on a dummy. Print PASS/FAIL with a CI exit code. → **17/17 PASS**.
- [x] **T9 — Web build & deploy**: `export_presets.cfg` Web preset (nothreads); headless `--export-release "Web"` to `build/web/`; `serve.py` (correct `.wasm`/`.pck` MIME) on `http://localhost:8061`; verify the engine boots and the game runs in-browser. → **runs in Chrome/WebGL, PCK 11.1 MB**.

## 5. Deviations from the original design (post-build)
- **T4 — manual ray camera collision instead of `SpringArm3D`.** Plain math (yaw/pitch basis + a pivot→camera
  ray clamp) made the OTS shoulder offset and the aim-zoom blend trivial to control and is fully renderer/web
  safe; the SpringArm's child-positioning convention added confusion for no benefit.
- **T5 — the character always holds the gun-ready pose** (the `Shooting` clip held at t=0.21). Only a shooting
  clip was provided (no idle/walk), so HIP and AIM share that pose; aiming differs by the camera zoom, the body
  yawing to face the camera, and the spine following the crosshair. Wiring a locomotion clip + a lowered
  "low-ready" pose is the documented extension point.
- **T5 — `AimModifier.pitch_sign = -1`** (calibrated): on the Mixamo rig, rotating the spine about +local-X
  pitches the torso *forward*, so look-up needed the negative sign to arch back / raise the gun.
- **T8 — the aim-modifier test probes the gun's world position, not the hand bone.** Godot 4.6
  `Skeleton3D.get_bone_global_pose()` returns the *pre-modifier* pose (reads Δ=0 while the spine visibly bends);
  the modifier output only appears in the rendered pose that `BoneAttachment3D` follows — so the gun moves ~1 m.
- **T9 — textures re-imported VRAM-compressed + size-capped** (model 1024 / animation 256) to cut the web PCK
  from 310 MB to 11.1 MB; the Mixamo FBX embed 12 lossless 4K–8K textures each, duplicated across both files.

## 3. Acceptance criteria
- Right-click raises the gun and zooms the camera (RE4-style); the mouse still aims. Release returns to hip.
- The upper body visibly pitches to follow the center crosshair; the gun points where the camera looks.
- Left-click plays the recoil, flashes the muzzle, and a hit-scan ray marks/【flashes】the target it hits.
- The gun is a real node attached to the hand bone (rides the animation).
- Project runs in DEBUG with **no errors** in the output log (warnings triaged).
- Automated tests print **PASS** (CI exit 0).
- `build/web/index.html` loads and runs the game at `http://localhost:8061`.
- Every bug found/fixed and every feature change is recorded in [[logs]].

## 4. Risks / mitigations
- **Mixamo bone-name flavor (`mixamorig_X` vs `mixamorig:X`)** → resolve names at inspection (T3); store as constants.
- **Shooting clip has no clean aim-hold / fire split** → sample arm height across the clip to pick times empirically; if the clip is a tight loop, hold at t≈0 and treat one loop as the recoil.
- **Spine modifier over-rotates / breaks the mesh** → clamp total pitch, split across 2–3 bones, ease `influence`; expose all of it as `@export`.
- **Aim-zoom clips the camera into geometry** → `SpringArm3D` handles collision; aim profile only shortens length, never disables the arm.
- **Model imports giant/tiny (cm vs m)** → fix the FBX import scale at T3 if needed.
- **Glow/HDR unreliable on Compatibility** → muzzle flash = a plain additive/emissive light pulse, no glow post-FX.
- **WASM MIME / threads on Python server** → `nothreads` build + custom handler sets `application/wasm`; no COOP/COEP needed.
