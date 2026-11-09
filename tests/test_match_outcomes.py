from dataclasses import FrozenInstanceError

import pytest

from match_outcomes import (
    ExplicitResult,
    UnknownOutcomeError,
    explicit_result,
    get_outcome,
    is_registered,
    list_outcomes,
)


def test_registry_contains_exactly_normal_and_walkover():
    outcomes = {outcome.key: outcome for outcome in list_outcomes()}
    assert set(outcomes) == {'normal', 'walkover'}


def test_normal_outcome_definition():
    outcome = get_outcome('normal')
    assert outcome.label == 'Normal'
    assert outcome.requires_score is True
    assert outcome.winner_is_explicit is False


def test_walkover_outcome_definition():
    outcome = get_outcome('walkover')
    assert outcome.label == 'Walkover'
    assert outcome.requires_score is False
    assert outcome.winner_is_explicit is True


def test_outcome_type_is_frozen():
    outcome = get_outcome('normal')
    with pytest.raises(FrozenInstanceError):
        outcome.label = 'Changed'


def test_get_outcome_unknown_raises():
    with pytest.raises(UnknownOutcomeError) as excinfo:
        get_outcome('bogus')
    message = str(excinfo.value)
    assert 'bogus' in message
    assert 'normal' in message
    assert 'walkover' in message


def test_is_registered():
    assert is_registered('normal') is True
    assert is_registered('walkover') is True
    assert is_registered('bogus') is False
    assert is_registered(None) is False


def test_explicit_result_normal_is_not_explicit():
    assert explicit_result('normal', 'T001') == ExplicitResult(
        is_explicit=False, winner_id=None
    )


def test_explicit_result_walkover_uses_stored_winner():
    assert explicit_result('walkover', 'T001') == ExplicitResult(
        is_explicit=True, winner_id='T001'
    )


def test_explicit_result_walkover_without_winner_is_played_without_winner():
    assert explicit_result('walkover', None) == ExplicitResult(
        is_explicit=True, winner_id=None
    )


@pytest.mark.parametrize('missing', [None, ''])
def test_explicit_result_missing_outcome_is_normal(missing):
    assert explicit_result(missing, 'T001') == ExplicitResult(
        is_explicit=False, winner_id=None
    )


def test_explicit_result_unregistered_is_normal_and_logged(capsys):
    result = explicit_result('bogus', 'T001')
    assert result == ExplicitResult(is_explicit=False, winner_id=None)
    assert "unregistered outcome_type 'bogus'" in capsys.readouterr().out
