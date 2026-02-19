# Phase 18: Start Screen, Pause Menu & Quit

**Status:** Complete

## Goal
Add a title/start screen, an in-game pause menu, and the ability to quit back to the title screen.

## Requirements

- [x] Title screen scene with "Press Start" (or key) to begin
- [x] Title screen shows game name
- [x] Pause menu triggered by Escape key during gameplay
- [x] Pause menu pauses the game tree
- [x] Pause menu has Resume, Restart, and Quit to Title options
- [x] Quit to Title returns to the title screen scene
- [x] Add `pause` input action to project.godot

## Implementation Notes

- Create `scenes/ui/title_screen.tscn` as a new scene
- Change `project.godot` main scene to title screen
- Title screen transitions to `main.tscn` on start
- Pause menu can be a `CanvasLayer` overlay in `main.tscn` with `process_mode = ALWAYS`
- Use `get_tree().paused = true/false` for pause
- Use `get_tree().change_scene_to_file()` for scene transitions
