# Adaptive Math Adventure — Prototype v1

A Flutter Web mathematics-learning prototype for children aged 6–8. Level 1
contains a 36-question bank and runs five-question sessions using reusable
Counting, Multiple Choice, and Drag & Drop mechanics. A rule-based assessment
and session planner adapt later sessions from locally saved evidence. Levels
2–25 remain locked placeholders.

## Requirements

- Flutter SDK with Dart compatible with `pubspec.yaml` (`^3.12.0`)
- Chrome for the initial target

## Install and run

From this project directory:

```powershell
flutter pub get
flutter run -d chrome
```

The main flow is **Play → Level 1 → answer five questions → results → start
another session**. The separate `/demo` route demonstrates the available
activity mechanics. Session results and adaptive progress are stored locally
in browser preferences; clearing browser data removes this prototype data.

## Verify

```powershell
dart format --output=none --set-exit-if-changed lib test
dart analyze
flutter test
flutter build web --release
```

## Architecture at a glance

Content (`content/`, `domain/`) defines level-scoped questions and learning
evidence independently of artwork. The mechanic layer (`mechanics/`) renders
the interaction and submits an answer; the visual presentation layer
(`presentation/`) supplies replaceable counting themes and the event-driven
mascot. The `SessionController` owns answer evaluation, timing and attempts.
`AdaptiveAssessmentEngine` evaluates completed-session evidence, and
`AdaptiveSessionPlanner` selects questions for a future session. See
[docs/architecture.md](docs/architecture.md), [docs/INTEGRATION_GUIDE.md](docs/INTEGRATION_GUIDE.md),
and [docs/TEAM_HANDOVER.md](docs/TEAM_HANDOVER.md).

## Project files

- `lib/main.dart` — application bootstrap and persistence providers.
- `lib/app.dart`, `lib/navigation/app_router.dart` — theme and routes.
- `lib/screens/` — menu, levels, session, and results screens.
- `lib/content/`, `lib/domain/` — question bank, level definitions, and models.
- `lib/session/` — shared session controller and adaptive question planner.
- `lib/mechanics/` — activity renderer and reusable gameplay widgets.
- `lib/presentation/` — visual themes and event-driven mascot.
- `lib/persistence/`, `lib/progress/` — local repositories and history state.
- `test/` — unit and widget tests.
- `docs/` — assessment policy, planning policy, architecture, and handover.

This is a prototype, not a validated curriculum or production learner account
system. Current policies, content, and visual feedback require review. Levels
are not unlocked automatically.
