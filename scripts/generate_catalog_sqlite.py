#!/usr/bin/env python3

import json
import sqlite3
import sys
from pathlib import Path


def normalize(value: str | None) -> str:
    return (value or "").strip().lower()


def build_conjugation(raw: dict | None) -> tuple[str | None, str | None, str | None]:
    if not raw:
        return None, None, None

    present = raw.get("presentTense") or {}
    order = [
        ("ich", "ich"),
        ("du", "du"),
        ("er_sie_es", "er/sie/es"),
        ("wir", "wir"),
        ("ihr", "ihr"),
        ("sie_Sie", "sie/Sie"),
    ]
    parts: list[str] = []
    for source_key, label in order:
        value = (present.get(source_key) or "").strip()
        if value:
            parts.append(f"{label} {value}")

    perfect = raw.get("perfect") or {}
    return (
        ", ".join(parts) or None,
        (perfect.get("auxiliary") or "").strip() or None,
        (perfect.get("participle") or "").strip() or None,
    )


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: generate_catalog_sqlite.py <input-json> <output-sqlite>")
        return 1

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.exists():
        output_path.unlink()

    payload = json.loads(input_path.read_text())
    words = payload["words"]

    conn = sqlite3.connect(output_path)
    conn.execute("PRAGMA journal_mode = DELETE;")
    conn.execute("PRAGMA synchronous = NORMAL;")
    conn.execute(
        """
        CREATE TABLE words (
            id TEXT PRIMARY KEY,
            word TEXT NOT NULL,
            translation TEXT NOT NULL,
            translation_zh TEXT,
            source_language TEXT NOT NULL,
            pronunciation_code TEXT NOT NULL,
            difficulty_level INTEGER NOT NULL,
            cefr_level TEXT,
            article TEXT,
            gender TEXT,
            part_of_speech TEXT,
            plural TEXT,
            usage_notes TEXT,
            usage_notes_zh TEXT,
            curiosity_facts TEXT,
            curiosity_facts_zh TEXT,
            notification_message TEXT,
            notification_message_zh TEXT,
            conjugation TEXT,
            auxiliary_verb TEXT,
            past_participle TEXT,
            antonym TEXT,
            comparative TEXT,
            superlative TEXT,
            examples_json TEXT NOT NULL,
            example_translations_json TEXT NOT NULL,
            example_translations_zh_json TEXT,
            related_words_json TEXT NOT NULL,
            practice_quiz_json TEXT,
            date_added REAL NOT NULL,
            word_lower TEXT NOT NULL,
            translation_lower TEXT NOT NULL,
            usage_notes_lower TEXT NOT NULL
        )
        """
    )
    conn.execute("CREATE INDEX index_words_source_language ON words(source_language)")
    conn.execute("CREATE INDEX index_words_word_lower ON words(word_lower)")
    conn.execute("CREATE INDEX index_words_translation_lower ON words(translation_lower)")
    conn.execute("CREATE INDEX index_words_difficulty ON words(difficulty_level)")
    conn.execute("CREATE INDEX index_words_cefr ON words(cefr_level)")
    conn.execute("CREATE INDEX index_words_part_of_speech ON words(part_of_speech)")
    conn.execute("CREATE INDEX index_words_word_prefix ON words(source_language, word_lower)")

    insert_sql = """
        INSERT INTO words (
            id, word, translation, translation_zh, source_language, pronunciation_code,
            difficulty_level, cefr_level, article, gender, part_of_speech, plural,
            usage_notes, usage_notes_zh, curiosity_facts, curiosity_facts_zh,
            notification_message, notification_message_zh, conjugation, auxiliary_verb,
            past_participle, antonym, comparative, superlative, examples_json,
            example_translations_json, example_translations_zh_json, related_words_json,
            practice_quiz_json, date_added, word_lower, translation_lower, usage_notes_lower
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """

    rows = []
    for index, word in enumerate(words):
        conjugation, auxiliary_verb, past_participle = build_conjugation(word.get("verbConjugation"))
        rows.append(
            (
                f"{word.get('sourceLanguage', 'de')}-{index}",
                word.get("word", ""),
                word.get("translation", ""),
                None,
                word.get("sourceLanguage", "de"),
                word.get("pronunciationCode", "de-DE"),
                int(word.get("difficultyLevel", 1)),
                word.get("cefrLevel"),
                word.get("article"),
                word.get("gender"),
                word.get("partOfSpeech"),
                word.get("plural"),
                word.get("usageNotes"),
                None,
                word.get("curiosityFacts"),
                None,
                word.get("notificationMessage"),
                None,
                conjugation,
                auxiliary_verb,
                past_participle,
                None,
                None,
                None,
                json.dumps(word.get("examples") or [], ensure_ascii=False),
                json.dumps(word.get("exampleTranslations") or [], ensure_ascii=False),
                None,
                json.dumps(word.get("relatedWords") or [], ensure_ascii=False),
                None,
                float(index),
                normalize(word.get("word")),
                normalize(word.get("translation")),
                normalize(word.get("usageNotes")),
            )
        )

    with conn:
        conn.executemany(insert_sql, rows)

    conn.close()
    print(f"generated {output_path} with {len(rows)} rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
