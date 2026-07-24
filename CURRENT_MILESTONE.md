# Current Milestone: M8 - Advanced Hazards (Repulsion/Attraction Fields)

## Goal
Introduce two new hazard types: repulsion and attraction fields. These fields will apply forces to the atom, pushing it away or pulling it in, creating new navigational challenges.

## Why This Matters
M7 introduced a simple probabilistic hazard. M8 adds physics-based hazards that directly affect player movement. This requires more skillful navigation and adds variety to the gameplay, moving beyond simple "stay out of the zone" mechanics.

## Prerequisites
- M7 complete (basic neutron field hazards)
- Player movement and physics are stable

---

## Step-by-Step Instructions

### Step 1: Create New Hazard Scenes/Types
1.  In `Scenes/`, you can either create new scenes for the new hazards or add them as variations in your existing hazard setup. Let's create distinct scenes for clarity.
2.  Create `ProtonField.tscn` and `ElectronField.tscn`.
3.  Both scenes will have an `Area2D` as the root node.
4.  Add a `CollisionShape2D` to each, similar to the `NeutronField`.
5.  Add distinct visuals for each field type. For example:
    *   `ProtonField`: A reddish hue or particles moving outward.
    *   `ElectronField`: A bluish hue or particles spiraling inward.

### Step 2: Implement Force-Application Logic
Instead of a kill chance, these fields will apply a force.

1.  In `Scripts/player.gd` (or wherever you handle player physics), add functions to apply forces.

    ```gdscript
    # In player.gd
    var external_force = Vector2.ZERO

    func _physics_process(delta):
        # ... existing movement code ...
        var total_force = velocity + external_force
        # Apply total_force
        # ...
        # Reset external force each frame
        external_force = Vector2.ZERO

    func apply_external_force(force: Vector2):
        external_force += force
    ```

2.  Create scripts for the new fields, `ProtonField.gd` and `ElectronField.gd`.

    **`ProtonField.gd`:**
    ```gdscript
    extends Area2D

    @export var repulsion_strength: float = 500.0

    func _physics_process(delta: float):
        var overlapping_bodies = get_overlapping_bodies()
        for body in overlapping_bodies:
            if body.is_in_group("player"):
                var direction_away = global_position.direction_to(body.global_position)
                body.apply_external_force(direction_away * repulsion_strength * delta)
    ```

    **`ElectronField.gd`:**
    ```gdscript
    extends Area2D

    @export var attraction_strength: float = 500.0

    func _physics_process(delta: float):
        var overlapping_bodies = get_overlapping_bodies()
        for body in overlapping_bodies:
            if body.is_in_group("player"):
                var direction_towards = body.global_position.direction_to(global_position)
                body.apply_external_force(direction_towards * attraction_strength * delta)
    ```
3.  Ensure your `player` node is in the "player" group.

### Step 3: Add New Hazards to the Game
In `Scenes/game.tscn`, instance a few of your new `ProtonField` and `ElectronField` scenes under the `Hazards` node. Place them strategically to create interesting navigational puzzles.

### Step 4: Refine Visual and Audio Feedback
1.  **Visuals**: Make sure the fields are easily distinguishable. Consider adding particle effects (`CPUParticles2D`) to show the direction of the force (outward for repulsion, inward for attraction).
2.  **Audio**: Add subtle, continuous sound effects when the player is inside one of these fields. Use `AudioStreamPlayer2D` in each field's scene. The volume could increase as the player gets closer to the center.

### Step 5: Balancing
Playtest the game and adjust the `repulsion_strength` and `attraction_strength` values. The forces should be strong enough to be a challenge but not so strong that they make the game unplayable. They should present a risk/reward, not a complete barrier.

### Step 6: Update Hazard Management
If you are spawning hazards procedurally in `game.gd`, update your logic to include the new hazard types. You can use an array of hazard scenes to pick from.

```gdscript
# In game.gd
@export var hazard_scenes: Array[PackedScene] = [
    preload("res://Scenes/NeutronField.tscn"),
    preload("res://Scenes/ProtonField.tscn"),
    preload("res://Scenes/ElectronField.tscn")
]

func spawn_random_hazard():
    var random_hazard_scene = hazard_scenes.pick_random()
    var new_hazard = random_hazard_scene.instantiate()
    # ... rest of the spawning logic
```

Good luck!
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
