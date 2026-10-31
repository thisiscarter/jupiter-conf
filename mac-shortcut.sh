#!/usr/bin/env bash
# mac-shortcut.sh
# Makes Cmd+<key> behave like macOS inside Hyprland.
#   GUI apps  : Cmd+C -> Ctrl+C, Cmd+T -> Ctrl+T, ...
#   Terminals : Cmd+C -> Ctrl+Shift+C (so it copies instead of sending SIGINT)
#
# Usage: mac-shortcut.sh <key> [SHIFT]
# Install to: ~/.config/hypr/scripts/mac-shortcut.sh  (and chmod +x it)
# Requires: hyprctl, jq

key="$1"
extra="$2"

class=$(hyprctl activewindow -j | jq -r '.class // ""' | tr '[:upper:]' '[:lower:]')

terminal=0
firefox=0
case "$class" in
  kitty|foot|footclient|alacritty|org.wezfurlong.wezterm|com.mitchellh.ghostty|konsole|*terminal*) terminal=1 ;;
  firefox|zen*|librewolf|floorp) firefox=1 ;;
esac

send() {
  # $1 = modifiers, $2 = key
  hyprctl dispatch sendshortcut "$1, $2, activewindow" >/dev/null
}

# ---- Terminals ---------------------------------------------------------------
if [ "$terminal" = 1 ]; then
  # Shift variants and most other shortcuts are left alone in terminals.
  [ -n "$extra" ] && exit 0
  case "$key" in
    c|v|t|n|w|equal|minus) send "CTRL SHIFT" "$key" ;;
    linedel)               send "CTRL" "u" ;;          # Cmd+Backspace: kill line
    wordel)                send "ALT" "BackSpace" ;;   # Option+Backspace: kill word
  esac
  exit 0
fi

# ---- Everything else ---------------------------------------------------------
case "$key" in
  linedel)
    # Cmd+Backspace: select to start of line, then delete
    hyprctl --batch "dispatch sendshortcut SHIFT, Home, activewindow; dispatch sendshortcut , BackSpace, activewindow" >/dev/null
    ;;
  wordel)
    send "CTRL" "BackSpace"
    ;;
  [0-9])
    # Cmd+1..9 = jump to tab. Chromium uses Ctrl+N, Firefox on Linux uses Alt+N.
    if [ "$firefox" = 1 ]; then send "ALT" "$key"; else send "CTRL" "$key"; fi
    ;;
  *)
    send "CTRL${extra:+ $extra}" "$key"
    ;;
esac
