"""Match outcome registry.

An outcome type describes HOW a match ended (normal, walkover, ...). It is
deliberately separate from the match lifecycle status and from the scoring
rules. New outcomes (forfeit, bye, ...) are added by registering another
OutcomeType here; callers never need their own ``if outcome == ...`` checks.
"""

from dataclasses import dataclass


class UnknownOutcomeError(ValueError):
    """Raised when an outcome type is not present in the registry."""


@dataclass(frozen=True)
class OutcomeType:
    key: str
    label: str
    requires_score: bool
    winner_is_explicit: bool


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
