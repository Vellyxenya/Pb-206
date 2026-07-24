# PB-206 Implementation Plan
**Project:** Nuclear Decay Chain Roguelike  
**Engine:** Godot 4  
**Timeline:** 3 days with incremental milestones  
**Experience Level:** First Godot project - guided step-by-step

## Overview
This plan breaks down the project into **13 milestones** that build on each other. Each milestone is small, testable, and has clear success criteria. We verify each milestone works before moving to the next.

---

## Milestone Structure
Each milestone includes:
- **Goal:** What we're building
- **Why:** How it fits into the game
- **Prerequisites:** What must be done first
- **Steps:** Detailed instructions with UI guidance
- **Verification:** How to test it works
- **Expected Result:** What you should see/experience

---

## Milestone 0: Project Setup ✓
**Goal:** Create a new Godot 4 project and verify it runs

**Steps:**
1. Open Godot 4
2. Create new project named "pb-206"
3. Set up basic project structure:
   - Create folders: `Scenes/`, `Scripts/`, `Assets/`
4. Create and run a test scene
5. Verify the project opens and runs without errors

**Verification:**
- Project opens in Godot 4 without errors
- Can run an empty scene (see blue/gray default background)
- Folders are created and visible in FileSystem panel

**Expected Result:** Empty window with default background when you press F5 (Run Project)

---

## Milestone 1: Atom with Nucleus Sprites
**Goal:** Create an atom composed of multiple animated nucleus sprites arranged in a disk pattern

**Why:** This establishes the core visual system where each atom (player or NPC) is made of individual nucleus sprites. The number of nuclei scales with mass (mass - 200), creating dramatic visual differences between heavy and light atoms.

**Prerequisites:** M0 complete, nucleus spritesheet (4×4 grid) in Assets folder

**Architecture:**
```
Atom (Node2D)
├── Nucleus 1 (AnimatedSprite2D)
├── Nucleus 2 (AnimatedSprite2D)
└── ... (38 nuclei for U-238)
```

**Detailed Steps:**
1. Import nucleus spritesheet into Assets folder
   - 4×4 grid (16 frames)
   - Row 1 (frames 0-3): Spawn animation ← Use this in M1
   - Set Filter to "Nearest" for crisp pixels
2. Create **nucleus.tscn**:
   - New 2D Scene, root named "Nucleus"
   - Add child: AnimatedSprite2D
   - Create SpriteFrames resource
   - Configure "spawn" animation with frames 0-3
   - Set animation speed to 8 FPS
   - Enable "Autoplay on Load" and "Playing"
3. Save as `Scenes/nucleus.tscn`
4. Create **atom.tscn**:
   - New 2D Scene, root named "Atom"
   - Attach script: `Scripts/atom.gd`
5. Write spawning code in atom.gd:
   - Preload nucleus scene
   - Calculate nucleus count: `mass_number - 200`
   - Spawn nuclei in disk pattern using polar coordinates
   - Random angle + sqrt(randf()) * radius for uniform distribution
6. Create **game.tscn**:
   - New 2D Scene, root named "Game"
   - Instance atom.tscn as child
7. Set game.tscn as main scene
8. Configure Atom properties in Inspector:
   - Isotope Name: "U-238"
   - Mass Number: 238 (creates 38 nuclei)
   - Disk Radius: 60.0

**Code for atom.gd:**
```gdscript
extends Node2D

const NucleusScene = preload("res://Scenes/nucleus.tscn")

@export var isotope_name: String = "U-238"
@export var mass_number: int = 238
@export var disk_radius: float = 60.0

func _ready():
	spawn_nuclei()

func spawn_nuclei():
	var nucleus_count = mass_number - 200
	print("Spawning ", nucleus_count, " nuclei for ", isotope_name)
	
	for i in range(nucleus_count):
		var nucleus = NucleusScene.instantiate()
		var angle = randf() * TAU
		var distance = sqrt(randf()) * disk_radius
		var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
		nucleus.position = pos
		add_child(nucleus)
```

**Verification:**
- Run game (F5)
- See 38 animated nucleus sprites in a disk pattern
- Each nucleus cycles through spawn animation (4 frames)
- Output panel shows: "Spawning 38 nuclei for U-238"
- Change mass_number to 206 (Pb-206) → See only 6 nuclei (dramatic difference!)

**Expected Result:** Circular cluster of 38 animated nuclei, spread across ~60 pixel radius disk

---

## Milestone 2: Mouse Following Movement
**Goal:** Atom accelerates toward mouse cursor position with physics-based movement

