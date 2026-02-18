# NBA Jam Clone - Project Guidelines

## Game Overview

Arcade Basketball (NBA Jam-style): 2v2 half-court, fast exaggerated gameplay, simple controls, high responsiveness.

## Phase Workflow

When working on a phase, follow this process:

1. Complete all tasks in the phase
2. Write tests and make sure they pass
3. Review the code and refactor if needed
4. Make sure tests still pass after refactoring
5. Commit changes

## Phase Tracking

Each phase has a dedicated file in `docs/phases/`. Update the **Status** field in each file as you work (`Not Started` → `In Progress` → `Complete`). Check off individual feature checkboxes as they are implemented.

| Phase | File | Description |
|-------|------|-------------|
| 0 | [phase-00](docs/phases/phase-00-core-design-goals.md) | Core Design Goals |
| 1 | [phase-01](docs/phases/phase-01-core-game-loop.md) | Core Game Loop |
| 2 | [phase-02](docs/phases/phase-02-player-controller.md) | Player Controller |
| 3 | [phase-03](docs/phases/phase-03-ball-system.md) | Ball System |
| 4 | [phase-04](docs/phases/phase-04-shooting-system.md) | Shooting System |
| 5 | [phase-05](docs/phases/phase-05-dunk-layup-system.md) | Dunk & Layup System |
| 6 | [phase-06](docs/phases/phase-06-blocking-system.md) | Blocking System |
| 7 | [phase-07](docs/phases/phase-07-steal-defense-system.md) | Steal & Defense System |
| 8 | [phase-08](docs/phases/phase-08-ai-players.md) | AI Players (Arcade Style) |
| 9 | [phase-09](docs/phases/phase-09-camera-system.md) | Camera System |
| 10 | [phase-10](docs/phases/phase-10-game-rules.md) | Game Rules |
| 11 | [phase-11](docs/phases/phase-11-on-fire-streak-system.md) | "On Fire" / Streak System |
| 12 | [phase-12](docs/phases/phase-12-ui-hud.md) | UI / HUD |
| 13 | [phase-13](docs/phases/phase-13-juice-feedback.md) | Juice / Feedback Layer |
| 14 | [phase-14](docs/phases/phase-14-data-tuning.md) | Data & Tuning |
| 15 | [phase-15](docs/phases/phase-15-technical-architecture.md) | Technical Architecture |
| 16 | [phase-16](docs/phases/phase-16-stretch-features.md) | Stretch Features (Low Priority) |

## Core Design Principles

- Fast, exaggerated arcade gameplay (not simulation)
- Simple controls, high responsiveness
- Deterministic, readable game rules
- Modular systems, minimal coupling
- Config-driven tuning values
- Always keep a playable build
