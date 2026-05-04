# Oksishuter

3D FPS Wave Survival Shooter made with Godot 4.6

## Gameplay
- First-person wave-based shooter
- Survive enemy waves that get progressively harder
- Earn coins by killing enemies and completing waves
- Touch controls optimized for mobile play

## Controls (Mobile)
- **Left side of screen**: Drag to move (virtual joystick)
- **Right side of screen**: Drag to look around
- **FIRE button**: Shoot
- **RELOAD button**: Reload weapon

## Controls (Desktop)
- **WASD**: Move
- **Mouse**: Look around
- **Left Click**: Shoot
- **R**: Reload

## How to Open in Godot Web Editor
1. Download this repo as ZIP from GitHub (Code → Download ZIP)
2. Go to [Godot Web Editor](https://editor.godotengine.org)
3. Click "Import" and select the ZIP file
4. Open the project

## Project Structure
```
project.godot          - Project configuration
scenes/                - Scene files (.tscn)
  main_menu.tscn       - Main menu scene
  game_world.tscn      - Game level scene
  hud.tscn             - HUD overlay scene
scripts/               - GDScript files (.gd)
  game_data.gd         - Global game data (autoload)
  main_menu.gd         - Main menu logic
  game_manager.gd      - Wave system & level builder
  player.gd            - FPS player controller
  enemy.gd             - Enemy AI
  hud.gd               - HUD & touch controls
textures/              - Game textures
  enemies/             - Enemy sprites
  ui/                  - UI textures
```
