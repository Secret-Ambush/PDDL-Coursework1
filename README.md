### README
## Lunar Exploration Planning in PDDL: Domain, Missions, and Design Rationale

### Abstract
This report documents the design and implementation of a PDDL domain and three planning problems modeling a simplified lunar exploration scenario. We formalize rover and lander operations for mobility, data acquisition, communication, and sample handling. We first present the baseline domain used in Part A&B and then the extended domain in Part C that introduces human operators (astronauts) and rooms that gate certain actions. For each mission, we specify the initial state, goals, salient constraints, and how the domain supports the required plans. We conclude with modeling choices, assumptions, and potential extensions.

### Contents
- Overview and Modeling Objectives
- Domain (Part A&B): Types, Predicates, Actions, Invariants
- Missions (Part A&B): Mission 1 and Mission 2
- Domain Extension (Part C): New Types, Predicates, Actions, and Constraints
- Mission 3 (Part C): Problem Setup and Goal Satisfaction
- Assumptions, Design Trade-offs, and Limitations
- Reproducibility Notes

### Overview and Modeling Objectives
The planning tasks capture a typical robotic exploration pipeline:
- Place landers at feasible sites, deploy rovers, and move rovers along directed paths.
- Acquire images and scans at specific waypoints, buffering data in rover memory.
- Transmit buffered data to a lander (and later, with an astronaut in the control room in Part C).
- Collect geologic samples and store them at an associated lander subject to capacity constraints.

The key objectives driving the model were: (i) action preconditions that mirror operational pre-requisites, (ii) explicit representation of data lifecycles (acquisition → ready-for-transmission → collected), (iii) clean separation of mobility and logistics, and (iv) scalability to multi-rover and multi-lander settings with partial coupling.

---
## Domain (Part A&B)

### Types
- rover, lander, location, sample, data
- image ⊑ data, scan ⊑ data

This supports multi-typed data artifacts and enables generic handling where appropriate (e.g., transmission over the common supertype `data`).

### Predicates
- Positions and placement: `rover-at(r, l)`, `lander-at(la, l)`, `lander-placed(la)`, `possible-lander-location(l)`
- Connectivity: `path-from-to(from, to)` for directed traversability
- Deployment and association: `rover-belongs-to(r, la)`, `rover-deployed(r)`
- Memory and data lifecycle: `has-mem-space(r)`, `image-ready-for-transmission(img)`, `scan-ready-for-transmission(sc)`, `collected-data(d)`
- World facts: `image-at(img, l)`, `scan-at(sc, l)`, `sample-at(s, l)`
- Sample handling: `carrying-sample(r, s)`, `sample-stored(s, la)`, `lander-full(la)`

Design notes:
- We model directed connectivity to allow one-way arcs; this matches provided waypoint graphs.
- The memory model abstracts capacity to a Boolean `has-mem-space(r)` representing one-slot memory, enforcing a collect→transmit cycle.
- Data readiness predicates encode the transient state between acquisition and successful transmission, after which `collected-data(d)` records persistence.

### Actions
1) place-lander(la, l)
- Preconditions: lander not yet placed; `possible-lander-location(l)`
- Effects: `lander-placed(la)`, `lander-at(la, l)`
- Rationale: Explicit siting to bind lander to a location once.

2) deploy-rover(r, la, l)
- Preconditions: `lander-placed(la)`, `lander-at(la, l)`, `rover-belongs-to(r, la)`, not `rover-deployed(r)`
- Effects: `rover-deployed(r)`, `rover-at(r, l)`
- Rationale: Deployment ties rover initial pose to its parent lander’s location.

3) move(r, from, to)
- Preconditions: `rover-at(r, from)`, `path-from-to(from, to)`, `rover-deployed(r)`
- Effects: remove `rover-at(r, from)`, add `rover-at(r, to)`
- Rationale: Directed motion only along admissible arcs; disallows teleportation and pre-deployment motion.

4) take-image(r, img, l)
- Preconditions: `rover-at(r, l)`, `image-at(img, l)`, `has-mem-space(r)`, not `collected-data(img)`
- Effects: remove `has-mem-space(r)`, add `image-ready-for-transmission(img)`
- Rationale: Consumes memory slot; prevents re-acquisition after collection.

5) perform-scan(r, sc, l)
- Preconditions: `rover-at(r, l)`, `scan-at(sc, l)`, `has-mem-space(r)`, not `collected-data(sc)`
- Effects: remove `has-mem-space(r)`, add `scan-ready-for-transmission(sc)`
- Rationale: Symmetric to imaging.

6) transmit-data(r, data, la)
- Preconditions: not `has-mem-space(r)` and data is ready (image or scan)
- Effects: add `has-mem-space(r)`, remove readiness flags, add `collected-data(data)`
- Rationale: Frees memory and marks data as persistently collected. The lander argument models logical handoff even without an explicit `lander-at` precondition in Part A&B (the physical channel is abstracted; see Part C for a stricter gate).

7) pick-sample(r, s, l)
- Preconditions: `rover-at(r, l)`, `sample-at(s, l)`, not `carrying-sample(r, s)`
- Effects: `carrying-sample(r, s)`, remove `sample-at(s, l)`
- Rationale: Lifts a sample; single-sample carry policy is implied by the action schema plus goal structure.

8) drop-sample(r, s, la, l)
- Preconditions: carrying the sample; co-located with lander; lander not full; rover belongs to lander
- Effects: remove `carrying-sample`, add `sample-stored(s, la)`, set `lander-full(la)`
- Rationale: Models a one-slot lander cache per mission instance; enforces association consistency.

