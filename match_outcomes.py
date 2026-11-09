"""Match outcome registry.

An outcome type describes HOW a match ended (normal, walkover, ...). It is
deliberately separate from the match lifecycle status and from the scoring
rules. New outcomes (forfeit, bye, ...) are added by registering another
OutcomeType here; callers never need their own ``if outcome == ...`` checks.
"""

from dataclasses import dataclass
from typing import Optional


class UnknownOutcomeError(ValueError):
    """Raised when an outcome type is not present in the registry."""


@dataclass(frozen=True)
class OutcomeType:
    key: str
    label: str
    requires_score: bool
    winner_is_explicit: bool


@dataclass(frozen=True)
class ExplicitResult:
    """Result of asking the registry how a stored match should be read.

    ``is_explicit`` is True when the winner is recorded on the match instead of
    being derived from the score. ``winner_id`` is the stored winner, which may
    be None if no winner was recorded.
    """

    is_explicit: bool
    winner_id: Optional[str]


_OUTCOMES = {
    'normal': OutcomeType(
        key='normal',
        label='Normal',
        requires_score=True,
        winner_is_explicit=False,
    ),
    'walkover': OutcomeType(
        key='walkover',
        label='Walkover',
        requires_score=False,
        winner_is_explicit=True,
    ),
}


def get_outcome(key):
    """Return the registered OutcomeType for ``key``.

    Raises UnknownOutcomeError with a clear message when ``key`` is not
    registered.
    """
    try:
        return _OUTCOMES[key]
    except KeyError:
        registered = ', '.join(sorted(_OUTCOMES))
        raise UnknownOutcomeError(
            f"Unknown outcome_type '{key}'. Registered outcomes: {registered}"
        )


def is_registered(key):
    """Return True when ``key`` is a registered outcome type."""
    return key in _OUTCOMES


def list_outcomes():
    """Return all registered OutcomeType objects."""
    return list(_OUTCOMES.values())


def explicit_result(outcome_type, winner_team_id):
    """Return an ExplicitResult describing how to read a stored match.

    A missing/NULL outcome_type is treated as 'normal'. An unregistered value is
    also treated as 'normal' (and logged) so a bad row can never break standings.
    For outcomes whose winner is explicit, the stored winner_team_id is used and
    score comparison must be skipped.
    """
    key = outcome_type or 'normal'

    if key not in _OUTCOMES:
        print(
            f"WARNING: unregistered outcome_type '{key}' treated as normal"
        )
        return ExplicitResult(is_explicit=False, winner_id=None)

    if not _OUTCOMES[key].winner_is_explicit:
        return ExplicitResult(is_explicit=False, winner_id=None)

    return ExplicitResult(is_explicit=True, winner_id=winner_team_id)
