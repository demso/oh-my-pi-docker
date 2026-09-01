#!/usr/bin/env bash
set -e

# Тот же каталог bin, который добавлял install.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

BASHRC="${HOME}/.bashrc"

if [ ! -f "$BASHRC" ]; then
    echo "~/.bashrc не найден — удалять нечего."
    exit 0
fi

# --- 1. Удаляем записи из ~/.bashrc ---
if grep -qF -- "$BIN_DIR" "$BASHRC"; then
    BACKUP="$BASHRC.uninstall.$(date +%Y%m%d%H%M%S).bak"
    cp "$BASHRC" "$BACKUP"

    grep -vF -- "$BIN_DIR" "$BASHRC" > "$BASHRC.tmp" && mv "$BASHRC.tmp" "$BASHRC"

    REMOVED=$(( $(wc -l < "$BACKUP") - $(wc -l < "$BASHRC") ))
    echo "Удалено строк из ~/.bashrc: $REMOVED (бэкап: $BACKUP)"
else
    echo "В ~/.bashrc нет записей с $BIN_DIR"
fi

# --- 2. Убираем путь из PATH текущей сессии ---
if printf '%s' "$PATH" | tr ':' '\n' | grep -qxF -- "$BIN_DIR"; then
    PATH="$(printf '%s' "$PATH" | tr ':' '\n' \
        | grep -vxF -- "$BIN_DIR" | paste -sd: -)"
    export PATH
    echo "Путь убран из PATH текущей сессии."
fi

echo "Готово. В уже открытых окнах Git Bash выполните: source ~/.bashrc"