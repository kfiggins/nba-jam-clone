# Phase 19: Player Boundary Clamping

**Status:** Not Started

## Goal
Prevent players (and ball) from moving outside the court boundaries. Players and ball should stay within bounds at all times.

## Requirements

- [ ] Players cannot move outside `court_bounds` from `GameConfigData`
- [ ] Position is clamped after `move_and_slide()` in player movement
- [ ] Ball position clamping is verified in all ball states (not just loose)
- [ ] Boundary feels natural — player stops at edge, no jittering

## Implementation Notes

- `court_bounds` is already defined in `GameConfigData` as `Rect2(80, 80, 1120, 560)`
- Add position clamping in `player.gd:apply_movement()` after `move_and_slide()`
- Ball loose state already clamps — verify held/pass/shot states also respect bounds
- Rect2 uses (x, y, width, height) so actual bounds are x:[80, 1200], y:[80, 640]
