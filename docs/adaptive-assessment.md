# Adaptive assessment (provisional rules)

`AdaptiveAssessmentEngine` is a standalone Dart service. It accepts one completed `SessionResult` and that level's `AdaptiveProgressState`, then returns score components, session score, updated mastery, recommended difficulty, focus skill, completion eligibility, trend, diagnostics and proposed updated state. `SessionController` records answers and timing; the engine evaluates the evidence; `AdaptiveProgressRepository` persists per-level learning state; UI screens only display results. Existing session-result fields and storage remain readable; new results also include optional `expectedQuestionCount`. Older saved results without it load normally, but cannot prove evidence completeness and are not used to update mastery.

## Scoring

Every recorded answer attempt contributes its question difficulty weight: Easy (1) = 1.0, Medium (2) = 1.2, Hard (3) = 1.4.

```text
Weighted Accuracy = 100 × sum(weight × correct) / sum(weight)
Hint Independence = 100 × unhinted attempts / all attempts
Session Score = clamp(0.80 × Weighted Accuracy
                    + 0.10 × Hint Independence
                    + 0.10 × Response Efficiency, 0, 100)
```

Only recorded attempts enter the denominator, so the weighted-accuracy ratio is normalized and cannot exceed 100. Empty attempt lists make evidence incomplete; a partial score may be reported from recorded attempts, but mastery, skill history, difficulty and completion are not updated. A result with no attempts has a null score. Response times are recorded by the existing session model, but the product has not established an age-appropriate target or penalty. Therefore response efficiency defaults to a configurable neutral **100** for every attempt; elapsed time does not alter the score. This provisional neutral choice gives the term no discriminating effect until validated.

**Example:** A completed session has one correct Easy attempt, one incorrect Medium attempt and one correct Hard attempt, all without hints and all tagged `counting`. Weighted accuracy is `(1.0 + 1.4) / (1.0 + 1.2 + 1.4) × 100 = 66.67`; hint independence is 100 and neutral response efficiency is 100. Session score is `0.8 × 66.67 + 0.1 × 100 + 0.1 × 100 = 73.33`. With two prior sessions, mastery 70, current difficulty Medium, prior scores 72 and 74, one previous mastery snapshot of 70, and no successful medium session, updated mastery is `0.7 × 70 + 0.3 × 73.33 = 71.00`. Recent average is 73.11, so difficulty is maintained. Three skill attempts give `counting` 66.67% accuracy and make it the focus (additional practice). Trend is Stable (+1); level completion is not eligible because mastery is below 75 and there is no successful medium session.

## Mastery, skills, difficulty

- First eligible completed session initializes mastery to its session score. Later sessions use `clamp(0.70 × previous mastery + 0.30 × session score, 0, 100)`.
- Skill accuracy aggregates historical attempts by tag. Fewer than three attempts is insufficient evidence. Below 60% means strong reinforcement; 60% through below 75% means additional practice; 75% or higher is satisfactory. Focus skill is the lowest-accuracy eligible skill; ties use alphabetical skill-tag ordering. With no eligible skill, focus is null and diagnostics explain the evidence gap.
- Recent score average uses the latest three eligible completed session scores, including the current session. Decision order is explicit: first decrease one step (clamped) if latest score is below 50 **or** recent average is below 60; otherwise increase one step (clamped) only when recent average is at least 80 and updated mastery at least 75; otherwise maintain. Thus a very poor latest session overrides a previously strong average.
- One session is provisionally considered a successful medium session if its session score is at least 75 and at least one correctly answered question has difficulty 2. This is an assumption pending a curriculum definition of “successful.”

## Level completion and trends

Level completion requires at least two eligible completed sessions, mastery at least 75, one successful medium session, at least one skill observed at the three-attempt threshold, and no evaluated skill below 50%. If no skill can yet be evaluated, `levelCompletionEvidenceSufficient` is false and completion is withheld rather than treating an empty skill set as a pass. Hard difficulty is not required. Eligibility is an assessment output only; it does not unlock levels.

Trend compares the newest mastery snapshot with the immediately preceding snapshot (two snapshots required). Difference `>= +5` is Improving; `<= -5` is Declining; values strictly between those boundaries (including exactly -4 through +4) are Stable. Fewer than two snapshots is Not Enough Data. Snapshots are retained up to ten per level.

## Persistence, idempotency, and limitations

Adaptive history is stored separately from existing session results using local preferences. Completed session IDs are retained per level; reprocessing an ID returns the existing state without applying score/mastery/count changes twice. This local read/evaluate/write flow assumes sequential processing by one app instance; it is not a cross-device or concurrent-writer transaction.

The engine is deterministic rule-based logic, not machine learning. Score weights, neutral response efficiency, mastery coefficients, skill minimum/thresholds, the three-session average, poor-latest precedence, successful-medium criterion, completion criteria, and trend window require educator/child testing and calibration. Current questions use integer difficulty values 1–3. The separate `AdaptiveSessionPlanner` consumes the persisted difficulty recommendation, focus skill, and recent question IDs to plan a later session; it does not change the assessment formulas or adjust questions during an active session. Session data does not establish a validated response-speed target or confidence model.
