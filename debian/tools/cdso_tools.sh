#!/bin/sh

info() {
    echo "[•] $*"
}

success() {
    echo "[✓] $*"
}

fail() {
    echo "[⨯] $*" >&2
    exit 1
}
