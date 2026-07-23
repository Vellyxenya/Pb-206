# Current Milestone: M7 - Basic Hazards (Neutron Fields)

## Goal
Add the first hazard type: neutron fields that penalize the player when touched.

## Why This Matters
M6 completed phase outcomes and game-over flow. M7 introduces risk during navigation so reaching the finish area is no longer only a movement/time challenge.

## Prerequisites
- M6 complete (success/fail resolution, game over UI, restart flow)
- Goal system and timer system working

---

## Step-by-Step Instructions

### Step 1: Create Hazard Scene
Create a new scene `Scenes/neutron_field.tscn`:
1. Root: `Area2D` named `NeutronField`
2. Child: `CollisionShape2D` with `CircleShape2D`
3. Child: `Polygon2D` or `Line2D` for simple visible ring
4. Attach script: `Scripts/neutron_field.gd`

### Step 2: Create Hazard Script
Create `Scripts/neutron_field.gd`:

```gdscript
extends Area2D

signal hazard_triggered

@export var radius: float = 180.0
@export var damage_seconds: float = 8.0
@export var tick_interval: float = 0.5

var _atom_inside: RigidBody2D = null
var _tick_accum: float = 0.0

func _ready() -> void:
body_entered.connect(_on_body_entered)
body_exited.connect(_on_body_exited)
_update_shape()

func _physics_process(delta: float) -> void:
if _atom_inside == null:
return
_tick_accum += delta
if _tick_accum < tick_interval:
return
_tick_accum = 0.0
_apply_hazard_tick()

func _on_body_entered(body: Node) -> void:
if body != null and body.name == "Atom":
_atom_inside = body as RigidBody2D
_tick_accum = 0.0

func _on_body_exited(body: Node) -> void:
if body == _atom_inside:
_atom_inside = null

func _apply_hazard_tick() -> void:
if _atom_inside == null:
return
if _atom_inside.has_method("apply_hazard_time_penalty"):
_atom_inside.apply_hazard_time_penalty(damage_seconds)
hazard_triggered.emit()

func _update_shape() -> void:
var collision = $CollisionShape2D
if collision != null and collision.shape is CircleShape2D:
(collision.shape as CircleShape2D).radius = radius
```

### Step 3: Add Timer Penalty API on Atom
In `Scripts/atom.gd`, add:

```gdscript
func apply_hazard_time_penalty(seconds: float) -> void:
if not phase_active:
return
phase_time_left = max(0.0, phase_time_left - seconds)
if phase_time_left <= 0.0:
phase_time_left = 0.0
phase_active = false
on_phase_timer_finished()
```

### Step 4: Add Hazard Container to Game Scene
In `Scenes/game.tscn`, under `Game`, add `Node2D` named `Hazards`.

### Step 5: Spawn Initial Neutron Fields
In `Scripts/game.gd`:
1. preload `neutron_field.tscn`
2. add exports:
   - `hazard_count`
   - `hazard_min_goal_distance`
   - `hazard_min_player_distance`
3. add `spawn_neutron_fields()` called in `_ready()` and when phase resets/advances.

### Step 6: Safe Placement Rules
When spawning each hazard:
- Keep away from atom start position
- Keep away from finish area center
- Keep inside a broad play band around player
- Retry random samples up to N attempts

### Step 7: Add Hazard UI Feedback
Add a small label under existing timer/status:
- `HazardStatusLabel` in `UI`
- Update text when hazard triggers:
  - e.g. `"Neutron Field: -8.0s"`
- Fade/clear after ~1 second.

### Step 8: Respawn Hazards on Phase Change
In both success and restart flows in `game.gd`:
- clear old hazards
- spawn new hazards after goal randomization

### Step 9: Run and Validate
1. Press F5.
2. Enter neutron field.
3. Confirm timer drops by penalty ticks.
4. Confirm hazard feedback text appears.
5. Confirm hazards respawn after success and restart.

---

## Verification Checklist

- [ ] `NeutronField` scene exists with `Area2D` + collision
- [ ] Atom exposes `apply_hazard_time_penalty()`
- [ ] Hazard contact reduces phase timer
- [ ] Timer-end behavior still follows M6 rules
- [ ] Hazards avoid spawning on top of player/goal
- [ ] Hazards respawn on phase transition/restart
- [ ] No script/runtime errors

---

## Expected Result

Neutron fields now create active danger: staying in them drains phase time and increases fail risk, while M6 game-over and chain progression behavior remain intact.

---

## Next Step

When checklist is fully validated, reply with:
**M7 Complete!**

Then move to M8 (Containment Walls).
