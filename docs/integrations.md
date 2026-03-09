# Integrations

## Firebase

The app contains optional Firebase analytics and crash-reporting integration via:

- `aWordaDay/Managers/FirebaseAnalyticsManager.swift`

Local secrets/config remain outside Git:

- `aWordaDay/GoogleService-Info.plist`

## Notifications

Daily reminder scheduling is handled by:

- `aWordaDay/Managers/NotificationManager.swift`
- `aWordaDay/Services/NotificationWordSelector.swift`

Default reminder time is `18:00`, shown in the user’s locale format.

## Speech

Pronunciation playback is handled locally through:

- `aWordaDay/Managers/SpeechSynthesizerManager.swift`

## Content generation tooling

Generation and validation live under:

- `tooling/pipeline/`
- `tooling/scripts/`
- `tooling/validation/`

These are development-time integrations and are not shipped as part of the app runtime.
