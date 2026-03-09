# Wolke

`Wolke` is an iOS app for learning German vocabulary from a bundled offline dictionary.

## Repository layout

- `aWordaDay/`: app source, assets, bundled JSON, bundled SQLite catalog
- `aWordaDayTests/`: unit tests
- `aWordaDayUITests/`: UI tests
- `docs/`: product and pipeline documentation
- `tooling/`: generation, validation, and support scripts

## Build the app

```bash
xcodebuild -project aWordaDay.xcodeproj \
  -scheme aWordaDay \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Bundled dictionary assets

- JSON export: `aWordaDay/wordy_words_export_german.json`
- SQLite catalog: `aWordaDay/catalog.sqlite`

## Tooling

The content pipeline lives under `tooling/`.

- main generator: `tooling/scripts/generate.sh`
- validator: `tooling/validation/validate_word_export.py`
- pipeline internals: `tooling/pipeline/`

See `docs/pipeline.md` and `tooling/README.md` for details.

## Local-only ignored data

These working artifacts are intentionally not part of Git:

- `data/`
- `generated_words/`
- `words.db`
- `scratch/`

## Notes

- The shipped app name is `Wolke`.
- App Store metadata, including the App Store title, is managed outside this repo.
