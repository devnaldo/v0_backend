# Khel Club Backend — Scoring and Walkover Outcomes

## 1. How the current scoring mechanism works

- **Data model.** A `Tournament` has `Round`s, and a `Match` belongs to a round and a pool.
  `Match` stores `team1_id`, `team2_id`, `winner_team_id`, `is_final`, `status` and
  `outcome_type`. Each team in a match has one `Score` row with a single integer `score`
  (one number per team per match, not per game).
- **Submission flow.** `POST /update-score` accepts
  `{match_id, tournament_id, score: "a-b", final, override}`. It parses the `"a-b"` string,
  creates or updates the two `Score` rows and commits.
- **Winner is stored, not derived.** When `final` is true, `update_score` compares the two
  integers (`>`; equal means `None`) and stores `winner_team_id` plus `is_final`.
- **Status is set by a separate call.** `update_score` does not set `status`; the frontend
  calls `POST /update-match-status/<match_id>` with `status: "completed"` after finalizing.
  A match can therefore have `is_final = 1` while `status = "pending"`.
- **Standings are recomputed on every request.** `GET /standings/<id>`,
  `GET /overall-standings/<id>` and `GET /second-place-standings/<id>` live in
  `routes/tournament/tournament_core.py`; `get_round_standings` in
  `routes/round/round_completion.py` and `get_pool_standings` in
  `routes/round/round_knockout.py` are the two round helpers.
- **0-0 means "not played".** The three tournament endpoints skip a match when both stored
  scores are 0. The two round helpers have no such skip and already counted pending 0-0
  matches as played before this work.
- **Different win scales.** `tournament_core` awards `matches_won * 2` total scores;
  `round_completion` uses `matches_won` (1); `get_pool_standings` has no total.
- **Quirks, preserved on purpose.**
  - Winner logic is duplicated in six places.
  - `/update-score` accepts an `override` flag but ignores it.
  - The `/update-score` response does not include `winner_team_id`.
  - No pickleball rules: no win-by-2, no best-of-N, no per-game scores.
  - One integer score per team per match is the only scoring input.

## 2. What I changed and why

- **`outcome_type` column, not a boolean.** A string column describes HOW a match ended and
  can be extended (forfeit, bye) without another schema change. It is separate from `status`
  (lifecycle) and from scoring rules (how points count).
- **`match_outcomes.py` registry.** Pure Python, no Flask/DB imports. Each `OutcomeType` has
  `key`, `label`, `requires_score` and `winner_is_explicit`; registered outcomes are `normal`
  and `walkover`. It also exposes `get_outcome`, `is_registered`, `list_outcomes` and
  `explicit_result(outcome_type, winner_team_id)`, which returns an
  `ExplicitResult(is_explicit, winner_id)`.
- **`finalize_match()`** (in `routes/score/score_core.py`) sets `winner_team_id`, `is_final`
  and `outcome_type`, advances a knockout successor, and deliberately does **not** set
  `status` or commit. Both `/update-score` and the new endpoint use it.
- **`POST /update-match-outcome`** (`routes/match/match_outcome.py`) takes
  `{match_id, tournament_id, outcome_type, winner_team_id}`. It validates in order: required
  keys (400), match in tournament (404), registered outcome (400), outcome does not require a
  score (400), both teams set (400), winner is one of the teams (400), not already final
  (409). It resets both score rows to 0, calls `finalize_match`, sets `status = "completed"`,
  commits once and emits the existing `score_update` socket event.
- **Standings ask the registry.** None of the standings functions contains an
  `if outcome_type == 'walkover'`. They call `explicit_result`; when the result is explicit the
  stored winner decides the match and the score comparison is skipped. The branch runs before
  the 0-0 skip. An explicit result counts as played for both teams, the winner gets a win, and
  `points_scored` / `points_lost` / `points_difference` do not change. Normal matches run the
  original code path unchanged.
- **API exposure.** `get-match-fixtures` puts `outcome_type`, `outcome_label` and
  `requires_score` inside `match_status`; `GET /score/match` exposes them at the top level.
  Existing fields, including `match_result` (`"a-b"`), are untouched.
- **Frontend.** One helper (`src/utils/matchOutcome.js`) and one component
  (`OutcomeBadge`/`WinnerBadge`). Fixture cards, tables, bracket views and the overlay render
  API fields only. `DECLARABLE_OUTCOMES` drives the referee action.
- **Tests and regression.** `tests/test_match_outcomes.py` covers the registry and
  `explicit_result` with pytest (no DB, no Flask). A normal-only standings baseline
  (`11-7 / 9-11 / 11-0`) was replayed after the change; the diff was empty.

## 3. Schema and migration

- Column: `match.outcome_type VARCHAR(20) NOT NULL DEFAULT 'normal'`.
- `migrations/bul/add_match_outcome_type.sql` is a plain `ALTER TABLE`.
- `migrations/bul/add_match_outcome_type.py` is the runnable wrapper; it checks
  `INFORMATION_SCHEMA.COLUMNS` first, so it is idempotent (verified by running it twice).
- `dump-test-202512221924.sql` declares the column and its seed `INSERT` uses an explicit
  column list, so existing rows take the `'normal'` default.
