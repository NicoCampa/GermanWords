# Product Overview

## App

`Wolke` is an iOS app for learning German vocabulary from a bundled dictionary of more than 9,500 words, with the content pipeline designed to scale beyond 10k entries.

## Current product shape

- German-only curriculum
- Daily word flow centered on consumption rather than explicit review prompts
- XP progression capped at level 50
- Favorites, streaks, browsing, and notifications
- Local bundled content via JSON + SQLite

## Core user experience

1. Open the app and receive a curated German word.
2. Read translation, examples, usage, and notes.
3. Gain XP when consuming a new word for the day.
4. Save favorite words with the double-tap heart gesture.
5. Browse the wider library and revisit learned vocabulary.

## Content model

Each bundled word can include:

- word
- translation
- CEFR level
- difficulty metadata
- examples and translations
- usage notes
- curiosity / notes content
- related words
- notification copy

## Product constraints

- The app is currently optimized for German only.
- App Store listing copy lives in App Store Connect, not in this repo.
- The repo keeps the shipping bundle and lean tooling, not large local generation archives.

## Release readiness checklist

- Build passes for the iOS app target
- Bundled JSON and SQLite catalog are in sync
- Onboarding and home flows reflect the current feature set
- Docs under `docs/` and `tooling/` match the live repo layout
