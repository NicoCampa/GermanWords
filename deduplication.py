#!/usr/bin/env python3
"""
Advanced Deduplication System for Wordy App
Uses Bloom Filter + SQLite for scalable duplicate detection
"""

import sqlite3
from pathlib import Path
from typing import Set, Optional, List, Dict
import unicodedata
from datetime import datetime

try:
    from pybloom_live import BloomFilter
    BLOOM_AVAILABLE = True
except ImportError:
    print("⚠️  pybloom-live not available. Install with: pip install pybloom-live")
    BLOOM_AVAILABLE = False


class WordDatabase:
    """SQLite database for persistent word storage and querying"""

    def __init__(self, db_path: str = "words.db"):
        self.db_path = Path(db_path)
        self.conn = sqlite3.connect(str(self.db_path))
        self.conn.row_factory = sqlite3.Row
        self._create_tables()

    def _create_tables(self):
        """Create database schema"""
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS words (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word TEXT NOT NULL,
                word_normalized TEXT NOT NULL,
                translation TEXT,
                language TEXT NOT NULL,
                cefr_level TEXT,
                difficulty_level INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(word_normalized, language)
            );

            CREATE INDEX IF NOT EXISTS idx_word_normalized
                ON words(word_normalized);

            CREATE INDEX IF NOT EXISTS idx_language
                ON words(language);

            CREATE INDEX IF NOT EXISTS idx_cefr
                ON words(cefr_level);

            CREATE TABLE IF NOT EXISTS translations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                translation TEXT NOT NULL,
                translation_normalized TEXT NOT NULL,
                language TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(translation_normalized, language)
            );

            CREATE INDEX IF NOT EXISTS idx_translation_normalized
                ON translations(translation_normalized);
        """)
        self.conn.commit()

    @staticmethod
    def normalize_text(text: str) -> str:
        """Normalize text for comparison"""
        return unicodedata.normalize('NFC', text.strip().lower())

    def is_word_duplicate(self, word: str, language: str) -> bool:
        """Check if word already exists"""
        normalized = self.normalize_text(word)
        cursor = self.conn.execute(
            "SELECT 1 FROM words WHERE word_normalized = ? AND language = ? LIMIT 1",
            (normalized, language)
        )
        return cursor.fetchone() is not None

    def is_translation_duplicate(self, translation: str, language: str) -> bool:
        """Check if translation already exists (avoid concept duplicates)"""
        normalized = self.normalize_text(translation)
        cursor = self.conn.execute(
            "SELECT 1 FROM translations WHERE translation_normalized = ? AND language = ? LIMIT 1",
            (normalized, language)
        )
        return cursor.fetchone() is not None

    def add_word(self, word_data: Dict) -> bool:
        """Add word to database. Returns True if added, False if duplicate."""
        try:
            word = word_data['word']
            language = word_data.get('sourceLanguage', word_data.get('language', 'de'))

            # Helper to convert lists to single values
            def ensure_scalar(value):
                """Convert complex types to a scalar representation."""
                if value is None:
                    return None
                if isinstance(value, list):
                    if not value:
                        return None
                    # Prefer first entry but stringify rest if needed
                    head = value[0]
                    if isinstance(head, (str, int, float)):
                        return head
                    return str(head)
                if isinstance(value, dict):
                    # Flatten dict into a readable string
                    items = [f"{k}: {v}" for k, v in value.items() if v is not None]
                    return ", ".join(items) if items else None
                if isinstance(value, (str, int, float)):
                    return value
                # Fallback: stringify custom objects
                return str(value)

            # Handle difficulty level - ensure it's a single value
            difficulty_level = ensure_scalar(word_data.get('difficultyLevel'))

            # Handle CEFR level - ensure it's a string
            cefr_level = ensure_scalar(word_data.get('cefrLevel'))

            # Handle translation - ensure it's a string
            translation = ensure_scalar(word_data.get('translation'))

            self.conn.execute("""
                INSERT INTO words
                (word, word_normalized, translation, language, cefr_level, difficulty_level)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                word,
                self.normalize_text(word),
                translation,
                language,
                cefr_level,
                difficulty_level
            ))

            # Also track translation
            if word_data.get('translation'):
                self.conn.execute("""
                    INSERT OR IGNORE INTO translations
                    (translation, translation_normalized, language)
                    VALUES (?, ?, ?)
                """, (
                    word_data['translation'],
                    self.normalize_text(word_data['translation']),
                    language
                ))

            self.conn.commit()
            return True

        except sqlite3.IntegrityError:
            # Duplicate
            return False

    def get_all_words(self, language: Optional[str] = None) -> List[str]:
        """Get all words, optionally filtered by language"""
        if language:
            cursor = self.conn.execute(
                "SELECT word FROM words WHERE language = ?",
                (language,)
            )
        else:
            cursor = self.conn.execute("SELECT word FROM words")

        return [row['word'] for row in cursor.fetchall()]

    def get_all_normalized_words(self, language: Optional[str] = None) -> Set[str]:
        """Get all normalized words for fast set operations"""
        if language:
            cursor = self.conn.execute(
                "SELECT word_normalized FROM words WHERE language = ?",
                (language,)
            )
        else:
            cursor = self.conn.execute("SELECT word_normalized FROM words")

        return {row['word_normalized'] for row in cursor.fetchall()}

    def get_stats(self) -> Dict:
        """Get database statistics"""
        stats = {}

        # Total words
        cursor = self.conn.execute("SELECT COUNT(*) as count FROM words")
        stats['total_words'] = cursor.fetchone()['count']

        # Words per language
        cursor = self.conn.execute("""
            SELECT language, COUNT(*) as count
            FROM words
            GROUP BY language
        """)
        stats['by_language'] = {row['language']: row['count'] for row in cursor.fetchall()}

        # Words per CEFR level
        cursor = self.conn.execute("""
            SELECT cefr_level, COUNT(*) as count
            FROM words
            WHERE cefr_level IS NOT NULL
            GROUP BY cefr_level
        """)
        stats['by_cefr'] = {row['cefr_level']: row['count'] for row in cursor.fetchall()}

        return stats

    def close(self):
        """Close database connection"""
        self.conn.close()


