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
