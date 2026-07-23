# Current Milestone: M1 - Atom with Nucleus Sprites

## Goal
Create an atom made up of individual animated nucleus sprites arranged in a disk pattern.

## Why This Matters
This establishes our core visual system. Each atom (player or NPC) will be composed of multiple nucleus sprites. The number of nuclei = (mass - 200), creating a dramatic visual difference between heavy atoms like U-238 (38 nuclei) and light atoms like Pb-206 (6 nuclei).

## Prerequisites
- ✓ M0 Complete (Project exists with Scenes, Scripts, Assets folders)
- Project is open in Godot 4
- Nucleus spritesheet (4x4 grid) in Assets folder

---

## Architecture Overview

**What we're building:**
```
Atom (Node2D)
├── Nucleus 1 (AnimatedSprite2D) ──> spawns at random position in disk
├── Nucleus 2 (AnimatedSprite2D)
├── Nucleus 3 (AnimatedSprite2D)
└── ... (38 nuclei total for U-238)
```

**Spritesheet structure (4x4 grid, 16 frames):**
- **Row 1 (frames 0-3):** Spawn animation ← **We'll use this in M1**
- **Row 2 (frames 4-7):** Proton animation
- **Row 3 (frames 8-11):** Neutron animation
- **Row 4 (frames 12-15):** Destruction animation

---

## Step-by-Step Instructions

### Step 1: Import the Nucleus Spritesheet
First, let's make sure your spritesheet is properly imported.

1. In the **FileSystem panel** (bottom-left), navigate to **Assets** folder
2. You should see your nucleus spritesheet file (4x4 grid image)
3. **Click on the spritesheet file** to select it
4. Look at the **Import panel** (next to Scene panel on the left)
5. Verify these settings:
   - **Mode:** Should be "2D" or "Texture"
   - **Filter:** Set to **"Nearest"** (for pixel-art style, crisp pixels)
6. If you changed anything, click **"Reimport"** at the bottom

**✓ Checkpoint:** Spritesheet appears in Assets folder and preview shows in Inspector

---

### Step 2: Create the Nucleus Scene
Now we'll create a reusable nucleus scene with animation.

1. Click **Scene menu** > **New Scene**
2. Click **"2D Scene"** 
3. **Double-click** "Node2D" and rename it to: `Nucleus`

**What you'll see:** Scene panel shows "Nucleus" as the root node

---

### Step 3: Add AnimatedSprite2D to Nucleus
1. **Right-click** on "Nucleus" in the Scene panel
2. Select **"Add Child Node"** (or press Ctrl+A)
3. In the search box, type: `AnimatedSprite2D`
4. **Double-click** "AnimatedSprite2D" in the results

**What you'll see:**
```
Nucleus
└── AnimatedSprite2D
```

**Why AnimatedSprite2D?** Unlike Sprite2D, this node can play frame-based animations from spritesheets!

---

### Step 4: Create SpriteFrames Resource
AnimatedSprite2D needs a SpriteFrames resource to define animations.

1. Select **AnimatedSprite2D** in the Scene panel
2. In the **Inspector panel** (right side), find **"Sprite Frames"** property
3. Click the dropdown that says **"[empty]"**
4. Select **"New SpriteFrames"**

**What you'll see:** The property now shows a SpriteFrames resource icon

5. **Click on the SpriteFrames icon** (or the newly created resource text)

**What happens:** The **SpriteFrames editor panel** opens at the bottom (replacing FileSystem)

**✓ Checkpoint:** Bottom panel now shows SpriteFrames editor with "default" animation

---

### Step 5: Configure Spawn Animation
Now we'll set up the spawn animation using the top row of your spritesheet.

**In the SpriteFrames editor panel (bottom):**

1. You'll see a "default" animation in the left list
2. **Double-click** "default" and rename it to: `spawn`
3. Press **Enter**

**Now add frames:**

4. Click the **"Add frames from sprite sheet"** button (grid icon with +)
5. In the file dialog:
   - Navigate to **Assets** folder
   - Select your **nucleus spritesheet** file
   - Click **Open**

**Sprite sheet configuration dialog appears:**

6. Set these values:
   - **Horizontal:** `4`
   - **Vertical:** `4`
   - **Size:** Should auto-detect (if not, set based on your image dimensions)

7. Click **OK**

**What you'll see:** A grid showing all 16 frames (4x4)

8. **Select only the top row (frames 0-3):**
   - Click frame 0 (top-left)
   - Hold **Shift** and click frame 3 (top-right of first row)
   - All 4 frames should be highlighted

