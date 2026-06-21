#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PLUGIN_NAME="place-gamescope"

case "$1" in
  on)
    kscreen-doctor output.HDMI-A-4.enable

    qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$SCRIPT_DIR/place-gamescope.js" "$PLUGIN_NAME"
    qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.start

    gamescope -f -W 1920 -H 1080 -w 1920 -h 1080 -e -- steam -tenfoot &

    sleep 30
    qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$PLUGIN_NAME"
    ;;

  off)
    kscreen-doctor output.HDMI-A-4.disable
    qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$PLUGIN_NAME" 2>/dev/null || true
    ;;

  *)
    echo "Usage: $0 on|off" >&2
    exit 1
    ;;
esac
