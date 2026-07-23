# Current Milestone: M4 - Phase Timer System

## Goal
Add a per-phase countdown timer driven by isotope data.

## Why This Matters
The decay timer is a core rule of the game loop. Each isotope phase must run on a timer before transitioning.

## Prerequisites
- M2 complete (movement working)
- M3 complete (data-driven isotope loading working)
- `Data/IsotopeData.gd` contains `timer_range` per isotope

---

## Step-by-Step Instructions

### Step 1: Add Timer State to Atom Script
Open `Scripts/atom.gd` and add these variables near your other fields:

```gdscript
var phase_time_total: float = 0.0
var phase_time_left: float = 0.0
var phase_active: bool = false
```

### Step 2: Sample Timer From Isotope Data
In `load_isotope_data()`, after loading isotope values, sample the timer range:

```gdscript
var timer_range = data.timer_range
phase_time_total = randf_range(float(timer_range[0]), float(timer_range[1]))
phase_time_left = phase_time_total
phase_active = true
print("Phase timer started: ", snapped(phase_time_left, 0.1), "s")
```

### Step 3: Add Countdown Tick
In `Scripts/atom.gd`, add this function:

```gdscript
func tick_phase_timer(delta: float) -> void:
if not phase_active:
return

phase_time_left -= delta
if phase_time_left <= 0.0:
phase_time_left = 0.0
phase_active = false
on_phase_timer_finished()
```

### Step 4: Hook Timer Tick Into Physics Loop
At the top of `drive_towards(world_target: Vector2)`, add:

```gdscript
tick_phase_timer(get_physics_process_delta_time())
```

This keeps timer updates tied to gameplay update cadence.

### Step 5: Add Finish Handler
In `Scripts/atom.gd`, add:

```gdscript
func on_phase_timer_finished() -> void:
print("Phase timer finished for ", isotope_name)
# Transition logic will be added in M10.
```

### Step 6: Expose Read Helpers
Add read-only helpers for UI and game systems:

```gdscript
func get_phase_time_left() -> float:
return phase_time_left

func get_phase_time_total() -> float:
return phase_time_total

func is_phase_active() -> bool:
return phase_active
```

### Step 7: Add a Simple On-Screen Timer Label
Open `Scenes/game.tscn` and add:
1. Child node of `Game`: `CanvasLayer` named `UI`
2. Child node of `UI`: `Label` named `PhaseTimerLabel`
3. In Inspector for `PhaseTimerLabel`, set:
   - Position: `(20, 20)`
   - Text: `Time: --`

### Step 8: Update Game Script for Timer UI
Open `Scripts/game.gd` and add:
1. Onready reference to label
2. Per-frame update from atom timer

Use this logic:

```gdscript
@onready var timer_label: Label = $UI/PhaseTimerLabel

func _process(_delta):
if atom != null and background_material != null:
background_material.set_shader_parameter("world_offset", atom.global_position)

if atom != null and timer_label != null and atom.has_method("get_phase_time_left"):
timer_label.text = "Time: " + str(snapped(atom.get_phase_time_left(), 0.1))
```

### Step 9: Run and Validate
1. Press F5.
2. Confirm timer appears top-left.
3. Confirm value counts down every frame.
4. Confirm finish print appears in output at zero.

---

## Verification Checklist

- [ ] Atom stores `phase_time_total`, `phase_time_left`, and `phase_active`
- [ ] Timer is sampled from isotope `timer_range`
- [ ] Timer counts down during gameplay
- [ ] Timer clamps to 0 at finish
- [ ] `on_phase_timer_finished()` triggers once
- [ ] UI label shows live remaining time
- [ ] No script/runtime errors

---

## Expected Result

When running the game:
- The atom phase starts with a random timer from isotope data.
- Countdown is visible and updates live.
- At zero, phase ends and finish event fires.

---

## Next Step

When all checklist items are done, reply with:
**M4 Complete!**

Then we move to M5 (Goal Area System).