9. Click **"Add [4] Frame(s)"** button at the bottom

**What you'll see:** The spawn animation now has 4 frames in the timeline

10. Close the sprite sheet selector dialog

---

### Step 6: Set Animation Speed
Let's make the spawn animation play at a nice speed.

**In the SpriteFrames editor:**

1. Make sure "spawn" animation is selected
2. Look for **"Speed (FPS)"** setting at the bottom
3. Set it to: `8` (8 frames per second)

**✓ Checkpoint:** SpriteFrames editor shows spawn animation with 4 frames

---

### Step 7: Test the Nucleus Animation
Let's verify the animation works before moving on.

1. Select **AnimatedSprite2D** in the Scene panel
2. In the **Inspector**, find the **"Animation"** property
3. Set it to: `spawn`
4. Check the **"Autoplay on Load"** property (enable it)
5. Check the **"Playing"** property (enable it)

**View the animation:**

6. In the **viewport** (center), you should see the nucleus sprite
7. Look at the **Animation section** in Inspector - you might see it cycling through frames

---

### Step 8: Save the Nucleus Scene
1. Press **Ctrl+S**
2. Navigate to **Scenes** folder
3. Name: `nucleus.tscn`
4. Click **Save**

**✓ Checkpoint:** FileSystem shows `Scenes/nucleus.tscn`

---

### Step 9: Create the Atom Scene
Now let's create the atom that will hold multiple nuclei.

1. Click **Scene menu** > **New Scene**
2. Click **"2D Scene"**
3. Rename "Node2D" to: `Atom`

**Why "Atom" not "Player"?** Atoms can be players OR NPCs. We're building a reusable system!

---

### Step 10: Add Script to Atom
Time to write our first GDScript! This will spawn the nuclei.

1. With **Atom** selected, click the **"Attach Script"** icon (scroll icon with +)
   - Or right-click Atom > "Attach Script"
2. In the "Attach Node Script" dialog:
   - **Path:** Should be `res://Scripts/atom.gd`
   - If not, navigate to Scripts folder
   - **Template:** "Empty" (default is fine)
3. Click **"Create"**

**What happens:** Script editor opens showing `atom.gd`

---

### Step 11: Write the Nucleus Spawning Code
Copy this code into `atom.gd`:

```gdscript
extends Node2D

# Preload the nucleus scene so we can instantiate it
const NucleusScene = preload("res://Scenes/nucleus.tscn")

# Isotope configuration
@export var isotope_name: String = "U-238"
@export var mass_number: int = 238

# Visual configuration
@export var disk_radius: float = 60.0

func _ready():
	spawn_nuclei()

func spawn_nuclei():
	# Calculate number of nuclei: mass - 200
	var nucleus_count = mass_number - 200
	
	print("Spawning ", nucleus_count, " nuclei for ", isotope_name)
	
	# Spawn each nucleus at a random position within disk
	for i in range(nucleus_count):
		var nucleus = NucleusScene.instantiate()
		
		# Random position within a disk (polar coordinates)
		var angle = randf() * TAU  # TAU = 2*PI (full circle)
		var distance = sqrt(randf()) * disk_radius  # sqrt for uniform distribution
		
		var pos = Vector2(
			cos(angle) * distance,
			sin(angle) * distance
		)
		
		nucleus.position = pos
		add_child(nucleus)
```

**What this code does:**
- Defines isotope properties (name, mass number)
- Calculates nucleus count using formula: `mass - 200`
- For U-238: 238 - 200 = 38 nuclei
- Spawns each nucleus at a random position within a disk
- Uses polar coordinates (angle + distance) for even distribution

4. Press **Ctrl+S** to save the script

**✓ Checkpoint:** Scripts folder now has `atom.gd`

---

