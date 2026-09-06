Purpose:
This document describes the planned core gameplay systems and their responsibilities for the “Thing Riot” project. Each section can serve as a reference for AI agents (e.g., GitHub Copilot/Codex) or collaborators to understand, implement, or extend specific features in GDScript.

1. Title Screen System
Goal:
Display a start menu before gameplay. When the player presses “Start” (button or key), transition to the main game.

Responsibilities:

Show game title and simple menu (Start, maybe Quit).

Await player input to start.

On “Start,” load the main gameplay scene and initialize game state.

2. Game Over System
Goal:
Display a “Game Over” screen when the player loses (or optionally, wins), with an option to restart.

Responsibilities:

Detect end-of-game condition (e.g., player HP reaches zero).

Pause/stop the main gameplay loop.

Display Game Over UI.

Provide option to restart the game (resets all variables/scenes to starting state).

3. Auto-Attack System
Goal:
Enable the player character to automatically attack enemies in range at set intervals.

Responsibilities:

Detect when enemies are within attack range of the player.

Trigger an attack on the nearest (or all) enemies every X seconds.

Reduce enemy HP by attack value.

Optionally trigger attack animations/effects.

4. Enemy Damage System
Goal:
Manage enemy health, apply damage from attacks, and handle death/removal of defeated enemies.

Responsibilities:

Track each enemy’s current HP.

Subtract damage when attacked.

Detect when HP ≤ 0; remove enemy from game, play death animation/effects.

Optionally trigger player rewards (score, loot) upon enemy death.

5. Enemy Spawning System
Goal:
Continuously or periodically spawn new enemies into the game world.

Responsibilities:

Spawn enemies at set intervals, or based on conditions (e.g., max enemies on screen).

Randomize spawn location, within allowed areas.

Optionally scale difficulty over time (more/faster/tougher enemies).

6. Main Game Loop
Goal:
Coordinate all core systems during gameplay, updating game state, checking win/lose conditions, and managing transitions.

Responsibilities:

Update player and enemy positions, attacks, and health every frame.

Handle spawning, deaths, and removal of game objects.

Check for game over/win condition.

Transition between Title, Gameplay, and Game Over as needed.

Note for AI Agents:
Each system should be implemented as a modular script/component, using Godot’s recommended scene structure and best practices for GDScript. Focus on clear signals and separation of responsibilities.
Document any changes or additions below.
- Added title screen scene (title_screen.tscn) loading main game on Start.

- Core-loop stability: Main owns queued-upgrade pause transitions. Picker hides before emitting its selection and subsequent choices open deferred. Player duplicates stats per run; damage/death/pickup paths guard duplicate callbacks. Armour uses fractional HP; crowns apply outgoing knockback; luck increases crate drops.
- Regression command (Godot 4.3): `godot --headless --path thing-riot-v1 --script res://tests/core_loop_test.gd`. Import once first with `godot --headless --editor --path thing-riot-v1 --import`.

- Step 2: `weapons/weapon_controller.gd` owns targeting, independent cooldowns, procedural audio and recipe feedback. `RiotWeaponSpec` resources are duplicated per run. `riot_projectile.gd` sweeps collision segments; hits are limited per pass, ricochets are capped, and crown returns track the player. `crumb_patch.gd` bounds patch lifetime/population.
- Player movement and crate placement share the camera's playable bounds. Crates use stratified arena placement, not a player-centred ring. Do not reintroduce test props into production spawning.
- Run both `core_loop_test.gd` and `weapon_test.gd` after combat changes. For visual QA, use a separate fixture with tough enemies to make crumb chains observable; do not alter production enemy HP for screenshots.

- Step 3: `arena/` owns delayed bomb chains, bumper impulses, tactical enemy states and swept hostile bolts. Base enemies expose `_desired_velocity` so attack states retain existing knockback, crumbs and death handling. Telegraph directions lock at windup; bombs are friendly environmental weapons.
- `characters/king_visual.gd` provides original animated vector artwork. Player collision is a 14-pixel circle at the feet, independent of portrait proportions.
- Production spawning includes a deliberate introductory bomb pair and spring pad; the rest remains spread across the arena. Screenshot-only actors stay in `tests/arena_visual.gd`.
- Combat regression gate now includes `tests/arena_test.gd` alongside the core and weapon suites (34 + 16 + 19 checks). Rendered QA can use `tests/arena_visual.gd`.

- Step 4 performance pass: projectiles use reusable broad-phase shape queries on collision layer 2, followed by exact swept centre-distance checks and ordered contacts. Enemy bodies and crate HurtBoxes supply query geometry; damage sensors use layer 0 and only monitor the player/map layer.
- Bumpers and crumb patches use Area2D body overlaps. Tests must allow physics synchronisation after spawning/moving sensor fixtures. Redraw static artwork only on state changes; retain continuous attack telegraphs.
- Combat regression gate includes `tests/collision_query_test.gd` (78 checks across all four suites). `tests/combat_benchmark.gd` requires `--fixed-fps 60` for comparable offline samples. F3 displays sampled performance counters during play. Do not replace population/behaviour with benchmark fixture settings in production.

- Step 4 gameplay: Main creates `run/run_director.gd`, which owns the pausable run clock, wave breaks, one-time boss entrance and guarded results transition. Spawner reads the director clock. Results move through a consumed SceneTree metadata snapshot, not persistent player stats.
- `weapons/loaded_die.gd` supplies bounded timed AoE; crowns cash dice into Royal Wager via `cash_out(true)`. Dice share the projectile cap and cannot recursively detonate each other. Resources remain per-run duplicates. UpgradePicker records chosen titles for the build summary.
- `run/bureaucrab.gd` inherits normal enemy targeting/collision but handles boss death through the director. Four separate stamp attacks precede combined rectangles below half health. `run/stamp.gd` locks geometry on creation and applies damage once after warning.
- Five-suite gate: run core, weapon, arena, collision-query and run tests (112 checks). Disable RunDirector in fixtures that intentionally place enemies outside the playable encounter radius. `tests/run_visual.gd` stages boss and results screenshots without changing production settings. Full-run duration is a balance target, not a timed loss condition.
