# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Darkblue is a beat-synchronized shoot-em-up subproject within CLEAR-CITY. Resolution: 525x350. BPM: 143.

## Running

Main game: `modes/game_mode.tscn`. Test scenes in `tests/`.

## Autoloads

**`g`** (extends `common/common.gd` via `scripts/darkblue.gd`):
- `g.p1` - player ship reference
- `g.energy` - player health/energy
- `g.playfield` - main game node
- `g.spawn("scene_name", parent, position)` - instantiate cached scene
- `g.sfx(stream, volume, bus)` - self-choking sound effect

**`beat`** (`common/beat.gd`):
- `beat.bpm`, `beat.scale` (seconds per beat), `beat.current_beat`
- `await beat.wait(4)` - wait 4 beats
- Signals: `beat_hit`, `measure_hit`

**`enemies`** (`scripts/enemies.gd`):
- `enemies.get_stats("enemy_name")` returns `{hp, atk, bounty}`
- Override per-stage via `EnemyStatsSet` subclass in StageConfig

## Class Hierarchy

```
StateMachineCharacterBody2D
  └─ Actor2D
       └─ Vessel2D (scripts/vessel_2d.gd)
            ├─ Ship (actors/ship.gd)
            └─ enemy_* (actors/enemy_*.gd)
```

**Vessel2D** - Combat entity base:
- `hp`, `atk`, `bounty`, `r` (collision radius)
- `damage(amount)`, `die()`
- Auto-loads stats from `enemies` autoload based on scene filename

## Orchestration

**Sequence** (`common/sequence.gd`) - Timeline via AnimationPlayer:
- Child Sequences launched via `next()` method track calls
- `timing_mode`: NORMAL (seconds) or MUSICAL (beat-scaled)
- `start_mode`: IMMEDIATE, ON_PARENT, ON_NODE, ON_SIGNAL

**Wave** (`scripts/wave.gd`) - Scripted wave sequences:
```gdscript
extends Wave
func run():
    await beats(4)
    start($Formation)
    await beats(8)
    next_wave()
```

**Encounter** (`scripts/encounter.gd`) - Animation-driven enemy formation, frees self when done.

## Configuration Nodes

**StageConfig** - Per-stage parameters:
- `enemy_stats`, `starting_energy`, `invincibility`
- `enemy_bullet_factor`, `burst_force_factor`, `damage_deadzone`

**BeatConfig** - Tempo configuration:
- `bpm`, `music` (WAV), `start_from_beat` (debug)

## Code Patterns

Enemy with musical animation:
```gdscript
func init():
    animation = range(25)
    animationSpeed = musical_anim_speed(animation, 2)  # 2-beat cycle
```

Coroutine behavior:
```gdscript
func init():
    while true:
        await beats(2)
        shoot()
```

## Structure

- `actors/` - Ship, enemies, projectiles (tri, orb, shot)
- `scripts/` - Core systems (vessel_2d, wave, enemies, playfield, encounter)
- `effects/` - Visual effects, LCD shader stack
- `modes/` - Game mode scenes
- `tests/` - Development test scenes
