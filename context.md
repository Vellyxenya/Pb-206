# Core Systems & Mechanics  
- **Movement & Physics:** The player controls an atom in a top-down 2D space. Movement is based on inertia – the atom accelerates gradually toward the mouse/cursor and drifts if no input is given. Heavier isotopes (higher atomic mass) accelerate slower and are harder to turn (higher momentum).  This physics-based motion gives each atom a distinct “feel” and makes speed/energy management a core challenge.  
- **Timed Phases:** Each phase represents an isotope. On phase start we sample a random duration (e.g. 2–3 minutes). A visible countdown (or half-life meter) ticks down. When it reaches zero, the atom *decays* into the next element. The transition changes the player’s stats (mass, charge, abilities) and begins the new phase’s timer. This enforces the “countdown” theme: decay is inevitable, but its timing is semi-random.  
- **Environment & Procedural Layout:** The game world is a large 2D area (e.g. a containment chamber or cavern) with obstacles, fields, and items. For replayability, each run’s item/hazard layout is shuffled or procedurally generated. Standard roguelike features apply: **permadeath** means death (see below) ends the run; procedural variation ensures each playthrough is fresh.  
- **Collectibles (Score):** Scattered in the environment are **“energy quanta”** (e.g. photons, free electrons, or neutrons) that the player can collect to increase score. Collecting an electron could charge the atom, enabling new interactions (see below), while photons might boost speed. These pickups function as the “treasure” of the roguelike run. Points may also be awarded for time remaining when a phase ends (encouraging fast progress).  (In roguelikes, scoring typically combines treasure gathered with completion time.)  
- **Hazards (Fail Conditions):** Various traps or dangers can terminate the run prematurely. Examples: *neutron fields* that cause immediate fission (death), high-energy zones that ionise or tear apart the atom, or collisions with heavy walls/other particles. Each phase can have theme-appropriate hazards (e.g. in a radon gas area have turbulent currents that push the atom into walls). Touching any fatal hazard ends the run (permadeath).  
- **Phase Transitions:** When decay occurs, the player’s element changes (see chain below). We visually/physically update the atom: e.g. a green U-238 sprite changes to orange Th-234. This can also trigger effects: an α-decay might blast out an “alpha particle” obstacle, or a β-decay might emit an electron collectible. The shift can briefly stun or reposition the player for drama.  
- **Universal Interactions:** To keep mechanics consistent, include features that apply to any charged/neutral atom. Examples:  *Electric fields* that push or pull charged atoms, *magnetic fields* that bend moving charged atoms, and *ionisation zones* that strip or grant electrons. These environment features don’t change per isotope, but how the atom is affected does (see Attributes below). For instance, after a β-decay the atom is positive and is drawn to negative charges; a neutral atom might drift unaffected.  
- **No Weapons:** The atom has no traditional weapons. Instead, *kinetic energy* is the weapon. High speed may allow the atom to “break through” certain barriers or knock out items. For example, moving very fast could let an atom punch through a soft barricade (simulating high-energy collision). This rewards skillful control: faster movement yields power, but is harder to steer. 


## Decay Chain Phases & Branching  

We’ll use the real **U-238 decay chain** as our phase sequence. In reality U-238 undergoes 14 successive decays (8 α and 6 β) before ending at stable lead-206.  Each decay is a “phase.” For gameplay, each isotope is a distinct phase with its own stats/hazards.  Notably, the chain **terminates in Pb-206** (lead), which is “home” (the stable end). For brevity we might combine some fast steps, but a full run could go:  

