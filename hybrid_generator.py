#!/usr/bin/env python3
"""
Hybrid Word Generator — Dictionary-sourced grammar + Gemini batch enrichment.

Pipeline:
  1. Select lemmas from Wiktionary dictionary index (filtered by frequency)
  2. Enrich grammar locally (article, gender, plural, translation)
  3. Batch-enrich via Gemini Flash Lite (CEFR level, examples, usage notes, etc.)
  4. Export to iOS JSON format

Usage:
    python hybrid_generator.py --count 10        # test with 10 words
    python hybrid_generator.py --count 10155     # all words
    python hybrid_generator.py --count 50 --pos noun,verb

Prerequisites:
    1. Build dictionary index: python dict_index.py --download --build --verify
    2. Set GEMINI_API_KEY env var or pass --api-key
"""

import argparse
import json
import os
import random
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Literal, Optional

from google import genai
from pydantic import BaseModel, Field

from dict_index import DictIndex
from deduplication import HybridDuplicateChecker
from frequency_loader import FrequencyLoader
from yaml_utils import WordFormatConverter

# ── Defaults ──────────────────────────────────────────────────────────────────

DEFAULT_DICT_DB = "data/dict_index.db"
DEFAULT_FREQ_FILE = "data/de_50k.txt"
DEFAULT_DEDUP_DB = "words.db"
DEFAULT_OUTPUT_DIR = "generated_words"
DEFAULT_MAX_RANK = 20000  # Top 20k most frequent → ~10k lemmas
DEFAULT_MODEL = "gemini-2.5-flash-lite"

# Pattern matching inflected/form-of glosses (not standalone vocabulary).
INFLECTED_FORM_PATTERN = re.compile(
    r"("
    r"inflection of\b"
    r"|\bsingular of\b"
    r"|\bplural of\b"
    r"|\bgenitive of\b"
    r"|\bdative of\b"
    r"|\baccusative of\b"
    r"|\bnominative of\b"
    r"|\bgerund of\b"
    r"|\bparticiple of\b"
    r"|\bpreterite of\b"
    r"|\bimperative of\b"
    r"|\bsubjunctive .* of\b"
    r"|\bperson singular\b"
    r"|\bperson plural\b"
    r"|\bdegree of\b"
    r"|\bform of\b"
    r"|\bspelling of\b"
    r"|\bmisspelling of\b"
    r"|\bfemale equivalent of\b"
    r"|\bmale equivalent of\b"
    r"|\bdiminutive of\b"
    r"|\binfinitive of\b"
    r")",
    re.IGNORECASE,
)

# POS types to include (mapped from Wiktionary POS to app POS)
WIKTIONARY_POS_MAP = {
    "noun": "noun",
    "verb": "verb",
    "adj": "adjective",
    "adv": "adverb",
}

GERMAN_LANG_INFO = {
    "name": "German",
    "native_name": "Deutsch",
    "code": "de",
    "pronunciation_code": "de-DE",
    "requires_article": True,
    "article_set": ["der", "die", "das"],
}


# ── Structured Output Schema ─────────────────────────────────────────────────

class RelatedWord(BaseModel):
    word: str = Field(description="A synonym or related German word")
    note: str = Field(description="How it differs from the main word")


class WordEnrichment(BaseModel):
    cefrLevel: Literal["A1", "A2", "B1", "B2", "C1", "C2"] = Field(
        description="CEFR proficiency level"
    )
    examples: List[str] = Field(
        description="3 German example sentences at the assigned CEFR level"
    )
    exampleTranslations: List[str] = Field(
        description="English translations of the 3 example sentences"
    )
    usageNotes: str = Field(
        description="When/how to use this word, common collocations, register notes (2-3 sentences)"
    )
    relatedWords: List[RelatedWord] = Field(
        description="2 synonyms or related words with differentiation notes"
    )
    curiosityFacts: str = Field(
        description="1-2 interesting cultural, etymological, or linguistic facts"
    )
    notificationMessage: str = Field(
        description="Push notification teaser, max 45 chars, with at least one emoji"
    )


# ── Generator ─────────────────────────────────────────────────────────────────