### Step 12: Save the Atom Scene
1. Switch back to the atom scene tab (if you're in the script editor, click "2D" at the top)
2. Press **Ctrl+S**
3. Navigate to **Scenes** folder
4. Name: `atom.tscn`
5. Click **Save**

**✓ Checkpoint:** FileSystem shows `Scenes/atom.tscn` and `Scripts/atom.gd`

---

### Step 13: Create Main Game Scene
Now we need a main game scene to hold our atom.

1. Click **Scene menu** > **New Scene**
2. Click **"2D Scene"**
3. Rename "Node2D" to: `Game`

---

### Step 14: Instance the Atom in Game Scene
1. With **Game** node selected:
   - Click the **chain-link icon** 🔗 at top of Scene panel ("Instantiate Child Scene")
   - Or right-click "Game" > "Instantiate Child Scene"
2. Navigate to **Scenes** folder
3. Select **atom.tscn**
4. Click **Open**

**What you'll see:**
```
Game
└── Atom
```

---

### Step 15: Configure the Atom Properties
Let's set up U-238 for testing (38 nuclei).

1. Select the **Atom** instance in the Scene panel
2. In the **Inspector**, you'll see exported properties:
   - **Isotope Name:** `U-238` (already set)
   - **Mass Number:** `238` (already set)
   - **Disk Radius:** `60.0` (you can adjust this)

**These values are editable in Inspector because we used `@export` in the script!**

---

### Step 16: Save Game Scene and Set as Main
1. Press **Ctrl+S**
2. Navigate to **Scenes** folder
3. Name: `game.tscn`
4. Click **Save**

Set as main scene:

5. **Project menu** > **Project Settings**
6. **Application > Run** section
7. **Main Scene** > Click **"Select Current"**
8. Click **Close**

---

### Step 17: Run and Test!
Time to see your atom with 38 animated nuclei!

1. Press **F5** (or click Play ▶ button)

**What you should see:**
- Game window opens
- 38 animated nucleus sprites arranged in a disk pattern
- Each nucleus playing the spawn animation (cycling through 4 frames)
- Nuclei don't move (that's correct for now!)

2. Look at the **Output panel** (bottom) - you should see:
   ```
   Spawning 38 nuclei for U-238
   ```

3. Press **F8** to stop

---

### Step 18: Experiment with Different Isotopes (Optional)
Let's see the visual difference between heavy and light atoms!

1. Open **game.tscn** 
2. Select the **Atom** instance
3. In **Inspector**, change:
   - **Isotope Name:** `Pb-206`
   - **Mass Number:** `206`

4. Press **F5** to run

**What you should see:** Only 6 nuclei (206 - 200 = 6) - much smaller atom!

5. Try U-238 again to see the difference

---

## Verification Checklist

Check off each item:
- [ ] Nucleus spritesheet imported in Assets folder
- [ ] Nucleus scene created with AnimatedSprite2D
- [ ] SpriteFrames configured with spawn animation (4 frames)
- [ ] Nucleus scene saved as `Scenes/nucleus.tscn`
- [ ] Atom scene created with Node2D root
- [ ] atom.gd script created with spawning code
- [ ] Atom scene saved as `Scenes/atom.tscn`
- [ ] Game scene created with Atom instanced
- [ ] Game scene set as main scene
- [ ] Running game shows 38 animated nuclei for U-238
- [ ] Output panel shows "Spawning 38 nuclei for U-238"
- [ ] Nuclei are arranged in disk pattern (not all in center)
- [ ] Each nucleus is animating (cycling through frames)

---

## Expected Result

✓ **When you press F5 with U-238:**
- 38 animated nucleus sprites appear
- Arranged in a circular disk pattern (radius ~60 pixels)
- Each nucleus cycles through the spawn animation
- Output console shows "Spawning 38 nuclei for U-238"

✓ **When you change to Pb-206 and run:**
- Only 6 nucleus sprites appear (dramatic visual difference!)
- Smaller, more compact atom

✓ **Nucleus animation:**
- Each sprite smoothly cycles through 4 frames
- Animation loops continuously


---

## If Something Went Wrong

**Problem:** "Can't see nucleus sprites / nothing appears"
- **Solution:** 
  - Check Output panel for "Spawning X nuclei" message
  - Verify nucleus.tscn has AnimatedSprite2D with SpriteFrames configured
  - Check that spritesheet is in Assets folder
  - Try zooming out in viewport (mouse wheel)
  - Select Atom in Game scene, check Inspector shows mass_number = 238

**Problem:** "Nuclei aren't animating / static image"
- **Solution:**
  - Open nucleus.tscn
  - Select AnimatedSprite2D
  - In Inspector, verify "Autoplay on Load" is checked
  - Verify "Playing" is checked
  - Check Animation is set to "spawn"

**Problem:** "All nuclei appear in the center / not spread out"
- **Solution:**
  - Check atom.gd code copied correctly (especially the position calculation)
  - Verify disk_radius is not 0 (should be 60.0)
  - Try increasing disk_radius to 100 in Inspector

**Problem:** "Script error / won't run"
- **Solution:**
  - Check Output panel for error message
  - Verify preload path: `"res://Scenes/nucleus.tscn"` (exact capitalization)
  - Make sure nucleus.tscn is saved before running
  - Check that script is attached to Atom node (script icon should appear next to node)