- **Phase 1: Uranium-238 (U-238).** Alpha emitter (α-decay in ~2–3 min to Th-234). Heavy and neutral initially.  
- **Phase 2: Thorium-234 (Th-234).** Beta emitter (β-decay to Pa-234). Slightly lighter. After β-decay it becomes positively charged (lost an electron).  
- **Phase 3: Protactinium-234 (Pa-234).** Beta emitter to U-234. Still heavy, initially charged from previous step.  
- **Phase 4: Uranium-234 (U-234).** Alpha emitter to Th-230. Back to neutral after capturing an electron.  
- **Phase 5: Thorium-230 (Th-230).** Alpha to Ra-226. Heavy, neutral.  
- **Phase 6: Radium-226 (Ra-226).** Alpha to Radon-222. Heavy, neutral. Emits strong α.  
- **Phase 7: Radon-222 (Rn-222).** Alpha to Polonium-218. A gas phase with drifting movement. Neutral.  
- **Phase 8: Polonium-218 (Po-218).** Mostly α to Lead-214; *rarely* β to Astatine-218. (We could implement a 0.02% branch: if triggered, go to Astatine-218 instead of Pb-214 for an alternate path.)  
- **Phase 9: Lead-214 (Pb-214).** β to Bismuth-214. Now charged.  
- **Phase 10: Bismuth-214 (Bi-214).** Mostly β to Polonium-214; tiny α branch to Thallium-210. (Optional rare branch to implement as Easter egg.)  
- **Phase 11: Polonium-214 (Po-214).** α to Lead-210. Emits very short-lived α (fast timer phase). Neutral.  
- **Phase 12: Lead-210 (Pb-210).** β to Bismuth-210. Slight positive charge after decay.  
- **Phase 13: Bismuth-210 (Bi-210).** β to Polonium-210. Positive (or neutral if capturing electron).  
- **Phase 14: Polonium-210 (Po-210).** α to Lead-206 (stable). This final α-decay releases the last large burst, and the atom becomes Pb-206 – a stable lead atom.  

*(All isotopic data from the U-238 series.)*  

Key points: the overall chain has 8 α-decays and 6 β-decays. Each α-decay jumps two elements down; each β-decay moves one up. Only the last product (Pb-206) is stable. Rare branching decays (Po-218, Bi-214) can be hidden “lucky” routes. 


## Atom Attributes & Interactions  

Each isotope (phase) is characterized by its **atomic properties**, which we convert into game stats:  

- **Mass:** Proportional to atomic mass number (protons+neutrons).  Higher mass = slower acceleration and higher momentum. For example, U-238 (mass ~238) feels sluggish; Po-210 (mass 210) is lighter and quicker. (U-238 literally has 92 protons and 146 neutrons, giving it large mass.) This can be coded by setting the atom’s mass or inverse mass in the physics body.  
- **Charge:** Neutral atoms have balanced protons/electrons. After a **β⁻ decay**, the nucleus gains a proton but emits an electron, so the atom becomes positively charged (missing an electron). In gameplay terms, mark the new atom as +1 charge until it picks up an electron. Charged atoms respond to fields (see below).  α-decays remove a He nucleus (2p+2n) but we assume the atom leaves with neutral charge by ejecting 2 electrons, so the atom remains overall neutral after each α event. (As EPA notes, an α particle is 2 protons + 2 neutrons.)  
- **Valence/Electron count:** In a detailed model, one could track how many electrons the atom “should” have. A β-decay effectively drops an electron into the scene (which the player could collect). The atom might need to collect an electron later to return to neutral. We can simplify: only care about “charged” vs “neutral” state. However, valence could influence interactions in an advanced version (e.g. certain elements attract particular pickups).  
- **Stability:** Each isotope’s timer is its “instability.” Longer timers (like U-238, 2–3min) versus short timers (Po-214 decays in microseconds). We emulate this by the sampled countdown.  

**Universal interactions:** Every atom, charged or not, can use the same interaction rules:  
- **Electric fields:** Regions of space apply force $F=qE$ on charged atoms. A positive atom is pushed along the field; a neutral one is unaffected. We can place “positive/negative plates” in the map.  
- **Magnetic fields:** If desired, a magnet zone could curve the trajectory of moving charged atoms via a Lorentz force $F=q(v\times B)$. This requires velocity, charge, and a B-field direction. Practically, a “magnet” object could constantly push sidewise on a moving charged atom.  
- **Photon/Energy zones:** Areas of light that give kinetic boosts. Since actual photons are weightless, we treat them as pickups that grant speed or energy (score).  
- **Electron capture:** To simulate β⁺ or capture, we could include rare “free electron” sprites. If the atom enters an electron cloud, it might capture an electron and change its charge state (or gain points). Similarly, a dense electron zone could be a hazard causing an electron capture event, altering the atom’s future.  
- **Physical obstacles:** Walls or particles that can be broken if the atom is fast enough. For example, an “energy barrier” may block slow atoms but shatter under high-energy (fast) impact. Since we have no weapons, this is a way to let high speed act as an attack.  
- **Magnetic or gravitational traps:** Zones that hold atoms (like a magnetic trap for charged atoms, or a gravity well that pulls all atoms). Running into these could be either hazard (if you can’t escape) or a puzzle element (requiring charge changes).  

