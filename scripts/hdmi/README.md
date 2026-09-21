# hdmi

Fish function for managing an external display via `hyprctl` (Hyprland).

## Usage

```
hdmi [mirror|extend|off]
hdmi [--mirror|--extend|--off]
```

## Commands

| Command  | Description |
|----------|-------------|
| `mirror` | Mirror internal display to external |
| `extend` | Extend desktop to external display (positioned to the right) |
| `off`    | Turn off external display |

## Examples

```fish
hdmi mirror   # Mirror
hdmi extend   # Extend
hdmi off      # Turn off
```

## Requirements

- `hyprctl` — included with [Hyprland](https://hyprland.org/)

## Installation

```fish
cp hdmi.fish ~/.config/fish/functions/hdmi.fish
```
