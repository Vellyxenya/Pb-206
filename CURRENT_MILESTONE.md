# Current Milestone: M5 - Goal Area System

## Goal
Add a target goal area on screen. The atom must reach it before the phase timer expires to advance the decay chain.

## Why This Matters
The goal area is the win condition for each phase. It creates the core loop: navigate atom to goal within time limit, trigger decay/transition on success.

## Prerequisites
- M4 complete (phase timer working)
- Visual representation of the atom on screen (nuclei visible)

---

## Step-by-Step Instructions

### Step 1: Add Goal Area State to Game Script
Open `Scripts/game.gd` and add these variables near the top after existing fields:

```gdscript
var goal_position: Vector2 = Vector2(720, 200)  # Top-center of screen
var goal_radius: float = 50.0
var goal_reached: bool = false
```

### Step 2: Add Goal Area Visualization
Open `Scenes/game.tscn` and add:
1. Child node of `UI`: `Node2D` named `GoalArea`
2. Add a script reference or use a ColorRect for now (we'll add proper visuals in M6)
3. For now, create a simple colored circle by adding a `ColorRect` child:
   - Name it `GoalMarker`
   - Set size to `(100, 100)`
   - Anchor preset: center (set offset to center the rect)
   - Add a custom shader material or just use a solid color (light green, RGB 0.3, 0.8, 0.3)
   - Set position to `(720, 200)`

### Step 3: Add Goal Detection Logic
In `Scripts/game.gd`, add a function to check if atom is in goal:

```gdscript
func check_goal_reached() -> bool:
if atom == null or goal_reached:
return false

var distance = atom.global_position.distance_to(goal_position)
if distance <= goal_radius:
goal_reached = true
on_goal_reached()
return true
return false
```

### Step 4: Add Goal Reached Handler
In `Scripts/game.gd`, add:

```gdscript
func on_goal_reached() -> void:
print("Goal reached! Phase complete early.")
atom.phase_active = false  # Stop the timer
if atom.has_method("on_phase_completed"):
atom.on_phase_completed()
```

### Step 5: Hook Detection Into Process Loop
In `Scripts/game.gd`, update `_process()` to call detection:

```gdscript
func _process(_delta):
if atom != null and background_material != null:
background_material.set_shader_parameter("world_offset", atom.global_position)

if atom != null and timer_label != null and atom.has_method("get_phase_time_left"):
timer_label.text = "Time: " + str(snapped(atom.get_phase_time_left(), 0.1))

# NEW: Check goal every frame
check_goal_reached()
```

### Step 6: Add Goal Reset Function
In `Scripts/game.gd`, add:

```gdscript
func reset_goal_for_new_phase() -> void:
goal_reached = false
# Goal position can stay fixed or randomize in M6
```

### Step 7: Update Atom Completion Handler
In `Scripts/atom.gd`, add a phase completion method (separate from timeout):

```gdscript
func on_phase_completed() -> void:
print("Phase completed successfully for ", isotope_name)
# Transition logic will be added in M10
```

### Step 8: Add Goal Area Update to Game
In `Scripts/game.gd`, add a function to move the goal marker with the goal state:

```gdscript
func _process(_delta):
# ... existing code ...

# Update visual goal marker position
var goal_marker = get_node_or_null("UI/GoalArea/GoalMarker") as Node2D
if goal_marker != null:
goal_marker.global_position = goal_position
```

### Step 9: Run and Validate
1. Press F5.
2. Confirm green circle (goal marker) appears top-center.
3. Move atom toward the goal (mouse positioning).
4. When atom nucleus touches goal area, confirm "Goal reached!" prints and timer stops.
5. Confirm both timer-expire and goal-reach paths work.

---

## Verification Checklist

- [ ] Goal position and radius defined in game.gd
- [ ] Goal area visual appears on screen (green circle)
- [ ] Goal detection checks distance each frame
- [ ] Goal reached before timer expires triggers early completion
- [ ] Timer still triggers finish event if goal not reached
- [ ] Both paths print confirmation messages
- [ ] No script/runtime errors

---

## Expected Result

When running the game:
- Green goal marker visible at top-center.
- Move atom to the goal within the time limit to win the phase.
- Phase ends either on timeout or goal reach (whichever comes first).
- Next milestone (M6) will add goal position randomization and decay animation.

---

## Next Step

When all checklist items are done, reply with:
**M5 Complete!**

Then we move to M6 (Decay Animation & Goal Randomization).
