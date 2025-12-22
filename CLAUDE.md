# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CLEAR-CITY is a Godot 4.5 game project using GL Compatibility renderer with a retro pixel-art aesthetic (320x240 base resolution with integer scaling).

## Running the Project

Open in Godot 4.5 and run with F5. Main scene is `vgapipes/test.tscn`.

## Architecture

### Global Autoload (`g`)
The `common/common.gd` script is autoloaded as `g` and provides:
- **Scene Manager**: Automatically scans and caches all `.tscn` files at startup. Spawn scenes by name: `g.spawn("scene_name")` or `g.spawn("scene_name", parent, position)`
- **Positioning**: `g.at(x, y)` sets pen position, `g.pen` holds current position
- **Utilities**: `g.somewhere(x1, y1, x2, y2)` returns random Vector2 in range

### State Machine Pattern (`StateMachineCharacterBody2D`)
Base class for actors with a behavior-based state machine:
- `act(callable)` - Set current behavior (called every physics frame)
- `await frame()` / `await frames(n)` - Wait for physics frames
- `await secs(n)` - Wait for seconds
- `passed(time)` - Check if time has elapsed since last check
- `time_counter` / `frame_counter` - Timing utilities

### Actor2D
Extends `StateMachineCharacterBody2D`, adds sprite sheet support:
- `sprite_texture`, `frame_width`, `frame_height` - Configure sprite sheet
- `current_frame` - Set displayed frame
- `set_sprite(texture, width, height)` - Configure sprite at runtime

### Editor Plugins

**REPL** (`addons/repl/`) - Currently enabled
- Bottom panel with command input for live GDScript evaluation
- Commands: `list` (show node tree), `spawn path/to/scene.tscn`, `attach node/path scene.tscn`, `debug`
- Expression context includes: `root`, `ei` (editor interface), `spawn()`, `attach()`

**Live Builder** (`addons/live_builder/`) - Available but not enabled
- Live scene editor panel

## Code Patterns

State machine actors use callable behaviors:
```gdscript
func init():
    act(func():
        # This runs every physics frame
        position.x += delta * speed
    )
```

Or coroutine-style with explicit frame waiting:
```gdscript
func init():
    while true:
        await secs(1)
        do_something()
```

## Project Structure

- `common/` - Shared utilities and base classes
- `vgapipes/` - Game-specific scenes and scripts (main test scene here)
- `addons/` - Editor plugins (repl, live_builder)
