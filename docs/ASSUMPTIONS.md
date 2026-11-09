# Assumptions

Running list. Newest phase appended at the bottom.

## Phase 1 — database schema (`match.outcome_type`)

1. **Notes location.** `/khel/_notes` is not creatable on this machine, so notes live at
   `/home/devnaldo/khel/_notes/` (same decision as `CODEBASE_MAP.md` / `RUN.md`).
2. **Migration idempotency lives in the `.py` wrapper.** The existing pattern
   (`migrations/bul/add_match_bracket_columns.sql` + `.py`) keeps the `.sql` as a plain
   `ALTER` and puts the `INFORMATION_SCHEMA.COLUMNS` guard in the Python script. I mirrored
   that exactly, so the `.sql` alone is not re-runnable, but the `.py` is (verified twice).
3. **Column order differs between migrated DB and dump.** `ALTER TABLE ... ADD COLUMN`
   without `AFTER` appends `outcome_type` at the end of the live table; the dump declares it
   after `status`. MySQL column order is not semantically meaningful and SQLAlchemy maps by
   name, so this is accepted. No `AFTER status` was added, to keep the migration minimal.
4. **Dump seed INSERT uses an explicit column list.** Because the dump previously used
   `INSERT INTO \`match\` VALUES (...)` without a column list, adding a column would have
   broken the import. The INSERT now lists all pre-existing columns, so `outcome_type`
   takes its `'normal'` default. No other table was touched.
5. **No DB CHECK constraint.** Per the approved design, allowed values are validated by the
   backend registry (`match_outcomes.py`, later phase), not by MySQL.
6. **Defaults are set in both places.** The column has `DEFAULT 'normal'` in SQL and the model
   has `default='normal', server_default='normal'`, so ORM inserts and raw inserts agree.
7. **Phase 1 does not expose `outcome_type` via the API.** `get-match-fixtures` still returns
   the old `match_status` shape (verified: only `is_final`, `status`, `winner_team_id`).
   Adding `outcome_type` / `outcome_label` is a later phase.
8. **Local DB is the Docker container on port 3307**, DB `khel_club`, per `_notes/RUN.md`.
   The migration was applied there; the scratch import used `khel_scratch` and was dropped.
9. **Backend restart.** The old Flask process was stopped and a fresh one started so the new
   model loads. `.env` was not modified or committed.
10. **Frontend verification is limited to HTTP 200 + the backend call.** The tournament page
    renders fixtures client-side, so a headless `curl` cannot prove the table visually
    rendered. The page returned 200 and the exact endpoint it calls returned 200 with the
    unchanged shape.

## Phase 2 — outcome registry, `finalize_match`, `/update-match-outcome`

11. **Partial scores are reset to 0-0 on walkover.** The endpoint overwrites any existing
    `score` rows for both teams with 0, because a walkover means nothing was played. This was
    verified by seeding a 5-3 partial score on match 8 first: after the walkover both rows
    read 0.
12. **`finalize_match` does not set `status` and does not commit.** That keeps
    `/update-score` behavior byte-for-byte identical (it historically leaves `status` alone;
    `is_final` can be 1 while `status` is still `pending`). Only `/update-match-outcome` sets
    `status='completed'`, in the endpoint, before its single commit.
13. **Walkover cannot be undone through the API.** A second `/update-match-outcome` call, and
    `/update-score` on a non-normal match, both return 409. There is no revert endpoint.
14. **PATCHing status afterwards is not blocked.** `/update-match-status` is untouched and
    still accepts any status string, so a completed walkover could be moved back to
    `pending`/`on-going` by that endpoint. Guarding it is out of scope for Phase 2.
15. **Existing knockout bracket endpoints cannot create brackets.** `/knockout` and
    `/knockout-from-matches` both fail with MySQL error 1452: they insert `'TBD'` into
    `round.team_id`, which has an FK to `team.team_id`. This is a pre-existing bug unrelated
    to the walkover work; it is documented here, not fixed.
16. **Knockout successor verification used a seeded bracket.** Because of (15), matches
    1001/1002/1003 were inserted directly via SQL in the live DB (two semifinals pointing at a
    final), the walkover was declared through the real endpoint, and the winner appeared as
    `team1` of the final in both the DB and `get-match-fixtures`. The DB was then restored
    from `_notes/khel_club_backup.sql`, so no seed rows remain.
17. **`outcome_label` always comes from the registry.** Both APIs call `get_outcome(...).label`
    rather than hard-coding "Walkover". A future registry entry needs no API change.
18. **The 1-point vs 2-point standings scale mismatch is still present.** It is out of scope
    until Phase 3; `resolve_match_result` will be introduced there without changing it.

## Phase 3 — standings and round logic

19. **Missing/NULL `outcome_type` is treated as `normal`.** `explicit_result` maps falsy keys to
    `'normal'`, so rows written before the column existed keep the old score-comparison path.
20. **Unregistered `outcome_type` is treated as `normal` and logged with `print`.** A bad row
    can never 500 a standings page; the warning goes to the backend log only. This is the same
    fallback used by `explicit_result` in tests.
