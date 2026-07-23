# Current Milestone: M6 - Decay Animation, Chain Decay, and Game Over Flow

## Goal
Implement full phase resolution behavior:
- Success at timer end decays to the next isotope in the chain.
- Failure at timer end plays destroy animations and enters a slowed game-over state.
- New finish area positions are always far from the player so spawn-inside is impossible.

## Why This Matters
M5 established the timer + finish rule. M6 now makes outcome handling complete and explicit:
- Success advances progression.
- Failure creates consequence and player agency (Restart/Main Menu).
- Goal placement quality stays consistent and fair.

## Prerequisites
- M5 complete (finish area + in/out status + guidance arrow)
- M4 complete (timer + phase end signal)

---

## Step-by-Step Instructions

### Step 1: Add Transition + Game Over State in `Scripts/game.gd`
Add exports/state:

```gdscript
@export var transition_duration: float = 0.8
@export var game_over_time_scale: float = 0.22
@export var min_goal_edge_distance: float = 900.0
@export var max_goal_center_distance: float = 5200.0

var is_transitioning: bool = false
var is_game_over: bool = false
```

### Step 2: Add UI for Failure Choice in `Scenes/game.tscn`
Under `UI`, add a hidden fullscreen overlay:
- `ColorRect` named `GameOverOverlay`
- Dark translucent background
- Child `Panel` with:
  - `Label` title (`GameOverTitle`)
  - `Button` `RestartButton`
  - `Button` `MainMenuButton`

### Step 3: Cache and Wire Overlay Nodes in `Scripts/game.gd`
Add onready refs and connect button signals in `_ready()`:

```gdscript
@onready var game_over_overlay: ColorRect = $UI/GameOverOverlay
@onready var restart_button: Button = $UI/GameOverOverlay/GameOverPanel/RestartButton
@onready var main_menu_button: Button = $UI/GameOverOverlay/GameOverPanel/MainMenuButton
```

### Step 4: Keep Timer-End Split, But Remove Auto-Respawn on Fail
In `_on_atom_phase_timer_finished()`:
- inside finish area -> `start_phase_transition(true)`
- outside finish area -> `start_phase_transition(false)`

In fail branch inside `start_phase_transition(false)`:
1. play nuclei destroy animation
2. flash red
3. enter game over state

Do **not** call restart automatically.

### Step 5: Slow Time + Show Choice on Failure
Add `enter_game_over_state()`:

```gdscript
func enter_game_over_state() -> void:
is_game_over = true
Engine.time_scale = game_over_time_scale
game_over_overlay.visible = true
```

### Step 6: Implement Restart and Main Menu Actions
- `Restart`:
  - hide overlay
  - restore `Engine.time_scale = 1.0`
  - restart current isotope phase (new timer + new visuals + new far goal)
- `Main Menu`:
  - if `res://Scenes/main_menu.tscn` exists, change scene
  - otherwise exit gracefully (temporary fallback)

### Step 7: Success Must Decay to Next Isotope in Chain
In `advance_to_next_phase()`:
1. read current isotope from `IsotopeData`
2. get `next_isotope`
3. set `atom.isotope_key` to `next_isotope` when present
4. reload isotope data + respawn nuclei visuals

### Step 8: Enforce Far Goal Randomization
Replace viewport-local randomization with radial randomization around player:
- minimum center distance = `goal_radius + min_goal_edge_distance`
- random direction + random radius
- retry several attempts

This guarantees the player cannot start inside the finish area.

### Step 9: Preserve Existing Guidance/Status Rules
While transitioning or game over:
- hide arrow guidance
- keep finish status visible

### Step 10: Run and Validate
1. Press F5.
2. Success case (inside area at timer=0):
   - green flash
   - atom decays to next isotope in chain
   - new far finish area appears
3. Failure case (outside area at timer=0):
   - nuclei destroy animation plays
   - red flash
   - game slows down
   - game-over overlay appears with Restart/Main Menu
   - no auto-respawn
4. Press Restart:
   - game returns to normal speed
   - current isotope restarts
   - new finish area is far from player
5. Verify player never starts inside finish area.

---

## Verification Checklist

- [ ] Success path decays to `next_isotope`
- [ ] Fail path does not auto-respawn
- [ ] Fail path plays destroy animation on all nuclei
- [ ] Fail path enters slowed game-over state
- [ ] Game-over overlay shows Restart/Main Menu
- [ ] Restart restores normal speed and restarts phase
- [ ] Main Menu action works (scene switch or fallback exit)
- [ ] Goal is always spawned far from player
- [ ] Player never starts inside finish area
- [ ] No script/runtime errors

---

## Expected Result

At timer end:
- Inside area -> transition flash + isotope decays to next chain entry + new far goal.
- Outside area -> destroy animation + red flash + slowed game-over screen with player choice.

---

## Next Step

When checklist is fully validated, reply with:
**M6 Complete!**

Then move to M7 (Basic Hazards - Neutron Fields).