class HybridDuplicateChecker:
    """
    Hybrid deduplication using Bloom Filter (fast) + SQLite (accurate)

    Strategy:
    1. Bloom filter for fast O(1) checks (may have false positives)
    2. SQLite for accurate verification and persistence
    """

    def __init__(self, db_path: str = "words.db", capacity: int = 50000):
        self.db = WordDatabase(db_path)

        # Initialize Bloom filter
        if BLOOM_AVAILABLE:
            self.bloom = BloomFilter(capacity=capacity, error_rate=0.001)
            self._warm_bloom_filter()
            self.use_bloom = True
        else:
            self.bloom = None
            self.use_bloom = False
            print("⚠️  Running without Bloom filter (slower)")

    def _warm_bloom_filter(self):
        """Pre-populate Bloom filter from database"""
        print("🔥 Warming up Bloom filter...")
        words = self.db.get_all_normalized_words()
        for word in words:
            self.bloom.add(word)
        print(f"✅ Loaded {len(words)} words into Bloom filter")

    def is_duplicate(self, word: str, language: str, check_translation: bool = False,
                     translation: Optional[str] = None) -> tuple[bool, str]:
        """
        Check if word is duplicate

        Returns: (is_duplicate: bool, reason: str)
        """
        normalized_word = WordDatabase.normalize_text(word)

        # Fast Bloom filter check (if available)
        if self.use_bloom and normalized_word not in self.bloom:
            # Definitely not a duplicate
            return (False, "unique")

        # Bloom says "maybe duplicate" or we don't have Bloom - check database
        if self.db.is_word_duplicate(word, language):
            return (True, "word_exists")

        # Check translation duplicates if requested
        if check_translation and translation:
            if self.db.is_translation_duplicate(translation, language):
                return (True, "translation_exists")

        return (False, "unique")

    def add_word(self, word_data: Dict) -> bool:
        """
        Add word to both Bloom filter and database

        Returns: True if added, False if duplicate
        """
        word = word_data['word']
        normalized = WordDatabase.normalize_text(word)

        # Add to database
        added = self.db.add_word(word_data)

        # Add to Bloom filter if successfully added
        if added and self.use_bloom:
            self.bloom.add(normalized)
            if word_data.get('translation'):
                trans_normalized = WordDatabase.normalize_text(word_data['translation'])
                self.bloom.add(trans_normalized)

        return added

    def batch_check_duplicates(self, words: List[Dict], language: str) -> tuple[List[Dict], List[Dict]]:
        """
        Check a batch of words for duplicates

        Returns: (unique_words, duplicate_words)
        """
        unique = []
        duplicates = []

        for word_data in words:
            word = word_data.get('word', '')
            translation = word_data.get('translation', '')

            is_dup, reason = self.is_duplicate(
                word,
                language,
                check_translation=True,
                translation=translation
            )

            if is_dup:
                word_data['duplicate_reason'] = reason
                duplicates.append(word_data)
            else:
                unique.append(word_data)

        return unique, duplicates

    def get_stats(self) -> Dict:
        """Get statistics about stored words"""
        stats = self.db.get_stats()
        stats['bloom_filter_enabled'] = self.use_bloom
        if self.use_bloom:
            stats['bloom_filter_size'] = len(self.bloom)
        return stats

    def close(self):
        """Close connections"""
        self.db.close()


