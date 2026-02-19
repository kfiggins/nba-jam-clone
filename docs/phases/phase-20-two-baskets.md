# Phase 20: Two Baskets (Full Court)

**Status:** Not Started

## Goal
Add a second basket on the left side of the court so each team attacks a different basket, matching NBA Jam's full-court style where each team has an offensive and defensive end.

## Requirements

- [ ] Left basket added at mirrored position (e.g., ~150, 360)
- [ ] Each basket has a `team_target` property indicating which team scores on it
- [ ] Team 1 attacks the right basket, Team 2 attacks the left basket
- [ ] Shot system targets the correct basket based on shooter's team
- [ ] Dunk system targets the correct basket based on dunker's team
- [ ] AI navigates toward the correct basket on offense
- [ ] Inbound positions adjusted per team (inbound near own basket)
- [ ] Basket group or lookup updated to find the correct basket per team

## Implementation Notes

- Current basket is at (1130, 360) — add second at (~150, 360)
- Add `team_target: int` export to `basket.gd`
- Update `_find_basket()` in shot_state.gd to filter by team
- Update `is_in_dunk_range()` in player.gd to target correct basket
- Update AI controller basket references
- Update inbound_position logic to be team-aware
