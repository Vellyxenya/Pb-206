# Project Overview
**Engine:** Godot 4  
**Timeline:** 3 days  
**Core Concept:** A physics-based 2D roguelike where you play as an atom decaying through the U-238 chain to stable Pb-206.

# Core Systems & Mechanics  
- **Movement & Physics:** The player controls an atom in a top-down 2D space. Movement is based on inertia – the atom accelerates gradually toward the mouse/cursor and drifts if no input is given. Heavier isotopes (higher atomic mass) accelerate slower and are harder to turn (higher momentum). This physics-based motion gives each atom a distinct "feel" and makes speed/energy management a core challenge.  
- **Timed Phases:** Each phase represents an isotope. On phase start we sample a random duration (e.g. 2–3 minutes). A visible countdown (or half-life meter) ticks down. When it reaches zero, the atom *decays* into the next element. The transition changes the player's stats (mass, charge, abilities) and begins the new phase's timer. This enforces the "countdown" theme: decay is inevitable, but its timing is semi-random.  
- **Phase Goal Areas:** Each phase has a designated goal area marked by a large green circle somewhere in the level. The player **must** reach this goal area before the phase timer expires or **the run ends (game over)**. Simply staying put is not a valid survival strategy – the player must navigate through hazards and use environmental interactions (like electric fields) to reach the goal. Once inside the goal area, the player earns **bonus points per second** for staying inside (risk/reward mechanic). However, goal areas are deliberately placed in **more hazardous zones** with increased enemy density, stronger fields, or environmental dangers, making them high-risk/high-reward areas. **Important:** Reaching the goal area does NOT end the phase early – the phase only transitions when the decay timer reaches zero. The player must survive inside or near the dangerous goal area until decay occurs.
- **Environment & Procedural Layout:** The game world is a large 2D area (e.g. a containment chamber or cavern) with obstacles, fields, and items. For replayability, each run’s item/hazard layout is shuffled or procedurally generated. Standard roguelike features apply: **permadeath** means death (see below) ends the run; procedural variation ensures each playthrough is fresh.  
- **Collectibles (Score):** Scattered in the environment are **"energy quanta"** (photons, free electrons, or neutrons) that the player collects to increase score. Collecting an electron charges the atom, enabling new interactions (see below), while photons boost speed. These pickups function as the "treasure" of the roguelike run. Points are also awarded for time remaining when a phase ends (encouraging fast progress). In roguelikes, scoring typically combines treasure gathered with completion time.
- **Hazards (Fail Conditions):** Various traps or dangers terminate the run prematurely. Touching any fatal hazard ends the run (permadeath). The run also ends if the phase timer expires before reaching the goal area. See "Hazard Types" section below for the complete list of dangers.  
- **Phase Transitions:** When decay occurs, the player's element changes (see chain below). We visually and physically update the atom: e.g. a green U-238 sprite changes to orange Th-234. This also triggers effects: an α-decay blasts out an "alpha particle" obstacle, or a β-decay emits an electron collectible. The shift briefly stuns or repositions the player for drama.
- **Universal Interactions:** To keep mechanics consistent, we include features that apply to any charged/neutral atom. Examples: *Electric fields* push or pull charged atoms, *magnetic fields* bend moving charged atoms, and *ionisation zones* strip or grant electrons. These environment features don't change per isotope, but how the atom is affected does (see Attributes below). For instance, after a β-decay the atom is positive and is drawn to negative charges; a neutral atom drifts unaffected.
- **No Weapons:** The atom has no traditional weapons. Instead, *kinetic energy* is the weapon. High speed allows the atom to "break through" certain barriers or knock out items. For example, moving very fast lets an atom punch through a soft barricade (simulating high-energy collision). This rewards skillful control: faster movement yields power, but is harder to steer.


## Decay Chain Phases

We use the real **U-238 decay chain** as our phase sequence. U-238 undergoes 14 successive decays (8 α and 6 β) before ending at stable lead-206. Each decay is a "phase." For gameplay, each isotope is a distinct phase with its own stats/hazards. The chain **terminates in Pb-206** (lead), which is "home" (the stable end). A full run goes:

