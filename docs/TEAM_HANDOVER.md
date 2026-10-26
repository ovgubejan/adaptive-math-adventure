# Team handover — Prototype v1

## Current functionality

- Flutter Web app shell with menu, level selection, play, results, and demo
  routes.
- Level 1 has 36 provisional questions across Easy/Medium/Hard and the existing
  Counting, Multiple Choice, and Drag & Drop mechanics. A session plans exactly
  five unique questions when the valid bank has sufficient content.
- Shared session controller records answers, attempts, response times, hints,
  and completion evidence.
- Rule-based assessment calculates session score, mastery, skill focus,
  recommended difficulty, level-completion eligibility, and trend.
- The next-session planner consumes saved adaptive state and avoids recently
  used questions when alternatives are sufficient.
- Mascot is integrated in the play screen. Correct/incorrect answers, session
  start, transitions, and completion update presentation state; sleeping has
  priority over gameplay celebration events.
- Session results and adaptive progress use separate local persistence
  abstractions.
- Levels 2–25 remain placeholders and cannot launch. Completion eligibility
  does not unlock them.

## Module status

| Area | Status | Notes |
|---|---|---|
| App shell/navigation | Implemented | Web/Chrome is the target. |
| Level 1 content/mechanics | Implemented provisionally | Content is not educator-validated. |
| Session evidence/persistence | Implemented | Browser-local preferences; not an account or sync system. |
| Adaptive assessment | Implemented provisionally | Deterministic rules, not machine learning. |
| Adaptive session planning | Implemented provisionally | Same-level selection; policy needs calibration. |
| Mascot | Integrated prototype | Built-in Flutter animation; artwork is placeholder. |
| Levels 2–25 | Not implemented | Locked placeholders only. |
| Parent accounts/dashboard/cloud | Absent | Explicitly out of scope. |
| Screen-time enforcement | Absent | Sleeping state/event is only a reserved presentation hook. |
| Production curriculum/accessibility review | Pending | Required before educational claims or release. |

## Known limitations

- Score weights, mastery thresholds, question bank, focus allocation, and
  difficulty rules are preliminary and require educator/child evaluation.
- Response efficiency is neutral because no suitable child-centered speed
  metric has been specified.
- Browser preference storage is local to the browser profile and offers no
  multi-user identity, backup, synchronization, or transactional concurrency.
- Integer answer payloads and current question schemas are prototype contracts;
  schema changes may require persistence versioning.
- Mascot art is custom-painted placeholder artwork; no screen-time lock invokes
  sleeping yet.
- Automated tests cover core policies and app surfaces; a full Chrome
  end-to-end acceptance run is still recommended for release candidates.

## Developer setup

1. Install Flutter/Dart matching the SDK constraint in `pubspec.yaml`.
2. From the project root, run `flutter pub get`.
3. Start Chrome with `flutter run -d chrome`.
4. Before submitting a branch, run the four commands in the README's Verify
   section. Keep changes focused and add tests for new behavior.
5. Create a feature branch; do not commit generated `build/`, `.dart_tool/`,
   secrets, or local credentials. `pubspec.lock` is intentionally tracked.

The app is currently a local prototype with no configured remote. See
[INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) for module boundaries and the
branch-based team workflow.
