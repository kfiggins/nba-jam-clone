# Phase 18: Start Screen, Pause Menu & Quit

**Status:** Not Started

## Goal
Add a title/start screen, an in-game pause menu, and the ability to quit back to the title screen.

## Requirements

- [ ] Title screen scene with "Press Start" (or key) to begin
- [ ] Title screen shows game name
- [ ] Pause menu triggered by Escape key during gameplay
- [ ] Pause menu pauses the game tree
- [ ] Pause menu has Resume, Restart, and Quit to Title options
- [ ] Quit to Title returns to the title screen scene
- [ ] Add `pause` input action to project.godot

## Implementation Notes

- Create `scenes/ui/title_screen.tscn` as a new scene
- Change `project.godot` main scene to title screen
- Title screen transitions to `main.tscn` on start
- Pause menu can be a `CanvasLayer` overlay in `main.tscn` with `process_mode = ALWAYS`
- Use `get_tree().paused = true/false` for pause
- Use `get_tree().change_scene_to_file()` for scene transitions