- **Phase 1: Uranium-238 (U-238).** Alpha emitter (α-decay in ~2–3 min to Th-234). Heavy and neutral initially.  
- **Phase 2: Thorium-234 (Th-234).** Beta emitter (β-decay to Pa-234). Slightly lighter. After β-decay it becomes positively charged (lost an electron).  
- **Phase 3: Protactinium-234 (Pa-234).** Beta emitter to U-234. Still heavy, initially charged from previous step.  
- **Phase 4: Uranium-234 (U-234).** Alpha emitter to Th-230. Back to neutral after capturing an electron.  
- **Phase 5: Thorium-230 (Th-230).** Alpha to Ra-226. Heavy, neutral.  
- **Phase 6: Radium-226 (Ra-226).** Alpha to Radon-222. Heavy, neutral. Emits strong α.  
- **Phase 7: Radon-222 (Rn-222).** Alpha to Polonium-218. A gas phase with drifting movement. Neutral.  
- **Phase 8: Polonium-218 (Po-218).** Alpha to Lead-214. Fast decay with short timer.  
- **Phase 9: Lead-214 (Pb-214).** β to Bismuth-214. Now charged.  
- **Phase 10: Bismuth-214 (Bi-214).** Beta to Polonium-214. Positive charge after decay.  
- **Phase 11: Polonium-214 (Po-214).** α to Lead-210. Emits very short-lived α (fast timer phase). Neutral.  
- **Phase 12: Lead-210 (Pb-210).** β to Bismuth-210. Slight positive charge after decay.  
- **Phase 13: Bismuth-210 (Bi-210).** β to Polonium-210. Positive (or neutral if capturing electron).  
- **Phase 14: Polonium-210 (Po-210).** α to Lead-206 (stable). This final α-decay releases the last large burst, and the atom becomes Pb-206 – a stable lead atom.  

*(All isotopic data from the U-238 series.)*  

Key points: the overall chain has 8 α-decays and 6 β-decays. Each α-decay jumps two elements down; each β-decay moves one up. Only the last product (Pb-206) is stable.


## Atom Attributes & Interactions  

Each isotope (phase) is characterized by its **atomic properties**, which we convert into game stats using a **data-driven approach**. All isotope data is stored in a structured format (e.g. JSON, Godot Resource files, or a dictionary) containing each isotope's properties.

### Parameter Scaling System
To make differences between isotopes more pronounced and interesting, we use **(mass - 200)** scaling for key parameters. Since all isotopes in the decay chain are between 206-238, subtracting 200 gives us a working range of 6-38:
- U-238: 238 - 200 = **38** (heaviest, slowest)
- Po-218: 218 - 200 = **18** (medium)
- Pb-206: 206 - 200 = **6** (lightest, fastest)

This makes U-238 more than 6× heavier than Pb-206, creating dramatic gameplay differences.

### Isotope Properties

- **Mass:** Proportional to (atomic_mass - 200). U-238 has effective mass 38, making it sluggish with high momentum. Po-218 has effective mass 18, making it more agile. Pb-206 has effective mass 6, making it very light and responsive. This is coded by setting `physics_body.mass = isotope_mass - 200` in Godot.
- **Visual Size:** Sprite scale is also proportional to (atomic_mass - 200). U-238 appears 38 units large, Po-218 appears 18 units, Pb-206 appears 6 units. This visual feedback reinforces the mass differences. Scale factor: `sprite.scale = (isotope_mass - 200) / 20.0` gives reasonable sizes.
- **Charge:** Neutral atoms have balanced protons/electrons. After a **β⁻ decay**, the nucleus gains a proton but emits an electron, so the atom becomes positively charged (missing an electron). In gameplay terms, we mark the new atom as +1 charge until it picks up an electron. Charged atoms respond to fields (see below). α-decays remove a He nucleus (2p+2n) but we assume the atom leaves with neutral charge by ejecting 2 electrons, so the atom remains overall neutral after each α event. (An α particle is 2 protons + 2 neutrons.)
- **Valence/Electron count:** In a detailed model, we track how many electrons the atom "should" have. A β-decay effectively drops an electron into the scene (which the player collects). The atom needs to collect an electron later to return to neutral. We simplify: only care about "charged" vs "neutral" state. Valence influences interactions (e.g. certain elements attract particular pickups).
- **Stability:** Each isotope's timer is its "instability." Longer timers (like U-238, 2–3min) versus short timers (Po-214 decays in microseconds). We emulate this with the sampled countdown.

### Data-Driven Isotope Structure
In Godot, create a data structure (Resource or Dictionary) for each isotope:
```gdscript
var isotope_data = {
    "U-238": {
        "name": "Uranium-238",
        "mass": 238,
        "decay_type": "alpha",
        "next_isotope": "Th-234",
        "timer_range": [120, 180],  # 2-3 minutes
        "initial_charge": 0,
        "sprite_color": Color(0.2, 0.8, 0.3)  # green
    },
    "Th-234": {
        "name": "Thorium-234",
        "mass": 234,
        "decay_type": "beta",
        "next_isotope": "Pa-234",
        "timer_range": [90, 150],
        "initial_charge": 0,  # becomes +1 after beta decay
        "sprite_color": Color(0.9, 0.5, 0.2)  # orange
    },
    # ... all 14 isotopes
}
```
This data-driven approach makes it easy to tune parameters, add new isotopes, or modify the decay chain without changing code.

