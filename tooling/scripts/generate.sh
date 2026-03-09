#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

python3 "$ROOT_DIR/tooling/pipeline/hybrid_generator.py" "$@"
python3 "$ROOT_DIR/tooling/validation/validate_word_export.py" "$ROOT_DIR"/generated_words/german/exports/*.json
cp "$ROOT_DIR/generated_words/german/exports/wordy_words_export_german.json" "$ROOT_DIR/aWordaDay/wordy_words_export_german.json"
python3 "$ROOT_DIR/tooling/scripts/generate_catalog_sqlite.py" \
  "$ROOT_DIR/aWordaDay/wordy_words_export_german.json" \
  "$ROOT_DIR/aWordaDay/catalog.sqlite"

echo "Done. Build the app to pick up the refreshed JSON and SQLite catalog."
