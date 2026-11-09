#!/usr/bin/env python3
"""
Migration script to add the outcome_type column to the match table.
Run this script to add: outcome_type
"""

import sys
import os

# Add parent directory to path to import config
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

from config import Config
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text

def run_migration():
    """Add the outcome_type column to the match table"""
    app = Flask(__name__)
    app.config.from_object(Config)
    db = SQLAlchemy(app)

    with app.app_context():
        try:
            # Check if the column already exists
            result = db.session.execute(text("""
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = :db_name
                AND TABLE_NAME = 'match'
                AND COLUMN_NAME = 'outcome_type'
            """), {'db_name': Config.DB_NAME})

            existing_columns = {row[0] for row in result.fetchall()}

            if 'outcome_type' in existing_columns:
                print("Column outcome_type already exists. Migration not needed.")
                return

            alter_sql = (
                "ALTER TABLE `match` "
                "ADD COLUMN `outcome_type` VARCHAR(20) NOT NULL DEFAULT 'normal'"
            )
            print(f"Executing: {alter_sql}")
            db.session.execute(text(alter_sql))
            db.session.commit()

            print("Migration completed successfully!")

        except Exception as e:
            print(f"Error running migration: {str(e)}")
            db.session.rollback()
            raise

if __name__ == '__main__':
    run_migration()