**Why:** Core movement mechanic - the atom follows the mouse with inertia. All nuclei move together as one rigid unit.

**Prerequisites:** M1 complete (atom with nucleus sprites)

**Detailed Steps:**
1. Open `Scenes/atom.tscn`
2. Change root from Node2D to **RigidBody2D**
   - Right-click Atom node > Change Type > search "RigidBody2D"
3. Set RigidBody2D properties in Inspector:
   - Gravity Scale: 0 (no gravity in space)
   - Lock Rotation: ON (atom doesn't spin)
4. Add CollisionShape2D as child of Atom (before nuclei spawn)
   - Add child node: CollisionShape2D
   - In Inspector, create CircleShape2D resource
   - Adjust radius to encompass nuclei disk (~disk_radius)
5. Update `Scripts/atom.gd` to add movement code
6. Run and test - atom follows mouse, nuclei move as one unit

**Updated atom.gd code:**
```gdscript
extends RigidBody2D  # Changed from Node2D

const NucleusScene = preload("res://Scenes/nucleus.tscn")

@export var isotope_name: String = "U-238"
@export var mass_number: int = 238
@export var disk_radius: float = 60.0
@export var acceleration_force := 500.0

func _ready():
	# Set physics mass based on isotope
	mass = mass_number - 200
	spawn_nuclei()

func _physics_process(delta):
	# Get mouse position
	var mouse_pos = get_global_mouse_position()
	
	# Calculate direction to mouse
	var direction = (mouse_pos - global_position).normalized()
	
	# Apply force toward mouse
	apply_central_force(direction * acceleration_force)

func spawn_nuclei():
	var nucleus_count = mass_number - 200
	print("Spawning ", nucleus_count, " nuclei for ", isotope_name)
	
	for i in range(nucleus_count):
		var nucleus = NucleusScene.instantiate()
		var angle = randf() * TAU
		var distance = sqrt(randf()) * disk_radius
		var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
		nucleus.position = pos
		add_child(nucleus)
```

**Verification:**
- Run game (F5)
- Move mouse around screen
- Atom accelerates toward mouse cursor
- Atom drifts with inertia (doesn't stop instantly)
- Atom doesn't rotate

**Expected Result:** Circle follows mouse smoothly with physics-based motion

---

## Milestone 3: Mass-Based Movement (Data-Driven)
**Goal:** Create isotope data structure and use (mass-200) scaling

**Why:** Different isotopes need different movement feel. Heavy atoms move slower.

**Prerequisites:** M2 complete

**Detailed Steps:**
1. Create `Scripts/isotope_data.gd` - an autoload singleton
2. Define isotope dictionary with U-238 data
3. Load isotope data in Player script
4. Set mass based on (atomic_mass - 200)
5. Adjust sprite scale based on mass
6. Test with U-238 (should feel heavy)

**Code for isotope_data.gd:**
```gdscript
extends Node

var isotope_data = {
	"U-238": {
		"name": "Uranium-238",
		"mass": 238,
		"decay_type": "alpha",
		"next_isotope": "Th-234",
		"timer_range": [90, 120],
		"initial_charge": 0,
		"sprite_color": Color(0.2, 0.8, 0.3)  # green
	},
	# More isotopes will be added later
}

func get_isotope(isotope_name: String) -> Dictionary:
	return isotope_data.get(isotope_name, {})
```

**Steps to add autoload:**
1. Project > Project Settings > Autoload tab
2. Path: `res://Scripts/isotope_data.gd`
3. Name: IsotopeData
4. Click Add

**Update player.gd:**
```gdscript
extends RigidBody2D

@export var acceleration_force := 500.0
var current_isotope := "U-238"
var isotope_info: Dictionary

func _ready():
	load_isotope(current_isotope)

func load_isotope(isotope_name: String):
	isotope_info = IsotopeData.get_isotope(isotope_name)
	
	# Set mass using (mass - 200) scaling
	var effective_mass = isotope_info.mass - 200
	mass = effective_mass
	
	# Set sprite scale based on mass
	$Sprite2D.scale = Vector2.ONE * (effective_mass / 20.0)
	
	# Set sprite color
	$Sprite2D.modulate = isotope_info.sprite_color

func _physics_process(delta):
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	apply_central_force(direction * acceleration_force)
```

**Verification:**
- Run game
- Atom should be green (U-238 color)
- Atom should be larger (mass 38 → scale 1.9)
- Atom should feel sluggish/heavy when following mouse

**Expected Result:** Large green atom that moves slowly with high momentum

---

## Milestone 4: Phase Timer System
**Goal:** Display countdown timer that triggers when it reaches zero

**Why:** Each phase has a decay timer - this is core to the countdown mechanic.

**Prerequisites:** M3 complete

**Detailed Steps:**
1. Add Timer node to Player
2. Create UI layer for countdown display
3. Implement phase timer logic
4. Display time remaining on screen
5. Test timer countdown

**Verification:**
- Timer counts down from 90-120 seconds (random)
- Time displays on screen (e.g., "1:45")
- When timer hits zero, something happens (print message for now)

**Expected Result:** Visible countdown timer that reaches zero

---

## Milestone 5: Goal Area System
**Goal:** Green circle appears in random location, detect when player enters

**Why:** Players must reach the goal area before timer expires.

**Prerequisites:** M4 complete

**Detailed Steps:**
1. Create `Scenes/goal_area.tscn`
2. Use Area2D with CircleShape2D collision
3. Add visual indicator (large green circle)
4. Spawn in random location
5. Detect player entry with `body_entered` signal
6. Track `goal_reached` flag
7. Test detection

**Verification:**
- Large green circle appears somewhere on screen at game start
- When player atom enters green circle, console prints "Goal reached!"
- Green circle stays visible
- Can enter/exit repeatedly

**Expected Result:** Green goal zone that detects player entry

---

## Milestone 6: Win/Lose Conditions
**Goal:** Game ends if timer expires without reaching goal, or if goal reached

**Why:** Establishes the core pass/fail mechanic for each phase.

**Prerequisites:** M5 complete

**Detailed Steps:**
1. Check `goal_reached` flag when timer expires
2. If `false`: trigger game over
3. If `true`: allow phase to continue (later: transition)
4. Display simple win/lose message
5. Add restart capability

**Verification:**
- If you don't reach goal before timer: "Game Over" message
- If you reach goal: "Goal Reached! Waiting for decay..."
- Can restart game after game over

**Expected Result:** Clear feedback on success/failure

---

## Milestone 7: Basic Hazards (Neutron Fields)
**Goal:** Red death zones that end the game on contact

**Why:** First hazard type - establishes permadeath mechanic.

**Prerequisites:** M6 complete

**Detailed Steps:**
1. Create `Scenes/neutron_field.tscn` (Area2D)
2. Red circular visual indicator
3. Detect collision with player
4. Trigger game over on contact
5. Place 2-3 fields in test level
6. Test collision

**Verification:**
- Red glowing circles appear in level
- Touching any red circle → instant game over
- Can navigate around them successfully

**Expected Result:** Red hazard zones that kill on contact

---

## Milestone 8: Attraction and repulsion fields

---

## Milestone 9: Complete Isotope Data
**Goal:** Add all 14 isotopes to the data structure

**Why:** Prepares for full decay chain implementation.

**Prerequisites:** M8 complete

**Detailed Steps:**
1. Open `isotope_data.gd`
2. Add entries for all 14 isotopes (I'll provide the complete data)
3. Verify data structure is correct
4. Test loading different isotopes (manually change current_isotope)

**Verification:**
- Can manually change to any isotope name
- Each isotope shows different color
- Each isotope has different size
- Each isotope has different mass (movement feel)

**Expected Result:** All 14 isotopes defined and loadable

---

## Milestone 10: Scoring System
**Goal:** Track points for pickups and goal area time

**Detailed Steps:**
1. Create score variable
2. Add score display UI
3. Award points for entering goal (+50)
4. Award points per second in goal (+5/sec)
5. Create simple collectibles (photons, electrons)
6. Award points for collecting items (+5, +10)

**Verification:**
- Score displays on screen
- Score increases when entering goal area
- Score increases over time while in goal
- Score increases when collecting items

**Expected Result:** Working score system with multiple sources

---

## Milestone 11: Electric Fields & Charge
**Goal:** Add charged state and electric field interactions. To do this update the ProtonField and ElectronField to only work on charged atoms. Also need to display the current charge visually on the atom. And also need to display the name of the current atom on top of the atom.

**Why:** Core physics-based navigation mechanic.

**Prerequisites:** M11 complete

**Detailed Steps:**
1. Add `charge` variable to player (0 or +1)
2. After β-decay, set charge = 1
3. Create electric field plates (Area2D)
4. Apply force to charged atoms in field
5. Neutral atoms unaffected
6. Test navigation with fields

**Verification:**
- Start as U-238 (neutral) → fields don't affect
- Decay to Th-234 (β-decay) → becomes charged
- Electric fields push/pull charged atom
- Can use fields to navigate around hazards

**Expected Result:** Fields affect movement based on charge state