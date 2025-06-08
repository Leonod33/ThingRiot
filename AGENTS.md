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
