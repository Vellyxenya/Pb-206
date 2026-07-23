# M1 Extensions - Quick Reference

## Files Created

All extension code files have been created in organized folders:

1. **Data/IsotopeData.gd** - Autoload singleton with all isotope data
2. **Scripts/Utilities/HexGrid.gd** - Hexagonal positioning utility (class_name, no extends)
3. **Scripts/nucleus.gd** - Complete nucleus script with all extensions
4. **Scripts/atom.gd** - Complete atom script with all extensions

**Folder Structure:**
```
pb-206/
├── Data/
│   └── IsotopeData.gd        ← Isotope database
├── Scripts/
│   ├── Utilities/
│   │   └── HexGrid.gd        ← Hexagonal grid utility
│   ├── atom.gd
│   └── nucleus.gd
├── Scenes/
└── Assets/
```

## Implementation Checklist

### Extension 1: Animation States
- [ ] Add "proton" animation (Row 2, frames 4-7) to SpriteFrames
- [ ] Add "neutron" animation (Row 3, frames 8-11) to SpriteFrames
- [ ] Update nucleus.gd with animation logic (see CURRENT_MILESTONE.md)
- [ ] Test: Nuclei should transition from spawn → proton/neutron animations

### Extension 2: Data-Driven System
- [ ] IsotopeData.gd already created in Data/ folder
- [ ] Add IsotopeData.gd as Autoload in Project Settings (use path: res://Data/IsotopeData.gd)
- [ ] Update atom.gd with data-driven code (see CURRENT_MILESTONE.md)
- [ ] Test: Change isotope_key to "Pb-206" in Inspector → Should spawn 6 nuclei

### Extension 3: Hexagonal Grid
- [ ] HexGrid.gd already created in Scripts/Utilities/ folder
- [ ] Update atom.gd to use HexGrid.get_hex_positions() (see CURRENT_MILESTONE.md)
- [ ] Test: Nuclei should form perfect hexagonal rings

### Extension 4: Oscillation
- [ ] Update nucleus.gd with oscillation code (see CURRENT_MILESTONE.md)
- [ ] Adjust oscillation_amplitude if too much/little (default: 3.0 pixels)
- [ ] Test: Nuclei should gently wobble in place

## Code Integration

Follow the step-by-step instructions in CURRENT_MILESTONE.md Extensions section for detailed guidance on each change. All code should be added directly to nucleus.gd and atom.gd.

## Testing Steps

1. **Run game (F5)**
2. **Expected results:**
   - 38 nuclei for U-238 in hexagonal pattern
   - Nuclei spawn → then play proton/neutron idle
   - Nuclei gently oscillate (~3 pixels)
   - Output: "Spawning 92 protons + 146 neutrons"

3. **Change isotope:**
   - Select Atom in game.tscn
   - Inspector → Isotope Key: "Pb-206"
   - Run (F5)
   - Should spawn only 6 nuclei in perfect hexagon

## Key Concepts

**Autoload Singleton:**
- Global script accessible from any scene
- IsotopeData can be called from anywhere: `IsotopeData.get_isotope("U-238")`

**class_name:**
- Makes script a globally available class
- HexGrid functions: `HexGrid.get_hex_positions(38)`

**Hexagonal Packing:**
- Ring 0: 1 nucleus (center)
- Ring 1: 6 nuclei (around center)
- Ring 2: 12 nuclei (around ring 1)
- Ring 3: 18 nuclei (around ring 2)
- Pattern: 1, 6, 12, 18, 24, 30...

**Oscillation:**
- Each nucleus stores its original position
- Applies sin/cos offset each frame
- Random speed/phase makes each nucleus unique

## Next Steps

When all extensions work:
1. Test both U-238 and Pb-206
2. Verify all checklist items
3. Report "M1 Extensions Complete!"
4. Move to M2: Mouse Following Movement
