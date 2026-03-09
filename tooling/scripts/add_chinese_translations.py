#!/usr/bin/env python3
"""
Add Simplified Chinese translations to the German word export JSON.

Reads wordy_words_export_german.json, calls OpenAI to translate English fields
into Simplified Chinese, and writes the enriched JSON back with new *Zh fields.

Usage:
    python tooling/scripts/add_chinese_translations.py
    python tooling/scripts/add_chinese_translations.py --dry-run   # preview without writing
    python tooling/scripts/add_chinese_translations.py --resume    # skip words that already have Zh fields

Prerequisites:
    - Set OPENAI_API_KEY environment variable
    - pip install openai>=1.40.0
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional

from openai import OpenAI

# Path to the word export file
REPO_ROOT = Path(__file__).resolve().parents[2]
WORD_FILE = REPO_ROOT / "aWordaDay" / "wordy_words_export_german.json"
BACKUP_FILE = WORD_FILE.with_suffix(".backup.json")

# Rate limiting
DELAY_BETWEEN_CALLS = 0.5  # seconds between API calls
BATCH_SIZE = 5  # words per batch to reduce API calls


def load_words(path: Path) -> Dict:
    """Load the word export JSON file."""
    if not path.exists():
        raise SystemExit(f"Word file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def save_words(path: Path, data: Dict) -> None:
    """Write the enriched JSON back to disk."""
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def build_translation_prompt(words_batch: List[Dict]) -> str:
    """Build a prompt to translate a batch of words to Simplified Chinese."""
    entries = []
    for i, word in enumerate(words_batch):
        entry = {
            "index": i,
            "word": word["word"],
            "translation": word["translation"],
            "exampleTranslations": word.get("exampleTranslations", []),
            "curiosityFacts": word.get("curiosityFacts", ""),
            "usageNotes": word.get("usageNotes", ""),
            "notificationMessage": word.get("notificationMessage", ""),
        }
        entries.append(entry)

    return json.dumps(entries, ensure_ascii=False, indent=2)


def translate_batch(client: OpenAI, words_batch: List[Dict], model: str = "gpt-4o-mini") -> List[Dict]:
    """Call OpenAI to translate a batch of word fields to Simplified Chinese."""
    user_content = build_translation_prompt(words_batch)

    system_prompt = """You are a professional translator specializing in German language education.
Translate the following English fields into Simplified Chinese for Chinese speakers learning German.

For each word entry, produce:
- translationZh: Chinese translation of the English "translation" field
- exampleTranslationsZh: array of Chinese translations matching each English example translation
- curiosityFactsZh: Chinese translation of curiosityFacts (empty string if source is empty)
- usageNotesZh: Chinese translation of usageNotes (empty string if source is empty)
- notificationMessageZh: Chinese translation of notificationMessage (empty string if source is empty; keep under 45 characters)