**Problem:** "Can't see the SpriteFrames editor panel"
- **Solution:**
  - Click on the SpriteFrames resource in Inspector
  - Or: Bottom panel tabs - click "SpriteFrames" if it's there
  - Try closing and reopening nucleus.tscn

**Problem:** "Spritesheet shows wrong frames / all black"
- **Solution:**
  - Reselect frames 0-3 only (top row)
  - Verify grid is 4x4
  - Check spritesheet imported correctly (click it in Assets, check Import panel)
  - Reimport with Filter = "Nearest"

**Problem:** "Only see 1 nucleus instead of 38"
- **Solution:**
  - Check Output panel - does it say "Spawning 38 nuclei"?
  - If yes but only see 1: nuclei might be overlapping perfectly (rare but possible)
  - Try running again (random positions)
  - Check the Scene panel while running - you should see 38 child nodes under Atom

---

## Understanding What We Built

**Scene Hierarchy:**
```
game.tscn
└── Game (Node2D)
    └── Atom (instanced from atom.tscn)
        ├── Nucleus (instanced from nucleus.tscn) [spawned at runtime]
        ├── Nucleus
        ├── Nucleus
        └── ... (38 total for U-238)
```

**Node types used:**
- **Node2D**: Basic 2D node with position, rotation, scale
- **AnimatedSprite2D**: Plays frame-based animations from spritesheets
- **SpriteFrames**: Resource that defines animations and their frames

**Key GDScript concepts:**
- **`preload()`**: Loads a scene at compile time (faster than load())
- **`.instantiate()`**: Creates a new instance of a scene
- **`add_child()`**: Adds a node as a child (becomes part of scene tree)
- **`@export`**: Makes a variable editable in the Inspector
- **`randf()`**: Random float between 0 and 1
- **`TAU`**: Built-in constant = 2*PI (full circle in radians)

**Why polar coordinates for positioning?**
```gdscript
angle = randf() * TAU              # Random angle (0 to 360°)
distance = sqrt(randf()) * radius  # Random distance (0 to radius)
```
Using `sqrt(randf())` ensures **uniform distribution** in the disk. Without sqrt, nuclei would cluster toward the center!

**The mass formula:**
```
nucleus_count = mass_number - 200
```
- U-238: 238 - 200 = **38 nuclei** (large, dramatic)
- Pb-206: 206 - 200 = **6 nuclei** (small, compact)
- This creates a 6× visual difference between heavy and light atoms!

---

## Code Explanation: atom.gd

Let's break down the spawning code:

```gdscript
const NucleusScene = preload("res://Scenes/nucleus.tscn")
```
Loads the nucleus scene once at startup (efficient!)

```gdscript
@export var mass_number: int = 238
```
`@export` makes this editable in Inspector - you can change it per-instance!

```gdscript
var nucleus_count = mass_number - 200
```
Our core formula: more mass = more nuclei

```gdscript
for i in range(nucleus_count):
    var nucleus = NucleusScene.instantiate()
```
Creates 38 separate nucleus instances (for U-238)

```gdscript
var angle = randf() * TAU
var distance = sqrt(randf()) * disk_radius
```
Polar coordinates: random angle + random distance = uniform disk distribution

```gdscript
var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
```
Converts polar (angle, distance) to Cartesian (x, y)

```gdscript
nucleus.position = pos
add_child(nucleus)
```
Places nucleus at position and adds to scene tree

---

## Visual Reference

**U-238 (38 nuclei) vs Pb-206 (6 nuclei):**
```
U-238:                    Pb-206:
   • • • • •                • •
  • • • • • •              • • •
 • • • • • • •              • •
  • • • • • •
   • • • • •
```

**Spritesheet Layout (4x4 grid):**
```
[0][1][2][3]  ← Row 1: Spawn (M1 uses this)
[4][5][6][7]  ← Row 2: Proton
[8][9][10][11] ← Row 3: Neutron
[12][13][14][15] ← Row 4: Destruction
```

---

## What's Next in M2?

In M2, we'll add:
- **RigidBody2D** physics to the atom
- **Mouse-following movement** with forces
- **CollisionShape2D** for physics interactions
- The atom will move and follow your cursor!

The nucleus system you just built will move as one unit with the atom. All 38 nuclei will stay in formation! 🚀

---

## Next Steps

Once all checkboxes are checked:
1. Tell me **"M1 Complete!"**
2. I'll update the progress tracker
3. We'll move to **Milestone 2: Mouse Following Movement**

---

## Questions?

