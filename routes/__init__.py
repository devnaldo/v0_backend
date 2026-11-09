from flask import Blueprint

# Import all blueprints
from .tournament import tournament_bp
from .team import team_bp
from .match import match_bp
from .score import score_bp
from .match import match_outcome  # noqa: F401  (registers /update-match-outcome)
from .round import round_bp
from .season import season_bp
from .super_tournament import super_tournament_bp
from .match_ops import match_ops_bp
from .player_ops import player_ops_bp

def initialize_routes(app):
    """Initialize all route blueprints with the app"""
    app.register_blueprint(tournament_bp)
    app.register_blueprint(team_bp)
    app.register_blueprint(match_bp)
    app.register_blueprint(score_bp)
    app.register_blueprint(round_bp)
    app.register_blueprint(season_bp)
    app.register_blueprint(super_tournament_bp)
    app.register_blueprint(match_ops_bp, url_prefix='/match-ops')
    app.register_blueprint(player_ops_bp, url_prefix='/player-ops')

