# Thing Riot: A Surreal Survivors Game

Inspired by “Vampire Survivors” but with a surreal, whimsical twist!

## Premise

Survive against endless waves of oddball enemies, armed with the strangest arsenal ever—biscuits, dice, toy mallets, and more! Gain XP, level up, and unlock even more ridiculous weapon upgrades.

## Core Features

- Choose from 2 starting characters, each with unique stats.
- Battle on 2 wild, hand-crafted stages.
- 4 initial weapons: All weird, all upgradable.
- 3 enemy types, each with quirky behaviors.
- Modular codebase for easy addition of new content (characters, weapons, enemies, stages).
- Simple, chunky pixel art (homemade and proudly so).

## Controls

- Move: Arrow keys or WASD
- Attack: Automatic (or [SPACE] for testing)
- Pick up gems: Walk over them

## Roadmap

- [ ] Core movement & collision
- [ ] Char & stage selection menu
- [ ] Basic enemy spawns and waves
- [ ] XP & leveling
- [ ] Modular weapon/equipment system
- [ ] Sound & juice!

## Requirements

- Godot (latest stable)
- [Optional] Graphics editor for custom sprites (Aseprite, Piskel, etc.)

## How to Run

1. Clone the repo
2. Open the project in Godot
3. Hit Play!

## Core-loop stability update

- Multiple levels earned together give one choice each while combat stays paused.
- Starting again restores the original stats, XP and health.
- Armour reduces damage fractionally; exact HP is visible in the pause panel and heart tooltip. Half-heart icons round remaining HP upward; odd maximum HP now has its own final heart.
- Knockback upgrades strengthen crown hits against enemies. Clover adds 10% of the base crate-drop chance per upgrade (35% becomes 38.5% after one; capped at a 100% bonus).
- Capped upgrades stop appearing. Health pickups work during damage immunity. Crowns, enemies, crates and pickups cannot award duplicate hits or rewards in one frame.

### Regression tests
Requires Godot 4.3. From the repository root:

```sh
godot --headless --editor --path thing-riot-v1 --import
godot --headless --path thing-riot-v1 --script res://tests/core_loop_test.gd
```

The tests load the actual game scenes and exercise queued choices, armour, healing, capped upgrades, loot, projectile collisions, pause, death and restart.

## Step 2: Royal Crumble

Both weapons are equipped at the start of a run:

- **Returning Crown** pierces targets on its outward flight and steers back to your current position. Each target can take one hit per pass. Reposition to line up the return.
- **Biscuit Blaster** leaves six-second crumb patches on impact or at maximum range. Enemies in a patch move at 45% speed and stay coated for two seconds after leaving it.
- **Royal Crumble**: an outward crown hitting a coated enemy seeks another coated enemy within 240 pixels, up to three ricochets (five with upgrades). Rings and crumbs identify coated enemies without relying on colour.
- New upgrades expand patches, extend their duration, or add ricochets. Weapon definitions are editable resources in `weapons/`.

### Controls

Move with WASD, arrows, or the controller left stick. Auto-aim is the default. Hold the right mouse button or move the right stick to aim both weapons manually, including at crates; release to restore auto-aim. M toggles procedural weapon sounds. Existing pause/upgrade controls are retained.

This build also uses a closer 1280×800 view with window stretching, analogue movement, collision-aware knockback, and 320 crates distributed across the playable camera bounds. The temporary crate pile/debug spawns are removed.

### Weapon regression tests

```sh
godot --headless --path thing-riot-v1 --script res://tests/weapon_test.gd
```

This is the first two-weapon balance pass, not the later boss/run progression milestone.

For rendered QA, run `godot --path thing-riot-v1 --script res://tests/visual_smoke.gd`. This isolated fixture creates tough enemies, simulates movement, captures gameplay and upgrade PNGs in Godot's user-data directory, then exits. It does not change production enemy stats.


## Step 3: Arena tricks and a new King

