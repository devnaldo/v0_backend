-- Add match outcome type to match table
-- Outcome type is how a match ended (normal, walkover, ...), separate from
-- scoring rules and from the lifecycle status column.

ALTER TABLE `match`
ADD COLUMN `outcome_type` VARCHAR(20) NOT NULL DEFAULT 'normal';
