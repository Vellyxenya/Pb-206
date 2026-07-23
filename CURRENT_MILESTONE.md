# Current Milestone: M7 - Basic Hazards (Neutron Fields)

## Goal
Add the first hazard type: neutron fields embedded directly in the existing game scene.

## Why This Matters
M6 completed phase outcomes and game-over flow. M7 introduces risk during navigation so reaching the finish area is no longer only a movement/time challenge. Instead of constant damage, hazard pressure is now event-based: each bleep is a high-stakes moment.

## Prerequisites
- M6 complete (success/fail resolution, game over UI, restart flow)
- Goal system and timer system working

---

## Step-by-Step Instructions

### Step 1: Add Hazards In Existing Scene
Do **not** create a new scene. Add hazards directly to `Scenes/game.tscn`:
1. Under `Game`, add `Node2D` named `Hazards`
2. Add one `Area2D` child template named `NeutronField`
3. Give it a `CollisionShape2D` with `CircleShape2D`
4. Add simple visual children (`Polygon2D`/`Line2D`/`Sprite2D`)
5. Duplicate this in-scene field or instantiate extra `Area2D` fields from `game.gd`

### Step 2: Create Hazard Script
Implement hazard logic inside `Scripts/game.gd` (or lightweight helper script) with periodic bleeps:

```gdscript
@export var neutron_bleep_interval: float = 2.0
@export var neutron_kill_chance: float = 0.28

var _bleep_time_left: float = 0.0

func _physics_process(delta: float) -> void:
_bleep_time_left -= delta
if _bleep_time_left > 0.0:
return

_bleep_time_left = neutron_bleep_interval
run_neutron_bleep()

func run_neutron_bleep() -> void:
# For each neutron field, if atom is inside at bleep time:
#   - roll RNG
#   - on fail: trigger game over flow
#   - on survive: show floating "I got lucky"
```

### Step 3: Add In-Field Check Helper
In `Scripts/game.gd`, add a helper to test whether atom is inside a field at bleep time:

```gdscript
func is_atom_inside_field(field: Area2D) -> bool:
if atom == null or field == null:
return false
for body in field.get_overlapping_bodies():
if body == atom:
return true
return false
```

### Step 4: Bleep Resolution Rule
During each bleep for each field:
1. If atom is not inside: nothing happens
2. If atom is inside:
  - Roll random chance
  - If roll <= `neutron_kill_chance`: trigger existing M6 failure/game-over flow
  - Else: player survives and gets visual feedback

### Step 5: Add "I got lucky" Floating Feedback
In `Scenes/game.tscn`, under `UI`, add a label for transient hazard feedback:
- `LuckyPopupLabel` (initially hidden)

In `Scripts/game.gd`, add a helper like:

```gdscript
func show_lucky_popup(world_pos: Vector2) -> void:
# Set text: "I got lucky"
# Position near player or above field
# Tween upward and fade alpha to 0
# Hide/reset after tween
```

### Step 6: Hazard Placement in Current Scene
If hazards are generated dynamically in `game.gd`, keep safe placement rules:
- Keep away from atom spawn
- Keep away from finish area center
- Keep inside broad play band around player
- Retry random samples up to N attempts

If hazards are manually authored in `game.tscn`, ensure they are not placed on the initial player spawn.

### Step 7: Add Hazard UI Feedback
Keep existing timer/status labels.
Add short bleep feedback states:
- Optional text when a field bleeps while player is outside (for debugging)
- Mandatory floating `"I got lucky"` when player survives a lethal roll

### Step 8: Respawn Hazards on Phase Change
In both success and restart flows in `game.gd`:
- clear old hazards
- rebuild/reposition hazards after goal randomization (still within current scene flow)

### Step 9: Run and Validate
1. Press F5.
2. Enter neutron field and wait for a bleep.
3. Confirm chance-based resolution at bleep moment.
4. On survival, confirm `"I got lucky"` appears, moves upward, and fades out.
5. On fail, confirm M6 game-over path triggers correctly.
5. Confirm hazards respawn after success and restart.

---

## Verification Checklist

- [ ] `NeutronField` Area2D nodes exist in `Scenes/game.tscn` with collision
- [ ] Hazards are implemented in current scene flow (no separate hazard scene dependency)
- [ ] Hazards bleep every N seconds
- [ ] If inside on bleep: chance-based game-over roll is applied
- [ ] Surviving a lethal roll shows floating/fading `"I got lucky"`
- [ ] Timer-end behavior still follows M6 rules
- [ ] Hazards avoid spawning on top of player/goal
- [ ] Hazards respawn on phase transition/restart
- [ ] No script/runtime errors

---

## Expected Result

Neutron fields now create active danger through periodic bleep checks: being inside at bleep time can instantly end the run by chance, while lucky survivals produce visible floating feedback. M6 game-over and chain progression behavior remain intact.

---

## Next Step

When checklist is fully validated, reply with:
**M7 Complete!**

Then move to M8 (Containment Walls).
