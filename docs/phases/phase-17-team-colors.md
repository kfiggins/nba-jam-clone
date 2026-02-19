# Phase 17: Team Color Differentiation

**Status:** Complete

## Goal
Make players visually distinguishable by team so the player knows who is on their team and who is an opponent.

## Requirements

- [x] Team 1 players use a distinct color (e.g., blue)
- [x] Team 2 players use a distinct color (e.g., red/orange)
- [x] Colors are applied at runtime based on `player.team` property
- [x] Human-controlled player has a visible indicator (e.g., arrow or outline) to distinguish from AI teammate

## Implementation Notes

- Player scene currently uses a hardcoded blue `ColorRect` for `BodySprite`
- Apply `modulate` or change `color` property on the `BodySprite` node in `player.gd:_ready()`
- Team colors can be defined as constants or added to `GameConfigData`
- Add a small indicator (triangle/arrow) above the human player
