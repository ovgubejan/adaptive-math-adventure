# Adaptive session planning

`AdaptiveSessionPlanner` is a deterministic, explainable question selector. It
is separate from `AdaptiveAssessmentEngine`: the engine evaluates completed
evidence and updates mastery/difficulty; the planner uses that saved result to
choose questions for a later session. Neither service unlocks levels.

## Inputs and output

The planner receives a `LevelDefinition`, its available question bank, previous
mastery, recommended difficulty (Easy 1, Medium 2, Hard 3), optional focus
skill, recently used question IDs, desired session length, and a random seed.
It returns the selected `MathQuestion`s and IDs, the modal planned difficulty,
target skill, a human-readable explanation, and explicit fallback messages.

Only questions whose level ID and activity type match the selected level are
eligible. Every eligible question is validated against the shared activity
content contract before selection. Duplicate IDs, malformed eligible
questions, and a bank too small to fill the requested session fail explicitly;
the planner never invents questions or reaches into another level's bank.

## Initial policy

1. Prefer the recommended difficulty. Within a selected skill/group, use the
   closest difficulty band if that band has too few questions.
2. If at least the desired number of eligible questions have not been seen
   recently, exclude recent IDs for this session. Otherwise allow reuse and
   report it.
3. If a focus skill exists at the recommended difficulty, reserve up to three
   positions for it while leaving at least one position for other skills when
   those are available.
4. Fill remaining positions with other skills, favoring skills least
   represented in the current session, then the nearest difficulty.
5. Use the injected seed to choose reproducibly among equally suitable
   candidates. Production play sessions seed from the current clock.

The planner never changes difficulty during a session. A new learner starts at
Easy; otherwise the saved adaptive recommendation is passed to the planner.
Mastery is included in the explanation and retained as context, but does not
override the assessment engine's difficulty recommendation.

If focus-skill questions are unavailable at the recommended difficulty, the
planner prioritizes the recommended band and reports the focus fallback. It
uses adjacent bands only when needed. If the level has fewer than five valid
eligible questions, it returns an explicit planning error instead of silently
starting a shorter session.

## Example: consecutive sessions

For seed `42`, a new Level 1 learner starts with five Easy questions. After a
perfect session, the assessment engine stores the updated mastery, a Medium
recommendation, focus evidence, and the five question IDs in recent history.
The next plan uses that saved recommendation and recent IDs: it selects five
Medium questions with different IDs when enough unseen Medium alternatives
exist. The exact IDs are reproducible for the same bank, state, and seed.

This policy is an initial engineering rule set, not a pedagogically validated
sequence. The question bank, recency window (30 IDs), focus allocation (up to
three questions), fallback behavior, difficulty transitions, and seed policy
need review with educators and learning data before production use.
