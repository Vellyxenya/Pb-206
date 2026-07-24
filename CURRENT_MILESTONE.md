# Current Milestone: M9 - Complete Isotope Data

## Goal
Add all 14 isotopes to the data structure in `Data/IsotopeData.gd`.

## Why This Matters
This milestone is a crucial data-entry step. With the full isotope dataset, we can implement the complete decay chain, allowing the player to transition from Uranium-238 all the way down to Lead-206. It prepares the project for the core progression loop.

## Prerequisites
- M8 complete (Attraction and repulsion fields are implemented).
- `Data/IsotopeData.gd` exists and is configured as an autoload singleton.

---

## Step-by-Step Instructions

### Step 1: Open IsotopeData.gd
Navigate to `Data/IsotopeData.gd` in the FileSystem dock and open it.

### Step 2: Add the Complete Isotope Data
Replace the existing `isotope_data` dictionary with the full 14-isotope data structure. This includes data for names, mass, decay types, next isotopes, timer ranges, and visual tints.

I will provide the complete data structure to be pasted into the file.

### Step 3: Verify the Data Structure
Carefully check the new data for any syntax errors, such as missing commas or incorrect bracket placement. Ensure it's a valid Godot dictionary.

---

## Verification Checklist

- [ ] `Data/IsotopeData.gd` contains the complete data for all 14 isotopes.
- [ ] The data structure is syntactically correct with no errors.
- [ ] Manually changing the starting `isotope_key` in `atom.gd` correctly loads the new isotope's properties (mass, tint, etc.).
- [ ] The starting `isotope_key` is reset to `"U-238"` after testing.

---

## Expected Result

The `IsotopeData` singleton now contains all the necessary data for the full decay chain. The game is now ready for Milestone 10, where we will implement the phase transitions that use this data.
