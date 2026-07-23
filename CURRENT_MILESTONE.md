# Current Milestone: M2 - Mouse Following Movement

## Goal
Make the atom follow the mouse cursor using physics-based movement with inertia.

## Why This Matters
Movement is the core gameplay loop. In this milestone, the atom becomes controllable while preserving your nucleus visuals, tinting, hex layout, and subtle nucleus motion.

## Prerequisites
- M1 complete
- `Scenes/atom.tscn` exists
- `Scripts/atom.gd` exists
- Atom visuals already spawn correctly (mixed proton/neutron, shader tinting, concentric hex layout)

---

## Step-by-Step Instructions

### Step 1: Open Atom Scene
1. Open `Scenes/atom.tscn`.
2. Select the root node `Atom` in the Scene panel.

### Step 2: Change Atom Root to RigidBody2D
1. Right-click `Atom`.
2. Click **Change Type**.
3. Search and select **RigidBody2D**.

### Step 3: Configure RigidBody2D Properties
With `Atom` selected in Inspector:
1. Set **Gravity Scale** to `0`.
2. Enable **Lock Rotation**.
3. Keep default damping values for now.

### Step 4: Add Collision Shape
1. Select `Atom`.
2. Add child node: **CollisionShape2D**.
3. In Inspector, assign **CircleShape2D** to `shape`.
4. Set radius so it roughly covers the full nucleus cluster.
   - Good start: radius `110` to `140` depending on your `HEX_RADIUS`.

### Step 5: Update Atom Script Base Class
In `Scripts/atom.gd`:
1. Change `extends Node2D` to `extends RigidBody2D`.
2. Add export for movement force:
   - `@export var acceleration_force: float = 1400.0`

### Step 6: Add Mouse-Follow Physics
In `Scripts/atom.gd`, add:
1. A `_physics_process(_delta)` function.
2. Read mouse world position with `get_global_mouse_position()`.
3. Compute direction from atom to mouse.
4. Apply central force in that direction.

Use this code block exactly:

```gdscript
func _physics_process(_delta):
var mouse_pos = get_global_mouse_position()
var to_mouse = mouse_pos - global_position
if to_mouse.length_squared() > 1.0:
apply_central_force(to_mouse.normalized() * acceleration_force)
```

### Step 7: Set Physics Mass from Isotope
In `_ready()` after loading isotope data, set the body mass:

```gdscript
mass = max(1.0, float(mass_number - 200))
```

This preserves your mass-scaling rule and makes heavy isotopes feel slower.

### Step 8: Verify Scene Wiring
1. Ensure `Scenes/game.tscn` still instances `atom.tscn`.
2. Ensure `game.tscn` is still the main scene in Project Settings > Run.

### Step 9: Run and Validate
1. Press F5.
2. Move mouse around.
3. Confirm:
   - Atom accelerates toward cursor.
   - Movement has inertia (drift/momentum).
   - Atom does not spin.
   - Nucleus visuals remain intact while moving.

---

## Verification Checklist

- [ ] `Atom` root is `RigidBody2D`
- [ ] Gravity Scale is `0`
- [ ] Lock Rotation is enabled
- [ ] `CollisionShape2D` exists with `CircleShape2D`
- [ ] `atom.gd` extends `RigidBody2D`
- [ ] `_physics_process` applies force toward mouse
- [ ] `mass` is set from `(mass_number - 200)`
- [ ] Atom follows cursor with inertia
- [ ] Nucleus visuals still render correctly while moving

---

## Expected Result

When running the game:
- The atom follows the cursor using force-based movement.
- Heavy isotopes feel slower due to higher mass.
- The atom remains visually stable: mixed proton/neutron tinting, concentric layout, and subtle nucleus motion.

---

## Next Step

When this checklist is fully done, reply with:
**M2 Complete!**

Then we move to M3 and formalize full data-driven isotope switching/tuning.
