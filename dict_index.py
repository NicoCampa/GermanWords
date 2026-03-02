#!/usr/bin/env python3
"""
Dictionary Index Builder — Parse kaikki.org Wiktionary JSONL into SQLite.

Downloads (if needed) and parses the kaikki.org German Wiktionary dump,
extracting grammar data (gender, article, plural, forms, senses)
into a fast SQLite lookup database.

Usage:
    python dict_index.py [--input FILE] [--output FILE] [--download]

The resulting SQLite DB is used by hybrid_generator.py for authoritative
grammar data, replacing LLM-generated grammar.
"""

import argparse
import json
import os
import sqlite3
import sys
import time
import urllib.request
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Default paths
DEFAULT_JSONL = "data/kaikki-german.jsonl"
DEFAULT_DB = "data/dict_index.db"
KAIKKI_URL = "https://kaikki.org/dictionary/German/kaikki.org-dictionary-German.jsonl"

# Tag → gender/article mapping
GENDER_MAP = {
    "masculine": ("masculine", "der"),
    "feminine": ("feminine", "die"),
    "neuter": ("neuter", "das"),
}

# Short gender codes used in kaikki head_templates args["1"]
SHORT_GENDER_MAP = {
    "m": ("masculine", "der"),
    "f": ("feminine", "die"),
    "n": ("neuter", "das"),
}


def download_kaikki(output_path: str) -> None:
    """Download the kaikki.org German JSONL if it doesn't exist."""
    path = Path(output_path)
    if path.exists():
        size_mb = path.stat().st_size / (1024 * 1024)
        print(f"  File already exists: {path} ({size_mb:.1f} MB)")
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    print(f"  Downloading from {KAIKKI_URL} ...")
    print(f"  This is ~500MB and may take several minutes.")

    start = time.time()
    urllib.request.urlretrieve(KAIKKI_URL, str(path))
    elapsed = time.time() - start
    size_mb = path.stat().st_size / (1024 * 1024)
    print(f"  Downloaded {size_mb:.1f} MB in {elapsed:.0f}s")


def download_frequency(output_path: str = "data/de_50k.txt") -> None:
    """Download FrequencyWords German 50k list if it doesn't exist."""
    path = Path(output_path)
    if path.exists():
        print(f"  Frequency file already exists: {path}")
        return

    url = "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/de/de_50k.txt"
    path.parent.mkdir(parents=True, exist_ok=True)
    print(f"  Downloading frequency data from GitHub ...")
    urllib.request.urlretrieve(url, str(path))
    print(f"  Downloaded: {path}")


