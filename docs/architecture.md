# Architecture

## Layers and ownership

The application uses three reusable activity layers:

1. **Learning content** — `MathQuestion`, `LevelDefinition`, and
   `QuestionRepository` describe question data, answer, skill, difficulty,
   level scope, and activity type. Content is independent of concrete visual
   objects.
2. **Gameplay mechanics** — `ActivityRenderer` chooses `CountingActivity`,
   `MultipleChoiceActivity`, or `DragDropActivity`. Mechanics render validated
   question data and submit integer answers; they do not score, time, persist,
   or progress the learner.
3. **Visual presentation** — `CountingTheme` selects interchangeable object
   icons and colors. The presentation-only mascot reacts to session events and
   has no authority over learning decisions.

The shared `SessionController` owns one active session: it validates selected
questions, records attempts and response times, evaluates answers, advances
questions, and saves a completed `SessionResult`. It does not choose adaptive
content during a session.

`AdaptiveAssessmentEngine` evaluates completed evidence and updates mastery,
skill summaries, difficulty recommendation, completion eligibility, trend,
and diagnostics. `AdaptiveProgressRepository` persists per-level state.
`AdaptiveSessionPlanner` uses that saved state to choose a later five-question
session from the same level's bank. Neither assessment eligibility nor a
completed session unlocks another level.

## Entry points and modules

- `lib/main.dart` constructs local repositories and providers.
- `lib/app.dart` configures the application theme and router.
- `lib/navigation/app_router.dart` defines `/`, `/levels`, `/play/:levelId`,
  `/demo`, and `/results`; unavailable levels redirect safely.
- `lib/screens/` coordinates UI and displays controller state.
- `lib/content/` owns the 25-level catalogue and 36 Level 1 questions.
- `lib/domain/` owns validated content, attempt/result, and adaptive models.
- `lib/session/session_controller.dart` owns session lifecycle and evidence.
- `lib/session/adaptive_session_planner.dart` owns next-session selection.
- `lib/mechanics/` owns mechanic widgets and renderer selection.
- `lib/presentation/mascot/` owns mascot event/state mapping and animation.
- `lib/persistence/` defines repositories and local `shared_preferences`
  implementations; session history and adaptive progress remain separate.
- `test/` verifies mechanics, session behavior, persistence, adaptation,
  planning, navigation, and mascot presentation.

## Main data flow

1. The play screen loads adaptive progress, uses Easy for a new learner, and
   asks the planner for exactly five valid level-scoped questions.
2. The session controller validates the planned set and starts the session.
   `ActivityRenderer` dispatches each question to its mechanic.
3. A mechanic submits an integer answer. The controller records correctness,
   attempts, hint use, and response time, then advances without adaptive
   difficulty changes mid-session.
4. Completion saves the session evidence and passes it to the assessment
   engine. A processed session ID is idempotent; existing session-result
   persistence remains separate and readable.
5. The next session reads the updated difficulty recommendation, focus skill,
   and recent question IDs. Selection remains within Level 1; Levels 2–25 stay
   locked.
6. A session-event bridge translates lifecycle and answer state into mascot
   events. Mascot state and animation cannot alter the controller, assessment,
   planner, persistence, or progression.

Detailed rule choices and provisional assumptions are in
[adaptive-assessment.md](adaptive-assessment.md) and
[adaptive-session-planning.md](adaptive-session-planning.md).
