from flask import request, jsonify

from models import Match, Score, db
from match_outcomes import get_outcome, UnknownOutcomeError
from routes.score.score_core import finalize_match, emit_score_update
from . import match_bp


@match_bp.route('/update-match-outcome', methods=['POST'])
def update_match_outcome():
    data = request.get_json(silent=True) or {}

    required = ['match_id', 'tournament_id', 'outcome_type', 'winner_team_id']
    missing = [key for key in required if key not in data]
    if missing:
        return jsonify({
            'error': f"Missing required field(s): {', '.join(missing)}"
        }), 400

    match_id = data.get('match_id')
    tournament_id = data.get('tournament_id')
    outcome_type = data.get('outcome_type')
    winner_team_id = data.get('winner_team_id')

    match = Match.query.filter_by(id=match_id, tournament_id=tournament_id).first()
    if not match:
        return jsonify({'error': 'Match not found for this tournament'}), 404

    try:
        outcome = get_outcome(outcome_type)
    except UnknownOutcomeError as e:
        return jsonify({'error': str(e)}), 400

    if outcome.requires_score:
        return jsonify({
            'error': (
                f"Outcome '{outcome_type}' requires a played score; "
                "use /update-score instead"
            )
        }), 400

    if not match.team1_id or not match.team2_id:
        return jsonify({
            'error': 'Both teams must be set before declaring an outcome'
        }), 400

    if winner_team_id not in (match.team1_id, match.team2_id):
        return jsonify({
            'error': 'winner_team_id must be one of the two teams in the match'
        }), 400

    if match.is_final:
        return jsonify({'error': 'Match is already final'}), 409

    try:
        # A walkover means nothing was played: discard any partial score.
        for team_id in (match.team1_id, match.team2_id):
            score_record = Score.query.filter_by(
                match_id=match.id,
                team_id=team_id,
                tournament_id=tournament_id
            ).first()

            if not score_record:
                score_record = Score(
                    match_id=match.id,
                    team_id=team_id,
                    tournament_id=tournament_id,
                    score=0
                )
                db.session.add(score_record)
            else:
                score_record.score = 0

        finalize_match(match, winner_team_id, outcome_type)
        match.status = 'completed'
        db.session.commit()

        emit_score_update(
            match.id, match.team1_id, 0,
            match.team2_id, 0, match.is_final, match.tournament_id
        )

        return jsonify({
            'match_id': match.id,
            'tournament_id': match.tournament_id,
            'outcome_type': match.outcome_type,
            'outcome_label': outcome.label,
            'winner_team_id': match.winner_team_id,
            'is_final': match.is_final,
            'status': match.status
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