- There is no DB `CHECK` constraint. Allowed values are validated by the backend registry.

## 4. How to add a new outcome (e.g. forfeit)

1. **Backend:** add one entry to `_OUTCOMES` in `match_outcomes.py`:

   ```python
   'forfeit': OutcomeType(
       key='forfeit',
       label='Forfeit',
       requires_score=False,     # no played score
       winner_is_explicit=True,  # winner comes from winner_team_id
   )
   ```

   Set `requires_score=True` only if the outcome is decided by a played score (then it goes
   through `/update-score`, and `/update-match-outcome` rejects it). Set
   `winner_is_explicit=True` when the winner is recorded explicitly; `False` means compare
   scores as today. Add a case to `tests/test_match_outcomes.py`.

2. **Frontend:** add one entry to `DECLARABLE_OUTCOMES` in `src/utils/matchOutcome.js`:

   ```js
   { key: 'forfeit', label: 'Forfeit' }
   ```

   The referee dialog, tables, cards, brackets and overlay are already data-driven.

No other source change should be required.

## 5. Assumptions

Full list: [`docs/ASSUMPTIONS.md`](docs/ASSUMPTIONS.md) (copy of `_notes/ASSUMPTIONS.md`,
items 1-39). Summary:

- `outcome_type` is tolerant: `NULL`/missing means `normal`; an unregistered value is also
  treated as `normal` and logged with `print`, so a bad row cannot 500 a standings page.
- A walkover resets both score rows to 0-0; partial scores are discarded. It cannot be undone
  through the API.
- `finalize_match` does not set `status` or commit; only `/update-match-outcome` sets
  `completed`, in one commit.
- Explicit outcomes are played + win, with zero points and zero point difference, including
  in the untouched cumulative-points and CSV paths.
- Existing inconsistencies are preserved: 2 points per win in `tournament_core` vs 1 in
  `round_completion`; the round helpers count pending 0-0 as played while the three endpoints
  skip it.
- No DB `CHECK`; the registry validates. The SQL dump uses an explicit `INSERT` column list.
- The frontend never computes a result; the only `outcome_type !== 'normal'` check is in the
  helper.
- Verification data was restored: 6 seed matches, all `pending` / `normal`.
- `npm run lint` was not run (no ESLint config), and the UI was not exercised in an automated
  browser.

## 6. Known issues, not fixed

- `/knockout` and `/knockout-from-matches` fail with MySQL FK error 1452 because they insert
  `'TBD'` into `round.team_id` (FK to `team.team_id`).
- `NameError` at `round_core.py:49`.
- Duplicate `Round.name` definition in `models.py`.
- `PATCH /update-match-status` can move a completed walkover back to `pending`; there is no
  status-transition guard.
- A walkover cannot be undone through any endpoint.
- The fixtures API calls `get_outcome(...).label` strictly, so a hand-edited/unknown
  `outcome_type` would raise there even though standings tolerate it.
- Frontend lint was not run because the repo has no ESLint config, and the UI was not verified
  in an automated browser (none installed).
- Commit `d94216a` fixed a `TypeError` introduced by the previous standings commit because
  amending was forbidden.

## 7. What I would improve with more time

- One shared winner-resolution function replacing the six copies, and removal of the 0-0
  sentinel in favour of an explicit played/unplayed signal.
- A status-transition guard plus an admin undo for declared outcomes.
- `forfeit` and `bye` registry entries with tests.
- API tests against a disposable test database, frontend component tests, and an ESLint
  config.
- Authentication for the referee/organizer actions.
- Fix the knockout bracket FK bug (`'TBD'` in `round.team_id`).

## Original README

| **# Pools** | **Same-Pool Pairing**                        | **Near-pool Pairing**                       | **Half-Pool Pairing**                     | **Far-Pool Pairing**                     |
|-------------|----------------------------------------------|---------------------------------------------|-------------------------------------------|------------------------------------------|
| **2 Pools** | A1 vs A2, B1 vs B2                           | A1 vs B2, A2 vs B1                         | A1 vs A2, B1 vs B2 (same as "same-pool")  | A1 vs B2, A2 vs B1                       |
| **4 Pools** | A1 vs A2, B1 vs B2, C1 vs C2, D1 vs D2       | A1 vs B2, A2 vs B1, C1 vs D2, C2 vs D1     | A1 vs B2, A2 vs B1, C1 vs D2, C2 vs D1    | A1 vs D2, A2 vs D1, B1 vs C2, B2 vs C1   |
| **8 Pools** | A1 vs A2, B1 vs B2, C1 vs C2, D1 vs D2, E1 vs E2, F1 vs F2, G1 vs G2, H1 vs H2 | A1 vs B2, A2 vs B1, C1 vs D2, C2 vs D1, E1 vs F2, E2 vs F1, G1 vs H2, G2 vs H1 | A1 vs D2, A2 vs D1, E1 vs H2, H1 vs E2    | A1 vs H2, A2 vs H1, B1 vs G2, B2 vs G1, C1 vs F2, C2 vs F1, D1 vs E2, D2 vs E1 |
