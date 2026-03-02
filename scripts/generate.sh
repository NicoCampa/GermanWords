#!/usr/bin/env bash
set -e
python3 hybrid_generator.py "$@"
python3 tools/validate_word_export.py generated_words/german/exports/*.json
cp generated_words/german/exports/wordy_words_export_german.json aWordaDay/wordy_words_export_german.json
echo "Done. Build the app to pick up new words."