Ask me anything! Common questions:
- **"Why Node2D for Atom root?"** → We'll upgrade to RigidBody2D in M2 for physics
- **"Can I change the disk_radius?"** → Yes! Experiment with different values
- **"What if I want more/fewer nuclei?"** → Change mass_number in Inspector
- **"The spawn animation isn't visible"** → It loops fast! We'll add other animations later
- **"How do I add color variety?"** → We'll add isotope-specific colors in later milestones
- **"Can nuclei move independently?"** → Not in this game - they move as one atom unit
- **"I'm stuck at [step]"** → Tell me which step and what you see, I'll help!

**Remember:** Take your time with each step. Understanding instancing and scripting now will make everything else easier! 🔬✨

---
---

# 🎨 M1 Extensions - Visual & Data Improvements

Once you've completed the basic M1 milestone above, these extensions add polish and proper architecture before moving to M2.

---

## Extension 1: Nucleus Animation States (Proton vs Neutron)

### Goal
Distinguish between protons and neutrons visually by playing different idle animations.

### Why
Atoms are made of protons and neutrons. We can use the proton/neutron ratio to determine which animation each nucleus plays, creating visual variety.

---

### Step 1.1: Add Proton and Neutron Animations

1. Open `Scenes/nucleus.tscn`
2. Select the **AnimatedSprite2D** node
3. In the **Inspector**, click on the **SpriteFrames** resource to open the editor
4. In the **SpriteFrames panel** (bottom), you should see "spawn" animation

**Add Proton Animation:**

5. Click the **"+"** button next to the animation list (left side)
6. Name it: `proton`
7. Click **"Add frames from sprite sheet"** button
8. Select your nucleus spritesheet from Assets
9. Grid should still be 4×4
10. This time, select **Row 2 (frames 4-7)**
    - Click frame 4 (first frame of row 2)
    - Hold Shift, click frame 7 (last frame of row 2)
11. Click **"Add [4] Frame(s)"**
12. Set animation speed to **6 FPS**

**Add Neutron Animation:**

13. Click **"+"** again to add another animation
14. Name it: `neutron`
15. Click **"Add frames from sprite sheet"**
16. Select your nucleus spritesheet
17. Select **Row 3 (frames 8-11)**
    - Click frame 8, Shift+click frame 11
18. Click **"Add [4] Frame(s)"**
19. Set animation speed to **6 FPS**

**✓ Checkpoint:** SpriteFrames now has 3 animations: spawn, proton, neutron

---

### Step 1.2: Add Nucleus Script

Now we'll add logic to choose which animation to play.

1. With `nucleus.tscn` open, select the **Nucleus** root node
2. Click **"Attach Script"** icon (scroll with +)
3. Path: `res://Scripts/nucleus.gd`
4. Click **"Create"**

**Copy this code into nucleus.gd:**

```gdscript
extends Node2D

enum NucleusType { PROTON, NEUTRON }

@export var nucleus_type: NucleusType = NucleusType.PROTON

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Ensure sprite is centered (pivot at center, not top-left)
	sprite.centered = true
	
	# Play spawn animation first
	sprite.play("spawn")
	# After spawn completes, transition to idle animation
	sprite.animation_finished.connect(_on_spawn_finished)

func _on_spawn_finished():
	# Switch to proton or neutron idle animation
	if nucleus_type == NucleusType.PROTON:
		sprite.play("proton")
	else:
		sprite.play("neutron")

func set_type(type: NucleusType):
	nucleus_type = type
```

5. Press **Ctrl+S** to save

**✓ Checkpoint:** nucleus.gd created with animation logic

---

### Step 1.3: Update Atom Script to Assign Types

Now update atom.gd to assign proton/neutron types when spawning.

**Replace the spawn_nuclei() function in atom.gd with this:**

```gdscript
func spawn_nuclei():
	var nucleus_count = mass_number - 200
	print("Spawning ", nucleus_count, " nuclei for ", isotope_name)
	
	# Simple ratio: 50% protons, 50% neutrons
	# (In reality, the ratio varies per isotope - we'll improve this in Extension 2)
	var proton_count = nucleus_count / 2
	
	for i in range(nucleus_count):
		var nucleus = NucleusScene.instantiate()
		
		# Random position within a disk (polar coordinates)
		var angle = randf() * TAU
		var distance = sqrt(randf()) * disk_radius
		var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
		nucleus.position = pos
		
		# Assign type: first half are protons, second half are neutrons
		if i < proton_count:
			nucleus.set_type(nucleus.NucleusType.PROTON)
		else:
			nucleus.set_type(nucleus.NucleusType.NEUTRON)
		
		add_child(nucleus)
```

