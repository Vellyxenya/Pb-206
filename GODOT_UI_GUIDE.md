# Godot 4 UI Navigation Guide
**For First-Time Users**

This guide helps you find your way around the Godot 4 interface. Refer to this whenever you're unsure where to click.

---

## Main Interface Layout

```
┌─────────────────────────────────────────────────────────┐
│ Menu Bar: Scene, Project, Debug, Editor, Help          │
├──────────┬──────────────────────────────┬───────────────┤
│          │                              │               │
│  Scene   │                              │   Inspector   │
│  Tree    │      Main Viewport           │   (Properties)│
│  Panel   │      (Your game view)        │               │
│          │                              │               │
│  - Click │                              │   - Shows     │
│    nodes │                              │     settings  │
│    here  │                              │     for       │
│          │                              │     selected  │
│          │                              │     node      │
│          │                              │               │
├──────────┴──────────────────────────────┴───────────────┤
│  FileSystem          │  Output/Console                  │
│  (Project files)     │  (Errors & messages)             │
└──────────────────────┴──────────────────────────────────┘
```

---

## Essential UI Elements

### 1. Scene Panel (Top-Left)
**What it is:** Shows the hierarchy of nodes in your current scene

**Key actions:**
- **Add Node:** Click the "+" button (or press Ctrl+A)
- **Delete Node:** Select node, press Delete
- **Rename Node:** Double-click node name
- **Reparent:** Drag node onto another node
- **Instance Scene:** Click chain-link icon

**Tip:** The tree structure shows parent-child relationships. Indented nodes are children.

---

### 2. Inspector Panel (Right Side)
**What it is:** Shows properties of the selected node

