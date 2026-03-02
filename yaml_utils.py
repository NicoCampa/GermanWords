#!/usr/bin/env python3
"""
YAML/JSON Conversion Utilities for Wordy App
Handles conversion between development (YAML) and production (JSON) formats
"""

import json
import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime
import unicodedata


class WordFormatConverter:
    """Convert between YAML and JSON word formats"""

    # CEFR to app difficulty mapping
    CEFR_TO_DIFFICULTY = {
        'A1': 1,  # Beginner
        'A2': 1,  # Elementary
        'B1': 2,  # Intermediate
        'B2': 2,  # Upper Intermediate
        'C1': 3,  # Advanced
        'C2': 3,  # Proficient (native-like)
    }

    @staticmethod
    def normalize_text(text: str) -> str:
        """Normalize Unicode text"""
        return unicodedata.normalize('NFC', text.strip())

    @classmethod
    def cefr_to_difficulty(cls, cefr_level: str) -> int:
        """Convert CEFR level to app difficulty (1-3)"""
        return cls.CEFR_TO_DIFFICULTY.get(cefr_level.upper(), 2)

    @classmethod
    def yaml_to_dict(cls, yaml_path: Path) -> Dict:
        """Load YAML file and return as dict"""
        with open(yaml_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)

    @classmethod
    def dict_to_yaml(cls, data: Dict, yaml_path: Path, sort_keys: bool = False):
        """Save dict to YAML file"""
        yaml_path.parent.mkdir(parents=True, exist_ok=True)
        with open(yaml_path, 'w', encoding='utf-8') as f:
            yaml.dump(
                data,
                f,
                default_flow_style=False,
                allow_unicode=True,
                sort_keys=sort_keys,
                width=120
            )

    @classmethod
    def dict_to_json(cls, data: Dict, json_path: Path, indent: int = 2):
        """Save dict to JSON file"""
        json_path.parent.mkdir(parents=True, exist_ok=True)
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=indent, ensure_ascii=False)

    @classmethod
    def normalize_word_list(cls, words: List[Dict]) -> List[Dict]:
        """
        Normalize a list of word dictionaries from Phase 1 format

        Input (minimal):
          - word: Gemütlichkeit
            translation: Coziness
            cefr: B1

        Output (normalized):
          - word: Gemütlichkeit
            translation: Coziness
            cefrLevel: B1
            difficultyLevel: 2
        """
        normalized = []

        for word_data in words:
            if not word_data.get('word'):
                continue

            norm = {
                'word': cls.normalize_text(word_data['word']),
                'translation': cls.normalize_text(word_data.get('translation', '')),
            }

            # Handle CEFR level (may be 'cefr' or 'cefrLevel')
            cefr = word_data.get('cefrLevel') or word_data.get('cefr', 'B1')
            norm['cefrLevel'] = cefr.upper()
            norm['difficultyLevel'] = cls.cefr_to_difficulty(norm['cefrLevel'])

            normalized.append(norm)

        return normalized

    @classmethod
    def enrich_to_ios_format(cls, enriched_word: Dict, language_info: Dict) -> Dict:
        """
        Convert enriched word data to iOS app format

        Input (enriched YAML):
          word: Gemütlichkeit
          translation: Coziness
          cefrLevel: B1
          usageNotes: "..."
          examples: [...]
          exampleTranslations: [...]
          curiosityFacts: "..."
          relatedWords: [...]

        Output (iOS JSON):
          {
            "word": "Gemütlichkeit",
            "translation": "Coziness",
            "usageNotes": "...",
            "examples": [...],
            "exampleTranslations": [...],
            "difficultyLevel": 2,
            "curiosityFacts": "...",
            "relatedWords": [...],
            "sourceLanguage": "de",
            "targetLanguage": "en",
            "pronunciationCode": "de-DE"
          }
        """
        # Basic fields
        ios_word = {
            'word': cls.normalize_text(enriched_word['word']),
            'translation': cls.normalize_text(enriched_word.get('translation', '')),
            'usageNotes': cls.normalize_text(enriched_word.get('usageNotes', '')),
        }

        # CEFR and difficulty
        cefr = enriched_word.get('cefrLevel', 'B1')
        ios_word['cefrLevel'] = cefr.upper()
        ios_word['difficultyLevel'] = cls.cefr_to_difficulty(cefr)

        # Examples (ensure arrays)
        examples = enriched_word.get('examples', [])
        if isinstance(examples, str):
            examples = [examples]
        ios_word['examples'] = [cls.normalize_text(ex) for ex in examples]

        # Example translations
        example_translations = enriched_word.get('exampleTranslations', [])
        if isinstance(example_translations, str):
            example_translations = [example_translations]
        ios_word['exampleTranslations'] = [cls.normalize_text(ex) for ex in example_translations]

        # Curiosity facts (convert to semicolon-separated string if needed)
        curiosity = enriched_word.get('curiosityFacts', '')
        if isinstance(curiosity, list):
            curiosity = '; '.join(str(item) for item in curiosity)
        ios_word['curiosityFacts'] = cls.normalize_text(curiosity) if curiosity else None

        # Similar words and synonyms -> semicolon-separated string
        similar_entries: List[str] = []
        if 'relatedWords' in enriched_word and enriched_word['relatedWords'] is not None:
            ios_word['relatedWords'] = enriched_word['relatedWords']

        # Language info
        ios_word['sourceLanguage'] = language_info.get('code', 'de')
        ios_word['pronunciationCode'] = language_info.get('pronunciation_code', 'de-DE')

        # Notification message
        notification = enriched_word.get('notificationMessage')
        if notification:
            ios_word['notificationMessage'] = cls.normalize_text(notification)

        # Article & gender (if present)
        article = enriched_word.get('article')
        if isinstance(article, str) and article.strip():
            ios_word['article'] = cls.normalize_text(article)

        gender = enriched_word.get('gender')
        if isinstance(gender, str) and gender.strip():
            ios_word['gender'] = cls.normalize_text(gender)


        # Part of speech and simple grammar metadata
        if enriched_word.get('partOfSpeech'):
            ios_word['partOfSpeech'] = str(enriched_word['partOfSpeech']).strip()
        if enriched_word.get('plural'):
            ios_word['plural'] = cls.normalize_text(enriched_word['plural'])
        if 'relatedWords' in enriched_word and enriched_word['relatedWords'] is not None:
            ios_word['relatedWords'] = enriched_word['relatedWords']

        # Copy list/dict fields directly if present
        def add_if_present(source_key: str, target_key: str = None):
            if source_key in enriched_word and enriched_word[source_key] is not None:
                ios_word[target_key or source_key] = enriched_word[source_key]

        add_if_present('practiceQuiz')
        if 'antonym' in enriched_word and enriched_word['antonym'] is not None:
            ios_word['antonym'] = enriched_word['antonym']

        # Usage notes (merged field)
        if enriched_word.get('usageNotes'):
            ios_word['usageNotes'] = cls.normalize_text(enriched_word['usageNotes'])

        # Verb conjugation: support both dict format (old) and flat fields (new)
        if enriched_word.get('conjugation') and isinstance(enriched_word['conjugation'], dict):
            ios_word['verbConjugation'] = cls._normalize_conjugation(enriched_word['conjugation'])
        elif enriched_word.get('conjugation') and isinstance(enriched_word['conjugation'], str):
            # Convert "ich gehe, du gehst, ..." string to structured format
            verb_conj: Dict = {}
            present_tense: Dict = {}
            pronoun_map = {
                "ich": "ich", "du": "du", "er/sie/es": "er_sie_es",
                "wir": "wir", "ihr": "ihr", "sie/Sie": "sie_Sie",
            }
            for part in enriched_word['conjugation'].split(", "):
                part = part.strip()
                for pronoun, key in pronoun_map.items():
                    if part.startswith(pronoun + " "):
                        present_tense[key] = part[len(pronoun) + 1:]
                        break
            if present_tense:
                verb_conj['presentTense'] = present_tense
            perfect: Dict = {}
            if enriched_word.get('auxiliaryVerb'):
                perfect['auxiliary'] = enriched_word['auxiliaryVerb']
            if enriched_word.get('pastParticiple'):
                perfect['participle'] = enriched_word['pastParticiple']
            if perfect:
                verb_conj['perfect'] = perfect
            if verb_conj:
                ios_word['verbConjugation'] = verb_conj
        if enriched_word.get('adjectiveForms'):
            ios_word['adjectiveForms'] = cls._normalize_adjective_forms(enriched_word['adjectiveForms'])

        return ios_word

    # Pronoun prefixes to strip from conjugation values
    _PRONOUN_PREFIXES = {
        'ich': 'ich ',
        'du': 'du ',
        'er_sie_es': 'er/sie/es ',
        'wir': 'wir ',
        'ihr': 'ihr ',
        'sie_Sie': 'sie/Sie ',
    }

    @classmethod
    def _strip_pronoun(cls, form_key: str, value: str) -> str:
        """Strip leading pronoun prefix from a conjugation form value."""
        prefix = cls._PRONOUN_PREFIXES.get(form_key)
        if prefix and value.lower().startswith(prefix.lower()):
            return value[len(prefix):].strip()
        return value.strip()

    @classmethod
    def _normalize_conjugation(cls, conjugation: Dict) -> Dict:
        if not isinstance(conjugation, dict):
            return {}

        normalized: Dict = {}

        present = conjugation.get('presentTense')
        if isinstance(present, dict):
            normalized_present = {}
            for form, value in present.items():
                if isinstance(value, str):
                    stripped = cls._strip_pronoun(form, value.strip())
                    if stripped:
                        normalized_present[form] = stripped
            if normalized_present:
                normalized['presentTense'] = normalized_present

        past = conjugation.get('pastTense')
        if isinstance(past, dict):
            normalized_past = {}
            for form, value in past.items():
                if isinstance(value, str):
                    stripped = cls._strip_pronoun(form, value.strip())
                    if stripped:
                        normalized_past[form] = stripped
            if normalized_past:
                normalized['pastTense'] = normalized_past

        perfect = conjugation.get('perfect')
        if isinstance(perfect, dict):
            normalized_perfect = {}
            for key, value in perfect.items():
                if value is not None:
                    normalized_perfect[key] = str(value).strip()
            if normalized_perfect:
                normalized['perfect'] = normalized_perfect

        # Carry over any additional metadata (e.g., infinitive)
        for key, value in conjugation.items():
            if key not in {'presentTense', 'pastTense', 'perfect'}:
                if value is not None:
                    normalized[key] = str(value).strip()

        return normalized

    @classmethod
    def _normalize_adjective_forms(cls, forms: Dict) -> Dict:
        if not isinstance(forms, dict):
            return {}

        normalized: Dict = {}
        for key, value in forms.items():
            if value is not None:
                normalized[key] = str(value).strip()
            else:
                normalized[key] = value
        return normalized

    @classmethod
    def create_ios_export(cls, words: List[Dict], language_info: Dict, output_path: Path):
        """
        Create complete iOS export file with metadata

        Output format:
        {
          "metadata": {
            "exportDate": "...",
            "language": {...},
            "totalWords": 100,
            "difficultyDistribution": {...}
          },
          "words": [...]
        }
        """
        # Convert all words to iOS format
        ios_words = []
        for word in words:
            try:
                ios_word = cls.enrich_to_ios_format(word, language_info)
                ios_words.append(ios_word)
            except Exception as e:
                print(f"⚠️  Skipped word {word.get('word', 'unknown')}: {e}")

        # Sort by difficulty, then alphabetically
        ios_words.sort(key=lambda x: (x.get('difficultyLevel', 1), x.get('word', '').lower()))

        # Create metadata
        difficulty_dist = {}
        for level in [1, 2, 3]:
            difficulty_dist[str(level)] = len([w for w in ios_words if w.get('difficultyLevel') == level])

        export_data = {
            'metadata': {
                'exportDate': datetime.now().isoformat(),
                'schemaVersion': 2,
                'language': {
                    'code': language_info.get('code', 'de'),
                    'name': language_info.get('name', 'German'),
                    'nativeName': language_info.get('native_name', 'Deutsch'),
                    'pronunciationCode': language_info.get('pronunciation_code', 'de-DE')
                },
                'totalWords': len(ios_words),
                'difficultyDistribution': difficulty_dist
            },
            'words': ios_words
        }

        # Save to JSON
        cls.dict_to_json(export_data, output_path)

        print(f"✅ Exported {len(ios_words)} words to {output_path}")
        print(f"📊 Difficulty distribution:")
        for level, count in difficulty_dist.items():
            print(f"   Level {level}: {count} words")

        return export_data