Invariants and safety conditions (informal):
- Deployment is monotonic: a rover cannot be “undeployed”.
- Lander placement is monotonic and single-location.
- Mobility is constrained to directed edges only.
- Data objects cannot be “re-acquired” after `collected-data(d)` holds.
- Memory alternates between free and occupied states: acquisition requires free; transmission frees it.

---
## Missions (Part A&B)

### Mission 1 (`mission1.pddl`)
Objects include five waypoints, one rover, one lander, one sample, one image, and one scan. The initial state provides potential lander sites at wp1–wp5 and a directed path network connecting the waypoints. The goals require:
- Lander placement
- Image collected at wp5 and scan collected at wp3 (via acquisition then transmission)
- Sample from wp1 stored at the lander

Implications:
- Planner must choose a feasible initial lander location (any of the possible sites) before deploying the rover.
- The single-slot memory requires interleaving acquisition and transmission actions to avoid deadlock.
- Directed arcs enforce particular route choices, e.g., wp3→wp5→wp1 cycles.

### Mission 2 (`mission2.pddl` with baseline domain)
Expands to two landers and two rovers, with `lander1` pre-placed at wp2 and `lander2` to be placed. `rover1` is pre-deployed at wp2; `rover2` belongs to `lander2` and must be deployed after `lander2` is placed. Goals include collecting two images and two scans at specified waypoints and storing two samples, each at a designated lander.

Implications:
- Interactions between two rovers are independent except for shared paths; the domain allows concurrent progress if the planner supports it.
- Sample storage is tied to the correct lander via `rover-belongs-to` and explicit goal constraints.
- The memory model scales to multiple rovers without cross-coupling.

---
## Domain Extension (Part C)

### New Types
- astronaut; room with subtypes `controlRoom`, `dockingBay`

### Additional Predicates
- Astronaut assignment and location: `astronaut-assigned-to(a, la)`, `astronaut-at-room(a, r)`

All prior predicates are retained. Astronauts introduce organizational constraints on operations.

### Extended/Added Actions
1) move-astronaut-to-room(a, la, r)
- Preconditions: astronaut is assigned to `la` and not already at `r`
- Effects: places astronaut in `r`
- Rationale: Abstracts movement within the habitat; used to gate other actions.

2) deploy-rover(a, d, r, la, l)
- Preconditions: as before, plus astronaut at `dockingBay`
- Effects: as before
- Rationale: Operationalizes human-in-the-loop deployment.

3) transmit-data(r, a, c, data, la)
- Preconditions: as before, plus astronaut assigned to `la` and at `controlRoom`
- Effects: frees memory, clears readiness, marks `collected-data(data)`
- Rationale: Models supervised communication via control room.

4) drop-sample(r, a, d, s, la, l)
- Preconditions: as before, plus astronaut assigned to `la` and at `dockingBay`
- Effects: stores sample and sets `lander-full(la)`
- Rationale: Human-assisted sample intake.

Unchanged actions: `place-lander`, `move`, `take-image`, `perform-scan`, `pick-sample`.

Design effect:
- Part C tightens operational safety by coupling specific actions to astronaut presence in role-specific rooms. This acts as a policy layer enforcing realistic procedures while keeping rover mobility unchanged.

---
## Mission 3 (`mission3.pddl` with extended domain)
Setup mirrors Mission 2 but adds two astronauts (`alice`, `bob`) assigned respectively to `lander1` and `lander2`. `alice` starts at `dockingBay` and `bob` at `controlRoom`. The initial state includes the same directed path structure and sensing/collection targets.

Goal satisfaction:
- `lander2` must be placed; `rover2` deployed by an astronaut at the docking bay.
- Data transmission for both rovers requires an astronaut at the control room of the corresponding lander.
- Sample drops require astronaut presence at the docking bay and correct rover–lander association.

These gates ensure a plan that sequences astronaut room movements with rover activities, maintaining the same data and sample lifecycles under supervision.

---
## Assumptions, Design Trade-offs, and Limitations
- Directed connectivity: We intentionally use `path-from-to` to encode one-way mobility, capturing asymmetric terrain or navigation policies.
- Single-slot memory: A Boolean `has-mem-space(r)` models minimal onboard storage. This forces interleaving acquisition and transmission and simplifies capacity reasoning. Generalizing to multi-slot memory is a natural extension via a numeric fluent in temporal PDDL (not used here).
- Lander capacity: `lander-full(la)` abstracts a one-sample capacity in the mission instances. If multiple samples must be stored per lander, the model should switch to a counter or remove the capacity predicate and encode per-sample goals only.
- Transmission locality (Part A&B): Transmission does not require spatial co-location with a lander; it abstracts a communication link. Part C tightens this via astronaut control-room mediation, a more conservative operational assumption.
- Association consistency: `rover-belongs-to` ensures drops occur at the correct lander and prevents cross-lander misuse.

Potential extensions:
- Multi-slot memory and limited bandwidth with explicit queues.
- Energy budgeting and recharging actions.
- Terrain risk with stochastic failure modes (outside classical PDDL STRIPS scope).
- Shared lander capacity and multi-sample logistics with numeric fluents.

---
## Reproducibility Notes
- Domains and problems:
  - Part A&B domain: `PartA&B/domain.pddl`
  - Missions: `PartA&B/mission1.pddl`, `PartA&B/mission2.pddl`
  - Part C domain: `PartC/domain-ext.pddl`
  - Mission 3: `PartC/mission3.pddl`
- Requirements: `:strips :typing`
- Any classical planner supporting STRIPS with typing (e.g., Fast Downward with appropriate translator) can solve these problems.
- Typical run (example with downward): translate domain and problem, then run a blind or heuristic (e.g., A* with LM-cut); solutions should exhibit the acquisition–transmission alternation and astronaut gating in Part C.