class HybridGenerator:
    """Hybrid word generation: dictionary grammar + Gemini batch enrichment."""

    def __init__(
        self,
        api_key: str,
        dict_db: str = DEFAULT_DICT_DB,
        freq_file: str = DEFAULT_FREQ_FILE,
        dedup_db: str = DEFAULT_DEDUP_DB,
        max_rank: int = DEFAULT_MAX_RANK,
        model: str = DEFAULT_MODEL,
    ):
        print("  Loading dictionary index ...")
        self.dict_index = DictIndex(dict_db)
        print(f"    {self.dict_index.count():,} entries loaded")

        print("  Loading frequency data ...")
        self.freq = FrequencyLoader(freq_file)
        print(f"    {len(self.freq):,} words loaded")

        self.max_rank = max_rank

        print("  Loading deduplication checker ...")
        self.dedup = HybridDuplicateChecker(dedup_db)

        self.model = model
        self.client = genai.Client(api_key=api_key)
        self.lang_info = GERMAN_LANG_INFO

    # ── Step 1: Word Selection ─────────────────────────────────────────────

    def _is_lemma(self, word: str, pos: str) -> bool:
        """Check if a word is a lemma (base form) rather than an inflected form."""
        entries = self.dict_index.lookup(word, pos)
        if not entries:
            return False
        senses = entries[0].get("senses", [])
        if not senses:
            return False
        for sense in senses:
            joined = " ".join(sense.get("glosses", []))
            if joined and not INFLECTED_FORM_PATTERN.search(joined):
                return True
        return False

    def select_words(
        self,
        count: int,
        pos_types: Optional[List[str]] = None,
    ) -> List[Dict]:
        """Select lemmas from the dictionary index, filtered to top-frequency words."""
        if pos_types is None:
            pos_types = list(WIKTIONARY_POS_MAP.keys())

        print(f"\n  [Selection] count={count}, max_rank={self.max_rank}, pos={pos_types}")

        print("    Gathering candidates (lemmas in top frequency) ...")
        candidates = []
        inflected_count = 0
        out_of_freq = 0
        for wikt_pos in pos_types:
            app_pos = WIKTIONARY_POS_MAP.get(wikt_pos, wikt_pos)
            words = self.dict_index.get_all_words(pos=wikt_pos)
            for word in words:
                rank = self.freq.get_rank(word)
                if not rank or rank > self.max_rank:
                    out_of_freq += 1
                    continue
                if self._is_lemma(word, wikt_pos):
                    candidates.append({"word": word, "wikt_pos": wikt_pos, "app_pos": app_pos, "freq_rank": rank})
                else:
                    inflected_count += 1

        print(f"    Found {len(candidates):,} lemmas ({inflected_count:,} inflected, {out_of_freq:,} below frequency cutoff)")

        if not candidates:
            print("    ⚠️  No candidates found")
            return []

        # Deduplicate
        print("    Deduplicating ...")
        unique_candidates = []
        for c in candidates:
            is_dup, reason = self.dedup.is_duplicate(c["word"], "de")
            if not is_dup:
                unique_candidates.append(c)

        print(f"    {len(unique_candidates):,} unique candidates after dedup")

        if not unique_candidates:
            print("    ⚠️  All candidates are duplicates")
            return []

        random.shuffle(unique_candidates)
        selected = unique_candidates[:count]
        print(f"    Selected {len(selected)} words")

        return selected

    # ── Step 2: Grammar Enrichment (LOCAL) ─────────────────────────────────

    def enrich_grammar(self, word_info: Dict) -> Dict:
        """Enrich a word with grammar data from the dictionary index."""
        word = word_info["word"]
        wikt_pos = word_info["wikt_pos"]
        app_pos = word_info["app_pos"]

        entries = self.dict_index.lookup(word, wikt_pos)
        if not entries:
            entries = self.dict_index.lookup(word)

        if not entries:
            return {"word": word, "partOfSpeech": app_pos}

        entry = entries[0]
        enriched = {"word": word, "partOfSpeech": app_pos}

        # Extract English glosses as translation — short, clean
        glosses = []
        for sense in entry.get("senses", []):
            for gloss in sense.get("glosses", []):
                if gloss and gloss not in glosses:
                    # Strip parenthetical explanations: "woman (adult female human)" → "woman"
                    clean = re.sub(r"\s*\(.*?\)", "", gloss).strip().rstrip(",;")
                    if clean:
                        glosses.append(clean)
        if glosses:
            enriched["translation"] = glosses[0]

        # Noun-specific grammar
        if app_pos == "noun":
            if entry.get("article"):
                enriched["article"] = entry["article"]
                enriched["word"] = f"{entry['article']} {word}"
            if entry.get("gender"):
                enriched["gender"] = entry["gender"]
            if entry.get("plural"):
                enriched["plural"] = entry["plural"]

        # Verb-specific grammar: auxiliary, pastParticiple, conjugation
        if app_pos == "verb":
            forms = entry.get("forms", [])
            for f in forms:
                tags = set(f.get("tags", []))
                form = f.get("form", "")
                if not form:
                    continue
                # Auxiliary verb (haben/sein)
                if tags == {"auxiliary"} and form in ("haben", "sein"):
                    enriched["auxiliaryVerb"] = form
                # Past participle
                if {"participle", "past"} <= tags and "auxiliary" not in tags:
                    if "pastParticiple" not in enriched:
                        enriched["pastParticiple"] = form
            # Present tense conjugation: "ich ..., du ..., er/sie/es ..., wir ..., ihr ..., sie/Sie ..."
            conj_map = {}
            for f in forms:
                tags = set(f.get("tags", []))
                form = f.get("form", "")
                if not form or "indicative" not in tags or "present" not in tags:
                    continue
                if {"first-person", "singular"} <= tags:
                    conj_map["ich"] = form
                elif {"second-person", "singular"} <= tags:
                    conj_map["du"] = form
                elif {"third-person", "singular"} <= tags:
                    conj_map["er/sie/es"] = form
                elif {"first-person", "plural"} <= tags:
                    conj_map["wir"] = form
                elif {"second-person", "plural"} <= tags:
                    conj_map["ihr"] = form
                elif {"third-person", "plural"} <= tags:
                    conj_map["sie/Sie"] = form
            if conj_map:
                parts = []
                for pronoun in ["ich", "du", "er/sie/es", "wir", "ihr", "sie/Sie"]:
                    if pronoun in conj_map:
                        parts.append(f"{pronoun} {conj_map[pronoun]}")
                if parts:
                    enriched["conjugation"] = ", ".join(parts)

        return enriched

    # ── Step 3: Gemini Batch Enrichment ────────────────────────────────────

    def _build_prompt(self, enriched_word: Dict) -> str:
        """Build the enrichment prompt for a single word."""
        word = enriched_word.get("word", "")
        translation = enriched_word.get("translation", "")
        pos = enriched_word.get("partOfSpeech", "")
        article = enriched_word.get("article", "")
        gender = enriched_word.get("gender", "")
        plural = enriched_word.get("plural", "")

        grammar_ctx = f"Word: {word}\nTranslation: {translation}\nPart of speech: {pos}"
        if article:
            grammar_ctx += f"\nArticle: {article}"
        if gender:
            grammar_ctx += f"\nGender: {gender}"
        if plural:
            grammar_ctx += f"\nPlural: {plural}"

        return f"""You are a German language curriculum designer. Given this word with verified grammar data, generate learning content.

{grammar_ctx}

Rules:
- cefrLevel: Assign based on how common/essential the word is:
  A1=core survival, A2=everyday life, B1=independent communication,
  B2=complex topics, C1=academic/professional, C2=near-native
- examples: 3 German sentences whose complexity matches the CEFR level:
  A1=simple present max 6 words, A2=compound max 10 words,
  B1=subordinate clauses 8-14 words, B2=conditional/passive 10-18 words,
  C1=academic/literary 12-22 words, C2=complex prose 14-25 words
- Use the EXACT article/gender/plural provided
- usageNotes: practical, learner-friendly, 2-3 sentences
- relatedWords: 2 entries with meaningful differentiation
- curiosityFacts: genuinely interesting, not generic
- notificationMessage: max 45 chars with at least one emoji"""

    @staticmethod
    def _build_gemini_schema() -> dict:
        """Build a Gemini-compatible JSON schema (no $defs/$ref)."""
        return {
            "type": "object",
            "properties": {
                "cefrLevel": {
                    "type": "string",
                    "enum": ["A1", "A2", "B1", "B2", "C1", "C2"],
                    "description": "CEFR proficiency level",
                },
                "examples": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "3 German example sentences at the assigned CEFR level",
                },
                "exampleTranslations": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "English translations of the 3 example sentences",
                },
                "usageNotes": {
                    "type": "string",
                    "description": "When/how to use this word, collocations, register (2-3 sentences)",
                },
                "relatedWords": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "word": {"type": "string", "description": "A synonym or related German word"},
                            "note": {"type": "string", "description": "How it differs from the main word"},
                        },
                        "required": ["word", "note"],
                    },
                    "description": "2 related words with differentiation notes",
                },
                "curiosityFacts": {
                    "type": "string",
                    "description": "1-2 interesting cultural, etymological, or linguistic facts",
                },
                "notificationMessage": {
                    "type": "string",
                    "description": "Push notification teaser, max 45 chars, with at least one emoji",
                },
            },
            "required": [
                "cefrLevel", "examples", "exampleTranslations",
                "usageNotes", "relatedWords", "curiosityFacts", "notificationMessage",
            ],
        }

    def enrich_batch(self, enriched_words: List[Dict], batch_size: int = 100) -> List[Dict]:
        """Enrich words via Gemini Batch API with structured output.

        Submits words as inline batch requests for 50% cost savings.
        Uses SDK types to handle request formatting.
        """
        total = len(enriched_words)
        total_batches = (total + batch_size - 1) // batch_size
        print(f"\n  Submitting {total} words via Gemini Batch API ({self.model})")
        print(f"    Batch size: {batch_size}, total batches: {total_batches}")

        schema = self._build_gemini_schema()
        all_results: List[Optional[dict]] = [None] * total

        for batch_start in range(0, total, batch_size):
            batch_end = min(batch_start + batch_size, total)
            batch_words = enriched_words[batch_start:batch_end]
            batch_num = batch_start // batch_size + 1

            print(f"\n    ── Batch {batch_num}/{total_batches} ({len(batch_words)} words) ──")

            # Build inline requests with structured output config
            # Use metadata to track request→response mapping (batch API may reorder)
            inline_requests = []
            for local_i, word_data in enumerate(batch_words):
                global_idx = batch_start + local_i
                prompt = self._build_prompt(word_data)
                inline_requests.append({
                    "contents": [
                        {"parts": [{"text": prompt}], "role": "user"}
                    ],
                    "config": {
                        "response_mime_type": "application/json",
                        "response_schema": schema,
                    },
                    "metadata": {"idx": str(global_idx)},
                })

            # Submit batch
            print(f"    Submitting ...")
            batch_job = self.client.batches.create(
                model=self.model,
                src=inline_requests,
                config={"display_name": f"wordy-{batch_num}"},
            )
            print(f"    Job: {batch_job.name}")

            # Poll for completion
            completed_states = {"JOB_STATE_SUCCEEDED", "JOB_STATE_FAILED",
                                "JOB_STATE_CANCELLED", "JOB_STATE_EXPIRED"}

            poll_count = 0
            while batch_job.state.name not in completed_states:
                time.sleep(15)
                batch_job = self.client.batches.get(name=batch_job.name)
                poll_count += 1
                if poll_count % 4 == 0:  # Log every minute
                    print(f"    Waiting... {batch_job.state.name} ({poll_count * 15}s)")

            print(f"    Done: {batch_job.state.name}")

            if batch_job.state.name != "JOB_STATE_SUCCEEDED":
                print(f"    ⚠️  Batch {batch_num} failed: {getattr(batch_job, 'error', 'unknown')}")
                continue

            # Extract inline results — match by metadata idx (not position)
            if batch_job.dest and batch_job.dest.inlined_responses:
                success = 0
                for resp in batch_job.dest.inlined_responses:
                    try:
                        # Recover the global index from metadata
                        meta = resp.metadata or {}
                        idx_str = meta.get("idx")
                        if idx_str is None:
                            # Fallback: shouldn't happen but log it
                            print(f"    ⚠️  Response missing metadata idx")
                            continue
                        idx = int(idx_str)
                        if resp.response and resp.response.candidates:
                            text = resp.response.candidates[0].content.parts[0].text
                            all_results[idx] = json.loads(text)
                            success += 1
                    except (json.JSONDecodeError, IndexError, AttributeError, ValueError) as e:
                        word_label = enriched_words[idx].get("word", "?") if 'idx' in dir() else "?"
                        print(f"    ⚠️  Parse error for '{word_label}': {e}")

                print(f"    ✓ {success}/{len(batch_words)} enriched")
            else:
                print(f"    ⚠️  No inline responses returned")

        # Merge results into enriched words
        merged = sum(1 for r in all_results if r is not None)
        print(f"\n  Merging {merged}/{total} LLM results with grammar data ...")
        for i, word_data in enumerate(enriched_words):
            creative = all_results[i]
            if creative:
                for field in ["cefrLevel", "examples", "exampleTranslations",
                              "usageNotes", "relatedWords", "curiosityFacts",
                              "notificationMessage"]:
                    if field in creative and creative[field] is not None:
                        word_data[field] = creative[field]

        print(f"  ✓ Merged {merged}/{total} words")
        return enriched_words

    # ── Step 4: Export ─────────────────────────────────────────────────────

    def export_ios(self, words: List[Dict], output_path: str) -> Dict:
        """Export enriched words to iOS JSON format."""
        output = Path(output_path)
        output.parent.mkdir(parents=True, exist_ok=True)
        return WordFormatConverter.create_ios_export(words, self.lang_info, output)

    # ── Full Pipeline ──────────────────────────────────────────────────────

    def run(
        self,
        count: int,
        output_dir: str = DEFAULT_OUTPUT_DIR,
        pos_types: Optional[List[str]] = None,
        batch_size: int = 100,
    ) -> List[Dict]:
        """Run the full pipeline: select → grammar → batch enrich → export."""
        start_time = time.time()

        print("\n" + "=" * 60)
        print(f"  Hybrid Generator — {count} words via Gemini Batch")
        print("=" * 60)

        # Step 1: Select words
        print("\n── Step 1: Word Selection ─────────────────────────────────")
        selected = self.select_words(count, pos_types)
        if not selected:
            print("  No words selected. Exiting.")
            return []

        # Step 2: Grammar enrichment (local, fast)
        print("\n── Step 2: Grammar Enrichment (dictionary) ────────────────")
        enriched_words = []
        for i, word_info in enumerate(selected):
            enriched = self.enrich_grammar(word_info)
            enriched_words.append(enriched)
            if (i + 1) % 500 == 0:
                print(f"    Grammar enriched: {i + 1}/{len(selected)}")
        print(f"    ✓ Grammar enrichment complete: {len(enriched_words)} words")

        # Step 3: Batch enrichment via Gemini
        print("\n── Step 3: Gemini Batch Enrichment ────────────────────────")
        enriched_words = self.enrich_batch(enriched_words, batch_size=batch_size)

        # Register in dedup DB
        print("\n── Step 4: Register & Export ──────────────────────────────")
        for word_data in enriched_words:
            self.dedup.add_word({
                "word": word_data.get("word", ""),
                "translation": word_data.get("translation", ""),
                "language": "de",
                "cefrLevel": word_data.get("cefrLevel", ""),
            })

        # Export
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"hybrid_{timestamp}.json"
        output_path = Path(output_dir) / "german" / "exports" / filename
        self.export_ios(enriched_words, str(output_path))

        # Save raw data for debugging
        raw_path = Path(output_dir) / "german" / "hybrid_raw" / f"raw_{timestamp}.json"
        raw_path.parent.mkdir(parents=True, exist_ok=True)
        with open(raw_path, "w", encoding="utf-8") as f:
            json.dump(enriched_words, f, ensure_ascii=False, indent=2)
        print(f"  Raw data saved: {raw_path}")

        elapsed = time.time() - start_time
        print(f"\n{'=' * 60}")
        print(f"  Done! Generated {len(enriched_words)} words in {elapsed:.1f}s")
        print(f"  Export: {output_path}")
        print(f"{'=' * 60}\n")

        return enriched_words

    def close(self):
        self.dict_index.close()
        self.dedup.close()


    def postprocess(self, raw_path: str, output_dir: str = DEFAULT_OUTPUT_DIR) -> List[Dict]:
        """Post-process an existing raw JSON: add verb grammar from dictionary and re-export."""
        print(f"\n  Loading raw data from {raw_path} ...")
        with open(raw_path, "r", encoding="utf-8") as f:
            words = json.load(f)
        print(f"    {len(words)} words loaded")

        # Enrich verb grammar from dictionary
        verbs = [w for w in words if w.get("partOfSpeech") == "verb"]
        print(f"\n  Enriching {len(verbs)} verbs with grammar from dictionary ...")
        enriched_count = 0
        for word_data in verbs:
            raw_word = word_data.get("word", "")
            entries = self.dict_index.lookup(raw_word, "verb")
            if not entries:
                entries = self.dict_index.lookup(raw_word)
            if not entries:
                continue

            entry = entries[0]
            forms = entry.get("forms", [])

            # Auxiliary verb
            if not word_data.get("auxiliaryVerb"):
                for f in forms:
                    tags = set(f.get("tags", []))
                    form = f.get("form", "")
                    if tags == {"auxiliary"} and form in ("haben", "sein"):
                        word_data["auxiliaryVerb"] = form
                        break

            # Past participle
            if not word_data.get("pastParticiple"):
                for f in forms:
                    tags = set(f.get("tags", []))
                    form = f.get("form", "")
                    if {"participle", "past"} <= tags and "auxiliary" not in tags and form:
                        word_data["pastParticiple"] = form
                        break

            # Conjugation
            if not word_data.get("conjugation"):
                conj_map = {}
                for f in forms:
                    tags = set(f.get("tags", []))
                    form = f.get("form", "")
                    if not form or "indicative" not in tags or "present" not in tags:
                        continue
                    if {"first-person", "singular"} <= tags:
                        conj_map["ich"] = form
                    elif {"second-person", "singular"} <= tags:
                        conj_map["du"] = form
                    elif {"third-person", "singular"} <= tags:
                        conj_map["er/sie/es"] = form
                    elif {"first-person", "plural"} <= tags:
                        conj_map["wir"] = form
                    elif {"second-person", "plural"} <= tags:
                        conj_map["ihr"] = form
                    elif {"third-person", "plural"} <= tags:
                        conj_map["sie/Sie"] = form
                if conj_map:
                    parts = []
                    for pronoun in ["ich", "du", "er/sie/es", "wir", "ihr", "sie/Sie"]:
                        if pronoun in conj_map:
                            parts.append(f"{pronoun} {conj_map[pronoun]}")
                    if parts:
                        word_data["conjugation"] = ", ".join(parts)

            if word_data.get("auxiliaryVerb") or word_data.get("conjugation"):
                enriched_count += 1

        print(f"    ✓ {enriched_count}/{len(verbs)} verbs enriched with grammar")

        # Deduplicate: same normalized word → keep best POS, merge translations
        print(f"\n  Deduplicating words ...")
        pos_priority = {"noun": 0, "verb": 1, "adjective": 2, "adverb": 3}
        seen: Dict[str, int] = {}  # normalized_word → index in deduped list
        deduped: List[Dict] = []

        for w in words:
            raw = w.get("word", "").strip()
            article = (w.get("article") or "").strip()
            # Normalize: strip article prefix (same as iOS loader)
            normalized = raw
            if article:
                prefix = article.lower() + " "
                if normalized.lower().startswith(prefix):
                    normalized = normalized[len(prefix):].strip()
            key = normalized.lower()

            if key in seen:
                # Merge: append translation, keep higher-priority POS
                existing = deduped[seen[key]]
                existing_pos = existing.get("partOfSpeech", "")
                new_pos = w.get("partOfSpeech", "")
                existing_pri = pos_priority.get(existing_pos, 99)
                new_pri = pos_priority.get(new_pos, 99)

                # Merge translation
                existing_trans = existing.get("translation", "")
                new_trans = w.get("translation", "")
                if new_trans and new_trans not in existing_trans:
                    existing["translation"] = f"{existing_trans}; {new_trans}"

                # Replace if new POS has higher priority
                if new_pri < existing_pri:
                    # Keep merged translation, swap everything else
                    merged_trans = existing["translation"]
                    deduped[seen[key]] = w
                    deduped[seen[key]]["translation"] = merged_trans
            else:
                seen[key] = len(deduped)
                deduped.append(w)

        print(f"    {len(words)} → {len(deduped)} words ({len(words) - len(deduped)} duplicates merged)")
        words = deduped

        # Clean translations: short and learner-friendly (after dedup so merged translations are cleaned too)
        print(f"\n  Cleaning translations ...")
        cleaned = 0
        for w in words:
            trans = w.get("translation", "")
            # Strip parenthetical explanations
            clean = re.sub(r"\s*\(.*?\)", "", trans).strip()
            # Take first meaning before semicolon
            clean = clean.split(";")[0].strip().rstrip(",")
            # Keep at most 3 comma-separated synonyms
            parts = [p.strip() for p in clean.split(",") if p.strip()]
            clean = ", ".join(parts[:3])
            # Hard cap: truncate to first comma part if still long
            if len(clean) > 40:
                clean = parts[0] if parts else clean
            # Final safety: truncate at 50 chars
            if len(clean) > 50:
                clean = clean[:47].rsplit(" ", 1)[0] + "..."
            if clean and clean != trans:
                w["translation"] = clean
                cleaned += 1
        print(f"    ✓ {cleaned} translations cleaned")

        # Re-export
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"hybrid_{timestamp}.json"
        output_path = Path(output_dir) / "german" / "exports" / filename
        self.export_ios(words, str(output_path))

        # Save updated raw
        raw_out = Path(output_dir) / "german" / "hybrid_raw" / f"raw_{timestamp}.json"
        raw_out.parent.mkdir(parents=True, exist_ok=True)
        with open(raw_out, "w", encoding="utf-8") as f:
            json.dump(words, f, ensure_ascii=False, indent=2)
        print(f"  Updated raw saved: {raw_out}")

        print(f"\n  Done! Post-processed {len(words)} words → {output_path}")
        return words