The King now wears a gold crown, purple coat and swaying blue cape, with an ivory moustache and marching boots. His original vector artwork animates directly in Godot. A 14-pixel foot collision circle replaces the oversized body collision.

- **Bomb crates** show a bomb icon. Breaking one lights a 0.55-second fuse, then deals six damage within 170 pixels to enemies and other crates. Nearby bomb crates chain with their own warning delay. These player-triggered blasts do not hurt the King.
- **Spring pads** launch the King or enemies away from their centre, with a per-body cooldown. Use them to reposition or disrupt pursuing enemies.
- **Chargers** begin spawning after 20 seconds. Their outlined lane and countdown ring warn of a committed dash; step sideways or slow them with crumbs.
- **Casters** join after 40 seconds. They keep their distance and telegraph a straight projectile before firing. Both enemy types lock aim when their warning begins.
- Bomb crates and spring pads are distributed throughout the arena. A small introductory encounter near the start lets you try both immediately; the main crate distribution still spans the map.

Aim at bomb crates with RMB/right stick. The existing crown, biscuits and crumb chains interact with the new enemies and crates. Enemy and hostile-projectile populations are capped.

```sh
godot --headless --path thing-riot-v1 --script res://tests/arena_test.gd
```

Run this alongside the core and weapon suites (69 checks total). For rendered inspection, `godot --path thing-riot-v1 --script res://tests/arena_visual.gd` captures gameplay and an enlarged King portrait in the Godot user-data directory. Its frozen attack warnings and enlarged portrait are confined to the fixture. Difficulty and controller feel still need human playtesting.


## Step 4 performance pass

This patch addresses crowded-fight stutter reported after Step 3. It is the performance portion of the next milestone; Loaded Dice, further combinations and the Bureaucrab/run progression remain future work.

- Weapon projectiles query nearby physics shapes before performing their exact swept hit checks. Dense sweeps retain all contacts, and biscuits choose the nearest target along the sweep.
- Spring pads and crumb patches use physics-maintained overlap lists instead of scanning every enemy across the arena. New overlaps become available after physics synchronisation.
- Enemy damage sensors no longer appear as duplicate weapon targets. Crate hurtboxes remain queryable without monitoring nearby bodies.
- Enemy artwork redraws when its state changes; warning rings still animate. Idle bomb crates stop processing, and hostile bolts cache the player reference and their unchanged drawing.
- Press **F3** during gameplay to toggle FPS, physics time and enemy/projectile counts. Counters refresh twice per second while visible.

### Validation and performance

The previous development session passed all 78 checks: core (34), weapons (16), arena (19), and collision queries (9). The collision suite includes a 141-enemy sweep, crate detection, per-pass hit guards and nearest-target selection.

```sh
godot --headless --editor --path thing-riot-v1 --import
godot --headless --path thing-riot-v1 --script res://tests/core_loop_test.gd
godot --headless --path thing-riot-v1 --script res://tests/weapon_test.gd
godot --headless --path thing-riot-v1 --script res://tests/arena_test.gd
godot --headless --path thing-riot-v1 --script res://tests/collision_query_test.gd
godot --headless --fixed-fps 60 --path thing-riot-v1 --script res://tests/combat_benchmark.gd
```

Use Godot 4.3 and the same machine/settings for comparisons. The benchmark creates 180 durable enemies (120 casters), 24 initial crumb patches and boosted weapon fire in an isolated fixture. It samples wall-frame time and script callback time after warmup. Script timing excludes physics-server work outside those callbacks. `--fixed-fps 60` fixes simulation steps; these are offline timings, not displayed FPS.

One recorded headless comparison against Step 3 reduced median wall-frame time from 24.504 to 6.390 ms, and p95 from 53.767 to 11.855 ms. Script callback medians were 18.145 and 2.897 ms. Both runs used the same temporary two-worker setting; that setting is not shipped. These results are preliminary and hardware-dependent. Rendered stress validation was not completed, so Windows/controller playtesting remains necessary. Try F3 during a crowded fight and report FPS plus enemy/shot counts if stutter remains.
