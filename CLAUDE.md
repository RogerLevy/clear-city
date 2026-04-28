# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CLEAR-CITY is a multi-project Godot 4.5 workspace using GL Compatibility renderer. Subprojects share common infrastructure and can extend the base autoload.

## Subprojects

- `darkblue/` - Beat-synchronized shoot-em-up (see `darkblue/CLAUDE.md`)
- `vgapipes/` - Earlier prototype

## Running

Open in Godot 4.5, run with F5. Change main scene in Project Settings or use run configurations.

## Common Infrastructure

### Autoload (`g`) - `common/common.gd`
Subprojects extend this (e.g., `darkblue/scripts/darkblue.gd`):
- `g.spawn("scene_name", parent, position)` - instantiate cached scene
- `g.at(x, y)` sets pen position, `g.spawn()` uses it if no position given
- `g.sfx(stream, volume, bus)` - self-choking sound effects
- `g.playfield` - main game node reference

### Beat System (`beat`) - `common/beat.gd`
Sample-accurate tempo synchronization:
- `beat.bpm`, `beat.scale` (seconds per beat), `beat.current_beat`
- `await beat.wait(n)` - wait n beats
- `beat.play_music(stream, from_beat)` - start with music (WAV only)
- Signals: `beat_hit`, `measure_hit`, `sequence_signal`
- Configure per-scene with `BeatConfig` node

### State Machine (`StateMachineCharacterBody2D`)
Base class for actors:
- `act(callable)` - set behavior (called every physics frame)
- `await frame()`, `await frames(n)`, `await secs(n)`, `await beats(n)`
- `passed(time)` - check if time elapsed since last check

### Actor2D
Extends state machine, adds sprite sheet support:
- `sprite_texture`, `frame_width`, `frame_height`, `current_frame`
- `animation` array + `animationSpeed` for frame cycling
- `musical_anim_speed(frames, period)` - sync to beat

### Sequence System (`common/sequence.gd`)
Timeline orchestration via AnimationPlayer:
- Child Sequences launched via `next()` method track calls
- `timing_mode`: NORMAL (seconds) or MUSICAL (beat-scaled)
- `start_mode`: IMMEDIATE, ON_PARENT, ON_NODE, ON_SIGNAL

## Code Patterns

Callable behavior:
```gdscript
func init():
    act(func():
        position.x += delta * speed
    )
```

Coroutine-style:
```gdscript
func init():
    while true:
        await beats(2)
        do_something()
```

## Structure

- `common/` - Shared base classes, beat system, sequence system
- `addons/` - Editor plugins (repl, sequence_editor, favorites, etc.)
- `darkblue/`, `vgapipes/` - Subprojects