def create_database(db_path: str) -> sqlite3.Connection:
    """Create the SQLite database with the required schema."""
    path = Path(db_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    # Remove existing DB for a clean build
    if path.exists():
        path.unlink()

    conn = sqlite3.connect(str(path))
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")

    conn.executescript("""
        CREATE TABLE words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL,
            pos TEXT NOT NULL,
            gender TEXT,
            article TEXT,
            plural TEXT,
            etymology TEXT,
            senses_json TEXT,
            forms_json TEXT
        );

        CREATE TABLE forms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            form TEXT NOT NULL,
            word TEXT NOT NULL,
            pos TEXT NOT NULL,
            tags TEXT
        );
    """)

    return conn


def extract_gender_article(entry: Dict) -> Tuple[Optional[str], Optional[str]]:
    """Extract gender and article from a kaikki entry's head tags."""
    # 1. Check head_templates args["1"] for short gender code (most reliable)
    #    e.g. "m,(e)s" → masculine, "f" → feminine, "n" → neuter
    for ht in entry.get("head_templates", []):
        arg1 = ht.get("args", {}).get("1", "")
        if isinstance(arg1, str) and arg1:
            # The first character (before any comma/parenthesis) is the gender code
            code = arg1.split(",")[0].split("(")[0].strip().lower()
            if code in SHORT_GENDER_MAP:
                return SHORT_GENDER_MAP[code]

    # 2. Check head_templates expansion text for "m ", "f ", "n " markers
    for ht in entry.get("head_templates", []):
        expansion = ht.get("expansion", "")
        if isinstance(expansion, str):
            # Pattern: "Word m (...)" or "Word f (...)" or "Word n (...)"
            word = entry.get("word", "")
            for code, result in SHORT_GENDER_MAP.items():
                if f"{word} {code} " in expansion or f"{word} {code}\u00a0" in expansion:
                    return result

    # 3. Check tags on the entry itself
    for tag in entry.get("tags", []):
        if isinstance(tag, str):
            tag_lower = tag.lower().strip()
            if tag_lower in GENDER_MAP:
                return GENDER_MAP[tag_lower]

    # 4. Check forms for gender tags — only on non-diminutive, non-counterpart forms
    for form_entry in entry.get("forms", []):
        tags = form_entry.get("tags", [])
        tag_strs = [t.lower() for t in tags if isinstance(t, str)]
        # Skip diminutive forms and masculine/feminine counterpart forms
        if "diminutive" in tag_strs:
            continue
        for tag_lower in tag_strs:
            if tag_lower in GENDER_MAP:
                # Only trust this if the form text matches the word itself
                form_text = form_entry.get("form", "")
                if form_text == entry.get("word", ""):
                    return GENDER_MAP[tag_lower]

    return None, None


def extract_plural(entry: Dict) -> Optional[str]:
    """Extract the nominative plural form from forms array."""
    forms = entry.get("forms", [])
    for form_entry in forms:
        tags = [t.lower() for t in form_entry.get("tags", []) if isinstance(t, str)]
        # Look for nominative plural
        if "nominative" in tags and "plural" in tags:
            form_text = form_entry.get("form", "")
            if form_text and form_text != "-":
                return form_text

    # Fallback: just look for any form tagged "plural"
    for form_entry in forms:
        tags = [t.lower() for t in form_entry.get("tags", []) if isinstance(t, str)]
        if "plural" in tags and "diminutive" not in tags:
            form_text = form_entry.get("form", "")
            if form_text and form_text != "-":
                return form_text

    return None


def extract_senses(entry: Dict) -> List[Dict]:
    """Extract senses with glosses and tags."""
    senses = []
    for sense in entry.get("senses", []):
        glosses = sense.get("glosses", [])
        raw_glosses = sense.get("raw_glosses", [])
        tags = sense.get("tags", [])
        if glosses or raw_glosses:
            senses.append({
                "glosses": glosses,
                "raw_glosses": raw_glosses,
                "tags": tags,
            })
    return senses


def parse_jsonl(jsonl_path: str, conn: sqlite3.Connection) -> int:
    """Parse the JSONL file and insert into the database."""
    word_rows = []
    form_rows = []
    seen_word_pos = set()  # Track (word, pos) to pick best entry
    entry_count = 0
    skipped = 0

    print(f"  Parsing {jsonl_path} ...")
    start = time.time()

    with open(jsonl_path, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue

            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                skipped += 1
                continue

            word = entry.get("word", "").strip()
            pos = entry.get("pos", "").strip()
            lang = entry.get("lang", "")

            # Skip non-German entries and entries without word/pos
            if lang != "German" or not word or not pos:
                skipped += 1
                continue

            # Skip entries that are just redirects or have no senses
            senses = extract_senses(entry)
            if not senses:
                skipped += 1
                continue

            entry_count += 1

            # For duplicate (word, pos), prefer entries with more forms/senses
            key = (word.lower(), pos.lower())
            forms_list = entry.get("forms", [])

            gender, article = None, None
            plural = None

            if pos.lower() == "noun":
                gender, article = extract_gender_article(entry)
                plural = extract_plural(entry)

            etymology = entry.get("etymology_text", "")

            # Build the word row
            word_row = (
                word,
                pos.lower(),
                gender,
                article,
                plural,
                etymology[:2000] if etymology else None,  # Truncate very long etymologies
                json.dumps(senses, ensure_ascii=False),
                json.dumps(forms_list, ensure_ascii=False) if forms_list else None,
            )

            # If we've seen this (word, pos) before, only keep if this entry has more data
            if key in seen_word_pos:
                # We'll handle dedup at insert time via the batch approach
                pass
            seen_word_pos.add(key)
            word_rows.append(word_row)

            # Extract inflected forms for the forms table
            for form_entry in forms_list:
                form_text = form_entry.get("form", "").strip()
                tags = form_entry.get("tags", [])
                if form_text and form_text != "-" and form_text != word:
                    form_rows.append((
                        form_text,
                        word,
                        pos.lower(),
                        json.dumps(tags, ensure_ascii=False) if tags else None,
                    ))

            # Progress reporting
            if line_num % 100000 == 0:
                elapsed = time.time() - start
                print(f"    ... processed {line_num:,} lines ({entry_count:,} entries) in {elapsed:.0f}s")

    elapsed = time.time() - start
    print(f"  Parsed {entry_count:,} entries ({skipped:,} skipped) in {elapsed:.0f}s")

    # Batch insert
    print(f"  Inserting {len(word_rows):,} word entries ...")
    conn.executemany(
        "INSERT INTO words (word, pos, gender, article, plural, etymology, senses_json, forms_json) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        word_rows,
    )

    print(f"  Inserting {len(form_rows):,} form entries ...")
    conn.executemany(
        "INSERT INTO forms (form, word, pos, tags) VALUES (?, ?, ?, ?)",
        form_rows,
    )

    conn.commit()

    # Create indexes after bulk insert (faster than indexing during insert)
    print("  Creating indexes ...")
    conn.executescript("""
        CREATE INDEX IF NOT EXISTS idx_words_word ON words(word COLLATE NOCASE);
        CREATE INDEX IF NOT EXISTS idx_words_word_pos ON words(word COLLATE NOCASE, pos);
        CREATE INDEX IF NOT EXISTS idx_forms_form ON forms(form COLLATE NOCASE);
        CREATE INDEX IF NOT EXISTS idx_forms_word ON forms(word COLLATE NOCASE);
    """)
    conn.commit()

    return entry_count


class DictIndex:
    """Query interface for the dictionary index database."""

    def __init__(self, db_path: str = DEFAULT_DB):
        if not Path(db_path).exists():
            raise FileNotFoundError(
                f"Dictionary index not found at {db_path}. "
                f"Run: python dict_index.py --build"
            )
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row

    def lookup(self, word: str, pos: Optional[str] = None) -> List[Dict]:
        """Look up a word, optionally filtered by part of speech.

        Returns a list of matching entries as dicts.
        """
        if pos:
            rows = self.conn.execute(
                "SELECT * FROM words WHERE word = ? COLLATE NOCASE AND pos = ? COLLATE NOCASE",
                (word, pos),
            ).fetchall()
        else:
            rows = self.conn.execute(
                "SELECT * FROM words WHERE word = ? COLLATE NOCASE",
                (word,),
            ).fetchall()

        results = []
        for row in rows:
            entry = dict(row)
            # Parse JSON fields
            if entry.get("senses_json"):
                entry["senses"] = json.loads(entry["senses_json"])
            else:
                entry["senses"] = []
            if entry.get("forms_json"):
                entry["forms"] = json.loads(entry["forms_json"])
            else:
                entry["forms"] = []
            del entry["senses_json"]
            del entry["forms_json"]
            results.append(entry)

        return results

    def lookup_forms(self, word: str, pos: Optional[str] = None) -> List[Dict]:
        """Look up all inflected forms for a word."""
        if pos:
            rows = self.conn.execute(
                "SELECT * FROM forms WHERE word = ? COLLATE NOCASE AND pos = ? COLLATE NOCASE",
                (word, pos),
            ).fetchall()
        else:
            rows = self.conn.execute(
                "SELECT * FROM forms WHERE word = ? COLLATE NOCASE",
                (word,),
            ).fetchall()

        results = []
        for row in rows:
            entry = dict(row)
            if entry.get("tags"):
                entry["tags"] = json.loads(entry["tags"])
            else:
                entry["tags"] = []
            results.append(entry)

        return results

    def get_english_glosses(self, word: str, pos: Optional[str] = None) -> List[str]:
        """Get English translation glosses for a word."""
        entries = self.lookup(word, pos)
        glosses = []
        for entry in entries:
            for sense in entry.get("senses", []):
                for gloss in sense.get("glosses", []):
                    if gloss and gloss not in glosses:
                        glosses.append(gloss)
        return glosses

    def build_conjugation(self, word: str) -> Optional[Dict]:
        """Build verb conjugation table from form tags.

        Maps Wiktionary form tags to the app's conjugation schema:
        - ["present", "third-person", "singular"] → conjugation.presentTense.er_sie_es
        - ["past", "first-person", "singular"] → conjugation.pastTense.ich
        """
        entries = self.lookup(word, "verb")
        if not entries:
            return None

        entry = entries[0]
        forms = entry.get("forms", [])
        if not forms:
            return None

        # Person mapping: Wiktionary tags → app keys
        person_map = {
            ("first-person", "singular"): "ich",
            ("second-person", "singular"): "du",
            ("third-person", "singular"): "er_sie_es",
            ("first-person", "plural"): "wir",
            ("second-person", "plural"): "ihr",
            ("third-person", "plural"): "sie_Sie",
        }

        conjugation = {
            "infinitive": word,
            "presentTense": {},
            "pastTense": {},
            "perfect": {},
        }

        for form_entry in forms:
            form_text = form_entry.get("form", "")
            tags = [t.lower() for t in form_entry.get("tags", []) if isinstance(t, str)]
            if not form_text or form_text == "-":
                continue

            # Present tense
            if "present" in tags:
                for (p1, p2), key in person_map.items():
                    if p1 in tags and p2 in tags:
                        conjugation["presentTense"][key] = form_text
                        break

            # Past tense (preterite / simple past)
            if "preterite" in tags or ("past" in tags and "participle" not in tags):
                for (p1, p2), key in person_map.items():
                    if p1 in tags and p2 in tags:
                        conjugation["pastTense"][key] = form_text
                        break

            # Past participle
            if "past" in tags and "participle" in tags:
                conjugation["perfect"]["participle"] = form_text

            # Auxiliary (haben/sein) from tags
            if "auxiliary" in tags:
                conjugation["perfect"]["auxiliary"] = form_text

        # Check if we got enough data to be useful
        if not conjugation["presentTense"] and not conjugation["pastTense"]:
            return None

        # Try to extract auxiliary from the entry's head templates
        entries_full = self.lookup(word, "verb")
        if entries_full:
            for ht in entries_full[0].get("forms", []):
                ht_tags = [t.lower() for t in ht.get("tags", []) if isinstance(t, str)]
                if "auxiliary" in ht_tags:
                    aux = ht.get("form", "")
                    if aux in ("haben", "sein"):
                        conjugation["perfect"]["auxiliary"] = aux

        return conjugation

    def build_declension(self, word: str) -> Optional[Dict]:
        """Build noun declension table from form tags.

        Maps Wiktionary form tags to declension schema:
        - ["nominative", "singular"] → declension.nominative.singular
        - ["dative", "plural"] → declension.dative.plural
        """
        entries = self.lookup(word, "noun")
        if not entries:
            return None

        entry = entries[0]
        forms = entry.get("forms", [])
        if not forms:
            return None

        cases = ["nominative", "genitive", "dative", "accusative"]
        numbers = ["singular", "plural"]

        declension = {}
        for case in cases:
            declension[case] = {}

        for form_entry in forms:
            form_text = form_entry.get("form", "")
            tags = [t.lower() for t in form_entry.get("tags", []) if isinstance(t, str)]
            if not form_text or form_text == "-":
                continue

            for case in cases:
                if case in tags:
                    for number in numbers:
                        if number in tags:
                            declension[case][number] = form_text
                            break

        # Only return if we got at least nominative forms
        if not declension.get("nominative"):
            return None

        return declension

    def build_adjective_forms(self, word: str) -> Optional[Dict]:
        """Build adjective forms (comparative, superlative) from form tags."""
        entries = self.lookup(word, "adj")
        if not entries:
            return None

        entry = entries[0]
        forms = entry.get("forms", [])
        if not forms:
            return None

        adj_forms = {}
        for form_entry in forms:
            form_text = form_entry.get("form", "")
            tags = [t.lower() for t in form_entry.get("tags", []) if isinstance(t, str)]
            if not form_text or form_text == "-":
                continue

            if "comparative" in tags:
                adj_forms["comparative"] = form_text
            elif "superlative" in tags:
                adj_forms["superlative"] = form_text

        return adj_forms if adj_forms else None

    def get_all_words(self, pos: Optional[str] = None) -> List[str]:
        """Get all unique words in the index, optionally filtered by POS."""
        if pos:
            rows = self.conn.execute(
                "SELECT DISTINCT word FROM words WHERE pos = ? COLLATE NOCASE ORDER BY word",
                (pos,),
            ).fetchall()
        else:
            rows = self.conn.execute(
                "SELECT DISTINCT word FROM words ORDER BY word"
            ).fetchall()
        return [row["word"] for row in rows]

    def get_words_by_pos(self, pos_list: List[str]) -> List[str]:
        """Get all unique words matching any of the given POS types."""
        placeholders = ",".join("?" for _ in pos_list)
        rows = self.conn.execute(
            f"SELECT DISTINCT word FROM words WHERE pos IN ({placeholders}) COLLATE NOCASE ORDER BY word",
            [p.lower() for p in pos_list],
        ).fetchall()
        return [row["word"] for row in rows]

    def count(self) -> int:
        """Get total number of word entries."""
        row = self.conn.execute("SELECT COUNT(*) as cnt FROM words").fetchone()
        return row["cnt"]

    def count_distinct_words(self) -> int:
        """Get number of distinct words."""
        row = self.conn.execute("SELECT COUNT(DISTINCT word) as cnt FROM words").fetchone()
        return row["cnt"]

    def detect_verb_type(self, word: str) -> Optional[str]:
        """Detect if a verb is strong, weak, or mixed based on preterite forms.

        Strong: vowel change in stem, no -te suffix (e.g., gehen -> ging)
        Weak: no vowel change, -te suffix (e.g., machen -> machte)
        Mixed: vowel change + -te suffix (e.g., bringen -> brachte)
        """
        conjugation = self.build_conjugation(word)
        if not conjugation:
            return None

        present = conjugation.get("presentTense", {})
        past = conjugation.get("pastTense", {})

        # Need at least one present and one past form to compare
        present_er = present.get("er_sie_es") or present.get("ich")
        past_er = past.get("er_sie_es") or past.get("ich")

        if not present_er or not past_er:
            return None

        present_er = present_er.lower().strip()
        past_er = past_er.lower().strip()

        has_te_suffix = past_er.endswith("te") or past_er.endswith("ete")

        # Extract stems for vowel comparison
        # For present: remove personal ending (-t, -e, -en)
        # For past: remove -te if weak/mixed
        present_stem = present_er.rstrip("t").rstrip("e")
        if has_te_suffix:
            past_stem = past_er[:-2] if past_er.endswith("ete") else past_er[:-2]
            if past_stem.endswith("t"):
                past_stem = past_stem  # keep for comparison
        else:
            past_stem = past_er.rstrip("t").rstrip("e")

        # Extract vowels for comparison
        vowels = set("aeiouäöü")
        present_vowels = [c for c in present_stem if c in vowels]
        past_vowels = [c for c in past_stem if c in vowels]

        vowel_changed = present_vowels != past_vowels

        if vowel_changed and has_te_suffix:
            return "mixed"
        elif vowel_changed and not has_te_suffix:
            return "strong"
        elif not vowel_changed and has_te_suffix:
            return "weak"

        return None

    def derive_plural_pattern(self, word: str) -> Optional[str]:
        """Derive the plural formation pattern from nominative forms.

        Returns patterns like: "-e", "-er", "-en", "-n", "-s",
        "umlaut+-e", "umlaut+-er", "no change"
        """
        entries = self.lookup(word, "noun")
        if not entries:
            return None

        entry = entries[0]
        singular = word.lower()

        # Get plural from entry or declension
        plural_form = entry.get("plural")
        if not plural_form:
            declension = self.build_declension(word)
            if declension and declension.get("nominative", {}).get("plural"):
                plural_form = declension["nominative"]["plural"]

        if not plural_form:
            return None

        plural = plural_form.lower().strip()

        # Remove article if present
        for art in ("die ", "der ", "das "):
            if plural.startswith(art):
                plural = plural[len(art):]
                break
            if singular.startswith(art):
                singular = singular[len(art):]
                break

        if plural == singular:
            return "no change"

        # Check for umlaut (ä, ö, ü where original has a, o, u)
        umlaut_map = {"a": "ä", "o": "ö", "u": "ü", "au": "äu"}
        has_umlaut = False
        for base, umlauted in umlaut_map.items():
            if base in singular and umlauted in plural:
                has_umlaut = True
                break

        # Determine suffix pattern
        # Remove the singular from the plural to find what was added
        # This is a simplified heuristic
        umlaut_prefix = "umlaut+" if has_umlaut else ""

        if plural.endswith("er") and not singular.endswith("er"):
            return f"{umlaut_prefix}-er"
        elif plural.endswith("en") and not singular.endswith("en"):
            return f"{umlaut_prefix}-en"
        elif plural.endswith("n") and not singular.endswith("n"):
            return "-n"
        elif plural.endswith("e") and not singular.endswith("e"):
            return f"{umlaut_prefix}-e"
        elif plural.endswith("s") and not singular.endswith("s"):
            return "-s"
        elif has_umlaut:
            return "umlaut"

        return None

    def detect_separable_prefix(self, word: str) -> Optional[str]:
        """Detect if a verb has a separable prefix.

        Checks Wiktionary form tags for 'separable' and also checks against
        known German separable prefixes.
        """
        SEPARABLE_PREFIXES = [
            "ab", "an", "auf", "aus", "bei", "ein", "mit", "nach",
            "vor", "zu", "zurück", "zusammen", "weg", "her", "hin",
            "los", "fest", "dar", "um", "durch", "über", "unter",
            "wieder", "empor", "herab", "heran", "herauf", "heraus",
            "herein", "herüber", "herum", "herunter", "hervor",
            "hinab", "hinan", "hinauf", "hinaus", "hindurch",
            "hinein", "hinüber", "hinunter", "hinweg",
        ]

        entries = self.lookup(word, "verb")
        if not entries:
            return None

        entry = entries[0]

        # Check forms for "separable" tag
        for form_entry in entry.get("forms", []):
            tags = [t.lower() for t in form_entry.get("tags", []) if isinstance(t, str)]
            if "separable" in tags:
                # Found separable tag, now identify the prefix
                word_lower = word.lower()
                for prefix in sorted(SEPARABLE_PREFIXES, key=len, reverse=True):
                    if word_lower.startswith(prefix):
                        return prefix
                return None  # Tagged separable but no known prefix match

        # Check senses for "separable" tag
        for sense in entry.get("senses", []):
            tags = [t.lower() for t in sense.get("tags", []) if isinstance(t, str)]
            if "separable" in tags:
                word_lower = word.lower()
                for prefix in sorted(SEPARABLE_PREFIXES, key=len, reverse=True):
                    if word_lower.startswith(prefix):
                        return prefix
                return None

        # Heuristic: check if the word starts with a known separable prefix
        # AND the remaining part is a valid verb
        word_lower = word.lower()
        for prefix in sorted(SEPARABLE_PREFIXES, key=len, reverse=True):
            if word_lower.startswith(prefix) and len(word_lower) > len(prefix) + 2:
                remainder = word_lower[len(prefix):]
                # Check if remainder exists as a verb
                remainder_entries = self.lookup(remainder, "verb")
                if remainder_entries:
                    return prefix

        return None

    def detect_reflexive(self, word: str) -> bool:
        """Detect if a verb is reflexive based on Wiktionary tags."""
        entries = self.lookup(word, "verb")
        if not entries:
            return False

        entry = entries[0]

        # Check senses for "reflexive" tag
        for sense in entry.get("senses", []):
            tags = [t.lower() for t in sense.get("tags", []) if isinstance(t, str)]
            if "reflexive" in tags:
                return True

        # Check forms for "reflexive" tag
        for form_entry in entry.get("forms", []):
            tags = [t.lower() for t in form_entry.get("tags", []) if isinstance(t, str)]
            if "reflexive" in tags:
                return True

        return False

    def close(self):
        self.conn.close()


def main():
    parser = argparse.ArgumentParser(
        description="Build dictionary index from kaikki.org Wiktionary JSONL"
    )
    parser.add_argument(
        "--input", default=DEFAULT_JSONL,
        help=f"Path to kaikki.org JSONL file (default: {DEFAULT_JSONL})"
    )
    parser.add_argument(
        "--output", default=DEFAULT_DB,
        help=f"Path for output SQLite DB (default: {DEFAULT_DB})"
    )
    parser.add_argument(
        "--download", action="store_true",
        help="Download source data files if they don't exist"
    )
    parser.add_argument(
        "--build", action="store_true", default=True,
        help="Build the index (default: True)"
    )
    parser.add_argument(
        "--verify", action="store_true",
        help="Verify the index after building by spot-checking known words"
    )

    args = parser.parse_args()

    print("=" * 60)
    print("Dictionary Index Builder")
    print("=" * 60)

    # Download if requested
    if args.download:
        print("\n[1/3] Downloading data files ...")
        download_kaikki(args.input)
        download_frequency()
    else:
        if not Path(args.input).exists():
            print(f"\n  Error: Input file not found: {args.input}")
            print(f"  Run with --download to fetch it, or provide the path with --input")
            sys.exit(1)

    # Build the index
    print(f"\n[2/3] Building index: {args.output}")
    conn = create_database(args.output)
    entry_count = parse_jsonl(args.input, conn)
    conn.close()

    # Verify
    print(f"\n[3/3] Verification")
    idx = DictIndex(args.output)

    total = idx.count()
    distinct = idx.count_distinct_words()
    print(f"  Total entries: {total:,}")
    print(f"  Distinct words: {distinct:,}")

    if args.verify:
        # Spot-check known words
        test_words = [
            ("Tisch", "noun", "der", "masculine", "Tische"),
            ("Katze", "noun", "die", "feminine", "Katzen"),
            ("Kind", "noun", "das", "neuter", "Kinder"),
            ("gehen", "verb", None, None, None),
            ("schön", "adj", None, None, None),
        ]

        print("\n  Spot-checking known words:")
        for word, pos, expected_article, expected_gender, expected_plural in test_words:
            results = idx.lookup(word, pos)
            if results:
                r = results[0]
                status = "OK"
                details = []
                if expected_article and r.get("article") != expected_article:
                    status = "MISMATCH"
                    details.append(f"article: got {r.get('article')}, expected {expected_article}")
                if expected_gender and r.get("gender") != expected_gender:
                    status = "MISMATCH"
                    details.append(f"gender: got {r.get('gender')}, expected {expected_gender}")
                if expected_plural and r.get("plural") != expected_plural:
                    status = "MISMATCH"
                    details.append(f"plural: got {r.get('plural')}, expected {expected_plural}")

                detail_str = f" ({', '.join(details)})" if details else ""
                print(f"    {word} ({pos}): {status}{detail_str}")
                print(f"      article={r.get('article')}, gender={r.get('gender')}, plural={r.get('plural')}")
            else:
                print(f"    {word} ({pos}): NOT FOUND")

    idx.close()

    print(f"\n  Index built successfully: {args.output}")
    if total < 100000:
        print(f"  ⚠️  Warning: Only {total:,} entries — expected 100K+. Check input file.")
    else:
        print(f"  ✓ {total:,} entries looks good!")

    print("=" * 60)


if __name__ == "__main__":
    main()
