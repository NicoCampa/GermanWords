# Content Pipeline

This repo keeps the shipping German dictionary bundle inside the app and the generation workflow under `tooling/`.

## Source of truth

- Bundled JSON export: `aWordaDay/wordy_words_export_german.json`
- Bundled SQLite catalog: `aWordaDay/catalog.sqlite`
- Generator entrypoint: `tooling/scripts/generate.sh`
- Validator: `tooling/validation/validate_word_export.py`
- Generator internals: `tooling/pipeline/`

## Local-only working data

These folders are intentionally ignored and should not be committed:

- `data/`
- `generated_words/`
- `words.db`
- `scratch/`

`data/` contains the downloaded dictionary index inputs. `generated_words/` contains intermediate and exported pipeline outputs.

## Regenerate the German bundle

From the repo root:

```bash
./tooling/scripts/generate.sh --count 10155
```

That workflow:

1. Runs `tooling/pipeline/hybrid_generator.py`
2. Validates the generated JSON export
3. Copies the final export into `aWordaDay/wordy_words_export_german.json`
4. Rebuilds `aWordaDay/catalog.sqlite`

After that, build and launch the app so the fresh bundle is used by the simulator or device install.

## Validate an existing export

```bash
python3 tooling/validation/validate_word_export.py aWordaDay/wordy_words_export_german.json
```

## Rebuild only the SQLite catalog

```bash
python3 tooling/scripts/generate_catalog_sqlite.py \
  aWordaDay/wordy_words_export_german.json \
  aWordaDay/catalog.sqlite
```

## Build the dictionary index locally

```bash
python3 tooling/pipeline/dict_index.py --download --build --verify
```

This populates the local `data/` directory with:

- `data/kaikki-german.jsonl`
- `data/de_50k.txt`
- `data/dict_index.db`

## Chinese translation enrichment

Optional post-processing for Simplified Chinese fields:

```bash
python3 tooling/scripts/add_chinese_translations.py --resume
```

This updates `aWordaDay/wordy_words_export_german.json` in place and requires `OPENAI_API_KEY`.

## Notes

- The app currently ships a German-only curriculum.
- App Store metadata is managed outside this repo.
- Heavy local archives belong outside Git; commit only the final app bundle assets and the supporting tooling/docs.