def main():
    parser = argparse.ArgumentParser(
        description="Hybrid word generator: dictionary grammar + Gemini batch enrichment"
    )
    sub = parser.add_subparsers(dest="command")

    # Default: generate
    gen_parser = sub.add_parser("generate", help="Generate and enrich words (default)")
    gen_parser.add_argument("--count", type=int, default=10)
    gen_parser.add_argument("--pos", type=str, default=None)
    gen_parser.add_argument("--batch-size", type=int, default=100)
    gen_parser.add_argument("--output", type=str, default=DEFAULT_OUTPUT_DIR)
    gen_parser.add_argument("--dict-db", type=str, default=DEFAULT_DICT_DB)
    gen_parser.add_argument("--dedup-db", type=str, default=DEFAULT_DEDUP_DB)
    gen_parser.add_argument("--max-rank", type=int, default=DEFAULT_MAX_RANK)
    gen_parser.add_argument("--model", type=str, default=DEFAULT_MODEL)
    gen_parser.add_argument("--api-key", type=str, default=None)

    # Postprocess
    pp_parser = sub.add_parser("postprocess", help="Post-process raw JSON: add verb grammar and re-export")
    pp_parser.add_argument("raw_path", help="Path to raw JSON file")
    pp_parser.add_argument("--output", type=str, default=DEFAULT_OUTPUT_DIR)
    pp_parser.add_argument("--dict-db", type=str, default=DEFAULT_DICT_DB)

    args = parser.parse_args()

    # Default to generate if no subcommand given
    command = args.command or "generate"

    if command == "postprocess":
        gen = HybridGenerator.__new__(HybridGenerator)
        gen.dict_index = DictIndex(args.dict_db)
        gen.lang_info = GERMAN_LANG_INFO
        try:
            gen.postprocess(args.raw_path, output_dir=args.output)
        finally:
            gen.dict_index.close()
        return

    # generate
    api_key = args.api_key or os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("Error: Set GEMINI_API_KEY or pass --api-key")
        sys.exit(1)

    pos_types = None
    if args.pos:
        pos_types = [p.strip() for p in args.pos.split(",")]
        valid_pos = set(WIKTIONARY_POS_MAP.keys())
        for p in pos_types:
            if p not in valid_pos:
                print(f"Error: Invalid POS '{p}'. Must be one of: {', '.join(valid_pos)}")
                sys.exit(1)

    gen = HybridGenerator(
        api_key=api_key,
        dict_db=args.dict_db,
        dedup_db=args.dedup_db,
        max_rank=args.max_rank,
        model=args.model,
    )

    try:
        words = gen.run(
            count=args.count,
            output_dir=args.output,
            pos_types=pos_types,
            batch_size=args.batch_size,
        )
    finally:
        gen.close()

    if not words:
        sys.exit(1)


if __name__ == "__main__":
    main()