def test_deduplication():
    """Test the deduplication system"""
    print("🧪 Testing Deduplication System\n")

    # Create test database
    test_db = "test_words.db"
    if Path(test_db).exists():
        Path(test_db).unlink()

    checker = HybridDuplicateChecker(test_db)

    # Test 1: Add unique words
    print("Test 1: Adding unique words")
    test_words = [
        {
            'word': 'Gemütlichkeit',
            'translation': 'Coziness',
            'sourceLanguage': 'de',
            'cefrLevel': 'B1',
            'difficultyLevel': 2
        },
        {
            'word': 'Schadenfreude',
            'translation': 'Pleasure at misfortune',
            'sourceLanguage': 'de',
            'cefrLevel': 'B2',
            'difficultyLevel': 2
        }
    ]

    for word_data in test_words:
        added = checker.add_word(word_data)
        print(f"  {'✅' if added else '❌'} {word_data['word']}")

    # Test 2: Try to add duplicates
    print("\nTest 2: Trying to add duplicates")
    duplicate = test_words[0].copy()
    added = checker.add_word(duplicate)
    print(f"  {'❌ FAILED - Duplicate added!' if added else '✅ Correctly rejected duplicate'}")

    # Test 3: Batch duplicate check
    print("\nTest 3: Batch duplicate checking")
    batch = [
        {'word': 'Fernweh', 'translation': 'Travel longing', 'sourceLanguage': 'de'},
        {'word': 'Gemütlichkeit', 'translation': 'Coziness', 'sourceLanguage': 'de'},  # Duplicate
        {'word': 'Zeitgeist', 'translation': 'Spirit of the age', 'sourceLanguage': 'de'},
    ]

    unique, duplicates = checker.batch_check_duplicates(batch, 'de')
    print(f"  Unique: {len(unique)}")
    print(f"  Duplicates: {len(duplicates)}")

    for dup in duplicates:
        print(f"    - {dup['word']} ({dup['duplicate_reason']})")

    # Test 4: Statistics
    print("\nTest 4: Statistics")
    stats = checker.get_stats()
    print(f"  Total words: {stats['total_words']}")
    print(f"  By language: {stats['by_language']}")
    print(f"  Bloom filter enabled: {stats['bloom_filter_enabled']}")

    checker.close()

    # Cleanup
    Path(test_db).unlink()

    print("\n✅ All tests passed!")


if __name__ == "__main__":
    test_deduplication()