**Key sections:**
- **Node tab:** Node-specific properties (mass, color, position, etc.)
- **Script:** Shows attached script (if any)
- **Groups:** Node groups for organization
- **Signals:** Connect signals here (we'll use this for detection)

**How to edit:**
- Click property name to edit values
- Color properties: click color box to open picker
- Vector2/Vector3: click to expand X, Y, Z fields
- Checkboxes: click to toggle

**Tip:** Properties with a revert arrow (↶) have been changed from default. Click arrow to reset.

---

### 3. FileSystem Panel (Bottom-Left)
**What it is:** Your project folder browser

**Common actions:**
- **Navigate:** Double-click folders
- **Create folder:** Right-click > New Folder
- **Import files:** Drag files from Windows Explorer
- **Open scene:** Double-click .tscn file
- **Open script:** Double-click .gd file

**Folder structure we're using:**
```
pb-206/
├── Scenes/        # .tscn scene files
├── Scripts/       # .gd script files
└── Assets/        # images, sounds, etc.
```

---

### 4. Main Viewport (Center)
**What it is:** Where you see and edit your game

**View controls:**
- **Pan:** Middle mouse drag (or Shift + left drag)
- **Zoom:** Mouse wheel
- **Reset view:** Click "100%" button at bottom
- **Grid snap:** Click magnet icon at top

**Modes (top toolbar):**
- **Select Mode (Q):** Select and move nodes
- **Move Mode (W):** Move selected node
- **Rotate Mode (E):** Rotate selected node
- **Scale Mode (S):** Scale selected node

---

### 5. Top Toolbar

```
[2D] [3D] [Script] [AssetLib]  |  Play▶ Scene▶ Pause⏸ Stop⏹
```

**Main tabs:**
- **2D:** Edit 2D scenes (we'll use this most)
- **3D:** Edit 3D scenes (not used in this project)
- **Script:** Code editor (opens when you attach scripts)
- **AssetLib:** Download assets (not needed for this project)

**Play controls:**
- **Play (F5):** Run main scene
- **Play Scene (F6):** Run currently open scene
- **Pause:** Pause running game
- **Stop (F8):** Stop running game

---

## Common Tasks & Where to Find Them

### Creating a New Scene
1. Click **Scene menu** > New Scene
2. Choose scene type:
   - **2D Scene:** Creates Node2D root (most common for us)
   - **3D Scene:** Creates Node3D root (not used)
   - **User Interface:** Creates Control root (for UI)
   - **Other Node:** Choose custom root node

**Shortcut:** Ctrl+N

---

### Adding Nodes
1. Make sure a scene is open (if not, create new scene)
2. Click the **"+" button** at top of Scene panel
   - Or press **Ctrl+A**
3. Search for node type (e.g., "Sprite2D", "RigidBody2D")
4. Double-click to add it

**Node naming:**
- Godot auto-names (Sprite2D, Sprite2D2, etc.)
- Rename by double-clicking the name

---

### Attaching Scripts
**Method 1 (Recommended):**
1. Select node in Scene panel
2. Click "Attach Script" button (scroll icon) at top of Scene panel
3. Choose save location (Scripts/ folder)
4. Click "Create"
5. Script editor opens automatically

**Method 2:**
1. Right-click node > Attach Script
2. Follow same steps

**Finding attached script:**
- Look for script icon next to node name in Scene panel
- Click the icon to open script

---

### Saving Scenes
1. **Ctrl+S** or Scene menu > Save Scene
2. First time: choose location and name
   - Save in `Scenes/` folder
   - Use lowercase with underscores: `player.tscn`, `goal_area.tscn`
3. Scene tab shows asterisk (*) when unsaved

**Tip:** Save often! Godot shows * on tab when scene has unsaved changes.

---

### Running Your Game
1. **Set main scene (first time only):**
   - Project menu > Project Settings > Application > Run
   - Main Scene: Select your main .tscn file
   - Or click "Select Current" if main scene is open

2. **Run game:**
   - Press **F5** (or click ▶ Play button)
   - Game runs in new window
   - Output panel shows messages/errors

3. **Stop game:**
   - Press **F8** (or click ⏹ Stop button)
   - Or close the game window

---

### Reading the Output Console
**Location:** Bottom panel, "Output" tab

**What it shows:**
- `print()` statements from your code
- Errors (red text)
- Warnings (yellow text)
- System messages

**Tip:** If game doesn't work, check Output for error messages!

---

## Node Types We'll Use

### RigidBody2D
**What it is:** Physics-based object with mass and forces  
**Used for:** Player atom (moves with physics)  
**Key properties:**
- Mass: How heavy (affects movement)
- Gravity Scale: We set to 0 (no gravity)
- Lock Rotation: Prevents spinning

### Sprite2D
**What it is:** Displays an image  
**Used for:** Visual representation of atom  
**Key properties:**
- Texture: The image file
- Modulate: Tint color
- Scale: Size multiplier

### Area2D
**What it is:** Detects when other objects enter/exit  
**Used for:** Goal areas, hazards, collectibles  
**Key properties:**
- Monitoring: Must be ON to detect
- Monitorable: Can be detected by others

### CollisionShape2D
**What it is:** Defines collision boundary  
**Used for:** Must be child of physics nodes  
**Key properties:**
- Shape: CircleShape2D, RectangleShape2D, etc.

### Timer
**What it is:** Counts down and signals when done  
**Used for:** Phase decay timer  
**Key properties:**
- Wait Time: Duration in seconds
- One Shot: If true, runs once then stops
- Autostart: Starts automatically

### Node2D
**What it is:** Basic 2D node with position/rotation  
**Used for:** Organizing other nodes  
**Key properties:**
- Position: X, Y coordinates
- Rotation: Angle in radians
- Scale: Size multiplier

---

## Connecting Signals (We'll Do This Later)

**What are signals?** Events that nodes emit (like "body_entered" when something collides)

**How to connect:**
1. Select node in Scene panel
2. Click "Node" tab in Inspector (next to Inspector tab)
3. Find signal in list (e.g., "body_entered")
4. Double-click signal
5. Select receiving node
6. Choose/create function name
7. Click "Connect"

**Tip:** When we need this, I'll provide detailed steps!

---

## Project Settings

**How to open:** Project menu > Project Settings

**Important sections we'll use:**
- **Application > Run > Main Scene:** Set starting scene
- **Display > Window > Size:** Set game resolution (we'll use 1920×1080)
- **Physics > 2D:** Physics settings (default is fine)
- **Autoload:** Add singleton scripts (we'll use this for IsotopeData)

---

## Keyboard Shortcuts Summary

| Action | Shortcut |
|--------|----------|
| New Scene | Ctrl+N |
| Open Scene | Ctrl+O |
| Save Scene | Ctrl+S |
| Add Node | Ctrl+A |
| Run Project | F5 |
| Run Current Scene | F6 |
| Stop Game | F8 |
| Search Help | F1 |
| Delete Node | Delete |

---

## Troubleshooting Tips

### "I can't see my sprite!"
- Check Sprite2D has a texture assigned (Inspector > Texture)
- Check sprite position (might be off-screen)
- Check sprite is visible (Inspector > Visibility > Visible = ON)
- Zoom out in viewport (scroll wheel)

### "My physics isn't working!"
- RigidBody2D must have a CollisionShape2D child
- CollisionShape2D must have a shape (CircleShape2D, etc.)
- Check properties: Gravity Scale, Lock Rotation, etc.

### "Error: Invalid call. Function not found!"
- Check spelling of function name
- Check the script is attached to the right node
- Check function is defined in the script

### "Script has errors!"
- Read error message in Output panel
- Check line number (shown in error)
- Common issues: missing colons, wrong indentation, typos

---

## Getting Help

**In Godot:**
- Press **F1** to search documentation
- Select a node > Press F1 to see its docs
- Help menu > Online Documentation

**During our work:**
- Ask me anytime you're stuck!
- I'll provide exact UI locations for each step
- We'll go step-by-step

---

## Ready to Start!

When you're ready to begin:
1. Open Godot 4
2. Let me know you're ready
3. We'll start with **Milestone 0: Project Setup**
4. I'll guide you through every step with exact UI instructions

**Remember:** 
- Take your time
- Ask questions anytime
- We verify each step before moving on
- There are no wrong questions!
