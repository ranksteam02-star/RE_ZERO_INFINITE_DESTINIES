#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
"$GODOT_BIN" --headless --path . --editor --import --quit
"$GODOT_BIN" --headless --path . res://tests/TestRunner.tscn
"$GODOT_BIN" --headless --path . res://tests/CampaignRunner.tscn
"$GODOT_BIN" --headless --path . res://tests/PersistenceRunner.tscn -- --write
"$GODOT_BIN" --headless --path . res://tests/PersistenceRunner.tscn -- --read
