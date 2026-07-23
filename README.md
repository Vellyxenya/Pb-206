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

2. **[GODOT_UI_GUIDE.md](GODOT_UI_GUIDE.md)**
   - Complete reference for Godot 4 interface
   - Where to find every panel and menu
   - Common tasks with exact UI locations
   - Troubleshooting guide

3. **[CURRENT_MILESTONE.md](CURRENT_MILESTONE.md)**
   - Detailed step-by-step instructions for active milestone
   - Updated as we progress

4. **[context.md](context.md)**
   - Complete game design document
   - All mechanics, hazards, and systems
   - Technical implementation details

---

## 🚀 How to Use This System

### The Workflow:

1. **Read current milestone** in `CURRENT_MILESTONE.md`
2. **Follow steps one-by-one** (with exact UI guidance)
3. **Verify completion** using the checklist
4. **Report completion** to me
5. **Move to next milestone** (I'll update files)

### If You Get Stuck:

- Check `GODOT_UI_GUIDE.md` for interface help
- Review the milestone's troubleshooting section
- Ask me for clarification!
- We can break steps down further if needed

---

## 📊 Current Progress

**Active Milestone:** M1 - Atom with Nucleus Sprites  
**Completed Milestones:** M0 ✓  
**Next Up:** M2 - Mouse Following Movement

### Milestone Overview:

- [x] **M0:** Project Setup ✓ **COMPLETE**
- [ ] **M1:** Atom with Nucleus Sprites ← **YOU ARE HERE**
- [ ] **M2:** Mouse Following Movement
- [ ] **M3:** Mass-Based Movement (Data-Driven)
- [ ] **M4:** Phase Timer System
- [ ] **M5:** Goal Area System
- [ ] **M6:** Win/Lose Conditions
- [ ] **M7:** Basic Hazards (Neutron Fields)
- [ ] **M8:** Containment Walls
- [ ] **M9:** Complete Isotope Data
- [ ] **M10:** Phase Transitions (Decay)
- [ ] **M11:** Scoring System
- [ ] **M12:** Electric Fields & Charge
- [ ] **M13:** Full Game Loop & Polish

---

## 🎯 Getting Started

**Right now:**
1. Open `CURRENT_MILESTONE.md`
2. Follow the M0 (Project Setup) instructions
3. When complete, tell me "M0 Complete!"
4. I'll update everything for M1

**Need help first?**
- Open `GODOT_UI_GUIDE.md` to familiarize yourself with Godot
- Review `IMPLEMENTATION_PLAN.md` to see the big picture
- Ask me any questions!

---

## 📁 Project Structure

```
pb-206/
├── README.md                     ← You are here
├── context.md                    ← Game design document
├── IMPLEMENTATION_PLAN.md        ← All 13 milestones
├── GODOT_UI_GUIDE.md            ← Godot interface guide
├── CURRENT_MILESTONE.md         ← Active step-by-step guide
├── Scenes/                      ← .tscn scene files (created in M0)
├── Scripts/                     ← .gd script files (created in M0)
└── Assets/                      ← Images, sounds (created in M0)
```