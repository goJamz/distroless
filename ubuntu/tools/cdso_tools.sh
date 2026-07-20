#!/bin/sh

info() {
    echo "[•] $*"
}

success() {
    echo "[✓] $*"
}

fail() {
    echo "[⨯] $*"
    exit 1
}