**Universal interactions:** Every atom, charged or not, uses the same interaction rules:  
- **Electric fields:** Regions of space apply force $F=qE$ on charged atoms. A positive atom is pushed along the field; a neutral one is unaffected. We place "positive/negative plates" in the map.
- **Magnetic fields:** A magnet zone curves the trajectory of moving charged atoms via a Lorentz force $F=q(v\times B)$. This requires velocity, charge, and a B-field direction. Practically, a "magnet" object constantly pushes sidewise on a moving charged atom.
- **Photon/Energy zones:** Areas of light that give kinetic boosts. Since actual photons are weightless, we treat them as pickups that grant speed or energy (score).  
- **Electron capture:** To simulate β⁺ or capture, we include rare "free electron" sprites. If the atom enters an electron cloud, it captures an electron and changes its charge state (or gains points). Similarly, a dense electron zone is a hazard causing an electron capture event, altering the atom's future.
- **Physical obstacles:** Walls or particles that break if the atom is fast enough. For example, an "energy barrier" blocks slow atoms but shatters under high-energy (fast) impact. Since we have no weapons, high speed acts as an attack.
- **Magnetic or gravitational traps:** Zones that hold atoms (like a magnetic trap for charged atoms, or a gravity well that pulls all atoms). Running into these is either hazard (if you can't escape) or a puzzle element (requiring charge changes).

Overall, atoms change only by decay and by these interactions – players don't shoot or collect foreign nuclei. All gameplay complexity comes from moving and maneuvering the current "atom" through fields, picking up score-items, and avoiding lethal regions.


## Visual Representation - Nucleus System

### Atom Composition
Each atom (player or NPC) is visually composed of **individual nucleus sprites** rather than a single sprite. This creates a dynamic, particle-based appearance that scales with mass.

### Nucleus Count Formula
The number of visible nuclei = **(mass_number - 200)**

Examples:
- **U-238:** 238 - 200 = **38 nuclei** (large, dense cluster)
- **Po-218:** 218 - 200 = **18 nuclei** (medium cluster)
- **Pb-206:** 206 - 200 = **6 nuclei** (small, compact cluster)

This creates a dramatic **6× visual difference** between the heaviest and lightest atoms in the decay chain.

### Nucleus Scene Structure
```
Atom (Node2D)
├── Nucleus 1 (AnimatedSprite2D)
├── Nucleus 2 (AnimatedSprite2D)
├── Nucleus 3 (AnimatedSprite2D)
└── ... (count based on mass_number - 200)
```

### Nucleus Arrangement
Nuclei are positioned in a **disk pattern** (circular area) when spawned:
- Random positions using polar coordinates (angle + distance)
- `sqrt(randf())` distribution ensures uniform density across the disk
- Disk radius scales with atom size (configurable per isotope)
- All nuclei move together as a single rigid unit (the atom)

### Nucleus Spritesheet (4×4 Grid, 16 Frames)
Each nucleus uses an **AnimatedSprite2D** with a 4×4 spritesheet:

**Animation Types:**
- **Row 1 (frames 0-3):** Spawn animation - plays when nucleus first appears
- **Row 2 (frames 4-7):** Proton animation - used for proton-rich states
- **Row 3 (frames 8-11):** Neutron animation - used for neutron-rich states  
- **Row 4 (frames 12-15):** Destruction animation - plays when nucleus is destroyed

### Implementation Details
- **nucleus.tscn:** Reusable scene with AnimatedSprite2D and SpriteFrames resource
- **atom.gd:** Script that instantiates the correct number of nuclei at `_ready()`
- **Instancing:** Each atom scene creates its own nucleus instances dynamically
- **Physics:** The Atom root has the RigidBody2D (added in M2); nuclei are visual children only

### Visual Benefits
- Scales naturally with mass (heavy atoms look bigger and more complex)
- Creates organic, particle-like appearance
- Allows for future effects (nuclei can flash, change color, or animate independently)
- Makes decay transitions more dramatic (nuclei can be ejected or transform)
- Differentiates player from NPCs while using same system


## Hazard Types

To create varied but contained gameplay, we use a focused set of hazard types that interact with the atom physics:

### Core Hazards (Always Present)
1. **Neutron Fields (Instant Death Zones):** Red glowing regions that cause immediate fission if touched. Small circular or rectangular zones scattered throughout. These are the primary "spike traps" – avoid at all costs.

2. **Containment Walls:** Hard boundaries of the play area. Collision causes instant death (atom shatters). Walls are visible and clear, acting as the arena boundary.

3. **Energy Barriers:** Translucent walls that can only be broken by high-speed collisions. Slow atoms bounce off (taking no damage), but hitting them at low speed wastes time. These create routing puzzles where you need to build up speed.

### Electric/Magnetic Hazards (Interact with Charge)
4. **Electric Field Plates:** Pairs of positive/negative plates that create directional force fields. Charged atoms are pushed/pulled (useful for navigation), but these forces can slam you into walls or neutron fields if you're not careful. Neutral atoms pass through unaffected.

5. **Magnetic Vortices:** Spinning magnetic fields that curve the trajectory of moving charged atoms. Creates spiraling motion that's hard to control but can be used strategically. Neutral atoms ignore these.

6. **Ionization Zones (Charge Strippers):** Purple crackling zones that strip electrons from neutral atoms (making them +1 charged) or add electrons to charged atoms (neutralizing them). Not lethal, but changes your physics behavior unexpectedly, which can lead to danger.

### Environmental Hazards (Theme-Appropriate)
7. **Turbulent Currents (Radon Gas Phases):** Invisible wind zones that push the atom in random directions. Creates "slippery" navigation, especially dangerous when combined with neutron fields. More common in Radon-222 phase.

8. **Decay Debris:** After each α-decay transition, the ejected alpha particle becomes a slow-moving obstacle for a few seconds. β-decays eject electrons (collectible). This creates temporary navigation challenges right after phase transitions.

9. **Photon Streams:** Fast-moving beams of light that cross the arena periodically. Neutral to touch (actually boosts speed slightly), but they push you, potentially into hazards. Creates timing-based challenges.

### Goal Area Specific Hazards
10. **Dense Neutron Clusters:** Multiple small neutron fields clustered near goal areas, requiring precise navigation.

11. **Oscillating Barriers:** Energy barriers that flicker on/off near goal areas, requiring timing to enter/exit safely.

12. **Crossed Electric Fields:** Multiple overlapping electric field plates near goals create chaotic forces for charged atoms.

### Hazard Density Guidelines
- **Safe zones:** 0-1 hazards, mostly open space for learning movement
- **Normal zones:** 2-4 hazards, standard navigation challenge
- **Goal areas:** 5-8 hazards, high-risk areas requiring mastery
- Each phase increases overall hazard density slightly (U-238 easiest, Pb-210 hardest)

This hazard set provides:
- **Binary dangers** (neutron fields, walls) for clear fail states
- **Physics interactions** (fields, magnets) for skillful navigation
- **Environmental variety** (currents, debris) for phase-specific flavor
- **Risk/reward zones** (goal areas) for scoring opportunities

All hazards are visually distinct and learnable, supporting roguelike mastery through repeated runs.


## Scoring, Failure, & Progression  

- **Scoring:** Points are awarded for **collecting energy items** (photons, electrons, etc.), reaching goal areas, and surviving inside them. For example, each electron pickup is +10 points, each photon +5. Reaching a phase goal area grants +50 bonus points. While inside the goal area, earn **+5 points per second** (risk/reward for staying in the dangerous zone). When the phase timer expires, any remaining time since reaching the goal converts to additional bonus. Roguelike tradition is to reward *treasure* and risk-taking, so we mirror that: collecting pickups, quickly reaching goals, and surviving in hazardous goal zones = higher score. A final bonus (+500) is given for reaching Pb-206 (winning). Note that reaching the goal area does not end the phase early – you must survive until the decay timer expires.  
- **Failure Conditions:** A run ends (game over) if the atom is "destroyed." This happens via: colliding with a lethal hazard (neutron field, containment wall), or **failing to reach the phase goal area before the timer expires**. In essence, touch any fatal obstacle = permadeath, and failing to reach the goal in time = permadeath. As typical roguelikes use permadeath, the player restarts from Phase 1 after any death, and the run score is tallied on a leaderboard.
- **Roguelike Progression:** Each run randomises key elements: the timers (via random ranges), placement of pickups/hazards, and goal area locations. There is no in-run save (no cheating), so every decision matters. With only 3 days, we focus on in-run design rather than meta-progression. A final performance screen shows how far the player got and the score, encouraging retry for higher score (like typical roguelikes).  

In summary, players *survive through all phases to Pb-206* while racking up points and reaching each phase's goal area. Phases always run for their full timer duration – reaching the goal area grants bonuses but does not skip ahead. Each failed run restarts with new random elements, making the challenge about strategy and luck. 


## 3-Day Godot 4 Implementation Plan  

1. **Day 1 – Core Engine & Movement:** Set up a Godot 4 project and scenes. Create the **isotope data structure** (dictionary or Resource file) containing all 14 isotopes with their properties (id, mass, decay_type, next_isotope, timer_range, charge, color). Implement the player atom as a RigidBody2D that accelerates toward the mouse cursor. Use the data-driven approach: set `mass = isotope_data[current].mass - 200` and `sprite.scale = (mass) / 20.0`. Tune the movement for a good "floaty" feel. Create a timer system for phases: on entering a phase, sample a random duration from the isotope's timer_range and display a countdown. When time expires, check if player reached goal: if yes, trigger `decay_to_next_isotope()`, if no, trigger `game_over()`. Create the goal area system: implement a large green circle (Area2D) that appears at a random location each phase. Add detection for when the player enters it (sets `goal_reached = true` but does NOT end the phase). While player is inside goal area, accumulate bonus points per second. Implement basic hazards: neutron fields (instant death) and containment walls. Stub out a simple large play area. Verify movement, pickup (increment score), hazard collision (game over), goal area detection, and per-second bonus work.
2. **Day 2 – Phase Transitions & Interactions:** Implement the decay transition function: when timer expires, check if `goal_reached == true`. If false, call `game_over()`. If true, look up `next_isotope` from the data, then update the player's mass `(new_mass - 200)`, sprite scale `(new_mass - 200) / 20.0`, sprite color, and charge based on decay_type (β-decay sets charge to +1, α-decay keeps it neutral). Emit decay particles (alpha or beta) as visual effects and temporary obstacles. The data structure already contains all 14 isotopes, so the chain flows automatically. Add more hazard types: electric field plates (push/pull charged atoms), energy barriers (need speed to break), ionization zones (change charge state), and turbulent currents. Populate the map: randomly place pickups and hazards, but concentrate 2-3× more hazards near the goal area to create the risk/reward zone. Implement goal area mechanics: when player enters, set `goal_reached = true`, grant +50 entry bonus, and start accumulating +5 points/second while inside. Start work on the UI: show current isotope name, countdown, score, points/second indicator when in goal area, and directional arrow pointing toward the goal area.
3. **Day 3 – Balancing & Polish:** Fill in remaining details. Tune the isotope data: adjust timer_ranges and colors for all 14 isotopes. The (mass - 200) scaling already makes heavier isotopes move slower automatically. Verify the charge mechanic: after a β-decay, the atom is marked charged (+1) and interacts with electric fields. Test and balance: timers should be tight but fair (e.g. 90-120 seconds for most phases), goal areas should be reachable in 30-60% of the timer, leaving rest of time to survive in the hazardous goal zone. Tune hazard placement: safe paths should exist to goal area, but goal area itself is dangerous (test that 2-3× hazard density feels challenging but not impossible). Emphasize to players via UI that phases cannot end early and you MUST reach the goal or lose. Add tutorial hints for first phase. Randomise the initial layout for each run (procedural scattering with safe starting zone). Implement all hazard types from the Hazard Types section. Implement the final goal: once the Pb-206 phase timer expires (and goal was reached), allow the atom to escape out of the container (triggering victory). Add game-over and win screens showing score/rank and how far you got. Polish visuals: use the data-driven sprite colors, scale sprites by (mass-200)/20, glowing green goal circles with danger indicators, glowing red neutron fields, colored electric fields, and particle effects for all hazards. Create audio cues for decay, goal area reach, per-second bonuses, and hazard proximity. Ensure Godot 4's physics run smoothly and fix bugs. The result is a working 2D roguelike where the atom "counts down" through the nuclear decay chain, with physics-inspired interactions throughout.

This plan focuses Day 1 on getting the **movement/timer loop and goal areas**, Day 2 on **phases and game objects**, and Day 3 on **game feel and polish**, which is a reasonable scope for a 3-day jam. By the end, the player experiences each atomic phase as a timed gameplay mode, collecting points, reaching goal areas, and dodging death until (hopefully) reaching Pb-206.  

**Sources:** We use the real uranium-238 decay chain as inspiration. Atomic properties (protons, neutrons) come from standard data (e.g. U-238 has Z=92, N=146). For game design context, roguelikes emphasize score via pickups/time and permadeath with procedural variation. References on decay clarify α/β particles and chains.