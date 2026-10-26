# Integration guide

## Worktree and branch workflow

Use `adaptive_math_adventure` as the app root. Keep each contribution on a
focused feature branch, add/update tests, run formatting/analyzer/tests/build,
then open a pull request against the team's chosen default branch. Do not
change another feature's persistence schema, public model, or route as a
side-effect; coordinate contract changes first.

Suggested independent workstreams:

- **Curriculum/content:** add reviewed questions and objectives in
  `lib/content/` using the existing `MathQuestion` schema.
- **Mechanics/accessibility:** implement mechanic widgets and tests without
  moving evaluation or timing out of `SessionController`.
- **Visual design/mascot:** adjust theme, layout, or mascot presentation without
  changing learning state.
- **Assessment/planning research:** propose calibrated policies and tests
  separately from widget code.
- **Persistence/platform:** improve local storage behind repository interfaces;
  preserve existing serialized session results and adaptive progress.

These are ownership suggestions, not permission to work concurrently on the
same files without coordination.

## Adding a question or level

1. Define the learning objective, skill tag, difficulty, level ID, supported
   activity type, validated prompt/options, and correct answer in the content
   repository.
2. Keep content independent of object artwork. Counting uses a numeric count;
   theme selection supplies its visual objects.
3. Ensure the level's `availableActivityTypes` and question-set reference agree
   with the bank. Do not select questions across level boundaries.
4. Add model/planner tests for correctness, uniqueness, difficulty, and
   insufficient-bank behavior.
5. Do not unlock a level as a side-effect of adding content. Progression policy
   is a separate product decision.

## Adding a mechanic

1. Extend `ActivityType`.
2. Define and validate its structured configuration in `ActivityContent`.
3. Implement a widget that receives validated question data, presentation
   configuration, an answer callback, and answer-lock state.
4. Register it in `ActivityRenderer` and enable it only for appropriate levels.
5. Submit the established integer answer type to `SessionController`; do not
   compare with the correct answer, record timing, persist, or advance in the
   widget.
6. Add mechanic and integration tests, including invalid content.

The three layers remain: learning content describes what is asked; mechanics
define how the learner interacts; presentation defines how objects/backgrounds
and animations look. A presentation change should not require new question
logic; a new mechanic should not copy assessment or session lifecycle code.

## Assessment, planning, mascot, and persistence boundaries

- Send completed `SessionResult` evidence to `AdaptiveAssessmentEngine`; do
  not put formulas in widgets or mechanics.
- Use the engine's persisted recommendation and focus/history as planner input.
  `AdaptiveSessionPlanner` must return only existing, eligible questions or
  report an explicit shortfall.
- Translate session lifecycle and answer outcomes into mascot events through
  `MascotSessionEventBridge`. Mascot animations must never change answers,
  scores, planning, persistence, or level access. A screen-time service may
  eventually send the sleeping lock event; that service does not exist yet.
- Add storage behind `SessionResultPersistence` or
  `AdaptiveProgressRepository`. Keep the two record types separate and preserve
  reading current local data if serialization changes.

## Validation checklist

```powershell
dart format --output=none --set-exit-if-changed lib test
dart analyze
flutter test
flutter build web --release
```

Review test evidence for the touched boundary, inspect `git diff`, and include
provisional assumptions in the relevant architecture or policy documentation.