**✓ Checkpoint:** Run the game - nuclei should spawn, then transition to proton/neutron animations!

---

## Extension 2: Data-Driven Isotope Configuration

### Goal
Create a centralized data system for all isotope properties instead of hardcoding values.

### Why
Makes it easy to add/modify isotopes, ensures consistency, and prepares for the full decay chain.

---

### Step 2.1: Create IsotopeData Autoload

An "autoload" is a singleton script accessible from anywhere in the game.

1. In **FileSystem panel**, navigate to **Data** folder (create it if needed)
2. Right-click Data folder > **"New Script"**
3. In the Create Script dialog:
   - **Inherits:** Node (default)
   - **Template:** Empty
   - **Path:** `res://Data/IsotopeData.gd`
4. Click **"Create"**

**Copy this code into IsotopeData.gd:**

```gdscript
extends Node

# Centralized isotope data for all 14 decay chain isotopes
var isotopes = {
	"U-238": {
		"name": "Uranium-238",
		"mass_number": 238,
		"protons": 92,
		"neutrons": 146,
		"decay_type": "alpha",
		"next_isotope": "Th-234",
		"timer_range": [120, 180],  # 2-3 minutes
		"disk_radius": 70.0,
		"sprite_color": Color(0.2, 0.8, 0.3)  # green
	},
	"Th-234": {
		"name": "Thorium-234",
		"mass_number": 234,
		"protons": 90,
		"neutrons": 144,
		"decay_type": "beta",
		"next_isotope": "Pa-234",
		"timer_range": [90, 150],
		"disk_radius": 68.0,
		"sprite_color": Color(0.9, 0.5, 0.2)  # orange
	},
	"Pa-234": {
		"name": "Protactinium-234",
		"mass_number": 234,
		"protons": 91,
		"neutrons": 143,
		"decay_type": "beta",
		"next_isotope": "U-234",
		"timer_range": [60, 120],
		"disk_radius": 68.0,
		"sprite_color": Color(0.8, 0.3, 0.8)  # purple
	},
	"Pb-206": {
		"name": "Lead-206",
		"mass_number": 206,
		"protons": 82,
		"neutrons": 124,
		"decay_type": "stable",
		"next_isotope": null,
		"timer_range": [0, 0],
		"disk_radius": 50.0,
		"sprite_color": Color(0.6, 0.6, 0.7)  # silver/lead
	}
	# TODO: Add remaining 10 isotopes in later milestones
}

# Helper function to get isotope data
func get_isotope(isotope_key: String) -> Dictionary:
	if isotopes.has(isotope_key):
		return isotopes[isotope_key]
	else:
		push_error("Isotope not found: " + isotope_key)
		return {}

# Get nucleus count for an isotope
func get_nucleus_count(isotope_key: String) -> int:
	var data = get_isotope(isotope_key)
	if data.is_empty():
		return 6  # fallback
	return data.mass_number - 200

# Get proton count
func get_proton_count(isotope_key: String) -> int:
	var data = get_isotope(isotope_key)
	if data.is_empty():
		return 0
	return data.protons

# Get neutron count
func get_neutron_count(isotope_key: String) -> int:
	var data = get_isotope(isotope_key)
	if data.is_empty():
		return 0
	return data.neutrons
```

5. Press **Ctrl+S** to save

---

### Step 2.2: Register as Autoload

Now make IsotopeData globally accessible.

1. Click **Project menu** > **Project Settings**
2. Go to **Autoload** tab (left side)
3. Click the **folder icon** next to "Path"
4. Navigate to **Data** folder
5. Select **IsotopeData.gd**
6. Click **"Open"**
7. The Node Name should auto-fill as "IsotopeData"
8. Click **"Add"**
9. Click **"Close"**

**✓ Checkpoint:** IsotopeData is now accessible globally via `IsotopeData.get_isotope("U-238")`

---

### Step 2.3: Update Atom Script to Use Data

Replace atom.gd with this data-driven version:

```gdscript
extends Node2D

const NucleusScene = preload("res://Scenes/nucleus.tscn")

@export var isotope_key: String = "U-238"

var mass_number: int
var disk_radius: float
var isotope_name: String

func _ready():
	load_isotope_data()
	spawn_nuclei()

func load_isotope_data():
	var data = IsotopeData.get_isotope(isotope_key)
	if data.is_empty():
		push_error("Failed to load isotope: " + isotope_key)
		return
	
	isotope_name = data.name
	mass_number = data.mass_number
	disk_radius = data.disk_radius
	
	print("Loaded isotope: ", isotope_name, " (", mass_number, ")")

func spawn_nuclei():
	var proton_count = IsotopeData.get_proton_count(isotope_key)
	var neutron_count = IsotopeData.get_neutron_count(isotope_key)
	var nucleus_count = proton_count + neutron_count - 200  # mass - 200
	
	print("Spawning ", proton_count, " protons + ", neutron_count, " neutrons")
	
	var nuclei_spawned = 0
	
	# Spawn protons first
	for i in range(proton_count):
		if nuclei_spawned >= nucleus_count:
			break
		spawn_nucleus(nucleus.NucleusType.PROTON)
		nuclei_spawned += 1
	
	# Then spawn neutrons
	for i in range(neutron_count):
		if nuclei_spawned >= nucleus_count:
			break
		spawn_nucleus(nucleus.NucleusType.NEUTRON)
		nuclei_spawned += 1

func spawn_nucleus(type):
	var nucleus = NucleusScene.instantiate()
	
	# Random position within a disk (polar coordinates)
	var angle = randf() * TAU
	var distance = sqrt(randf()) * disk_radius
	var pos = Vector2(cos(angle) * distance, sin(angle) * distance)
	nucleus.position = pos
	
	nucleus.set_type(type)
	add_child(nucleus)
```

**✓ Checkpoint:** Run game - should work same as before, but now using centralized data!

**Test it:**
1. Select Atom in game.tscn
2. In Inspector, change **Isotope Key** to "Pb-206"
3. Run (F5) - should spawn only 6 nuclei with correct proton/neutron ratio!

---

## Extension 3: Hexagonal Grid Positioning

### Goal
Replace random disk positioning with structured hexagonal packing for cleaner, more organized atoms.

### Why
Hexagonal packing is how atoms naturally arrange (close-packing). It looks more professional and scientific while maintaining density.

---

### Step 3.1: Create Hex Grid Utility

1. Create a new script: `Scripts/Utilities/HexGrid.gd`
2. This will be a static utility class (no extends Node)

**Copy this code into HexGrid.gd:**

```gdscript
class_name HexGrid

# Hexagonal grid positioning utility
# Uses axial coordinates (q, r) for hex layout

static var HEX_RADIUS := 12.0  # Distance between hex centers

# Generate hexagonal ring positions around center
static func get_hex_ring(center: Vector2, ring: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	
	if ring == 0:
		positions.append(center)
		return positions
	
	# Hex directions (6 directions around center)
	var hex_directions = [
		Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1),
		Vector2(-1, 0), Vector2(0, -1), Vector2(1, -1)
	]
	
	# Start at a corner of the ring
	var q = ring
	var r = 0
	
	# Walk around the ring
	for direction in hex_directions:
		for step in range(ring):
			positions.append(hex_to_pixel(Vector2(q, r)))
			q += direction.x
			r += direction.y
	
	return positions

# Convert axial hex coordinates to pixel position
static func hex_to_pixel(hex: Vector2) -> Vector2:
	var x = HEX_RADIUS * (3.0 / 2.0 * hex.x)
	var y = HEX_RADIUS * (sqrt(3.0) / 2.0 * hex.x + sqrt(3.0) * hex.y)
	return Vector2(x, y)

# Get N positions in hexagonal pattern (fills from center outward)
static func get_hex_positions(count: int, center: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var ring = 0
	
	while positions.size() < count:
		var ring_positions = get_hex_ring(center, ring)
		for pos in ring_positions:
			positions.append(pos)
			if positions.size() >= count:
				break
		ring += 1
	
	return positions.slice(0, count)
```

3. Press **Ctrl+S** to save

**✓ Checkpoint:** HexGrid utility created

---

### Step 3.2: Update Atom Script to Use Hex Grid

Replace the `spawn_nucleus()` function in atom.gd:

```gdscript
func spawn_nuclei():
	var proton_count = IsotopeData.get_proton_count(isotope_key)
	var neutron_count = IsotopeData.get_neutron_count(isotope_key)
	var nucleus_count = proton_count + neutron_count - 200  # mass - 200
	
	print("Spawning ", proton_count, " protons + ", neutron_count, " neutrons")
	
	# Get hexagonal grid positions
	var hex_positions = HexGrid.get_hex_positions(nucleus_count, Vector2.ZERO)
	
	var nuclei_spawned = 0
	
	# Spawn protons first
	for i in range(proton_count):
		if nuclei_spawned >= nucleus_count:
			break
		var nucleus = NucleusScene.instantiate()
		nucleus.position = hex_positions[nuclei_spawned]
		nucleus.set_type(nucleus.NucleusType.PROTON)
		add_child(nucleus)
		nuclei_spawned += 1
	
	# Then spawn neutrons
	for i in range(neutron_count):
		if nuclei_spawned >= nucleus_count:
			break
		var nucleus = NucleusScene.instantiate()
		nucleus.position = hex_positions[nuclei_spawned]
		nucleus.set_type(nucleus.NucleusType.NEUTRON)
		add_child(nucleus)
		nuclei_spawned += 1
```

**✓ Checkpoint:** Run game - nuclei now arranged in beautiful hexagonal pattern!

**Compare:**
- U-238 (38 nuclei): Fills ~3 complete hex rings
- Pb-206 (6 nuclei): Perfect hexagon around center nucleus!

---

## Extension 4: Nucleus Oscillation (Living Atom)

### Goal
Add subtle random movement to each nucleus to make the atom look alive and dynamic.

### Why
Static sprites look lifeless. Small oscillations suggest quantum jitter, thermal motion, and make the atom visually engaging.

---

### Step 4.1: Add Oscillation to Nucleus Script

Update `nucleus.gd` to add gentle movement:

```gdscript
extends Node2D

enum NucleusType { PROTON, NEUTRON }

@export var nucleus_type: NucleusType = NucleusType.PROTON

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Oscillation properties
var oscillation_offset: Vector2 = Vector2.ZERO
var oscillation_speed: Vector2
var oscillation_amplitude := 3.0  # pixels
var time_offset: float

func _ready():
	# Ensure sprite is centered (pivot at center, not top-left)
	sprite.centered = true
	
	# Random oscillation parameters for each nucleus
	oscillation_speed = Vector2(
		randf_range(0.5, 1.5),  # X speed
		randf_range(0.5, 1.5)   # Y speed
	)
	time_offset = randf() * TAU  # Random start phase
	
	# Play spawn animation first
	sprite.play("spawn")
	sprite.animation_finished.connect(_on_spawn_finished)

func _process(delta):
	# Gentle sinusoidal oscillation applied to SPRITE position, not node position
	var time = Time.get_ticks_msec() / 1000.0 + time_offset
	oscillation_offset = Vector2(
		sin(time * oscillation_speed.x) * oscillation_amplitude,
		cos(time * oscillation_speed.y) * oscillation_amplitude
	)
	
	# Apply oscillation to sprite position (keeps hex grid intact)
	sprite.position = oscillation_offset

func _on_spawn_finished():
	if nucleus_type == NucleusType.PROTON:
		sprite.play("proton")
	else:
		sprite.play("neutron")

func set_type(type: NucleusType):
	nucleus_type = type
```

**✓ Checkpoint:** Run game - nuclei gently wobble in place, creating a "living" atom effect!

---

## Extension Verification Checklist

After completing all 4 extensions:

- [ ] **Extension 1:** Nuclei play proton or neutron animations after spawn
- [ ] **Extension 2:** IsotopeData autoload created and working
- [ ] **Extension 2:** Can change isotope_key in Inspector (try "Pb-206")
- [ ] **Extension 2:** Correct proton/neutron counts displayed
- [ ] **Extension 3:** Nuclei arranged in hexagonal grid pattern
- [ ] **Extension 3:** U-238 shows ~3 hex rings, Pb-206 shows 1 ring
- [ ] **Extension 4:** Nuclei gently oscillate (~3 pixels)
- [ ] **Extension 4:** Each nucleus has unique oscillation phase
- [ ] All nuclei still spawn correctly
- [ ] No errors in Output panel

---

## Extensions Complete! 🎉

**What you've built:**
- ✅ Proton/neutron visual distinction
- ✅ Centralized data system (ready for all 14 isotopes)
- ✅ Scientific hexagonal packing
- ✅ Living, breathing atoms with quantum jitter

**Files created:**
- `Data/IsotopeData.gd` - Isotope database (autoload)
- `Scripts/Utilities/HexGrid.gd` - Hexagonal positioning utility
- `Scripts/nucleus.gd` - Enhanced with animation logic and oscillation
- Updated `Scripts/atom.gd` - Data-driven with hex positioning

**Your atom system is now production-ready!** 🔬✨

When you're satisfied with these improvements, tell me **"M1 Extensions Complete!"** and we'll move to **M2: Mouse Following Movement** where we'll add physics and make the atom controllable!