def test_conversion():
    """Test YAML/JSON conversion"""
    print("🧪 Testing YAML/JSON Conversion\n")

    # Test data
    test_words = [
        {
            'word': 'Gemütlichkeit',
            'translation': 'Coziness',
            'cefrLevel': 'B1',
            'usageNotes': 'A warm, friendly atmosphere that makes you feel at home.',
            'examples': [
                'Das Café hat eine tolle Gemütlichkeit.',
                'Ich liebe die Gemütlichkeit hier.'
            ],
            'exampleTranslations': [
                'The café has a great cozy atmosphere.',
                'I love the coziness here.'
            ],
            'curiosityFacts': 'Etymology: From gemüt (mind) + lich (like) + keit (ness); Regional usage: Common in Southern Germany',
            'relatedWords': [
                {'word': 'Behaglichkeit', 'note': 'Similar comfort'},
                {'word': 'Wärme', 'note': 'Warmth'}
            ],
        }
    ]

    language_info = {
        'code': 'de',
        'name': 'German',
        'native_name': 'Deutsch',
        'pronunciation_code': 'de-DE'
    }

    # Test 1: Save to YAML
    print("Test 1: Saving to YAML")
    yaml_path = Path("test_words.yaml")
    WordFormatConverter.dict_to_yaml({'words': test_words}, yaml_path)
    print(f"  ✅ Saved to {yaml_path}")

    # Test 2: Load from YAML
    print("\nTest 2: Loading from YAML")
    loaded_data = WordFormatConverter.yaml_to_dict(yaml_path)
    print(f"  ✅ Loaded {len(loaded_data['words'])} words")

    # Test 3: Convert to iOS format
    print("\nTest 3: Converting to iOS format")
    ios_word = WordFormatConverter.enrich_to_ios_format(test_words[0], language_info)
    print(f"  ✅ Converted: {ios_word['word']}")
    print(f"     Difficulty: {ios_word['difficultyLevel']}")

    # Test 4: Create full export
    print("\nTest 4: Creating iOS export")
    export_path = Path("test_export.json")
    WordFormatConverter.create_ios_export(test_words, language_info, export_path)
    print(f"  ✅ Export complete")

    # Test 5: CEFR to difficulty mapping
    print("\nTest 5: CEFR to difficulty mapping")
    for cefr in ['A1', 'A2', 'B1', 'B2', 'C1']:
        diff = WordFormatConverter.cefr_to_difficulty(cefr)
        print(f"  {cefr} → Level {diff}")

    # Cleanup
    yaml_path.unlink()
    export_path.unlink()

    print("\n✅ All tests passed!")


if __name__ == "__main__":
    test_conversion()
