#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/Sussy.sh"

if [ ! -f "$SCRIPT_PATH" ]; then
    osascript -e 'display dialog "Файл Sussy.sh не найден!" with title "SLS Archivizer - Ошибка" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

chmod +x "$SCRIPT_PATH"

exec "$SCRIPT_PATH" "$@"
