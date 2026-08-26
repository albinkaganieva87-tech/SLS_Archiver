#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/Sussy.sh"

if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo
    echo "SLS Archivizer - Ошибка"
    echo
    echo "Файл Sussy.sh не найден!"
    echo
    echo "Ожидаемый путь:"
    echo "$SCRIPT_PATH"
    echo
    read -r -p "Нажмите Enter для выхода"
    exit 1
fi

chmod +x "$SCRIPT_PATH"

exec "$SCRIPT_PATH" "$@"