21. **Explicit-result matches contribute zero points, even if stale scores exist.** The
    standings branch skips points accumulation entirely and uses the stored winner. This was
    probed by writing 11-3 onto a walkover row whose declared winner was the 3-point side: the
    declared winner still got the win and points stayed 0. The probe state was restored.
22. **`get_round_standings` and `get_pool_standings` already counted pending 0-0 matches as
    played before this phase.** They have no 0-0 skip, unlike the three `tournament_core`
    endpoints. That inconsistency is preserved deliberately; Phase 3 only replaces the winner
    comparison. As a result, `matches_played` differs between the endpoint and the function for
    pending matches (e.g. 0 vs 3 in the verification data).
23. **`round_helpers.get_cumulative_points_for_round`, the `/points` endpoints and CSV export
    are untouched.** A walkover contributes 0 points there, matching "nothing was played".
24. **`total_scores` formulas are preserved.** `tournament_core` functions use `matches_won * 2`,
    `get_round_standings` uses `matches_won` (x1), and `get_pool_standings` has no
    `total_scores`. A walkover win follows each function's existing formula.
25. **`ExplicitResult` is a frozen dataclass, not a tuple.** Call sites read `.is_explicit` /
    `.winner_id`; an initial tuple-style unpack raised `TypeError` and was fixed in a follow-up
    commit (`fix(standings): unpack ExplicitResult fields, not the object`).
26. **Tests live in `tests/` with a `conftest.py` that adds the backend root to `sys.path`.**
    No `pytest.ini`/`pyproject.toml` was added because the phase scope allowed only `tests/` and
    `requirements-dev.txt`. `pytest` is installed in the existing venv for local runs.
27. **Normal-path regression is byte-identical.** The Phase 3 baseline (`baseline_standings.json`,
    normal-only 11-7 / 9-11 / 11-0 scenario) was reproduced after the change and diffed against
    the three endpoints plus both round functions: zero differences.

## Phase 4 — frontend

28. **One outcome check, one helper.** `getOutcomeView` is the only place that compares
    `outcome_type` with `'normal'`. Everything else branches on `showTag` / `isScored` /
    `winnerSide`. `DECLARABLE_OUTCOMES` is the only outcome list used by the referee UI, so
    adding a future outcome is one line there (plus its backend registry entry).
29. **The helper accepts both API shapes.** Fixtures wrap the fields in `match_status`; the
    `/score/match` response has them at the top level. `getOutcomeView` uses
    `match.match_status || match`, so `Match.js` and `MatchOverlay` can use the same helper.
30. **`isScored` defaults to true when `requires_score` is missing**, so cached/old responses
    without the field keep the previous score presentation.
31. **`Fixtures.js` has no status pill in `renderMatches` or `renderGroupedMatches`.** The
    `OutcomeBadge` is therefore appended to the existing `matchInfo` row (next to the round /
    court metadata) rather than next to a pill that does not exist there. `TournamentFixtures`
    does have a status pill and puts the badge directly after it.
32. **The referee declare dialog is generic.** It maps over `DECLARABLE_OUTCOMES`, asks for the
    winner via the two team buttons, POSTs `endpoints.updateMatchOutcome`, and then calls the
    component's extracted `fetchMatches` (now a `useCallback`) instead of patching state.
    The endpoint returns no `message`, so the toast falls back to
    `"<label> declared successfully"`.
33. **`Match.js` does not auto-open the override dialog for non-scored outcomes.** A walkover
    has no score to override; normal completed and pending matches keep the old prompt. The
    score inputs, +/- controls, Update and Final buttons are disabled via `isScored`.
34. **`MatchOverlay` was completed, not skipped.** It shows `outcome_label` in place of the two
    score values when `showTag && !isScored`; the change is about 12 JSX/SCSS lines.
35. **`KnockoutBracket2` needed a real fix.** Its `CustomSeed` had been edited to compare an
    undeclared `score` variable; it now checks `seed.teams[n]?.score` against both `undefined`
    and `null`, so the loser's `null` result renders nothing.
36. **`npm run lint` could not run.** The repo has no ESLint config, and `next lint` stops at
    the interactive "How would you like to configure ESLint?" prompt. Adding a config was
    outside the allowed file list, so lint was not run; `npm run build` is the gate and passed.
37. **Visual rendering is untested.** No Chromium/Chrome, Playwright or Puppeteer is installed,
    and installing one was forbidden. Verification is HTTP-level: the live fixtures response
    shows `outcome_type=walkover`, `requires_score=false`, winner `T001`, and the dev server
    returns 200 for `/tournament/1` and `/referee`.
38. **Verification data was restored.** After declaring the walkover on match 8, the DB was
    restored from `_notes/khel_club_backup_p3.sql`: 6 matches, all `pending`/`normal`,
    `is_final=0`.
39. **`.env.local` and `logs/` are excluded via `.git/info/exclude`**, not `.gitignore`. The
    working tree is clean and no such files were staged; only the named source files were
    committed explicitly.
