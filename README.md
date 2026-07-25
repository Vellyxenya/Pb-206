# PB-206: Nuclear Decay Chain Roguelike
**A physics-based 2D roguelike where you play as an atom decaying through the U-238 chain**

---

## 🎮 What We're Building

Control an atom that decays through 14 isotopes (U-238 → Pb-206) in this physics-based roguelike. Each phase is a timed race to reach a goal area while avoiding hazards. Different isotopes have unique physics based on their atomic mass, creating varied gameplay.

**Core Features:**
- Physics-based mouse-following movement with inertia
- 14 unique isotope phases with different mass/size/charge
- Timed phases with mandatory goal areas
- Multiple hazard types (neutron fields, electric fields, etc.)
- Risk/reward scoring system
- Permadeath roguelike structure

---

## 📋 Implementation System

This project uses a **milestone-based approach** with clear verification at each step. Perfect for learning Godot while building a complete game!

### Key Files Created:

1. **[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)**
   - 13 milestones from project setup to polished game
   - Each milestone builds on the previous
   - Clear goals, steps, and verification criteria

2. **[CURRENT_MILESTONE.md](CURRENT_MILESTONE.md)**
   - Detailed step-by-step instructions for active milestone
   - Updated as we progress

3. **[context.md](context.md)**
   - Complete game design document
   - All mechanics, hazards, and systems
   - Technical implementation details



   ## TODO
   - There should be less photons in the map
   - Green arrival area should be more dangerous


   - Swallowing photons should fill an energy bar, fill-amount should be parametrizable. The energy bar should be right below the name of the atom (and thus also follow the atom).
   - When the user presses the left-mouse button, the speed should be doubled (smooth transition) and when he releases it shold go back to normal speed. As long as it is pressed, the energy bar depletes. If fully depleted, the user can no longer press until the energy is not empty again.
   - When decaying there should be a proper animation where an atom made out of 2 protons and 2 neutrons is ejected for an alpha decay. For a beta decay there should be a spark or something and an electron should be visually released. Only then (i guess after 2 seconds or so we should transition to the next phase).
   - Work on leaderboard
   - add sound when mouse enters button