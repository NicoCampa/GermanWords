#!/usr/bin/env python3
"""
Frequency Loader — Map German word frequency ranks to CEFR levels.

Uses the FrequencyWords (hermitdave/FrequencyWords) German 50k list from
OpenSubtitles to estimate CEFR levels based on frequency rank:

    Rank 1-1000     → A1  (most common everyday words)
    Rank 1001-3000  → A2  (elementary vocabulary)
    Rank 3001-6000  → B1  (intermediate)
    Rank 6001-12000 → B2  (upper intermediate)
    Rank 12001+     → C1  (advanced)
    Unknown         → C1  (assume advanced if not in frequency list)

Usage:
    from frequency_loader import FrequencyLoader
    fl = FrequencyLoader("data/de_50k.txt")
    print(fl.get_cefr("Haus"))   # "A1"
    print(fl.get_cefr("Gemütlichkeit"))  # "C1"
"""

from pathlib import Path
from typing import Dict, Optional


# CEFR thresholds by frequency rank
CEFR_THRESHOLDS = [
    (1000, "A1"),
    (3000, "A2"),
    (6000, "B1"),
    (12000, "B2"),
]
DEFAULT_CEFR = "C1"

DEFAULT_PATH = "data/de_50k.txt"


class FrequencyLoader:
    """Load word frequency data and map frequency rank to CEFR level."""

    def __init__(self, path: str = DEFAULT_PATH):
        self.path = path
        self._rank: Dict[str, int] = {}  # normalized_word → rank
        self._load()

    def _load(self) -> None:
        """Parse the frequency file: 'word frequency' per line."""
        p = Path(self.path)
        if not p.exists():
            raise FileNotFoundError(
                f"Frequency file not found: {self.path}\n"
                f"Download it with: python dict_index.py --download"
            )

        rank = 0
        with open(p, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                parts = line.split()
                if len(parts) >= 2:
                    word = parts[0]
                    rank += 1
                    # Store by lowercase for case-insensitive lookup
                    normalized = word.lower()
                    if normalized not in self._rank:
                        self._rank[normalized] = rank

    def get_rank(self, word: str) -> Optional[int]:
        """Get the frequency rank for a word (1 = most frequent). None if unknown."""
        return self._rank.get(word.lower().strip())

    def get_cefr(self, word: str) -> str:
        """Map a word's frequency rank to an estimated CEFR level."""
        rank = self.get_rank(word)
        if rank is None:
            return DEFAULT_CEFR

        for threshold, level in CEFR_THRESHOLDS:
            if rank <= threshold:
                return level

        return DEFAULT_CEFR

    def filter_by_cefr(self, words: list, level: str) -> list:
        """Filter a word list to only those matching the given CEFR level."""
        return [w for w in words if self.get_cefr(w) == level.upper()]

    def get_words_at_level(self, level: str) -> list:
        """Get all words from the frequency list at a specific CEFR level."""
        level = level.upper()
        result = []
        for word, rank in sorted(self._rank.items(), key=lambda x: x[1]):
            if self._rank_to_cefr(rank) == level:
                result.append(word)
        return result

    @staticmethod
    def _rank_to_cefr(rank: int) -> str:
        """Convert a numeric rank to CEFR level."""
        for threshold, level in CEFR_THRESHOLDS:
            if rank <= threshold:
                return level
        return DEFAULT_CEFR

    def __len__(self) -> int:
        return len(self._rank)

    def __contains__(self, word: str) -> bool:
        return word.lower().strip() in self._rank
