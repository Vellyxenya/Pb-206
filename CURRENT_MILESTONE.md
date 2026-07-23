# Current Milestone: M6 - Decay Animation & Goal Randomization

## Goal
Add a visible phase-transition sequence when a phase ends and randomize the finish area for the next phase.

## Why This Matters
M5 established the phase win rule. M6 makes phase flow feel alive: clear feedback when a phase resolves, plus a new finish location each phase so movement decisions stay meaningful.

## Prerequisites
- M5 complete (finish area + in/out status + guidance arrow)
- M4 complete (timer + phase end signal)

---

## Step-by-Step Instructions

### Step 1: Add Transition State to Game
Open `Scripts/game.gd` and add state near your exports:

```gdscript
@export var transition_duration: float = 0.8
@export var goal_margin: float = 220.0

var is_transitioning: bool = false
```

### Step 2: Add Transition Visual Node in Scene
Open `Scenes/game.tscn` and under `UI` add:
1. `ColorRect` named `TransitionFlash`
2. Fullscreen anchors preset
3. Color `Color(1, 1, 1, 0)`
4. `mouse_filter = Ignore`

This node will flash briefly during decay transition.

### Step 3: Cache Transition Node in Script
In `Scripts/game.gd` add onready:

```gdscript
@onready var transition_flash: ColorRect = $UI/TransitionFlash
```

### Step 4: Split Phase-End Handling
In `_on_atom_phase_timer_finished()` keep rule from M5:
- If atom is in finish area: success path
- Else: fail path

Replace direct completion call with:

```gdscript
if is_atom_in_finish_area():
start_phase_transition(true)
else:
start_phase_transition(false)
```

### Step 5: Implement Transition Routine
In `Scripts/game.gd`, add:

```gdscript
func start_phase_transition(success: bool) -> void:
if is_transitioning:
return
is_transitioning = true

if success:
print("Phase success: atom in finish area at timer end.")
else:
print("Phase fail: atom outside finish area at timer end.")

await play_transition_flash(success)

if success:
advance_to_next_phase()
else:
restart_current_phase()

is_transitioning = false
```

### Step 6: Add Flash Animation
In `Scripts/game.gd` add:

```gdscript
func play_transition_flash(success: bool) -> void:
if transition_flash == null:
await get_tree().create_timer(transition_duration).timeout
return

var flash_color = Color(0.55, 0.95, 0.60, 0.0) if success else Color(0.95, 0.45, 0.45, 0.0)
transition_flash.color = flash_color

var tween = create_tween()
tween.tween_property(transition_flash, "color:a", 0.45, transition_duration * 0.35)
tween.tween_property(transition_flash, "color:a", 0.0, transition_duration * 0.65)
await tween.finished
```

### Step 7: Add Goal Randomization
In `Scripts/game.gd` add:

```gdscript
func randomize_goal_position() -> void:
var viewport_size = get_viewport_rect().size
var center = camera.global_position if camera != null else Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5)

var min_x = center.x - viewport_size.x * 0.5 + goal_margin
var max_x = center.x + viewport_size.x * 0.5 - goal_margin
var min_y = center.y - viewport_size.y * 0.5 + goal_margin
var max_y = center.y + viewport_size.y * 0.5 - goal_margin

goal_position = Vector2(
randf_range(min_x, max_x),
randf_range(min_y, max_y)
)
```

### Step 8: Add Phase Flow Hooks
In `Scripts/game.gd`, add:

```gdscript
func advance_to_next_phase() -> void:
if atom != null:
atom.on_phase_completed()
randomize_goal_position()
if atom != null:
atom.load_isotope_data()

func restart_current_phase() -> void:
randomize_goal_position()
if atom != null:
atom.load_isotope_data()
```

### Step 9: Initialize First Random Goal
In `_ready()` after your current setup, call:

```gdscript
randomize_goal_position()
_update_goal_area_visual()
```

### Step 10: Run and Validate
1. Press F5.
2. Let timer hit zero while **inside** finish area:
   - Green-ish flash plays
   - Success message prints
   - New randomized goal appears
3. Let timer hit zero while **outside** finish area:
   - Red-ish flash plays
   - Fail message prints
   - New randomized goal appears
4. Confirm arrow/status continue to work with new positions.

---

## Verification Checklist

- [ ] Timer end triggers transition routine (not instant print-only)
- [ ] Success/fail both have distinct flash colors
- [ ] Goal randomizes after each phase resolution
- [ ] Goal stays within camera-visible safe margins
- [ ] Guidance arrow still points correctly after randomization
- [ ] No script/runtime errors

---

## Expected Result

When timer reaches zero:
- If inside finish area: success transition + next phase setup
- If outside finish area: fail transition + retry setup
- In both cases, a visible flash plays and a new goal position is assigned.

---

## Next Step

When all checklist items are done, reply with:
**M6 Complete!**

Then we move to M7 (Basic Hazards - Neutron Fields).
