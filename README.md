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
