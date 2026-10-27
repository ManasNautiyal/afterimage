# AFTERIMAGE

**Your past self is trying to stop you.**

A top-down survival arcade game built with Flutter and Flame. Survive an increasingly dangerous neon arena while your own ghost replays haunt your path.

## Game Overview

- **Genre:** Top-down survival arcade
- **Platform:** Android (portrait mode)
- **Engine:** Flutter + Flame
- **Monetization:** Google AdMob (optional, game works offline)

### Core Mechanic
Every few seconds, a ghost appears that replays your earlier movements. As you survive longer, more ghosts appear, turning your own history against you. Dodge red hazards, collect energy fragments, and chase high scores.

## Setup

### Prerequisites
- Flutter SDK (3.7+)
- Android Studio with Android SDK
- A connected Android device or emulator

### Install and Run
```bash
flutter pub get
flutter run
flutter build apk --debug
```

### Testing
```bash
flutter test
flutter analyze
dart format lib test
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/                         # Theme, constants, root widget
├── game/                        # Flame game, components, systems
├── screens/                     # Menu, gameplay, game over, skins, settings
├── services/                    # Storage, audio, ads
├── models/                      # Player stats, skins, run results
└── widgets/                     # Neon buttons, displays, overlays
```

## Key Features

- Ghost Replay Mechanic with timestamped interpolation
- 5 Unlockable Cosmetic Skins
- Progressive Difficulty System
- Offline-first gameplay
- Neon procedural rendering
- Virtual joystick + keyboard support
- AdMob integration with test IDs

## Ad Configuration for Release

Edit `lib/services/ads_service.dart`:
1. Set `_useTestAds = false`
2. Replace production ad unit IDs
3. Add AdMob App ID to AndroidManifest.xml
4. Implement GDPR consent where required

## License

Proprietary - All rights reserved.