Important:
- Keep German words/examples unchanged — only translate English explanations into Chinese
- Use natural, clear Simplified Chinese suitable for language learners
- Maintain the same tone and style as the English originals
- The exampleTranslationsZh array MUST have the same length as exampleTranslations
- Return ONLY a JSON array with objects containing: index, translationZh, exampleTranslationsZh, curiosityFactsZh, usageNotesZh, notificationMessageZh
- No markdown fences, no extra text — just valid JSON."""

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content},
        ],
        temperature=0.3,
        max_tokens=4000,
    )

    raw = response.choices[0].message.content.strip()

    # Strip markdown fences if present
    if raw.startswith("```"):
        lines = raw.split("\n")
        # Remove first and last lines if they are fences
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        raw = "\n".join(lines)

    try:
        results = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"  WARNING: Failed to parse API response: {e}", file=sys.stderr)
        print(f"  Raw response: {raw[:500]}", file=sys.stderr)
        return []

    if not isinstance(results, list):
        print(f"  WARNING: Expected array, got {type(results).__name__}", file=sys.stderr)
        return []

    return results


def has_chinese_fields(word: Dict) -> bool:
    """Check if a word already has Chinese translation fields."""
    return bool(word.get("translationZh"))


def apply_translations(word: Dict, translation: Dict) -> None:
    """Apply Chinese translation fields to a word entry."""
    if "translationZh" in translation:
        word["translationZh"] = translation["translationZh"]

    if "exampleTranslationsZh" in translation:
        zh_translations = translation["exampleTranslationsZh"]
        # Ensure array length matches
        en_translations = word.get("exampleTranslations", [])
        if len(zh_translations) == len(en_translations):
            word["exampleTranslationsZh"] = zh_translations
        elif zh_translations:
            # Pad or truncate to match
            while len(zh_translations) < len(en_translations):
                zh_translations.append(zh_translations[-1] if zh_translations else "")
            word["exampleTranslationsZh"] = zh_translations[:len(en_translations)]

    if "curiosityFactsZh" in translation:
        word["curiosityFactsZh"] = translation["curiosityFactsZh"] or None

    if "usageNotesZh" in translation:
        word["usageNotesZh"] = translation["usageNotesZh"] or None

    if "notificationMessageZh" in translation:
        word["notificationMessageZh"] = translation["notificationMessageZh"] or None


def main():
    parser = argparse.ArgumentParser(description="Add Chinese translations to word export.")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing changes")
    parser.add_argument("--resume", action="store_true", help="Skip words that already have Zh fields")
    parser.add_argument("--model", default="gpt-4o-mini", help="OpenAI model to use (default: gpt-4o-mini)")
    parser.add_argument("--batch-size", type=int, default=BATCH_SIZE, help=f"Words per API call (default: {BATCH_SIZE})")
    args = parser.parse_args()

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise SystemExit("OPENAI_API_KEY environment variable not set")

    client = OpenAI(api_key=api_key)

    print(f"Loading words from {WORD_FILE}...")
    data = load_words(WORD_FILE)
    words = data.get("words", [])
    print(f"Found {len(words)} words")

    # Filter words that need translation
    if args.resume:
        to_translate = [(i, w) for i, w in enumerate(words) if not has_chinese_fields(w)]
        print(f"Resuming: {len(to_translate)} words need translation ({len(words) - len(to_translate)} already done)")
    else:
        to_translate = list(enumerate(words))

    if not to_translate:
        print("All words already have Chinese translations!")
        return

    # Create backup before modifying
    if not args.dry_run:
        print(f"Creating backup at {BACKUP_FILE}...")
        save_words(BACKUP_FILE, data)

    # Process in batches
    total_translated = 0
    total_failed = 0
    batch_size = args.batch_size

    for batch_start in range(0, len(to_translate), batch_size):
        batch = to_translate[batch_start:batch_start + batch_size]
        batch_indices = [idx for idx, _ in batch]
        batch_words = [w for _, w in batch]

        batch_num = batch_start // batch_size + 1
        total_batches = (len(to_translate) + batch_size - 1) // batch_size
        print(f"\nBatch {batch_num}/{total_batches}: translating {len(batch_words)} words...")

        for w in batch_words:
            print(f"  - {w['word']} ({w['translation']})")

        if args.dry_run:
            total_translated += len(batch_words)
            continue

        try:
            results = translate_batch(client, batch_words, model=args.model)

            if not results:
                print(f"  WARNING: No results returned for batch {batch_num}")
                total_failed += len(batch_words)
                continue

            # Map results back by index
            result_map = {}
            for r in results:
                idx = r.get("index")
                if idx is not None:
                    result_map[idx] = r

            for batch_idx, (word_idx, word) in enumerate(batch):
                if batch_idx in result_map:
                    apply_translations(word, result_map[batch_idx])
                    total_translated += 1
                    print(f"  OK: {word['word']} -> {result_map[batch_idx].get('translationZh', '?')}")
                else:
                    total_failed += 1
                    print(f"  MISSING: {word['word']} (no result from API)")

        except Exception as e:
            print(f"  ERROR: Batch {batch_num} failed: {e}", file=sys.stderr)
            total_failed += len(batch_words)

        # Rate limiting
        if batch_start + batch_size < len(to_translate):
            time.sleep(DELAY_BETWEEN_CALLS)

    # Bump schema version
    if not args.dry_run:
        if "metadata" in data:
            data["metadata"]["schemaVersion"] = 3
            print("\nBumped schemaVersion to 3")

        # Write enriched JSON
        print(f"Writing enriched JSON to {WORD_FILE}...")
        save_words(WORD_FILE, data)

    print(f"\nDone! Translated: {total_translated}, Failed: {total_failed}")
    if total_failed > 0:
        print(f"Run with --resume to retry failed words.")


if __name__ == "__main__":
    main()
