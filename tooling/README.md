# Tooling

This folder contains the development-time content pipeline and helper scripts used to regenerate the shipped German dictionary bundle.

## Layout

- `pipeline/`: Python modules for dictionary indexing, frequency loading, deduplication, and generation
- `scripts/`: operator-facing entrypoints
- `validation/`: export validation
- `requirements.txt`: Python dependencies

## Prerequisites

- Python 3
- dependencies from `tooling/requirements.txt`
- local input data under `data/`
- optional API keys depending on the task:
  - `GEMINI_API_KEY`
  - `OPENAI_API_KEY`

## Common commands

Generate the full German bundle:

```bash
./tooling/scripts/generate.sh --count 10155
```

Validate the shipping export:

```bash
python3 tooling/validation/validate_word_export.py aWordaDay/wordy_words_export_german.json
```

Rebuild the SQLite catalog only:

```bash
python3 tooling/scripts/generate_catalog_sqlite.py \
  aWordaDay/wordy_words_export_german.json \
  aWordaDay/catalog.sqlite
```

## Local data

The following are intentionally local and ignored by Git:

- `data/`
- `generated_words/`
- `words.db`
- `scratch/`