Overall, atoms change only by decay and by these interactions – players can’t shoot or collect foreign nuclei. All gameplay complexity comes from moving and maneuvering the current “atom” through fields, picking up score-items, and avoiding lethal regions.


## Scoring, Failure, & Progression  

- **Scoring:** Points are awarded for **collecting energy items** (photons, electrons, etc.) and possibly for swift decay completions (time bonuses). For example, each electron pickup might be +10 points, each photon +5. Unused time could convert to bonus at phase end.  If branching decays are implemented, taking the rare path could grant a big bonus. Roguelike tradition is to reward *treasure* and speed, so we mirror that: faster runs and more pickups = higher score. A final bonus could be given for reaching Pb-206 (winning).  
- **Failure Conditions:** A run ends (game over) if the atom is “destroyed.” This can happen via: colliding with a lethal hazard (neutron trap, high-energy explosion, bottomless pit), or being trapped so long that some simulated “half-life penalty” kills it. We could also say that if the atom decays too early (timer unexpectedly drops to zero in a hazard zone), it fails to properly transform and the run ends. In essence, touch any fatal obstacle = permadeath. As typical roguelikes use permadeath, the player restarts from Phase 1 after any death, and the run score is tallied on a leaderboard.  
- **Roguelike Progression:** Each run randomises key elements: the timers (via random ranges), placement of pickups/hazards, and even minor branching chances. There is no in-run save (no cheating), so every decision matters. We might include unlockables or meta-progression between runs (e.g. unlocked cosmetics, or starting options) but with only 3 days, focus on in-run design. A final performance screen shows how far the player got and the score, encouraging retry for higher score (like typical roguelikes).  

In summary, players try to *survive through all phases to Pb-206* while racking up points. Each failed run restarts with new random elements, making the challenge about strategy and luck. 


## 3-Day Godot 4 Implementation Plan  

1. **Day 1 – Core Engine & Movement:** Set up a Godot 4 project and scenes. Implement the player atom as a RigidBody2D (or custom KinematicBody2D with inertia) that accelerates toward the mouse cursor. Tune mass/inertia parameters for a good “floaty” feel. Create a timer system for phases: on entering a phase, sample a random duration (e.g. using `rand_range(120,180)`) and display a countdown. When time expires, trigger the `decay_to_next_isotope()` function. Also stub out a simple large play area with one collectible object and one hazard. Verify movement, pickup (increment score), and hazard collision (game over) work.  
2. **Day 2 – Phase Transitions & Interactions:** Implement all phase states: create data for each isotope (name, mass, next decay type). On decay, swap the player’s sprite and stats according to the new isotope. For example, in Godot change the atom’s mass, sprite, and charge flag. Set up the decay chain logic (hard-code or data-driven sequence of isotopes as above). Add a few environmental features: for example, one electric field zone (Area2D with a force on charged atoms) and one static obstacle that only breaks on high-speed impact. Populate the map with more pickups and hazards (randomly place a dozen each). Ensure that pickups vanish on contact and increment a score variable. Start work on the UI: show current phase (element symbol) and countdown, plus score.  
3. **Day 3 – Balancing & Polish:** Fill in remaining details. Tune each phase’s parameters: e.g. heavier isotopes move slower. Possibly add the charge mechanic: after a β-decay, mark the atom charged (+1) and allow it to interact with a second field. Test and balance timers so phases feel neither trivial nor impossible. Randomise the initial layout for each run (e.g. use a simple procedural scattering of objects). Implement the final goal: once Pb-206 phase ends, allow the atom to escape out of the container (triggering victory). Add game-over and win screens showing score/rank. Polish visuals (distinct color per isotope) and audio cues for decay. Ensure Godot 4’s physics run smoothly and fix bugs (collisions, off-by-one decays, etc.). The result will be a working 2D roguelike where the atom “counts down” through the nuclear decay chain, with physics-inspired interactions throughout.  

This plan focuses Day 1 on getting the **movement/timer loop**, Day 2 on **phases and game objects**, and Day 3 on **game feel and polish**, which is a reasonable scope for a 3-day jam. By the end, the player should experience each atomic phase as a timed gameplay mode, collecting points and dodging death until (hopefully) reaching Pb-206.  

**Sources:** We use the real uranium-238 decay chain as inspiration. Atomic properties (protons, neutrons) come from standard data (e.g. U-238 has Z=92, N=146).  For game design context, note that roguelikes emphasize score via pickups/time and permadeath with procedural variation.  References on decay clarify α/β particles and chains.