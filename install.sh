#!/usr/bin/env bash
set -e

# Каталог, где находится сам скрипт (корень репозитория)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

chmod +x "$BIN_DIR/"* 2>/dev/null || true

# Идемпотентность: не добавлять повторно
if grep -qF "$BIN_DIR" ~/.bashrc; then
    echo "Уже прописано в ~/.bashrc: $BIN_DIR"
else
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> ~/.bashrc
    echo "Добавлено в ~/.bashrc: $BIN_DIR"
fi

echo "Выполните: source ~/.bashrc"