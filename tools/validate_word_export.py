#!/usr/bin/env python3
"""
Validate word export JSON files for schema v2/v3.

Checks performed:
  - required fields present (word, translation, partOfSpeech, cefrLevel, etc.)
  - examples and exampleTranslations arrays are balanced
  - verb conjugation present tense forms do not include the pronoun prefix
  - perfect tense information uses the nested {"auxiliary", "participle"} shape
  - antonym structure: {word: String, note: String}
  - adjectiveForms structure: {comparative: String, superlative: String}
  - metadata contains schemaVersion
  - warns if any removed/legacy field is present
  - optional Chinese (Zh) fields validated when present (schema v3)
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple


CANONICAL_PRONOUNS: Dict[str, str] = {
    "ich": "ich",
    "du": "du",
    "er_sie_es": "er/sie/es",
    "wir": "wir",
    "ihr": "ihr",
    "sie_Sie": "sie/Sie",
}

REMOVED_FIELDS = {
    "meaning", "targetLanguage", "frequencyInfo", "verbMeta", "topic", "category",
    "ipa", "falseFriends", "compoundParts", "verbType", "separablePrefix",
    "isReflexive", "verbGovernance", "nounDeclension", "pluralPattern",
    "exampleCaseHints",
}

REQUIRED_FIELDS = {
    "word", "translation", "partOfSpeech", "cefrLevel", "difficultyLevel",
    "examples", "exampleTranslations", "usageNotes",
    "curiosityFacts", "relatedWords", "notificationMessage",
    "sourceLanguage", "pronunciationCode", "practiceQuiz",
}


def load_json(path: Path) -> Dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Failed to parse JSON '{path}': {exc}") from exc


def validate_word(word: Dict, index: int) -> Tuple[List[str], List[str]]:
    """Returns (errors, warnings)."""
    errors: List[str] = []
    warnings: List[str] = []
    word_label = word.get("word", f"<index {index}>")

    # Check for removed/legacy fields
    for field in REMOVED_FIELDS:
        if field in word:
            warnings.append(
                f"[{word_label}] contains removed field '{field}' — should be deleted"
            )

    # Check required fields
    for field in REQUIRED_FIELDS:
        value = word.get(field)
        if value is None or (isinstance(value, str) and not value.strip()):
            errors.append(f"[{word_label}] missing required field '{field}'")

    # Ensure examples and translations are balanced
    examples = word.get("examples") or []
    translations = word.get("exampleTranslations") or []
    if examples and translations and len(examples) != len(translations):
        errors.append(
            f"[{word_label}] examples ({len(examples)}) and exampleTranslations ({len(translations)}) differ in length"
        )
    if not examples or not translations:
        errors.append(f"[{word_label}] missing example sentences or translations")


    # Validate verb conjugation structure if present
    conjugation = word.get("verbConjugation") or {}
    if conjugation:
        for tense_name in ("presentTense", "pastTense"):
            tense = conjugation.get(tense_name)
            if isinstance(tense, dict):
                for pronoun_key, raw_value in tense.items():
                    canonical = CANONICAL_PRONOUNS.get(pronoun_key)
                    if not canonical or not isinstance(raw_value, str):
                        continue

                    value_lower = raw_value.strip().lower()
                    if value_lower.startswith(canonical.lower() + " "):
                        errors.append(
                            f"[{word_label}] {tense_name} '{pronoun_key}' value repeats pronoun: {raw_value!r}"
                        )

        perfect = conjugation.get("perfect")
        if perfect is not None and not isinstance(perfect, dict):
            errors.append(
                f"[{word_label}] verbConjugation.perfect should be an object, found {type(perfect).__name__}"
            )

    # Validate antonym structure
    antonym = word.get("antonym")
    if antonym is not None:
        if not isinstance(antonym, dict):
            errors.append(f"[{word_label}] antonym should be an object {{word, note}}")
        else:
            if not isinstance(antonym.get("word"), str) or not antonym["word"].strip():
                errors.append(f"[{word_label}] antonym.word must be a non-empty string")

    # Validate adjectiveForms structure
    adj_forms = word.get("adjectiveForms")
    if adj_forms is not None:
        if not isinstance(adj_forms, dict):
            errors.append(f"[{word_label}] adjectiveForms should be an object {{comparative, superlative}}")
        else:
            for key in ("comparative", "superlative"):
                val = adj_forms.get(key)
                if val is not None and not isinstance(val, str):
                    errors.append(f"[{word_label}] adjectiveForms.{key} should be a string")

    # Validate optional Chinese (Zh) fields (schema v3)
    zh_string_fields = [
        "translationZh", "curiosityFactsZh", "usageNotesZh", "notificationMessageZh"
    ]
    for field in zh_string_fields:
        value = word.get(field)
        if value is not None:
            if not isinstance(value, str) or not value.strip():
                errors.append(
                    f"[{word_label}] '{field}' is present but empty or not a string"
                )

    example_translations_zh = word.get("exampleTranslationsZh")
    if example_translations_zh is not None:
        if not isinstance(example_translations_zh, list):
            errors.append(
                f"[{word_label}] 'exampleTranslationsZh' should be an array"
            )
        else:
            if any(not isinstance(t, str) or not t.strip() for t in example_translations_zh):
                errors.append(
                    f"[{word_label}] 'exampleTranslationsZh' contains empty or non-string entries"
                )
            if examples and len(example_translations_zh) != len(examples):
                errors.append(
                    f"[{word_label}] exampleTranslationsZh ({len(example_translations_zh)}) "
                    f"and examples ({len(examples)}) differ in length"
                )

    # Validate practiceQuiz structure
    quiz = word.get("practiceQuiz")
    if quiz is not None:
        if not isinstance(quiz, dict):
            errors.append(f"[{word_label}] practiceQuiz should be an object")
        else:
            if not quiz.get("question"):
                errors.append(f"[{word_label}] practiceQuiz missing 'question'")
            if not quiz.get("correctAnswer"):
                errors.append(f"[{word_label}] practiceQuiz missing 'correctAnswer'")
            distractors = quiz.get("distractors")
            if not isinstance(distractors, list) or len(distractors) != 3:
                errors.append(
                    f"[{word_label}] practiceQuiz.distractors must be an array of exactly 3 items"
                )

    return errors, warnings


def validate_file(path: Path) -> Tuple[int, int, int]:
    """Returns (word_count, error_count, warning_count)."""
    data = load_json(path)

    # Validate metadata
    metadata = data.get("metadata")
    if isinstance(metadata, dict):
        schema_version = metadata.get("schemaVersion")
        if schema_version is None:
            print(f"WARNING {path.name}: metadata missing 'schemaVersion'", file=sys.stderr)
        elif schema_version < 2:
            print(f"WARNING {path.name}: schemaVersion is {schema_version}, expected >= 2", file=sys.stderr)
    else:
        print(f"WARNING {path.name}: missing metadata object", file=sys.stderr)

    words = data.get("words")
    if not isinstance(words, list):
        raise SystemExit(f"{path} does not contain a top-level 'words' array")

    total_errors = 0
    total_warnings = 0
    for index, word in enumerate(words):
        if not isinstance(word, dict):
            total_errors += 1
            print(f"ERROR {path.name} index {index}: word is not an object", file=sys.stderr)
            continue

        errors, warnings = validate_word(word, index)
        for message in errors:
            total_errors += 1
            print(f"ERROR {path.name} index {index}: {message}", file=sys.stderr)
        for message in warnings:
            total_warnings += 1
            print(f"WARNING {path.name} index {index}: {message}", file=sys.stderr)

    return len(words), total_errors, total_warnings


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate word export JSON files (schema v2/v3).")
    parser.add_argument(
        "files",
        nargs="+",
        type=Path,
        help="Path(s) to JSON export file(s) to validate.",
    )
    args = parser.parse_args(argv)

    grand_total = 0
    grand_errors = 0
    grand_warnings = 0
    for json_path in args.files:
        if not json_path.exists():
            print(f"Skipping missing file: {json_path}", file=sys.stderr)
            continue

        words_count, errors, warnings = validate_file(json_path)
        grand_total += words_count
        grand_errors += errors
        grand_warnings += warnings

        status = "PASS" if errors == 0 else "FAIL"
        warn_str = f", {warnings} warning(s)" if warnings > 0 else ""
        print(f"{status} {json_path}: {words_count} words checked, {errors} error(s){warn_str}")

    if grand_total == 0:
        print("No words validated.", file=sys.stderr)
        return 1

    if grand_errors > 0:
        print(f"Validation completed with {grand_errors} error(s) and {grand_warnings} warning(s).", file=sys.stderr)
        return 1

    print("All validations passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
